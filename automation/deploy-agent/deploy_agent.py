import argparse
import json
import logging
import os
import subprocess
import sys


def validate_sql(path: str) -> None:
    if not path.endswith('.sql'):
        raise ValueError(f"Not an SQL file: {path}")
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    with open(path, 'r', encoding='utf-8') as f:
        contents = f.read()
    if not contents.strip():
        raise ValueError(f"SQL file is empty: {path}")


def validate_json(path: str) -> None:
    if not path.endswith('.json'):
        raise ValueError(f"Not a JSON file: {path}")
    if not os.path.isfile(path):
        raise FileNotFoundError(path)
    with open(path, 'r', encoding='utf-8') as f:
        json.load(f)


def run_command(cmd: list, env: dict) -> None:
    logging.info("Running %s", " ".join(cmd))
    subprocess.run(cmd, check=True, env=env)


def main() -> int:
    parser = argparse.ArgumentParser(description="Deploy Agent")
    parser.add_argument("--db-url", required=True, help="Postgres connection string")
    parser.add_argument("--sql", nargs="+", required=True, help="SQL migration files")
    parser.add_argument("--workflow", nargs="+", required=True, help="n8n workflow JSON files")
    parser.add_argument("--supabase-token", help="Supabase access token")
    parser.add_argument("--log-file", default="deploy.log")
    args = parser.parse_args()

    logging.basicConfig(
        filename=args.log_file,
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(logging.Formatter("%(levelname)s: %(message)s"))
    logging.getLogger('').addHandler(console)

    try:
        for sql in args.sql:
            validate_sql(sql)
        for wf in args.workflow:
            validate_json(wf)
    except Exception as exc:
        logging.error("Validation failed: %s", exc)
        return 1

    env = os.environ.copy()
    env['SUPABASE_DB_URL'] = args.db_url
    if args.supabase_token:
        env['SUPABASE_ACCESS_TOKEN'] = args.supabase_token

    try:
        run_command(['supabase', 'db', 'push'], env)
    except subprocess.CalledProcessError as exc:
        logging.error("Database push failed: %s", exc)
        return 1

    for wf in args.workflow:
        try:
            run_command(['n8n', 'import:workflow', '--input', wf], env)
        except subprocess.CalledProcessError as exc:
            logging.error("Workflow import failed (%s): %s", wf, exc)
            return 1

    logging.info("Deployment completed successfully")
    return 0


if __name__ == "__main__":
    sys.exit(main())
