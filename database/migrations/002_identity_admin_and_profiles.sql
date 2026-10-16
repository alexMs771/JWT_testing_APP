BEGIN;

ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_content_type VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_bytes BYTEA;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS platform_admins (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    granted_by UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS auth_login_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    email CITEXT NOT NULL,
    outcome VARCHAR(24) NOT NULL CHECK (outcome IN ('success', 'failed', 'logout')),
    ip_hash TEXT,
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS workspace_usage_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    event_type VARCHAR(80) NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS workspace_deletions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_name VARCHAR(120) NOT NULL,
    deleted_by UUID REFERENCES users(id) ON DELETE SET NULL,
    deleted_by_admin BOOLEAN NOT NULL DEFAULT false,
    reason VARCHAR(500),
    deleted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_login_events_created ON auth_login_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_login_events_user_created ON auth_login_events(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_usage_workspace_created ON workspace_usage_events(workspace_id, created_at DESC);

COMMIT;
