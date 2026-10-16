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

	function health( event, rc, prc ){
		return success( event, {
			service     : "duepilot-api",
			version     : "v1",
			status      : "healthy",
			persistence : getSystemSetting( "DATA_MODE", "demo" )
		} );
	}

	function login( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		param rc.email = "";
		param rc.password = "";
		var email = lCase( trim( toString( rc.email ) ) );
		var password = toString( rc.password );
		if ( !reFindNoCase( "^[^\s@]+@[^\s@]+\.[^\s@]+$", email ) ) {
			return failure( event, 400, "INVALID_LOGIN_REQUEST", "Enter a valid work email address." );
		}
		if ( len( password ) < 6 || len( password ) > 200 ) {
			return failure( event, 400, "INVALID_LOGIN_REQUEST", "Password must contain between 6 and 200 characters." );
		}

		var authentication = authService.authenticate( email, password );
		if ( !authentication.authenticated ) {
			return failure( event, 401, "INVALID_CREDENTIALS", "That email or password is not correct." );
		}

		var account = authentication.user;
		startSession( account );

		return success( event, {
			user      : account,
			workspace : duePilotService.getOrganization(),
			csrfToken : session.csrfToken
		} );
	}

	function register( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		param rc.workspaceName = "";
		param rc.organizationType = "business";
		param rc.name = "";
		param rc.email = "";
		param rc.password = "";
		try {
			var registration = authService.register(
				workspaceName   = rc.workspaceName,
				organizationType = rc.organizationType,
				name            = rc.name,
				email           = rc.email,
				password        = rc.password
			);
			startSession( registration.user );
			return success( event, {
				user      : registration.user,
				workspace : duePilotService.getOrganization(),
				csrfToken : session.csrfToken
			}, {}, 201 );
		} catch ( any error ) {
			return failure( event, 422, "REGISTRATION_VALIDATION_FAILED", error.message );
		}
	}

	function me( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		return success( event, {
			user      : duplicate( session.user ),
			workspace : duePilotService.getOrganization(),
			csrfToken : session.csrfToken ?: ""
		} );
	}

	function logout( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		lock scope="session" type="exclusive" timeout="5" {
			authService.logLogout( session.user.id, session.user.email );
			structDelete( session, "user" );
			structDelete( session, "tokens" );
			structDelete( session, "csrfToken" );
		}
		return success( event, { signedOut : true } );
	}

	function profile( event, rc, prc ){
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		var method = uCase( cgi.request_method ?: "GET" );
		if ( method == "GET" ) return success( event, authService.getProfile( session.user.id ) );
		if ( method != "POST" ) return failure( event, 405, "METHOD_NOT_ALLOWED", "This endpoint supports GET and POST." );
		if ( !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.name = "";
		try {
			var profile = authService.updateProfile( session.user.id, rc.name );
			session.user.name = profile.name;
			session.user.initials = profile.initials;
			return success( event, profile );
		} catch ( any error ) { return failure( event, 422, "PROFILE_VALIDATION_FAILED", error.message ); }
	}

	function saveProfilePhoto( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) || !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.contentType = ""; param rc.imageBase64 = "";
		try { return success( event, authService.saveProfilePhoto( session.user.id, rc.contentType, rc.imageBase64 ) ); } catch ( any error ) { return failure( event, 422, "PROFILE_PHOTO_INVALID", error.message ); }
	}

	function removeProfilePhoto( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) || !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		return success( event, authService.removeProfilePhoto( session.user.id ) );
	}

	function deleteWorkspace( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) || !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.confirmation = "";
		try { authService.deleteOwnWorkspace( session.user, rc.confirmation ); lock scope="session" type="exclusive" timeout="5" { structClear( session ); } return success( event, { deleted : true } ); } catch ( any error ) { return failure( event, 422, "WORKSPACE_DELETE_FAILED", error.message ); }
	}

	function adminOverview( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) || !requirePlatformAdmin( event ) ) return request.duePilotApiResponse;
		return success( event, authService.getAdminOverview() );
	}

	function adminDeleteWorkspace( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) || !requirePlatformAdmin( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		try { authService.adminDeleteWorkspace( rc.workspaceId ?: "", session.user.id ); return success( event, { deleted : true } ); } catch ( any error ) { return failure( event, 422, "ADMIN_WORKSPACE_DELETE_FAILED", error.message ); }
	}

	function dashboard( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		return success( event, duePilotService.getDashboard() );
	}

	function invoices( event, rc, prc ){
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		var method = uCase( cgi.request_method ?: "GET" );
		if ( method == "POST" ) {
			if ( !requireCsrf( event ) ) return request.duePilotApiResponse;
			param rc.customerId = "";
			param rc.amount = 0;
			param rc.issueDate = "";
			param rc.dueDate = "";
			param rc.purchaseOrder = "";
			param rc.description = "";
			try {
				var created = duePilotService.createInvoice(
					customerId    = rc.customerId,
					amount        = val( rc.amount ),
					issueDate     = rc.issueDate,
					dueDate       = rc.dueDate,
					purchaseOrder = rc.purchaseOrder,
					description   = rc.description
				);
				return success( event, created, {}, 201 );
			} catch ( any error ) {
				return failure( event, 422, "INVOICE_VALIDATION_FAILED", error.message );
			}
		}
		if ( method != "GET" ) {
			event.setHTTPHeader( name = "Allow", value = "GET, POST" );
			return failure( event, 405, "METHOD_NOT_ALLOWED", "This endpoint supports GET and POST." );
		}
		param rc.status = "all";
		param rc.search = "";
		return success( event, duePilotService.listInvoices( rc.status, rc.search ), {
			filters : { status : rc.status, search : rc.search }
		} );
	}

	function recordPayment( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.amount = 0;
		param rc.reference = "";
		try {
			return success( event, duePilotService.recordPayment( rc.invoiceId ?: "", val( rc.amount ), rc.reference ) );
		} catch ( any error ) {
			return failure( event, 422, "PAYMENT_VALIDATION_FAILED", error.message );
		}
	}

	function savePromise( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.promiseDate = "";
		param rc.note = "";
		try {
			return success( event, duePilotService.savePromise( rc.invoiceId ?: "", rc.promiseDate, rc.note ) );
		} catch ( any error ) {
			return failure( event, 422, "PROMISE_VALIDATION_FAILED", error.message );
		}
	}

	function openDispute( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.reason = "";
		try {
			return success( event, duePilotService.openDispute( rc.invoiceId ?: "", rc.reason ) );
		} catch ( any error ) {
			return failure( event, 422, "DISPUTE_VALIDATION_FAILED", error.message );
		}
	}

	function sendReminder( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.channel = "email";
		try {
			return success( event, duePilotService.sendReminder( rc.invoiceId ?: "", rc.channel ) );
		} catch ( any error ) {
			return failure( event, 422, "REMINDER_VALIDATION_FAILED", error.message );
		}
	}

	function invoice( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		try {
			return success( event, duePilotService.getInvoice( rc.invoiceId ?: "" ) );
		} catch ( any error ) {
			return failure( event, 404, "INVOICE_NOT_FOUND", error.message );
		}
	}

	function customers( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		param rc.search = "";
		return success( event, duePilotService.listCustomers( rc.search ), {
			filters : { search : rc.search }
		} );
	}

	function reports( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		return success( event, duePilotService.getReports() );
	}

	function settings( event, rc, prc ){
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		var method = uCase( cgi.request_method ?: "GET" );
		if ( method == "GET" ) return success( event, duePilotService.getOrganization() );
		if ( method != "POST" ) {
			event.setHTTPHeader( name = "Allow", value = "GET, POST" );
			return failure( event, 405, "METHOD_NOT_ALLOWED", "This endpoint supports GET and POST." );
		}
		if ( !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.name = "";
		param rc.currency = "INR";
		param rc.financeEmail = "";
		param rc.defaultTerms = 30;
		try {
			return success( event, duePilotService.updateOrganization(
				name         = rc.name,
				currency     = rc.currency,
				financeEmail = rc.financeEmail,
				defaultTerms = val( rc.defaultTerms )
			) );
		} catch ( any error ) {
			return failure( event, 422, "WORKSPACE_VALIDATION_FAILED", error.message );
		}
	}

	function assistantStatus( event, rc, prc ){
		if ( !requireMethod( event, "GET" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) ) return request.duePilotApiResponse;
		return success( event, duePilotAiService.getStatus() );
	}

	function assistantChat( event, rc, prc ){
		if ( !requireMethod( event, "POST" ) ) return request.duePilotApiResponse;
		if ( !requireAuthentication( event ) || !requireCsrf( event ) ) return request.duePilotApiResponse;
		param rc.message = "";
		if ( !isSimpleValue( rc.message ) || !len( trim( rc.message ) ) || len( trim( rc.message ) ) > 2000 ) {
			return failure( event, 422, "AI_MESSAGE_INVALID", "Enter a plain-text question between 1 and 2,000 characters." );
		}
		if ( !consumeAssistantRateLimit() ) {
			return failure( event, 429, "AI_RATE_LIMITED", "You have reached the assistant limit. Wait a minute and try again." );
		}
		try {
			var result = duePilotAiService.chat(
				message     = rc.message,
				history     = isArray( rc.history ?: [] ) ? rc.history : [],
				pageContext = isStruct( rc.context ?: {} ) ? rc.context : {}
			);
			structDelete( result, "ok" );
			return success( event, result );
		} catch ( any error ) {
			return failure( event, 503, "AI_UNAVAILABLE", error.message );
		}
	}

	private boolean function requireAuthentication( required any event ){
		if ( structKeyExists( session, "user" ) && isStruct( session.user ) && structKeyExists( session, "tokens" ) ) {
			return true;
		}
		failure( arguments.event, 401, "AUTHENTICATION_REQUIRED", "Sign in to continue." );
		return false;
	}

	private boolean function requirePlatformAdmin( required any event ){
		if ( !requireAuthentication( arguments.event ) ) return false;
		if ( !structKeyExists( session.user, "isPlatformAdmin" ) || !session.user.isPlatformAdmin ) {
			failure( arguments.event, 403, "ADMIN_ACCESS_REQUIRED", "This action requires platform administrator access." );
			return false;
		}
		return true;
	}

	private void function startSession( required struct account ){
		lock scope="session" type="exclusive" timeout="5" {
			session.user = arguments.account;
			session.tokens = tokenManager.issue( {
				id    : arguments.account.id,
				role  : arguments.account.role,
				email : arguments.account.email
			} );
			session.csrfToken = hash( createUUID() & getTickCount(), "SHA-256" );
		}
	}

	private boolean function consumeAssistantRateLimit(){
		var allowed = true;
		var lockKey = "duepilot-api-ai-rate-" & hash( session.csrfToken );
		lock name=lockKey type="exclusive" timeout="3" {
			if ( !structKeyExists( session, "aiApiRateLimit" ) || dateDiff( "s", session.aiApiRateLimit.startedAt, now() ) >= 60 ) {
				session.aiApiRateLimit = { startedAt : now(), count : 0 };
			}
			if ( session.aiApiRateLimit.count >= 10 ) {
				allowed = false;
			} else {
				session.aiApiRateLimit.count++;
			}
		}
		return allowed;
	}

	private boolean function requireCsrf( required any event ){
		var providedToken = cgi.http_x_csrf_token ?: "";
		if (
			structKeyExists( session, "csrfToken" )
			&& len( providedToken )
			&& providedToken == session.csrfToken
		) {
			return true;
		}
		failure( arguments.event, 403, "CSRF_VALIDATION_FAILED", "Your request expired. Refresh the page and try again." );
		return false;
	}

	private boolean function requireMethod( required any event, required string method ){
		if ( compareNoCase( cgi.request_method ?: "GET", arguments.method ) == 0 ) {
			return true;
		}
		arguments.event.setHTTPHeader( name = "Allow", value = arguments.method );
		failure( arguments.event, 405, "METHOD_NOT_ALLOWED", "This endpoint requires #arguments.method#." );
		return false;
	}

	private any function success( required any event, required any data, struct meta = {}, numeric statusCode = 200 ){
		var responseMeta = duplicate( arguments.meta );
		responseMeta.apiVersion = "v1";
		responseMeta.requestId = createUUID();
		responseMeta.timestamp = dateTimeFormat( dateConvert( "local2utc", now() ), "yyyy-mm-dd'T'HH:nn:ss'Z'" );
		arguments.event.setHTTPHeader( statusCode = arguments.statusCode );
		arguments.event.setHTTPHeader( name = "Content-Type", value = "application/json; charset=utf-8" );
		var responseBody = jsonSerialize(
			toApiCase( {
				"ok"   : true,
				"data" : arguments.data,
				"meta" : responseMeta
			} )
		);
		request.duePilotApiResponse = responseBody;
		return responseBody;
	}

	private any function failure(
		required any event,
		required numeric statusCode,
		required string code,
		required string message,
		array details = []
	){
		arguments.event.setHTTPHeader( statusCode = arguments.statusCode );
		arguments.event.setHTTPHeader( name = "Content-Type", value = "application/json; charset=utf-8" );
		var responseBody = jsonSerialize(
			toApiCase( {
				"ok"    : false,
				"error" : {
					"code"    : arguments.code,
					"message" : arguments.message,
					"details" : arguments.details
				},
				"meta" : { "apiVersion" : "v1", "requestId" : createUUID() }
			} )
		);
		request.duePilotApiResponse = responseBody;
		return responseBody;
	}

	/**
	 * CFML-compatible structs are case-insensitive and therefore store unquoted
	 * keys in uppercase. Rebuild API values as case-sensitive structs using the
	 * public contract vocabulary before JSON serialization.
	 */
	private any function toApiCase( required any value ){
		if ( isArray( arguments.value ) ) {
			return arguments.value.map( function( item ){ return toApiCase( item ); } );
		}
		if ( !isStruct( arguments.value ) ) {
			return arguments.value;
		}

		var canonicalNames = listToArray(
			"ok,data,meta,error,code,message,details,apiVersion,requestId,timestamp," &
			"service,version,status,persistence,signedOut,user,workspace,workspaceId,csrfToken," &
			"id,name,email,role,initials,isPlatformAdmin,plan,currency,financeEmail,defaultTerms," &
			"organization,outstanding,overdueAmount,overdueCount,dueSoonAmount," &
			"disputedAmount,collectedAmount,collectionRate,customerCount," &
			"priorityInvoices,recentActivity,aging,forecast,current,oneToThirty," &
			"thirtyOneToSixty,overSixty,total,label,amount,confidence,kind,title," &
			"detail,at,invoiceId,invoiceNumber,customerId,customerName,paidAmount," &
			"issueDate,dueDate,description,purchaseOrder,owner,promiseDate," &
			"promiseNote,statusOverride,disputeReason,reminderCount,lastContactAt," &
			"paidAt,paymentRef,portalToken,daysUntilDue,daysOverdue,paymentPercent," &
			"contact,phone,color,avgDaysLate,invoiceCount,overdue,paid,health," &
			"topCustomers,avgDaysToPay,promiseKept,monthly,billed,collected,filters,search," &
			"enabled,configured,keyCount,provider,model,mode,answer,evidence,nextActions,source," &
			"financeEmail,defaultTerms,photoUrl,createdAt,lastLogin,deleted,workspaceCount,userCount,loginsToday,invoiceCount,workspaces,loginEvents,slug,memberCount,usage30d,outcome"
		);
		var keyMap = structNew( "casesensitive" );
		for ( var canonicalName in canonicalNames ) {
			keyMap[ uCase( toString( canonicalName ) ) ] = toString( canonicalName );
		}

		// A Java map keeps String keys intact across the ColdBox/BoxLang JSON
		// boundary. Dynamic writes to a case-sensitive BoxLang struct currently
		// expose internal Key objects through ColdBox's marshaller.
		var output = createObject( "java", "java.util.LinkedHashMap" ).init();
		for ( var sourceKey in arguments.value ) {
			var sourceKeyName = toString( sourceKey );
			var upperKey = uCase( sourceKeyName );
			var targetKey = toString( structKeyExists( keyMap, upperKey ) ? keyMap[ upperKey ] : lCase( sourceKeyName ) );
			output.put( targetKey, toApiCase( arguments.value[ sourceKey ] ) );
		}
		return output;
	}

}
