#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Show MCP Connection Guide
# ═══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./scripts/show-mcp.sh
#
# Displays MCP connection configuration for:
# - Claude Desktop / Cursor
# - Environment variables for SDK
#
# ═══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

# Get env value
get_env_value() {
    local key="$1"
    grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | head -1 || echo ""
}

# Check .env exists
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found. Run 'docker compose up -d' first."
    exit 1
fi

# Load values
SUPABASE_URL=$(get_env_value "SUPABASE_PUBLIC_URL")
SERVICE_ROLE_KEY=$(get_env_value "SERVICE_ROLE_KEY")
ANON_KEY=$(get_env_value "ANON_KEY")

SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"

cat <<EOF

================================================================================
                    SUPABASE MCP CONNECTION GUIDE
================================================================================

Add this to your claude_desktop_config.json or .cursor/mcp.json:

{
  "mcpServers": {
    "supabase": {
      "command": "npx",
      "args": [
        "-y",
        "@supabase/mcp-server-supabase@latest",
        "--supabase-url", "${SUPABASE_URL}",
        "--supabase-key", "${SERVICE_ROLE_KEY}"
      ]
    }
  }
}

--------------------------------------------------------------------------------
ENVIRONMENT VARIABLES
--------------------------------------------------------------------------------

SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}

WARNING: Keep SERVICE_ROLE_KEY secret! It bypasses Row Level Security.

================================================================================

EOF
