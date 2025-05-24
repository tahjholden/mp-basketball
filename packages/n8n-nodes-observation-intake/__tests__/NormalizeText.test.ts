import { NormalizeText } from '../src/NormalizeText.node';
import { IExecuteFunctions, INodeExecutionData } from 'n8n-core';

describe('NormalizeText node', () => {
  test('normalizes whitespace in configured field', async () => {
    const node = new NormalizeText();
    const items: INodeExecutionData[] = [{ json: { raw_note: '  hello   world ' } } as any];

    const context = {
      getInputData: jest.fn().mockReturnValue(items),
      getNodeParameter: jest.fn().mockReturnValue('raw_note'),
    } as unknown as IExecuteFunctions;

    const result = await node.execute.call(context);
    expect(result[0][0].json.normalized).toBe('hello world');
  });
});
