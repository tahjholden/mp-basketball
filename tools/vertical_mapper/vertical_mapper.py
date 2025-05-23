import argparse
from pathlib import Path
from typing import Dict, Any


def load_mapping(path: Path) -> Dict[str, Any]:
    """Load a very small subset of YAML used for the mapping files."""
    mapping: Dict[str, Any] = {}
    current_section: Dict[str, str] | None = None
    with open(path, "r", encoding="utf-8") as f:
        for line in f:
            stripped = line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            if not line.startswith(" ") and stripped.endswith(":"):
                section_name = stripped[:-1]
                mapping[section_name] = {}
                current_section = mapping[section_name]
            elif current_section is not None and ":" in stripped:
                key, value = stripped.split(":", 1)
                current_section[key.strip()] = value.strip()
    return mapping


def apply_replacements(text: str, replacements: Dict[str, str]) -> str:
    """Replace all occurrences of keys in text with their mapped values."""
    for src, dst in replacements.items():
        if src:
            text = text.replace(src, dst)
    return text


def transform_text(text: str, mapping: Dict[str, Any]) -> str:
    """Apply tables, fields and value mappings to a text blob."""
    for key in ("tables", "fields", "values"):
        repl = mapping.get(key, {}) or {}
        text = apply_replacements(text, repl)
    return text


def transform_directory(sql_dir: Path, workflow_dir: Path, mapping_path: Path, dist_dir: Path) -> None:
    """Transform SQL and JSON files using the provided mapping."""
    mapping = load_mapping(mapping_path)
    dist_dir.mkdir(parents=True, exist_ok=True)

    for sql_file in sql_dir.glob("*.sql"):
        text = sql_file.read_text(encoding="utf-8")
        transformed = transform_text(text, mapping)
        (dist_dir / sql_file.name).write_text(transformed, encoding="utf-8")

    for json_file in workflow_dir.glob("*.json"):
        text = json_file.read_text(encoding="utf-8")
        transformed = transform_text(text, mapping)
        (dist_dir / json_file.name).write_text(transformed, encoding="utf-8")


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="Apply vertical mapping to SQL migrations and workflow JSON files.")
    parser.add_argument("--mapping", required=True, type=Path, help="Path to YAML mapping file")
    parser.add_argument("--sql-dir", default=Path("supabase/migrations"), type=Path, help="Directory containing SQL migration files")
    parser.add_argument("--workflow-dir", default=Path("workflows"), type=Path, help="Directory containing workflow JSON files")
    parser.add_argument("--dist-dir", required=True, type=Path, help="Directory to write transformed files")
    args = parser.parse_args(argv)

    transform_directory(args.sql_dir, args.workflow_dir, args.mapping, args.dist_dir)


if __name__ == "__main__":
    main()
