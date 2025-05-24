const { execSync } = require('child_process');
const path = require('path');

function runWorkflow(workflowFile, env = {}) {
  const filePath = path.resolve(workflowFile);
  execSync(`n8n execute --file ${filePath}`, {
    stdio: 'inherit',
    env: { ...process.env, ...env },
  });
}

module.exports = { runWorkflow };
