/**
 * DuePilot v1 domain service.
 *
 * The first product release uses an application-scoped demo repository so the
 * full workflow can be evaluated without requiring database credentials.  The
 * service boundary intentionally mirrors the persistence model in
 * resources/database/schema/mysql.sql, allowing a database repository to
 * replace this implementation without changing handlers or views.
 */
component singleton {
	property name="postgresRepository" inject="PostgresDuePilotRepository";

	variables.lockName = "duepilot-demo-repository";
	variables.store    = {};

	function init(){
		resetDemoData();
		return this;
	}

	public void function resetDemoData(){
		if ( isPostgresMode() ) return;
		lock name=variables.lockName type="exclusive" timeout="10" {
			variables.store = {
				organization : {
					id           : "org-northstar",
					name         : "Northstar Digital",
					initials     : "ND",
					plan         : "Growth trial",
					currency     : "INR",
					financeEmail : "finance@northstardigital.in",
					defaultTerms : 30
				},
				customers : buildCustomers(),
				invoices  : buildInvoices(),
				activities : buildActivities()
			};
		}
	}

	public struct function getOrganization(){
		if ( isPostgresMode() ) return postgresRepository.getOrganization();
		return duplicate( variables.store.organization );
	}

	public struct function updateOrganization(
		required string name,
		required string currency,
		required string financeEmail,
		required numeric defaultTerms
	){
		var cleanName = trim( reReplace( arguments.name, "\s+", " ", "all" ) );
		var cleanCurrency = uCase( trim( arguments.currency ) );
		var cleanEmail = lCase( trim( arguments.financeEmail ) );
		if ( len( cleanName ) < 2 || len( cleanName ) > 100 ) {
			throw( type = "DuePilot.InvalidOrganization", message = "Organization name must be between 2 and 100 characters." );
		}
		if ( !listFindNoCase( "INR,USD", cleanCurrency ) ) {
			throw( type = "DuePilot.InvalidCurrency", message = "Choose INR or USD as the base currency." );
		}
		if ( len( cleanEmail ) > 254 || !isValid( "email", cleanEmail ) ) {
			throw( type = "DuePilot.InvalidEmail", message = "Enter a valid finance email address." );
		}
		if ( !listFind( "15,30,45", arguments.defaultTerms ) ) {
			throw( type = "DuePilot.InvalidTerms", message = "Choose Net 15, Net 30 or Net 45 payment terms." );
		}
		if ( isPostgresMode() ) return postgresRepository.updateOrganization( cleanName, cleanCurrency, cleanEmail, arguments.defaultTerms );

		lock name=variables.lockName type="exclusive" timeout="10" {
			if ( cleanCurrency != variables.store.organization.currency && variables.store.invoices.len() ) {
				throw( type = "DuePilot.CurrencyLocked", message = "Base currency cannot be changed after invoices have been created." );
			}
			var nameParts = listToArray( cleanName, " " );
			variables.store.organization.name         = cleanName;
			variables.store.organization.initials     = uCase( left( nameParts[ 1 ], 1 ) & ( nameParts.len() > 1 ? left( nameParts[ nameParts.len() ], 1 ) : "" ) );
			variables.store.organization.currency     = cleanCurrency;
			variables.store.organization.financeEmail = cleanEmail;
			variables.store.organization.defaultTerms = arguments.defaultTerms;
		}
		return getOrganization();
	}

	public struct function getDashboard(){
		var invoices       = listInvoices();
		var customers      = listCustomers();
		var totalBilled    = 0;
		var totalPaid      = 0;
		var totalOpen      = 0;
		var overdueAmount  = 0;
		var overdueCount   = 0;
		var dueSoonAmount  = 0;
		var disputedAmount = 0;

		for ( var invoice in invoices ) {
			totalBilled += invoice.amount;
			totalPaid   += invoice.paidAmount;
			totalOpen   += invoice.outstanding;

			if ( invoice.daysOverdue > 0 && invoice.status != "paid" ) {
				overdueAmount += invoice.outstanding;
				overdueCount++;
			}
			if ( invoice.daysUntilDue >= 0 && invoice.daysUntilDue <= 7 && invoice.status != "paid" ) {
				dueSoonAmount += invoice.outstanding;
			}
			if ( invoice.status == "disputed" ) {
				disputedAmount += invoice.outstanding;
			}
		}

		var priorityInvoices = invoices.filter( function( item ){
			return item.status != "paid";
		} );
		priorityInvoices.sort( function( leftItem, rightItem ){
			if ( leftItem.status == "disputed" && rightItem.status != "disputed" ) {
				return -1;
			}
			if ( rightItem.status == "disputed" && leftItem.status != "disputed" ) {
				return 1;
			}
			return rightItem.daysOverdue - leftItem.daysOverdue;
		} );
		if ( priorityInvoices.len() > 6 ) {
			priorityInvoices = priorityInvoices.slice( 1, 6 );
		}

		return {
			organization     : getOrganization(),
			outstanding      : totalOpen,
			overdueAmount    : overdueAmount,
			overdueCount     : overdueCount,
			dueSoonAmount    : dueSoonAmount,
			disputedAmount   : disputedAmount,
			collectedAmount  : totalPaid,
			collectionRate   : totalBilled ? round( ( totalPaid / totalBilled ) * 100 ) : 0,
			customerCount    : customers.len(),
			priorityInvoices : priorityInvoices,
			recentActivity   : getRecentActivity( 6 ),
			aging            : calculateAging( invoices ),
			forecast         : buildForecast()
		};
	}

	public array function listInvoices( string status = "", string search = "" ){
		if ( isPostgresMode() ) return postgresRepository.listInvoices( arguments.status, arguments.search );
		var output = [];
		var wantedStatus = lCase( trim( arguments.status ) );
		var wantedSearch = lCase( trim( arguments.search ) );

		for ( var sourceInvoice in variables.store.invoices ) {
			var invoice = decorateInvoice( sourceInvoice );
			if ( len( wantedStatus ) && wantedStatus != "all" && invoice.status != wantedStatus ) {
				continue;
			}
			if ( len( wantedSearch ) && !findNoCase( wantedSearch, invoice.invoiceNumber & " " & invoice.customerName ) ) {
				continue;
			}
			output.append( invoice );
		}

		output.sort( function( leftItem, rightItem ){
			return compare( rightItem.issueDate, leftItem.issueDate );
		} );
		return output;
	}

	public struct function getInvoice( required string invoiceId ){
		if ( isPostgresMode() ) return postgresRepository.getInvoice( arguments.invoiceId );
		var index = findInvoiceIndex( arguments.invoiceId );
		if ( !index ) {
			throw( type = "DuePilot.InvoiceNotFound", message = "Invoice not found." );
		}
		return decorateInvoice( variables.store.invoices[ index ] );
	}

	public struct function getInvoiceByPortalToken( required string portalToken ){
		if ( isPostgresMode() ) return postgresRepository.getInvoiceByPortalToken( arguments.portalToken );
		for ( var invoice in variables.store.invoices ) {
			if ( compareNoCase( invoice.portalToken, arguments.portalToken ) == 0 ) {
				return decorateInvoice( invoice );
			}
		}
		throw( type = "DuePilot.PortalLinkNotFound", message = "This payment link is invalid or has expired." );
	}

	public struct function createInvoice(
		required string customerId,
		required numeric amount,
		required string issueDate,
		required string dueDate,
		string purchaseOrder = "",
		string description = "Professional services"
	){
		if ( arguments.amount <= 0 ) {
			throw( type = "DuePilot.InvalidAmount", message = "Invoice amount must be greater than zero." );
		}
		if ( arguments.amount > 999999999.99 ) {
			throw( type = "DuePilot.InvalidAmount", message = "Invoice amount must be below INR 1,000,000,000." );
		}
		var normalizedIssueDate = normalizeDate( arguments.issueDate, "Issue date" );
		var normalizedDueDate   = normalizeDate( arguments.dueDate, "Due date" );
		if ( dateCompare( parseDateTime( normalizedDueDate ), parseDateTime( normalizedIssueDate ) ) < 0 ) {
			throw( type = "DuePilot.InvalidDateRange", message = "Due date cannot be before the issue date." );
		}
		var cleanDescription = trim( arguments.description );
		var cleanPurchaseOrder = trim( arguments.purchaseOrder );
		if ( len( cleanDescription ) < 3 || len( cleanDescription ) > 500 ) {
			throw( type = "DuePilot.InvalidDescription", message = "Description must be between 3 and 500 characters." );
		}
		if ( len( cleanPurchaseOrder ) > 80 ) {
			throw( type = "DuePilot.InvalidPurchaseOrder", message = "Purchase order must be 80 characters or fewer." );
		}
		getCustomer( arguments.customerId );
		if ( isPostgresMode() ) return postgresRepository.createInvoice( argumentCollection=arguments );

		var createdInvoice = {};
		lock name=variables.lockName type="exclusive" timeout="10" {
			var nextNumber = 1049 + variables.store.invoices.len();
			createdInvoice = {
				id             : "inv-" & lCase( replace( createUUID(), "-", "", "all" ) ),
				invoiceNumber  : "INV-#year( now() )#-#nextNumber#",
				customerId     : arguments.customerId,
				amount         : arguments.amount,
				paidAmount     : 0,
				issueDate      : normalizedIssueDate,
				dueDate        : normalizedDueDate,
				purchaseOrder  : cleanPurchaseOrder,
				description    : cleanDescription,
				owner          : "Alex Morgan",
				statusOverride : "",
				promiseDate    : "",
				disputeReason  : "",
				reminderCount  : 0,
				lastContactAt  : "",
				paidAt         : "",
				paymentRef     : "",
				portalToken    : lCase( replace( createUUID(), "-", "", "all" ) )
			};
			variables.store.invoices.prepend( createdInvoice );
			addActivity(
				"invoice",
				"Invoice #createdInvoice.invoiceNumber# created",
				"#getCustomerName( createdInvoice.customerId )# - #moneyLabel( createdInvoice.amount )#",
				createdInvoice.id
			);
		}
		return decorateInvoice( createdInvoice );
	}

	public struct function recordPayment( required string invoiceId, required numeric amount, string reference = "" ){
		if ( arguments.amount <= 0 ) {
			throw( type = "DuePilot.InvalidAmount", message = "Payment amount must be greater than zero." );
		}
		if ( len( trim( arguments.reference ) ) > 100 ) {
			throw( type = "DuePilot.InvalidReference", message = "Payment reference must be 100 characters or fewer." );
		}
		if ( isPostgresMode() ) return postgresRepository.recordPayment( argumentCollection=arguments );

		var updatedInvoice = {};
		lock name=variables.lockName type="exclusive" timeout="10" {
			var index   = requiredInvoiceIndex( arguments.invoiceId );
			var invoice = variables.store.invoices[ index ];
			var remaining = invoice.amount - invoice.paidAmount;
			if ( remaining <= 0 ) {
				throw( type = "DuePilot.AlreadyPaid", message = "This invoice is already fully paid." );
			}
			if ( arguments.amount > remaining ) {
				throw( type = "DuePilot.Overpayment", message = "Payment cannot be greater than the outstanding balance." );
			}
			invoice.paidAmount = invoice.paidAmount + arguments.amount;
			invoice.paymentRef = trim( arguments.reference );
			invoice.paidAt     = dateTimeFormat( now(), "yyyy-mm-dd HH:nn" );
			invoice.statusOverride = invoice.paidAmount >= invoice.amount ? "paid" : "";
			variables.store.invoices[ index ] = invoice;
			updatedInvoice = invoice;
			var paymentSource = len( trim( arguments.reference ) ) ? trim( arguments.reference ) : "manual entry";
			addActivity(
				"payment",
				"Payment recorded for #invoice.invoiceNumber#",
				"#moneyLabel( min( remaining, arguments.amount ) )# received - #paymentSource#",
				invoice.id
			);
		}
		return decorateInvoice( updatedInvoice );
	}

	public struct function savePromise( required string invoiceId, required string promiseDate, string note = "" ){
		var normalizedPromiseDate = normalizeDate( arguments.promiseDate, "Payment promise date" );
		if ( dateCompare( parseDateTime( normalizedPromiseDate ), parseDateTime( dateText( 0 ) ) ) < 0 ) {
			throw( type = "DuePilot.InvalidPromiseDate", message = "Payment promise date cannot be in the past." );
		}
		if ( len( trim( arguments.note ) ) > 500 ) {
			throw( type = "DuePilot.InvalidPromiseNote", message = "Promise note must be 500 characters or fewer." );
		}
		if ( isPostgresMode() ) return postgresRepository.savePromise( argumentCollection=arguments );
		var updatedInvoice = {};
		lock name=variables.lockName type="exclusive" timeout="10" {
			var index   = requiredInvoiceIndex( arguments.invoiceId );
			var invoice = variables.store.invoices[ index ];
			if ( invoice.paidAmount >= invoice.amount ) {
				throw( type = "DuePilot.AlreadyPaid", message = "A payment promise cannot be added to a paid invoice." );
			}
			invoice.promiseDate   = normalizedPromiseDate;
			invoice.promiseNote   = trim( arguments.note );
			invoice.lastContactAt = dateTimeFormat( now(), "yyyy-mm-dd HH:nn" );
			variables.store.invoices[ index ] = invoice;
			updatedInvoice = invoice;
			addActivity(
				"promise",
				"Payment promise captured",
				"#invoice.invoiceNumber# - expected #dateFormat( parseDateTime( normalizedPromiseDate ), "dd mmm yyyy" )#",
				invoice.id
			);
		}
		return decorateInvoice( updatedInvoice );
	}

	public struct function openDispute( required string invoiceId, required string reason ){
		var cleanReason = trim( arguments.reason );
		if ( len( cleanReason ) < 10 || len( cleanReason ) > 1000 ) {
			throw( type = "DuePilot.InvalidDispute", message = "Dispute reason must be between 10 and 1,000 characters." );
		}
		if ( isPostgresMode() ) return postgresRepository.openDispute( arguments.invoiceId, cleanReason );

		var updatedInvoice = {};
		lock name=variables.lockName type="exclusive" timeout="10" {
			var index   = requiredInvoiceIndex( arguments.invoiceId );
			var invoice = variables.store.invoices[ index ];
			if ( invoice.paidAmount >= invoice.amount ) {
				throw( type = "DuePilot.AlreadyPaid", message = "A dispute cannot be opened on a paid invoice." );
			}
			invoice.statusOverride = "disputed";
			invoice.disputeReason  = cleanReason;
			invoice.lastContactAt  = dateTimeFormat( now(), "yyyy-mm-dd HH:nn" );
			variables.store.invoices[ index ] = invoice;
			updatedInvoice = invoice;
			addActivity(
				"dispute",
				"Dispute opened on #invoice.invoiceNumber#",
				cleanReason,
				invoice.id
			);
		}
		return decorateInvoice( updatedInvoice );
	}

	public struct function sendReminder( required string invoiceId, string channel = "email" ){
		var cleanChannel = lCase( trim( arguments.channel ) );
		if ( !listFindNoCase( "email,whatsapp,sms", cleanChannel ) ) {
			throw( type = "DuePilot.InvalidChannel", message = "Choose email, WhatsApp or SMS." );
		}
		if ( isPostgresMode() ) return postgresRepository.sendReminder( arguments.invoiceId, cleanChannel );
		var updatedInvoice = {};
		lock name=variables.lockName type="exclusive" timeout="10" {
			var index   = requiredInvoiceIndex( arguments.invoiceId );
			var invoice = variables.store.invoices[ index ];
			if ( invoice.paidAmount >= invoice.amount ) {
				throw( type = "DuePilot.AlreadyPaid", message = "A reminder cannot be sent for a paid invoice." );
			}
			invoice.reminderCount++;
			invoice.lastContactAt = dateTimeFormat( now(), "yyyy-mm-dd HH:nn" );
			variables.store.invoices[ index ] = invoice;
			updatedInvoice = invoice;
			addActivity(
				"reminder",
				"Reminder sent to #getCustomerName( invoice.customerId )#",
				invoice.invoiceNumber & " - " & cleanChannel & " reminder " & invoice.reminderCount,
				invoice.id
			);
		}
		return decorateInvoice( updatedInvoice );
	}

	public array function listCustomers( string search = "" ){
		if ( isPostgresMode() ) return postgresRepository.listCustomers( arguments.search );
		var output = [];
		for ( var sourceCustomer in variables.store.customers ) {
			if ( len( trim( arguments.search ) ) && !findNoCase( arguments.search, sourceCustomer.name & " " & sourceCustomer.email ) ) {
				continue;
			}
			output.append( decorateCustomer( sourceCustomer ) );
		}
		output.sort( function( leftItem, rightItem ){
			return rightItem.outstanding - leftItem.outstanding;
		} );
		return output;
	}

	public struct function getCustomer( required string customerId ){
		if ( isPostgresMode() ) return postgresRepository.getCustomer( arguments.customerId );
		for ( var customer in variables.store.customers ) {
			if ( customer.id == arguments.customerId ) {
				return decorateCustomer( customer );
			}
		}
		throw( type = "DuePilot.CustomerNotFound", message = "Customer not found." );
	}

	public array function getCollectionQueue(){
		var queue = listInvoices().filter( function( invoice ){
			return invoice.status != "paid";
		} );
		queue.sort( function( leftItem, rightItem ){
			return rightItem.daysOverdue - leftItem.daysOverdue;
		} );
		return queue;
	}

	public struct function getReports(){
		var invoices = listInvoices();
		var customers = listCustomers();
		var dashboard = getDashboard();
		var topCustomers = duplicate( customers );
		if ( topCustomers.len() > 5 ) {
			topCustomers = topCustomers.slice( 1, 5 );
		}

		return {
			aging         : dashboard.aging,
			topCustomers  : topCustomers,
			collectionRate: dashboard.collectionRate,
			avgDaysToPay  : 34,
			promiseKept   : 78,
			monthly       : [
				{ label : "May", billed : 610000, collected : 520000 },
				{ label : "Jun", billed : 720000, collected : 640000 },
				{ label : "Jul", billed : 680000, collected : 590000 },
				{ label : "Aug", billed : 810000, collected : 725000 },
				{ label : "Sep", billed : 760000, collected : 690000 },
				{ label : "Oct", billed : 890000, collected : dashboard.collectedAmount }
			]
		};
	}

	public array function getRecentActivity( numeric limit = 10 ){
		if ( isPostgresMode() ) return postgresRepository.getRecentActivity( arguments.limit );
		var activities = duplicate( variables.store.activities );
		if ( activities.len() > arguments.limit ) {
			return activities.slice( 1, arguments.limit );
		}
		return activities;
	}

	/**
	 * A deliberately narrow, non-sensitive snapshot for the finance copilot.
	 * Contact details, portal tokens and internal identifiers are excluded.
	 */
	public struct function getAssistantContext(){
		var dashboard = getDashboard();
		var queue     = getCollectionQueue();
		var priorities = [];

		for ( var index = 1; index <= min( 5, queue.len() ); index++ ) {
			var invoice = queue[ index ];
			priorities.append( {
				invoiceNumber : invoice.invoiceNumber,
				customerName  : invoice.customerName,
				outstanding   : invoice.outstanding,
				daysOverdue   : invoice.daysOverdue,
				status        : invoice.status,
				statusLabel   : invoice.status == "disputed"
					? "Disputed"
					: ( invoice.daysOverdue > 0 ? invoice.daysOverdue & " days overdue" : "Due in " & invoice.daysUntilDue & " days" ),
				promiseDate   : invoice.promiseDate
			} );
		}

		return {
			generatedAt : dateTimeFormat( dateConvert( "local2utc", now() ), "yyyy-mm-dd HH:nn 'UTC'" ),
			currency    : dashboard.organization.currency,
			summary     : {
				outstanding     : dashboard.outstanding,
				overdueAmount   : dashboard.overdueAmount,
				overdueCount    : dashboard.overdueCount,
				dueSoonAmount   : dashboard.dueSoonAmount,
				disputedAmount  : dashboard.disputedAmount,
				collectionRate  : dashboard.collectionRate,
				openInvoiceCount: queue.len()
			},
			aging      : dashboard.aging,
			priorities : priorities
		};
	}

	private string function normalizeDate( required any value, required string label ){
		var candidate = trim( toString( arguments.value ) );
		if ( !reFind( "^\d{4}-\d{2}-\d{2}$", candidate ) || !isDate( candidate ) ) {
			throw( type = "DuePilot.InvalidDate", message = arguments.label & " must be a valid date." );
		}
		return dateFormat( parseDateTime( candidate ), "yyyy-mm-dd" );
	}

	private array function buildCustomers(){
		return [
			{ id : "cus-atlas", name : "Atlas Manufacturing", contact : "Priya Shah", email : "accounts@atlasmfg.in", phone : "+91 98400 24018", initials : "AM", color : "indigo", avgDaysLate : 18 },
			{ id : "cus-kaveri", name : "Kaveri Systems", contact : "Arun Kumar", email : "finance@kaverisystems.com", phone : "+91 98840 73102", initials : "KS", color : "teal", avgDaysLate : 7 },
			{ id : "cus-greengrid", name : "GreenGrid Energy", contact : "Meera Nair", email : "payables@greengrid.in", phone : "+91 90031 88214", initials : "GE", color : "green", avgDaysLate : 3 },
			{ id : "cus-pixelcraft", name : "PixelCraft Studios", contact : "Rahul Jain", email : "rahul@pixelcraft.studio", phone : "+91 97908 44391", initials : "PS", color : "amber", avgDaysLate : 12 },
			{ id : "cus-vertex", name : "Vertex Consulting", contact : "Sneha Iyer", email : "billing@vertexconsulting.in", phone : "+91 94444 10872", initials : "VC", color : "blue", avgDaysLate : 4 },
			{ id : "cus-mosaic", name : "Mosaic Retail Labs", contact : "Vikram Rao", email : "ap@mosaicretail.com", phone : "+91 98412 99820", initials : "MR", color : "violet", avgDaysLate : 10 },
			{ id : "cus-bluepeak", name : "BluePeak Analytics", contact : "Nisha Thomas", email : "nisha@bluepeakanalytics.com", phone : "+91 89391 22841", initials : "BA", color : "cyan", avgDaysLate : 0 },
			{ id : "cus-brightline", name : "Brightline Media", contact : "Karan Singh", email : "finance@brightline.media", phone : "+91 87545 66712", initials : "BM", color : "rose", avgDaysLate : 22 }
		];
	}

	private array function buildInvoices(){
		return [
			invoiceSeed( "inv-1048", "INV-#year( now() )#-1048", "cus-atlas", 185000, 0, -48, -18, "Website modernization and integrations", "PO-ATL-8821", "", "", "", 3 ),
			invoiceSeed( "inv-1047", "INV-#year( now() )#-1047", "cus-brightline", 45000, 0, -41, -11, "Campaign analytics implementation", "BL-2026-091", "", "", "", 2 ),
			invoiceSeed( "inv-1046", "INV-#year( now() )#-1046", "cus-kaveri", 248000, 0, -36, -6, "Q3 product engineering retainer", "KS-RET-330", dateText( 2 ), "", "", 2 ),
			invoiceSeed( "inv-1045", "INV-#year( now() )#-1045", "cus-pixelcraft", 67500, 0, -31, -1, "Design system implementation", "PC-445", "", "disputed", "Purchase order amount does not match the invoice.", 1 ),
			invoiceSeed( "inv-1044", "INV-#year( now() )#-1044", "cus-greengrid", 156000, 0, -28, 2, "Operations dashboard delivery", "GG-OPS-19", "", "", "", 1 ),
			invoiceSeed( "inv-1043", "INV-#year( now() )#-1043", "cus-vertex", 84000, 0, -25, 5, "Cloud migration advisory", "VC-CLOUD-76", "", "", "", 0 ),
			invoiceSeed( "inv-1042", "INV-#year( now() )#-1042", "cus-mosaic", 120000, 40000, -38, -8, "Commerce API development", "MRL-API-112", dateText( 4 ), "", "", 2 ),
			invoiceSeed( "inv-1041", "INV-#year( now() )#-1041", "cus-bluepeak", 98000, 98000, -52, -22, "Data pipeline optimization", "BPA-801", "", "paid", "", 1, -16, "UTR982135710" ),
			invoiceSeed( "inv-1040", "INV-#year( now() )#-1040", "cus-greengrid", 74000, 74000, -61, -31, "Support and maintenance", "GG-SUP-18", "", "paid", "", 1, -28, "UTR741220884" ),
			invoiceSeed( "inv-1039", "INV-#year( now() )#-1039", "cus-atlas", 132000, 0, -65, -35, "ERP integration milestone", "PO-ATL-8702", "", "", "", 4 ),
			invoiceSeed( "inv-1038", "INV-#year( now() )#-1038", "cus-vertex", 54000, 54000, -70, -40, "Architecture assessment", "VC-ARCH-61", "", "paid", "", 1, -36, "UTR540008521" ),
			invoiceSeed( "inv-1037", "INV-#year( now() )#-1037", "cus-mosaic", 88000, 88000, -78, -48, "Mobile checkout discovery", "MRL-MOB-104", "", "paid", "", 2, -43, "UTR880014602" )
		];
	}

	private struct function invoiceSeed(
		required string id,
		required string invoiceNumber,
		required string customerId,
		required numeric amount,
		required numeric paidAmount,
		required numeric issueOffset,
		required numeric dueOffset,
		required string description,
		required string purchaseOrder,
		string promiseDate = "",
		string statusOverride = "",
		string disputeReason = "",
		numeric reminderCount = 0,
		numeric paidOffset = 0,
		string paymentRef = ""
	){
		return {
			id             : arguments.id,
			invoiceNumber  : arguments.invoiceNumber,
			customerId     : arguments.customerId,
			amount         : arguments.amount,
			paidAmount     : arguments.paidAmount,
			issueDate      : dateText( arguments.issueOffset ),
			dueDate        : dateText( arguments.dueOffset ),
			description    : arguments.description,
			purchaseOrder  : arguments.purchaseOrder,
			owner          : "Alex Morgan",
			promiseDate    : arguments.promiseDate,
			promiseNote    : len( arguments.promiseDate ) ? "Confirmed by customer finance team." : "",
			statusOverride : arguments.statusOverride,
			disputeReason  : arguments.disputeReason,
			reminderCount  : arguments.reminderCount,
			lastContactAt  : arguments.reminderCount ? dateTimeFormat( dateAdd( "d", -1, now() ), "yyyy-mm-dd HH:nn" ) : "",
			paidAt         : arguments.statusOverride == "paid" ? dateTimeFormat( dateAdd( "d", arguments.paidOffset, now() ), "yyyy-mm-dd HH:nn" ) : "",
			paymentRef     : arguments.paymentRef,
			portalToken    : lCase( replace( createUUID(), "-", "", "all" ) )
		};
	}

	private array function buildActivities(){
		return [
			{ kind : "promise", title : "Kaveri Systems promised payment", detail : "INV-#year( now() )#-1046 - expected #dateFormat( dateAdd( "d", 2, now() ), "dd mmm" )#", at : "18 minutes ago", invoiceId : "inv-1046" },
			{ kind : "dispute", title : "PixelCraft raised a dispute", detail : "Purchase order amount mismatch", at : "1 hour ago", invoiceId : "inv-1045" },
			{ kind : "payment", title : "Payment received from BluePeak", detail : "#moneyLabel( 98000 )# - UTR982135710", at : "Yesterday", invoiceId : "inv-1041" },
			{ kind : "reminder", title : "Reminder sent to Atlas Manufacturing", detail : "INV-#year( now() )#-1048 - email reminder 3", at : "Yesterday", invoiceId : "inv-1048" },
			{ kind : "invoice", title : "Invoice INV-#year( now() )#-1044 created", detail : "GreenGrid Energy - #moneyLabel( 156000 )#", at : "2 days ago", invoiceId : "inv-1044" },
			{ kind : "payment", title : "Payment received from GreenGrid", detail : "#moneyLabel( 74000 )# - UTR741220884", at : "3 days ago", invoiceId : "inv-1040" }
		];
	}

	private struct function decorateInvoice( required struct sourceInvoice ){
		var invoice = duplicate( arguments.sourceInvoice );
		var dueDate = parseDateTime( invoice.dueDate );
		invoice.customerName  = getCustomerName( invoice.customerId );
		invoice.outstanding   = max( 0, invoice.amount - invoice.paidAmount );
		invoice.daysUntilDue  = dateDiff( "d", parseDateTime( dateText( 0 ) ), dueDate );
		invoice.daysOverdue   = invoice.daysUntilDue < 0 ? abs( invoice.daysUntilDue ) : 0;
		invoice.paymentPercent = invoice.amount ? round( ( invoice.paidAmount / invoice.amount ) * 100 ) : 0;

		if ( invoice.paidAmount >= invoice.amount || invoice.statusOverride == "paid" ) {
			invoice.status = "paid";
		} else if ( invoice.statusOverride == "disputed" ) {
			invoice.status = "disputed";
		} else if ( invoice.paidAmount > 0 ) {
			invoice.status = "partial";
		} else if ( invoice.daysUntilDue < 0 ) {
			invoice.status = "overdue";
		} else if ( invoice.daysUntilDue <= 7 ) {
			invoice.status = "due_soon";
		} else {
			invoice.status = "open";
		}
		return invoice;
	}

	private struct function decorateCustomer( required struct sourceCustomer ){
		var customer = duplicate( arguments.sourceCustomer );
		customer.invoiceCount = 0;
		customer.outstanding  = 0;
		customer.overdue      = 0;
		customer.paid         = 0;

		for ( var sourceInvoice in variables.store.invoices ) {
			if ( sourceInvoice.customerId != customer.id ) {
				continue;
			}
			var invoice = decorateInvoice( sourceInvoice );
			customer.invoiceCount++;
			customer.outstanding += invoice.outstanding;
			customer.paid        += invoice.paidAmount;
			if ( invoice.daysOverdue > 0 && invoice.status != "paid" ) {
				customer.overdue += invoice.outstanding;
			}
		}

		customer.health = customer.avgDaysLate <= 3 ? "excellent" : ( customer.avgDaysLate <= 10 ? "watch" : "at_risk" );
		return customer;
	}

	private struct function calculateAging( required array invoices ){
		var aging = { current : 0, oneToThirty : 0, thirtyOneToSixty : 0, overSixty : 0 };
		for ( var invoice in arguments.invoices ) {
			if ( invoice.status == "paid" ) {
				continue;
			}
			if ( invoice.daysOverdue == 0 ) {
				aging.current += invoice.outstanding;
			} else if ( invoice.daysOverdue <= 30 ) {
				aging.oneToThirty += invoice.outstanding;
			} else if ( invoice.daysOverdue <= 60 ) {
				aging.thirtyOneToSixty += invoice.outstanding;
			} else {
				aging.overSixty += invoice.outstanding;
			}
		}
		aging.total = aging.current + aging.oneToThirty + aging.thirtyOneToSixty + aging.overSixty;
		return aging;
	}

	private array function buildForecast(){
		return [
			{ label : "This week", amount : 164000, confidence : 82 },
			{ label : "Next week", amount : 312000, confidence : 68 },
			{ label : "Later", amount : 441500, confidence : 54 }
		];
	}

	private numeric function findInvoiceIndex( required string invoiceId ){
		for ( var index = 1; index <= variables.store.invoices.len(); index++ ) {
			if ( variables.store.invoices[ index ].id == arguments.invoiceId ) {
				return index;
			}
		}
		return 0;
	}

	private numeric function requiredInvoiceIndex( required string invoiceId ){
		var index = findInvoiceIndex( arguments.invoiceId );
		if ( !index ) {
			throw( type = "DuePilot.InvoiceNotFound", message = "Invoice not found." );
		}
		return index;
	}

	private string function getCustomerName( required string customerId ){
		for ( var customer in variables.store.customers ) {
			if ( customer.id == arguments.customerId ) {
				return customer.name;
			}
		}
		return "Unknown customer";
	}

	private void function addActivity(
		required string kind,
		required string title,
		required string detail,
		string invoiceId = ""
	){
		variables.store.activities.prepend( {
			kind      : arguments.kind,
			title     : arguments.title,
			detail    : arguments.detail,
			at        : "Just now",
			invoiceId : arguments.invoiceId
		} );
	}

	private string function dateText( required numeric dayOffset ){
		return dateFormat( dateAdd( "d", arguments.dayOffset, now() ), "yyyy-mm-dd" );
	}

	private string function moneyLabel( required numeric amount ){
		return "INR " & numberFormat( arguments.amount, ",999" );
	}

	private boolean function isPostgresMode(){
		return compareNoCase( getSystemSetting( "DATA_MODE", "demo" ), "postgres" ) == 0;
	}

}
