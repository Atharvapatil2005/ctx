#!/usr/bin/env bash
set -euo pipefail

fail() {
  printf 'real search quality benchmark failed: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'USAGE'
usage: scripts/bench-real-search-quality.sh [QUERY_FILE]

Runs an opt-in, read-only benchmark against the existing local ctx index. It
compares current `ctx search --refresh off` with `ctx research --refresh off`
for a judged query manifest and writes JSON plus Markdown review artifacts.

Environment overrides:
  CTX_REAL_SEARCH_BENCH_BIN=/path/to/ctx
  CTX_REAL_SEARCH_BENCH_REPEATS=3
  CTX_REAL_SEARCH_BENCH_LIMIT=5
  CTX_REAL_SEARCH_BENCH_TIMEOUT_SECONDS=5
  CTX_REAL_SEARCH_BENCH_ARTIFACT_DIR=target/ctx-artifacts/real-search-quality
  CTX_REAL_SEARCH_BENCH_KEEP_CODEX_THREAD=1
USAGE
}

find_repo_root() {
  local candidate
  for candidate in "${BUILD_WORKSPACE_DIRECTORY:-}" "$(pwd)" "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; do
    if [[ -n "${candidate}" && -f "${candidate}/Cargo.toml" ]]; then
      cd "${candidate}"
      pwd
      return 0
    fi
  done
  fail 'could not locate repo root containing Cargo.toml'
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if (( "$#" > 1 )); then
  usage >&2
  exit 2
fi

command -v python3 >/dev/null 2>&1 || fail 'python3 is required'

repo_root="$(find_repo_root)"
query_file="${1:-${repo_root}/docs/benchmarks/real-search-quality-queries.json}"
[[ -f "${query_file}" ]] || fail "query file not found: ${query_file}"

ctx_bin="${CTX_REAL_SEARCH_BENCH_BIN:-}"
if [[ -z "${ctx_bin}" ]]; then
  printf '==> cargo build --quiet --locked -p ctx --bin ctx\n'
  cargo build --quiet --locked -p ctx --bin ctx
  ctx_bin="${repo_root}/target/debug/ctx"
fi
[[ -x "${ctx_bin}" ]] || fail "ctx binary is not executable: ${ctx_bin}"

python3 - "${repo_root}" "${ctx_bin}" "${query_file}" <<'PY'
from __future__ import annotations

import datetime as dt
import csv
import json
import math
import os
import statistics
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


REPO_ROOT = Path(sys.argv[1]).resolve()
CTX_BIN = Path(sys.argv[2]).resolve()
QUERY_FILE = Path(sys.argv[3]).resolve()


class BenchError(Exception):
    pass


def env_int(name: str, default: int, minimum: int = 1) -> int:
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        value = int(raw)
    except ValueError as exc:
        raise BenchError(f"{name} must be an integer, got {raw!r}") from exc
    if value < minimum:
        raise BenchError(f"{name} must be at least {minimum}, got {value}")
    return value


def env_flag(name: str, default: bool = False) -> bool:
    raw = os.environ.get(name)
    if raw is None:
        return default
    return raw.strip().lower() not in {"", "0", "false", "no", "off"}


def round2(value: float) -> float:
    return round(value, 2)


def percentile(sorted_samples: list[float], pct: float) -> float:
    if not sorted_samples:
        raise BenchError("cannot compute percentile for empty samples")
    index = math.ceil((len(sorted_samples) - 1) * (pct / 100.0))
    return sorted_samples[min(index, len(sorted_samples) - 1)]


def timing_stats(samples: list[float]) -> dict[str, Any]:
    sorted_samples = sorted(samples)
    return {
        "sample_count": len(samples),
        "samples_ms": [round2(sample) for sample in samples],
        "mean_ms": round2(statistics.fmean(samples)),
        "p50_ms": round2(percentile(sorted_samples, 50.0)),
        "p95_ms": round2(percentile(sorted_samples, 95.0)),
        "min_ms": round2(sorted_samples[0]),
        "max_ms": round2(sorted_samples[-1]),
    }


def command_env() -> dict[str, str]:
    env = os.environ.copy()
    env["CTX_ANALYTICS_OFF"] = "1"
    if not env_flag("CTX_REAL_SEARCH_BENCH_KEEP_CODEX_THREAD"):
        env.pop("CODEX_THREAD_ID", None)
    return env


def append_filters(args: list[str], filters: dict[str, Any]) -> list[str]:
    args = list(args)
    for key in ["provider", "repo", "since", "event_type", "file"]:
        value = filters.get(key)
        if value:
            flag = "--event-type" if key == "event_type" else f"--{key.replace('_', '-')}"
            args.extend([flag, str(value)])
    for key in ["primary_only", "include_subagents", "include_current_session"]:
        if filters.get(key):
            args.append(f"--{key.replace('_', '-')}")
    return args


def run_ctx(args: list[str], env: dict[str, str]) -> tuple[float, dict[str, Any]]:
    timeout_seconds = float(os.environ.get("CTX_REAL_SEARCH_BENCH_TIMEOUT_SECONDS", "5"))
    started = time.perf_counter()
    try:
        completed = subprocess.run(
            [str(CTX_BIN), *args],
            cwd=REPO_ROOT,
            env=env,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout_seconds,
        )
    except subprocess.TimeoutExpired as exc:
        raise BenchError(
            "ctx command timed out\n"
            f"command: {' '.join([str(CTX_BIN), *args])}\n"
            f"timeout_seconds: {timeout_seconds}"
        ) from exc
    elapsed_ms = (time.perf_counter() - started) * 1000.0
    if completed.returncode != 0:
        raise BenchError(
            "ctx command failed\n"
            f"command: {' '.join([str(CTX_BIN), *args])}\n"
            f"exit: {completed.returncode}\n"
            f"stdout:\n{completed.stdout}\n"
            f"stderr:\n{completed.stderr}"
        )
    try:
        packet = json.loads(completed.stdout)
    except json.JSONDecodeError as exc:
        raise BenchError(
            f"ctx command did not return JSON: {' '.join([str(CTX_BIN), *args])}\n"
            f"{completed.stdout}"
        ) from exc
    return elapsed_ms, packet


def truncate(value: Any, limit: int = 260) -> str:
    text = "" if value is None else str(value)
    text = " ".join(text.split())
    if len(text) > limit:
        return text[: limit - 3] + "..."
    return text


def top_search_results(packet: dict[str, Any], limit: int) -> list[dict[str, Any]]:
    results = []
    for item in packet.get("results", [])[:limit]:
        results.append(
            {
                "title": item.get("title"),
                "snippet": truncate(item.get("snippet")),
                "ctx_session_id": item.get("ctx_session_id"),
                "ctx_event_id": item.get("ctx_event_id"),
                "rank": item.get("rank"),
                "result_scope": item.get("result_scope"),
                "more_matches_in_session": item.get("more_matches_in_session"),
                "session_importance": item.get("session_importance"),
                "source_exists": item.get("source_exists"),
                "why_matched": item.get("why_matched"),
                "next": (item.get("suggested_next_commands") or [None])[0],
            }
        )
    return results


def top_research_results(packet: dict[str, Any], limit: int) -> list[dict[str, Any]]:
    results = []
    for item in packet.get("read_next", [])[:limit]:
        top_event = (item.get("top_events") or [{}])[0]
        results.append(
            {
                "title": item.get("title"),
                "snippet": truncate((item.get("snippets") or [None])[0]),
                "ctx_session_id": item.get("ctx_session_id"),
                "ctx_event_id": top_event.get("ctx_event_id"),
                "importance": item.get("importance"),
                "matched_events": item.get("matched_events"),
                "why": item.get("why"),
                "next": (item.get("suggested_next_commands") or [None])[0],
            }
        )
    return results


def session_ids(results: list[dict[str, Any]]) -> list[str]:
    ids = []
    for item in results:
        session_id = item.get("ctx_session_id")
        if isinstance(session_id, str) and session_id and session_id not in ids:
            ids.append(session_id)
    return ids


def mode_command(mode: str, query: str, filters: dict[str, Any], limit: int) -> list[str]:
    if mode == "search":
        base = ["search", query, "--refresh", "off", "--json", "--limit", str(limit)]
    elif mode == "research":
        base = ["research", query, "--refresh", "off", "--json", "--limit", str(limit)]
    else:
        raise BenchError(f"unknown mode {mode}")
    return append_filters(base, filters)


def run_mode(
    mode: str,
    query: str,
    filters: dict[str, Any],
    repeats: int,
    limit: int,
    env: dict[str, str],
) -> dict[str, Any]:
    timings = []
    last_packet: dict[str, Any] | None = None
    command = mode_command(mode, query, filters, limit)
    for _ in range(repeats):
        elapsed_ms, packet = run_ctx(command, env)
        timings.append(elapsed_ms)
        last_packet = packet
    assert last_packet is not None
    if mode == "search":
        top = top_search_results(last_packet, limit)
        count = len(last_packet.get("results", []))
    else:
        top = top_research_results(last_packet, limit)
        count = len(last_packet.get("read_next", []))
    return {
        "mode": mode,
        "command": " ".join([str(CTX_BIN), *command]),
        "timings": timing_stats(timings),
        "result_count": count,
        "session_ids": session_ids(top),
        "top_results": top,
        "packet_summary": {
            "freshness": last_packet.get("freshness"),
            "query_variants": last_packet.get("query_variants"),
            "summary": last_packet.get("summary"),
            "truncation": last_packet.get("truncation"),
        },
    }


def merge_filters(defaults: dict[str, Any], query_filters: dict[str, Any]) -> dict[str, Any]:
    merged = dict(defaults)
    for key, value in query_filters.items():
        if value is None:
            merged.pop(key, None)
        else:
            merged[key] = value
    return merged


def markdown_escape(value: Any) -> str:
    text = truncate(value, 180)
    return text.replace("|", "\\|")


def write_review_markdown(path: Path, artifact: dict[str, Any]) -> None:
    lines = [
        "# ctx Real Search Quality Review",
        "",
        f"Generated: {artifact['generated_at']}",
        f"Query file: `{artifact['query_file']}`",
        f"Binary: `{artifact['binary']['path']}`",
        "",
        "Fill the judgment columns manually or with an agent review pass.",
        "",
        "| Query | Intent | Mode | p95 ms | Count | Top Result | Top Session | Judgment | Notes |",
        "| --- | --- | ---: | ---: | ---: | --- | --- | --- | --- |",
    ]
    for query in artifact["queries"]:
        for mode in query["modes"]:
            top = (mode["top_results"] or [{}])[0]
            lines.append(
                "| {query} | {intent} | {mode} | {p95} | {count} | {top} | {session} |  |  |".format(
                    query=markdown_escape(query["query"]),
                    intent=markdown_escape(query["intent_type"]),
                    mode=mode["mode"],
                    p95=mode["timings"]["p95_ms"],
                    count=mode["result_count"],
                    top=markdown_escape(top.get("title") or top.get("snippet")),
                    session=markdown_escape(top.get("ctx_session_id")),
                )
            )
    lines.extend(
        [
            "",
            "Suggested judgment values:",
            "",
            "- `good`: top result or read-next path is clearly useful.",
            "- `partial`: useful material appears, but not in the first result or with notable noise.",
            "- `bad`: top results are misleading or miss the intended prior work.",
            "- `control-ok`: no-result/noisy-control behavior is acceptable.",
        ]
    )
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_judge_csv(path: Path, artifact: dict[str, Any]) -> None:
    fields = [
        "run_id",
        "git_rev",
        "corpus_id",
        "query_id",
        "intent_class",
        "query",
        "filters_json",
        "strategy",
        "rank",
        "latency_p95_ms",
        "subquery_count",
        "expanded_terms",
        "ctx_session_id",
        "ctx_event_id",
        "title",
        "snippet",
        "why_matched",
        "more_matches_in_session",
        "source_exists",
        "relevance_0_3",
        "support_0_2",
        "noise_0_2",
        "failure_code",
        "judge_notes",
    ]
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for query in artifact["queries"]:
            for mode in query["modes"]:
                strategy = mode["mode"]
                subquery_count = 1
                expanded_terms = ""
                if strategy == "research":
                    variants = mode.get("packet_summary", {}).get("query_variants") or []
                    subquery_count = len(variants) or ""
                    expanded_terms = " ".join(variants)
                for rank, item in enumerate(mode["top_results"], start=1):
                    writer.writerow(
                        {
                            "run_id": artifact["run_id"],
                            "git_rev": artifact["git_rev"],
                            "corpus_id": artifact["corpus_id"],
                            "query_id": query["id"],
                            "intent_class": query["intent_type"],
                            "query": query["query"],
                            "filters_json": json.dumps(query["filters"], sort_keys=True),
                            "strategy": strategy,
                            "rank": rank,
                            "latency_p95_ms": mode["timings"]["p95_ms"],
                            "subquery_count": subquery_count,
                            "expanded_terms": expanded_terms,
                            "ctx_session_id": item.get("ctx_session_id"),
                            "ctx_event_id": item.get("ctx_event_id"),
                            "title": item.get("title"),
                            "snippet": item.get("snippet"),
                            "why_matched": json.dumps(item.get("why") or item.get("why_matched") or []),
                            "more_matches_in_session": item.get("more_matches_in_session"),
                            "source_exists": item.get("source_exists"),
                            "relevance_0_3": "",
                            "support_0_2": "",
                            "noise_0_2": "",
                            "failure_code": "",
                            "judge_notes": "",
                        }
                    )


def main() -> int:
    repeats = env_int("CTX_REAL_SEARCH_BENCH_REPEATS", 3)
    limit = env_int("CTX_REAL_SEARCH_BENCH_LIMIT", 5)
    artifact_dir = Path(
        os.environ.get(
            "CTX_REAL_SEARCH_BENCH_ARTIFACT_DIR",
            REPO_ROOT / "target" / "ctx-artifacts" / "real-search-quality",
        )
    )
    artifact_dir.mkdir(parents=True, exist_ok=True)
    manifest = json.loads(QUERY_FILE.read_text(encoding="utf-8"))
    default_filters = manifest.get("default_filters") or {}
    queries = manifest.get("queries") or []
    if not queries:
        raise BenchError("query manifest has no queries")
    env = command_env()
    version = subprocess.run(
        [str(CTX_BIN), "--version"],
        cwd=REPO_ROOT,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=True,
    ).stdout.strip()
    git_rev = subprocess.run(
        ["git", "rev-parse", "--short=12", "HEAD"],
        cwd=REPO_ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        check=False,
    ).stdout.strip()

    status_elapsed, status_packet = run_ctx(["status", "--json"], env)
    if not status_packet.get("initialized"):
        raise BenchError("ctx status reports the local index is not initialized")

    artifact: dict[str, Any] = {
        "schema_version": 1,
        "profile": "ctx-real-search-quality",
        "run_id": dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ"),
        "git_rev": git_rev,
        "corpus_id": str(status_packet.get("database_path")),
        "generated_at": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
        "query_file": str(QUERY_FILE),
        "binary": {
            "path": str(CTX_BIN),
            "version": version,
        },
        "settings": {
            "repeats": repeats,
            "limit": limit,
            "modes": ["search", "research"],
            "refresh": "off",
            "keep_codex_thread": env_flag("CTX_REAL_SEARCH_BENCH_KEEP_CODEX_THREAD"),
        },
        "status": {
            "duration_ms": round2(status_elapsed),
            "indexed_items": status_packet.get("indexed_items"),
            "cataloged_sessions": status_packet.get("cataloged_sessions"),
            "database_path": status_packet.get("database_path"),
        },
        "queries": [],
    }

    for index, query_spec in enumerate(queries, start=1):
        query = query_spec["query"]
        filters = merge_filters(default_filters, query_spec.get("filters") or {})
        print(f"[{index}/{len(queries)}] {query}", flush=True)
        modes = [
            run_mode("search", query, filters, repeats, limit, env),
            run_mode("research", query, filters, repeats, limit, env),
        ]
        search_sessions = set(modes[0]["session_ids"])
        research_sessions = set(modes[1]["session_ids"])
        artifact["queries"].append(
            {
                "id": query_spec.get("id"),
                "query": query,
                "intent_type": query_spec.get("intent_type"),
                "why_it_matters": query_spec.get("why_it_matters"),
                "expected_quality_signal": query_spec.get("expected_quality_signal"),
                "filters": filters,
                "modes": modes,
                "comparison": {
                    "top_session_same": (
                        (modes[0]["session_ids"] or [None])[0]
                        == (modes[1]["session_ids"] or [None])[0]
                    ),
                    "session_overlap_count": len(search_sessions & research_sessions),
                    "research_p95_over_search_p95": round2(
                        modes[1]["timings"]["p95_ms"] / max(modes[0]["timings"]["p95_ms"], 1.0)
                    ),
                },
                "judgment": {
                    "search": None,
                    "research": None,
                    "winner": None,
                    "notes": None,
                },
            }
        )

    json_path = artifact_dir / "real-search-quality.json"
    md_path = artifact_dir / "real-search-quality-review.md"
    csv_path = artifact_dir / "real-search-quality-judge.csv"
    json_path.write_text(json.dumps(artifact, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    write_review_markdown(md_path, artifact)
    write_judge_csv(csv_path, artifact)

    search_p95s = [q["modes"][0]["timings"]["p95_ms"] for q in artifact["queries"]]
    research_p95s = [q["modes"][1]["timings"]["p95_ms"] for q in artifact["queries"]]
    ratios = [q["comparison"]["research_p95_over_search_p95"] for q in artifact["queries"]]
    print(f"artifact_json={json_path}")
    print(f"artifact_review={md_path}")
    print(f"artifact_judge_csv={csv_path}")
    print(f"queries={len(artifact['queries'])}")
    print(f"search_p95_median_ms={round2(statistics.median(search_p95s))}")
    print(f"research_p95_median_ms={round2(statistics.median(research_p95s))}")
    print(f"research_over_search_ratio_median={round2(statistics.median(ratios))}")
    return 0


try:
    raise SystemExit(main())
except BenchError as exc:
    print(f"real search quality benchmark failed: {exc}", file=sys.stderr)
    raise SystemExit(1)
PY
