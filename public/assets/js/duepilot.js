(function () {
	"use strict";

	var body = document.body;
	var root = document.documentElement;

	function getSavedTheme() {
		try { return localStorage.getItem("duepilot-theme"); } catch (error) { return null; }
	}

	function setTheme(theme, persist) {
		var safeTheme = theme === "dark" ? "dark" : "light";
		root.setAttribute("data-theme", safeTheme);
		if (persist) {
			try { localStorage.setItem("duepilot-theme", safeTheme); } catch (error) { /* Storage can be blocked. */ }
		}
		document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
			var isDark = safeTheme === "dark";
			button.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode");
			button.setAttribute("title", isDark ? "Switch to light mode" : "Switch to dark mode");
			var icon = button.querySelector("i");
			if (icon) icon.className = isDark ? "bi bi-sun" : "bi bi-moon-stars";
		});
		var themeMeta = document.querySelector('meta[name="theme-color"]');
		if (themeMeta) themeMeta.setAttribute("content", safeTheme === "dark" ? "#0c1220" : "#ffffff");
	}

	setTheme(root.getAttribute("data-theme") || "light", false);
	document.querySelectorAll("[data-theme-toggle]").forEach(function (button) {
		button.addEventListener("click", function () {
			setTheme(root.getAttribute("data-theme") === "dark" ? "light" : "dark", true);
		});
	});

	var colorPreference = window.matchMedia ? window.matchMedia("(prefers-color-scheme: dark)") : null;
	if (colorPreference && colorPreference.addEventListener) {
		colorPreference.addEventListener("change", function (event) {
			if (!getSavedTheme()) setTheme(event.matches ? "dark" : "light", false);
		});
	}

	var marketingMenu = document.querySelector("[data-marketing-menu]");
	var marketingNav = document.querySelector("[data-marketing-nav]");
	if (marketingMenu && marketingNav) {
		marketingMenu.addEventListener("click", function () {
			var isOpen = marketingNav.classList.toggle("open");
			marketingMenu.setAttribute("aria-expanded", String(isOpen));
			marketingMenu.setAttribute("aria-label", isOpen ? "Close menu" : "Open menu");
		});
		marketingNav.querySelectorAll("a").forEach(function (link) {
			link.addEventListener("click", function () {
				marketingNav.classList.remove("open");
				marketingMenu.setAttribute("aria-expanded", "false");
				marketingMenu.setAttribute("aria-label", "Open menu");
			});
		});
	}

	document.querySelectorAll("[data-sidebar-open]").forEach(function (button) {
		button.addEventListener("click", function () {
			body.classList.add("sidebar-open");
			button.setAttribute("aria-expanded", "true");
			var close = document.querySelector("[data-sidebar-close]");
			if (close) close.focus();
		});
	});
	document.querySelectorAll("[data-sidebar-close]").forEach(function (button) {
		button.addEventListener("click", function () {
			body.classList.remove("sidebar-open");
			var opener = document.querySelector("[data-sidebar-open]");
			if (opener) opener.setAttribute("aria-expanded", "false");
		});
	});
	document.addEventListener("keydown", function (event) {
		if (event.key === "Escape" && body.classList.contains("sidebar-open")) {
			body.classList.remove("sidebar-open");
			var opener = document.querySelector("[data-sidebar-open]");
			if (opener) {
				opener.setAttribute("aria-expanded", "false");
				opener.focus();
			}
		}
	});

	document.querySelectorAll("[data-dismiss-flash]").forEach(function (button) {
		button.addEventListener("click", function () { button.closest(".flash").remove(); });
	});

	document.querySelectorAll("[data-confirm]").forEach(function (form) {
		form.addEventListener("submit", function (event) {
			if (!window.confirm(form.getAttribute("data-confirm"))) event.preventDefault();
		});
	});

	document.querySelectorAll("[data-copy]").forEach(function (button) {
		button.addEventListener("click", function () {
			var value = button.getAttribute("data-copy");
			if (!navigator.clipboard) return;
			navigator.clipboard.writeText(value).then(function () {
				var original = button.innerHTML;
				button.innerHTML = '<i class="bi bi-check2"></i> Copied';
				setTimeout(function () { button.innerHTML = original; }, 1800);
			});
		});
	});

	document.querySelectorAll("[data-toggle-password]").forEach(function (button) {
		button.addEventListener("click", function () {
			var input = document.getElementById(button.getAttribute("data-toggle-password"));
			if (!input) return;
			input.type = input.type === "password" ? "text" : "password";
			button.setAttribute("aria-label", input.type === "password" ? "Show password" : "Hide password");
			button.querySelector("i").className = input.type === "password" ? "bi bi-eye" : "bi bi-eye-slash";
		});
	});

	var demoFill = document.querySelector("[data-demo-fill]");
	if (demoFill) {
		demoFill.addEventListener("click", function () {
			document.getElementById("username").value = "alex@duepilot.app";
			document.getElementById("password").value = "demo123";
		});
	}

	var globalSearch = document.querySelector("[data-global-search]");
	if (globalSearch) {
		var searchShortcut = document.querySelector("[data-search-shortcut]");
		if (searchShortcut && /Mac|iPhone|iPad/.test(navigator.platform || "")) searchShortcut.textContent = "⌘ K";
		globalSearch.form.addEventListener("submit", function (event) {
			if (!globalSearch.value.trim()) {
				event.preventDefault();
				globalSearch.focus();
			}
		});
		document.addEventListener("keydown", function (event) {
			var target = event.target;
			var typing = target && /^(INPUT|TEXTAREA|SELECT)$/.test(target.tagName);
			if (((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") || (!typing && event.key === "/")) {
				event.preventDefault();
				globalSearch.focus();
				globalSearch.select();
			}
		});
	}

	document.querySelectorAll("form[data-validated-form]").forEach(function (form) {
		form.addEventListener("invalid", function () { form.classList.add("was-validated"); }, true);
		form.addEventListener("submit", function () {
			form.classList.add("was-validated");
			if (!form.checkValidity()) return;
			var submit = form.querySelector('button[type="submit"]');
			if (submit) {
				submit.disabled = true;
				submit.setAttribute("aria-busy", "true");
			}
		});
	});

	document.querySelectorAll("[data-invoice-form]").forEach(function (form) {
		var issueDate = form.querySelector('[name="issueDate"]');
		var dueDate = form.querySelector('[name="dueDate"]');
		if (!issueDate || !dueDate) return;
		function validateDateRange() {
			dueDate.min = issueDate.value || "";
			dueDate.setCustomValidity(issueDate.value && dueDate.value && dueDate.value < issueDate.value ? "Due date cannot be before the issue date." : "");
		}
		issueDate.addEventListener("change", validateDateRange);
		dueDate.addEventListener("change", validateDateRange);
		validateDateRange();
	});

	document.querySelectorAll("[data-dialog-open]").forEach(function (button) {
		button.addEventListener("click", function () {
			var dialog = document.getElementById(button.getAttribute("data-dialog-open"));
			if (dialog && dialog.showModal) dialog.showModal();
		});
	});
	document.querySelectorAll("[data-dialog-close]").forEach(function (button) {
		button.addEventListener("click", function () {
			var dialog = button.closest("dialog");
			if (dialog) dialog.close();
		});
	});

	document.querySelectorAll("[data-export-table]").forEach(function (button) {
		button.addEventListener("click", function () {
			var table = document.querySelector(button.getAttribute("data-export-table"));
			if (!table) return;
			var rows = Array.prototype.slice.call(table.querySelectorAll("tr"));
			var csv = rows.map(function (row) {
				return Array.prototype.slice.call(row.querySelectorAll("th, td")).map(function (cell) {
					var value = (cell.innerText || cell.textContent || "").replace(/\s+/g, " ").trim();
					return '"' + value.replace(/"/g, '""') + '"';
				}).join(",");
			}).join("\r\n");
			var url = URL.createObjectURL(new Blob(["\ufeff" + csv], { type: "text/csv;charset=utf-8" }));
			var link = document.createElement("a");
			link.href = url;
			link.download = button.getAttribute("data-export-file") || "duepilot-export.csv";
			document.body.appendChild(link);
			link.click();
			link.remove();
			URL.revokeObjectURL(url);
		});
	});

	var assistant = document.querySelector("[data-ai-assistant]");
	if (!assistant) return;

	var aiForm = assistant.querySelector("[data-ai-form]");
	var aiInput = assistant.querySelector("[data-ai-input]");
	var aiSend = assistant.querySelector("[data-ai-send]");
	var aiMessages = assistant.querySelector("[data-ai-messages]");
	var aiStarter = assistant.querySelector("[data-ai-starter]");
	var aiCount = assistant.querySelector("[data-ai-count]");
	var aiStatus = assistant.querySelector("[data-ai-status]");
	var aiModel = assistant.querySelector("[data-ai-model]");
	var aiValidation = assistant.querySelector("[data-ai-validation]");
	var history = [];
	var busy = false;
	var statusLoaded = false;
	var assistantEnabled = true;
	var statusKeyCount = 0;
	var lastFocused = null;

	function jsonValue(object, key) {
		if (!object) return undefined;
		return object[key] !== undefined ? object[key] : object[key.toUpperCase()];
	}

	function openAssistant() {
		lastFocused = document.activeElement;
		body.classList.add("ai-drawer-open");
		assistant.setAttribute("aria-hidden", "false");
		document.querySelectorAll("[data-ai-open]").forEach(function (button) { button.setAttribute("aria-expanded", "true"); });
		if (!statusLoaded) loadStatus();
		setTimeout(function () { aiInput.focus(); }, 180);
	}

	function closeAssistant() {
		body.classList.remove("ai-drawer-open");
		assistant.setAttribute("aria-hidden", "true");
		document.querySelectorAll("[data-ai-open]").forEach(function (button) { button.setAttribute("aria-expanded", "false"); });
		if (lastFocused && lastFocused.focus) lastFocused.focus();
	}

	document.querySelectorAll("[data-ai-open]").forEach(function (button) { button.addEventListener("click", openAssistant); });
	document.querySelectorAll("[data-ai-close]").forEach(function (button) { button.addEventListener("click", closeAssistant); });
	document.addEventListener("keydown", function (event) {
		if (event.key === "Escape" && body.classList.contains("ai-drawer-open")) closeAssistant();
		if (event.key === "Tab" && body.classList.contains("ai-drawer-open")) trapAssistantFocus(event);
	});

	function trapAssistantFocus(event) {
		var focusable = Array.prototype.slice.call(assistant.querySelectorAll('button:not([disabled]), textarea:not([disabled]), a[href], input:not([disabled])'));
		if (!focusable.length) return;
		var first = focusable[0];
		var last = focusable[focusable.length - 1];
		if (event.shiftKey && document.activeElement === first) {
			event.preventDefault();
			last.focus();
		} else if (!event.shiftKey && document.activeElement === last) {
			event.preventDefault();
			first.focus();
		}
	}

	function setAssistantStatus(mode, model, keyCount) {
		var safeMode = ["live", "fallback", "guided", "disabled"].indexOf(mode) >= 0 ? mode : "guided";
		var label = safeMode === "live" ? "Live AI" : (safeMode === "fallback" ? "Fallback mode" : (safeMode === "disabled" ? "Assistant off" : "Guided mode"));
		aiStatus.className = "ai-status-pill ai-status-" + safeMode;
		aiStatus.innerHTML = "<i></i> " + label;
		if (safeMode === "live") {
			aiModel.textContent = (model || "Groq") + (keyCount > 1 ? " · " + keyCount + " secure key slots" : "");
		} else {
			aiModel.textContent = safeMode === "fallback" ? "Provider unavailable" : (safeMode === "disabled" ? "Disabled by workspace configuration" : "Works without an API key");
		}
	}

	function loadStatus() {
		statusLoaded = true;
		fetch(assistant.getAttribute("data-status-url"), {
			method: "GET",
			headers: { "Accept": "application/json" },
			credentials: "same-origin"
		}).then(function (response) {
			if (!response.ok) throw new Error("Status unavailable");
			return response.json();
		}).then(function (data) {
			var details = jsonValue(data, "assistant") || {};
			var mode = jsonValue(details, "mode") || "guided";
			statusKeyCount = Number(jsonValue(details, "keyCount") || 0);
			assistantEnabled = mode !== "disabled";
			setBusy(false);
			setAssistantStatus(mode, jsonValue(details, "model") || "", statusKeyCount);
			if (!assistantEnabled) showValidation("The assistant is disabled for this workspace.");
		}).catch(function () {
			statusLoaded = false;
			setAssistantStatus("fallback", "", 0);
		});
	}

	function setBusy(value) {
		busy = value;
		assistant.setAttribute("aria-busy", String(value));
		aiSend.disabled = value || !assistantEnabled;
		aiInput.disabled = value || !assistantEnabled;
		assistant.querySelectorAll("[data-ai-prompt]").forEach(function (button) { button.disabled = value || !assistantEnabled; });
	}

	function appendMessage(role, text, meta, isError) {
		var message = document.createElement("div");
		message.className = "ai-message ai-message-" + role + (isError ? " ai-message-error" : "");
		message.setAttribute("data-ai-dynamic", "true");

		if (role === "assistant") {
			var avatar = document.createElement("span");
			avatar.className = "ai-message-avatar";
			avatar.innerHTML = '<i class="bi bi-stars"></i>';
			message.appendChild(avatar);
		}

		var content = document.createElement("div");
		content.className = "ai-message-content";
		var paragraph = document.createElement("p");
		paragraph.textContent = text;
		content.appendChild(paragraph);

		if (role === "assistant") {
			var footer = document.createElement("div");
			footer.className = "ai-message-footer";
			var note = document.createElement("small");
			note.textContent = meta || "DuePilot AI";
			footer.appendChild(note);
			if (!isError && navigator.clipboard) {
				var copy = document.createElement("button");
				copy.type = "button";
				copy.className = "ai-copy-button";
				copy.setAttribute("aria-label", "Copy response");
				copy.innerHTML = '<i class="bi bi-copy"></i> Copy';
				copy.addEventListener("click", function () {
					navigator.clipboard.writeText(text).then(function () {
						copy.innerHTML = '<i class="bi bi-check2"></i> Copied';
						setTimeout(function () { copy.innerHTML = '<i class="bi bi-copy"></i> Copy'; }, 1500);
					});
				});
				footer.appendChild(copy);
			}
			content.appendChild(footer);
		}

		message.appendChild(content);
		aiMessages.appendChild(message);
		aiMessages.scrollTop = aiMessages.scrollHeight;
		return message;
	}

	function appendThinking() {
		var message = document.createElement("div");
		message.className = "ai-message ai-message-assistant ai-thinking";
		message.setAttribute("data-ai-thinking", "true");
		message.innerHTML = '<span class="ai-message-avatar"><i class="bi bi-stars"></i></span><div class="ai-message-content"><span></span><span></span><span></span></div>';
		aiMessages.appendChild(message);
		aiMessages.scrollTop = aiMessages.scrollHeight;
		return message;
	}

	function validateMessage(message) {
		if (!message) return "Enter a question for DuePilot AI.";
		if (message.length > 2000) return "Keep your question under 2,000 characters.";
		return "";
	}

	function showValidation(message) {
		if (!aiValidation) return;
		aiValidation.textContent = message;
		aiValidation.hidden = !message;
		aiForm.classList.toggle("has-error", Boolean(message));
	}

	function sendMessage(rawMessage) {
		if (busy) return;
		var message = String(rawMessage || "").trim();
		var validationError = validateMessage(message);
		showValidation(validationError);
		if (validationError) {
			aiInput.focus();
			return;
		}

		var priorHistory = history.slice(-8);
		history.push({ role: "user", content: message });
		appendMessage("user", message, "", false);
		if (aiStarter) aiStarter.hidden = true;
		aiInput.value = "";
		resizeInput();
		setBusy(true);
		var thinking = appendThinking();

		fetch(assistant.getAttribute("data-chat-url"), {
			method: "POST",
			headers: { "Accept": "application/json", "Content-Type": "application/json" },
			credentials: "same-origin",
			body: JSON.stringify({
				message: message,
				history: priorHistory,
				csrfToken: assistant.getAttribute("data-csrf-token"),
				context: { page: assistant.getAttribute("data-page") || "Workspace", path: window.location.pathname }
			})
		}).then(function (response) {
			return response.json().catch(function () { return {}; }).then(function (data) {
				if (!response.ok || jsonValue(data, "ok") === false) {
					throw new Error(jsonValue(data, "error") || "The assistant could not complete that request.");
				}
				return data;
			});
		}).then(function (data) {
			thinking.remove();
			var answer = String(jsonValue(data, "answer") || "I could not generate a response.");
			var mode = jsonValue(data, "mode") || "guided";
			var provider = jsonValue(data, "provider") || "DuePilot AI";
			history.push({ role: "assistant", content: answer });
			if (history.length > 16) history = history.slice(-16);
			appendMessage("assistant", answer, provider, false);
			setAssistantStatus(mode, jsonValue(data, "model") || "", statusKeyCount);
		}).catch(function (error) {
			thinking.remove();
			appendMessage("assistant", error.message || "The assistant is temporarily unavailable. Please try again.", "Request not completed", true);
		}).finally(function () {
			setBusy(false);
			aiInput.focus();
		});
	}

	function resizeInput() {
		aiInput.style.height = "auto";
		aiInput.style.height = Math.min(aiInput.scrollHeight, 120) + "px";
		aiCount.textContent = String(aiInput.value.length);
		aiCount.parentElement.classList.toggle("near-limit", aiInput.value.length >= 1800);
		if (aiInput.value.trim()) showValidation("");
	}

	aiInput.addEventListener("input", resizeInput);
	aiInput.addEventListener("keydown", function (event) {
		if (event.key === "Enter" && !event.shiftKey) {
			event.preventDefault();
			sendMessage(aiInput.value);
		}
	});
	aiForm.addEventListener("submit", function (event) {
		event.preventDefault();
		sendMessage(aiInput.value);
	});
	assistant.querySelectorAll("[data-ai-prompt]").forEach(function (button) {
		button.addEventListener("click", function () { sendMessage(button.getAttribute("data-ai-prompt")); });
	});
	assistant.querySelector("[data-ai-clear]").addEventListener("click", function () {
		history = [];
		assistant.querySelectorAll("[data-ai-dynamic], [data-ai-thinking]").forEach(function (message) { message.remove(); });
		if (aiStarter) aiStarter.hidden = false;
		showValidation("");
		aiInput.value = "";
		resizeInput();
		aiInput.focus();
	});
})();
