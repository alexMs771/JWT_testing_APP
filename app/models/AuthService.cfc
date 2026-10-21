/** PostgreSQL identity, profile, and platform-administration boundary. */
component singleton {

	public struct function authenticate( required string username, required string password ){
		var email = lCase( trim( arguments.username ) );
		bootstrapPlatformAdmin( email );
		if ( !isValid( "email", email ) || len( email ) > 254 || len( arguments.password ) < 12 || len( arguments.password ) > 200 ) {
			logLogin( 0, email, "failed" );
			return { authenticated:false, user:{} };
		}
		var result = queryExecute(
			"SELECT u.id,u.name,u.email,wm.role,w.id workspace_id,(pa.user_id IS NOT NULL) is_platform_admin FROM users u JOIN workspace_members wm ON wm.user_id=u.id AND wm.status='active' JOIN workspaces w ON w.id=wm.workspace_id LEFT JOIN platform_admins pa ON pa.user_id=u.id WHERE u.email=:email AND u.status='active' AND u.password_hash=crypt(:password,u.password_hash) ORDER BY wm.joined_at LIMIT 1",
			{ email:{value:email,sqltype:"varchar"}, password:{value:arguments.password,sqltype:"varchar"} }, { datasource:"duepilot" }
		);
		if ( !result.recordCount ) { logLogin( 0, email, "failed" ); return { authenticated:false, user:{} }; }
		var account = userFromRow( result );
		queryExecute( "UPDATE users SET last_login_at=now(),updated_at=now() WHERE id=:id", {id:{value:account.id,sqltype:"other"}}, {datasource:"duepilot"} );
		logLogin( account.id, email, "success" );
		return { authenticated:true, user:account };
	}

	public struct function register(required string workspaceName, required string organizationType, required string name, required string email, required string password){
		var cleanWorkspace=normalizeName(arguments.workspaceName,"Workspace name",2,120); var cleanName=normalizeName(arguments.name,"Your name",2,120); var cleanEmail=lCase(trim(arguments.email)); var organization=lCase(trim(arguments.organizationType));
		if(!isValid("email",cleanEmail)||len(cleanEmail)>254)throw(type="DuePilot.InvalidEmail",message="Enter a valid work email address.");
		if(!reFind("^(?=.*[A-Za-z])(?=.*[0-9]).{12,200}$",arguments.password))throw(type="DuePilot.InvalidPassword",message="Use 12 to 200 characters with at least one letter and one number.");
		if(!listFindNoCase("business,school,college,coaching,property,utility,subscription,healthcare,other",organization))throw(type="DuePilot.InvalidOrganizationType",message="Choose a valid organization type.");
		var userId=""; var workspaceId="";
		transaction {
			if(queryExecute("SELECT 1 FROM users WHERE email=:email LIMIT 1",{email:{value:cleanEmail,sqltype:"varchar"}},{datasource:"duepilot"}).recordCount)throw(type="DuePilot.EmailInUse",message="An account already exists for this email. Sign in instead.");
			var slug=nextSlug(cleanWorkspace);
			queryExecute("INSERT INTO users(name,email,password_hash,email_verified_at,status) VALUES(:name,:email,crypt(:password,gen_salt('bf',12)),now(),'active')",{name:{value:cleanName,sqltype:"varchar"},email:{value:cleanEmail,sqltype:"varchar"},password:{value:arguments.password,sqltype:"varchar"}},{datasource:"duepilot"});
			var userRow=queryExecute("SELECT id FROM users WHERE email=:email",{email:{value:cleanEmail,sqltype:"varchar"}},{datasource:"duepilot"}); userId=toString(userRow.id[1]);
			queryExecute("INSERT INTO workspaces(name,slug,organization_type,finance_email) VALUES(:name,:slug,CAST(:organization AS organization_type),:email)",{name:{value:cleanWorkspace,sqltype:"varchar"},slug:{value:slug,sqltype:"varchar"},organization:{value:organization,sqltype:"varchar"},email:{value:cleanEmail,sqltype:"varchar"}},{datasource:"duepilot"});
			var workspaceRow=queryExecute("SELECT id FROM workspaces WHERE slug=:slug",{slug:{value:slug,sqltype:"varchar"}},{datasource:"duepilot"}); workspaceId=toString(workspaceRow.id[1]);
			queryExecute("INSERT INTO workspace_members(workspace_id,user_id,role,status) VALUES(:workspaceId,:userId,'Owner','active')",{workspaceId:{value:workspaceId,sqltype:"other"},userId:{value:userId,sqltype:"other"}},{datasource:"duepilot"});
			trackUsage(workspaceId,userId,"workspace.created");
		}
		return {authenticated:true,user:{id:userId,name:cleanName,email:cleanEmail,role:"Owner",initials:initials(cleanName),workspaceId:workspaceId,isPlatformAdmin:false}};
	}

	public struct function getProfile(required string userId){
		var row=queryExecute("SELECT name,email,created_at,last_login_at,profile_photo_content_type,profile_photo_bytes FROM users WHERE id=:id",{id:{value:arguments.userId,sqltype:"other"}},{datasource:"duepilot"});
		if(!row.recordCount)throw(type="DuePilot.ProfileNotFound",message="Your profile is no longer available.");
		return profileFromRow(row);
	}

	public struct function updateProfile(required string userId,required string name){
		var cleanName=normalizeName(arguments.name,"Your name",2,120); queryExecute("UPDATE users SET name=:name,updated_at=now() WHERE id=:id",{name:{value:cleanName,sqltype:"varchar"},id:{value:arguments.userId,sqltype:"other"}},{datasource:"duepilot"}); return getProfile(arguments.userId);
	}

	public struct function saveProfilePhoto(required string userId,required string contentType,required string imageBase64){
		var type=lCase(trim(arguments.contentType)); if(!listFindNoCase("image/jpeg,image/png,image/webp",type))throw(type="DuePilot.InvalidPhoto",message="Choose a JPG, PNG, or WEBP image.");
		var bytes=""; try { bytes=binaryDecode(arguments.imageBase64,"base64"); } catch(any error) { throw(type="DuePilot.InvalidPhoto",message="The uploaded image could not be read."); }
		if(arrayLen(bytes)>2097152)throw(type="DuePilot.InvalidPhoto",message="Profile photos must be 2 MB or smaller.");
		queryExecute("UPDATE users SET profile_photo_content_type=:type,profile_photo_bytes=decode(:imageBase64,'base64'),updated_at=now() WHERE id=:id",{type:{value:type,sqltype:"varchar"},imageBase64:{value:arguments.imageBase64,sqltype:"varchar"},id:{value:arguments.userId,sqltype:"other"}},{datasource:"duepilot"}); return getProfile(arguments.userId);
	}

	public struct function removeProfilePhoto(required string userId){queryExecute("UPDATE users SET profile_photo_content_type=NULL,profile_photo_bytes=NULL,updated_at=now() WHERE id=:id",{id:{value:arguments.userId,sqltype:"other"}},{datasource:"duepilot"});return getProfile(arguments.userId);}

	public void function deleteOwnWorkspace(required struct user,required string confirmation){
		var workspaceName=""; transaction { var row=queryExecute("SELECT w.name FROM workspaces w JOIN workspace_members wm ON wm.workspace_id=w.id WHERE w.id=:workspaceId AND wm.user_id=:userId AND wm.role='Owner' AND wm.status='active' FOR UPDATE",{workspaceId:{value:arguments.user.workspaceId,sqltype:"other"},userId:{value:arguments.user.id,sqltype:"other"}},{datasource:"duepilot"}); if(!row.recordCount)throw(type="DuePilot.Forbidden",message="Only the workspace owner can delete this workspace."); workspaceName=toString(row.name[1]); if(compare(trim(arguments.confirmation),workspaceName)!=0)throw(type="DuePilot.InvalidConfirmation",message="Enter the workspace name exactly to confirm deletion."); queryExecute("DELETE FROM workspaces WHERE id=:id",{id:{value:arguments.user.workspaceId,sqltype:"other"}},{datasource:"duepilot"}); queryExecute("INSERT INTO workspace_deletions(workspace_name,deleted_by,deleted_by_admin) VALUES(:name,:userId,false)",{name:{value:workspaceName,sqltype:"varchar"},userId:{value:arguments.user.id,sqltype:"other"}},{datasource:"duepilot"}); }
	}

	public boolean function isPlatformAdmin(required string userId){return queryExecute("SELECT 1 FROM platform_admins WHERE user_id=:id",{id:{value:arguments.userId,sqltype:"other"}},{datasource:"duepilot"}).recordCount>0;}

	public struct function getAdminOverview(){
		var totals=queryExecute("SELECT (SELECT count(*) FROM workspaces) workspace_count,(SELECT count(*) FROM users WHERE status='active') user_count,(SELECT count(*) FROM auth_login_events WHERE outcome='success' AND created_at>now()-interval '24 hours') logins_today,(SELECT count(*) FROM invoices) invoice_count",{}, {datasource:"duepilot"});
		var rows=queryExecute("SELECT w.id,w.name,w.slug,w.organization_type,w.created_at,w.finance_email,coalesce((SELECT s.plan FROM workspace_subscriptions s WHERE s.workspace_id=w.id AND s.status IN ('active','trialing') AND s.ends_at>now() ORDER BY s.starts_at DESC LIMIT 1),'free') plan,count(DISTINCT wm.user_id) member_count,count(DISTINCT i.id) invoice_count,max(u.last_login_at) last_login,coalesce((SELECT count(*) FROM workspace_usage_events ue WHERE ue.workspace_id=w.id AND ue.created_at>now()-interval '30 days'),0) usage_30d FROM workspaces w LEFT JOIN workspace_members wm ON wm.workspace_id=w.id LEFT JOIN invoices i ON i.workspace_id=w.id LEFT JOIN users u ON u.id=wm.user_id GROUP BY w.id ORDER BY w.created_at DESC",{}, {datasource:"duepilot"});
		var workspaces=[]; for(var row in rows)workspaces.append({id:toString(row.id),name:toString(row.name),slug:toString(row.slug),organizationType:toString(row.organization_type),plan:toString(row.plan),email:toString(row.finance_email?:""),createdAt:dateTimeFormat(row.created_at,"yyyy-MM-dd HH:nn"),memberCount:row.member_count,invoiceCount:row.invoice_count,lastLogin:isNull(row.last_login)?"Never":dateTimeFormat(row.last_login,"yyyy-MM-dd HH:nn"),usage30d:row.usage_30d});
		var events=queryExecute("SELECT e.email,e.outcome,e.created_at,u.name FROM auth_login_events e LEFT JOIN users u ON u.id=e.user_id ORDER BY e.created_at DESC LIMIT 25",{}, {datasource:"duepilot"}); var activity=[]; for(var eventRow in events)activity.append({email:toString(eventRow.email),name:toString(eventRow.name?:"Unknown"),outcome:toString(eventRow.outcome),at:dateTimeFormat(eventRow.created_at,"yyyy-MM-dd HH:nn")});
		return {metrics:{workspaceCount:totals.workspace_count[1],userCount:totals.user_count[1],loginsToday:totals.logins_today[1],invoiceCount:totals.invoice_count[1]},workspaces:workspaces,loginEvents:activity};
	}

	public void function adminDeleteWorkspace(required string workspaceId,required string adminId){
		transaction { var row=queryExecute("SELECT name FROM workspaces WHERE id=:id FOR UPDATE",{id:{value:arguments.workspaceId,sqltype:"other"}},{datasource:"duepilot"}); if(!row.recordCount)throw(type="DuePilot.WorkspaceNotFound",message="Workspace not found."); var name=toString(row.name[1]); queryExecute("DELETE FROM workspaces WHERE id=:id",{id:{value:arguments.workspaceId,sqltype:"other"}},{datasource:"duepilot"}); queryExecute("INSERT INTO workspace_deletions(workspace_name,deleted_by,deleted_by_admin) VALUES(:name,:adminId,true)",{name:{value:name,sqltype:"varchar"},adminId:{value:arguments.adminId,sqltype:"other"}},{datasource:"duepilot"}); }
	}

	public void function logLogout(required string userId,required string email){logLogin(arguments.userId,arguments.email,"logout");}

	private void function bootstrapPlatformAdmin(required string requestedEmail){
		var adminEmail=lCase(trim(getSystemSetting("PLATFORM_ADMIN_EMAIL",""))); var adminPassword=getSystemSetting("PLATFORM_ADMIN_PASSWORD","");
		if(!len(adminEmail)||compare(adminEmail,arguments.requestedEmail)!=0||!isValid("email",adminEmail)||!reFind("^(?=.*[A-Za-z])(?=.*[0-9]).{12,200}$",adminPassword))return;
		if(queryExecute("SELECT 1 FROM users WHERE email=:email",{email:{value:adminEmail,sqltype:"varchar"}},{datasource:"duepilot"}).recordCount)return;
		var adminName=normalizeName(getSystemSetting("PLATFORM_ADMIN_NAME","DuePilot Administrator"),"Administrator name",2,120); var userId=""; var workspaceId="";
		transaction { queryExecute("INSERT INTO users(name,email,password_hash,email_verified_at,status) VALUES(:name,:email,crypt(:password,gen_salt('bf',12)),now(),'active')",{name:{value:adminName,sqltype:"varchar"},email:{value:adminEmail,sqltype:"varchar"},password:{value:adminPassword,sqltype:"varchar"}},{datasource:"duepilot"}); var userRow=queryExecute("SELECT id FROM users WHERE email=:email",{email:{value:adminEmail,sqltype:"varchar"}},{datasource:"duepilot"});userId=toString(userRow.id[1]); var slug=nextSlug("duepilot-administration"); queryExecute("INSERT INTO workspaces(name,slug,organization_type,finance_email) VALUES('DuePilot Administration',:slug,'business',:email)",{slug:{value:slug,sqltype:"varchar"},email:{value:adminEmail,sqltype:"varchar"}},{datasource:"duepilot"});var workspaceRow=queryExecute("SELECT id FROM workspaces WHERE slug=:slug",{slug:{value:slug,sqltype:"varchar"}},{datasource:"duepilot"});workspaceId=toString(workspaceRow.id[1]);queryExecute("INSERT INTO workspace_members(workspace_id,user_id,role,status) VALUES(:workspaceId,:userId,'Owner','active')",{workspaceId:{value:workspaceId,sqltype:"other"},userId:{value:userId,sqltype:"other"}},{datasource:"duepilot"});queryExecute("INSERT INTO platform_admins(user_id) VALUES(:userId)",{userId:{value:userId,sqltype:"other"}},{datasource:"duepilot"}); }
	}

	private void function logLogin(required any userId,required string email,required string outcome){try{queryExecute("INSERT INTO auth_login_events(user_id,email,outcome,ip_hash,user_agent) VALUES(:userId,:email,:outcome,:ip,:agent)",{userId:{value:arguments.userId,sqltype:"other",null:!len(arguments.userId)},email:{value:arguments.email,sqltype:"varchar"},outcome:{value:arguments.outcome,sqltype:"varchar"},ip:{value:hash(cgi.remote_addr?:"","SHA-256"),sqltype:"varchar"},agent:{value:left(cgi.http_user_agent?:"",500),sqltype:"varchar"}},{datasource:"duepilot"});}catch(any ignored){}}
	private void function trackUsage(required string workspaceId,required string userId,required string eventType){queryExecute("INSERT INTO workspace_usage_events(workspace_id,user_id,event_type) VALUES(:workspaceId,:userId,:eventType)",{workspaceId:{value:arguments.workspaceId,sqltype:"other"},userId:{value:arguments.userId,sqltype:"other"},eventType:{value:arguments.eventType,sqltype:"varchar"}},{datasource:"duepilot"});}
	private string function nextSlug(required string workspaceName){var base=reReplace(lCase(trim(arguments.workspaceName)),"[^a-z0-9]+","-","all");base=reReplace(base,"(^-+|-+$)","","all");base=left(base,68);if(!len(base))base="workspace";var candidate=base;var suffix=2;while(queryExecute("SELECT 1 FROM workspaces WHERE slug=:slug LIMIT 1",{slug:{value:candidate,sqltype:"varchar"}},{datasource:"duepilot"}).recordCount){candidate=left(base,75-len(suffix))&"-"&suffix;suffix++;}return candidate;}
	private string function normalizeName(required string value,required string label,required numeric minimum,required numeric maximum){var clean=trim(reReplace(arguments.value,"\\s+"," ","all"));if(len(clean)<arguments.minimum||len(clean)>arguments.maximum)throw(type="DuePilot.InvalidName",message="#arguments.label# must be between #arguments.minimum# and #arguments.maximum# characters.");return clean;}
	private struct function userFromRow(required query result){var name=toString(arguments.result.name[1]);return {id:toString(arguments.result.id[1]),name:name,email:toString(arguments.result.email[1]),role:toString(arguments.result.role[1]),initials:initials(name),workspaceId:toString(arguments.result.workspace_id[1]),isPlatformAdmin:arguments.result.is_platform_admin[1] == true};}
	private struct function profileFromRow(required query result){var photo="";if(!isNull(arguments.result.profile_photo_bytes[1])&&len(arguments.result.profile_photo_content_type[1]))photo="data:"&toString(arguments.result.profile_photo_content_type[1])&";base64,"&binaryEncode(arguments.result.profile_photo_bytes[1],"base64");return {name:toString(arguments.result.name[1]),email:toString(arguments.result.email[1]),initials:initials(toString(arguments.result.name[1])),photoUrl:photo,createdAt:dateTimeFormat(arguments.result.created_at[1],"yyyy-MM-dd"),lastLogin:isNull(arguments.result.last_login_at[1])?"Never":dateTimeFormat(arguments.result.last_login_at[1],"yyyy-MM-dd HH:nn")};}
	private string function initials(required string name){var parts=listToArray(trim(arguments.name)," ");return uCase(left(parts[1],1)&(parts.len()>1?left(parts[parts.len()],1):""));}
}
