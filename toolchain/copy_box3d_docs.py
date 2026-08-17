#!/usr/bin/env python3
"""Copy Doxygen comments from Box3D C headers into translate-c Zig output."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


DOC_LINE = re.compile(r"^\s*///<?\s?(.*)$")
IDENT = r"[A-Za-z_]\w*"


def clean_block(lines: list[str]) -> list[str]:
    result: list[str] = []
    for line in lines:
        text = re.sub(r"^\s*/\*\*<?", "", line)
        text = re.sub(r"\*/\s*$", "", text)
        text = re.sub(r"^\s*\*\s?", "", text).rstrip()
        result.append(text)
    while result and not result[0]:
        result.pop(0)
    while result and not result[-1]:
        result.pop()
    return result


def usable_doc(lines: list[str]) -> list[str]:
    """Exclude Doxygen group containers, which document sections, not symbols."""
    if any(re.search(r"@(defgroup|addtogroup|name)\b", line) for line in lines):
        return []
    if lines and all(line.strip() in {"@{", "@}"} for line in lines):
        return []
    return lines


def declaration_name(text: str) -> str | None:
    """Return the public name defined by a top-level C declaration."""
    match = re.search(r"\btypedef\s+(?:struct|union|enum)\s+(%s)\b" % IDENT, text)
    if match:
        return match.group(1)
    match = re.search(r"\btypedef\b.*?\b(%s)\s*\(" % IDENT, text, re.S)
    if match:
        return match.group(1)
    match = re.search(r"\b(b3\w+)\s*\(", text)
    if match:
        return match.group(1)
    match = re.search(r"^\s*#define\s+(B3_\w+)", text)
    return match.group(1) if match else None


def member_name(text: str) -> str | None:
    text = re.sub(r"///<.*$", "", text).strip()
    if not text or text.startswith("#") or "(" in text:
        return None
    match = re.search(r"\b(%s)\s*(?:\[[^]]*\])?\s*(?:=[^,}]*)?[,;}]?\s*$" % IDENT, text)
    return match.group(1) if match else None


def extract_docs(headers: list[Path]) -> tuple[dict[str, list[str]], dict[tuple[str, str], list[str]]]:
    symbols: dict[str, list[str]] = {}
    members: dict[tuple[str, str], list[str]] = {}

    for header in headers:
        lines = header.read_text(encoding="utf-8").splitlines()
        pending: list[str] = []
        block: list[str] = []
        in_block = False
        aggregate: str | None = None
        aggregate_kind: str | None = None
        depth = 0
        function_depth = 0
        declaration = ""

        for raw in lines:
            stripped = raw.strip()
            if in_block:
                block.append(raw)
                if "*/" in raw:
                    pending = usable_doc(clean_block(block))
                    block = []
                    in_block = False
                continue
            if stripped.startswith("/**"):
                block = [raw]
                if "*/" in stripped[3:]:
                    pending = usable_doc(clean_block(block))
                    block = []
                else:
                    in_block = True
                continue
            line_doc = DOC_LINE.match(raw)
            if line_doc:
                pending.append(line_doc.group(1).rstrip())
                continue

            trailing = re.search(r"///<\s?(.*)$", raw)
            code = re.sub(r"///<.*$", "", raw)

            if function_depth:
                function_depth += code.count("{") - code.count("}")
                continue

            if aggregate is not None:
                if depth == 1 and (";" in code or aggregate_kind == "enum" and "," in code):
                    name = member_name(code)
                    doc = pending or ([trailing.group(1).rstrip()] if trailing else [])
                    if name and doc:
                        members[(aggregate, name)] = doc
                        if aggregate_kind == "enum":
                            symbols[name] = doc
                    pending = []
                depth += code.count("{") - code.count("}")
                if depth <= 0:
                    aggregate = None
                    aggregate_kind = None
                    depth = 0
                continue

            if not stripped or stripped.startswith("//"):
                continue
            if stripped.startswith("#"):
                name = declaration_name(code)
                if name and pending:
                    symbols[name] = pending
                    pending = []
                declaration = ""
                continue
            declaration = (declaration + " " + code.strip()).strip()
            aggregate_match = re.search(r"\btypedef\s+(struct|union|enum)\s+%s\s*\{" % IDENT, declaration)
            if aggregate_match:
                name = declaration_name(declaration)
                if name:
                    if pending:
                        symbols[name] = pending
                    aggregate = name
                    aggregate_kind = aggregate_match.group(1)
                    depth = declaration.count("{") - declaration.count("}")
                pending = []
                declaration = ""
                continue
            if "(" in declaration and "{" in declaration:
                name = declaration_name(declaration)
                if name and pending:
                    symbols[name] = pending
                pending = []
                function_depth = declaration.count("{") - declaration.count("}")
                declaration = ""
                continue
            if ";" in declaration or (declaration.startswith("#define") and "\\" not in declaration):
                name = declaration_name(declaration)
                if name and pending:
                    symbols[name] = pending
                pending = []
                declaration = ""

    return symbols, members


def zig_docs(lines: list[str], indent: str) -> list[str]:
    return [f"{indent}///{(' ' + line) if line else ''}\n" for line in lines]


def annotate(
    source: str, symbols: dict[str, list[str]], members: dict[tuple[str, str], list[str]]
) -> tuple[str, set[str]]:
    output: list[str] = []
    matched_symbols: set[str] = set()
    aggregate: str | None = None
    depth = 0

    for line in source.splitlines(keepends=True):
        type_start = re.match(r"^(\s*)pub const struct_(b3\w+) = extern (?:struct|union) \{", line)
        if type_start:
            aggregate = type_start.group(2)
            depth = 1

        alias = re.match(r"^(\s*)pub const (b3\w+) = (?:struct_|union_|enum_)\2;", line)
        function = re.match(r"^(\s*)pub (?:(?:extern|inline) )?fn ((?:b3|B3_)\w+)\b", line)
        callback = re.match(r"^(\s*)pub const (b3\w+) = fn\b", line)
        constant = re.match(r"^(\s*)pub const ((?:b3|B3_)\w+)\s*(?::|=)", line)
        target = alias or function or callback or constant

        if aggregate and depth == 1:
            field = re.match(r"^(\s{4})([A-Za-z_]\w*):", line)
            if field:
                docs = members.get((aggregate, field.group(2)))
                if docs:
                    output.extend(zig_docs(docs, field.group(1)))
        if target:
            docs = symbols.get(target.group(2))
            if docs:
                output.extend(zig_docs(docs, target.group(1)))
                matched_symbols.add(target.group(2))

        output.append(line)
        if aggregate:
            depth += line.count("{") - line.count("}")
            if type_start:
                depth = 1
            elif depth <= 0:
                aggregate = None
                depth = 0

    return "".join(output), matched_symbols


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--headers", type=Path, required=True)
    parser.add_argument("--bindings", type=Path, required=True)
    args = parser.parse_args()

    headers = sorted(args.headers.glob("*.h"))
    if not headers:
        parser.error(f"no Box3D headers found in {args.headers}")
    symbols, members = extract_docs(headers)
    original = args.bindings.read_text(encoding="utf-8")
    # The input should be fresh translate-c output. This also makes reruns idempotent.
    if re.search(r"^\s*///", original, re.MULTILINE):
        parser.error(f"{args.bindings} already contains Zig documentation comments")
    result, matched_symbols = annotate(original, symbols, members)
    missing = sorted(symbols.keys() - matched_symbols)
    if missing:
        parser.error("documented C symbols missing from Zig output: " + ", ".join(missing))
    args.bindings.write_text(result, encoding="utf-8")
    print(
        f"documented Box3D bindings from {len(headers)} headers: "
        f"{len(matched_symbols)} symbols, {len(members)} members"
    )


if __name__ == "__main__":
    main()
