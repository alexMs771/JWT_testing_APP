<cfoutput>
<section class="page-heading">
	<div><p class="eyebrow">Performance</p><h1>Reports</h1><p>Understand collection performance, cash flow and customer exposure.</p></div>
	<div class="heading-actions"><span class="button button-secondary button-static"><i class="bi bi-calendar3"></i> Last 6 months</span><button class="button button-primary" type="button" data-export-table="##customer-exposure-table" data-export-file="duepilot-customer-exposure.csv"><i class="bi bi-download"></i> Export CSV</button></div>
</section>

<section class="metric-grid">
	<article class="metric-card success"><div class="metric-label"><span>Collection rate</span><span class="metric-icon"><i class="bi bi-graph-up-arrow"></i></span></div><h2>#prc.reports.collectionRate#%</h2><div class="metric-note"><strong>+4.6%</strong> versus prior period</div></article>
	<article class="metric-card"><div class="metric-label"><span>Average days to pay</span><span class="metric-icon"><i class="bi bi-stopwatch"></i></span></div><h2>#prc.reports.avgDaysToPay# days</h2><div class="metric-note">From invoice issue date</div></article>
	<article class="metric-card warning"><div class="metric-label"><span>Promises kept</span><span class="metric-icon"><i class="bi bi-calendar-check"></i></span></div><h2>#prc.reports.promiseKept#%</h2><div class="metric-note">Customer commitments honoured</div></article>
	<article class="metric-card danger"><div class="metric-label"><span>60+ day exposure</span><span class="metric-icon"><i class="bi bi-exclamation-triangle"></i></span></div><h2>#dpMoney( prc.reports.aging.overSixty )#</h2><div class="metric-note">Highest-risk receivables</div></article>
</section>

<div class="two-column">
	<article class="panel">
		<header class="panel-header"><div><h2>Billed vs collected</h2><p>Monthly cash conversion trend</p></div><div class="legend"><span><i></i> Collected</span><span><i></i> Billed</span></div></header>
		<div class="chart-wrap"><cfloop array="#prc.reports.monthly#" item="month"><div class="chart-group"><span class="chart-bar" style="height:#round( month.billed / 900000 * 100 )#%" title="Billed #dpMoney( month.billed )#"></span><span class="chart-bar collected" style="height:#round( month.collected / 900000 * 100 )#%" title="Collected #dpMoney( month.collected )#"></span></div></cfloop></div>
		<div class="chart-labels"><cfloop array="#prc.reports.monthly#" item="month"><span>#month.label#</span></cfloop></div>
	</article>
	<article class="panel">
		<header class="panel-header"><div><h2>Receivables aging</h2><p>Open amount by age bucket</p></div></header>
		<div class="panel-body">
			<cfset reportAgingTotal = max( 1, prc.reports.aging.total )>
			<div class="aging-row"><div class="aging-meta"><span>Current</span><strong>#dpMoney( prc.reports.aging.current )#</strong></div><div class="progress-track success"><span style="width:#round( prc.reports.aging.current / reportAgingTotal * 100 )#%"></span></div></div>
			<div class="aging-row"><div class="aging-meta"><span>1–30 days overdue</span><strong>#dpMoney( prc.reports.aging.oneToThirty )#</strong></div><div class="progress-track"><span style="width:#round( prc.reports.aging.oneToThirty / reportAgingTotal * 100 )#%"></span></div></div>
			<div class="aging-row"><div class="aging-meta"><span>31–60 days overdue</span><strong>#dpMoney( prc.reports.aging.thirtyOneToSixty )#</strong></div><div class="progress-track warning"><span style="width:#round( prc.reports.aging.thirtyOneToSixty / reportAgingTotal * 100 )#%"></span></div></div>
			<div class="aging-row"><div class="aging-meta"><span>More than 60 days</span><strong>#dpMoney( prc.reports.aging.overSixty )#</strong></div><div class="progress-track danger"><span style="width:#round( prc.reports.aging.overSixty / reportAgingTotal * 100 )#%"></span></div></div>
		</div>
	</article>
</div>

<article class="panel" style="margin-top:18px">
	<header class="panel-header"><div><h2>Largest customer exposure</h2><p>Accounts ranked by outstanding balance</p></div><a class="panel-link" href="#event.buildLink( 'customers' )#">All customers</a></header>
	<div class="table-scroll"><table class="data-table" id="customer-exposure-table"><thead><tr><th>Customer</th><th>Health</th><th>Invoices</th><th>Average delay</th><th class="text-right">Outstanding</th><th class="text-right">Overdue</th></tr></thead><tbody><cfloop array="#prc.reports.topCustomers#" item="customer"><tr><td><div class="customer-cell"><span class="customer-avatar">#customer.initials#</span><span><a class="table-link" href="#event.buildLink( 'customers/#customer.id#' )#">#encodeForHTML( customer.name )#</a><small>#encodeForHTML( customer.contact )#</small></span></div></td><td><span class="status-badge status-#customer.health == 'excellent' ? 'success' : ( customer.health == 'watch' ? 'warning' : 'danger' )#">#replace( customer.health, '_', ' ', 'all' )#</span></td><td>#customer.invoiceCount#</td><td>#customer.avgDaysLate# days</td><td class="text-right fw-semibold">#dpMoney( customer.outstanding )#</td><td class="text-right text-danger">#dpMoney( customer.overdue )#</td></tr></cfloop></tbody></table></div>
</article>
</cfoutput>
