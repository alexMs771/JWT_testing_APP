/**
 * TokenDemo — Live demo console for the cf-token-manager module.
 *
 * Purpose: give a single, self-explanatory screen that exercises EVERY public
 * function of the package across ALL its dimensions, so it can be walked through
 * live in a review:
 *
 *   Public API .............. issue(), decode(), verify(), refresh()
 *   Diagnostics ............. validate(), diagnose()
 *
 * The "self-test matrix" runs the happy path AND every failure mode
 * (tampered signature, wrong secret, expired, malformed, missing, wrong type)
 * and reports expected-vs-actual for each — proving the module behaves.
 */
component extends="coldbox.system.EventHandler" {

	// The star of the show — the module's public API.
	property name="tokenManager" inject="TokenManager@cf-token-manager";
	// Low-level engine, used ONLY to fabricate edge-case fixtures (e.g. an
	// already-expired or wrong-secret token) for the self-test matrix.
	property name="jwt"          inject="JWTService@cf-token-manager";
	// Module settings, so the UI can show the configured policy (TTLs, alg, issuer).
	property name="settings"     inject="coldbox:moduleSettings:cf-token-manager";

	/**
	 * Main demo dashboard.
	 */
	function index( event, rc, prc ){
		prepare( event, rc, prc );
		event.setLayout( "Simple" );
		event.setView( "tokenDemo/index" );
	}

	/**
	 * issue() demo — mint a fresh token pair for a caller-supplied subject.
	 */
	function issue( event, rc, prc ){
		ensureTokens();
		param rc.id    = "";
		param rc.role  = "customer";
		param rc.email = "";

		try {
			var subject = demoSubject( session.demoEntitlement );
			subject.id = trim( rc.id );
			subject.role = trim( rc.role );
			subject.roles = [ trim( rc.role ) ];
			if ( len( trim( rc.email ) ) ) {
				subject[ "email" ] = trim( rc.email );
			}
			session.demoTokens = tokenManager.issue( subject );
			relocate(
				event         = "tokenDemo.index",
				persistStruct = { flashMsg : "issue() minted a new access + refresh pair for subject [#trim( rc.id )#].", flashType : "success" }
			);
		} catch ( any e ) {
			relocate(
				event         = "tokenDemo.index",
				persistStruct = { flashMsg : "issue() correctly rejected the request: #e.message#", flashType : "danger" }
			);
		}
	}

	/**
	 * refresh() demo — exchange the current refresh token for a new access token.
	 */
	function refresh( event, rc, prc ){
		ensureTokens();
		try {
			var oldExp = tokenManager.decode( session.demoTokens.accessToken ).exp;
			var result = tokenManager.refresh( session.demoTokens.refreshToken );
			lock scope="session" type="exclusive" timeout="5" {
				session.demoTokens.accessToken = result.accessToken;
			}
			var newExp = tokenManager.decode( result.accessToken ).exp;
			relocate(
				event         = "tokenDemo.index",
				persistStruct = { flashMsg : "refresh() issued a new access token. Expiry moved from #oldExp# to #newExp# (epoch seconds).", flashType : "success" }
			);
		} catch ( any e ) {
			relocate(
				event         = "tokenDemo.index",
				persistStruct = { flashMsg : "refresh() failed: #e.message#", flashType : "danger" }
			);
		}
	}

	/**
	 * Demo-only plan switch. This intentionally uses short TTLs so a reviewer
	 * can watch entitlement expiry without waiting a year. Production billing
	 * uses SubscriptionService and a one-year server-side subscription record.
	 */
	function subscribe( event, rc, prc ){
		ensureTokens();
		param rc.plan = "plus";
		var requestedPlan = lCase(trim(rc.plan));
		if (!listFindNoCase("plus,pro", requestedPlan)) {
			relocate(event="tokenDemo.index",persistStruct={flashMsg:"Choose Plus or Pro for the demo.",flashType:"danger"});
			return;
		}
		var demoDuration = requestedPlan == "plus" ? 120 : 180;
		lock scope="session" type="exclusive" timeout="5" {
			var state = session.demoEntitlement;
			state.plan = requestedPlan;
			state.subscriptionStatus = "active";
			state.startedAt = nowEpoch();
			state.expiresAt = state.startedAt + demoDuration;
			session.demoEntitlement = state;
			session.demoTokens = tokenManager.issue(demoSubject(state));
		}
		relocate(event="tokenDemo.index",persistStruct={flashMsg:"#requestedPlan# activated for the demo. It expires in #demoDuration# seconds; the signed claims will then return to free/expired.",flashType:"success"});
	}

	/**
	 * Interactive inspector — paste ANY token and run decode() + diagnose()
	 * against a chosen expected type. Demonstrates decode/verify/validate/diagnose
	 * on arbitrary input.
	 */
	function inspect( event, rc, prc ){
		param rc.token        = "";
		param rc.expectedType = "access";

		prepare( event, rc, prc );

		var result = {
			"token"        : trim( rc.token ),
			"expectedType" : rc.expectedType,
			"verify"       : tokenManager.verify( trim( rc.token ), rc.expectedType ),
			"diagnose"     : tokenManager.diagnose( trim( rc.token ), rc.expectedType ),
			"claims"       : {},
			"decodeError"  : ""
		};
		try {
			result.claims = tokenManager.decode( trim( rc.token ) );
		} catch ( any e ) {
			result.decodeError = e.message;
		}

		prc.inspect = result;
		event.setLayout( "Simple" );
		event.setView( "tokenDemo/index" );
	}

	/* --------------------------------------------------------------------- */
	/* Internals                                                             */
	/* --------------------------------------------------------------------- */

	/**
	 * Shared setup for the dashboard: current live tokens, their claims/status,
	 * the module policy, and the full self-test matrix.
	 */
	private void function prepare( event, rc, prc ){
		ensureTokens();

		prc.pageTitle = "cf-token-manager — Live Demo Console";
		prc.nowEpoch  = nowEpoch();
		prc.policy   = {
			"algorithm"          : settings.algorithm,
			"issuer"             : settings.issuer,
			"accessTokenExpiry"  : settings.accessTokenExpiry,
			"refreshTokenExpiry" : settings.refreshTokenExpiry
		};
		prc.demoState = session.demoEntitlement;
		prc.planCatalog = [
			{key:"free",name:"Free",duration:"5 minutes",ai:"3 requests",workspaces:"Main only"},
			{key:"plus",name:"Plus",duration:"2 minutes",ai:"100 requests",workspaces:"2 nested"},
			{key:"pro",name:"Pro",duration:"3 minutes",ai:"Full monthly quota",workspaces:"19 nested"}
		];

		prc.tokens        = session.demoTokens;
		prc.accessClaims  = tokenManager.decode( prc.tokens.accessToken );
		prc.refreshClaims = tokenManager.decode( prc.tokens.refreshToken );
		prc.accessDiag    = tokenManager.diagnose( prc.tokens.accessToken, "access" );
		prc.refreshDiag   = tokenManager.diagnose( prc.tokens.refreshToken, "refresh" );

		prc.matrix        = buildMatrix();
		prc.matrixPassed  = prc.matrix.filter( function( row ){ return row.pass; } ).len();
		prc.matrixTotal   = prc.matrix.len();

		prc.flashMsg  = rc.flashMsg ?: "";
		prc.flashType = rc.flashType ?: "";
		prc.inspect   = {};
	}

	/**
	 * Guarantee a live token pair exists in the session for the demo.
	 */
	private void function ensureTokens(){
		lock scope="session" type="exclusive" timeout="5" {
			if ( !structKeyExists( session, "demoEntitlement" ) ) {
				var started = nowEpoch();
				session.demoEntitlement = {plan:"free",subscriptionStatus:"trialing",startedAt:started,expiresAt:started+300,freeWindowExpiresAt:started+300};
			}
			if ( !structKeyExists( session, "demoTokens" ) ) session.demoTokens = tokenManager.issue(demoSubject(session.demoEntitlement));
		}
		syncDemoEntitlement();
	}

	private void function syncDemoEntitlement(){
		lock scope="session" type="exclusive" timeout="5" {
			if (!structKeyExists(session,"demoEntitlement")) return;
			var state = session.demoEntitlement;
			var now = nowEpoch();
			var expired = val(state.expiresAt ?: 0) <= now;
			if (expired && state.plan != "free") {
				state.plan = "free";
				state.subscriptionStatus = "expired";
				state.expiresAt = state.freeWindowExpiresAt ?: now;
				session.demoEntitlement = state;
				session.demoTokens = tokenManager.issue(demoSubject(state));
			} else if (state.plan == "free" && val(state.freeWindowExpiresAt ?: state.expiresAt) <= now && state.subscriptionStatus != "expired") {
				state.subscriptionStatus = "expired";
				state.expiresAt = state.freeWindowExpiresAt;
				session.demoEntitlement = state;
				session.demoTokens = tokenManager.issue(demoSubject(state));
			}
		}
	}

	private struct function demoSubject(required struct state){
		var plan = lCase(trim(toString(arguments.state.plan ?: "free")));
		var aiLimit = plan == "pro" ? -1 : plan == "plus" ? 100 : 3;
		var childLimit = plan == "pro" ? 19 : plan == "plus" ? 2 : 0;
		return {
			id:"alex",
			role:"member",
			roles:["member"],
			email:"alex@demo.io",
			plan:plan,
			subscriptionStatus:arguments.state.subscriptionStatus ?: "active",
			subscriptionExpiresAt:arguments.state.expiresAt ?: 0,
			entitlements:{aiRequestsPerMonth:aiLimit,childWorkspaces:childLimit,aiEnabled:plan != "free"}
		};
	}

	/**
	 * Build the automated self-test matrix: every function, every dimension,
	 * with expected-vs-actual and a pass flag.
	 */
	private array function buildMatrix(){
		var now    = nowEpoch();
		var rows   = [];

		// ---- Fixtures (some crafted via the low-level engine on purpose) ----
		var pair          = tokenManager.issue( { id : "matrix-user", role : "admin" } );
		var validAccess   = pair.accessToken;
		var validRefresh  = pair.refreshToken;
		var tampered      = flipLastChar( validAccess );
		var wrongSecret   = jwt.encode(
			{ "sub" : "matrix-user", "type" : "access", "iat" : now, "exp" : now + 900, "iss" : settings.issuer },
			"a-different-secret-than-the-module-uses",
			settings.algorithm
		);
		var expiredAccess = jwt.encode(
			{ "sub" : "matrix-user", "role" : "admin", "type" : "access", "iat" : now - 100, "exp" : now - 10, "iss" : settings.issuer },
			settings.secret,
			settings.algorithm
		);
		var malformed     = "abc.def"; // only 2 segments -> fails the 3-segment structure check
		var missing       = "";

		// ---- issue() ----
		rows.append( row(
			"issue()", "Mint a pair for a valid subject",
			"{ id : 'matrix-user', role : 'admin' }",
			"two 3-segment JWTs",
			"access segs=#listLen( validAccess, "." )#, refresh segs=#listLen( validRefresh, "." )#",
			listLen( validAccess, "." ) == 3 && listLen( validRefresh, "." ) == 3
		) );
		var issueRejected = false;
		var issueMsg      = "";
		try {
			tokenManager.issue( { role : "admin" } ); // no id/sub -> must throw
		} catch ( any e ) {
			issueRejected = true;
			issueMsg      = e.type;
		}
		rows.append( row(
			"issue()", "Reject a subject with no id/sub",
			"{ role : 'admin' }",
			"throws InvalidSubject",
			issueRejected ? issueMsg : "(no error)",
			issueRejected
		) );

		// ---- decode() ----
		var decodedTampered = tokenManager.decode( tampered );
		rows.append( row(
			"decode()", "Read claims WITHOUT verifying signature",
			"tampered access token",
			"sub = matrix-user",
			"sub = #( decodedTampered.sub ?: "?" )#",
			( decodedTampered.sub ?: "" ) == "matrix-user"
		) );

		// ---- verify() ----
		rows.append( row(
			"verify()", "Authentic, unexpired access token",
			"valid access token",
			"true",
			tokenManager.verify( validAccess, "access" ) ? "true" : "false",
			tokenManager.verify( validAccess, "access" ) == true
		) );
		rows.append( row(
			"verify()", "Tampered token is rejected",
			"tampered access token",
			"false",
			tokenManager.verify( tampered, "access" ) ? "true" : "false",
			tokenManager.verify( tampered, "access" ) == false
		) );

		// validate() is the strict, exception-oriented counterpart to diagnose().
		var validatedClaims = {};
		var validateOk      = false;
		try {
			validatedClaims = tokenManager.validate( validAccess, "access" );
			validateOk      = ( validatedClaims.sub ?: "" ) == "matrix-user";
		} catch ( any e ) {
			validatedClaims = { error : e.type };
		}
		rows.append( row(
			"validate()", "Return trusted claims for a valid token",
			"valid access token",
			"trusted claims with sub = matrix-user",
			"sub = #( validatedClaims.sub ?: validatedClaims.error ?: "?" )#",
			validateOk
		) );

		// ---- validate()/diagnose() dimensions ----
		rows.append( diagRow( "diagnose()", "Valid token",              validAccess,   "access",  "VALID" ) );
		rows.append( diagRow( "diagnose()", "Tampered signature",       tampered,      "access",  "INVALID_SIGNATURE" ) );
		rows.append( diagRow( "diagnose()", "Signed with wrong secret", wrongSecret,   "access",  "INVALID_SIGNATURE" ) );
		rows.append( diagRow( "diagnose()", "Expired token",            expiredAccess, "access",  "TOKEN_EXPIRED" ) );
		rows.append( diagRow( "diagnose()", "Malformed token",          malformed,     "access",  "MALFORMED_TOKEN" ) );
		rows.append( diagRow( "diagnose()", "Missing token",            missing,       "access",  "MISSING_TOKEN" ) );
		rows.append( diagRow( "diagnose()", "Wrong type (access as refresh)", validAccess, "refresh", "INVALID_TOKEN_TYPE" ) );

		// ---- refresh() ----
		var refreshOk   = false;
		var refreshCode = "";
		try {
			var refreshed = tokenManager.refresh( validRefresh );
			refreshCode   = tokenManager.diagnose( refreshed.accessToken, "access" ).code;
			refreshOk     = ( refreshCode == "VALID" );
		} catch ( any e ) {
			refreshCode = e.type;
		}
		rows.append( row(
			"refresh()", "Valid refresh token -> new access token",
			"valid refresh token",
			"new access token diagnoses VALID",
			refreshCode,
			refreshOk
		) );
		var refreshRejected = false;
		var refreshRejCode  = "";
		try {
			tokenManager.refresh( validAccess ); // access token is wrong type for refresh
			refreshRejCode = "(no error)";
		} catch ( any e ) {
			refreshRejected = true;
			refreshRejCode  = e.type;
		}
		rows.append( row(
			"refresh()", "Reject an access token used as a refresh token",
			"access token",
			"throws InvalidTokenType",
			refreshRejCode,
			refreshRejected
		) );

		// ---- RBAC ----
		var rbacPair = tokenManager.issue({
			id    : "rbac-user",
			roles : [ "admin", "finance" ]
		});
		var rbacDenied = tokenManager.diagnoseAuthorization( rbacPair.accessToken, "manager" );
		rows.append( row(
			"hasRole()", "Matching role is accepted",
			"roles = [admin, finance], required = admin",
			"true",
			tokenManager.hasRole( rbacPair.accessToken, "admin" ) ? "true" : "false",
			tokenManager.hasRole( rbacPair.accessToken, "admin" )
		) );
		rows.append( row(
			"hasAnyRole()", "At least one matching role is accepted",
			"roles = [admin, finance], required = [manager, finance]",
			"true",
			tokenManager.hasAnyRole( rbacPair.accessToken, [ "manager", "finance" ] ) ? "true" : "false",
			tokenManager.hasAnyRole( rbacPair.accessToken, [ "manager", "finance" ] )
		) );
		rows.append( row(
			"hasAllRoles()", "All required roles are present",
			"roles = [admin, finance], required = [admin, finance]",
			"true",
			tokenManager.hasAllRoles( rbacPair.accessToken, [ "admin", "finance" ] ) ? "true" : "false",
			tokenManager.hasAllRoles( rbacPair.accessToken, [ "admin", "finance" ] )
		) );
		rows.append( row(
			"diagnoseAuthorization()", "Valid token without required role",
			"roles = [admin, finance], required = manager",
			"INSUFFICIENT_ROLE",
			rbacDenied.code,
			rbacDenied.valid && !rbacDenied.authorized && rbacDenied.code == "INSUFFICIENT_ROLE"
		) );
		var authorizedClaims = {};
		var authorizeOk      = false;
		try {
			authorizedClaims = tokenManager.authorize( rbacPair.accessToken, "admin" );
			authorizeOk      = ( authorizedClaims.sub ?: "" ) == "rbac-user";
		} catch ( any e ) {
			authorizedClaims = { error : e.type };
		}
		rows.append( row(
			"authorize()", "Return trusted claims when the role is present",
			"roles = [admin, finance], required = admin",
			"trusted claims with sub = rbac-user",
			"sub = #( authorizedClaims.sub ?: authorizedClaims.error ?: "?" )#",
			authorizeOk
		) );

		return rows;
	}

	private struct function row( fn, scenario, input, expected, actual, pass ){
		return {
			"fn"       : arguments.fn,
			"scenario" : arguments.scenario,
			"input"    : arguments.input,
			"expected" : arguments.expected,
			"actual"   : arguments.actual,
			"pass"     : arguments.pass
		};
	}

	private struct function diagRow( fn, scenario, token, type, expectedCode ){
		var code = tokenManager.diagnose( arguments.token, arguments.type ).code;
		return row(
			arguments.fn,
			arguments.scenario,
			arguments.type & " check",
			arguments.expectedCode,
			code,
			code == arguments.expectedCode
		);
	}

	private string function flipLastChar( required string token ){
		var last = right( arguments.token, 1 );
		return left( arguments.token, len( arguments.token ) - 1 ) & ( last == "A" ? "B" : "A" );
	}

	private numeric function nowEpoch(){
		return int( createObject( "java", "java.lang.System" ).currentTimeMillis() / 1000 );
	}

}
