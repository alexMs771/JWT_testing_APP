/**
 * Subscription and entitlement boundary.
 *
 * Identity roles (owner, finance, member, platform_admin) are intentionally
 * separate from plan entitlements (free, plus, pro). The API asks this service
 * for the current server-side decision on every protected request. JWT claims
 * carry a signed snapshot for observability and fast client rendering, but a
 * stale paid claim never bypasses this database check.
 */
component singleton {

	public array function planCatalog(){
		var demo = demoSubscriptions();
		return [
			{ key:"free", name:"Free", annualValidity:demo ? demoDurationLabel("free") : "No paid term", aiRequestsPerMonth:3, childWorkspaces:0, description:"One workspace for trying the core receivables workflow." },
			{ key:"plus", name:"Plus", annualValidity:demo ? demoDurationLabel("plus") : "1 year", aiRequestsPerMonth:100, childWorkspaces:2, description:"Small teams with nested workspaces and guided AI." },
			{ key:"pro", name:"Pro", annualValidity:demo ? demoDurationLabel("pro") : "1 year", aiRequestsPerMonth:-1, childWorkspaces:19, description:"Operations teams with full AI access and workspace scale." }
		];
	}

	public struct function getAccessContext(required struct account){
		var context = defaultContext(arguments.account);
		if (isPostgresMode() && len(trim(toString(arguments.account.workspaceId ?: "")))) {
			var workspaceId = toString(arguments.account.workspaceId);
			ensureFreeSubscription(workspaceId);
			var current = queryExecute(
				"SELECT id,plan,status,starts_at,ends_at,(ends_at > now() AND status IN ('active','trialing')) entitled " &
				"FROM workspace_subscriptions WHERE workspace_id=:workspaceId ORDER BY starts_at DESC,created_at DESC LIMIT 1",
				{workspaceId:{value:workspaceId,sqltype:"other"}}, {datasource:"duepilot"}
			);
			if (current.recordCount) {
				var isEntitled = current.entitled[1] == true;
				context.plan = isEntitled ? lCase(toString(current.plan[1])) : "free";
				context.subscriptionStatus = isEntitled ? lCase(toString(current.status[1])) : "expired";
				context.subscriptionId = toString(current.id[1]);
				context.startsAt = dateTimeFormat(current.starts_at[1], "yyyy-MM-dd'T'HH:nn:ss'Z'");
				context.expiresAt = dateTimeFormat(current.ends_at[1], "yyyy-MM-dd'T'HH:nn:ss'Z'");
			}
			var childRows = queryExecute(
				"SELECT count(*) child_count FROM workspaces WHERE parent_workspace_id=:workspaceId",
				{workspaceId:{value:workspaceId,sqltype:"other"}}, {datasource:"duepilot"}
			);
			context.workspace.childCount = childRows.recordCount ? val(childRows.child_count[1]) : 0;
			var usageRows = queryExecute(
				"SELECT count(*) ai_count FROM ai_usage WHERE workspace_id=:workspaceId AND created_at >= date_trunc('month', now()) AND status IN ('requested','success','fallback')",
				{workspaceId:{value:workspaceId,sqltype:"other"}}, {datasource:"duepilot"}
			);
			context.usage.aiRequestsThisMonth = usageRows.recordCount ? val(usageRows.ai_count[1]) : 0;
		} else {
			context.workspace.childCount = 0;
			context.usage.aiRequestsThisMonth = session.aiPlanUsage ?: 0;
		}

		var catalogEntry = catalogEntry(context.plan);
		context.limits = {
			aiRequestsPerMonth: catalogEntry.aiRequestsPerMonth,
			childWorkspaces: catalogEntry.childWorkspaces
		};
		context.features = featureList(context.plan);
		context.usage.aiRequestsRemaining = catalogEntry.aiRequestsPerMonth < 0
			? -1
			: max(0, catalogEntry.aiRequestsPerMonth - context.usage.aiRequestsThisMonth);
		context.workspace.canCreateChild = canCreateChild(arguments.account, context);
		context.demoMode = demoSubscriptions();
		context.isPaid = context.plan != "free" && listFindNoCase("active,trialing", context.subscriptionStatus) > 0;
		return context;
	}

	public struct function enrichAccount(required struct account){
		var enriched = duplicate(arguments.account);
		var access = getAccessContext(enriched);
		enriched.plan = access.plan;
		enriched.subscriptionStatus = access.subscriptionStatus;
		enriched.subscriptionExpiresAt = access.expiresAt;
		enriched.entitlements = access;
		return enriched;
	}

	public struct function subscribe(required struct account, required string plan){
		var requestedPlan = lCase(trim(arguments.plan));
		if (!listFindNoCase("plus,pro", requestedPlan)) {
			throw(type="DuePilot.InvalidPlan", message="Choose the Plus or Pro plan.");
		}
		if (!isPostgresMode()) {
			throw(type="DuePilot.PersistenceRequired", message="Subscriptions require PostgreSQL persistence mode.");
		}
		if (!isWorkspaceAdmin(arguments.account.role ?: "")) {
			throw(type="DuePilot.Forbidden", message="Only a workspace owner or administrator can change the plan.");
		}
		var workspaceId = toString(arguments.account.workspaceId);
		var durationExpression = demoSubscriptions()
			? demoDurationSeconds(requestedPlan) & " seconds"
			: "1 year";
		var providerName = demoSubscriptions() ? "internal-demo" : "internal";
		transaction {
			queryExecute("UPDATE workspace_subscriptions SET status='replaced',updated_at=now() WHERE workspace_id=:workspaceId AND status IN ('active','trialing')", {workspaceId:{value:workspaceId,sqltype:"other"}}, {datasource:"duepilot"});
			queryExecute(
				"INSERT INTO workspace_subscriptions(workspace_id,plan,status,starts_at,ends_at,provider,provider_reference,created_by) VALUES(:workspaceId,:plan,'active',now(),now()+interval '" & durationExpression & "','" & providerName & "',:reference,:userId)",
				{workspaceId:{value:workspaceId,sqltype:"other"},plan:{value:requestedPlan,sqltype:"varchar"},reference:{value:(demoSubscriptions() ? "demo-" : "internal-") & lCase(replace(createUUID(),"-","","all")),sqltype:"varchar"},userId:{value:toString(arguments.account.id),sqltype:"other"}},
				{datasource:"duepilot"}
			);
		}
		return getAccessContext(arguments.account);
	}

	public struct function reserveAiRequest(required struct account){
		var access = getAccessContext(arguments.account);
		if (access.limits.aiRequestsPerMonth >= 0 && access.usage.aiRequestsThisMonth >= access.limits.aiRequestsPerMonth) {
			throw(type="DuePilot.AiQuotaExceeded", message="Your #access.plan# plan has used its AI allowance for this month. Upgrade to continue.");
		}
		if (isPostgresMode()) {
			queryExecute(
				"INSERT INTO ai_usage(workspace_id,user_id,provider,model,operation,status) VALUES(:workspaceId,:userId,'groq',:model,'assistant.chat','requested')",
				{workspaceId:{value:toString(arguments.account.workspaceId),sqltype:"other"},userId:{value:toString(arguments.account.id),sqltype:"other"},model:{value:getSystemSetting("GROQ_MODEL","configured"),sqltype:"varchar"}},
				{datasource:"duepilot"}
			);
		} else {
			session.aiPlanUsage = (session.aiPlanUsage ?: 0) + 1;
		}
		access.usage.aiRequestsThisMonth++;
		access.usage.aiRequestsRemaining = access.limits.aiRequestsPerMonth < 0 ? -1 : max(0, access.limits.aiRequestsPerMonth - access.usage.aiRequestsThisMonth);
		return access;
	}

	public struct function createChildWorkspace(required struct account, required string name, required string organizationType){
		if (!isPostgresMode()) throw(type="DuePilot.PersistenceRequired", message="Nested workspaces require PostgreSQL persistence mode.");
		var access = getAccessContext(arguments.account);
		if (!access.workspace.canCreateChild) throw(type="DuePilot.PlanLimitReached", message="Your plan does not allow another nested workspace.");
		if (!isWorkspaceAdmin(arguments.account.role ?: "")) throw(type="DuePilot.Forbidden", message="Only a workspace owner or administrator can create a nested workspace.");
		var cleanName = normalizeName(arguments.name, "Workspace name", 2, 120);
		var organization = lCase(trim(arguments.organizationType));
		if (!listFindNoCase("business,school,college,coaching,property,utility,subscription,healthcare,other", organization)) throw(type="DuePilot.InvalidOrganizationType", message="Choose a valid organization type.");
		var parentId = toString(arguments.account.workspaceId);
		var childId = "";
		transaction {
			var slug = nextSlug(cleanName);
			queryExecute("INSERT INTO workspaces(name,slug,organization_type,finance_email,parent_workspace_id) VALUES(:name,:slug,CAST(:organization AS organization_type),:email,:parentId) RETURNING id", {name:{value:cleanName,sqltype:"varchar"},slug:{value:slug,sqltype:"varchar"},organization:{value:organization,sqltype:"varchar"},email:{value:toString(arguments.account.email),sqltype:"varchar"},parentId:{value:parentId,sqltype:"other"}}, {datasource:"duepilot"});
			var row = queryExecute("SELECT id FROM workspaces WHERE slug=:slug", {slug:{value:slug,sqltype:"varchar"}}, {datasource:"duepilot"});
			if (!row.recordCount) throw(type="DuePilot.WorkspaceCreateFailed", message="The nested workspace could not be created.");
			childId = toString(row.id[1]);
			queryExecute("INSERT INTO workspace_members(workspace_id,user_id,role,status) VALUES(:workspaceId,:userId,'Owner','active')", {workspaceId:{value:childId,sqltype:"other"},userId:{value:toString(arguments.account.id),sqltype:"other"}}, {datasource:"duepilot"});
			var childFreeDuration = demoSubscriptions() ? demoDurationSeconds("free") & " seconds" : "100 years";
			queryExecute("INSERT INTO workspace_subscriptions(workspace_id,plan,status,starts_at,ends_at,provider,created_by) VALUES(:workspaceId,'free','active',now(),now()+interval '" & childFreeDuration & "','internal',:userId)", {workspaceId:{value:childId,sqltype:"other"},userId:{value:toString(arguments.account.id),sqltype:"other"}}, {datasource:"duepilot"});
		}
		return {id:childId,name:cleanName,slug:slug,organizationType:organization,parentWorkspaceId:parentId,plan:"free"};
	}

	public array function listWorkspaces(required struct account){
		if (!isPostgresMode()) return [{id:toString(arguments.account.workspaceId ?: "demo"),name:"Demo workspace",slug:"demo",organizationType:"business",plan:"free",parentWorkspaceId:""}];
		var rows = queryExecute(
			"SELECT w.id,w.name,w.slug,w.organization_type,w.parent_workspace_id,COALESCE(s.plan,'free') plan " &
			"FROM workspaces w JOIN workspace_members wm ON wm.workspace_id=w.id AND wm.user_id=:userId AND wm.status='active' " &
			"LEFT JOIN LATERAL (SELECT plan FROM workspace_subscriptions WHERE workspace_id=w.id AND status IN ('active','trialing') AND ends_at>now() ORDER BY starts_at DESC LIMIT 1) s ON true " &
			"ORDER BY w.parent_workspace_id NULLS FIRST,w.created_at",
			{userId:{value:toString(arguments.account.id),sqltype:"other"}}, {datasource:"duepilot"}
		);
		var output=[];
		for (var row in rows) output.append({id:toString(row.id),name:toString(row.name),slug:toString(row.slug),organizationType:toString(row.organization_type),plan:toString(row.plan),parentWorkspaceId:isNull(row.parent_workspace_id)?"":toString(row.parent_workspace_id)});
		return output;
	}

	public array function listWorkspaceUnits(required struct account){
		if (!isPostgresMode()) return [];
		var rows = queryExecute(
			"SELECT id,parent_unit_id,name,code,unit_type,created_at FROM workspace_units WHERE workspace_id=:workspaceId ORDER BY parent_unit_id NULLS FIRST,created_at",
			{workspaceId:{value:toString(arguments.account.workspaceId),sqltype:"other"}}, {datasource:"duepilot"}
		);
		var output = [];
		for (var row in rows) output.append({
			id:toString(row.id),
			parentUnitId:isNull(row.parent_unit_id) ? "" : toString(row.parent_unit_id),
			name:toString(row.name),
			code:isNull(row.code) ? "" : toString(row.code),
			unitType:toString(row.unit_type),
			createdAt:dateTimeFormat(row.created_at,"yyyy-MM-dd HH:nn")
		});
		return output;
	}

	public struct function createWorkspaceUnit(required struct account, required string name, required string unitType, string parentUnitId="", string code=""){
		if (!isPostgresMode()) throw(type="DuePilot.PersistenceRequired", message="Workspace structure requires PostgreSQL persistence mode.");
		var access = getAccessContext(arguments.account);
		var unitLimit = access.plan == "pro" ? 200 : access.plan == "plus" ? 20 : 0;
		if (unitLimit == 0) throw(type="DuePilot.PlanLimitReached", message="Workspace structure is available on Plus and Pro plans.");
		if (!isWorkspaceAdmin(arguments.account.role ?: "")) throw(type="DuePilot.Forbidden", message="Only a workspace owner or administrator can manage workspace structure.");
		var countRows = queryExecute("SELECT count(*) unit_count FROM workspace_units WHERE workspace_id=:workspaceId", {workspaceId:{value:toString(arguments.account.workspaceId),sqltype:"other"}}, {datasource:"duepilot"});
		if (val(countRows.unit_count[1]) >= unitLimit) throw(type="DuePilot.PlanLimitReached", message="Your #access.plan# plan has reached its workspace structure limit.");
		var cleanName = normalizeName(arguments.name, "Unit name", 2, 120);
		var cleanType = lCase(trim(arguments.unitType));
		if (!listFindNoCase("department,division,branch,grade,class,batch,team,custom", cleanType)) throw(type="DuePilot.InvalidUnitType", message="Choose a valid workspace unit type.");
		var cleanParent = trim(arguments.parentUnitId ?: "");
		if (len(cleanParent) && !queryExecute("SELECT 1 FROM workspace_units WHERE id=:id AND workspace_id=:workspaceId", {id:{value:cleanParent,sqltype:"other"},workspaceId:{value:toString(arguments.account.workspaceId),sqltype:"other"}}, {datasource:"duepilot"}).recordCount) throw(type="DuePilot.InvalidParentUnit", message="The selected parent unit is not part of this workspace.");
		var cleanCode = left(trim(arguments.code ?: ""), 40);
		queryExecute(
			"INSERT INTO workspace_units(workspace_id,parent_unit_id,name,code,unit_type,created_by) VALUES(:workspaceId,:parentId,:name,:code,:unitType,:userId)",
			{workspaceId:{value:toString(arguments.account.workspaceId),sqltype:"other"},parentId:{value:cleanParent,sqltype:"other",null:!len(cleanParent)},name:{value:cleanName,sqltype:"varchar"},code:{value:cleanCode,sqltype:"varchar",null:!len(cleanCode)},unitType:{value:cleanType,sqltype:"varchar"},userId:{value:toString(arguments.account.id),sqltype:"other"}},
			{datasource:"duepilot"}
		);
		var lookupSql = "SELECT id,created_at FROM workspace_units WHERE workspace_id=:workspaceId AND name=:name AND unit_type=:unitType";
		var lookupParams = {workspaceId:{value:toString(arguments.account.workspaceId),sqltype:"other"},name:{value:cleanName,sqltype:"varchar"},unitType:{value:cleanType,sqltype:"varchar"}};
		if (len(cleanParent)) {
			lookupSql &= " AND parent_unit_id=:parentId";
			lookupParams.parentId = {value:cleanParent,sqltype:"other"};
		} else {
			lookupSql &= " AND parent_unit_id IS NULL";
		}
		lookupSql &= " ORDER BY created_at DESC LIMIT 1";
		var inserted = queryExecute(lookupSql, lookupParams, {datasource:"duepilot"});
		if (!inserted.recordCount) throw(type="DuePilot.WorkspaceUnitCreateFailed", message="The workspace unit could not be created.");
		return {id:toString(inserted.id[1]),parentUnitId:cleanParent,name:cleanName,code:cleanCode,unitType:cleanType,createdAt:dateTimeFormat(inserted.created_at[1],"yyyy-MM-dd HH:nn")};
	}

	private struct function defaultContext(required struct account){
		var plan = lCase(trim(toString(arguments.account.plan ?: "free")));
		if (!listFindNoCase("free,plus,pro", plan)) plan = "free";
		return {plan:plan,subscriptionStatus:arguments.account.subscriptionStatus ?: "active",subscriptionId:"",startsAt:"",expiresAt:arguments.account.subscriptionExpiresAt ?: "",isPaid:plan != "free",demoMode:demoSubscriptions(),features:[],limits:{},usage:{aiRequestsThisMonth:0,aiRequestsRemaining:0},workspace:{childCount:0,canCreateChild:false}};
	}

	private boolean function canCreateChild(required struct account, required struct access){
		return isWorkspaceAdmin(arguments.account.role ?: "") && arguments.access.limits.childWorkspaces > arguments.access.workspace.childCount;
	}

	private boolean function isWorkspaceAdmin(required string role){ return listFindNoCase("owner,admin", lCase(trim(arguments.role))) > 0; }

	private struct function catalogEntry(required string plan){
		for (var item in planCatalog()) if (item.key == arguments.plan) return item;
		return planCatalog()[1];
	}

	private array function featureList(required string plan){
		if (arguments.plan == "pro") return ["core_receivables","nested_workspaces","workspace_units","ai_assistant","unlimited_ai","priority_ai","advanced_reports","audit_exports"];
		if (arguments.plan == "plus") return ["core_receivables","nested_workspaces","workspace_units","ai_assistant","guided_ai"];
		return ["core_receivables","basic_reports"];
	}

	private boolean function demoSubscriptions(){
		return listFindNoCase("true,1,yes,on", trim(toString(getSystemSetting("DUEPILOT_DEMO_SUBSCRIPTIONS", "false")))) > 0;
	}

	private numeric function demoDurationSeconds(required string plan){
		var normalizedPlan = lCase(trim(arguments.plan));
		var key = "DUEPILOT_" & uCase(normalizedPlan) & "_TTL_SECONDS";
		var fallback = normalizedPlan == "free" ? 300 : normalizedPlan == "pro" ? 180 : 120;
		return max(30, val(getSystemSetting(key, fallback)));
	}

	private string function demoDurationLabel(required string plan){
		var seconds = demoDurationSeconds(arguments.plan);
		return seconds < 60 ? seconds & " seconds (test)" : int(seconds / 60) & " minutes (test)";
	}

	private void function ensureFreeSubscription(required string workspaceId){
		transaction {
			queryExecute("SELECT pg_advisory_xact_lock(hashtext(:workspaceId))", {workspaceId:{value:arguments.workspaceId,sqltype:"varchar"}}, {datasource:"duepilot"});
			var exists = queryExecute("SELECT 1 FROM workspace_subscriptions WHERE workspace_id=:workspaceId LIMIT 1", {workspaceId:{value:arguments.workspaceId,sqltype:"other"}}, {datasource:"duepilot"});
			if (!exists.recordCount) {
				var freeDuration = demoSubscriptions() ? demoDurationSeconds("free") & " seconds" : "100 years";
				queryExecute("INSERT INTO workspace_subscriptions(workspace_id,plan,status,starts_at,ends_at,provider) VALUES(:workspaceId,'free','active',now(),now()+interval '" & freeDuration & "','internal')", {workspaceId:{value:arguments.workspaceId,sqltype:"other"}}, {datasource:"duepilot"});
			}
		}
	}

	private string function nextSlug(required string workspaceName){
		var base = reReplace(lCase(trim(arguments.workspaceName)), "[^a-z0-9]+", "-", "all");
		base = reReplace(base, "(^-+|-+$)", "", "all");
		base = left(base, 68); if (!len(base)) base = "workspace";
		var candidate = base; var suffix = 2;
		while(queryExecute("SELECT 1 FROM workspaces WHERE slug=:slug LIMIT 1", {slug:{value:candidate,sqltype:"varchar"}}, {datasource:"duepilot"}).recordCount){ candidate = left(base, 75-len(suffix)) & "-" & suffix; suffix++; }
		return candidate;
	}

	private string function normalizeName(required string value, required string label, required numeric minimum, required numeric maximum){
		var clean = trim(reReplace(arguments.value,"\\s+"," ","all"));
		if (len(clean) < arguments.minimum || len(clean) > arguments.maximum) throw(type="DuePilot.InvalidName", message="#arguments.label# must be between #arguments.minimum# and #arguments.maximum# characters.");
		return clean;
	}

	private boolean function isPostgresMode(){ return compareNoCase(getSystemSetting("DATA_MODE","demo"),"postgres") == 0; }
}
