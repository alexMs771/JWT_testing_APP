component {

    function configure() {
        route('/healthcheck', function(event, rc, prc) {
            return 'Ok!';
        });

        route('/', 'main.index').end();
        route('/login', 'security.login').end();
        route('/auth/login', 'security.doLogin').end();
        route('/logout', 'security.logout').end();
        route('/refresh', 'security.refreshToken').end();

        route('/dashboard', 'duePilot.dashboard').end();
        route('/invoices/new', 'duePilot.newInvoice').end();
        route('/invoices/create', 'duePilot.createInvoice').end();
        route('/invoices/:invoiceId/payment', 'duePilot.recordPayment').end();
        route('/invoices/:invoiceId/promise', 'duePilot.savePromise').end();
        route('/invoices/:invoiceId/dispute', 'duePilot.openDispute').end();
        route('/invoices/:invoiceId/reminder', 'duePilot.sendReminder').end();
        route('/invoices/:invoiceId', 'duePilot.invoice').end();
        route('/invoices', 'duePilot.invoices').end();

        route('/customers/:customerId', 'duePilot.customer').end();
        route('/customers', 'duePilot.customers').end();
        route('/collections', 'duePilot.collections').end();
        route('/reports', 'duePilot.reports').end();
        route('/settings/reset-demo', 'duePilot.resetDemo').end();
        route('/settings/update', 'duePilot.updateSettings').end();
        route('/settings', 'duePilot.settings').end();

        route('/pay/:portalToken/promise', 'duePilot.portalPromise').end();
        route('/pay/:portalToken/dispute', 'duePilot.portalDispute').end();
        route('/pay/:portalToken/complete', 'duePilot.portalPay').end();
        route('/pay/:portalToken', 'duePilot.portal').end();

        // Versioned REST API used by the separate Next.js frontend.
        route('/api/v1/health', 'apiV1.health').end();
        route('/api/v1/auth/login', 'apiV1.login').end();
        route('/api/v1/auth/refresh', 'apiV1.refreshToken').end();
        route('/api/v1/auth/permissions', 'apiV1.permissions').end();
        route('/api/v1/auth/register', 'apiV1.register').end();
        route('/api/v1/auth/logout', 'apiV1.logout').end();
        route('/api/v1/auth/me', 'apiV1.me').end();
        route('/api/v1/workspace/context', 'apiV1.workspaceContext').end();
        route('/api/v1/subscription/subscribe', 'apiV1.subscribe').end();
        // Keep the more specific subscription action before the collection
        // route. ColdBox evaluates these routes in declaration order.
        route('/api/v1/subscription', 'apiV1.subscription').end();
        route('/api/v1/workspaces', 'apiV1.workspaces').end();
        route('/api/v1/workspace/units', 'apiV1.workspaceUnits').end();
        route('/api/v1/personal/summary', 'apiV1.personalSummary').end();
        route('/api/v1/personal/profile', 'apiV1.personalProfile').end();
        route('/api/v1/personal/obligations', 'apiV1.personalObligations').end();
        route('/api/v1/profile/photo/remove', 'apiV1.removeProfilePhoto').end();
        route('/api/v1/profile/photo', 'apiV1.saveProfilePhoto').end();
        route('/api/v1/profile', 'apiV1.profile').end();
        route('/api/v1/workspace/delete', 'apiV1.deleteWorkspace').end();
        route('/api/v1/admin/workspaces/:workspaceId/delete', 'apiV1.adminDeleteWorkspace').end();
        route('/api/v1/admin/overview', 'apiV1.adminOverview').end();
        route('/api/v1/dashboard', 'apiV1.dashboard').end();
        route('/api/v1/invoices/:invoiceId/payment', 'apiV1.recordPayment').end();
        route('/api/v1/invoices/:invoiceId/promise', 'apiV1.savePromise').end();
        route('/api/v1/invoices/:invoiceId/dispute', 'apiV1.openDispute').end();
        route('/api/v1/invoices/:invoiceId/reminder', 'apiV1.sendReminder').end();
        route('/api/v1/invoices/:invoiceId', 'apiV1.invoice').end();
        route('/api/v1/invoices', 'apiV1.invoices').end();
        route('/api/v1/customers', 'apiV1.customers').end();
        route('/api/v1/reports', 'apiV1.reports').end();
        route('/api/v1/settings', 'apiV1.settings').end();
        route('/api/v1/assistant/status', 'apiV1.assistantStatus').end();
        route('/api/v1/assistant/chat', 'apiV1.assistantChat').end();

        route('/api/assistant/status', 'aiAssistant.status').end();
        route('/api/assistant/chat', 'aiAssistant.chat').end();

        // Kept as a developer-only JWT diagnostics lab.
        route('/demo/issue', 'tokenDemo.issue').end();
        route('/demo/refresh', 'tokenDemo.refresh').end();
        route('/demo/inspect', 'tokenDemo.inspect').end();
        route('/demo/subscribe', 'tokenDemo.subscribe').end();
        route('/demo', 'tokenDemo.index').end();

        route('/api/echo', function(event, rc, prc) {
            return {error: false, data: 'DuePilot API is ready.'};
        });

        route(':handler/:action?').end();
    }

}
