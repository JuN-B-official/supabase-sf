# Key Rotation Guide

> [!CAUTION]  
> **There is currently no official key rotation path for Self-hosted Supabase.**  
> The procedures below are community-verified methods, but there is a risk of data loss.  
> **Always perform a full backup before proceeding.**

## Why Can't Keys Be Simply Changed?

Self-hosted Supabase stores the following values inside the system during the first `docker compose up`:

| Key | Storage Location | How It's Stored |
|-----|------------------|-----------------|
| `POSTGRES_PASSWORD` | 5 PostgreSQL roles | `ALTER USER ... WITH PASSWORD` |
| `JWT_SECRET` | `postgres` DB setting | `ALTER DATABASE SET "app.settings.jwt_secret"` |
| `VAULT_ENC_KEY` | Supavisor internal | Encrypted tenant data |
| `ANON_KEY` / `SERVICE_ROLE_KEY` | Client code | JWT tokens signed with `JWT_SECRET` |

If you only change `.env`, containers start with new values, but the database and encrypted stores still contain the old values, causing a **mismatch**.

---

## Option 1: Full Reset (Recommended)

The safest approach is to backup your data and start fresh.

```bash
# 1. Backup data
docker exec supabase-db pg_dumpall -U postgres > backup_$(date +%Y%m%d).sql

# 2. Remove all containers and volumes
docker compose down -v --remove-orphans

# 3. Update new values in .env file
# Change POSTGRES_PASSWORD, JWT_SECRET, VAULT_ENC_KEY, etc.

# 4. Start fresh
docker compose up -d

# 5. Restore data (watch for schema conflicts)
docker exec -i supabase-db psql -U postgres < backup_$(date +%Y%m%d).sql
```

> [!WARNING]  
> When restoring data, JWT-related data in Auth tables may not be compatible with the new `JWT_SECRET`.  
> All user sessions will be invalidated, requiring re-login.

---

## Option 2: Manual Key Rotation (Advanced)

> [!CAUTION]  
> This method requires deep understanding of PostgreSQL and Supabase internals.  
> Incorrect execution may make the system unrecoverable.

### Changing POSTGRES_PASSWORD

```sql
-- 1. Connect directly to DB
docker exec -it supabase-db psql -U postgres

-- 2. Change password for all related roles
ALTER USER authenticator WITH PASSWORD 'new-password';
ALTER USER pgbouncer WITH PASSWORD 'new-password';
ALTER USER supabase_auth_admin WITH PASSWORD 'new-password';
ALTER USER supabase_functions_admin WITH PASSWORD 'new-password';
ALTER USER supabase_storage_admin WITH PASSWORD 'new-password';

-- 3. Update .env file with the same value
-- 4. Restart all services
docker compose restart
```

### Changing JWT_SECRET

```sql
-- 1. Change DB setting
docker exec -it supabase-db psql -U postgres -c \
  "ALTER DATABASE postgres SET \"app.settings.jwt_secret\" TO 'new-jwt-secret';"

-- 2. Update .env file

-- 3. Generate new ANON_KEY / SERVICE_ROLE_KEY
-- See https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys

-- 4. Restart all services
docker compose restart
```

### Changing VAULT_ENC_KEY

> [!CAUTION]  
> Changing `VAULT_ENC_KEY` is **very dangerous**.  
> Encrypted data stored in Supavisor will become undecryptable.  
> There is currently no official path to safely rotate this key alone.

**Recommendation**: Use Option 1 (Full Reset)

---

## Regenerating ANON_KEY / SERVICE_ROLE_KEY

These keys are JWT tokens signed with `JWT_SECRET`. If you changed `JWT_SECRET`, you must regenerate them.

```bash
# Example: Using Node.js
node -e "
const jwt = require('jsonwebtoken');

const payload = {
  role: 'anon', // or 'service_role'
  iss: 'supabase',
  iat: Math.floor(Date.now() / 1000),
  exp: Math.floor(Date.now() / 1000) + (10 * 365 * 24 * 60 * 60) // 10 years
};

console.log(jwt.sign(payload, 'YOUR_NEW_JWT_SECRET'));
"
```

Or use the [Supabase JWT Generator](https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys)

---

## Summary

| Scenario | Recommended Approach |
|----------|---------------------|
| Initial setup mistake | Option 1: Full Reset |
| Regular security rotation | No official path - Full Reset recommended |
| Key compromise | Option 1 + Invalidate all user sessions |
| Change specific key only | Option 2 (for that key only, understand risks) |
