import argparse
import difflib
import os
import subprocess
from datetime import datetime
from pathlib import Path


def dump_remote_schema(db_url: str) -> str:
    """Dump the live database schema using pg_dump."""
    result = subprocess.run(
        ["pg_dump", "--schema-only", "--no-owner", db_url],
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout


def load_local_schema(migrations_dir: Path) -> str:
    """Concatenate all SQL migrations into a single text blob."""
    parts: list[str] = []
    for path in sorted(migrations_dir.glob("*.sql")):
        parts.append(f"-- {path.name}")
        parts.append(path.read_text(encoding="utf-8"))
    return "\n".join(parts)


def unified_diff(local: str, remote: str) -> str:
    """Return unified diff between local and remote schemas."""
    local_lines = local.splitlines()
    remote_lines = remote.splitlines()
    diff = difflib.unified_diff(
        local_lines,
        remote_lines,
        fromfile="migrations",
        tofile="live-db",
        lineterm="",
    )
    return "\n".join(diff)


def html_diff(local: str, remote: str) -> str:
    """Return an HTML side-by-side diff."""
    differ = difflib.HtmlDiff()
    return differ.make_file(
        local.splitlines(), remote.splitlines(), "migrations", "live-db"
    )


def propose_migration_name(migrations_dir: Path) -> str:
    """Suggest a filename for the next migration."""
    files = sorted(migrations_dir.glob("*.sql"))
    if files:
        last = files[-1].stem.split("_", 1)[0]
        try:
            number = int(last)
        except ValueError:
            number = len(files)
        next_num = f"{number + 1:03d}"
    else:
        next_num = "001"
    timestamp = datetime.utcnow().strftime("%Y%m%d%H%M%S")
    return f"{next_num}_auto_{timestamp}.sql"


def main() -> None:
    parser = argparse.ArgumentParser(description="Compare migrations with live DB")
    parser.add_argument("--db-url", required=True, help="Postgres connection string")
    parser.add_argument(
        "--migrations-dir",
        type=Path,
        default=Path("supabase/migrations"),
        help="Directory containing SQL migrations",
    )
    parser.add_argument(
        "--html",
        type=Path,
        help="Write HTML side-by-side diff to this file",
    )
    args = parser.parse_args()

    remote = dump_remote_schema(args.db_url)
    local = load_local_schema(args.migrations_dir)

    text_diff = unified_diff(local, remote)
    print(text_diff)

    if args.html:
        args.html.write_text(html_diff(local, remote), encoding="utf-8")
        print(f"HTML diff written to {args.html}")

    print(f"Proposed next migration file: {propose_migration_name(args.migrations_dir)}")


if __name__ == "__main__":
    main()
