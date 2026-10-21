<cfoutput>
<section class="page-heading">
	<div><div class="breadcrumb"><a href="#event.buildLink( 'invoices' )#">Invoices</a><i class="bi bi-chevron-right"></i><span>New invoice</span></div><h1>Create invoice</h1><p>Add an invoice to the collection workspace and generate its customer portal.</p></div>
</section>

<section class="panel form-card">
	<form method="post" action="#event.buildLink( 'invoices/create' )#" data-validated-form data-invoice-form>
		<input type="hidden" name="csrfToken" value="#encodeForHTMLAttribute( prc.csrfToken )#">
		<div class="form-section">
			<div class="form-section-heading"><h2>Customer and amount</h2><p>Choose who owes the payment and enter the invoice value.</p></div>
			<div class="form-grid">
				<div class="form-group full"><label for="customerId">Customer</label><select class="form-control" id="customerId" name="customerId" required><option value="">Select a customer</option><cfloop array="#prc.customers#" item="customer"><option value="#encodeForHTMLAttribute( customer.id )#">#encodeForHTML( customer.name )# · #encodeForHTML( customer.contact )#</option></cfloop></select></div>
				<div class="form-group"><label for="amount">Invoice amount</label><div class="input-prefix"><span>INR</span><input class="form-control" id="amount" name="amount" type="number" min="1" max="999999999.99" step="0.01" inputmode="decimal" placeholder="125000" required></div></div>
				<div class="form-group"><label for="purchaseOrder">Purchase order</label><input class="form-control" id="purchaseOrder" name="purchaseOrder" type="text" maxlength="80" placeholder="PO-2026-001"></div>
			</div>
		</div>
		<div class="form-section">
			<div class="form-section-heading"><h2>Invoice schedule</h2><p>Set the issue and payment due dates.</p></div>
			<div class="form-grid">
				<div class="form-group"><label for="issueDate">Issue date</label><input class="form-control" id="issueDate" name="issueDate" type="date" value="#dateFormat( now(), 'yyyy-MM-dd' )#" required></div>
				<div class="form-group"><label for="dueDate">Due date</label><input class="form-control" id="dueDate" name="dueDate" type="date" value="#dateFormat( dateAdd( 'd', 30, now() ), 'yyyy-MM-dd' )#" required></div>
				<div class="form-group full"><label for="description">Description</label><textarea class="form-control" id="description" name="description" minlength="3" maxlength="500" placeholder="Describe the delivered work" required>Professional services</textarea><span class="form-hint">This description is visible to the customer in their secure portal.</span></div>
			</div>
		</div>
		<div class="form-actions"><a class="button button-secondary" href="#event.buildLink( 'invoices' )#">Cancel</a><button class="button button-primary" type="submit"><i class="bi bi-check2"></i> Create invoice</button></div>
	</form>
</section>
</cfoutput>
