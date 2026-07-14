component extends="coldbox.system.EventHandler" {

	property name="tokenManager" inject="TokenManager@cf-token-manager";

	/**
	 * Default Action
	 */
	function index( event, rc, prc ){
		// Initial testing: mint a sample access + refresh token pair and dump it
		prc.tokens = tokenManager.issue( { id : 101, role : "admin" } );
		writeDump( var = prc.tokens, label = "cf-token-manager issue()" );
		abort;
	}

	/**
	 * Produce some restfulf data
	 */
	function data( event, rc, prc ){
		return [
			{ "id" : createUUID(), name : "Luis" },
			{ "id" : createUUID(), name : "JOe" },
			{ "id" : createUUID(), name : "Bob" },
			{ "id" : createUUID(), name : "Darth" }
		];
	}


	/**
	 * error
	 */
	function error( event, rc, prc ){
		event.settttView( "Main/error" );
	}


	/**
	 * Relocation example
	 */
	function doSomething( event, rc, prc ){
		relocate( "main.index" );
	}

	/************************************** IMPLICIT ACTIONS *********************************************/

	function onAppInit( event, rc, prc ){
	}

	function onRequestStart( event, rc, prc ){
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
		var exception = prc.keyExists( "exception" ) ? prc.exception : {};
		var message   = ( isStruct( exception ) && exception.keyExists( "message" ) ) ? exception.message : "Unknown error";
		var detail    = ( isStruct( exception ) && exception.keyExists( "detail" ) )  ? exception.detail  : "";

		// Print the full error to stdout so it is visible in the Render "Logs" tab.
		systemOutput( "=== UNHANDLED EXCEPTION ===", true );
		systemOutput( "message: " & message, true );
		systemOutput( "detail : " & detail, true );
		if ( isStruct( exception ) && exception.keyExists( "stacktrace" ) ) {
			systemOutput( exception.stacktrace, true );
		}

		// Return a real, visible response instead of a blank body.
		return event.renderData(
			type       = "HTML",
			statusCode = 500,
			data       = "<!doctype html><html><body style='font-family:system-ui;padding:2rem'>"
				& "<h2>Something went wrong</h2>"
				& "<p>" & encodeForHTML( message ) & "</p>"
				& "<pre style='white-space:pre-wrap;color:##555'>" & encodeForHTML( detail ) & "</pre>"
				& "</body></html>"
		);
	}

}
