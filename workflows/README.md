# Workflows

This folder contains exported n8n workflows used by the MPB project. Each JSON file can be imported into n8n to recreate the automation.

- **file-chat-agent.json** – workflow for the File Chat agent.
- **mpos-basketball.json** – demo workflow for MPOS Basketball.
- **observation-intake-tagging-agent.json** – tags observation data automatically.
- **pdp-agent.json** – updates Personal Development Plans when events occur.
- **practice-planner-agent.json** – builds practice plans from routines.
- **session-plan-generator.json** – generates a session plan.

## Importing workflows

Start your n8n instance and in the editor choose **Import from File** for any of the JSON files. The same can be done from the command line:

```bash
n8n import:workflow --input <workflow file>
```

