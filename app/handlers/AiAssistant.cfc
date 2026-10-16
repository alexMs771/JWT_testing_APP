/**
 * Authenticated JSON endpoints for the DuePilot assistant.
 */
component extends="coldbox.system.EventHandler" {

	property name="duePilotAiService" inject="DuePilotAiService";

	function status( event, rc, prc ){
		setPrivateResponseHeaders( event );
		if ( !isSignedIn() ) return jsonError( event, 401, "Please sign in to use DuePilot AI." );
		return event.renderData( type = "json", data = { ok : true, assistant : duePilotAiService.getStatus() } );
	}

	function chat( event, rc, prc ){
		setPrivateResponseHeaders( event );
		if ( !isSignedIn() ) return jsonError( event, 401, "Please sign in to use DuePilot AI." );
		if ( compareNoCase( cgi.request_method ?: "GET", "POST" ) != 0 ) {
			return jsonError( event, 405, "This endpoint only accepts POST requests." );
		}
		if ( !findNoCase( "application/json", cgi.content_type ?: "" ) ) {
			return jsonError( event, 415, "Send the assistant request as application/json." );
		}

		param rc.csrfToken = "";
		if ( !structKeyExists( session, "csrfToken" ) || !len( rc.csrfToken ) || rc.csrfToken != session.csrfToken ) {
			return jsonError( event, 403, "Your session expired. Refresh the page and try again." );
		}

		param rc.message = "";
		if ( !isSimpleValue( rc.message ) ) {
			return jsonError( event, 400, "The message must be plain text." );
		}
		if ( !len( trim( rc.message ) ) || len( trim( rc.message ) ) > 2000 ) {
			return jsonError( event, 400, len( trim( rc.message ) ) ? "Please keep your question under 2,000 characters." : "Please enter a question." );
		}
		if ( !consumeRateLimit() ) {
			return jsonError( event, 429, "You have reached the assistant limit. Please wait a minute and try again." );
		}
		var history     = isArray( rc.history ?: [] ) ? rc.history : [];
		var pageContext = isStruct( rc.context ?: {} ) ? rc.context : {};

		try {
			return event.renderData(
				type = "json",
				data = duePilotAiService.chat(
					message     = rc.message,
					history     = history,
					pageContext = pageContext
				)
			);
		} catch ( "DuePilot.AI.EmptyMessage" error ) {
			return jsonError( event, 400, error.message );
		} catch ( "DuePilot.AI.MessageTooLong" error ) {
			return jsonError( event, 400, error.message );
		} catch ( "DuePilot.AI.Disabled" error ) {
			return jsonError( event, 503, error.message );
		} catch ( any error ) {
			return jsonError( event, 503, "DuePilot AI is temporarily unavailable. Please try again." );
		}
	}

	private boolean function consumeRateLimit(){
		var allowed = true;
		var lockKey = "duepilot-ai-rate-" & hash( session.csrfToken );
		lock name=lockKey type="exclusive" timeout="3" {
			if ( !structKeyExists( session, "aiRateLimit" ) || dateDiff( "s", session.aiRateLimit.startedAt, now() ) >= 60 ) {
				session.aiRateLimit = { startedAt : now(), count : 0 };
			}
			if ( session.aiRateLimit.count >= 10 ) {
				allowed = false;
			} else {
				session.aiRateLimit.count++;
			}
		}
		return allowed;
	}

	private boolean function isSignedIn(){
		return structKeyExists( session, "user" ) && isStruct( session.user ) && structKeyExists( session, "tokens" );
	}

	private void function setPrivateResponseHeaders( required any event ){
		arguments.event.setHTTPHeader( name = "Cache-Control", value = "no-store, private" );
		arguments.event.setHTTPHeader( name = "Pragma", value = "no-cache" );
	}

	private any function jsonError( required any event, required numeric statusCode, required string message ){
		return arguments.event.renderData(
			type       = "json",
			statusCode = arguments.statusCode,
			data       = { ok : false, error : arguments.message }
		);
	}

}
