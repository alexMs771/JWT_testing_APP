<cfoutput>
<!doctype html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta name="description" content="DuePilot helps service businesses collect invoices faster with one intelligent receivables workspace.">
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
	<title>#encodeForHTML( prc.pageTitle ?: "DuePilot" )# · DuePilot</title>
</head>
<body class="marketing-body">
	<a class="skip-link" href="##main-content">Skip to main content</a>
	#view()#
	<script src="assets/js/duepilot.js"></script>
</body>
</html>
</cfoutput>
