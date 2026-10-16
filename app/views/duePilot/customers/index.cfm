<cfoutput>
<section class="page-heading">
	<div><p class="eyebrow">Relationships</p><h1>Customers</h1><p>See payment behaviour, exposure and contact details in one place.</p></div>
	<div class="heading-actions"><button class="button button-secondary" type="button"><i class="bi bi-upload"></i> Import customers</button><button class="button button-primary" type="button"><i class="bi bi-plus-lg"></i> Add customer</button></div>
</section>

<section class="panel">
	<div class="toolbar">
		<form class="search-field" method="get" action="#event.buildLink( 'customers' )#"><i class="bi bi-search"></i><input name="search" type="search" value="#encodeForHTMLAttribute( prc.search )#" placeholder="Search company or email"></form>
		<span class="text-muted">#prc.customers.len()# customer#prc.customers.len() == 1 ? '' : 's'#</span>
	</div>
	<cfif prc.customers.len()>
		<div class="table-scroll">
			<table class="data-table">
				<thead><tr><th>Customer</th><th>Primary contact</th><th>Health</th><th>Invoices</th><th class="text-right">Outstanding</th><th class="text-right">Overdue</th><th></th></tr></thead>
				<tbody>
				<cfloop array="#prc.customers#" item="customer">
					<tr>
						<td><div class="customer-cell"><span class="customer-avatar">#encodeForHTML( customer.initials )#</span><span><a class="table-link" href="#event.buildLink( 'customers/#customer.id#' )#">#encodeForHTML( customer.name )#</a><small>#encodeForHTML( customer.email )#</small></span></div></td>
						<td>#encodeForHTML( customer.contact )#<br><small class="text-muted">#encodeForHTML( customer.phone )#</small></td>
						<td><span class="status-badge status-#customer.health == 'excellent' ? 'success' : ( customer.health == 'watch' ? 'warning' : 'danger' )#">#customer.health == 'excellent' ? 'Healthy' : ( customer.health == 'watch' ? 'Watch' : 'At risk' )#</span></td>
						<td>#customer.invoiceCount#</td>
						<td class="text-right fw-semibold">#dpMoney( customer.outstanding )#</td>
						<td class="text-right #customer.overdue ? 'text-danger fw-semibold' : 'text-muted'#">#dpMoney( customer.overdue )#</td>
						<td class="text-right"><a class="icon-button" href="#event.buildLink( 'customers/#customer.id#' )#" aria-label="View #encodeForHTMLAttribute( customer.name )#"><i class="bi bi-chevron-right" aria-hidden="true"></i></a></td>
					</tr>
				</cfloop>
				</tbody>
			</table>
		</div>
	<cfelse><div class="empty-state"><i class="bi bi-buildings"></i><h3>No customers found</h3><p>Try another company name or email.</p></div></cfif>
</section>
</cfoutput>
