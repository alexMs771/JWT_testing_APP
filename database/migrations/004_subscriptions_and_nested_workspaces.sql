BEGIN;

/*
 * Plans are workspace entitlements, not identity roles. A finance member stays
 * a finance member after an upgrade; the workspace subscription only changes
 * the capabilities available to that member.
 */
CREATE TABLE IF NOT EXISTS workspace_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    plan VARCHAR(20) NOT NULL CHECK (plan IN ('free', 'plus', 'pro')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'trialing', 'expired', 'cancelled', 'replaced')),
    starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ends_at TIMESTAMPTZ NOT NULL,
    provider VARCHAR(40) NOT NULL DEFAULT 'internal',
    provider_reference VARCHAR(180),
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);

ALTER TABLE workspaces
    ADD COLUMN IF NOT EXISTS parent_workspace_id UUID REFERENCES workspaces(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_workspace_subscriptions_current
    ON workspace_subscriptions(workspace_id, status, ends_at DESC);
CREATE INDEX IF NOT EXISTS idx_workspaces_parent
    ON workspaces(parent_workspace_id);

/* Existing tenants start on the free entitlement without changing data. */
INSERT INTO workspace_subscriptions (workspace_id, plan, status, starts_at, ends_at, provider)
SELECT w.id, 'free', 'active', now(), now() + interval '100 years', 'internal'
FROM workspaces w
WHERE NOT EXISTS (
    SELECT 1 FROM workspace_subscriptions s WHERE s.workspace_id = w.id
);

COMMIT;
