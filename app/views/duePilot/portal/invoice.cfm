<cfoutput>
<section class="portal-grid">
	<article class="portal-card">
		<div class="portal-card-body">
			<div class="portal-company"><span class="portal-company-logo">#encodeForHTML( prc.organization.initials )#</span><span><strong>#encodeForHTML( prc.organization.name )#</strong><small>Invoice from your service partner</small></span></div>
			<div class="portal-invoice-heading">
				<div><span class="status-badge status-#dpStatusClass( prc.invoice.status )#">#dpStatusLabel( prc.invoice.status )#</span><h1>Invoice #prc.invoice.invoiceNumber#</h1></div>
				<div class="invoice-total"><small>Amount due</small><strong>#dpMoney( prc.invoice.outstanding )#</strong><span class="#prc.invoice.daysOverdue ? 'text-danger' : 'text-muted'#">#dpDueLabel( prc.invoice )#</span></div>
			</div>
			<div class="portal-details">
				<div class="portal-detail"><small>BILLED TO</small><strong>#encodeForHTML( prc.invoice.customerName )#</strong></div>
				<div class="portal-detail"><small>DESCRIPTION</small><strong>#encodeForHTML( prc.invoice.description )#</strong></div>
				<div class="portal-detail"><small>ISSUE DATE</small><strong>#dateFormat( parseDateTime( prc.invoice.issueDate ), 'dd mmm yyyy' )#</strong></div>
				<div class="portal-detail"><small>DUE DATE</small><strong>#dateFormat( parseDateTime( prc.invoice.dueDate ), 'dd mmm yyyy' )#</strong></div>
				<div class="portal-detail"><small>PURCHASE ORDER</small><strong>#len( prc.invoice.purchaseOrder ) ? encodeForHTML( prc.invoice.purchaseOrder ) : 'Not provided'#</strong></div>
				<div class="portal-detail"><small>INVOICE TOTAL</small><strong>#dpMoney( prc.invoice.amount )#</strong></div>
			</div>
		</div>
	</article>

	<aside class="portal-card payment-box">
		<cfif prc.invoice.status == 'paid'>
			<div class="pay-amount"><i class="bi bi-check-circle-fill text-success" style="font-size:28px"></i><small style="margin-top:8px">PAYMENT COMPLETE</small><strong>#dpMoney( prc.invoice.amount )#</strong></div>
			<h2>Thank you for your payment</h2><p>This invoice is settled. Reference: #encodeForHTML( prc.invoice.paymentRef )#</p>
		<cfelse>
			<h2>Pay this invoice</h2><p>Choose a payment method and complete the secure checkout.</p>
			<div class="pay-amount"><small>TOTAL TO PAY</small><strong>#dpMoney( prc.invoice.outstanding )#</strong></div>
			<div class="payment-methods" aria-label="Demo payment methods"><span class="payment-method active"><i class="bi bi-phone"></i> UPI</span><span class="payment-method is-disabled" aria-disabled="true" title="Bank transfer is not enabled in demo mode"><i class="bi bi-bank"></i> Bank</span><span class="payment-method is-disabled" aria-disabled="true" title="Card payment is not enabled in demo mode"><i class="bi bi-credit-card"></i> Card</span></div>
			<form method="post" action="#event.buildLink( 'pay/#prc.invoice.portalToken#/complete' )#" data-confirm="Complete this demonstration payment? No real money will move."><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><button class="button button-primary button-lg button-block" type="submit">Pay securely <i class="bi bi-lock"></i></button></form>
			<p class="text-muted" style="font-size:9px;text-align:center;margin:9px 0 0">Demo checkout · no real payment is processed</p>
			<div class="portal-help"><button type="button" data-dialog-open="portal-promise">Promise a date</button><button type="button" data-dialog-open="portal-dispute">Raise a query</button></div>
		</cfif>
	</aside>
</section>

<cfif prc.invoice.status != 'paid'>
<dialog id="portal-promise">
	<form method="post" action="#event.buildLink( 'pay/#prc.invoice.portalToken#/promise' )#" data-validated-form>
		<div class="dialog-header"><h3>Promise a payment date</h3><button class="icon-button" type="button" data-dialog-close aria-label="Close dialog"><i class="bi bi-x-lg" aria-hidden="true"></i></button></div>
		<div class="dialog-body"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><div class="form-group"><label>When do you expect to pay?</label><input class="form-control" name="promiseDate" type="date" min="#dateFormat( now(), 'yyyy-mm-dd' )#" required></div><div class="form-group"><label>Optional note</label><textarea class="form-control" name="note" maxlength="500" placeholder="Add any context for the finance team"></textarea></div></div>
		<div class="dialog-actions"><button class="button button-secondary" type="button" data-dialog-close>Cancel</button><button class="button button-primary" type="submit">Share payment date</button></div>
	</form>
</dialog>
<dialog id="portal-dispute">
	<form method="post" action="#event.buildLink( 'pay/#prc.invoice.portalToken#/dispute' )#" data-validated-form>
		<div class="dialog-header"><h3>Raise an invoice query</h3><button class="icon-button" type="button" data-dialog-close aria-label="Close dialog"><i class="bi bi-x-lg" aria-hidden="true"></i></button></div>
		<div class="dialog-body"><input type="hidden" name="csrfToken" value="#prc.csrfToken#"><div class="form-group"><label>What should the finance team review?</label><textarea class="form-control" name="reason" minlength="10" maxlength="1000" placeholder="For example: PO mismatch, incorrect amount or missing tax information" required></textarea></div></div>
		<div class="dialog-actions"><button class="button button-secondary" type="button" data-dialog-close>Cancel</button><button class="button button-primary" type="submit">Submit query</button></div>
	</form>
</dialog>
</cfif>
</cfoutput>
