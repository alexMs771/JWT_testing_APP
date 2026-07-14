<cfscript>
	// ---- tiny view helpers -------------------------------------------------
	function fmtEpoch( required numeric e ){
		var localBase = dateConvert( "utc2Local", createDateTime( 1970, 1, 1, 0, 0, 0 ) );
		return dateTimeFormat( dateAdd( "s", arguments.e, localBase ), "yyyy-mm-dd HH:nn:ss" );
	}
	function ttlText( required numeric seconds ){
		var s = arguments.seconds;
		if ( s % 86400 == 0 ) return ( s / 86400 ) & " day" & ( s / 86400 == 1 ? "" : "s" );
		if ( s % 3600  == 0 ) return ( s / 3600  ) & " hour" & ( s / 3600 == 1 ? "" : "s" );
		if ( s % 60    == 0 ) return ( s / 60    ) & " min";
		return s & " sec";
	}
	function remainText( required numeric exp, required numeric nowE ){
		var left = arguments.exp - arguments.nowE;
		if ( left <= 0 ) return "EXPIRED";
		if ( left >= 86400 ) return int( left / 86400 ) & "d " & int( ( left % 86400 ) / 3600 ) & "h left";
		if ( left >= 3600 )  return int( left / 3600 ) & "h " & int( ( left % 3600 ) / 60 ) & "m left";
		if ( left >= 60 )    return int( left / 60 ) & "m " & ( left % 60 ) & "s left";
		return left & "s left";
	}
	function claimRow( required string name, required any value ){
		var isTime = listFindNoCase( "iat,exp", arguments.name );
		var display = isTime
			? fmtEpoch( arguments.value ) & ' <span class="text-muted">(' & arguments.value & ')</span>'
			: encodeForHTML( arguments.value );
		return '<tr><td class="text-muted" style="width:32%;">' & encodeForHTML( arguments.name ) & '</td><td class="font-monospace small">' & display & '</td></tr>';
	}
</cfscript>
<cfoutput>
<style>
	.tm-hero { background: linear-gradient( 135deg, ##0d1b3e 0%, ##17408b 55%, ##2d6cdf 100% ); color:##fff; border-radius:1rem; }
	.tm-code { font-family: ui-monospace, SFMono-Regular, Menlo, monospace; }
	.tm-token { word-break: break-all; font-family: ui-monospace, monospace; font-size:.78rem; }
	.tm-fn-badge { font-family: ui-monospace, monospace; }
	.tm-sticky-sum { position: sticky; top: 0; z-index: 5; }
</style>

<div class="py-4" style="max-width:1100px; margin:0 auto;">

	<!--- ===================== HERO ===================== --->
	<div class="tm-hero p-4 p-md-5 mb-4 shadow">
		<div class="d-flex flex-wrap justify-content-between align-items-center gap-3">
			<div>
				<div class="text-uppercase small fw-semibold opacity-75 mb-1">Ortus-style ColdBox Module &bull; Live Demo</div>
				<h1 class="fw-bold mb-2"><i class="bi bi-shield-lock"></i> cf-token-manager</h1>
				<p class="mb-0 opacity-75" style="max-width:640px;">
					A JWT token-lifecycle manager. This console exercises every public function
					&mdash; <span class="tm-code">issue()</span>, <span class="tm-code">decode()</span>,
					<span class="tm-code">verify()</span>, <span class="tm-code">refresh()</span> &mdash;
					plus the <span class="tm-code">validate()/diagnose()</span> diagnostics, across all success and failure dimensions.
				</p>
			</div>
			<div class="text-end">
				<div class="badge bg-light text-dark mb-1 d-block">alg: #encodeForHTML( prc.policy.algorithm )#</div>
				<div class="badge bg-light text-dark mb-1 d-block">issuer: #encodeForHTML( prc.policy.issuer )#</div>
				<div class="badge bg-light text-dark mb-1 d-block">access TTL: #ttlText( prc.policy.accessTokenExpiry )#</div>
				<div class="badge bg-light text-dark d-block">refresh TTL: #ttlText( prc.policy.refreshTokenExpiry )#</div>
			</div>
		</div>
	</div>

	<cfif len( prc.flashMsg )>
		<div class="alert alert-#( prc.flashType == 'danger' ? 'danger' : 'success' )# d-flex align-items-center">
			<i class="bi bi-#( prc.flashType == 'danger' ? 'exclamation-triangle' : 'check-circle' )# me-2"></i>
			<div class="small">#encodeForHTML( prc.flashMsg )#</div>
		</div>
	</cfif>

	<!--- ===================== SELF-TEST MATRIX ===================== --->
	<div class="card border-0 shadow-sm mb-4">
		<div class="card-header bg-white d-flex justify-content-between align-items-center py-3">
			<span class="fw-bold"><i class="bi bi-grid-3x3-gap text-primary"></i> Self-Test Matrix &mdash; all dimensions</span>
			<cfif prc.matrixPassed EQ prc.matrixTotal>
				<span class="badge bg-success fs-6"><i class="bi bi-check-circle"></i> #prc.matrixPassed# / #prc.matrixTotal# checks passed</span>
			<cfelse>
				<span class="badge bg-danger fs-6"><i class="bi bi-x-circle"></i> #prc.matrixPassed# / #prc.matrixTotal# passed</span>
			</cfif>
		</div>
		<div class="table-responsive">
			<table class="table table-sm table-hover align-middle mb-0">
				<thead class="table-light">
					<tr>
						<th style="width:12%;">Function</th>
						<th style="width:26%;">Scenario</th>
						<th style="width:18%;">Input</th>
						<th style="width:18%;">Expected</th>
						<th style="width:18%;">Actual</th>
						<th style="width:8%;" class="text-center">Result</th>
					</tr>
				</thead>
				<tbody>
					<cfloop array="#prc.matrix#" index="r">
						<tr>
							<td><span class="badge bg-primary-subtle text-primary-emphasis tm-fn-badge">#encodeForHTML( r.fn )#</span></td>
							<td class="small">#encodeForHTML( r.scenario )#</td>
							<td class="small text-muted tm-code">#encodeForHTML( r.input )#</td>
							<td class="small tm-code">#encodeForHTML( r.expected )#</td>
							<td class="small tm-code">#encodeForHTML( r.actual )#</td>
							<td class="text-center">
								<cfif r.pass>
									<span class="badge bg-success"><i class="bi bi-check-lg"></i> PASS</span>
								<cfelse>
									<span class="badge bg-danger"><i class="bi bi-x-lg"></i> FAIL</span>
								</cfif>
							</td>
						</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
		<div class="card-footer bg-white small text-muted">
			Runs live on every page load. Fixtures for the failure modes (expired, wrong-secret) are crafted with the low-level engine on purpose; everything else uses the public API exactly as a host app would.
		</div>
	</div>

	<div class="row g-4">

		<!--- ===================== issue() ===================== --->
		<div class="col-12 col-lg-6">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-header bg-white fw-bold"><span class="tm-code text-primary">issue()</span> &mdash; mint a token pair</div>
				<div class="card-body">
					<p class="small text-muted">Provide a subject; the module stamps <span class="tm-code">sub, type, iat, exp, iss</span> and signs both tokens.</p>
					<form method="post" action="#event.buildLink( 'tokenDemo.issue' )#" class="row g-2 mb-3">
						<div class="col-4">
							<label class="form-label small mb-0">id / sub</label>
							<input class="form-control form-control-sm" name="id" value="#encodeForHTMLAttribute( prc.accessClaims.sub ?: '' )#" placeholder="101">
						</div>
						<div class="col-4">
							<label class="form-label small mb-0">role</label>
							<input class="form-control form-control-sm" name="role" value="customer">
						</div>
						<div class="col-4">
							<label class="form-label small mb-0">email (optional)</label>
							<input class="form-control form-control-sm" name="email" placeholder="a@b.io">
						</div>
						<div class="col-12">
							<button class="btn btn-primary btn-sm w-100"><i class="bi bi-key"></i> issue()</button>
						</div>
					</form>

					<label class="form-label small text-muted mb-1">Access token</label>
					<div class="bg-light border rounded p-2 mb-1 tm-token">#encodeForHTML( prc.tokens.accessToken )#</div>
					<div class="d-flex justify-content-between small mb-3">
						<span>
							<cfif prc.accessDiag.valid><span class="badge bg-success">verify()=true</span>
							<cfelse><span class="badge bg-danger">verify()=false</span></cfif>
						</span>
						<span class="text-muted">expires #fmtEpoch( prc.accessClaims.exp )# &bull; <strong>#remainText( prc.accessClaims.exp, prc.nowEpoch )#</strong></span>
					</div>

					<label class="form-label small text-muted mb-1">Refresh token</label>
					<div class="bg-light border rounded p-2 mb-1 tm-token">#encodeForHTML( prc.tokens.refreshToken )#</div>
					<div class="d-flex justify-content-between small">
						<span>
							<cfif prc.refreshDiag.valid><span class="badge bg-success">verify()=true</span>
							<cfelse><span class="badge bg-danger">verify()=false</span></cfif>
						</span>
						<span class="text-muted">expires #fmtEpoch( prc.refreshClaims.exp )# &bull; <strong>#remainText( prc.refreshClaims.exp, prc.nowEpoch )#</strong></span>
					</div>
				</div>
			</div>
		</div>

		<!--- ===================== refresh() ===================== --->
		<div class="col-12 col-lg-6">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-header bg-white fw-bold"><span class="tm-code text-primary">refresh()</span> &mdash; renew the access token</div>
				<div class="card-body d-flex flex-column">
					<p class="small text-muted">Exchanges the current <em>refresh</em> token for a brand-new <em>access</em> token (same subject, fresh <span class="tm-code">iat/exp</span>). The refresh token itself is unchanged.</p>
					<ul class="small text-muted">
						<li>Rejects if the refresh token is expired or tampered.</li>
						<li>Rejects if an <em>access</em> token is passed instead (wrong type).</li>
					</ul>
					<form method="post" action="#event.buildLink( 'tokenDemo.refresh' )#" class="mt-auto">
						<button class="btn btn-outline-primary btn-sm w-100"><i class="bi bi-arrow-repeat"></i> refresh( refreshToken )</button>
					</form>
					<div class="small text-muted mt-2">
						Current access token expires <strong>#fmtEpoch( prc.accessClaims.exp )#</strong> (#remainText( prc.accessClaims.exp, prc.nowEpoch )#). Click refresh and watch it jump forward.
					</div>
				</div>
			</div>
		</div>

		<!--- ===================== decode() ===================== --->
		<div class="col-12 col-lg-6">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-header bg-white fw-bold"><span class="tm-code text-primary">decode()</span> &mdash; read claims (no verification)</div>
				<div class="card-body">
					<p class="small text-muted">Returns the claims struct without checking the signature. Use <span class="tm-code">verify()</span> first when you need to trust it.</p>
					<h6 class="small text-uppercase text-muted">Access claims</h6>
					<table class="table table-sm mb-3"><tbody>
						<cfloop collection="#prc.accessClaims#" item="claim">#claimRow( claim, prc.accessClaims[ claim ] )#</cfloop>
					</tbody></table>
					<h6 class="small text-uppercase text-muted">Refresh claims</h6>
					<table class="table table-sm mb-0"><tbody>
						<cfloop collection="#prc.refreshClaims#" item="claim">#claimRow( claim, prc.refreshClaims[ claim ] )#</cfloop>
					</tbody></table>
				</div>
			</div>
		</div>

		<!--- ===================== verify()/validate()/diagnose() ===================== --->
		<div class="col-12 col-lg-6">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-header bg-white fw-bold"><span class="tm-code text-primary">verify()</span> / <span class="tm-code text-primary">diagnose()</span> &mdash; inspect any token</div>
				<div class="card-body">
					<p class="small text-muted">Paste any token (try tampering a character, or paste an access token but choose "refresh") and see the exact verdict.</p>
					<form method="post" action="#event.buildLink( 'tokenDemo.inspect' )#">
						<textarea class="form-control form-control-sm tm-token mb-2" name="token" rows="4" placeholder="paste a JWT here...">#encodeForHTML( prc.inspect.token ?: prc.tokens.accessToken )#</textarea>
						<div class="input-group input-group-sm">
							<label class="input-group-text">expected type</label>
							<select class="form-select" name="expectedType">
								<option value="access"  <cfif ( prc.inspect.expectedType ?: '' ) EQ 'access'>selected</cfif>>access</option>
								<option value="refresh" <cfif ( prc.inspect.expectedType ?: '' ) EQ 'refresh'>selected</cfif>>refresh</option>
							</select>
							<button class="btn btn-primary"><i class="bi bi-search"></i> inspect</button>
						</div>
					</form>

					<cfif structCount( prc.inspect )>
						<hr>
						<div class="d-flex justify-content-between align-items-center mb-2">
							<span class="small fw-semibold">verify() &rarr;
								<cfif prc.inspect.verify><span class="badge bg-success">true</span>
								<cfelse><span class="badge bg-danger">false</span></cfif>
							</span>
							<span class="small">diagnose() &rarr;
								<span class="badge #( prc.inspect.diagnose.valid ? 'bg-success' : 'bg-danger' )# tm-code">#encodeForHTML( prc.inspect.diagnose.code )#</span>
							</span>
						</div>
						<p class="small text-muted mb-2">#encodeForHTML( prc.inspect.diagnose.message )#</p>
						<cfif len( prc.inspect.decodeError )>
							<div class="alert alert-warning py-1 small mb-0">decode() could not read this token: #encodeForHTML( prc.inspect.decodeError )#</div>
						<cfelse>
							<table class="table table-sm mb-0"><tbody>
								<cfloop collection="#prc.inspect.claims#" item="claim">#claimRow( claim, prc.inspect.claims[ claim ] )#</cfloop>
							</tbody></table>
						</cfif>
					</cfif>
				</div>
			</div>
		</div>

	</div>

	<p class="text-center text-muted small mt-4 mb-0">
		cf-token-manager v1.0.0 &bull; HMAC signing via the JVM (portable across Adobe CF, Lucee &amp; BoxLang)
	</p>
</div>
</cfoutput>
