BEGIN;

/*
 * Sector structure is intentionally separate from billing workspaces.
 * A college can model departments, a school can model grades/classes, and a
 * business can model divisions or branches without overloading the tenant
 * table. Workspace limits still control the number of billable child tenants.
 */
CREATE TABLE IF NOT EXISTS workspace_units (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    parent_unit_id UUID REFERENCES workspace_units(id) ON DELETE CASCADE,
    name VARCHAR(120) NOT NULL,
    code VARCHAR(40),
    unit_type VARCHAR(40) NOT NULL DEFAULT 'department',
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (unit_type IN ('department','division','branch','grade','class','batch','team','custom')),
    UNIQUE (workspace_id, parent_unit_id, name)
);

CREATE INDEX IF NOT EXISTS idx_workspace_units_tree
    ON workspace_units(workspace_id, parent_unit_id, created_at);

COMMIT;
