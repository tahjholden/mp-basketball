import path from 'path';
import { runWorkflow } from './n8nRunner';

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

describe('workflow example', () => {
  const wfPath = path.join(__dirname, '..', 'workflows', 'mpos-basketball.json');

  test('runs exported workflow', async () => {
    runMock.mockResolvedValue({ ok: true });
    const result = await runWorkflow(wfPath);
    expect(runMock).toHaveBeenCalled();
    expect(result).toEqual({ ok: true });
  });
});
