<cfoutput>
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="description" content="DuePilot accounts receivable command center">
	<meta name="theme-color" content="##11182a">
	<script>(function(){try{var saved=localStorage.getItem("duepilot-theme");var theme=saved||(window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light");document.documentElement.setAttribute("data-theme",theme);}catch(error){document.documentElement.setAttribute("data-theme","light");}})();</script>
	<base href="#event.getHTMLBaseURL()#">
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Manrope:wght@500;600;700;800&display=swap" rel="stylesheet">
	<link rel="preconnect" href="https://cdn.jsdelivr.net">
	<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
	<link rel="stylesheet" href="assets/css/duepilot.css">
	<link rel="stylesheet" href="assets/css/duepilot-modern.css">
	<link rel="stylesheet" href="assets/css/duepilot-v2.css">
	<title>#encodeForHTML( prc.pageTitle ?: "Workspace" )# · DuePilot</title>
</head>
<body class="app-body">
	<a class="skip-link" href="##main-content">Skip to main content</a>
	<div class="app-shell">
		<aside class="sidebar" id="app-sidebar" aria-label="Primary navigation">
			<div class="brand-row">
				<a class="brand" href="#event.buildLink( 'dashboard' )#" aria-label="DuePilot dashboard">
					<img class="brand-logo brand-logo-sidebar" src="assets/brand/duepilot-logo.svg" alt="DuePilot">
				</a>
				<button class="icon-button sidebar-close" type="button" data-sidebar-close aria-label="Close navigation"><i class="bi bi-x-lg"></i></button>
			</div>

			<div class="workspace-switcher">
				<span class="workspace-logo">#encodeForHTML( prc.organization.initials )#</span>
				<span class="workspace-copy">
					<strong>#encodeForHTML( prc.organization.name )#</strong>
					<small>#encodeForHTML( prc.organization.plan )#</small>
				</span>
				<i class="bi bi-chevron-expand"></i>
			</div>

			<nav class="side-nav">
				<p class="nav-label">Workspace</p>
				<a class="nav-link#prc.activeNav == 'dashboard' ? ' active' : ''#" href="#event.buildLink( 'dashboard' )#"><i class="bi bi-grid-1x2"></i><span>Dashboard</span></a>
				<a class="nav-link#prc.activeNav == 'invoices' ? ' active' : ''#" href="#event.buildLink( 'invoices' )#"><i class="bi bi-receipt"></i><span>Invoices</span></a>
				<a class="nav-link#prc.activeNav == 'customers' ? ' active' : ''#" href="#event.buildLink( 'customers' )#"><i class="bi bi-buildings"></i><span>Customers</span></a>
				<a class="nav-link#prc.activeNav == 'collections' ? ' active' : ''#" href="#event.buildLink( 'collections' )#"><i class="bi bi-inboxes"></i><span>Collections</span><span class="nav-count">#prc.openInvoiceCount#</span></a>

				<p class="nav-label">Insights</p>
				<a class="nav-link#prc.activeNav == 'reports' ? ' active' : ''#" href="#event.buildLink( 'reports' )#"><i class="bi bi-bar-chart-line"></i><span>Reports</span></a>
				<a class="nav-link#prc.activeNav == 'settings' ? ' active' : ''#" href="#event.buildLink( 'settings' )#"><i class="bi bi-sliders"></i><span>Settings</span></a>
			</nav>

			<div class="sidebar-bottom">
				<div class="trial-card">
					<div class="trial-icon"><i class="bi bi-stars"></i></div>
					<strong>Growth trial</strong>
					<p>12 days left in your trial</p>
					<div class="trial-progress"><span style="width:60%"></span></div>
					<a href="#event.buildLink( 'settings' )#">View plan <i class="bi bi-arrow-right"></i></a>
				</div>
				<div class="user-card">
					<span class="avatar">#encodeForHTML( prc.user.initials )#</span>
					<span><strong>#encodeForHTML( prc.user.name )#</strong><small>#encodeForHTML( prc.user.role )#</small></span>
					<form method="post" action="#event.buildLink( 'logout' )#">
						<input type="hidden" name="csrfToken" value="#encodeForHTMLAttribute( prc.csrfToken )#">
						<button class="icon-button" type="submit" aria-label="Sign out" title="Sign out"><i class="bi bi-box-arrow-right"></i></button>
					</form>
				</div>
			</div>
		</aside>

		<div class="sidebar-backdrop" data-sidebar-close></div>
		<section class="app-main">
			<header class="topbar">
				<div class="topbar-left">
					<button class="icon-button mobile-menu" type="button" data-sidebar-open aria-label="Open navigation" aria-controls="app-sidebar" aria-expanded="false"><i class="bi bi-list"></i></button>
					<form class="global-search" method="get" action="#event.buildLink( 'invoices' )#" role="search">
						<i class="bi bi-search"></i>
						<input type="search" name="search" maxlength="100" placeholder="Search invoices or customers..." aria-label="Search invoices or customers" data-global-search>
						<kbd data-search-shortcut>Ctrl K</kbd>
					</form>
				</div>
				<div class="topbar-actions">
					<span class="sync-state"><span></span> Demo workspace</span>
					<button class="button ai-launch-button" type="button" data-ai-open aria-controls="duepilot-ai-drawer" aria-expanded="false"><i class="bi bi-stars"></i><span>Ask DuePilot</span></button>
					<button class="icon-button theme-toggle" type="button" data-theme-toggle aria-label="Switch to dark mode" title="Switch theme"><i class="bi bi-moon-stars"></i></button>
					<a class="icon-button notification-button" href="#event.buildLink( 'collections' )#" aria-label="Collection notifications"><i class="bi bi-bell"></i><span class="notification-dot"></span></a>
					<a class="button button-primary button-sm" href="#event.buildLink( 'invoices/new' )#"><i class="bi bi-plus-lg"></i> New invoice</a>
				</div>
			</header>

			<main class="page-wrap" id="main-content">
				<cfif structKeyExists( rc, "notice" ) AND len( rc.notice )>
					<div class="flash flash-success" role="status"><i class="bi bi-check-circle-fill"></i><span>#encodeForHTML( rc.notice )#</span><button type="button" data-dismiss-flash aria-label="Dismiss"><i class="bi bi-x"></i></button></div>
				</cfif>
				<cfif structKeyExists( rc, "error" ) AND len( rc.error )>
					<div class="flash flash-error" role="alert"><i class="bi bi-exclamation-circle-fill"></i><span>#encodeForHTML( rc.error )#</span><button type="button" data-dismiss-flash aria-label="Dismiss"><i class="bi bi-x"></i></button></div>
				</cfif>
				#view()#
			</main>
		</section>
	</div>

	<div class="ai-drawer-backdrop" data-ai-close></div>
	<aside
		class="ai-drawer"
		id="duepilot-ai-drawer"
		aria-label="DuePilot AI assistant"
		aria-hidden="true"
		data-ai-assistant
		data-chat-url="#encodeForHTMLAttribute( event.buildLink( 'api/assistant/chat' ) )#"
		data-status-url="#encodeForHTMLAttribute( event.buildLink( 'api/assistant/status' ) )#"
		data-csrf-token="#encodeForHTMLAttribute( prc.csrfToken )#"
		data-page="#encodeForHTMLAttribute( prc.pageTitle ?: 'Workspace' )#"
	>
		<header class="ai-drawer-header">
			<div class="ai-title-group">
				<span class="ai-orb"><i class="bi bi-stars"></i></span>
				<div><h2>DuePilot AI</h2><p>Your receivables copilot</p></div>
			</div>
			<div class="ai-header-actions">
				<button class="icon-button" type="button" data-ai-clear aria-label="Start a new conversation" title="New conversation"><i class="bi bi-arrow-clockwise"></i></button>
				<button class="icon-button" type="button" data-ai-close aria-label="Close assistant"><i class="bi bi-x-lg"></i></button>
			</div>
		</header>

		<div class="ai-status-bar">
			<span class="ai-status-pill" data-ai-status><i></i> Checking assistant</span>
			<span data-ai-model>Secure server connection</span>
		</div>

		<div class="ai-conversation" data-ai-messages aria-live="polite" aria-relevant="additions">
			<div class="ai-message ai-message-assistant">
				<span class="ai-message-avatar"><i class="bi bi-stars"></i></span>
				<div class="ai-message-content">
					<p>Hi #encodeForHTML( listFirst( prc.user.name, ' ' ) )#. I can explain your receivables, rank today’s follow-ups, and draft customer-friendly reminders using the current DuePilot workspace.</p>
					<small>DuePilot AI · Uses workspace data</small>
				</div>
			</div>

			<div class="ai-starter" data-ai-starter>
				<p>Try one of these</p>
				<div class="ai-quick-grid">
					<button type="button" data-ai-prompt="Prioritize today's collections and explain why."><i class="bi bi-lightning-charge"></i><span><strong>Prioritize today</strong><small>Rank the next follow-ups</small></span></button>
					<button type="button" data-ai-prompt="Summarize the overdue receivables in this workspace."><i class="bi bi-pie-chart"></i><span><strong>Overdue summary</strong><small>Understand current exposure</small></span></button>
					<button type="button" data-ai-prompt="Draft a friendly reminder for the highest-priority invoice."><i class="bi bi-chat-square-text"></i><span><strong>Draft reminder</strong><small>Start with a useful message</small></span></button>
					<button type="button" data-ai-prompt="Explain the aging buckets and what I should do next."><i class="bi bi-hourglass-split"></i><span><strong>Explain aging</strong><small>Learn the collection signals</small></span></button>
				</div>
			</div>
		</div>

		<div class="ai-composer-wrap">
			<form class="ai-composer" data-ai-form novalidate>
				<label class="sr-only" for="duepilot-ai-input">Ask DuePilot AI</label>
				<textarea id="duepilot-ai-input" data-ai-input rows="1" maxlength="2000" placeholder="Ask about invoices, collections, or cash flow…" autocomplete="off" required></textarea>
				<div class="ai-composer-actions">
					<span><b data-ai-count>0</b>/2000</span>
					<button type="submit" data-ai-send aria-label="Send message"><i class="bi bi-arrow-up"></i></button>
				</div>
			</form>
			<p class="ai-validation" data-ai-validation role="alert" hidden></p>
			<p class="ai-disclaimer"><i class="bi bi-shield-check"></i> Read-only guidance. Review suggestions before acting.</p>
		</div>
	</aside>
	<script src="assets/js/duepilot.js"></script>
</body>
</html>
</cfoutput>
