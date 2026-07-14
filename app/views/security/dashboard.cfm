<style>
	.tk-token { word-break: break-all; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .78rem; line-height: 1.5; }
	.tk-count { font-variant-numeric: tabular-nums; font-weight: 700; }
	.tk-log { max-height: 260px; overflow-y: auto; }
	.tk-log li { border-left: 3px solid #dee2e6; }
	.tk-hero { background: linear-gradient(135deg, #0d1b3e 0%, #17408b 60%, #2d6cdf 100%); color: #fff; border-radius: 1rem; }
</style>
<cfoutput>
<div class="py-4" style="max-width: 960px; margin: 0 auto;">

	<div class="tk-hero p-4 mb-4 shadow d-flex flex-wrap justify-content-between align-items-center gap-3">
		<div>
			<div class="small text-uppercase opacity-75 fw-semibold">cf-token-manager &bull; Live Session</div>
			<h3 class="mb-1">Welcome, #encodeForHTML( prc.username )#</h3>
			<div class="opacity-75 small">
				On login the app called <span class="font-monospace">issue()</span> and received your access + refresh tokens below.
			</div>
		</div>
		<a href="#event.buildLink( 'security.logout' )#" class="btn btn-light btn-sm">
			<i class="bi bi-box-arrow-right"></i> Logout
		</a>
	</div>

	<div class="alert alert-info d-flex align-items-center small">
		<i class="bi bi-info-circle me-2 fs-5"></i>
		<div>
			Developer policy: access token lives <strong>#prc.accessTTL# sec</strong>, refresh token lives <strong>#prc.refreshTTL# sec</strong>.
			When the access token expires the app auto-calls <span class="font-monospace">refresh()</span>.
			When the refresh token expires you are logged out automatically. Just watch &mdash; no clicks needed.
		</div>
	</div>

	<div class="row g-4">
		<!--- Access token --->
		<div class="col-12 col-lg-6">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-header bg-white d-flex justify-content-between align-items-center">
					<span class="fw-bold"><i class="bi bi-key text-primary"></i> Access Token</span>
					<span id="accessBadge" class="badge bg-success">active</span>
				</div>
				<div class="card-body">
					<div class="d-flex justify-content-between align-items-baseline mb-1">
						<span class="text-muted small">Expires in</span>
						<span id="accessCountdown" class="tk-count fs-4 text-primary">--:--</span>
					</div>
					<div class="progress mb-3" style="height: 8px;">
						<div id="accessBar" class="progress-bar bg-success" style="width:100%"></div>
					</div>
					<div class="text-muted small mb-1">Token</div>
					<div id="accessTokenBox" class="bg-light border rounded p-2 tk-token">#encodeForHTML( prc.tokens.accessToken )#</div>
				</div>
			</div>
		</div>

		<!--- Refresh token --->
		<div class="col-12 col-lg-6">
			<div class="card border-0 shadow-sm h-100">
				<div class="card-header bg-white d-flex justify-content-between align-items-center">
					<span class="fw-bold"><i class="bi bi-arrow-repeat text-primary"></i> Refresh Token</span>
					<span id="refreshBadge" class="badge bg-success">active</span>
				</div>
				<div class="card-body">
					<div class="d-flex justify-content-between align-items-baseline mb-1">
						<span class="text-muted small">Session ends in</span>
						<span id="refreshCountdown" class="tk-count fs-4 text-primary">--:--</span>
					</div>
					<div class="progress mb-3" style="height: 8px;">
						<div id="refreshBar" class="progress-bar bg-success" style="width:100%"></div>
					</div>
					<div class="text-muted small mb-1">Token</div>
					<div id="refreshTokenBox" class="bg-light border rounded p-2 tk-token">#encodeForHTML( prc.tokens.refreshToken )#</div>
				</div>
			</div>
		</div>
	</div>

	<!--- Activity log --->
	<div class="card border-0 shadow-sm mt-4">
		<div class="card-header bg-white fw-bold"><i class="bi bi-list-check text-primary"></i> Activity</div>
		<ul id="activity" class="list-group list-group-flush tk-log"></ul>
	</div>

	<p class="text-center text-muted small mt-3 mb-0">
		This lifecycle is powered entirely by your <span class="font-monospace">cf-token-manager</span> package
		&mdash; issue(), decode(), verify(), refresh().
	</p>

</div>

<script>
	window.__SESSION__ = {
		username    : "#jsStringFormat( prc.username )#",
		accessIn    : #prc.accessIn#,
		refreshIn   : #prc.refreshIn#,
		accessTTL   : #prc.accessTTL#,
		refreshTTL  : #prc.refreshTTL#,
		refreshUrl  : "#event.buildLink( 'security.refreshToken' )#",
		logoutUrl   : "#event.buildLink( 'security.logout' )#"
	};
</script>
</cfoutput>

<script>
(function () {
	var S          = window.__SESSION__;
	var accessIn   = S.accessIn;
	var refreshIn  = S.refreshIn;
	var refreshing = false;
	var stopped    = false;

	var $ = function (id) { return document.getElementById(id); };

	function stamp() {
		var d = new Date();
		var p = function (n) { return (n < 10 ? "0" : "") + n; };
		return p(d.getHours()) + ":" + p(d.getMinutes()) + ":" + p(d.getSeconds());
	}

	function log(msg, kind) {
		var colors = { success: "#198754", warning: "#fd7e14", danger: "#dc3545", info: "#0d6efd" };
		var li = document.createElement("li");
		li.className = "list-group-item py-2 small";
		li.style.borderLeftColor = colors[kind] || "#dee2e6";
		li.innerHTML = '<span class="text-muted me-2">' + stamp() + '</span>' + msg;
		var list = $("activity");
		list.insertBefore(li, list.firstChild);
	}

	function fmt(sec) {
		if (sec < 0) sec = 0;
		var m = Math.floor(sec / 60), s = sec % 60;
		return m + ":" + (s < 10 ? "0" : "") + s;
	}

	function setBar(id, remain, ttl) {
		var pct = Math.max(0, Math.min(100, (remain / ttl) * 100));
		var el = $(id);
		el.style.width = pct + "%";
		el.className = "progress-bar " + (remain <= 0 ? "bg-danger" : (remain <= ttl * 0.34 ? "bg-warning" : "bg-success"));
	}

	function setBadge(id, remain) {
		var el = $(id);
		if (remain <= 0)        { el.className = "badge bg-danger";  el.textContent = "expired"; }
		else if (remain <= 10)  { el.className = "badge bg-warning text-dark"; el.textContent = "expiring"; }
		else                    { el.className = "badge bg-success"; el.textContent = "active"; }
	}

	function render() {
		$("accessCountdown").textContent  = fmt(accessIn);
		$("refreshCountdown").textContent = fmt(refreshIn);
		setBar("accessBar", accessIn, S.accessTTL);
		setBar("refreshBar", refreshIn, S.refreshTTL);
		setBadge("accessBadge", accessIn);
		setBadge("refreshBadge", refreshIn);
	}

	function goLogout(reasonMsg) {
		stopped = true;
		log(reasonMsg, "danger");
		render();
		setTimeout(function () { window.location.href = S.logoutUrl; }, 1600);
	}

	function doRefresh() {
		refreshing = true;
		log("Access token expired &rarr; calling <b>refresh()</b> with the refresh token&hellip;", "warning");
		fetch(S.refreshUrl, { method: "POST", headers: { "X-Requested-With": "XMLHttpRequest" } })
			.then(function (r) { return r.json(); })
			.then(function (d) {
				refreshing = false;
				if (d.ok) {
					accessIn  = d.accessIn;
					refreshIn = d.refreshIn;
					$("accessTokenBox").textContent = d.accessToken;
					log("A brand-new access token was issued. You stay logged in.", "success");
					render();
				} else {
					goLogout("refresh() rejected the refresh token (" + d.reason + ") &rarr; logging you out.");
				}
			})
			.catch(function () {
				refreshing = false;
				log("Network error while refreshing.", "danger");
			});
	}

	log("Logged in as <b>" + S.username + "</b> &mdash; access &amp; refresh tokens issued via <b>issue()</b>.", "success");
	render();

	setInterval(function () {
		if (stopped) return;
		accessIn--;
		refreshIn--;

		if (refreshIn <= 0) {
			goLogout("Refresh token expired &rarr; session over, logging you out automatically.");
			return;
		}
		if (accessIn <= 0 && !refreshing) {
			doRefresh();
		}
		render();
	}, 1000);
})();
</script>
