# Workflows

This folder contains exported n8n workflows used by the MPB project. Each JSON file can be imported into n8n to recreate the automation.

- **file-chat-agent.json** – workflow for the File Chat agent.
- **mpos-basketball.json** – demo workflow for MPOS Basketball.
- **daily-summary.json** – sends a reflection summary email each day.
- **observation-intake-tagging-agent.json** – tags observation data automatically.
- **pdp-agent.json** – updates Personal Development Plans when events occur.
- **practice-planner-agent.json** – builds practice plans from routines.
- **session-plan-generator.json** – generates a session plan.

## Importing workflows

Start your n8n instance and in the editor choose **Import from File** for any of the JSON files. The same can be done from the command line:

```bash
n8n import:workflow --input <workflow file>
```


## Required credentials

Several workflows connect to Supabase and OpenAI. Configure these credentials in n8n before running them:

- **Supabase** – create a credential named `supabaseApi` and set your project URL and service role key.
- **OpenAI** – provide your API key via an HTTP Request credential or set `OPENAI_API_KEY` in the environment.

When using `scripts/parametrize_workflow.js`, you can provide `SUPABASE_URL`, `SUPABASE_CREDENTIAL_ID` and `OPENAI_API_KEY` to rewrite placeholders in the exported JSON.
