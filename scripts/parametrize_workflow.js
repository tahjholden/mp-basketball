#!/usr/bin/env node
const fs = require('fs');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith('--')) {
      const key = arg.slice(2);
      if (i + 1 < argv.length && !argv[i + 1].startsWith('--')) {
        args[key] = argv[i + 1];
        i++;
      } else {
        args[key] = true;
      }
    }
  }
  return args;
}

const args = parseArgs(process.argv);

if (!args.workflow) {
  console.error('Usage: node scripts/parametrize_workflow.js --workflow <file> [--config config.json] [--output file]');
  process.exit(1);
}

let config = {};
if (args.config) {
  config = JSON.parse(fs.readFileSync(args.config, 'utf8'));
}

if (process.env.SUPABASE_URL && !config.supabaseUrl) {
  config.supabaseUrl = process.env.SUPABASE_URL;
}
if (process.env.SUPABASE_CREDENTIAL_ID && !config.supabaseCredentialId) {
  config.supabaseCredentialId = process.env.SUPABASE_CREDENTIAL_ID;
}

const workflow = JSON.parse(fs.readFileSync(args.workflow, 'utf8'));

const urlRegex = /https?:\/\/[^/]*\.supabase\.co/g;

function traverse(node) {
  if (Array.isArray(node)) {
    node.forEach(traverse);
    return;
  }
  if (node && typeof node === 'object') {
    if (node.credentials && node.credentials.supabaseApi && node.credentials.supabaseApi.id && config.supabaseCredentialId) {
      node.credentials.supabaseApi.id = config.supabaseCredentialId;
    }
    for (const key of Object.keys(node)) {
      const val = node[key];
      if (typeof val === 'string') {
        if (config.supabaseUrl) {
          node[key] = val.replace(urlRegex, config.supabaseUrl);
        }
      } else {
        traverse(val);
      }
    }
  }
}

traverse(workflow);

const output = JSON.stringify(workflow, null, 2);

if (args.output) {
  fs.writeFileSync(args.output, output);
} else {
  process.stdout.write(output + '\n');
}
