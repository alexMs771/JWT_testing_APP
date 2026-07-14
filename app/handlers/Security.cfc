/**
 * Security — the demo application that shows the cf-token-manager lifecycle
 * the way a real app uses it:
 *
 *   1. User logs in            -> issue()  mints an access + refresh token pair
 *   2. Tokens are shown live   -> decode() reads iat/exp for the countdowns
 *   3. Access token expires     -> refresh() silently mints a new access token
 *   4. Refresh token expires    -> the user is logged out automatically
 *
 * Token lifetimes are configured by the developer in
 * config/Coldbox.cfc -> moduleSettings["cf-token-manager"].
 */
component extends="coldbox.system.EventHandler" {

	property name="tokenManager" inject="TokenManager@cf-token-manager";
	property name="settings"     inject="coldbox:moduleSettings:cf-token-manager";

	/**
	 * Hardcoded demo users (no database).
	 */
	variables.users = {
		"test" : "test",
		"user" : "pass"
	};

	function index( event, rc, prc ){
		relocate( "security.login" );
	}

	/**
	 * Login screen.
	 */
	function login( event, rc, prc ){
		if ( isLoggedIn() ) {
			relocate( "security.dashboard" );
			return;
		}
		prc.pageTitle = "Sign in";
		event.setLayout( "Simple" );
		event.setView( "security/login" );
	}

	/**
	 * Validate credentials and, on success, ISSUE the first token pair.
	 */
	function doLogin( event, rc, prc ){
		param rc.username = "";
		param rc.password = "";

		var username = trim( rc.username );

		if ( variables.users.keyExists( username ) && variables.users[ username ] == rc.password ) {
			lock scope="session" type="exclusive" timeout="5" {
				session.user   = username;
				// issue() -> the first access + refresh token pair for this session
				session.tokens = tokenManager.issue( { id : username, role : "customer", email : "test@test.com" });
			}
			relocate( "security.dashboard" );
			return;
		}

		relocate(
			event         = "security.login",
			persistStruct = { "error" : "Invalid username or password. Please try again." }
		);
	}

	/**
	 * The protected dashboard — visible only while a valid session exists.
	 * Renders the live token console (countdowns + activity log run client-side).
	 */
	function dashboard( event, rc, prc ){
		if ( !isLoggedIn() ) {
			relocate( event = "security.login", persistStruct = { "error" : "Please log in to continue." } );
			return;
		}

		var now = nowEpoch();

		prc.username      = session.user;
		prc.tokens        = session.tokens;
		prc.accessClaims  = tokenManager.decode( session.tokens.accessToken );
		prc.refreshClaims = tokenManager.decode( session.tokens.refreshToken );

		prc.accessTTL   = int( settings.accessTokenExpiry );
		prc.refreshTTL  = int( settings.refreshTokenExpiry );
		prc.accessIn    = prc.accessClaims.exp - now;   // seconds until access expires
		prc.refreshIn   = prc.refreshClaims.exp - now;  // seconds until refresh expires

		prc.pageTitle = "Dashboard";
		event.setLayout( "Simple" );
		event.setView( "security/dashboard" );
	}

	/**
	 * JSON endpoint called by the dashboard when the access token expires.
	 * Uses refresh() to mint a new access token. If the refresh token itself
	 * is expired/invalid, the session is killed and the client is told to log out.
	 */
	function refreshToken( event, rc, prc ){
		if ( !isLoggedIn() ) {
			return event.renderData( type = "json", data = { "ok" : false, "reason" : "NOT_LOGGED_IN" } );
		}

		// Is the refresh token still good? diagnose() tells us exactly.
		var diag = tokenManager.diagnose( session.tokens.refreshToken, "refresh" );
		if ( !diag.valid ) {
			killSession();
			return event.renderData( type = "json", data = { "ok" : false, "reason" : diag.code, "message" : diag.message } );
		}

		var result = tokenManager.refresh( session.tokens.refreshToken );
		lock scope="session" type="exclusive" timeout="5" {
			session.tokens.accessToken = result.accessToken;
		}

		var now           = nowEpoch();
		var accessClaims  = tokenManager.decode( result.accessToken );
		var refreshClaims = tokenManager.decode( session.tokens.refreshToken );

		return event.renderData( type = "json", data = {
			"ok"          : true,
			"accessToken" : result.accessToken,
			"accessIn"    : accessClaims.exp - now,
			"refreshIn"   : refreshClaims.exp - now
		} );
	}

	function logout( event, rc, prc ){
		killSession();
		relocate( event = "security.login", persistStruct = { "error" : "You have been logged out." } );
	}

	/* --------------------------------------------------------------------- */
	/* Internals                                                             */
	/* --------------------------------------------------------------------- */

	private boolean function isLoggedIn(){
		return structKeyExists( session, "user" )
			&& len( session.user )
			&& structKeyExists( session, "tokens" );
	}

	private void function killSession(){
		lock scope="session" type="exclusive" timeout="5" {
			structDelete( session, "user" );
			structDelete( session, "tokens" );
		}
	}

	private numeric function nowEpoch(){
		return int( createObject( "java", "java.lang.System" ).currentTimeMillis() / 1000 );
	}

}
