component extends="coldbox.system.EventHandler" {

	/**
	 * Public DuePilot product landing page.
	 */
	function index( event, rc, prc ){
		prc.pageTitle = "Get invoices paid without the chasing";
		event.setLayout( "Marketing" );
		event.setView( "main/index" );
	}

	/************************************** IMPLICIT ACTIONS *********************************************/

	function onAppInit( event, rc, prc ){
	}

	function onRequestStart( event, rc, prc ){
		event.setHTTPHeader( name = "Cache-Control", value = "no-store, private" );
		event.setHTTPHeader( name = "Pragma", value = "no-cache" );
		event.setHTTPHeader( name = "X-Content-Type-Options", value = "nosniff" );
		event.setHTTPHeader( name = "X-Frame-Options", value = "DENY" );
		event.setHTTPHeader( name = "Referrer-Policy", value = "strict-origin-when-cross-origin" );
		event.setHTTPHeader( name = "Permissions-Policy", value = "camera=(), microphone=(), geolocation=()" );
		event.setHTTPHeader( name = "Cross-Origin-Opener-Policy", value = "same-origin" );
		event.setHTTPHeader(
			name  = "Content-Security-Policy",
			value = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://cdn.jsdelivr.net; font-src 'self' https://fonts.gstatic.com https://cdn.jsdelivr.net data:; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
		);
		if ( compareNoCase( getSystemSetting( "ENVIRONMENT", "development" ), "production" ) == 0 ) {
			event.setHTTPHeader( name = "Strict-Transport-Security", value = "max-age=31536000; includeSubDomains" );
		}
	}

	function onRequestEnd( event, rc, prc ){
	}

	function onSessionStart( event, rc, prc ){
	}

	function onSessionEnd( event, rc, prc ){
		var sessionScope     = event.getValue( "sessionReference" );
		var applicationScope = event.getValue( "applicationReference" );
	}

	function onException( event, rc, prc ){
		// Grab the exception placed by ColdBox's exception handling (guard against
		// it being missing so the handler itself can never throw/loop).
		var exception = structKeyExists( prc, "exception" ) ? prc.exception : {};
		var message = isObject( exception )
			? exception.getMessage()
			: ( isStruct( exception ) && structKeyExists( exception, "message" ) ? exception.message : "Unknown error" );
		var detail = isObject( exception )
			? exception.getDetail()
			: ( isStruct( exception ) && structKeyExists( exception, "detail" ) ? exception.detail : "" );
		var stackTrace = isObject( exception )
			? exception.getStackTrace()
			: ( isStruct( exception ) && structKeyExists( exception, "stacktrace" ) ? exception.stacktrace : "" );

		// Print the full error to stdout so it is visible in the Render "Logs" tab.
		systemOutput( "=== UNHANDLED EXCEPTION ===", true );
		systemOutput( "message: " & message, true );
		systemOutput( "detail : " & detail, true );
		if ( len( toString( stackTrace ) ) ) systemOutput( toString( stackTrace ), true );

		var isProduction = compareNoCase( getSystemSetting( "ENVIRONMENT", "development" ), "production" ) == 0;
		var publicMessage = isProduction ? "The request could not be completed. Please try again." : message;
		var publicDetail  = isProduction ? "" : detail;

		// Return a useful development response without exposing internals in production.
		return event.renderData(
			type       = "HTML",
			statusCode = 500,
			data       = "<!doctype html><html><body style='font-family:system-ui;padding:2rem'>"
				& "<h2>Something went wrong</h2>"
				& "<p>" & encodeForHTML( publicMessage ) & "</p>"
				& ( len( publicDetail ) ? "<pre style='white-space:pre-wrap;color:##555'>" & encodeForHTML( publicDetail ) & "</pre>" : "" )
				& "</body></html>"
		);
	}

}
