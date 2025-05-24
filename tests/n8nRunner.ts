import { promises as fs } from 'fs';
import {
    Workflow,
    NodeTypes,
    IRun,
} from 'n8n-workflow';
import {
    CredentialsHelper,
    NodeExecuteFunctions,
    WorkflowExecute,
} from 'n8n-core';

/**
 * Loads an exported n8n workflow and executes it in-process.
 * Optional credentials can be provided which will be injected before running.
 *
 * The result from `WorkflowExecute.run()` is returned so tests can make
 * assertions about inserted rows or any other output data.
 */
export async function runWorkflow(
    workflowPath: string,
    credentials: Record<string, Record<string, unknown>> = {},
): Promise<IRun> {
    // Read and parse workflow JSON
    const raw = await fs.readFile(workflowPath, 'utf8');
    const workflowJson = JSON.parse(raw);

    // Build the workflow instance from its nodes and connections
    const nodeTypes = new NodeTypes();
    const workflow = new Workflow(
        {
            id: workflowJson.id ?? 'test',
            name: workflowJson.name ?? 'workflow',
            nodes: workflowJson.nodes,
            connections: workflowJson.connections,
            active: false,
        },
        nodeTypes,
    );

    // Inject credentials for nodes if provided
    const credentialsHelper = new CredentialsHelper(credentials, '', nodeTypes);

    const additionalData = {
        credentialsHelper,
        timezone: 'UTC',
        executionMode: 'manual',
        hooks: {},
    } as any;

    const workflowExecute = new WorkflowExecute(additionalData, workflow);
    return workflowExecute.run();
}
