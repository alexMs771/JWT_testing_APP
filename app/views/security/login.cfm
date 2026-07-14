<cfoutput>
<div class="row justify-content-center align-items-center" style="min-height: 100vh;">
	<div class="col-11 col-sm-8 col-md-5 col-lg-4">
		<div class="card shadow border-0">
			<div class="card-body p-4 p-md-5">

				<div class="text-center mb-4">
					<i class="bi bi-shield-lock text-primary" style="font-size: 3rem;"></i>
					<h3 class="mt-2 mb-0">Secure Portal</h3>
					<small class="text-muted">Sign in — a JWT access &amp; refresh token pair will be issued</small>
				</div>

				<cfif structKeyExists( rc, "error" ) AND len( rc.error )>
					<div class="alert alert-danger py-2 small">
						<i class="bi bi-exclamation-triangle"></i> #encodeForHTML( rc.error )#
					</div>
				</cfif>

				<form method="post" action="#event.buildLink( 'security.doLogin' )#">
					<div class="mb-3">
						<label class="form-label">Username</label>
						<div class="input-group">
							<span class="input-group-text"><i class="bi bi-person"></i></span>
							<input
								type="text"
								name="username"
								class="form-control"
								placeholder="Enter username"
								required
								autofocus
							/>
						</div>
					</div>

					<div class="mb-4">
						<label class="form-label">Password</label>
						<div class="input-group">
							<span class="input-group-text"><i class="bi bi-lock"></i></span>
							<input
								type="password"
								name="password"
								class="form-control"
								placeholder="Enter password"
								required
							/>
						</div>
					</div>

					<div class="d-grid">
						<button type="submit" class="btn btn-primary btn-lg">
							<i class="bi bi-box-arrow-in-right"></i> Login
						</button>
					</div>
				</form>

			</div>
		</div>
	</div>
</div>
</cfoutput>
