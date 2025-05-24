import json
import subprocess
import sys
from pathlib import Path

import pytest

# The deploy_agent module lives inside the "deploy-agent" directory which is not
# a valid Python package name. Add that directory to sys.path so the module can
# be imported by filename.
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "deploy-agent"))
import deploy_agent as da


def test_validate_sql_missing(tmp_path):
    path = tmp_path / "missing.sql"
    with pytest.raises(FileNotFoundError):
        da.validate_sql(str(path))


def test_validate_sql_empty(tmp_path):
    path = tmp_path / "empty.sql"
    path.write_text("")
    with pytest.raises(ValueError):
        da.validate_sql(str(path))


def test_validate_json_missing(tmp_path):
    path = tmp_path / "missing.json"
    with pytest.raises(FileNotFoundError):
        da.validate_json(str(path))


def test_validate_json_empty(tmp_path):
    path = tmp_path / "empty.json"
    path.write_text("")
    with pytest.raises(json.JSONDecodeError):
        da.validate_json(str(path))


def test_run_command_invokes_subprocess(monkeypatch):
    recorded = {}

    def fake_run(cmd, check, env):
        recorded['cmd'] = cmd
        recorded['check'] = check
        recorded['env'] = env

    monkeypatch.setattr(subprocess, 'run', fake_run)
    env = {'A': 'B'}
    da.run_command(['echo', 'hi'], env)
    assert recorded['cmd'] == ['echo', 'hi']
    assert recorded['check'] is True
    assert recorded['env'] == env


def test_main_validation_error(monkeypatch, tmp_path):
    monkeypatch.setattr(da, 'validate_sql', lambda path: (_ for _ in ()).throw(ValueError('bad')))
    monkeypatch.setattr(da, 'validate_json', lambda path: None)
    monkeypatch.setattr(da, 'run_command', lambda cmd, env: None)
    sql_file = tmp_path / 'a.sql'
    wf_file = tmp_path / 'wf.json'
    sql_file.write_text('select 1;')
    wf_file.write_text('{}')
    args = ['prog', '--db-url', 'pg://url', '--sql', str(sql_file), '--workflow', str(wf_file)]
    monkeypatch.setattr(sys, 'argv', args)
    assert da.main() == 1
