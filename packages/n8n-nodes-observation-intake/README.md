# n8n-nodes-observation-intake

Community nodes that encapsulate the Observation Intake workflow.

## Nodes

- **NormalizeText** – clean up raw note input and expose a `normalized` field.
- **TagResolver** – apply a tag bank to text and return `tagged_skills` and `tagged_constraints` arrays.
- **DBWriter** – insert or update data using an HTTP request (for example, Supabase REST API).

These nodes can replace the large Observation Intake workflow with compact, reusable steps.

## Development

Install dependencies and build the package:

```bash
npm install
npm run build
```

Place the compiled `dist` directory in your n8n custom nodes folder or publish the package to npm.
