<cfoutput>
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="description" content="DuePilot JWT engineering diagnostics">
	<meta name="theme-color" content="##0b1020">
	<script>(function(){try{var saved=localStorage.getItem("duepilot-theme");var theme=saved||(window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light");document.documentElement.setAttribute("data-theme",theme);}catch(error){document.documentElement.setAttribute("data-theme","light");}})();</script>
	<base href="#event.getHTMLBaseURL()#">
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Manrope:wght@500;600;700;800&display=swap" rel="stylesheet">
	<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css">
	<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
	<link rel="stylesheet" href="assets/css/duepilot.css">
	<link rel="stylesheet" href="assets/css/duepilot-modern.css">
	<link rel="stylesheet" href="assets/css/duepilot-v2.css">
	<title>#encodeForHTML( prc.pageTitle ?: "JWT diagnostics" )# · DuePilot Labs</title>
</head>
<body class="dev-body">
	<a class="skip-link" href="##main-content">Skip to diagnostics</a>
	<header class="dev-topbar">
		<div class="dev-topbar-inner">
			<a class="brand brand-dark" href="#event.buildLink( 'dashboard' )#" aria-label="DuePilot dashboard">
				<img class="brand-logo brand-logo-header" src="assets/brand/duepilot-logo.svg" alt="DuePilot"><small>Labs</small>
			</a>
			<div class="dev-topbar-actions">
				<span class="dev-environment"><i></i> Local diagnostics</span>
				<a class="button button-secondary button-sm" href="#event.buildLink( 'settings' )#"><i class="bi bi-arrow-left"></i> Back to workspace</a>
				<button class="icon-button theme-toggle" type="button" data-theme-toggle aria-label="Switch to dark mode" title="Switch theme"><i class="bi bi-moon-stars"></i></button>
			</div>
		</div>
	</header>
	<main class="dev-main" id="main-content">
		#view()#
	</main>
	<footer class="dev-footer"><span>DuePilot Labs</span><span>cf-token-manager · BoxLang · ColdBox</span></footer>
	<script src="assets/js/duepilot.js"></script>
</body>
</html>
</cfoutput>
