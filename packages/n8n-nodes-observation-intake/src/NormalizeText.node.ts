import { IExecuteFunctions } from 'n8n-core';
import { INodeExecutionData, INodeType, INodeTypeDescription } from 'n8n-workflow';

export class NormalizeText implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'Normalize Text',
    name: 'normalizeText',
    group: ['transform'],
    version: 1,
    description: 'Normalize observation text',
    defaults: {
      name: 'Normalize Text',
    },
    inputs: ['main'],
    outputs: ['main'],
    properties: [
      {
        displayName: 'Field Name',
        name: 'field',
        type: 'string',
        default: 'raw_note',
        description: 'Name of the text field to normalize',
      },
    ],
  };

  async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
    const items = this.getInputData();
    const returnData: INodeExecutionData[] = [];

    const field = this.getNodeParameter('field', 0) as string;

    for (let i = 0; i < items.length; i++) {
      const item = { ...items[i] };
      const text = (item.json as any)[field] as string | undefined;
      if (typeof text === 'string') {
        const normalized = text.replace(/\s+/g, ' ').trim();
        item.json.normalized = normalized;
      }
      returnData.push(item);
    }

    return [returnData];
  }
}
