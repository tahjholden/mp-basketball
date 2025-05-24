const { parseArgs, traverse } = require('../scripts/parametrize_workflow');

describe('parseArgs', () => {
  test('parses flags with values', () => {
    const argv = ['node', 'script', '--workflow', 'file.json', '--config', 'cfg.json'];
    const result = parseArgs(argv);
    expect(result).toEqual({ workflow: 'file.json', config: 'cfg.json' });
  });

  test('parses boolean flags without values', () => {
    const argv = ['node', 'script', '--dry-run', '--workflow', 'wf.json'];
    const result = parseArgs(argv);
    expect(result).toEqual({ 'dry-run': true, workflow: 'wf.json' });
  });
});

describe('traverse', () => {
  test('updates supabase url and credential id in workflow', () => {
    const workflow = {
      nodes: [
        { parameters: { url: 'https://old.supabase.co/rest/v1' } },
        { credentials: { supabaseApi: { id: 'oldId' } } },
      ],
    };
    const config = { supabaseUrl: 'https://new.supabase.co', supabaseCredentialId: 'newId' };
    traverse(workflow, config);
    expect(workflow.nodes[0].parameters.url).toBe('https://new.supabase.co/rest/v1');
    expect(workflow.nodes[1].credentials.supabaseApi.id).toBe('newId');
  });
});
