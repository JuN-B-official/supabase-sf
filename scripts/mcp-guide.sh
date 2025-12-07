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

    echo ""
    echo "================================================================================"
    echo "                    SUPABASE MCP CONNECTION GUIDE"
    echo "================================================================================"
    echo ""
    echo "Keys loaded from .env (auto-generated on first deployment)"
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo "CLAUDE DESKTOP / CURSOR CONFIGURATION"
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "Add this to your claude_desktop_config.json or .cursor/mcp.json:"
    echo ""
    echo "{"
    echo "  \"mcpServers\": {"
    echo "    \"supabase\": {"
    echo "      \"command\": \"npx\","
    echo "      \"args\": ["
    echo "        \"-y\","
    echo "        \"@supabase/mcp-server-supabase@latest\","
    echo "        \"--supabase-url\", \"${SUPABASE_URL}\","
    echo "        \"--supabase-key\", \"${SERVICE_ROLE_KEY}\""
    echo "      ]"
    echo "    }"
    echo "  }"
    echo "}"
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo "SDK CONFIGURATION"
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "JavaScript/TypeScript:"
    echo "  npm install @supabase/supabase-js"
    echo ""
    echo "  import { createClient } from '@supabase/supabase-js'"
    echo "  const supabase = createClient("
    echo "    '${SUPABASE_URL}',"
    echo "    '${ANON_KEY}'"
    echo "  )"
    echo ""
    echo "Python:"
    echo "  pip install supabase"
    echo ""
    echo "  from supabase import create_client"
    echo "  supabase = create_client("
    echo "    '${SUPABASE_URL}',"
    echo "    '${ANON_KEY}'"
    echo "  )"
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo "REST API (PostgREST)"
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "curl '${SUPABASE_URL}/rest/v1/' \\"
    echo "  -H \"apikey: ${ANON_KEY}\""
    echo ""
    echo "--------------------------------------------------------------------------------"
    echo "ENVIRONMENT VARIABLES"
    echo "--------------------------------------------------------------------------------"
    echo ""
    echo "SUPABASE_URL=${SUPABASE_URL}"
    echo "SUPABASE_ANON_KEY=${ANON_KEY}"
    echo "SUPABASE_SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}"
    echo ""
    echo "WARNING: Keep SERVICE_ROLE_KEY secret! It bypasses Row Level Security."
    echo ""
    echo "================================================================================"
    echo "           Connection info refreshes every 5 minutes"
    echo "================================================================================"
    echo ""
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
