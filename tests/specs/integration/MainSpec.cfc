component extends="coldbox.system.testing.BaseTestCase" appMapping="/app" {

	function beforeAll(){
		super.beforeAll();
		variables.duePilot = getWireBox().getInstance( "DuePilotService" );
		variables.duePilotAi = getWireBox().getInstance( "DuePilotAiService" );
	}

	function afterAll(){
		variables.duePilot.resetDemoData();
		super.afterAll();
	}

	function run(){
		describe( "DuePilot v1 domain", function(){
			beforeEach( function(){
				setup();
				variables.duePilot.resetDemoData();
			} );

			it( "builds the receivables dashboard from seeded invoices", function(){
				var dashboard = variables.duePilot.getDashboard();
				expect( dashboard.outstanding ).toBeGT( 0 );
				expect( dashboard.overdueCount ).toBeGT( 0 );
				expect( dashboard.priorityInvoices ).notToBeEmpty();
				expect( dashboard.aging.total ).toBe( dashboard.outstanding );
			} );

			it( "creates an invoice and exposes it in the customer portal", function(){
				var invoice = variables.duePilot.createInvoice(
					customerId = "cus-atlas",
					amount     = 125000,
					issueDate  = dateFormat( now(), "yyyy-mm-dd" ),
					dueDate    = dateFormat( dateAdd( "d", 30, now() ), "yyyy-mm-dd" ),
					description = "Test invoice"
				);
				var portalInvoice = variables.duePilot.getInvoiceByPortalToken( invoice.portalToken );
				expect( portalInvoice.id ).toBe( invoice.id );
				expect( portalInvoice.outstanding ).toBe( 125000 );
			} );

			it( "moves an invoice through promise, dispute and payment", function(){
				variables.duePilot.savePromise( "inv-1047", dateFormat( dateAdd( "d", 5, now() ), "yyyy-mm-dd" ), "Confirmed" );
				expect( variables.duePilot.getInvoice( "inv-1047" ).promiseDate ).notToBeEmpty();

				variables.duePilot.openDispute( "inv-1047", "Purchase order mismatch" );
				expect( variables.duePilot.getInvoice( "inv-1047" ).status ).toBe( "disputed" );

				variables.duePilot.recordPayment( "inv-1047", 45000, "TEST-UTR" );
				var paidInvoice = variables.duePilot.getInvoice( "inv-1047" );
				expect( paidInvoice.status ).toBe( "paid" );
				expect( paidInvoice.outstanding ).toBe( 0 );
			} );

			it( "rejects invalid invoice dates without creating data", function(){
				var beforeCount = variables.duePilot.listInvoices().len();
				var errorType = "";
				try {
					variables.duePilot.createInvoice(
						customerId = "cus-atlas",
						amount = 125000,
						issueDate = dateFormat( now(), "yyyy-mm-dd" ),
						dueDate = dateFormat( dateAdd( "d", -1, now() ), "yyyy-mm-dd" ),
						description = "Invalid date range"
					);
				} catch ( any error ) {
					errorType = error.type;
				}
				expect( errorType ).toBe( "DuePilot.InvalidDateRange" );
				expect( variables.duePilot.listInvoices().len() ).toBe( beforeCount );
			} );

			it( "rejects overpayments without changing the balance", function(){
				var beforeInvoice = variables.duePilot.getInvoice( "inv-1047" );
				var errorType = "";
				try {
					variables.duePilot.recordPayment( "inv-1047", beforeInvoice.outstanding + 1, "TOO-MUCH" );
				} catch ( any error ) {
					errorType = error.type;
				}
				expect( errorType ).toBe( "DuePilot.Overpayment" );
				expect( variables.duePilot.getInvoice( "inv-1047" ).outstanding ).toBe( beforeInvoice.outstanding );
			} );

			it( "validates and saves workspace settings", function(){
				var organization = variables.duePilot.updateOrganization(
					name = "Northstar Labs",
					currency = "INR",
					financeEmail = "billing@northstar.example",
					defaultTerms = 45
				);
				expect( organization.name ).toBe( "Northstar Labs" );
				expect( organization.initials ).toBe( "NL" );
				expect( organization.defaultTerms ).toBe( 45 );
			} );

			it( "builds a minimal AI context without customer secrets", function(){
				var context = variables.duePilot.getAssistantContext();
				expect( context.summary.outstanding ).toBeGT( 0 );
				expect( context.priorities ).notToBeEmpty();
				expect( structKeyExists( context.priorities[ 1 ], "portalToken" ) ).toBeFalse();
				expect( structKeyExists( context.priorities[ 1 ], "customerEmail" ) ).toBeFalse();
			} );

			it( "provides useful guided AI responses before a Groq key is added", function(){
				var status = variables.duePilotAi.getStatus();
				expect( status.enabled ).toBeTrue();
				expect( status.provider ).toInclude( "BoxLang AI" );
				if ( status.configured ) {
					expect( status.keyCount ).toBeGT( 0 );
				} else {
					expect( status.keyCount ).toBe( 0 );
				}
				if ( !status.configured ) {
					var result = variables.duePilotAi.chat( "Prioritize today's collections" );
					expect( result.ok ).toBeTrue();
					expect( result.mode ).toBe( "guided" );
					expect( result.answer ).toInclude( "recommended collection order" );
				}
			} );
		} );
	}

}
