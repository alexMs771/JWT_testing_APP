-- DuePilot v1 persistence model (MySQL 8+)
-- The app starts in DATA_MODE=demo so it can be evaluated without a database.

CREATE DATABASE IF NOT EXISTS duepilot CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE duepilot;

CREATE TABLE organizations (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(160) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    plan VARCHAR(40) NOT NULL DEFAULT 'trial',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE users (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    name VARCHAR(120) NOT NULL,
    email VARCHAR(190) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('owner','admin','collector','viewer') NOT NULL DEFAULT 'collector',
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_users_email (email),
    CONSTRAINT fk_users_organization FOREIGN KEY (organization_id) REFERENCES organizations(id)
) ENGINE=InnoDB;

CREATE TABLE customers (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    name VARCHAR(180) NOT NULL,
    contact_name VARCHAR(120),
    email VARCHAR(190),
    phone VARCHAR(40),
    tax_id VARCHAR(50),
    payment_terms_days SMALLINT NOT NULL DEFAULT 30,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_customers_org_name (organization_id, name),
    CONSTRAINT fk_customers_organization FOREIGN KEY (organization_id) REFERENCES organizations(id)
) ENGINE=InnoDB;

CREATE TABLE invoices (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    customer_id CHAR(36) NOT NULL,
    invoice_number VARCHAR(60) NOT NULL,
    purchase_order VARCHAR(80),
    description TEXT,
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    amount DECIMAL(15,2) NOT NULL,
    paid_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    status ENUM('open','due_soon','overdue','partial','disputed','paid','void') NOT NULL DEFAULT 'open',
    owner_user_id CHAR(36),
    portal_token CHAR(64) NOT NULL,
    last_contact_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_invoice_number (organization_id, invoice_number),
    UNIQUE KEY uq_invoice_portal_token (portal_token),
    KEY idx_invoices_collection_queue (organization_id, status, due_date),
    KEY idx_invoices_customer (customer_id),
    CONSTRAINT fk_invoices_organization FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id) REFERENCES customers(id),
    CONSTRAINT fk_invoices_owner FOREIGN KEY (owner_user_id) REFERENCES users(id)
) ENGINE=InnoDB;

CREATE TABLE payments (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    invoice_id CHAR(36) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    method ENUM('upi','bank','card','cash','cheque','manual') NOT NULL DEFAULT 'manual',
    provider VARCHAR(80),
    provider_reference VARCHAR(160),
    paid_at DATETIME NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_payments_invoice (invoice_id, paid_at),
    CONSTRAINT fk_payments_organization FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id)
) ENGINE=InnoDB;

CREATE TABLE payment_promises (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    invoice_id CHAR(36) NOT NULL,
    promised_date DATE NOT NULL,
    note TEXT,
    source ENUM('customer_portal','team') NOT NULL,
    status ENUM('active','kept','broken','cancelled') NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_promises_due (organization_id, status, promised_date),
    CONSTRAINT fk_promises_organization FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_promises_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id)
) ENGINE=InnoDB;

CREATE TABLE disputes (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    invoice_id CHAR(36) NOT NULL,
    reason TEXT NOT NULL,
    source ENUM('customer_portal','team') NOT NULL,
    status ENUM('open','investigating','resolved','rejected') NOT NULL DEFAULT 'open',
    resolved_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_disputes_open (organization_id, status, created_at),
    CONSTRAINT fk_disputes_organization FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_disputes_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id)
) ENGINE=InnoDB;

CREATE TABLE reminders (
    id CHAR(36) PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    invoice_id CHAR(36) NOT NULL,
    channel ENUM('email','whatsapp','sms') NOT NULL,
    recipient VARCHAR(190) NOT NULL,
    status ENUM('queued','sent','delivered','failed') NOT NULL DEFAULT 'queued',
    provider_reference VARCHAR(160),
    sent_at DATETIME,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_reminders_invoice (invoice_id, created_at),
    CONSTRAINT fk_reminders_organization FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_reminders_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id)
) ENGINE=InnoDB;

CREATE TABLE activity_events (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    organization_id CHAR(36) NOT NULL,
    invoice_id CHAR(36),
    actor_user_id CHAR(36),
    event_type VARCHAR(50) NOT NULL,
    title VARCHAR(220) NOT NULL,
    detail TEXT,
    metadata JSON,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_activity_org_time (organization_id, created_at),
    KEY idx_activity_invoice (invoice_id, created_at),
    CONSTRAINT fk_activity_organization FOREIGN KEY (organization_id) REFERENCES organizations(id),
    CONSTRAINT fk_activity_invoice FOREIGN KEY (invoice_id) REFERENCES invoices(id),
    CONSTRAINT fk_activity_actor FOREIGN KEY (actor_user_id) REFERENCES users(id)
) ENGINE=InnoDB;
