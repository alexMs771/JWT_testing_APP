BEGIN;

/*
  Personal dues are deliberately separate from business workspace invoices.
  Provider adapters may write obligations here after a verified consent flow.
  No bank password, UPI PIN, card secret, or provider credential belongs in
  these tables.
*/
CREATE TABLE IF NOT EXISTS personal_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    mobile_e164 VARCHAR(16) UNIQUE,
    mobile_verified_at TIMESTAMPTZ,
    display_name VARCHAR(120),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS personal_consents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_key VARCHAR(80) NOT NULL,
    purpose VARCHAR(120) NOT NULL,
    scope JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(24) NOT NULL DEFAULT 'active' CHECK (status IN ('pending', 'active', 'expired', 'revoked')),
    granted_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS personal_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    consent_id UUID REFERENCES personal_consents(id) ON DELETE SET NULL,
    provider_key VARCHAR(80) NOT NULL,
    provider_name VARCHAR(160) NOT NULL,
    category VARCHAR(60) NOT NULL,
    external_reference VARCHAR(180) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'connected' CHECK (status IN ('pending', 'connected', 'needs_attention', 'disconnected')),
    last_synced_at TIMESTAMPTZ,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, provider_key, external_reference)
);

CREATE TABLE IF NOT EXISTS personal_obligations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    connection_id UUID REFERENCES personal_connections(id) ON DELETE SET NULL,
    provider_name VARCHAR(160) NOT NULL,
    category VARCHAR(60) NOT NULL,
    title VARCHAR(180) NOT NULL,
    external_reference VARCHAR(180) NOT NULL,
    amount NUMERIC(19,4) NOT NULL CHECK (amount >= 0),
    paid_amount NUMERIC(19,4) NOT NULL DEFAULT 0 CHECK (paid_amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    issue_date DATE,
    due_date DATE NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'partial', 'paid', 'overdue', 'cancelled')),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    source_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (paid_amount <= amount),
    UNIQUE (user_id, provider_name, external_reference, due_date)
);

CREATE TABLE IF NOT EXISTS personal_payment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    obligation_id UUID NOT NULL REFERENCES personal_obligations(id) ON DELETE RESTRICT,
    provider VARCHAR(60) NOT NULL,
    provider_reference VARCHAR(180),
    amount NUMERIC(19,4) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    status VARCHAR(24) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'pending', 'successful', 'failed', 'cancelled', 'refunded')),
    failure_code VARCHAR(80),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_personal_obligations_user_due ON personal_obligations(user_id, due_date, status);
CREATE INDEX IF NOT EXISTS idx_personal_connections_user ON personal_connections(user_id, status);
CREATE INDEX IF NOT EXISTS idx_personal_consents_user ON personal_consents(user_id, status);
CREATE INDEX IF NOT EXISTS idx_personal_payments_user_created ON personal_payment_attempts(user_id, created_at DESC);

COMMIT;
