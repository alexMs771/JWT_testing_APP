<cfoutput>
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="description" content="Secure invoice portal powered by DuePilot">
	<meta name="theme-color" content="##ffffff">
	<script>(function(){try{var saved=localStorage.getItem("duepilot-theme");var theme=saved||(window.matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light");document.documentElement.setAttribute("data-theme",theme);}catch(error){document.documentElement.setAttribute("data-theme","light");}})();</script>
	<base href="#event.getHTMLBaseURL()#">
	<link rel="preconnect" href="https://fonts.googleapis.com">
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
	<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500;600&family=Inter:wght@400;500;600;700&family=Manrope:wght@500;600;700;800&display=swap" rel="stylesheet">
	<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
	<link rel="stylesheet" href="assets/css/duepilot.css">
	<link rel="stylesheet" href="assets/css/duepilot-modern.css">
	<link rel="stylesheet" href="assets/css/duepilot-v2.css">
	<title>#encodeForHTML( prc.pageTitle ?: "Invoice portal" )# · DuePilot</title>
</head>
<body class="portal-body">
	<a class="skip-link" href="##main-content">Skip to invoice</a>
	<header class="portal-header">
		<a class="brand brand-dark" href="##" aria-label="DuePilot"><img class="brand-logo brand-logo-header" src="assets/brand/duepilot-logo.svg" alt="DuePilot"></a>
		<div class="portal-header-actions"><span><i class="bi bi-shield-check"></i> Secure payment portal</span><button class="icon-button theme-toggle" type="button" data-theme-toggle aria-label="Switch to dark mode" title="Switch theme"><i class="bi bi-moon-stars"></i></button></div>
	</header>
	<main class="portal-wrap" id="main-content">
		<cfif structKeyExists( rc, "notice" ) AND len( rc.notice )><div class="flash flash-success"><i class="bi bi-check-circle-fill"></i><span>#encodeForHTML( rc.notice )#</span></div></cfif>
		<cfif structKeyExists( rc, "error" ) AND len( rc.error )><div class="flash flash-error"><i class="bi bi-exclamation-circle-fill"></i><span>#encodeForHTML( rc.error )#</span></div></cfif>
		#view()#
	</main>
	<footer class="portal-footer"><i class="bi bi-lock-fill"></i> Secured by DuePilot · Your payment data is protected</footer>
	<script src="assets/js/duepilot.js"></script>
</body>
</html>
</cfoutput>
