<cfoutput>
<section class="page-heading">
	<div><p class="eyebrow">Receivables</p><h1>Invoices</h1><p>Track every invoice from issue through payment.</p></div>
	<div class="heading-actions"><button class="button button-secondary" type="button" disabled title="CSV import is planned for the persistent-data release"><i class="bi bi-upload"></i> Import <small>soon</small></button><a class="button button-primary" href="#event.buildLink( 'invoices/new' )#"><i class="bi bi-plus-lg"></i> New invoice</a></div>
</section>

<section class="panel">
	<div class="toolbar">
		<form class="search-field" method="get" action="#event.buildLink( 'invoices' )#">
			<i class="bi bi-search"></i><input name="search" type="search" value="#encodeForHTMLAttribute( prc.search )#" placeholder="Search invoice or customer"><input type="hidden" name="status" value="#encodeForHTMLAttribute( prc.statusFilter )#">
		</form>
		<nav class="filter-tabs" aria-label="Invoice status">
			<cfloop array="#['all','open','due_soon','overdue','partial','disputed','paid']#" item="filter">
				<a class="#prc.statusFilter == filter ? 'active' : ''#" href="#event.buildLink( 'invoices' )#?status=#urlEncodedFormat( filter )#&search=#urlEncodedFormat( prc.search )#">#filter == 'all' ? 'All' : dpStatusLabel( filter )#</a>
			</cfloop>
		</nav>
	</div>
	<cfif prc.invoices.len()>
		<div class="table-scroll">
			<table class="data-table">
				<thead><tr><th>Invoice</th><th>Customer</th><th>Issued</th><th>Due</th><th>Status</th><th class="text-right">Amount</th><th class="text-right">Outstanding</th><th></th></tr></thead>
				<tbody>
				<cfloop array="#prc.invoices#" item="invoice">
					<tr>
						<td><a class="table-link" href="#event.buildLink( 'invoices/#invoice.id#' )#">#invoice.invoiceNumber#</a><br><small class="text-muted">#encodeForHTML( invoice.purchaseOrder )#</small></td>
						<td><div class="customer-cell"><span class="customer-avatar">#encodeForHTML( uCase( left( listFirst( invoice.customerName, ' ' ), 1 ) & left( listLast( invoice.customerName, ' ' ), 1 ) ) )#</span><span><a class="table-link" href="#event.buildLink( 'customers/#invoice.customerId#' )#">#encodeForHTML( invoice.customerName )#</a><small>Customer account</small></span></div></td>
						<td>#dateFormat( parseDateTime( invoice.issueDate ), 'dd mmm yyyy' )#</td>
						<td>#dateFormat( parseDateTime( invoice.dueDate ), 'dd mmm yyyy' )#<br><small class="#invoice.daysOverdue ? 'text-danger' : 'text-muted'#">#dpDueLabel( invoice )#</small></td>
						<td><span class="status-badge status-#dpStatusClass( invoice.status )#">#dpStatusLabel( invoice.status )#</span></td>
						<td class="text-right">#dpMoney( invoice.amount )#</td>
						<td class="text-right fw-semibold">#dpMoney( invoice.outstanding )#</td>
						<td class="text-right"><a class="icon-button" href="#event.buildLink( 'invoices/#invoice.id#' )#" aria-label="View invoice"><i class="bi bi-chevron-right"></i></a></td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		</div>
	<cfelse>
		<div class="empty-state"><i class="bi bi-receipt"></i><h3>No invoices found</h3><p>Try changing the search or status filter.</p></div>
	</cfif>
</section>
</cfoutput>
