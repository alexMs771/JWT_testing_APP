/**
 * DuePilot product workflows.
 *
 * All mutations are protected by the signed-in session and a per-session CSRF
 * token. The injected service is deliberately persistence-agnostic so the demo
 * repository can later be replaced by MySQL without changing these actions.
 */
component extends="coldbox.system.EventHandler" {

	property name="duePilotService" inject="DuePilotService";

	function dashboard( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Dashboard", "dashboard" ) ) return;
		prc.dashboard = duePilotService.getDashboard();
		event.setView( "duePilot/dashboard" );
	}

	function invoices( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Invoices", "invoices" ) ) return;
		param rc.status = "all";
		param rc.search = "";
		prc.statusFilter = lCase( trim( rc.status ) );
		prc.search       = trim( rc.search );
		prc.invoices     = duePilotService.listInvoices( prc.statusFilter, prc.search );
		event.setView( "duePilot/invoices/index" );
	}

	function invoice( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Invoice details", "invoices" ) ) return;
		try {
			prc.invoice = duePilotService.getInvoice( rc.invoiceId ?: "" );
		} catch ( any error ) {
			relocate( URI = "/invoices", persistStruct = { error : error.message } );
			return;
		}
		event.setView( "duePilot/invoices/show" );
	}

	function newInvoice( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Create invoice", "invoices" ) ) return;
		prc.customers = duePilotService.listCustomers();
		event.setView( "duePilot/invoices/new" );
	}

	function createInvoice( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		param rc.customerId = "";
		param rc.amount = 0;
		param rc.issueDate = dateFormat( now(), "yyyy-MM-dd" );
		param rc.dueDate = dateFormat( dateAdd( "d", 30, now() ), "yyyy-MM-dd" );
		param rc.purchaseOrder = "";
		param rc.description = "Professional services";

		try {
			var created = duePilotService.createInvoice(
				customerId    = rc.customerId,
				amount        = val( rc.amount ),
				issueDate     = rc.issueDate,
				dueDate       = rc.dueDate,
				purchaseOrder = rc.purchaseOrder,
				description   = rc.description
			);
			relocate(
				URI           = "/invoices/#created.id#",
				persistStruct = { notice : "Invoice #created.invoiceNumber# was created." }
			);
			return;
		} catch ( any error ) {
			relocate( URI = "/invoices/new", persistStruct = { error : error.message } );
			return;
		}
	}

	function recordPayment( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		param rc.invoiceId = "";
		param rc.amount = 0;
		param rc.reference = "";
		try {
			var invoice = duePilotService.recordPayment( rc.invoiceId, val( rc.amount ), rc.reference );
			backToInvoice( invoice.id, "Payment recorded successfully." );
			return;
		} catch ( any error ) {
			backToInvoice( rc.invoiceId, "", error.message );
			return;
		}
	}

	function savePromise( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		param rc.invoiceId = "";
		param rc.promiseDate = "";
		param rc.note = "";
		try {
			duePilotService.savePromise( rc.invoiceId, rc.promiseDate, rc.note );
			backToInvoice( rc.invoiceId, "Payment promise saved." );
			return;
		} catch ( any error ) {
			backToInvoice( rc.invoiceId, "", error.message );
			return;
		}
	}

	function openDispute( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		param rc.invoiceId = "";
		param rc.reason = "";
		try {
			duePilotService.openDispute( rc.invoiceId, rc.reason );
			backToInvoice( rc.invoiceId, "Dispute opened and assigned for review." );
			return;
		} catch ( any error ) {
			backToInvoice( rc.invoiceId, "", error.message );
			return;
		}
	}

	function sendReminder( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		param rc.invoiceId = "";
		param rc.channel = "email";
		try {
			duePilotService.sendReminder( rc.invoiceId, rc.channel );
			backToInvoice( rc.invoiceId, "Reminder queued for delivery." );
			return;
		} catch ( any error ) {
			backToInvoice( rc.invoiceId, "", error.message );
			return;
		}
	}

	function customers( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Customers", "customers" ) ) return;
		param rc.search = "";
		prc.search    = trim( rc.search );
		prc.customers = duePilotService.listCustomers( prc.search );
		event.setView( "duePilot/customers/index" );
	}

	function customer( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Customer details", "customers" ) ) return;
		try {
			prc.customer = duePilotService.getCustomer( rc.customerId ?: "" );
			prc.invoices = duePilotService.listInvoices().filter( function( invoice ){
				return invoice.customerId == prc.customer.id;
			} );
		} catch ( any error ) {
			relocate( URI = "/customers", persistStruct = { error : error.message } );
			return;
		}
		event.setView( "duePilot/customers/show" );
	}

	function collections( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Collections", "collections" ) ) return;
		prc.queue = duePilotService.getCollectionQueue();
		event.setView( "duePilot/collections/index" );
	}

	function reports( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Reports", "reports" ) ) return;
		prc.reports = duePilotService.getReports();
		event.setView( "duePilot/reports/index" );
	}

	function settings( event, rc, prc ){
		if ( !prepareAppPage( event, prc, "Settings", "settings" ) ) return;
		event.setView( "duePilot/settings/index" );
	}

	function updateSettings( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		param rc.organizationName = "";
		param rc.currency = "INR";
		param rc.financeEmail = "";
		param rc.defaultTerms = 30;
		try {
			duePilotService.updateOrganization(
				name         = rc.organizationName,
				currency     = rc.currency,
				financeEmail = rc.financeEmail,
				defaultTerms = val( rc.defaultTerms )
			);
			relocate( URI = "/settings", persistStruct = { notice : "Workspace settings saved." } );
			return;
		} catch ( any error ) {
			relocate( URI = "/settings", persistStruct = { error : error.message } );
			return;
		}
	}

	function resetDemo( event, rc, prc ){
		if ( !protectMutation( event, rc ) ) return;
		duePilotService.resetDemoData();
		relocate( URI = "/settings", persistStruct = { notice : "Demo workspace restored to its original data." } );
	}

	function portal( event, rc, prc ){
		ensureCsrfToken();
		try {
			prc.invoice      = duePilotService.getInvoiceByPortalToken( rc.portalToken ?: "" );
			prc.organization = duePilotService.getOrganization();
			prc.csrfToken    = session.csrfToken;
			prc.pageTitle    = "Invoice #prc.invoice.invoiceNumber#";
			event.setLayout( "Portal" );
			event.setView( "duePilot/portal/invoice" );
		} catch ( any error ) {
			event.setHTTPHeader( statusCode = 404, statusText = "Not Found" );
			return event.renderData( type = "html", statusCode = 404, data = "<h1>Payment link unavailable</h1><p>#encodeForHTML( error.message )#</p>" );
		}
	}

	function portalPromise( event, rc, prc ){
		if ( !requirePost( event ) ) return;
		if ( !verifyCsrf( rc ) ) {
			portalFailure( rc.portalToken ?: "", "Your form expired. Please try again." );
			return;
		}
		param rc.promiseDate = "";
		param rc.note = "";
		try {
			var invoice = duePilotService.getInvoiceByPortalToken( rc.portalToken );
			duePilotService.savePromise( invoice.id, rc.promiseDate, rc.note );
			portalSuccess( rc.portalToken, "Thank you. Your payment date has been shared with the finance team." );
			return;
		} catch ( any error ) {
			portalFailure( rc.portalToken, error.message );
			return;
		}
	}

	function portalDispute( event, rc, prc ){
		if ( !requirePost( event ) ) return;
		if ( !verifyCsrf( rc ) ) {
			portalFailure( rc.portalToken ?: "", "Your form expired. Please try again." );
			return;
		}
		param rc.reason = "";
		try {
			var invoice = duePilotService.getInvoiceByPortalToken( rc.portalToken );
			duePilotService.openDispute( invoice.id, rc.reason );
			portalSuccess( rc.portalToken, "Your query has been opened. The finance team will contact you." );
			return;
		} catch ( any error ) {
			portalFailure( rc.portalToken, error.message );
			return;
		}
	}

	function portalPay( event, rc, prc ){
		if ( !requirePost( event ) ) return;
		if ( !verifyCsrf( rc ) ) {
			portalFailure( rc.portalToken ?: "", "Your form expired. Please try again." );
			return;
		}
		try {
			var invoice = duePilotService.getInvoiceByPortalToken( rc.portalToken );
			duePilotService.recordPayment( invoice.id, invoice.outstanding, "DEMO-UPI-#right( createUUID(), 8 )#" );
			portalSuccess( rc.portalToken, "Demo payment completed. A receipt has been recorded." );
			return;
		} catch ( any error ) {
			portalFailure( rc.portalToken, error.message );
			return;
		}
	}

	private boolean function prepareAppPage( required any event, required struct prc, required string title, required string activeNav ){
		if ( !isSignedIn() ) {
			relocate( URI = "/login", persistStruct = { error : "Please sign in to continue." } );
			return false;
		}
		ensureCsrfToken();
		arguments.prc.pageTitle    = arguments.title;
		arguments.prc.activeNav    = arguments.activeNav;
		arguments.prc.user         = session.user;
		arguments.prc.csrfToken    = session.csrfToken;
		arguments.prc.organization = duePilotService.getOrganization();
		arguments.prc.openInvoiceCount = duePilotService.getCollectionQueue().len();
		arguments.event.setLayout( "App" );
		return true;
	}

	private boolean function protectMutation( required any event, required struct rc ){
		if ( !isSignedIn() ) {
			relocate( URI = "/login", persistStruct = { error : "Please sign in to continue." } );
			return false;
		}
		if ( !requirePost( arguments.event ) ) {
			return false;
		}
		if ( !verifyCsrf( arguments.rc ) ) {
			relocate( URI = "/dashboard", persistStruct = { error : "Your form expired. Please try again." } );
			return false;
		}
		return true;
	}

	private boolean function requirePost( required any event ){
		if ( compareNoCase( cgi.request_method ?: "GET", "POST" ) == 0 ) {
			return true;
		}
		arguments.event.setHTTPHeader( name = "Allow", value = "POST" );
		arguments.event.renderData(
			type       = "html",
			statusCode = 405,
			data       = "<h1>Method not allowed</h1><p>This action requires a form submission.</p>"
		);
		return false;
	}

	private boolean function isSignedIn(){
		return structKeyExists( session, "user" ) && isStruct( session.user ) && structKeyExists( session, "tokens" );
	}

	private void function ensureCsrfToken(){
		if ( !structKeyExists( session, "csrfToken" ) || !len( session.csrfToken ) ) {
			session.csrfToken = hash( createUUID() & getTickCount(), "SHA-256" );
		}
	}

	private boolean function verifyCsrf( required struct rc ){
		return structKeyExists( session, "csrfToken" )
			&& structKeyExists( arguments.rc, "csrfToken" )
			&& len( arguments.rc.csrfToken )
			&& arguments.rc.csrfToken == session.csrfToken;
	}

	private void function backToInvoice( required string invoiceId, string notice = "", string error = "" ){
		relocate(
			URI           = "/invoices/#arguments.invoiceId#",
			persistStruct = { notice : arguments.notice, error : arguments.error }
		);
	}

	private void function portalSuccess( required string portalToken, required string message ){
		relocate(
			URI           = "/pay/#arguments.portalToken#",
			persistStruct = { notice : arguments.message }
		);
	}

	private void function portalFailure( required string portalToken, required string message ){
		relocate(
			URI           = "/pay/#arguments.portalToken#",
			persistStruct = { error : arguments.message }
		);
	}

}
