component {

	function configure(){
		/**
		 * --------------------------------------------------------------------------
		 * App Routes
		 * --------------------------------------------------------------------------
		 * Here is where you can register the routes for your web application!
		 * Go get Funky!
		 */

		// A nice healthcheck route example
		route( "/healthcheck", function( event, rc, prc ){
			return "Ok!";
		} );

		// A nice RESTFul Route example
		route( "/api/echo", function( event, rc, prc ){
			return { "error" : false, "data" : "Welcome to my awesome API!" };
		} );

		// Authentication + live token lifecycle
		route( "/login", "security.login" );
		route( "/logout", "security.logout" );
		route( "/dashboard", "security.dashboard" );
		route( "/refresh", "security.refreshToken" );

		// cf-token-manager engineering demo console (all-dimensions self test)
		route( "/demo", "tokenDemo.index" );
		route( "/demo/issue", "tokenDemo.issue" );
		route( "/demo/refresh", "tokenDemo.refresh" );
		route( "/demo/inspect", "tokenDemo.inspect" );

		// @app_routes@

		// Conventions-Based Routing
		route( ":handler/:action?" ).end();
	}

}
