/**
 * Versioned JSON API consumed by the Next.js frontend.
 *
 * Every response follows a predictable envelope and all workspace data is
 * resolved on the server. The current demo repository will be replaced by the
 * PostgreSQL repository without changing this public contract.
 */
component extends="coldbox.system.EventHandler" {

    property name="authService" inject="AuthService";
    property name="duePilotService" inject="DuePilotService";
    property name="duePilotAiService" inject="DuePilotAiService";
    property name="tokenManager" inject="TokenManager@cf-token-manager";
    property name="subscriptionService" inject="SubscriptionService";

    function health(event, rc, prc) {
        return success(
            event,
            {
                service: 'duepilot-api',
                version: 'v1',
                status: 'healthy',
                persistence: getSystemSetting('DATA_MODE', 'demo')
            }
        );
    }

    function login(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        param rc.email = '';
        param rc.password = '';
        var email = lCase(trim(rc.email ?: ''));
        var password = toString(rc.password);
        if (!isValid('email', email) || len(email) > 254) {
            return failure(
                event,
                400,
                'INVALID_LOGIN_REQUEST',
                'Enter a valid work email address.'
            );
        }
        if (len(password) < 12 || len(password) > 200) {
            return failure(
                event,
                400,
                'INVALID_LOGIN_REQUEST',
                'Password must contain between 12 and 200 characters.'
            );
        }

        var authentication = authService.authenticate(email, password);
        if (!authentication.authenticated) {
            return failure(
                event,
                401,
                'INVALID_CREDENTIALS',
                'That email or password is not correct.'
            );
        }

        var account = authentication.user;
        var accessToken = startSession(account);

        return success(event, sessionPayload(accessToken));
    }

    function refreshToken(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!hasSessionTokens()) {
            return failure(
                event,
                401,
                'AUTHENTICATION_REQUIRED',
                'Sign in before refreshing the session.'
            );
        }

        var diagnosis = tokenManager.diagnose(session.tokens.refreshToken, 'refresh');
        if (!diagnosis.valid) {
            clearAuthenticationSession();
            return failure(
                event,
                401,
                'AUTHENTICATION_REQUIRED',
                'Your refresh session is no longer valid.',
                [{code: diagnosis.code}]
            );
        }

        // Re-read the server-side entitlement before rotating the access
        // token. This is important for the short-lived subscription test:
        // an expired Plus/Pro record must produce a free claim immediately,
        // even when the refresh token itself is still valid.
        session.user = subscriptionService.enrichAccount(session.user);
        var result = tokenManager.refresh(session.tokens.refreshToken);
        var refreshedClaims = tokenManager.decode(result.accessToken);
        var currentClaims = buildTokenSubject(session.user);
        var accessToken = result.accessToken;
        if ((refreshedClaims.plan ?: 'free') != (currentClaims.plan ?: 'free') || (refreshedClaims.subscriptionStatus ?: '') != (currentClaims.subscriptionStatus ?: '')) {
            // Keep the package refresh() call in the flow, but issue a fresh
            // pair when server-side entitlements changed so both JWTs carry
            // the current signed RBAC/plan snapshot.
            var refreshedPair = tokenManager.issue(currentClaims);
            session.tokens.refreshToken = refreshedPair.refreshToken;
            accessToken = refreshedPair.accessToken;
        }

        var accessClaims = tokenManager.decode(accessToken);
        var refreshClaims = tokenManager.decode(session.tokens.refreshToken);
        return success(
            event,
            {
                refreshed: true,
                accessToken: accessToken,
                accessIn: accessClaims.exp - epochSeconds(),
                refreshIn: refreshClaims.exp - epochSeconds()
            }
        );
    }

    function permissions(event, rc, prc) {
        if (!requireMethod(event, 'GET') || !requireAuthentication(event)) return request.duePilotApiResponse;

        var accessToken = request.authAccessToken ?: bearerAccessToken();
        var claims = tokenManager.decode(accessToken);
        var role = lCase(trim(claims.role ?: session.user.role ?: ''));
        var roleChecks = {
            ownRole: len(role) ? tokenManager.hasRole(accessToken, role) : false,
            operations: tokenManager.hasAnyRole(accessToken, ['owner', 'admin', 'manager', 'finance']),
            collections: tokenManager.hasAnyRole(accessToken, ['owner', 'admin', 'manager', 'finance']),
            workspaceAdmin: tokenManager.hasAnyRole(accessToken, ['owner', 'admin']),
            platformAdmin: tokenManager.hasRole(accessToken, 'platform_admin'),
            platformOwner: tokenManager.hasAllRoles(accessToken, ['owner', 'platform_admin'])
        };
        var platformAuthorization = tokenManager.diagnoseAuthorization(accessToken, 'platform_admin');

        return success(
            event,
            {
                verified: tokenManager.verify(accessToken, 'access'),
                role: role,
                roles: isArray(claims.roles ?: []) ? claims.roles : [],
                checks: roleChecks,
                platform: {
                    valid: platformAuthorization.valid,
                    authorized: platformAuthorization.authorized,
                    code: platformAuthorization.code
                },
                plan: claims.plan ?: "free",
                subscriptionStatus: claims.subscriptionStatus ?: "active",
                subscriptionExpiresAt: claims.subscriptionExpiresAt ?: "",
                entitlements: claims.entitlements ?: {}
            }
        );
    }

    function register(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        param rc.workspaceName = '';
        param rc.organizationType = 'business';
        param rc.name = '';
        param rc.email = '';
        param rc.password = '';
        try {
            var registration = authService.register(
                workspaceName = rc.workspaceName,
                organizationType = rc.organizationType,
                name = rc.name,
                email = rc.email,
                password = rc.password
            );
            var accessToken = startSession(registration.user);
            return success(event, sessionPayload(accessToken), {}, 201);
        } catch (any error) {
            return failureForError(event, 422, 'REGISTRATION_VALIDATION_FAILED', error);
        }
    }

    function me(event, rc, prc) {
        if (!requireMethod(event, 'GET')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        return success(event, sessionPayload(request.authAccessToken ?: bearerAccessToken()));
    }

    function workspaceContext(event, rc, prc) {
        if (!requireMethod(event, 'GET') || !requireAuthentication(event)) return request.duePilotApiResponse;
        try {
            var context = duePilotService.getWorkspaceContext();
            context.access = subscriptionService.getAccessContext(session.user);
            context.plans = subscriptionService.planCatalog();
            return success(event, context);
        } catch (any error) {
            return failureForError(event, 503, 'WORKSPACE_CONTEXT_UNAVAILABLE', error);
        }
    }

    function subscription(event, rc, prc) {
        // GET is the canonical method for this read-only resource. Accept a
        // legacy POST from already-open frontend tabs as a compatibility
        // measure; it has no side effects and prevents an old client bundle
        // from displaying a misleading method error after a deployment.
        var subscriptionMethod = uCase(cgi.request_method ?: 'GET');
        if (subscriptionMethod != 'GET' && subscriptionMethod != 'POST') {
            arguments.event.setHTTPHeader(name = 'Allow', value = 'GET, POST');
            return failure(event, 405, 'METHOD_NOT_ALLOWED', 'This endpoint supports GET and POST.');
        }
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        try {
            return success(event, {current: subscriptionService.getAccessContext(session.user), plans: subscriptionService.planCatalog()});
        } catch (any error) {
            // Keep database/migration failures inside the API envelope. The
            // frontend can then show a useful recovery message instead of
            // treating an HTML/error-stream response as unreadable JSON.
            return failureForError(event, 503, 'SUBSCRIPTION_SERVICE_UNAVAILABLE', error);
        }
    }

    function subscribe(event, rc, prc) {
        if (!requireMethod(event, 'POST') || !requireAuthentication(event)) return request.duePilotApiResponse;
        param rc.plan = '';
        try {
            var access = subscriptionService.subscribe(session.user, rc.plan);
            session.user = subscriptionService.enrichAccount(session.user);
            var subscriptionPair = tokenManager.issue(buildTokenSubject(session.user));
            session.tokens = {refreshToken: subscriptionPair.refreshToken};
            return success(event, {subscription: access, session: sessionPayload(subscriptionPair.accessToken)});
        } catch (any error) {
            return failureForError(event, 422, 'SUBSCRIPTION_FAILED', error);
        }
    }

    function workspaces(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        if (method == 'GET') return success(event, {items: subscriptionService.listWorkspaces(session.user), access: subscriptionService.getAccessContext(session.user)});
        if (method != 'POST') return failure(event, 405, 'METHOD_NOT_ALLOWED', 'This endpoint supports GET and POST.');
        param rc.name = '';
        param rc.organizationType = 'business';
        try {
            return success(event, subscriptionService.createChildWorkspace(session.user, rc.name, rc.organizationType), {}, 201);
        } catch (any error) {
            return failureForError(event, 422, 'WORKSPACE_CREATE_FAILED', error);
        }
    }

    function workspaceUnits(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        if (method == 'GET') return success(event, {items: subscriptionService.listWorkspaceUnits(session.user), access: subscriptionService.getAccessContext(session.user)});
        if (method != 'POST') return failure(event, 405, 'METHOD_NOT_ALLOWED', 'This endpoint supports GET and POST.');
        param rc.name = '';
        param rc.unitType = 'department';
        param rc.parentUnitId = '';
        param rc.code = '';
        try {
            return success(event, subscriptionService.createWorkspaceUnit(session.user, rc.name, rc.unitType, rc.parentUnitId, rc.code), {}, 201);
        } catch (any error) {
            return failureForError(event, 422, 'WORKSPACE_UNIT_CREATE_FAILED', error);
        }
    }

    function personalSummary(event, rc, prc) {
        if (!requireMethod(event, 'GET') || !requireAuthentication(event)) return request.duePilotApiResponse;
        try {
            return success(event, duePilotService.getPersonalSummary());
        } catch (any error) {
            return failure(
                event,
                422,
                'PERSONAL_SUMMARY_UNAVAILABLE',
                error.message
            );
        }
    }

    function personalProfile(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        var summary = {};
        try { summary = duePilotService.getPersonalSummary(); } catch (any error) { return failure(event, 422, 'PERSONAL_PROFILE_UNAVAILABLE', error.message); }
        if (method == 'GET') return success(event, summary.profile);
        if (method != 'POST') return failure(event, 405, 'METHOD_NOT_ALLOWED', 'This endpoint supports GET and POST.');
        param rc.displayName = session.user.name ?: '';
        param rc.mobile = '';
        try {
            summary = duePilotService.updatePersonalProfile(rc.displayName, rc.mobile);
            return success(event, summary.profile);
        } catch (any error) {
            return failureForError(event, 422, 'PERSONAL_PROFILE_INVALID', error);
        }
    }

    function personalObligations(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        try {
            if (method == 'GET') return success(event, duePilotService.getPersonalSummary().obligations);
            if (method != 'POST') return failure(event, 405, 'METHOD_NOT_ALLOWED', 'This endpoint supports GET and POST.');
            param rc.providerName = '';
            param rc.category = 'other';
            param rc.title = '';
            param rc.externalReference = '';
            param rc.amount = 0;
            param rc.dueDate = '';
            param rc.issueDate = '';
            param rc.currency = 'INR';
            var summary = duePilotService.createPersonalObligation(
                providerName = rc.providerName,
                category = rc.category,
                title = rc.title,
                externalReference = rc.externalReference,
                amount = val(rc.amount),
                dueDate = rc.dueDate,
                issueDate = rc.issueDate,
                currency = rc.currency
            );
            return success(event, summary);
        } catch (any error) {
            return failureForError(event, 422, 'PERSONAL_OBLIGATION_INVALID', error);
        }
    }

    function logout(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        lock scope="session" type="exclusive" timeout="5" {
            authService.logLogout(session.user.id, session.user.email);
            structDelete(session, 'user');
            structDelete(session, 'tokens');
        }
        return success(event, {signedOut: true});
    }

    function profile(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        if (method == 'GET') return success(event, authService.getProfile(session.user.id));
        if (method != 'POST')
            return failure(
                event,
                405,
                'METHOD_NOT_ALLOWED',
                'This endpoint supports GET and POST.'
            );
        param rc.name = '';
        try {
            var profile = authService.updateProfile(session.user.id, rc.name);
            session.user.name = profile.name;
            session.user.initials = profile.initials;
            return success(event, profile);
        } catch (any error) {
            return failureForError(event, 422, 'PROFILE_VALIDATION_FAILED', error);
        }
    }

    function saveProfilePhoto(event, rc, prc) {
        if (!requireMethod(event, 'POST') || !requireAuthentication(event))
            return request.duePilotApiResponse;
        param rc.contentType = '';
        param rc.imageBase64 = '';
        try {
            return success(event, authService.saveProfilePhoto(session.user.id, rc.contentType, rc.imageBase64));
        } catch (any error) {
            return failureForError(event, 422, 'PROFILE_PHOTO_INVALID', error);
        }
    }

    function removeProfilePhoto(event, rc, prc) {
        if (!requireMethod(event, 'POST') || !requireAuthentication(event))
            return request.duePilotApiResponse;
        return success(event, authService.removeProfilePhoto(session.user.id));
    }

    function deleteWorkspace(event, rc, prc) {
        if (!requireMethod(event, 'POST') || !requireAuthentication(event))
            return request.duePilotApiResponse;
        param rc.confirmation = '';
        try {
            authService.deleteOwnWorkspace(session.user, rc.confirmation);
            lock scope="session" type="exclusive" timeout="5" {
                structClear(session);
            }
            return success(event, {deleted: true});
        } catch (any error) {
            return failureForError(event, 422, 'WORKSPACE_DELETE_FAILED', error);
        }
    }

    function adminOverview(event, rc, prc) {
        if (!requireMethod(event, 'GET') || !requirePlatformAdmin(event)) return request.duePilotApiResponse;
        return success(event, authService.getAdminOverview());
    }

    function adminDeleteWorkspace(event, rc, prc) {
        if (!requireMethod(event, 'POST') || !requirePlatformAdmin(event))
            return request.duePilotApiResponse;
        try {
            authService.adminDeleteWorkspace(rc.workspaceId ?: '', session.user.id);
            return success(event, {deleted: true});
        } catch (any error) {
            return failureForError(event, 422, 'ADMIN_WORKSPACE_DELETE_FAILED', error);
        }
    }

    function dashboard(event, rc, prc) {
        if (!requireMethod(event, 'GET')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var dashboardData = duePilotService.getDashboard();
        dashboardData.organization.plan = subscriptionService.getAccessContext(session.user).plan;
        return success(event, dashboardData);
    }

    function invoices(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        if (method == 'POST') {
            param rc.customerId = '';
            param rc.amount = 0;
            param rc.issueDate = '';
            param rc.dueDate = '';
            param rc.purchaseOrder = '';
            param rc.description = '';
            try {
                var created = duePilotService.createInvoice(
                    customerId = rc.customerId,
                    amount = val(rc.amount),
                    issueDate = rc.issueDate,
                    dueDate = rc.dueDate,
                    purchaseOrder = rc.purchaseOrder,
                    description = rc.description
                );
                return success(event, created, {}, 201);
            } catch (any error) {
                return failureForError(event, 422, 'INVOICE_VALIDATION_FAILED', error);
            }
        }
        if (method != 'GET') {
            event.setHTTPHeader(name = 'Allow', value = 'GET, POST');
            return failure(
                event,
                405,
                'METHOD_NOT_ALLOWED',
                'This endpoint supports GET and POST.'
            );
        }
        param rc.status = 'all';
        param rc.search = '';
        return success(
            event,
            duePilotService.listInvoices(rc.status, rc.search),
            {filters: {status: rc.status, search: rc.search}}
        );
    }

    function recordPayment(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        param rc.amount = 0;
        param rc.reference = '';
        try {
            return success(event, duePilotService.recordPayment(rc.invoiceId ?: '', val(rc.amount), rc.reference));
        } catch (any error) {
            return failureForError(event, 422, 'PAYMENT_VALIDATION_FAILED', error);
        }
    }

    function savePromise(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        param rc.promiseDate = '';
        param rc.note = '';
        try {
            return success(event, duePilotService.savePromise(rc.invoiceId ?: '', rc.promiseDate, rc.note));
        } catch (any error) {
            return failureForError(event, 422, 'PROMISE_VALIDATION_FAILED', error);
        }
    }

    function openDispute(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        param rc.reason = '';
        try {
            return success(event, duePilotService.openDispute(rc.invoiceId ?: '', rc.reason));
        } catch (any error) {
            return failureForError(event, 422, 'DISPUTE_VALIDATION_FAILED', error);
        }
    }

    function sendReminder(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        param rc.channel = 'email';
        try {
            return success(event, duePilotService.sendReminder(rc.invoiceId ?: '', rc.channel));
        } catch (any error) {
            return failureForError(event, 422, 'REMINDER_VALIDATION_FAILED', error);
        }
    }

    function invoice(event, rc, prc) {
        if (!requireMethod(event, 'GET')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        try {
            return success(event, duePilotService.getInvoice(rc.invoiceId ?: ''));
        } catch (any error) {
            return failure(
                event,
                404,
                'INVOICE_NOT_FOUND',
                error.message
            );
        }
    }

    function customers(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        if (method == 'POST') {
            param rc.name = '';
            param rc.contactName = '';
            param rc.email = '';
            param rc.phone = '';
            param rc.externalReference = '';
            try {
                return success(
                    event,
                    duePilotService.createCustomer(
                        rc.name,
                        rc.contactName,
                        rc.email,
                        rc.phone,
                        rc.externalReference
                    ),
                    {},
                    201
                );
            } catch (any error) {
                return failureForError(event, 422, 'CUSTOMER_VALIDATION_FAILED', error);
            }
        }
        if (method != 'GET') return request.duePilotApiResponse;
        param rc.search = '';
        return success(event, duePilotService.listCustomers(rc.search), {filters: {search: rc.search}});
    }

    function reports(event, rc, prc) {
        if (!requireMethod(event, 'GET')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        return success(event, duePilotService.getReports());
    }

    function settings(event, rc, prc) {
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var method = uCase(cgi.request_method ?: 'GET');
        if (method == 'GET') {
            var organization = duePilotService.getOrganization();
            organization.plan = subscriptionService.getAccessContext(session.user).plan;
            return success(event, organization);
        }
        if (method != 'POST') {
            event.setHTTPHeader(name = 'Allow', value = 'GET, POST');
            return failure(
                event,
                405,
                'METHOD_NOT_ALLOWED',
                'This endpoint supports GET and POST.'
            );
        }
        param rc.name = '';
        param rc.currency = 'INR';
        param rc.financeEmail = '';
        param rc.defaultTerms = 30;
        try {
            var updatedOrganization = duePilotService.updateOrganization(
                name = rc.name,
                currency = rc.currency,
                financeEmail = rc.financeEmail,
                defaultTerms = val(rc.defaultTerms)
            );
            updatedOrganization.plan = subscriptionService.getAccessContext(session.user).plan;
            return success(
                event,
                updatedOrganization
            );
        } catch (any error) {
            return failureForError(event, 422, 'WORKSPACE_VALIDATION_FAILED', error);
        }
    }

    function assistantStatus(event, rc, prc) {
        if (!requireMethod(event, 'GET')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        var status = duePilotAiService.getStatus();
        status.access = subscriptionService.getAccessContext(session.user);
        return success(event, status);
    }

    function assistantChat(event, rc, prc) {
        if (!requireMethod(event, 'POST')) return request.duePilotApiResponse;
        if (!requireAuthentication(event)) return request.duePilotApiResponse;
        param rc.message = '';
        if (!isSimpleValue(rc.message) || !len(trim(rc.message)) || len(trim(rc.message)) > 2000) {
            return failure(
                event,
                422,
                'AI_MESSAGE_INVALID',
                'Enter a plain-text question between 1 and 2,000 characters.'
            );
        }
        if (!consumeAssistantRateLimit()) {
            return failure(
                event,
                429,
                'AI_RATE_LIMITED',
                'You have reached the assistant limit. Wait a minute and try again.'
            );
        }
        try {
            var aiAccess = subscriptionService.reserveAiRequest(session.user);
            var requestHistory = structKeyExists(rc, 'history') && isArray(rc.history) ? rc.history : [];
            var requestContext = structKeyExists(rc, 'context') && isStruct(rc.context) ? rc.context : {};
            var result = duePilotAiService.chat(
                message = rc.message,
                history = requestHistory,
                pageContext = requestContext
            );
            structDelete(result, 'ok');
            result.usage = aiAccess.usage;
            result.plan = aiAccess.plan;
            return success(event, result);
        } catch (any error) {
            if (findNoCase('aiquotaexceeded', lCase(toString(error.type ?: '')))) {
                return failure(event, 429, 'AI_QUOTA_EXCEEDED', error.message);
            }
            writeLog(
                text = 'assistantChat failed: type=' & toString(error.type ?: 'Unknown') &
                    ' message=' & toString(error.message ?: 'Unknown error'),
                type = 'error',
                log = 'application'
            );
            return failure(event, 503, 'AI_UNAVAILABLE', error.message);
        }
    }

    private boolean function requireAuthentication(required any event) {
        if (!hasSessionTokens()) {
            failure(
                arguments.event,
                401,
                'AUTHENTICATION_REQUIRED',
                'Sign in to continue.'
            );
            return false;
        }

        var accessToken = bearerAccessToken();
        if (!len(accessToken)) {
            failure(
                arguments.event,
                401,
                'AUTHENTICATION_REQUIRED',
                'Send a valid bearer access token.'
            );
            return false;
        }

        var diagnosis = tokenManager.diagnose(accessToken, 'access');
        if (!diagnosis.valid) {
            failure(
                arguments.event,
                401,
                'AUTHENTICATION_REQUIRED',
                'Your access session is no longer valid.',
                [{code: diagnosis.code}]
            );
            return false;
        }

        session.user = subscriptionService.enrichAccount(session.user);
        var trustedClaims = tokenManager.decode(accessToken);
        request.authAccessToken = accessToken;
        if ((trustedClaims.plan ?: 'free') != session.user.plan || (trustedClaims.subscriptionStatus ?: '') != session.user.subscriptionStatus) {
            var rotatedPair = tokenManager.issue(buildTokenSubject(session.user));
            session.tokens = {refreshToken: rotatedPair.refreshToken};
            request.authAccessToken = rotatedPair.accessToken;
            arguments.event.setHTTPHeader(name = 'X-New-Access-Token', value = rotatedPair.accessToken);
        }
        return true;
    }

    private boolean function requirePlatformAdmin(required any event) {
        if (!requireAuthentication(arguments.event)) return false;
        var accessToken = request.authAccessToken ?: bearerAccessToken();
        var diagnosis = tokenManager.diagnoseAuthorization(accessToken, 'platform_admin');
        if (!diagnosis.valid) {
            failure(
                arguments.event,
                401,
                'AUTHENTICATION_REQUIRED',
                'Your access session is no longer valid.',
                [{code: diagnosis.code}]
            );
            return false;
        }
        if (!diagnosis.authorized) {
            failure(
                arguments.event,
                403,
                'ADMIN_ACCESS_REQUIRED',
                'This action requires platform administrator access.'
            );
            return false;
        }
        return true;
    }

    private string function startSession(required struct account) {
        var accessToken = '';
        lock scope="session" type="exclusive" timeout="5" {
            session.user = subscriptionService.enrichAccount(arguments.account);
            var pair = tokenManager.issue(buildTokenSubject(session.user));
            session.tokens = {refreshToken: pair.refreshToken};
            accessToken = pair.accessToken;
        }
        return accessToken;
    }

    private struct function buildTokenSubject(required struct account) {
        var roles = [arguments.account.role];
        if (structKeyExists(arguments.account, 'isPlatformAdmin') && arguments.account.isPlatformAdmin) {
            roles.append('platform_admin');
        }
        return {
            id: arguments.account.id,
            role: arguments.account.role,
            roles: roles,
            email: arguments.account.email,
            workspaceId: arguments.account.workspaceId ?: '',
            plan: arguments.account.plan ?: 'free',
            subscriptionStatus: arguments.account.subscriptionStatus ?: 'active',
            subscriptionExpiresAt: arguments.account.subscriptionExpiresAt ?: '',
            entitlements: arguments.account.entitlements ?: {}
        };
    }

    private struct function sessionPayload(string accessToken = '') {
        var access = subscriptionService.getAccessContext(session.user);
        var workspace = duePilotService.getOrganization();
        workspace.plan = access.plan;
        var currentAccessToken = arguments.accessToken;
        if (!len(currentAccessToken) && structKeyExists(request, 'authAccessToken')) {
            currentAccessToken = request.authAccessToken;
        }
        return {
            user: duplicate(session.user),
            workspace: workspace,
            accessToken: currentAccessToken,
            access: access
        };
    }

    private boolean function hasSessionTokens() {
        return structKeyExists(session, 'user')
        && isStruct(session.user)
        && structKeyExists(session, 'tokens')
        && isStruct(session.tokens)
        && structKeyExists(session.tokens, 'refreshToken');
    }

    private void function clearAuthenticationSession() {
        lock scope="session" type="exclusive" timeout="5" {
            structDelete(session, 'user');
            structDelete(session, 'tokens');
        }
    }

    private numeric function epochSeconds() {
        return int(createObject('java', 'java.lang.System').currentTimeMillis() / 1000);
    }

    private boolean function consumeAssistantRateLimit() {
        var allowed = true;
        var rateIdentity = session.user.id ?: session.user.email ?: 'anonymous';
        var lockKey = 'duepilot-api-ai-rate-' & hash(toString(rateIdentity));
        lock name=lockKey type="exclusive" timeout="3" {
            if (
                !structKeyExists(session, 'aiApiRateLimit') || dateDiff('s', session.aiApiRateLimit.startedAt, now()) >= 60
            ) {
                session.aiApiRateLimit = {startedAt: now(), count: 0};
            }
            if (session.aiApiRateLimit.count >= 10) {
                allowed = false;
            } else {
                session.aiApiRateLimit.count++;
            }
        }
        return allowed;
    }

    private string function bearerAccessToken() {
        var authorization = trim(toString(cgi.http_authorization ?: ''));
        if (!reFindNoCase('^Bearer\s+', authorization)) return '';
        return trim(reReplaceNoCase(authorization, '^Bearer\s+', ''));
    }

    private boolean function requireMethod(required any event, required string method) {
        if (compareNoCase(cgi.request_method ?: 'GET', arguments.method) == 0) {
            return true;
        }
        arguments.event.setHTTPHeader(name = 'Allow', value = arguments.method);
        failure(
            arguments.event,
            405,
            'METHOD_NOT_ALLOWED',
            'This endpoint requires #arguments.method#.'
        );
        return false;
    }

    /**
     * Translate domain failures into stable HTTP semantics without exposing
     * database/provider internals to the client.
     */
    private numeric function statusForError(required any error, numeric fallbackStatus = 422) {
        var errorType = '';
        if (isStruct(arguments.error) && structKeyExists(arguments.error, 'type')) {
            errorType = lCase(toString(arguments.error.type));
        }
        if (findNoCase('notfound', errorType)) return 404;
        if (findNoCase('forbidden', errorType) || findNoCase('planlimit', errorType)) return 403;
        if (
            findNoCase('duplicate', errorType)
            || findNoCase('emailinuse', errorType)
            || findNoCase('mobileinuse', errorType)
            || findNoCase('alreadypaid', errorType)
            || findNoCase('overpayment', errorType)
        ) return 409;
        return arguments.fallbackStatus;
    }

    private any function failureForError(
        required any event,
        required numeric fallbackStatus,
        required string code,
        required any error
    ) {
        return failure(
            arguments.event,
            statusForError(arguments.error, arguments.fallbackStatus),
            arguments.code,
            arguments.error.message
        );
    }

    private any function success(
        required any event,
        required any data,
        struct meta = {},
        numeric statusCode = 200
    ) {
        var responseMeta = duplicate(arguments.meta);
        responseMeta.apiVersion = 'v1';
        responseMeta.requestId = createUUID();
        responseMeta.timestamp = dateTimeFormat(dateConvert('local2utc', now()), 'yyyy-MM-dd''T''HH:nn:ss''Z''');
        arguments.event.setHTTPHeader(statusCode = arguments.statusCode);
        arguments.event.setHTTPHeader(name = 'Content-Type', value = 'application/json; charset=utf-8');
        arguments.event.setHTTPHeader(name = 'Cache-Control', value = 'no-store');
        arguments.event.setHTTPHeader(name = 'X-Content-Type-Options', value = 'nosniff');
        var responseBody = jsonSerialize(toApiCase({'ok': true, 'data': arguments.data, 'meta': responseMeta}));
        request.duePilotApiResponse = responseBody;
        return responseBody;
    }

    private any function failure(
        required any event,
        required numeric statusCode,
        required string code,
        required string message,
        array details = []
    ) {
        arguments.event.setHTTPHeader(statusCode = arguments.statusCode);
        arguments.event.setHTTPHeader(name = 'Content-Type', value = 'application/json; charset=utf-8');
        arguments.event.setHTTPHeader(name = 'Cache-Control', value = 'no-store');
        arguments.event.setHTTPHeader(name = 'X-Content-Type-Options', value = 'nosniff');
        var responseBody = jsonSerialize(
            toApiCase({
                'ok': false,
                'error': {'code': arguments.code, 'message': arguments.message, 'details': arguments.details},
                'meta': {'apiVersion': 'v1', 'requestId': createUUID()}
            })
        );
        request.duePilotApiResponse = responseBody;
        return responseBody;
    }

    /**
     * CFML-compatible structs are case-insensitive and therefore store unquoted
     * keys in uppercase. Rebuild API values as case-sensitive structs using the
     * public contract vocabulary before JSON serialization.
     */
    private any function toApiCase(required any value) {
        if (isArray(arguments.value)) {
            return arguments.value.map(function(item) {
                return toApiCase(item);
            });
        }
        if (!isStruct(arguments.value)) {
            return arguments.value;
        }

        var canonicalNames = listToArray(
            'ok,data,meta,error,code,message,details,apiVersion,requestId,timestamp,' &
            'service,version,status,persistence,signedOut,user,workspace,workspaceId,accessToken,' &
            'id,name,email,role,initials,isPlatformAdmin,plan,currency,financeEmail,defaultTerms,' &
            'organization,outstanding,overdueAmount,overdueCount,dueSoonAmount,' &
            'disputedAmount,collectedAmount,collectionRate,customerCount,' &
            'priorityInvoices,recentActivity,aging,forecast,current,oneToThirty,' &
            'thirtyOneToSixty,overSixty,total,label,amount,confidence,kind,title,' &
            'detail,at,invoiceId,invoiceNumber,customerId,customerName,paidAmount,' &
            'issueDate,dueDate,description,purchaseOrder,owner,promiseDate,' &
            'promiseNote,statusOverride,disputeReason,reminderCount,lastContactAt,' &
            'paidAt,paymentRef,portalToken,daysUntilDue,daysOverdue,paymentPercent,' &
            'contact,phone,color,avgDaysLate,invoiceCount,overdue,paid,health,' &
            'topCustomers,avgDaysToPay,promiseKept,monthly,billed,collected,filters,search,' &
            'enabled,configured,keyCount,provider,model,mode,answer,evidence,nextActions,source,' &
            'financeEmail,defaultTerms,photoUrl,createdAt,lastLogin,deleted,workspaceCount,userCount,loginsToday,invoiceCount,workspaces,loginEvents,slug,memberCount,usage30d,outcome,' &
            'profile,connections,obligations,summary,displayName,mobileLast4,mobileVerified,providerName,category,externalReference,balance,daysUntilDue,daysOverdue'
        );
        var keyMap = structNew('casesensitive');
        for (var canonicalName in canonicalNames) {
            keyMap[uCase(toString(canonicalName))] = toString(canonicalName);
        }

        // A Java map keeps String keys intact across the ColdBox/BoxLang JSON
        // boundary. Dynamic writes to a case-sensitive BoxLang struct currently
        // expose internal Key objects through ColdBox's marshaller.
        var output = createObject('java', 'java.util.LinkedHashMap').init();
        for (var sourceKey in arguments.value) {
            var sourceKeyName = toString(sourceKey);
            var upperKey = uCase(sourceKeyName);
            var targetKey = toString(structKeyExists(keyMap, upperKey) ? keyMap[upperKey] : lCase(sourceKeyName));
            output.put(targetKey, toApiCase(arguments.value[sourceKey]));
        }
        return output;
    }

}
