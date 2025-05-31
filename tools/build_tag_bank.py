import argparse
import csv
import json
import re
import subprocess
from pathlib import Path
from typing import Any, Dict, Iterable, List


DISPLAY_KEYS = {"display_name", "name", "tag_name", "Tag Name"}
CATEGORY_KEYS = {"category", "tag_type", "Tag Type", "tag_type"}
DESCRIPTION_KEYS = {"description", "Description"}
SYNONYM_KEYS = {"synonyms", "alias", "aliases", "Alias(es)"}
USE_CASE_KEYS = {"use_case", "pdp_group", "Use Case"}
ACTIVE_KEYS = {"is_active", "active", "verified"}
PARENT_KEYS = {"parent_tag_id", "tag_parent_id", "parent"}
LEGACY_KEYS = {"legacy_code", "uid", "UID"}


class TagRow(dict):
    """Dictionary subclass for a canonical tag row."""

    def merge(self, other: "TagRow") -> None:
        if len(other["description"]) > len(self["description"]):
            self["description"] = other["description"]
        self["synonyms"] = merge_values(self["synonyms"], other["synonyms"], ", ")
        self["use_case"] = merge_values(self["use_case"], other["use_case"], "; ")
        self["is_active"] = self["is_active"] and other["is_active"]
        if not self["parent_tag_id"]:
            self["parent_tag_id"] = other["parent_tag_id"]
        if not self["legacy_code"]:
            self["legacy_code"] = other["legacy_code"]
        elif other["legacy_code"] and other["legacy_code"] not in self["legacy_code"]:
            self["legacy_code"] += f";{other['legacy_code']}"

def merge_values(a: str, b: str, sep: str) -> str:
    parts = [p.strip() for p in filter(None, [a, b])]
    seen = []
    for p in parts:
        for item in p.split(sep.strip()):
            item = item.strip()
            if item and item not in seen:
                seen.append(item)
    return sep.join(seen)

def clone_or_pull(repo_url: str, dest: Path) -> None:
    if dest.exists():
        subprocess.run(["git", "-C", str(dest), "pull"], check=True)
    else:
        subprocess.run(["git", "clone", repo_url, str(dest)], check=True)

def parse_csv_file(path: Path) -> List[Dict[str, str]]:
    rows: List[Dict[str, str]] = []
    with path.open(newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            cleaned = {k.strip(): (v.strip() if isinstance(v, str) else v) for k, v in row.items()}
            rows.append(cleaned)
    return rows

def split_sql_values(values_blob: str) -> Iterable[str]:
    current = ""
    depth = 0
    in_quote = False
    for ch in values_blob:
        if ch == "'" and (not current.endswith("\\")):
            in_quote = not in_quote
        if ch == "(" and not in_quote:
            if depth == 0:
                current = ""
            depth += 1
            continue
        if ch == ")" and not in_quote:
            depth -= 1
            if depth == 0:
                yield current
            continue
        if depth > 0:
            current += ch

def parse_sql_file(path: Path) -> List[Dict[str, str]]:
    text = path.read_text(encoding="utf-8")
    matches = re.finditer(r"INSERT INTO[^()]+\(([^)]+)\)\s*VALUES\s*(.+?);", text, re.DOTALL | re.IGNORECASE)
    rows: List[Dict[str, str]] = []
    for m in matches:
        cols = [c.strip().strip('"') for c in m.group(1).split(',')]
        values_part = m.group(2)
        for tup in split_sql_values(values_part):
            reader = csv.reader([tup], skipinitialspace=True, quotechar="'", delimiter=',')
            values = next(reader)
            row = {cols[i]: values[i].strip() if i < len(values) else "" for i in range(len(cols))}
            rows.append(row)
    return rows

def parse_file(path: Path) -> List[Dict[str, str]]:
    try:
        if path.suffix.lower() == ".csv":
            return parse_csv_file(path)
        text = path.read_text(encoding="utf-8")
        if "INSERT INTO" in text:
            return parse_sql_file(path)
        # fallback to csv style
        return parse_csv_file(path)
    except Exception:
        return []

def map_row(raw: Dict[str, Any]) -> TagRow:
    def get(keys: set[str]) -> str:
        for key in keys:
            if key in raw and raw[key] not in {None, "", "NULL"}:
                return str(raw[key]).strip()
        return ""
    synonyms = parse_synonyms(get(SYNONYM_KEYS))
    row = TagRow(
        display_name=get(DISPLAY_KEYS),
        category=get(CATEGORY_KEYS),
        description=get(DESCRIPTION_KEYS),
        synonyms=", ".join(synonyms),
        use_case=get(USE_CASE_KEYS),
        is_active=parse_bool(get(ACTIVE_KEYS)),
        parent_tag_id=get(PARENT_KEYS),
        legacy_code=get(LEGACY_KEYS),
    )
    return row

def parse_bool(value: str) -> bool:
    if value.lower() in {"false", "0", "no"}:
        return False
    return True if value else True

def parse_synonyms(value: str) -> List[str]:
    if not value:
        return []
    value = value.strip()
    if value.startswith("["):
        try:
            arr = json.loads(value)
            return [str(v).strip() for v in arr]
        except json.JSONDecodeError:
            pass
    parts = re.split(r"[,;]", value)
    return [p.strip() for p in parts if p.strip()]

def build_tag_bank(paths: Iterable[Path]) -> tuple[List[TagRow], int]:
    merged: Dict[tuple[str, str], TagRow] = {}
    dropped = 0
    for path in paths:
        for raw in parse_file(path):
            row = map_row(raw)
            if not row["display_name"] or not row["category"] or not row["description"]:
                dropped += 1
                continue
            key = (row["display_name"].lower(), row["category"].lower())
            existing = merged.get(key)
            if existing:
                existing.merge(row)
            else:
                merged[key] = row
    return list(merged.values()), dropped

def write_csv(rows: List[TagRow], dest: Path) -> None:
    fieldnames = [
        "display_name",
        "category",
        "description",
        "synonyms",
        "use_case",
        "is_active",
        "parent_tag_id",
        "legacy_code",
    ]
    with dest.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)

def main() -> None:
    parser = argparse.ArgumentParser(description="Build canonical tag bank")
    parser.add_argument("repo_url", help="GitHub repository URL")
    parser.add_argument("dest", type=Path, help="Local clone directory")
    parser.add_argument(
        "--output",
        type=Path,
        default=Path("canonical_tag_bank.csv"),
        help="Output CSV file",
    )
    args = parser.parse_args()

    clone_or_pull(args.repo_url, args.dest)
    files = list(args.dest.rglob("*.csv")) + list(args.dest.rglob("*.txt")) + list(args.dest.rglob("*.sql"))
    rows, dropped = build_tag_bank(files)
    write_csv(rows, args.output)
    print(f"Processed {len(rows)} tags. Dropped {dropped} incomplete rows.")


if __name__ == "__main__":
    main()
