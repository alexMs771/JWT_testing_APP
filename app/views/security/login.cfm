<cfoutput>
<div class="auth-shell">
	<section class="auth-form-side">
		<a class="brand" href="#event.buildLink( 'login' )#" aria-label="DuePilot sign in"><img class="brand-logo brand-logo-auth" src="assets/brand/duepilot-logo.svg" alt="DuePilot"></a>

		<div class="auth-form-wrap">
			<p class="eyebrow">Welcome back</p>
			<h1>Sign in to your workspace</h1>
			<p class="auth-subtitle">Stay ahead of receivables and get paid on time.</p>

			<cfif structKeyExists( rc, "notice" ) AND len( rc.notice )>
				<div class="flash flash-success"><i class="bi bi-check-circle-fill"></i><span>#encodeForHTML( rc.notice )#</span></div>
			</cfif>
			<cfif structKeyExists( rc, "error" ) AND len( rc.error )>
				<div class="flash flash-error"><i class="bi bi-exclamation-circle-fill"></i><span>#encodeForHTML( rc.error )#</span></div>
			</cfif>

			<form class="auth-form" method="post" action="#event.buildLink( 'auth/login' )#" data-validated-form>
				<div class="form-group">
					<label for="username">Work email</label>
					<input class="form-control" id="username" name="username" type="text" autocomplete="username" maxlength="254" placeholder="you@company.com" value="alex@duepilot.app" required autofocus>
				</div>
				<div class="form-group">
					<label for="password">Password</label>
					<div class="password-wrap">
						<input class="form-control" id="password" name="password" type="password" autocomplete="current-password" maxlength="200" value="demo123" required>
						<button class="icon-button" type="button" data-toggle-password="password" aria-label="Show password"><i class="bi bi-eye"></i></button>
					</div>
				</div>
				<div class="auth-meta">
					<label class="checkbox-row"><input type="checkbox" checked> Keep me signed in</label>
					<a href="mailto:support@duepilot.app">Forgot password?</a>
				</div>
				<button class="button button-primary button-lg button-block" type="submit">Sign in <i class="bi bi-arrow-right"></i></button>
			</form>

			<div class="demo-credentials">
				<strong><i class="bi bi-stars"></i> Product demo access</strong>
				<div class="demo-line"><span>alex@duepilot.app / demo123</span><button class="link-button" type="button" data-demo-fill>Use demo</button></div>
			</div>
		</div>

		<p class="auth-footer">© #year( now() )# DuePilot · Receivables, under control.</p>
	</section>

	<section class="auth-visual" aria-hidden="true">
		<div class="visual-content">
			<div class="visual-copy">
				<span>Cash flow command center</span>
				<h2>Turn every unpaid invoice into a clear next action.</h2>
				<p>DuePilot brings invoices, customer conversations, payment promises and collection priorities into one calm workspace.</p>
			</div>
			<div class="visual-dashboard">
				<div class="visual-top"><div class="visual-dots"><i></i><i></i><i></i></div><div class="visual-pill"></div></div>
				<div class="visual-stats">
					<div class="visual-stat"><small>OUTSTANDING</small><strong>INR 9.18L</strong></div>
					<div class="visual-stat"><small>OVERDUE</small><strong>INR 6.66L</strong></div>
					<div class="visual-stat"><small>COLLECTED</small><strong>INR 3.54L</strong></div>
				</div>
				<div class="visual-chart"><span style="height:42%"></span><span style="height:58%"></span><span style="height:49%"></span><span style="height:72%"></span><span style="height:64%"></span><span style="height:88%"></span><span style="height:76%"></span><span style="height:94%"></span></div>
			</div>
		</div>
	</section>
</div>
</cfoutput>
