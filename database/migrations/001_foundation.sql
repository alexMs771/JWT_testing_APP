BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

CREATE TYPE organization_type AS ENUM ('business', 'school', 'college', 'coaching', 'property', 'utility', 'subscription', 'healthcare', 'other');
CREATE TYPE member_status AS ENUM ('invited', 'active', 'suspended');
CREATE TYPE invoice_status AS ENUM ('draft', 'open', 'partial', 'paid', 'overdue', 'disputed', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'successful', 'failed', 'cancelled', 'refunded', 'partially_refunded', 'under_review');

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    email CITEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    email_verified_at TIMESTAMPTZ,
    status VARCHAR(30) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(120) NOT NULL,
    slug VARCHAR(80) NOT NULL UNIQUE,
    organization_type organization_type NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    timezone VARCHAR(80) NOT NULL DEFAULT 'Asia/Kolkata',
    country_code CHAR(2) NOT NULL DEFAULT 'IN',
    finance_email CITEXT,
    default_payment_terms SMALLINT NOT NULL DEFAULT 30 CHECK (default_payment_terms BETWEEN 0 AND 365),
    logo_object_key TEXT,
    demo_mode BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(40) NOT NULL,
    permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
    status member_status NOT NULL DEFAULT 'active',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (workspace_id, user_id)
);

CREATE TABLE workspace_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    email CITEXT NOT NULL,
    role VARCHAR(40) NOT NULL,
    token_hash TEXT NOT NULL UNIQUE,
    invited_by UUID NOT NULL REFERENCES users(id),
    expires_at TIMESTAMPTZ NOT NULL,
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    display_name VARCHAR(160) NOT NULL,
    contact_name VARCHAR(120),
    email CITEXT,
    phone VARCHAR(40),
    billing_address JSONB NOT NULL DEFAULT '{}'::jsonb,
    tax_identifier VARCHAR(80),
    default_payment_terms SMALLINT CHECK (default_payment_terms BETWEEN 0 AND 365),
    external_reference VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (workspace_id, external_reference)
);

CREATE TABLE invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id),
    invoice_number VARCHAR(80) NOT NULL,
    status invoice_status NOT NULL DEFAULT 'draft',
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    currency CHAR(3) NOT NULL,
    subtotal NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (subtotal >= 0),
    tax_amount NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (tax_amount >= 0),
    discount_amount NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0),
    total_amount NUMERIC(19,4) NOT NULL CHECK (total_amount >= 0),
    paid_amount NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    balance_amount NUMERIC(19,4) NOT NULL CHECK (balance_amount >= 0),
    purchase_order VARCHAR(120),
    notes TEXT,
    portal_token_hash TEXT UNIQUE,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (due_date >= issue_date),
    CHECK (paid_amount <= total_amount),
    CHECK (balance_amount = total_amount - paid_amount),
    UNIQUE (workspace_id, invoice_number)
);

CREATE TABLE invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    description VARCHAR(500) NOT NULL,
    quantity NUMERIC(15,4) NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(19,4) NOT NULL CHECK (unit_price >= 0),
    tax_rate NUMERIC(7,4) NOT NULL DEFAULT 0 CHECK (tax_rate >= 0),
    line_total NUMERIC(19,4) NOT NULL CHECK (line_total >= 0),
    sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE payment_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    provider VARCHAR(40) NOT NULL,
    provider_request_id VARCHAR(180),
    amount NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'created',
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (workspace_id, provider, provider_request_id)
);

CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_id UUID REFERENCES invoices(id),
    payment_request_id UUID REFERENCES payment_requests(id),
    provider VARCHAR(40) NOT NULL,
    provider_reference VARCHAR(180) NOT NULL,
    status payment_status NOT NULL,
    amount NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL,
    paid_at TIMESTAMPTZ,
    verified_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (workspace_id, provider, provider_reference)
);

CREATE TABLE payment_webhook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider VARCHAR(40) NOT NULL,
    provider_event_id VARCHAR(180) NOT NULL,
    signature_verified BOOLEAN NOT NULL DEFAULT false,
    payload JSONB NOT NULL,
    processing_status VARCHAR(30) NOT NULL DEFAULT 'received',
    processed_at TIMESTAMPTZ,
    failure_reason TEXT,
    received_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_event_id)
);

CREATE TABLE collection_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    activity_type VARCHAR(40) NOT NULL,
    channel VARCHAR(30),
    summary TEXT NOT NULL,
    detail JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payment_promises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    promised_date DATE NOT NULL,
    promised_amount NUMERIC(19,4) NOT NULL CHECK (promised_amount > 0),
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'open',
    resolution TEXT,
    opened_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

CREATE TABLE refresh_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash TEXT NOT NULL UNIQUE,
    user_agent TEXT,
    ip_hash TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    rotated_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID REFERENCES workspaces(id) ON DELETE SET NULL,
    actor_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(80) NOT NULL,
    entity_id UUID,
    before_data JSONB,
    after_data JSONB,
    request_id VARCHAR(80),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ai_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    provider VARCHAR(40) NOT NULL,
    model VARCHAR(120) NOT NULL,
    operation VARCHAR(80) NOT NULL,
    input_tokens INTEGER NOT NULL DEFAULT 0,
    output_tokens INTEGER NOT NULL DEFAULT 0,
    latency_ms INTEGER,
    estimated_cost NUMERIC(14,8),
    status VARCHAR(30) NOT NULL,
    error_code VARCHAR(80),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_members_user ON workspace_members(user_id, status);
CREATE INDEX idx_customers_workspace_name ON customers(workspace_id, display_name);
CREATE INDEX idx_invoices_workspace_status_due ON invoices(workspace_id, status, due_date);
CREATE INDEX idx_invoices_workspace_customer ON invoices(workspace_id, customer_id);
CREATE INDEX idx_payments_workspace_paid ON payments(workspace_id, paid_at DESC);
CREATE INDEX idx_activities_invoice_created ON collection_activities(invoice_id, created_at DESC);
CREATE INDEX idx_audit_workspace_created ON audit_logs(workspace_id, created_at DESC);
CREATE INDEX idx_ai_usage_workspace_created ON ai_usage(workspace_id, created_at DESC);

COMMIT;
