const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

/** Helper to write JSON to a temp file and return the path */
function writeTempJson(obj, dir, name) {
  const file = path.join(dir, name);
  fs.writeFileSync(file, JSON.stringify(obj, null, 2));
  return file;
}

describe('parametrize_workflow.js integration', () => {
  test('replaces supabase details using config and env vars', () => {
    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'mpb-'));

    // Minimal workflow with placeholders
    const workflow = {
      nodes: [
        { parameters: { url: 'https://old.supabase.co/rest/v1/table' } },
        { credentials: { supabaseApi: { id: 'oldCred' } } },
      ],
    };
    const workflowPath = writeTempJson(workflow, tmpDir, 'workflow.json');

    // Config file will provide the new URL
    const config = { supabaseUrl: 'https://cli.supabase.co' };
    const configPath = writeTempJson(config, tmpDir, 'config.json');

    const env = {
      ...process.env,
      SUPABASE_CREDENTIAL_ID: 'credEnv',
    };

    const result = spawnSync(
      'node',
      ['scripts/parametrize_workflow.js', '--workflow', workflowPath, '--config', configPath],
      { encoding: 'utf8', env }
    );

    expect(result.status).toBe(0);
    const output = JSON.parse(result.stdout);
    expect(output.nodes[0].parameters.url).toBe('https://cli.supabase.co/rest/v1/table');
    expect(output.nodes[1].credentials.supabaseApi.id).toBe('credEnv');
  });
});
