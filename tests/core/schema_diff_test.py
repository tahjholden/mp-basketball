import datetime
import sys
from pathlib import Path
import subprocess

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from tools import schema_diff


def test_dump_remote_schema(monkeypatch):
    """dump_remote_schema should call pg_dump and return its output."""

    called = {}

    def fake_run(args, check, capture_output, text):
        called["args"] = args
        class Result:
            stdout = "remote-schema"
        return Result()

    monkeypatch.setattr(subprocess, "run", fake_run)

    result = schema_diff.dump_remote_schema("postgres://url")

    assert result == "remote-schema"
    assert called["args"] == ["pg_dump", "--schema-only", "--no-owner", "postgres://url"]


def test_load_local_schema_and_propose_name(tmp_path, monkeypatch):
    """load_local_schema concatenates SQL files and propose_migration_name increments numbers."""

    a = tmp_path / "001_init.sql"
    b = tmp_path / "002_more.sql"
    a.write_text("CREATE TABLE a;")
    b.write_text("ALTER TABLE a ADD COLUMN b INT;")

    expected = "-- 001_init.sql\nCREATE TABLE a;\n-- 002_more.sql\nALTER TABLE a ADD COLUMN b INT;"
    assert schema_diff.load_local_schema(tmp_path) == expected

    class FakeDateTime:
        @classmethod
        def utcnow(cls):
            return datetime.datetime(2023, 1, 2, 3, 4, 5)

    monkeypatch.setattr(schema_diff, "datetime", FakeDateTime)
    name = schema_diff.propose_migration_name(tmp_path)
    assert name == "003_auto_20230102030405.sql"


def test_diff_functions():
    """unified_diff and html_diff return comparisons in text and HTML form."""

    local = "A\nB\n"
    remote = "A\nC\n"

    diff = schema_diff.unified_diff(local, remote)
    assert diff.splitlines() == [
        "--- migrations",
        "+++ live-db",
        "@@ -1,2 +1,2 @@",
        " A",
        "-B",
        "+C",
    ]

    html = schema_diff.html_diff(local, remote)
    assert "<!DOCTYPE html" in html
    assert "B" in html and "C" in html
