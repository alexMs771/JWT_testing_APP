<cfoutput>
<section class="page-heading">
	<div><p class="eyebrow">Administration</p><h1>Settings</h1><p>Configure your organization, workflow and product environment.</p></div>
</section>

<nav class="settings-nav" aria-label="Settings sections"><a class="active" href="##workspace" aria-current="page">Workspace</a><span aria-disabled="true">Reminders <small>Coming soon</small></span><span aria-disabled="true">Team</span><span aria-disabled="true">Integrations</span><span aria-disabled="true">Billing</span></nav>

<div class="detail-grid">
	<section class="panel" id="workspace">
		<header class="panel-header"><div><h2>Workspace profile</h2><p>Information shown throughout the product and customer portal</p></div></header>
		<form class="panel-body" method="post" action="#event.buildLink( 'settings/update' )#" data-validated-form>
			<input type="hidden" name="csrfToken" value="#encodeForHTMLAttribute( prc.csrfToken )#">
			<div class="form-grid">
				<div class="form-group"><label for="organizationName">Organization name</label><input class="form-control" id="organizationName" name="organizationName" minlength="2" maxlength="100" value="#encodeForHTMLAttribute( prc.organization.name )#" required></div>
				<div class="form-group"><label for="currencyDisplay">Base currency</label><input type="hidden" name="currency" value="#encodeForHTMLAttribute( prc.organization.currency )#"><select class="form-control" id="currencyDisplay" disabled><option>#encodeForHTML( prc.organization.currency )# · Workspace currency</option></select><span class="form-hint">Locked after the first invoice to protect financial reporting.</span></div>
				<div class="form-group"><label for="financeEmail">Finance email</label><input class="form-control" id="financeEmail" name="financeEmail" type="email" maxlength="254" autocomplete="email" value="#encodeForHTMLAttribute( prc.organization.financeEmail )#" required></div>
				<div class="form-group"><label for="defaultTerms">Default payment terms</label><select class="form-control" id="defaultTerms" name="defaultTerms" required><cfloop array="#[ 15, 30, 45 ]#" item="term"><option value="#term#"#prc.organization.defaultTerms == term ? ' selected' : ''#>Net #term#</option></cfloop></select></div>
			</div>
			<div class="form-actions" style="margin:20px -18px -18px"><button class="button button-primary" type="submit"><i class="bi bi-check2"></i> Save workspace</button></div>
		</form>
	</section>
	<aside>
		<article class="panel side-card"><h3>Version 1 status</h3><div class="mini-detail"><span>Environment</span><span class="status-badge status-success">Demo ready</span></div><div class="mini-detail"><span>Persistence</span><strong>In-memory demo</strong></div><div class="mini-detail"><span>Authentication</span><strong>JWT session</strong></div><div class="mini-detail"><span>Database schema</span><strong>MySQL ready</strong></div><p class="text-muted" style="font-size:9px;margin:12px 0 0">The complete workflow runs without credentials. Connect MySQL before storing real customer data.</p></article>
		<article class="panel side-card"><h3>Developer tools</h3><div class="action-stack"><a class="button button-secondary button-block" href="#event.buildLink( 'demo' )#"><i class="bi bi-shield-lock"></i> Open JWT diagnostics</a><a class="button button-secondary button-block" href="#event.buildLink( 'healthcheck' )#"><i class="bi bi-heart-pulse"></i> Check service health</a><form method="post" action="#event.buildLink( 'settings/reset-demo' )#" data-confirm="Restore all demo invoices and activity to their original state?"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><button class="button button-danger button-block" type="submit"><i class="bi bi-arrow-counterclockwise"></i> Reset demo workspace</button></form></div></article>
	</aside>
</div>
</cfoutput>
