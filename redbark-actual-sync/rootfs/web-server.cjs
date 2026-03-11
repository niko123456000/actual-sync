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
  // Ensure child gets navigator polyfill (required for @actual-app/api in Node)
  const existing = (env.NODE_OPTIONS || '').trim();
  env.NODE_OPTIONS = existing ? `${existing} --require /polyfill-navigator.cjs` : '--require /polyfill-navigator.cjs';
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
  // Export payload is the object with "redbarkAccounts" at top level; there may be other log lines or nested braces
  const keyPos = trimmed.indexOf('"redbarkAccounts"');
  if (keyPos >= 0) {
    const start = trimmed.lastIndexOf('{', keyPos);
    if (start >= 0) {
      return JSON.parse(trimmed.slice(start));
    }
  }
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
    let responded = false;
    const send500 = (obj) => {
      if (responded) return;
      responded = true;
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(obj));
    };
    const timeout = setTimeout(() => {
      child.kill('SIGTERM');
      send500({ error: 'Export timed out', details: 'The account export took too long. Check add-on Log for errors.' });
    }, 60000);
    child.stdout.setEncoding('utf8').on('data', (chunk) => { stdout += chunk; });
    child.stderr.setEncoding('utf8').on('data', (chunk) => { stderr += chunk; });
    child.on('close', (code) => {
      clearTimeout(timeout);
      if (responded) return;
      if (code !== 0) {
        console.error('[web-server] /api/accounts export failed:', code, stderr.slice(-300));
        send500({ error: 'Export failed', details: stderr.slice(-500) });
        return;
      }
      try {
        const data = extractJsonFromStdout(stdout);
        responded = true;
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(data));
      } catch (e) {
        console.error('[web-server] /api/accounts parse failed:', e.message, 'stdout length:', stdout.length, 'stderr:', stderr.slice(-200));
        send500({
          error: 'Invalid export output',
          message: e.message,
          details: stdout.length ? `stdout (last 400 chars): ${stdout.slice(-400)}` : (stderr || 'No stdout captured'),
        });
      }
    });
    child.on('error', (err) => {
      clearTimeout(timeout);
      console.error('[web-server] /api/accounts spawn error:', err.message);
      send500({ error: err.message });
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
