<cfoutput>
<cfset portalPath = event.buildLink( 'pay/#prc.invoice.portalToken#' )>
<section class="page-heading">
	<div><div class="breadcrumb"><a href="#event.buildLink( 'invoices' )#">Invoices</a><i class="bi bi-chevron-right"></i><span>#prc.invoice.invoiceNumber#</span></div><h1>Invoice details</h1><p>Manage payment progress and customer follow-up.</p></div>
	<div class="heading-actions"><button class="button button-secondary" type="button" data-copy="#encodeForHTMLAttribute( portalPath )#"><i class="bi bi-link-45deg"></i> Copy payment link</button><button class="button button-primary" type="button" data-dialog-open="reminder-dialog"><i class="bi bi-send"></i> Send reminder</button></div>
</section>

<div class="detail-grid">
	<div>
		<article class="panel">
			<div class="invoice-hero">
				<div class="invoice-identity"><span class="invoice-icon"><i class="bi bi-receipt"></i></span><div><span class="status-badge status-#dpStatusClass( prc.invoice.status )#">#dpStatusLabel( prc.invoice.status )#</span><h1>#prc.invoice.invoiceNumber#</h1><p>Issued to <a class="table-link" href="#event.buildLink( 'customers/#prc.invoice.customerId#' )#">#encodeForHTML( prc.invoice.customerName )#</a></p></div></div>
				<div class="invoice-total"><small>Amount outstanding</small><strong>#dpMoney( prc.invoice.outstanding )#</strong><span class="#prc.invoice.daysOverdue ? 'text-danger' : 'text-muted'#">#dpDueLabel( prc.invoice )#</span></div>
			</div>
			<div class="invoice-summary">
				<div class="summary-item"><small>Invoice total</small><strong>#dpMoney( prc.invoice.amount )#</strong></div>
				<div class="summary-item"><small>Amount paid</small><strong class="text-success">#dpMoney( prc.invoice.paidAmount )#</strong></div>
				<div class="summary-item"><small>Issue date</small><strong>#dateFormat( parseDateTime( prc.invoice.issueDate ), 'dd MMM yyyy' )#</strong></div>
				<div class="summary-item"><small>Due date</small><strong>#dateFormat( parseDateTime( prc.invoice.dueDate ), 'dd MMM yyyy' )#</strong></div>
			</div>
			<div class="description-box"><small class="text-muted">DESCRIPTION</small><p>#encodeForHTML( prc.invoice.description )#</p></div>
		</article>

		<article class="panel">
			<header class="panel-header"><div><h2>Payment timeline</h2><p>Customer follow-up and financial events</p></div></header>
			<div class="panel-body activity-list">
				<div class="activity-item"><span class="activity-icon"><i class="bi bi-file-earmark-plus"></i></span><span><strong>Invoice issued</strong><p>#encodeForHTML( prc.invoice.description )#</p></span><time>#dateFormat( parseDateTime( prc.invoice.issueDate ), 'dd MMM' )#</time></div>
				<cfif len( prc.invoice.lastContactAt )><div class="activity-item"><span class="activity-icon"><i class="bi bi-send"></i></span><span><strong>Customer contacted</strong><p>#prc.invoice.reminderCount# reminder#prc.invoice.reminderCount == 1 ? '' : 's'# sent</p></span><time>#encodeForHTML( prc.invoice.lastContactAt )#</time></div></cfif>
			<cfif len( prc.invoice.promiseDate )><div class="activity-item"><span class="activity-icon"><i class="bi bi-calendar-check"></i></span><span><strong>Payment promised</strong><p>#encodeForHTML( prc.invoice.promiseNote ?: 'Customer shared an expected payment date.' )#</p></span><time>#dateFormat( parseDateTime( prc.invoice.promiseDate ), 'dd MMM' )#</time></div></cfif>
				<cfif len( prc.invoice.disputeReason )><div class="activity-item"><span class="activity-icon"><i class="bi bi-flag"></i></span><span><strong>Dispute opened</strong><p>#encodeForHTML( prc.invoice.disputeReason )#</p></span><time>Open</time></div></cfif>
				<cfif prc.invoice.paidAmount GT 0><div class="activity-item"><span class="activity-icon"><i class="bi bi-check2"></i></span><span><strong>Payment received</strong><p>#dpMoney( prc.invoice.paidAmount )# · #encodeForHTML( prc.invoice.paymentRef )#</p></span><time>#len( prc.invoice.paidAt ) ? encodeForHTML( prc.invoice.paidAt ) : 'Recorded'#</time></div></cfif>
			</div>
		</article>
	</div>

	<aside>
		<article class="panel side-card">
			<h3>Next action</h3>
			<div class="action-stack">
				<cfif prc.invoice.status NEQ 'paid'><button class="button button-primary button-block" type="button" data-dialog-open="payment-dialog"><i class="bi bi-currency-rupee"></i> Record payment</button><button class="button button-secondary button-block" type="button" data-dialog-open="promise-dialog"><i class="bi bi-calendar-check"></i> Add payment promise</button><button class="button button-secondary button-block" type="button" data-dialog-open="dispute-dialog"><i class="bi bi-flag"></i> Open dispute</button><cfelse><div class="flash flash-success"><i class="bi bi-check-circle-fill"></i><span>This invoice is fully paid.</span></div></cfif>
			</div>
		</article>

		<article class="panel side-card">
			<h3>Invoice information</h3>
			<div class="mini-detail"><span>Customer</span><a class="table-link" href="#event.buildLink( 'customers/#prc.invoice.customerId#' )#">#encodeForHTML( prc.invoice.customerName )#</a></div>
			<div class="mini-detail"><span>Purchase order</span><strong>#len( prc.invoice.purchaseOrder ) ? encodeForHTML( prc.invoice.purchaseOrder ) : '—'#</strong></div>
			<div class="mini-detail"><span>Owner</span><strong>#encodeForHTML( prc.invoice.owner )#</strong></div>
			<div class="mini-detail"><span>Reminders sent</span><strong>#prc.invoice.reminderCount#</strong></div>
			<div class="portal-link"><i class="bi bi-link-45deg"></i><code>#encodeForHTML( portalPath )#</code><button class="icon-button" type="button" data-copy="#encodeForHTMLAttribute( portalPath )#" aria-label="Copy link"><i class="bi bi-copy"></i></button></div>
		</article>
	</aside>
</div>

<dialog id="payment-dialog">
	<form method="post" action="#event.buildLink( 'invoices/#prc.invoice.id#/payment' )#" data-validated-form>
		<div class="dialog-header"><h3>Record payment</h3><button class="icon-button" type="button" data-dialog-close aria-label="Close dialog"><i class="bi bi-x-lg" aria-hidden="true"></i></button></div>
		<div class="dialog-body"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><input type="hidden" name="invoiceId" value="#prc.invoice.id#"><div class="form-group"><label>Amount received</label><div class="input-prefix"><span>INR</span><input class="form-control" name="amount" type="number" min="1" max="#prc.invoice.outstanding#" step="0.01" inputmode="decimal" value="#prc.invoice.outstanding#" required></div></div><div class="form-group"><label>Payment reference</label><input class="form-control" name="reference" type="text" maxlength="100" placeholder="UTR, cheque or transfer reference"></div></div>
		<div class="dialog-actions"><button class="button button-secondary" type="button" data-dialog-close>Cancel</button><button class="button button-success" type="submit">Record payment</button></div>
	</form>
</dialog>

<dialog id="promise-dialog">
	<form method="post" action="#event.buildLink( 'invoices/#prc.invoice.id#/promise' )#" data-validated-form>
		<div class="dialog-header"><h3>Add payment promise</h3><button class="icon-button" type="button" data-dialog-close aria-label="Close dialog"><i class="bi bi-x-lg" aria-hidden="true"></i></button></div>
		<div class="dialog-body"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><input type="hidden" name="invoiceId" value="#prc.invoice.id#"><div class="form-group"><label>Expected payment date</label><input class="form-control" name="promiseDate" type="date" min="#dateFormat( now(), 'yyyy-MM-dd' )#" value="#dateFormat( dateAdd( 'd', 7, now() ), 'yyyy-MM-dd' )#" required></div><div class="form-group"><label>Conversation note</label><textarea class="form-control" name="note" maxlength="500" placeholder="What did the customer confirm?"></textarea></div></div>
		<div class="dialog-actions"><button class="button button-secondary" type="button" data-dialog-close>Cancel</button><button class="button button-primary" type="submit">Save promise</button></div>
	</form>
</dialog>

<dialog id="dispute-dialog">
	<form method="post" action="#event.buildLink( 'invoices/#prc.invoice.id#/dispute' )#" data-validated-form>
		<div class="dialog-header"><h3>Open a dispute</h3><button class="icon-button" type="button" data-dialog-close aria-label="Close dialog"><i class="bi bi-x-lg" aria-hidden="true"></i></button></div>
		<div class="dialog-body"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><input type="hidden" name="invoiceId" value="#prc.invoice.id#"><div class="form-group"><label>Dispute reason</label><textarea class="form-control" name="reason" minlength="10" maxlength="1000" placeholder="Describe what needs to be resolved" required></textarea></div></div>
		<div class="dialog-actions"><button class="button button-secondary" type="button" data-dialog-close>Cancel</button><button class="button button-primary" type="submit">Open dispute</button></div>
	</form>
</dialog>

<dialog id="reminder-dialog">
	<form method="post" action="#event.buildLink( 'invoices/#prc.invoice.id#/reminder' )#" data-validated-form>
		<div class="dialog-header"><h3>Send payment reminder</h3><button class="icon-button" type="button" data-dialog-close aria-label="Close dialog"><i class="bi bi-x-lg" aria-hidden="true"></i></button></div>
		<div class="dialog-body"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><input type="hidden" name="invoiceId" value="#prc.invoice.id#"><div class="form-group"><label>Delivery channel</label><select class="form-control" name="channel"><option value="email">Email</option><option value="whatsapp">WhatsApp</option><option value="sms">SMS</option></select><span class="form-hint">Version 1 records the reminder in the workflow. Provider delivery is the next integration step.</span></div></div>
		<div class="dialog-actions"><button class="button button-secondary" type="button" data-dialog-close>Cancel</button><button class="button button-primary" type="submit"><i class="bi bi-send"></i> Send reminder</button></div>
	</form>
</dialog>
</cfoutput>
