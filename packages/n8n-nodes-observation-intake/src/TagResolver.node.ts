import type { IExecuteFunctions, INodeExecutionData, INodeType, INodeTypeDescription } from '@n8n/workflow';

function extractTags(text: string, tags: string[]): string[] {
  const lower = text.toLowerCase();
  return tags.filter((t) => lower.includes(t.toLowerCase()));
}

export class TagResolver implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'Tag Resolver',
    name: 'tagResolver',
    group: ['transform'],
    version: 1,
    description: 'Resolve tags from text',
    defaults: {
      name: 'Tag Resolver',
    },
    inputs: ['main'],
    outputs: ['main'],
    properties: [
      {
        displayName: 'Text Field',
        name: 'field',
        type: 'string',
        default: 'normalized',
        description: 'Field containing the text to tag',
      },
      {
        displayName: 'Tag Bank',
        name: 'tagBank',
        type: 'string',
        default: '',
        description: 'Comma separated list of tags',
      },
    ],
  };

  async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
    const items = this.getInputData();
    const returnData: INodeExecutionData[] = [];

    const field = this.getNodeParameter('field', 0) as string;
    const tagBankParam = this.getNodeParameter('tagBank', 0) as string;
    const tagBank = tagBankParam.split(',').map((t) => t.trim()).filter(Boolean);

    for (let i = 0; i < items.length; i++) {
      const item = { ...items[i] };
      const text = (item.json as any)[field];
      if (typeof text === 'string') {
        const tags = extractTags(text, tagBank);
        item.json.tagged_skills = tags;
        item.json.tagged_constraints = [];
        item.json.tagged = true;
      }
      returnData.push(item);
    }

    return [returnData];
  }
}
