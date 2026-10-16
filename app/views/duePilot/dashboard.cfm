<cfoutput>
<section class="page-heading">
	<div>
		<p class="eyebrow">#dateFormat( now(), "dddd, d mmmm" )#</p>
		<h1>Good morning, #encodeForHTML( listFirst( prc.user.name, " " ) )#</h1>
		<p>Here is what needs your attention across receivables today.</p>
	</div>
	<div class="heading-actions">
		<a class="button button-secondary" href="#event.buildLink( 'reports' )#"><i class="bi bi-download"></i> Export report</a>
		<a class="button button-primary" href="#event.buildLink( 'invoices/new' )#"><i class="bi bi-plus-lg"></i> Create invoice</a>
	</div>
</section>

<section class="metric-grid" aria-label="Receivables summary">
	<article class="metric-card">
		<div class="metric-label"><span>Total outstanding</span><span class="metric-icon"><i class="bi bi-wallet2"></i></span></div>
		<h2>#dpMoney( prc.dashboard.outstanding )#</h2>
		<div class="metric-note"><strong><i class="bi bi-arrow-up-right"></i> 8.2%</strong> from last month</div>
	</article>
	<article class="metric-card danger">
		<div class="metric-label"><span>Overdue</span><span class="metric-icon"><i class="bi bi-exclamation-circle"></i></span></div>
		<h2>#dpMoney( prc.dashboard.overdueAmount )#</h2>
		<div class="metric-note">Across #prc.dashboard.overdueCount# invoices</div>
	</article>
	<article class="metric-card warning">
		<div class="metric-label"><span>Due next 7 days</span><span class="metric-icon"><i class="bi bi-calendar3"></i></span></div>
		<h2>#dpMoney( prc.dashboard.dueSoonAmount )#</h2>
		<div class="metric-note">Schedule proactive reminders</div>
	</article>
	<article class="metric-card success">
		<div class="metric-label"><span>Collection rate</span><span class="metric-icon"><i class="bi bi-graph-up-arrow"></i></span></div>
		<h2>#prc.dashboard.collectionRate#%</h2>
		<div class="metric-note"><strong><i class="bi bi-arrow-up-right"></i> 4.6%</strong> from last month</div>
	</article>
</section>

<section class="dashboard-grid">
	<div>
		<article class="panel">
			<header class="panel-header">
				<div><h2>Priority collections</h2><p>Invoices ranked by payment risk and age</p></div>
				<a class="panel-link" href="#event.buildLink( 'collections' )#">Open collection queue <i class="bi bi-arrow-right"></i></a>
			</header>
			<div class="table-scroll">
				<table class="data-table">
					<thead><tr><th>Priority</th><th>Customer</th><th>Invoice</th><th>Due status</th><th class="text-right">Outstanding</th><th></th></tr></thead>
					<tbody>
					<cfloop array="#prc.dashboard.priorityInvoices#" item="invoice" index="rowIndex">
						<tr>
							<td><span class="priority #rowIndex LTE 2 ? 'priority-high' : ( rowIndex LTE 4 ? 'priority-medium' : 'priority-low' )#">#rowIndex#</span></td>
							<td><a class="table-link" href="#event.buildLink( 'customers/#invoice.customerId#' )#">#encodeForHTML( invoice.customerName )#</a></td>
							<td><a class="table-link" href="#event.buildLink( 'invoices/#invoice.id#' )#">#encodeForHTML( invoice.invoiceNumber )#</a></td>
							<td><span class="status-badge status-#dpStatusClass( invoice.status )#">#dpDueLabel( invoice )#</span></td>
							<td class="text-right fw-semibold">#dpMoney( invoice.outstanding )#</td>
							<td class="text-right"><a class="icon-button" href="#event.buildLink( 'invoices/#invoice.id#' )#" aria-label="Open invoice"><i class="bi bi-chevron-right"></i></a></td>
						</tr>
					</cfloop>
					</tbody>
				</table>
			</div>
		</article>

		<article class="panel">
			<header class="panel-header"><div><h2>Cash collection forecast</h2><p>Expected inflow based on due dates and promises</p></div><span class="status-badge status-success">Live forecast</span></header>
			<div class="panel-body">
				<cfloop array="#prc.dashboard.forecast#" item="forecast">
					<div class="aging-row">
						<div class="aging-meta"><span>#forecast.label# · #forecast.confidence#% confidence</span><strong>#dpMoney( forecast.amount )#</strong></div>
						<div class="progress-track"><span style="width:#forecast.confidence#%"></span></div>
					</div>
				</cfloop>
			</div>
		</article>
	</div>

	<div>
		<article class="panel">
			<header class="panel-header"><div><h2>Receivables aging</h2><p>#dpMoney( prc.dashboard.aging.total )# open</p></div><a class="panel-link" href="#event.buildLink( 'reports' )#">Details</a></header>
			<div class="panel-body">
				<cfset agingTotal = max( 1, prc.dashboard.aging.total )>
				<div class="aging-row"><div class="aging-meta"><span>Current</span><strong>#dpMoney( prc.dashboard.aging.current )#</strong></div><div class="progress-track success"><span style="width:#round( prc.dashboard.aging.current / agingTotal * 100 )#%"></span></div></div>
				<div class="aging-row"><div class="aging-meta"><span>1–30 days</span><strong>#dpMoney( prc.dashboard.aging.oneToThirty )#</strong></div><div class="progress-track"><span style="width:#round( prc.dashboard.aging.oneToThirty / agingTotal * 100 )#%"></span></div></div>
				<div class="aging-row"><div class="aging-meta"><span>31–60 days</span><strong>#dpMoney( prc.dashboard.aging.thirtyOneToSixty )#</strong></div><div class="progress-track warning"><span style="width:#round( prc.dashboard.aging.thirtyOneToSixty / agingTotal * 100 )#%"></span></div></div>
				<div class="aging-row"><div class="aging-meta"><span>60+ days</span><strong>#dpMoney( prc.dashboard.aging.overSixty )#</strong></div><div class="progress-track danger"><span style="width:#round( prc.dashboard.aging.overSixty / agingTotal * 100 )#%"></span></div></div>
			</div>
		</article>

		<article class="panel">
			<header class="panel-header"><div><h2>Recent activity</h2><p>Latest customer and team events</p></div></header>
			<div class="panel-body activity-list">
				<cfloop array="#prc.dashboard.recentActivity#" item="activity">
					<a class="activity-item" href="#len( activity.invoiceId ) ? event.buildLink( 'invoices/#activity.invoiceId#' ) : event.buildLink( 'dashboard' )#">
						<span class="activity-icon"><i class="bi bi-#activity.kind == 'payment' ? 'check2' : ( activity.kind == 'dispute' ? 'flag' : ( activity.kind == 'promise' ? 'calendar-check' : 'send' ) )#"></i></span>
						<span><strong>#encodeForHTML( activity.title )#</strong><p>#encodeForHTML( activity.detail )#</p></span>
						<time>#encodeForHTML( activity.at )#</time>
					</a>
				</cfloop>
			</div>
		</article>
	</div>
</section>
</cfoutput>
