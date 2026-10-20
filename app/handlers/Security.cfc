/** Authentication and JWT session lifecycle for DuePilot. */
component extends="coldbox.system.EventHandler" {

    property name="tokenManager" inject="TokenManager@cf-token-manager";
    property name="settings" inject="coldbox:moduleSettings:cf-token-manager";
    property name="authService" inject="AuthService";

    function index(event, rc, prc) {
        relocate(URI = isLoggedIn() ? '/dashboard' : '/login');
    }

    function login(event, rc, prc) {
        if (isLoggedIn()) {
            relocate(URI = '/dashboard');
            return;
        }
        prc.pageTitle = 'Sign in';
        event.setLayout('Auth');
        event.setView('security/login');
    }

    function doLogin(event, rc, prc) {
        if (compareNoCase(cgi.request_method ?: 'GET', 'POST') != 0) {
            event.setHTTPHeader(name = 'Allow', value = 'POST');
            return event.renderData(
                type = 'html',
                statusCode = 405,
                data = '<h1>Method not allowed</h1><p>Sign in using the login form.</p>'
            );
        }
        param rc.username = '';
        param rc.password = '';
        var authentication = authService.authenticate(rc.username, rc.password);

        if (authentication.authenticated) {
            var account = authentication.user;
            lock scope="session" type="exclusive" timeout="5" {
                session.user = account;
                session.tokens = tokenManager.issue(buildTokenSubject(account));
                session.csrfToken = hash(createUUID() & getTickCount(), 'SHA-256');
            }
            relocate(URI = '/dashboard');
            return;
        }

        relocate(URI = '/login', persistStruct = {error: 'That email or password is not correct.'});
    }

    function dashboard(event, rc, prc) {
        relocate(URI = '/dashboard');
    }

    function refreshToken(event, rc, prc) {
        if (!isLoggedIn()) {
            return event.renderData(type = 'json', statusCode = 401, data = {ok: false, reason: 'NOT_LOGGED_IN'});
        }
        var diagnosis = tokenManager.diagnose(session.tokens.refreshToken, 'refresh');
        if (!diagnosis.valid) {
            killSession();
            return event.renderData(
                type = 'json',
                statusCode = 401,
                data = {ok: false, reason: diagnosis.code, message: diagnosis.message}
            );
        }
        var result = tokenManager.refresh(session.tokens.refreshToken);
        lock scope="session" type="exclusive" timeout="5" {
            session.tokens.accessToken = result.accessToken;
        }
        var accessClaims = tokenManager.decode(result.accessToken);
        var refreshClaims = tokenManager.decode(session.tokens.refreshToken);
        return event.renderData(
            type = 'json',
            data = {
                ok: true,
                accessToken: result.accessToken,
                accessIn: accessClaims.exp - nowEpoch(),
                refreshIn: refreshClaims.exp - nowEpoch()
            }
        );
    }

    function logout(event, rc, prc) {
        if (compareNoCase(cgi.request_method ?: 'GET', 'POST') != 0) {
            event.setHTTPHeader(name = 'Allow', value = 'POST');
            return event.renderData(
                type = 'html',
                statusCode = 405,
                data = '<h1>Method not allowed</h1><p>Sign out from the workspace menu.</p>'
            );
        }
        param rc.csrfToken = '';
        if (!isLoggedIn() || !structKeyExists(session, 'csrfToken') || rc.csrfToken != session.csrfToken) {
            return event.renderData(
                type = 'html',
                statusCode = 403,
                data = '<h1>Request expired</h1><p>Refresh the workspace and try again.</p>'
            );
        }
        killSession();
        relocate(URI = '/login', persistStruct = {notice: 'You have been signed out safely.'});
    }

    private boolean function isLoggedIn() {
        return structKeyExists(session, 'user') && isStruct(session.user) && structKeyExists(session, 'tokens');
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
            email: arguments.account.email
        };
    }

    private void function killSession() {
        lock scope="session" type="exclusive" timeout="5" {
            structDelete(session, 'user');
            structDelete(session, 'tokens');
            structDelete(session, 'csrfToken');
        }
    }

    private numeric function nowEpoch() {
        return int(createObject('java', 'java.lang.System').currentTimeMillis() / 1000);
    }

}
