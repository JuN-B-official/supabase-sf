#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# Supabase Environment Info
# ═══════════════════════════════════════════════════════════════════════════════
#
# Displays current environment configuration in container logs.
# View this via: docker logs <instance>-env-info
#
# ═══════════════════════════════════════════════════════════════════════════════

ENV_FILE="/app/.env"

# Get env value
get_env_value() {
    local key="$1"
    grep "^${key}=" "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | head -1 || echo ""
}

# Mask secret (show first 4 and last 4 chars)
mask_secret() {
    local value="$1"
    local len=${#value}
    if [[ $len -gt 12 ]]; then
        echo "${value:0:4}...${value: -4}"
    else
        echo "****"
    fi
}

# Wait for .env to be ready
wait_for_env() {
    local retries=30
    while [[ ! -f "$ENV_FILE" ]] && [[ $retries -gt 0 ]]; do
        echo "[ENV] Waiting for initialization..."
        sleep 2
        retries=$((retries - 1))
    done
    
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "[ENV] ERROR: .env file not found after timeout"
        exit 1
    fi
}

print_env_info() {
    # Load values
    local INSTANCE_NAME=$(get_env_value "INSTANCE_NAME")
    local STUDIO_ORG=$(get_env_value "STUDIO_DEFAULT_ORGANIZATION")
    local STUDIO_PROJECT=$(get_env_value "STUDIO_DEFAULT_PROJECT")
    local DASHBOARD_USER=$(get_env_value "DASHBOARD_USERNAME")
    local DASHBOARD_PASS=$(get_env_value "DASHBOARD_PASSWORD")
    local SUPABASE_URL=$(get_env_value "SUPABASE_PUBLIC_URL")
    local SITE_URL=$(get_env_value "SITE_URL")
    local API_URL=$(get_env_value "API_EXTERNAL_URL")
    local KONG_HTTP=$(get_env_value "KONG_HTTP_PORT")
    local KONG_HTTPS=$(get_env_value "KONG_HTTPS_PORT")
    
    local PG_PASS=$(get_env_value "POSTGRES_PASSWORD")
    local JWT_SECRET=$(get_env_value "JWT_SECRET")
    local ANON_KEY=$(get_env_value "ANON_KEY")
    local SERVICE_KEY=$(get_env_value "SERVICE_ROLE_KEY")
    local VAULT_KEY=$(get_env_value "VAULT_ENC_KEY")

    local GENERATED_AT=$(date '+%Y-%m-%d %H:%M:%S')
    local MASKED_PG_PASS=$(mask_secret "$PG_PASS")
    local MASKED_JWT_SECRET=$(mask_secret "$JWT_SECRET")
    local MASKED_VAULT_KEY=$(mask_secret "$VAULT_KEY")

    cat <<EOF

================================================================================
                    SUPABASE ENVIRONMENT INFO
================================================================================

Instance: ${INSTANCE_NAME:-supabase}
Generated at: ${GENERATED_AT}

--------------------------------------------------------------------------------
DASHBOARD LOGIN
--------------------------------------------------------------------------------

  URL:      ${SUPABASE_URL:-http://localhost:8000}
  Username: ${DASHBOARD_USER:-supabase}
  Password: ${DASHBOARD_PASS}

--------------------------------------------------------------------------------
PROJECT INFO
--------------------------------------------------------------------------------

  Organization: ${STUDIO_ORG:-Default Organization}
  Project:      ${STUDIO_PROJECT:-Default Project}

--------------------------------------------------------------------------------
URLS
--------------------------------------------------------------------------------

  SUPABASE_PUBLIC_URL: ${SUPABASE_URL:-http://localhost:8000}
  SITE_URL:            ${SITE_URL:-http://localhost:3000}
  API_EXTERNAL_URL:    ${API_URL:-http://localhost:8000}
  KONG_HTTP_PORT:      ${KONG_HTTP:-8000}
  KONG_HTTPS_PORT:     ${KONG_HTTPS:-8443}

--------------------------------------------------------------------------------
API KEYS (copy these for your app)
--------------------------------------------------------------------------------

  ANON_KEY:
  ${ANON_KEY}

  SERVICE_ROLE_KEY (keep secret!):
  ${SERVICE_KEY}

--------------------------------------------------------------------------------
SECRETS (masked for security)
--------------------------------------------------------------------------------

  POSTGRES_PASSWORD: ${MASKED_PG_PASS}
  JWT_SECRET:        ${MASKED_JWT_SECRET}
  VAULT_ENC_KEY:     ${MASKED_VAULT_KEY}

  To see full secrets, check your .env file or platform environment variables.

================================================================================
           Info refreshes every 5 minutes | View: docker logs <instance>-env-info
================================================================================

EOF
}

main() {
    wait_for_env
    
    # Initial print
    print_env_info
    
    # Watch for .env changes using inotify (falls back to polling if unavailable)
    if command -v inotifywait &> /dev/null; then
        echo "[ENV] Watching for .env changes (inotify)..."
        while true; do
            inotifywait -qq -e modify -e close_write "$ENV_FILE" 2>/dev/null
            sleep 1  # Brief delay to avoid rapid updates
            print_env_info
        done
    else
        echo "[ENV] inotifywait not available, falling back to 5-minute polling..."
        while true; do
            sleep 300
            print_env_info
        done
    fi
}

main
