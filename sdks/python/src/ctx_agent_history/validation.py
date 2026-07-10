"""SDK input validation helpers."""

from __future__ import annotations

from typing import Optional, Sequence

from .errors import CtxAgentHistoryValidationError


def validate_search_intent(
    *,
    query: Optional[str],
    terms: Optional[Sequence[str]],
    file: Optional[str],
) -> None:
    if _has_text(query) or _has_text(file) or _has_term(terms):
        return
    raise CtxAgentHistoryValidationError(
        "search requires a query, term, or file option",
        details={"query": query, "terms": _term_details(terms), "file": file},
    )


def _has_term(terms: Optional[Sequence[str]]) -> bool:
    if terms is None:
        return False
    if isinstance(terms, str):
        return _has_text(terms)
    return any(_has_text(term) for term in terms)


def _has_text(value: object) -> bool:
    return isinstance(value, str) and bool(value.strip())


def normalize_lookup_id(label: str, value: Optional[str]) -> str:
    if not isinstance(value, str):
        raise CtxAgentHistoryValidationError(f"{label} is required", details={"value": value})

    trimmed = value.strip()
    if not trimmed:
        raise CtxAgentHistoryValidationError(f"{label} is required", details={"value": value})
    return trimmed


def _term_details(terms: Optional[Sequence[str]]) -> list[str]:
    if terms is None:
        return []
    if isinstance(terms, str):
        return [terms]
    return list(terms)
