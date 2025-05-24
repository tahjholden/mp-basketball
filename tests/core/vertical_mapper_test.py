import importlib
import sys
import types
from pathlib import Path
import tempfile
import textwrap

import pytest


def _yaml_stub():
    module = types.ModuleType("yaml")

    def safe_load(stream):
        text = stream.read()
        data: dict[str, dict[str, str]] = {}
        section = None
        for raw in text.splitlines():
            line = raw.rstrip()
            if not line:
                continue
            if line.startswith(" "):
                key, val = line.strip().split(":", 1)
                if section is not None:
                    data.setdefault(section, {})[key.strip()] = val.strip()
            else:
                section = line.rstrip(":")
                data[section] = {}
        return data

    module.safe_load = safe_load
    return module


@pytest.fixture
def vm(monkeypatch):
    monkeypatch.setitem(sys.modules, "yaml", _yaml_stub())
    tools_path = Path(__file__).resolve().parents[2] / "tools"
    monkeypatch.syspath_prepend(str(tools_path))
    module = importlib.import_module("vertical_mapper.vertical_mapper")
    return importlib.reload(module)


def test_load_mapping(vm, tmp_path):
    mapping_file = tmp_path / "map.yml"
    mapping_file.write_text(
        textwrap.dedent(
            """
            tables:
              old_table: new_table
            fields:
              old_field: new_field
            values:
              old_val: new_val
            """
        ),
        encoding="utf-8",
    )
    data = vm.load_mapping(mapping_file)
    assert data == {
        "tables": {"old_table": "new_table"},
        "fields": {"old_field": "new_field"},
        "values": {"old_val": "new_val"},
    }


def test_apply_replacements(vm):
    text = vm.apply_replacements("foo bar", {"foo": "baz", "": "noop"})
    assert text == "baz bar"


def test_transform_text(vm):
    mapping = {
        "tables": {"t1": "t2"},
        "fields": {"f1": "f2"},
        "values": {"v1": "v2"},
    }
    src = "select f1 from t1 where v='v1';"
    expected = "select f2 from t2 where v='v2';"
    assert vm.transform_text(src, mapping) == expected


def test_transform_directory(vm, tmp_path):
    sql_dir = tmp_path / "sql"
    wf_dir = tmp_path / "wf"
    dist_dir = tmp_path / "out"
    sql_dir.mkdir()
    wf_dir.mkdir()
    mapping_file = tmp_path / "map.yml"
    mapping_file.write_text(
        textwrap.dedent(
            """
            tables:
              t1: t2
            fields:
              f1: f2
            values:
              v1: v2
            """
        ),
        encoding="utf-8",
    )
    (sql_dir / "q.sql").write_text("select f1 from t1 where v='v1';", encoding="utf-8")
    (wf_dir / "w.json").write_text('{"q":"select f1 from t1 where v=\'v1\'"}', encoding="utf-8")

    vm.transform_directory(sql_dir, wf_dir, mapping_file, dist_dir)

    assert (dist_dir / "q.sql").read_text(encoding="utf-8") == "select f2 from t2 where v='v2';"
    assert (dist_dir / "w.json").read_text(encoding="utf-8") == '{"q":"select f2 from t2 where v=\'v2\'"}'

