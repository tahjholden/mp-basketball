import type { IExecuteFunctions, IDataObject, INodeExecutionData, INodeType, INodeTypeDescription } from '@n8n/workflow';

export class DBWriter implements INodeType {
  description: INodeTypeDescription = {
    displayName: 'DB Writer',
    name: 'dbWriter',
    group: ['output'],
    version: 1,
    description: 'Write items to a database via HTTP',
    defaults: {
      name: 'DB Writer',
    },
    inputs: ['main'],
    outputs: ['main'],
    properties: [
      {
        displayName: 'Endpoint URL',
        name: 'url',
        type: 'string',
        default: '',
        placeholder: 'https://example.com/rest/v1/observation',
      },
      {
        displayName: 'HTTP Method',
        name: 'method',
        type: 'options',
        options: [
          { name: 'POST', value: 'POST' },
          { name: 'PUT', value: 'PUT' },
          { name: 'PATCH', value: 'PATCH' },
        ],
        default: 'POST',
      },
    ],
  };

  async execute(this: IExecuteFunctions): Promise<INodeExecutionData[][]> {
    const items = this.getInputData();
    const returnData: INodeExecutionData[] = [];

    const url = this.getNodeParameter('url', 0) as string;
    const method = this.getNodeParameter('method', 0) as string;

    for (let i = 0; i < items.length; i++) {
      const data = items[i].json as IDataObject;
      await this.helpers.httpRequest({
        method,
        url,
        body: data,
        json: true,
      });
      returnData.push(items[i]);
    }

    return [returnData];
  }
}
