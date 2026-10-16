BEGIN;

INSERT INTO users (id, name, email, password_hash, email_verified_at)
VALUES ('10000000-0000-0000-0000-000000000001', 'Alex Morgan', 'alex@duepilot.app', crypt('demo123', gen_salt('bf', 12)), now())
ON CONFLICT (email) DO NOTHING;

INSERT INTO workspaces (id, name, slug, organization_type, currency, timezone, country_code, finance_email, default_payment_terms, demo_mode)
VALUES ('20000000-0000-0000-0000-000000000001', 'Northstar Digital', 'northstar-digital', 'business', 'INR', 'Asia/Kolkata', 'IN', 'finance@northstardigital.in', 30, true)
ON CONFLICT (slug) DO NOTHING;

INSERT INTO workspace_members (workspace_id, user_id, role, status)
VALUES ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'Owner', 'active')
ON CONFLICT (workspace_id, user_id) DO NOTHING;

INSERT INTO customers (id, workspace_id, display_name, contact_name, email, phone, external_reference) VALUES
('30000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Atlas Manufacturing','Priya Shah','accounts@atlasmfg.in','+91 98400 24018','cus-atlas'),
('30000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','Kaveri Systems','Arun Kumar','finance@kaverisystems.com','+91 98840 73102','cus-kaveri'),
('30000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','GreenGrid Energy','Meera Nair','payables@greengrid.in','+91 90031 88214','cus-greengrid'),
('30000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000001','PixelCraft Studios','Rahul Jain','rahul@pixelcraft.studio','+91 97908 44391','cus-pixelcraft'),
('30000000-0000-0000-0000-000000000005','20000000-0000-0000-0000-000000000001','Vertex Consulting','Sneha Iyer','billing@vertexconsulting.in','+91 94444 10872','cus-vertex'),
('30000000-0000-0000-0000-000000000006','20000000-0000-0000-0000-000000000001','Mosaic Retail Labs','Vikram Rao','ap@mosaicretail.com','+91 98412 99820','cus-mosaic'),
('30000000-0000-0000-0000-000000000007','20000000-0000-0000-0000-000000000001','BluePeak Analytics','Nisha Thomas','nisha@bluepeakanalytics.com','+91 89391 22841','cus-bluepeak'),
('30000000-0000-0000-0000-000000000008','20000000-0000-0000-0000-000000000001','Brightline Media','Karan Singh','finance@brightline.media','+91 87545 66712','cus-brightline')
ON CONFLICT (workspace_id, external_reference) DO NOTHING;

INSERT INTO invoices (id, workspace_id, customer_id, invoice_number, status, issue_date, due_date, currency, subtotal, total_amount, paid_amount, balance_amount, purchase_order, notes, portal_token_hash, created_by) VALUES
('40000000-0000-0000-0000-000000001048','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','INV-'||extract(year from current_date)::int||'-1048','overdue',current_date-48,current_date-18,'INR',185000,185000,0,185000,'PO-ATL-8821','Website modernization and integrations',encode(digest('portal-1048','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001047','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000008','INV-'||extract(year from current_date)::int||'-1047','overdue',current_date-41,current_date-11,'INR',45000,45000,0,45000,'BL-2026-091','Campaign analytics implementation',encode(digest('portal-1047','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001046','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002','INV-'||extract(year from current_date)::int||'-1046','overdue',current_date-36,current_date-6,'INR',248000,248000,0,248000,'KS-RET-330','Q3 product engineering retainer',encode(digest('portal-1046','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001045','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000004','INV-'||extract(year from current_date)::int||'-1045','disputed',current_date-31,current_date-1,'INR',67500,67500,0,67500,'PC-445','Design system implementation',encode(digest('portal-1045','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001044','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000003','INV-'||extract(year from current_date)::int||'-1044','open',current_date-28,current_date+2,'INR',156000,156000,0,156000,'GG-OPS-19','Operations dashboard delivery',encode(digest('portal-1044','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001043','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000005','INV-'||extract(year from current_date)::int||'-1043','open',current_date-25,current_date+5,'INR',84000,84000,0,84000,'VC-CLOUD-76','Cloud migration advisory',encode(digest('portal-1043','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001042','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000006','INV-'||extract(year from current_date)::int||'-1042','partial',current_date-38,current_date-8,'INR',120000,120000,40000,80000,'MRL-API-112','Commerce API development',encode(digest('portal-1042','sha256'),'hex'),'10000000-0000-0000-0000-000000000001'),
('40000000-0000-0000-0000-000000001041','20000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000007','INV-'||extract(year from current_date)::int||'-1041','paid',current_date-52,current_date-22,'INR',98000,98000,98000,0,'BPA-801','Data pipeline optimization',encode(digest('portal-1041','sha256'),'hex'),'10000000-0000-0000-0000-000000000001')
ON CONFLICT (workspace_id, invoice_number) DO NOTHING;

INSERT INTO disputes (workspace_id, invoice_id, reason)
SELECT '20000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000001045', 'Purchase order amount does not match the invoice.'
WHERE NOT EXISTS (SELECT 1 FROM disputes WHERE invoice_id='40000000-0000-0000-0000-000000001045' AND status='open');

COMMIT;
