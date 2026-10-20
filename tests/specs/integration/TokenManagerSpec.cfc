component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	function beforeAll(){
		super.beforeAll();
		variables.tokenManager = getWireBox().getInstance( "TokenManager@cf-token-manager" );
	}

	function run(){
		describe( "cf-token-manager RBAC", function(){
			it( "normalizes legacy role and roles array claims", function(){
				var pair = variables.tokenManager.issue({
					id    : "rbac-user",
					roles : [ "Admin", "finance", "admin" ]
				});
				var claims = variables.tokenManager.decode( pair.accessToken );

				expect( claims.role ).toBe( "admin" );
				expect( arrayLen( claims.roles ) ).toBe( 2 );
				expect( claims.roles[ 1 ] ).toBe( "admin" );
				expect( claims.roles[ 2 ] ).toBe( "finance" );
			} );

			it( "supports single-role and any/all role checks", function(){
				var pair = variables.tokenManager.issue({
					id    : "rbac-user",
					roles : [ "admin", "finance" ]
				});

				expect( variables.tokenManager.hasRole( pair.accessToken, "ADMIN" ) ).toBeTrue();
				expect( variables.tokenManager.hasAnyRole( pair.accessToken, [ "manager", "finance" ] ) ).toBeTrue();
				expect( variables.tokenManager.hasAllRoles( pair.accessToken, [ "admin", "finance" ] ) ).toBeTrue();
				expect( variables.tokenManager.hasAllRoles( pair.accessToken, [ "admin", "manager" ] ) ).toBeFalse();
			} );

			it( "returns trusted claims when authorize succeeds", function(){
				var pair = variables.tokenManager.issue({ id : "admin-user", role : "admin" });
				var claims = variables.tokenManager.authorize( pair.accessToken, "admin" );

				expect( claims.sub ).toBe( "admin-user" );
				expect( claims.type ).toBe( "access" );
			} );

			it( "distinguishes insufficient role from invalid authentication", function(){
				var pair = variables.tokenManager.issue({ id : "customer-user", role : "customer" });
				var denied = variables.tokenManager.diagnoseAuthorization( pair.accessToken, "admin" );
				var invalid = variables.tokenManager.diagnoseAuthorization( "not.a.token", "admin" );

				expect( denied.valid ).toBeTrue();
				expect( denied.authorized ).toBeFalse();
				expect( denied.code ).toBe( "INSUFFICIENT_ROLE" );
				expect( invalid.valid ).toBeFalse();
				expect( invalid.authorized ).toBeFalse();
				expect( invalid.code ).toBe( "INVALID_SIGNATURE" );
			} );

			it( "preserves roles when refreshing an access token", function(){
				var pair = variables.tokenManager.issue({
					id    : "refresh-user",
					roles : [ "admin", "finance" ]
				});
				var refreshed = variables.tokenManager.refresh( pair.refreshToken );

				expect( variables.tokenManager.hasAllRoles( refreshed.accessToken, [ "admin", "finance" ] ) ).toBeTrue();
				expect( variables.tokenManager.verify( refreshed.accessToken, "access" ) ).toBeTrue();
			} );

			it( "does not authorize a refresh token as an access token", function(){
				var pair = variables.tokenManager.issue({ id : "refresh-user", role : "admin" });
				var result = variables.tokenManager.diagnoseAuthorization( pair.refreshToken, "admin" );

				expect( result.valid ).toBeFalse();
				expect( result.authorized ).toBeFalse();
				expect( result.code ).toBe( "INVALID_TOKEN_TYPE" );
			} );
		} );
	}

}
