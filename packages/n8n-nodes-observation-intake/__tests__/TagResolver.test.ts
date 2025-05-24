import { TagResolver } from '../src/TagResolver.node';
import { IExecuteFunctions, INodeExecutionData } from 'n8n-core';

describe('TagResolver node', () => {
  test('resolves tags from text', async () => {
    const node = new TagResolver();
    const items: INodeExecutionData[] = [{ json: { normalized: 'shooting dribble pass' } } as any];

    const context = {
      getInputData: jest.fn().mockReturnValue(items),
      getNodeParameter: jest.fn()
        .mockImplementation((name: string) => {
          if (name === 'field') return 'normalized';
          if (name === 'tagBank') return 'shooting,passing,dribble';
          return '';
        }),
    } as unknown as IExecuteFunctions;

    const result = await node.execute.call(context);
    expect(result[0][0].json.tagged_skills).toEqual(['shooting', 'dribble']);
    expect(result[0][0].json.tagged).toBe(true);
  });
});
