import { promises as fs } from 'fs';
import path from 'path';
import { runWorkflow } from '../n8nRunner';

// Mock the n8n packages so we do not need the real dependencies
const runMock = jest.fn();

jest.mock('n8n-workflow', () => {
  return {
    Workflow: class { constructor(public data: any) { this.data = data; } },
    NodeTypes: class {},
  };
});

jest.mock('n8n-core', () => {
  return {
    CredentialsHelper: class {},
    NodeExecuteFunctions: class {},
    WorkflowExecute: class {
      constructor(_data: any, _workflow: any) {}
      run = runMock;
    },
  };
});


describe('runWorkflow', () => {
  const wfPath = path.join(__dirname, 'minimal.workflow.json');

  beforeAll(async () => {
    const wf = { nodes: [], connections: {} };
    await fs.writeFile(wfPath, JSON.stringify(wf));
  });

  afterAll(async () => {
    await fs.unlink(wfPath);
  });

  test('executes workflow and returns result', async () => {
    runMock.mockResolvedValue({ success: true });
    const result = await runWorkflow(wfPath);
    expect(result).toEqual({ success: true });
  });
});
