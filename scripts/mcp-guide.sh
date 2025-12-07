#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Supabase MCP Connection Guide
# ═══════════════════════════════════════════════════════════════════════════════
#
# This script displays MCP connection information in container logs.
# View this via: docker logs supabase-mcp-guide
#
# The keys shown are dynamically loaded from .env file.
#
# ═══════════════════════════════════════════════════════════════════════════════

ENV_FILE="/app/.env"

# Get env value
get_env_value() {
    local key="$1"
    grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | head -1 || echo ""
}

# Wait for .env to be ready
wait_for_env() {
    local retries=30
    while [[ ! -f "$ENV_FILE" ]] && [[ $retries -gt 0 ]]; do
        echo "[MCP] Waiting for initialization..."
        sleep 2
        retries=$((retries - 1))
    done
    
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "[MCP] ERROR: .env file not found after timeout"
        exit 1
    fi
}

print_connection_info() {
    local SUPABASE_URL=$(get_env_value "SUPABASE_PUBLIC_URL")
    local SERVICE_ROLE_KEY=$(get_env_value "SERVICE_ROLE_KEY")
    local ANON_KEY=$(get_env_value "ANON_KEY")
    
    SUPABASE_URL="${SUPABASE_URL:-http://localhost:8000}"

    cat <<EOF

================================================================================
                    SUPABASE MCP CONNECTION GUIDE
================================================================================

Keys loaded from .env (auto-generated on first deployment)

--------------------------------------------------------------------------------
CLAUDE DESKTOP / CURSOR CONFIGURATION
--------------------------------------------------------------------------------

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
SDK CONFIGURATION
--------------------------------------------------------------------------------

JavaScript/TypeScript:
  npm install @supabase/supabase-js

  import { createClient } from '@supabase/supabase-js'
  const supabase = createClient(
    '${SUPABASE_URL}',
    '${ANON_KEY}'
  )

Python:
  pip install supabase

  from supabase import create_client
  supabase = create_client(
    '${SUPABASE_URL}',
    '${ANON_KEY}'
  )

--------------------------------------------------------------------------------
REST API (PostgREST)
--------------------------------------------------------------------------------

curl '${SUPABASE_URL}/rest/v1/' \\
  -H "apikey: ${ANON_KEY}"

--------------------------------------------------------------------------------
ENVIRONMENT VARIABLES
--------------------------------------------------------------------------------

SUPABASE_URL=${SUPABASE_URL}
SUPABASE_ANON_KEY=${ANON_KEY}
SUPABASE_SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}

WARNING: Keep SERVICE_ROLE_KEY secret! It bypasses Row Level Security.

================================================================================
           Connection info refreshes every 5 minutes
================================================================================

EOF
}

main() {
    wait_for_env
    
    # Initial print
    print_connection_info
    
    # Watch for .env changes using inotify (falls back to polling if unavailable)
    if command -v inotifywait &> /dev/null; then
        echo "[MCP] Watching for .env changes (inotify)..."
        while true; do
            inotifywait -qq -e modify -e close_write "$ENV_FILE" 2>/dev/null
            sleep 1  # Brief delay to avoid rapid updates
            print_connection_info
        done
    else
        echo "[MCP] inotifywait not available, falling back to 5-minute polling..."
        while true; do
            sleep 300
            print_connection_info
        done
    fi
}

main
