#!/usr/bin/env bash
# Generates a tiny CLI with one real design decision (on-disk token cache)
# for design-council evals.
set -euo pipefail
cd "${1:-$PWD}"
mkdir -p src
cat > package.json <<'JSON'
{ "name": "deployctl", "version": "0.9.0", "private": true, "bin": { "deployctl": "src/cli.js" } }
JSON
cat > CLAUDE.md <<'MD'
# deployctl
CLI that deploys services through our internal API. Used by ~40 engineers on macOS and Linux, plus CI runners.
Conventions: TDD, Conventional Commits, no new runtime dependencies without discussion.
MD
cat > src/auth.js <<'JS'
// Today: every command does a full OAuth device-flow login (~8s, opens a browser).
async function getToken() {
  return deviceFlowLogin();
}
async function deviceFlowLogin() {
  /* talks to https://auth.internal.example/device */
  return "token";
}
module.exports = { getToken };
JS
cat > src/cli.js <<'JS'
#!/usr/bin/env node
const { getToken } = require("./auth");
(async () => {
  const token = await getToken();
  console.log(`deploying ${process.argv[2]} with token ${token.slice(0, 4)}…`);
})();
JS
cat > PROPOSAL.md <<'MD'
# Proposal: cache the access token on disk
Store the OAuth access + refresh token in `~/.config/deployctl/token.json` (mode 0600) so commands
reuse it until expiry (access 1h, refresh 30d). Alternative: OS keychain via a native module.
CI runners would keep using a short-lived token from an env var.
MD
