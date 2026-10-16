<cfoutput>
<header class="marketing-header">
	<div class="marketing-container marketing-nav">
		<a class="brand brand-dark" href="#event.buildLink( '' )#" aria-label="DuePilot home"><img class="brand-logo brand-logo-header" src="assets/brand/duepilot-logo.svg" alt="DuePilot"></a>
		<nav class="marketing-links" id="marketing-navigation" data-marketing-nav>
			<a href="##product">Product</a>
			<a href="##workflow">How it works</a>
			<a href="##security">Security</a>
			<a href="##pricing">Pricing</a>
		</nav>
		<div class="marketing-actions">
			<a class="marketing-login" href="#event.buildLink( 'login' )#">Sign in</a>
			<button class="icon-button theme-toggle marketing-theme-toggle" type="button" data-theme-toggle aria-label="Switch to dark mode" title="Switch theme"><i class="bi bi-moon-stars"></i></button>
			<a class="button button-primary" href="#event.buildLink( 'login' )#">Open live demo <i class="bi bi-arrow-up-right"></i></a>
			<button class="marketing-menu" type="button" data-marketing-menu aria-label="Open menu" aria-controls="marketing-navigation" aria-expanded="false"><i class="bi bi-list"></i></button>
		</div>
	</div>
</header>

<main id="main-content">
	<section class="marketing-hero">
		<div class="hero-orb hero-orb-one"></div><div class="hero-orb hero-orb-two"></div>
		<div class="marketing-container hero-grid">
			<div class="hero-copy">
				<div class="hero-badge"><span><i class="bi bi-stars"></i></span> The calm way to collect receivables <i class="bi bi-arrow-right"></i></div>
				<h1>Get every invoice paid.<br><span>Without the endless chasing.</span></h1>
				<p>DuePilot gives growing service businesses one intelligent workspace to prioritize collections, automate follow-ups and predict incoming cash.</p>
				<div class="hero-actions">
					<a class="button button-primary marketing-button" href="#event.buildLink( 'login' )#">Explore the product <i class="bi bi-arrow-right"></i></a>
					<a class="button button-secondary marketing-button" href="##product"><i class="bi bi-play-circle"></i> See how it works</a>
				</div>
				<div class="hero-proof"><span><i class="bi bi-check-circle-fill"></i> No card required</span><span><i class="bi bi-check-circle-fill"></i> Ready in 5 minutes</span><span><i class="bi bi-check-circle-fill"></i> Secure by design</span></div>
			</div>

			<div class="hero-product" aria-label="DuePilot product preview">
				<div class="hero-window-glow"></div>
				<div class="product-window">
					<div class="product-window-top"><div class="window-dots"><i></i><i></i><i></i></div><div class="window-url"><i class="bi bi-lock-fill"></i> app.duepilot.com/dashboard</div><span></span></div>
					<div class="product-shell-mini">
						<aside class="product-sidebar-mini">
							<div class="mini-brand"><img src="assets/brand/duepilot-logo.svg" alt="DuePilot"></div>
							<div class="mini-workspace"><span>ND</span><i></i><i></i></div>
							<cfloop array="#['grid-1x2','receipt','buildings','inboxes','bar-chart-line','sliders']#" item="icon" index="iconIndex"><div class="mini-nav-row#iconIndex == 1 ? ' active' : ''#"><i class="bi bi-#icon#"></i><span></span></div></cfloop>
						</aside>
						<div class="product-main-mini">
							<div class="mini-topbar"><span></span><div><i></i><i></i></div></div>
							<div class="mini-content">
								<div class="mini-heading"><div><small>MONDAY, 14 OCTOBER</small><strong>Good morning, Alex</strong><span>Here is what needs your attention today.</span></div><button>+ New invoice</button></div>
								<div class="mini-metrics"><cfloop array="#['Outstanding','Overdue','Due next 7 days','Collection rate']#" item="label" index="metricIndex"><div><small>#label#</small><strong>#metricIndex == 1 ? 'INR 9.18L' : ( metricIndex == 2 ? 'INR 6.66L' : ( metricIndex == 3 ? 'INR 2.40L' : '81%' ) )#</strong><span>#metricIndex == 4 ? '↑ 4.6%' : 'View details'#</span></div></cfloop></div>
								<div class="mini-panels"><div class="mini-table-panel"><header><strong>Priority collections</strong><span>View queue →</span></header><cfloop from="1" to="4" index="row"><div class="mini-table-row"><i>#row#</i><span></span><b></b><em>#row LTE 2 ? 'Overdue' : 'Due soon'#</em><strong>#row == 1 ? 'INR 1.85L' : ( row == 2 ? 'INR 1.32L' : 'INR 84K' )#</strong></div></cfloop></div><div class="mini-aging-panel"><header><strong>Aging</strong><span>Open</span></header><div class="aging-ring"><div><strong>9.18L</strong><small>Total</small></div></div><div class="aging-legend-mini"><span><i></i>Current</span><span><i></i>1–30 days</span><span><i></i>31+ days</span></div></div></div>
							</div>
						</div>
					</div>
				</div>
				<div class="floating-payment"><span class="floating-icon"><i class="bi bi-check2"></i></span><span><small>Payment received</small><strong>INR 98,000 from BluePeak</strong></span><i class="bi bi-arrow-up-right"></i></div>
			</div>
		</div>
	</section>

	<section class="logo-strip">
		<div class="marketing-container"><p>Built for modern finance teams at growing businesses</p><div class="company-logos"><span><i class="bi bi-hexagon-fill"></i> NORTHSTAR</span><span><i class="bi bi-diamond-fill"></i> VERTEX</span><span><i class="bi bi-triangle-fill"></i> ATLAS</span><span><i class="bi bi-circle-fill"></i> MOSAIC</span><span><i class="bi bi-command"></i> KAVERI</span></div></div>
	</section>

	<section class="marketing-section problem-section" id="product">
		<div class="marketing-container">
			<div class="section-heading centered"><span class="section-kicker">One source of truth</span><h2>Collections should not live in spreadsheets and memory.</h2><p>Bring every invoice, customer conversation and next action into a workflow your whole finance team can trust.</p></div>
			<div class="feature-bento">
				<article class="bento-card bento-wide"><div class="bento-copy"><span class="feature-icon feature-violet"><i class="bi bi-stars"></i></span><h3>Know exactly who to follow up with</h3><p>DuePilot ranks unpaid invoices by age, risk, value and customer behaviour—turning a noisy ledger into a clear daily queue.</p><a href="#event.buildLink( 'login' )#">Explore collection queue <i class="bi bi-arrow-right"></i></a></div><div class="priority-preview"><div class="priority-preview-head"><strong>Today’s priorities</strong><span>6 accounts</span></div><cfloop array="#['Atlas Manufacturing','Brightline Media','Kaveri Systems']#" item="company" index="companyIndex"><div class="priority-preview-row"><span class="priority #companyIndex LTE 2 ? 'priority-high' : 'priority-medium'#">#companyIndex#</span><div><strong>#company#</strong><small>INV-2026-10#49-companyIndex#</small></div><em>#companyIndex == 1 ? '18 days overdue' : ( companyIndex == 2 ? '11 days overdue' : 'Promised' )#</em><b>#companyIndex == 1 ? 'INR 1.85L' : ( companyIndex == 2 ? 'INR 45K' : 'INR 2.48L' )#</b></div></cfloop></div></article>
				<article class="bento-card"><span class="feature-icon feature-green"><i class="bi bi-send-check"></i></span><h3>Follow up at the right moment</h3><p>Coordinate email, WhatsApp and SMS reminders without losing the human context.</p><div class="message-preview"><span>Hi Priya, a quick reminder that invoice INV-1048 is now due.</span><i class="bi bi-check2-all"></i></div></article>
				<article class="bento-card"><span class="feature-icon feature-blue"><i class="bi bi-calendar2-check"></i></span><h3>Turn promises into forecasts</h3><p>Capture customer commitments and see expected cash by week with confidence levels.</p><div class="forecast-preview"><div><span>This week</span><strong>INR 1.64L</strong></div><div class="forecast-bars"><i style="width:82%"></i><i style="width:68%"></i><i style="width:54%"></i></div></div></article>
				<article class="bento-card bento-dark"><div><span class="feature-icon feature-dark"><i class="bi bi-link-45deg"></i></span><h3>A customer portal that resolves, not just reminds.</h3><p>Customers can pay, promise a date or raise a dispute from one secure link.</p></div><div class="portal-phone"><div class="phone-top"><img src="assets/brand/duepilot-mark.svg" alt=""><strong>Invoice INV-1048</strong></div><small>AMOUNT DUE</small><b>INR 1,85,000</b><button>Pay securely</button><div><span>Promise a date</span><span>Raise a query</span></div></div></article>
			</div>
		</div>
	</section>

	<section class="marketing-section workflow-section" id="workflow">
		<div class="marketing-container workflow-grid">
			<div class="section-heading"><span class="section-kicker">From invoice to income</span><h2>A repeatable collection process in four simple moves.</h2><p>DuePilot gives your team structure without making customer relationships feel robotic.</p><a class="button button-primary marketing-button" href="#event.buildLink( 'login' )#">Try the complete workflow <i class="bi bi-arrow-right"></i></a></div>
			<div class="workflow-list">
				<cfloop array="#[{n:'01',icon:'receipt',title:'Bring in every invoice',text:'Create invoices or connect your accounting system so the ledger stays current.'},{n:'02',icon:'magic',title:'Prioritize the right accounts',text:'Focus each day on the receivables with the greatest cash-flow impact.'},{n:'03',icon:'chat-square-text',title:'Keep every conversation',text:'Record reminders, promises, disputes and notes against the invoice.'},{n:'04',icon:'graph-up-arrow',title:'Forecast what will land',text:'Turn due dates and customer commitments into an honest cash view.'}]#" item="step"><article class="workflow-step"><span class="workflow-number">#step.n#</span><span class="workflow-icon"><i class="bi bi-#step.icon#"></i></span><div><h3>#step.title#</h3><p>#step.text#</p></div></article></cfloop>
			</div>
		</div>
	</section>

	<section class="marketing-section trust-section" id="security">
		<div class="marketing-container trust-card">
			<div class="trust-copy"><span class="section-kicker light">Built for responsible finance teams</span><h2>Your receivables data deserves enterprise-grade foundations.</h2><p>DuePilot separates public and private application code, protects mutations with CSRF tokens, and uses short-lived JWT access credentials with secure refresh sessions.</p><div class="trust-points"><span><i class="bi bi-shield-check"></i> Role-ready architecture</span><span><i class="bi bi-key"></i> JWT session security</span><span><i class="bi bi-journal-check"></i> Activity audit model</span><span><i class="bi bi-database-check"></i> Multi-tenant schema</span></div></div>
			<div class="security-visual"><div class="security-rings"><span><i class="bi bi-shield-lock-fill"></i></span></div><div class="security-chip chip-one"><i class="bi bi-check-circle-fill"></i><span><small>Session</small><strong>Protected</strong></span></div><div class="security-chip chip-two"><i class="bi bi-lock-fill"></i><span><small>Portal</small><strong>Token secured</strong></span></div></div>
		</div>
	</section>

	<section class="marketing-section pricing-section" id="pricing">
		<div class="marketing-container">
			<div class="section-heading centered"><span class="section-kicker">Simple starting point</span><h2>Start with the workflow. Scale when it pays for itself.</h2><p>Explore the complete version 1 product with realistic data before connecting your live systems.</p></div>
			<div class="pricing-card"><div><span class="pricing-label">PRODUCT PREVIEW</span><h3>DuePilot Growth</h3><p>For small finance teams that want a repeatable receivables process.</p></div><div class="pricing-price"><strong>Free</strong><span>during product preview</span></div><ul><li><i class="bi bi-check2"></i> Receivables dashboard</li><li><i class="bi bi-check2"></i> Collection priority queue</li><li><i class="bi bi-check2"></i> Payment promises and disputes</li><li><i class="bi bi-check2"></i> Secure customer portal</li><li><i class="bi bi-check2"></i> Aging and cash reports</li><li><i class="bi bi-check2"></i> MySQL-ready data model</li></ul><a class="button button-primary marketing-button button-block" href="#event.buildLink( 'login' )#">Open the live workspace <i class="bi bi-arrow-right"></i></a><small>No card required · Demo data included</small></div>
		</div>
	</section>

	<section class="final-cta"><div class="final-orb"></div><div class="marketing-container"><span class="section-kicker light">Receivables, under control</span><h2>Stop wondering what will get paid.</h2><p>Open DuePilot and experience the complete collection workflow with realistic demo data.</p><div><a class="button marketing-button cta-white" href="#event.buildLink( 'login' )#">Explore DuePilot <i class="bi bi-arrow-right"></i></a><a class="cta-link" href="mailto:hello@duepilot.app">Talk to us</a></div></div></section>
</main>

<footer class="marketing-footer"><div class="marketing-container footer-grid"><div><a class="brand brand-dark" href="#event.buildLink( '' )#" aria-label="DuePilot home"><img class="brand-logo brand-logo-footer" src="assets/brand/duepilot-logo.svg" alt="DuePilot"></a><p>The receivables command center for modern service businesses.</p></div><div class="footer-links"><div><strong>Product</strong><a href="##product">Features</a><a href="##workflow">Workflow</a><a href="##pricing">Pricing</a></div><div><strong>Company</strong><a href="mailto:hello@duepilot.app">Contact</a><a href="#event.buildLink( 'login' )#">Live demo</a><a href="#event.buildLink( 'healthcheck' )#">Service status</a></div><div><strong>Legal</strong><a href="##">Privacy</a><a href="##">Terms</a><a href="##security">Security</a></div></div></div><div class="marketing-container footer-bottom"><span>© #year( now() )# DuePilot. Built for better cash flow.</span><span>Made with care for finance teams.</span></div></footer>
</cfoutput>
