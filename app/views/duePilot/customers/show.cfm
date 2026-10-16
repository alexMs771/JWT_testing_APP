<cfoutput>
<section class="page-heading">
	<div><div class="breadcrumb"><a href="#event.buildLink( 'customers' )#">Customers</a><i class="bi bi-chevron-right"></i><span>#encodeForHTML( prc.customer.name )#</span></div><h1>#encodeForHTML( prc.customer.name )#</h1><p>Payment history and open receivables for this account.</p></div>
	<div class="heading-actions"><a class="button button-secondary" href="mailto:#encodeForHTMLAttribute( prc.customer.email )#"><i class="bi bi-envelope"></i> Email contact</a><a class="button button-primary" href="#event.buildLink( 'invoices/new' )#"><i class="bi bi-plus-lg"></i> New invoice</a></div>
</section>

<section class="metric-grid">
	<article class="metric-card"><div class="metric-label"><span>Outstanding</span><span class="metric-icon"><i class="bi bi-wallet2"></i></span></div><h2>#dpMoney( prc.customer.outstanding )#</h2><div class="metric-note">Across #prc.customer.invoiceCount# invoices</div></article>
	<article class="metric-card danger"><div class="metric-label"><span>Overdue</span><span class="metric-icon"><i class="bi bi-exclamation-circle"></i></span></div><h2>#dpMoney( prc.customer.overdue )#</h2><div class="metric-note">Requires collection follow-up</div></article>
	<article class="metric-card success"><div class="metric-label"><span>Collected</span><span class="metric-icon"><i class="bi bi-check2-circle"></i></span></div><h2>#dpMoney( prc.customer.paid )#</h2><div class="metric-note">Recorded payments</div></article>
	<article class="metric-card warning"><div class="metric-label"><span>Average delay</span><span class="metric-icon"><i class="bi bi-clock-history"></i></span></div><h2>#prc.customer.avgDaysLate# days</h2><div class="metric-note">Past due-date behaviour</div></article>
</section>

<div class="detail-grid">
	<section class="panel">
		<header class="panel-header"><div><h2>Invoice history</h2><p>All receivables linked to this customer</p></div></header>
		<div class="table-scroll">
			<table class="data-table"><thead><tr><th>Invoice</th><th>Due date</th><th>Status</th><th class="text-right">Amount</th><th class="text-right">Outstanding</th><th></th></tr></thead><tbody>
			<cfloop array="#prc.invoices#" item="invoice"><tr><td><a class="table-link" href="#event.buildLink( 'invoices/#invoice.id#' )#">#invoice.invoiceNumber#</a></td><td>#dateFormat( parseDateTime( invoice.dueDate ), 'dd mmm yyyy' )#<br><small class="#invoice.daysOverdue ? 'text-danger' : 'text-muted'#">#dpDueLabel( invoice )#</small></td><td><span class="status-badge status-#dpStatusClass( invoice.status )#">#dpStatusLabel( invoice.status )#</span></td><td class="text-right">#dpMoney( invoice.amount )#</td><td class="text-right fw-semibold">#dpMoney( invoice.outstanding )#</td><td><a class="icon-button" href="#event.buildLink( 'invoices/#invoice.id#' )#" aria-label="View #encodeForHTMLAttribute( invoice.invoiceNumber )#"><i class="bi bi-chevron-right" aria-hidden="true"></i></a></td></tr></cfloop>
			</tbody></table>
		</div>
	</section>
	<aside>
		<article class="panel side-card"><h3>Primary contact</h3><div class="customer-cell"><span class="customer-avatar">#prc.customer.initials#</span><span><strong>#encodeForHTML( prc.customer.contact )#</strong><small>Accounts payable</small></span></div><div style="margin-top:16px"><div class="mini-detail"><span>Email</span><a class="table-link" href="mailto:#encodeForHTMLAttribute( prc.customer.email )#">#encodeForHTML( prc.customer.email )#</a></div><div class="mini-detail"><span>Phone</span><strong>#encodeForHTML( prc.customer.phone )#</strong></div></div></article>
		<article class="panel side-card"><h3>Payment profile</h3><div class="mini-detail"><span>Account health</span><span class="status-badge status-#prc.customer.health == 'excellent' ? 'success' : ( prc.customer.health == 'watch' ? 'warning' : 'danger' )#">#replace( prc.customer.health, '_', ' ', 'all' )#</span></div><div class="mini-detail"><span>Average days late</span><strong>#prc.customer.avgDaysLate# days</strong></div><div class="mini-detail"><span>Owner</span><strong>#encodeForHTML( prc.user.name )#</strong></div></article>
	</aside>
</div>
</cfoutput>
