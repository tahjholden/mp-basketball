import { DBWriter } from '../src/DBWriter.node';
import type { IExecuteFunctions, INodeExecutionData } from '@n8n/workflow';

describe('DBWriter node', () => {
  test('sends items via httpRequest', async () => {
    const node = new DBWriter();
    const items: INodeExecutionData[] = [{ json: { id: 1, value: 'a' } } as any];

    const httpRequest = jest.fn().mockResolvedValue({});

    const context = {
      helpers: { httpRequest },
      getInputData: jest.fn().mockReturnValue(items),
      getNodeParameter: jest.fn((name: string) => {
        if (name === 'url') return 'https://example.com';
        if (name === 'method') return 'POST';
        return '';
      }),
    } as unknown as IExecuteFunctions;

    const result = await node.execute.call(context);
    expect(httpRequest).toHaveBeenCalledTimes(1);
    expect(httpRequest).toHaveBeenCalledWith({
      method: 'POST',
      url: 'https://example.com',
      body: items[0].json,
      json: true,
    });
    expect(result[0][0]).toEqual(items[0]);
  });
});
