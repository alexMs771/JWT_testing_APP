<cfoutput>
<cfset needsAction = prc.queue.filter( function( invoice ){ return invoice.status == 'disputed' || invoice.daysOverdue GTE 10; } )>
<cfset promises = prc.queue.filter( function( invoice ){ return len( invoice.promiseDate ) && invoice.status != 'disputed'; } )>
<cfset upcoming = prc.queue.filter( function( invoice ){ return invoice.daysOverdue LT 10 && !len( invoice.promiseDate ) && invoice.status != 'disputed'; } )>
<section class="page-heading">
	<div><p class="eyebrow">Action center</p><h1>Collections</h1><p>A focused queue for moving unpaid invoices toward resolution.</p></div>
	<div class="heading-actions"><a class="button button-secondary" href="#event.buildLink( 'invoices?status=overdue' )#"><i class="bi bi-funnel"></i> View overdue only</a></div>
</section>

<section class="kanban">
	<div class="kanban-column">
		<header class="kanban-heading"><strong><i class="bi bi-exclamation-circle text-danger"></i> Needs action</strong><span>#needsAction.len()#</span></header>
		<cfloop array="#needsAction#" item="invoice"><a class="queue-card" href="#event.buildLink( 'invoices/#invoice.id#' )#"><div class="queue-top"><span class="status-badge status-#dpStatusClass( invoice.status )#">#dpStatusLabel( invoice.status )#</span><i class="bi bi-arrow-up-right"></i></div><h3>#encodeForHTML( invoice.customerName )#</h3><p>#invoice.invoiceNumber# · #dpDueLabel( invoice )#</p><div class="queue-amount">#dpMoney( invoice.outstanding )#</div><div class="queue-footer"><span><i class="bi bi-send"></i> #invoice.reminderCount# reminders</span><span>Owner: Alex</span></div></a></cfloop>
	</div>
	<div class="kanban-column">
		<header class="kanban-heading"><strong><i class="bi bi-calendar-check text-success"></i> Promise to pay</strong><span>#promises.len()#</span></header>
		<cfloop array="#promises#" item="invoice"><a class="queue-card" href="#event.buildLink( 'invoices/#invoice.id#' )#"><div class="queue-top"><span class="status-badge status-success">Promised</span><i class="bi bi-arrow-up-right"></i></div><h3>#encodeForHTML( invoice.customerName )#</h3><p>#invoice.invoiceNumber# · expected #dateFormat( parseDateTime( invoice.promiseDate ), 'dd MMM' )#</p><div class="queue-amount">#dpMoney( invoice.outstanding )#</div><div class="queue-footer"><span><i class="bi bi-chat-left-text"></i> Promise captured</span><span>#dpDueLabel( invoice )#</span></div></a></cfloop>
		<cfif !promises.len()><div class="empty-state"><i class="bi bi-calendar2-check"></i><p>No active promises.</p></div></cfif>
	</div>
	<div class="kanban-column">
		<header class="kanban-heading"><strong><i class="bi bi-clock text-muted"></i> Upcoming follow-up</strong><span>#upcoming.len()#</span></header>
		<cfloop array="#upcoming#" item="invoice"><a class="queue-card" href="#event.buildLink( 'invoices/#invoice.id#' )#"><div class="queue-top"><span class="status-badge status-#dpStatusClass( invoice.status )#">#dpStatusLabel( invoice.status )#</span><i class="bi bi-arrow-up-right"></i></div><h3>#encodeForHTML( invoice.customerName )#</h3><p>#invoice.invoiceNumber# · #dpDueLabel( invoice )#</p><div class="queue-amount">#dpMoney( invoice.outstanding )#</div><div class="queue-footer"><span><i class="bi bi-envelope"></i> Email follow-up</span><span>#dateFormat( parseDateTime( invoice.dueDate ), 'dd MMM' )#</span></div></a></cfloop>
	</div>
</section>
</cfoutput>
