/**
 * Minimal HTTP server for the add-on web UI (ingress).
 * Serves the account-mapping page and /api/accounts (export from add-on config).
 */
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

const PORT = 8099;
const WWW = path.join(__dirname, 'www');

function readOptions() {
  try {
    return JSON.parse(fs.readFileSync('/data/options.json', 'utf8'));
  } catch (e) {
    return {};
  }
}

function envFromOptions(opts) {
  const env = { ...process.env };
  if (opts.redbark_api_key) env.REDBARK_API_KEY = opts.redbark_api_key;
  if (opts.redbark_api_url) env.REDBARK_API_URL = opts.redbark_api_url;
  if (opts.actual_server_url) env.ACTUAL_SERVER_URL = opts.actual_server_url;
  if (opts.actual_password) env.ACTUAL_PASSWORD = opts.actual_password;
  if (opts.actual_budget_id) env.ACTUAL_BUDGET_ID = opts.actual_budget_id;
  if (opts.actual_encryption_password) env.ACTUAL_ENCRYPTION_PASSWORD = opts.actual_encryption_password;
  env.ACTUAL_DATA_DIR = '/data/actual-cache';
  return env;
}

function extractJsonFromStdout(stdout) {
  const trimmed = stdout.trim();
  const lastBrace = trimmed.lastIndexOf('{');
  if (lastBrace >= 0) {
    return JSON.parse(trimmed.slice(lastBrace));
  }
  return JSON.parse(trimmed);
}

const server = http.createServer((req, res) => {
  const url = req.url?.split('?')[0] || '/';

  if (url === '/api/accounts') {
    const opts = readOptions();
    const env = envFromOptions(opts);
    const child = spawn('node', ['/app/main.cjs', '--export-accounts'], {
      env,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    let stdout = '';
    let stderr = '';
    child.stdout.setEncoding('utf8').on('data', (chunk) => { stdout += chunk; });
    child.stderr.setEncoding('utf8').on('data', (chunk) => { stderr += chunk; });
    child.on('close', (code) => {
      if (code !== 0) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Export failed', details: stderr.slice(-500) }));
        return;
      }
      try {
        const data = extractJsonFromStdout(stdout);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(data));
      } catch (e) {
        res.writeHead(500, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid export output', message: e.message }));
      }
    });
    child.on('error', (err) => {
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: err.message }));
    });
    return;
  }

  if (url === '/' || url === '/index.html') {
    const file = path.join(WWW, 'account-mapping.html');
    fs.readFile(file, (err, data) => {
      if (err) {
        res.writeHead(500);
        res.end('Not found');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(data);
    });
    return;
  }

  res.writeHead(404);
  res.end('Not found');
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Web UI listening on port ${PORT}`);
});
