/** PostgreSQL persistence adapter for the DuePilot V1 domain contract. */
component singleton {

	private query function run( required string sql, struct params = {} ){
		for ( var paramName in arguments.params ) {
			if ( listFindNoCase( "workspaceId,customerId,invoiceId,actor", toString( paramName ) ) ) {
				arguments.params[ paramName ].sqltype = "other";
			}
		}
		return queryExecute( arguments.sql, arguments.params, { datasource : "duepilot" } );
	}

	public string function workspaceId(){
		if ( structKeyExists( session, "user" ) && structKeyExists( session.user, "workspaceId" ) ) return session.user.workspaceId;
		var slug = getSystemSetting( "DUEPILOT_WORKSPACE_SLUG", "northstar-digital" );
		var result = run( "SELECT id FROM workspaces WHERE slug = :slug LIMIT 1", { slug : { value : slug, sqltype : "varchar" } } );
		if ( !result.recordCount ) throw( type="DuePilot.WorkspaceNotFound", message="The configured workspace was not found." );
		return toString( result.id[ 1 ] );
	}

	public struct function getOrganization(){
		var result = run( "SELECT id, name, currency, finance_email, default_payment_terms FROM workspaces WHERE id=:workspaceId", pWorkspace() );
		if ( !result.recordCount ) throw( type="DuePilot.WorkspaceNotFound", message="Workspace not found." );
		var workspaceName=textValue(result.name[1]);
		return { id:toString(result.id[1]), name:workspaceName, initials:initials(workspaceName), plan:"Growth", currency:textValue(result.currency[1]), financeEmail:textValue(result.finance_email[1]), defaultTerms:result.default_payment_terms[1] };
	}

	public struct function updateOrganization( required string name, required string currency, required string financeEmail, required numeric defaultTerms ){
		run( "UPDATE workspaces SET name=:name,currency=:currency,finance_email=:email,default_payment_terms=:terms,updated_at=now() WHERE id=:workspaceId", {
			workspaceId:{value:workspaceId(),sqltype:"varchar"}, name:{value:arguments.name,sqltype:"varchar"}, currency:{value:arguments.currency,sqltype:"varchar"}, email:{value:arguments.financeEmail,sqltype:"varchar"}, terms:{value:arguments.defaultTerms,sqltype:"integer"}
		} );
		return getOrganization();
	}

	public array function listInvoices( string status="", string search="" ){
		var sql = "SELECT i.id,i.invoice_number,i.customer_id,c.display_name customer_name,i.total_amount,i.paid_amount,i.balance_amount,i.issue_date,i.due_date,i.purchase_order,i.notes,i.status,"
			& "coalesce(CAST((SELECT promised_date FROM payment_promises pp WHERE pp.invoice_id=i.id AND pp.status='open' ORDER BY created_at DESC LIMIT 1) AS text),'') promise_date,"
			& "coalesce((SELECT note FROM payment_promises pp WHERE pp.invoice_id=i.id AND pp.status='open' ORDER BY created_at DESC LIMIT 1),'') promise_note,"
			& "coalesce((SELECT reason FROM disputes d WHERE d.invoice_id=i.id AND d.status='open' ORDER BY opened_at DESC LIMIT 1),'') dispute_reason,"
			& "(SELECT count(*) FROM collection_activities ca WHERE ca.invoice_id=i.id AND ca.activity_type='reminder') reminder_count,"
			& "coalesce((SELECT to_char(created_at,'YYYY-MM-DD HH24:MI') FROM collection_activities ca WHERE ca.invoice_id=i.id ORDER BY created_at DESC LIMIT 1),'') last_contact_at,"
			& "coalesce((SELECT to_char(paid_at,'YYYY-MM-DD HH24:MI') FROM payments p WHERE p.invoice_id=i.id AND p.status='successful' ORDER BY paid_at DESC LIMIT 1),'') paid_at,"
			& "coalesce((SELECT provider_reference FROM payments p WHERE p.invoice_id=i.id AND p.status='successful' ORDER BY paid_at DESC LIMIT 1),'') payment_ref "
			& "FROM invoices i JOIN customers c ON c.id=i.customer_id WHERE i.workspace_id=:workspaceId";
		var params = pWorkspace();
		if ( len(trim(arguments.status)) && arguments.status != "all" ) { sql &= " AND i.status=:status"; params.status={value:lCase(arguments.status),sqltype:"varchar"}; }
		if ( len(trim(arguments.search)) ) { sql &= " AND (i.invoice_number ILIKE :search OR c.display_name ILIKE :search)"; params.search={value:"%"&trim(arguments.search)&"%",sqltype:"varchar"}; }
		sql &= " ORDER BY i.issue_date DESC,i.created_at DESC";
		return invoiceRows( run(sql,params) );
	}

	public struct function getInvoice( required string invoiceId ){
		var wantedInvoiceId = arguments.invoiceId;
		var matches = listInvoices().filter( function(item){ return item.id == wantedInvoiceId; } );
		if ( !matches.len() ) throw( type="DuePilot.InvoiceNotFound", message="Invoice not found." );
		return matches[1];
	}

	public struct function getInvoiceByPortalToken( required string portalToken ){
		var result=run("SELECT id FROM invoices WHERE workspace_id=:workspaceId AND portal_token_hash=encode(digest(:token,'sha256'),'hex')",{workspaceId:{value:workspaceId(),sqltype:"varchar"},token:{value:arguments.portalToken,sqltype:"varchar"}});
		if(!result.recordCount) throw(type="DuePilot.PortalLinkNotFound",message="This payment link is invalid or has expired.");
		return getInvoice(toString(result.id[1]));
	}

	public struct function createInvoice( required string customerId, required numeric amount, required string issueDate, required string dueDate, string purchaseOrder="", string description="Professional services" ){
		var createdId=""; var portalToken=lCase(replace(createUUID(),"-","","all")); var workspace=workspaceId(); var actor=actorId();
		transaction {
			run("SELECT pg_advisory_xact_lock(hashtext(:workspaceId))",{workspaceId:{value:workspace,sqltype:"varchar"}});
			var sequence=run("SELECT coalesce(max(CAST(nullif(regexp_replace(invoice_number,'^.*-','','g'),'') AS integer)),1000)+1 next_number FROM invoices WHERE workspace_id=:workspaceId",{workspaceId:{value:workspace,sqltype:"varchar"}});
			var number="INV-#year(now())#-#sequence.next_number[1]#";
			run("INSERT INTO invoices(workspace_id,customer_id,invoice_number,status,issue_date,due_date,currency,subtotal,total_amount,paid_amount,balance_amount,purchase_order,notes,portal_token_hash,created_by) SELECT :workspaceId,:customerId,:number,'open',:issueDate,:dueDate,w.currency,:amount,:amount,0,:amount,:po,:notes,encode(digest(:portal,'sha256'),'hex'),:actor FROM workspaces w WHERE w.id=:workspaceId",{
				workspaceId:{value:workspace,sqltype:"varchar"},customerId:{value:arguments.customerId,sqltype:"varchar"},number:{value:number,sqltype:"varchar"},issueDate:{value:arguments.issueDate,sqltype:"date"},dueDate:{value:arguments.dueDate,sqltype:"date"},amount:{value:arguments.amount,sqltype:"decimal"},po:{value:arguments.purchaseOrder,sqltype:"varchar"},notes:{value:arguments.description,sqltype:"varchar"},portal:{value:portalToken,sqltype:"varchar"},actor:{value:actor,sqltype:"varchar"}
			});
			// Avoid depending on the case/shape of a JDBC RETURNING query result.
			// The portal-token hash is unique, so this lookup is deterministic inside
			// the same transaction and works consistently across BoxLang drivers.
			var insertedRows=run("SELECT id FROM invoices WHERE workspace_id=:workspaceId AND portal_token_hash=encode(digest(:portal,'sha256'),'hex')",{
				workspaceId:{value:workspace,sqltype:"varchar"},portal:{value:portalToken,sqltype:"varchar"}
			});
			if ( !insertedRows.recordCount ) throw(type="DuePilot.InvoiceCreateFailed",message="The invoice could not be created.");
			for ( var insertedRow in insertedRows ) { createdId=toString(insertedRow.id); break; }
			run("INSERT INTO invoice_items(workspace_id,invoice_id,description,quantity,unit_price,line_total) VALUES(:workspaceId,:invoiceId,:description,1,:amount,:amount)",{workspaceId:{value:workspace,sqltype:"varchar"},invoiceId:{value:createdId,sqltype:"varchar"},description:{value:arguments.description,sqltype:"varchar"},amount:{value:arguments.amount,sqltype:"decimal"}});
			activity(createdId,"invoice","Invoice #number# created",{amount:arguments.amount});
		}
		var output=getInvoice(createdId); output.portalToken=portalToken; return output;
	}

	public struct function recordPayment( required string invoiceId, required numeric amount, string reference="" ){
		var reference=len(trim(arguments.reference))?trim(arguments.reference):"manual-"&lCase(replace(createUUID(),"-","","all"));
		transaction {
			var locked=run("SELECT balance_amount,currency FROM invoices WHERE id=:invoiceId AND workspace_id=:workspaceId FOR UPDATE",invoiceParams(arguments.invoiceId));
			if(!locked.recordCount) throw(type="DuePilot.InvoiceNotFound",message="Invoice not found.");
			if(arguments.amount>locked.balance_amount[1]) throw(type="DuePilot.Overpayment",message="Payment cannot be greater than the outstanding balance.");
			run("INSERT INTO payments(workspace_id,invoice_id,provider,provider_reference,status,amount,currency,paid_at,verified_at) VALUES(:workspaceId,:invoiceId,'manual',:reference,'successful',:amount,:currency,now(),now())",{workspaceId:{value:workspaceId(),sqltype:"varchar"},invoiceId:{value:arguments.invoiceId,sqltype:"varchar"},reference:{value:reference,sqltype:"varchar"},amount:{value:arguments.amount,sqltype:"decimal"},currency:{value:locked.currency[1],sqltype:"varchar"}});
			run("UPDATE invoices SET paid_amount=paid_amount+:amount,balance_amount=balance_amount-:amount,status=CASE WHEN balance_amount-:amount=0 THEN CAST('paid' AS invoice_status) ELSE CAST('partial' AS invoice_status) END,updated_at=now() WHERE id=:invoiceId AND workspace_id=:workspaceId",{workspaceId:{value:workspaceId(),sqltype:"varchar"},invoiceId:{value:arguments.invoiceId,sqltype:"varchar"},amount:{value:arguments.amount,sqltype:"decimal"}});
			activity(arguments.invoiceId,"payment","Payment recorded",{amount:arguments.amount,reference:reference});
		}
		return getInvoice(arguments.invoiceId);
	}

	public struct function savePromise( required string invoiceId, required string promiseDate, string note="" ){
		transaction { assertOpen(arguments.invoiceId); run("UPDATE payment_promises SET status='superseded',resolved_at=now() WHERE invoice_id=:invoiceId AND status='open'",invoiceParams(arguments.invoiceId)); run("INSERT INTO payment_promises(workspace_id,invoice_id,promised_date,promised_amount,note) SELECT workspace_id,id,:promiseDate,balance_amount,:note FROM invoices WHERE id=:invoiceId AND workspace_id=:workspaceId",{workspaceId:{value:workspaceId(),sqltype:"varchar"},invoiceId:{value:arguments.invoiceId,sqltype:"varchar"},promiseDate:{value:arguments.promiseDate,sqltype:"date"},note:{value:arguments.note,sqltype:"varchar"}}); activity(arguments.invoiceId,"promise","Payment promise captured",{promiseDate:arguments.promiseDate}); }
		return getInvoice(arguments.invoiceId);
	}

	public struct function openDispute( required string invoiceId, required string reason ){
		transaction { assertOpen(arguments.invoiceId); run("INSERT INTO disputes(workspace_id,invoice_id,reason) VALUES(:workspaceId,:invoiceId,:reason)",{workspaceId:{value:workspaceId(),sqltype:"varchar"},invoiceId:{value:arguments.invoiceId,sqltype:"varchar"},reason:{value:arguments.reason,sqltype:"varchar"}}); run("UPDATE invoices SET status='disputed',updated_at=now() WHERE id=:invoiceId AND workspace_id=:workspaceId",invoiceParams(arguments.invoiceId)); activity(arguments.invoiceId,"dispute","Dispute opened",{reason:arguments.reason}); }
		return getInvoice(arguments.invoiceId);
	}

	public struct function sendReminder( required string invoiceId, string channel="email" ){
		assertOpen(arguments.invoiceId); activity(arguments.invoiceId,"reminder","Reminder sent",{channel:arguments.channel}); return getInvoice(arguments.invoiceId);
	}

	public array function listCustomers( string search="" ){
		var params=pWorkspace(); var sql="SELECT c.id,c.display_name,c.contact_name,c.email,c.phone,count(i.id) invoice_count,coalesce(sum(i.balance_amount),0) outstanding,coalesce(sum(CASE WHEN i.due_date<current_date AND i.status<>'paid' THEN i.balance_amount ELSE 0 END),0) overdue,coalesce(sum(i.paid_amount),0) paid FROM customers c LEFT JOIN invoices i ON i.customer_id=c.id WHERE c.workspace_id=:workspaceId";
		if(len(trim(arguments.search))){sql&=" AND (c.display_name ILIKE :search OR c.email ILIKE :search)";params.search={value:"%"&trim(arguments.search)&"%",sqltype:"varchar"};} sql&=" GROUP BY c.id ORDER BY outstanding DESC,c.display_name";
		var result=run(sql,params); var output=[]; for(var row in result){var name=row.display_name; output.append({id:toString(row.id),name:name,contact:row.contact_name?:"",email:row.email?:"",phone:row.phone?:"",initials:initials(name),color:"blue",avgDaysLate:0,invoiceCount:row.invoice_count,outstanding:row.outstanding,overdue:row.overdue,paid:row.paid,health:row.overdue>0?"watch":"excellent"});} return output;
	}

	public struct function getCustomer(required string customerId){var wantedCustomerId=arguments.customerId;var items=listCustomers().filter(function(item){return item.id==wantedCustomerId;});if(!items.len())throw(type="DuePilot.CustomerNotFound",message="Customer not found.");return items[1];}

	public array function getRecentActivity(numeric limit=10){var result=run("SELECT activity_type,summary,detail,invoice_id,created_at FROM collection_activities WHERE workspace_id=:workspaceId ORDER BY created_at DESC LIMIT :limit",{workspaceId:{value:workspaceId(),sqltype:"varchar"},limit:{value:arguments.limit,sqltype:"integer"}});var output=[];for(var row in result)output.append({kind:row.activity_type,title:row.summary,detail:isSimpleValue(row.detail)?toString(row.detail):serializeJSON(row.detail),at:dateTimeFormat(row.created_at,"yyyy-mm-dd HH:nn"),invoiceId:toString(row.invoice_id)});return output;}

	private array function invoiceRows(required query result){var output=[];for(var row in arguments.result){var due=dateFormat(row.due_date,"yyyy-mm-dd");var days=dateDiff("d",now(),row.due_date);var status=lCase(toString(row.status));if(status!="paid"&&status!="disputed"){if(row.paid_amount>0)status="partial";else if(days<0)status="overdue";else if(days<=7)status="due_soon";else status="open";}output.append({id:toString(row.id),invoiceNumber:row.invoice_number,customerId:toString(row.customer_id),customerName:row.customer_name,amount:row.total_amount,paidAmount:row.paid_amount,outstanding:row.balance_amount,issueDate:dateFormat(row.issue_date,"yyyy-mm-dd"),dueDate:due,description:row.notes?:"",purchaseOrder:row.purchase_order?:"",owner:"Alex Morgan",promiseDate:row.promise_date?:"",promiseNote:row.promise_note?:"",statusOverride:status=="disputed"?"disputed":"",disputeReason:row.dispute_reason?:"",reminderCount:row.reminder_count,lastContactAt:row.last_contact_at?:"",paidAt:row.paid_at?:"",paymentRef:row.payment_ref?:"",portalToken:"",daysUntilDue:days,daysOverdue:days<0?abs(days):0,paymentPercent:row.total_amount?round(row.paid_amount/row.total_amount*100):0,status:status});}return output;}

	private void function assertOpen(required string invoiceId){var result=run("SELECT balance_amount FROM invoices WHERE id=:invoiceId AND workspace_id=:workspaceId",invoiceParams(arguments.invoiceId));if(!result.recordCount)throw(type="DuePilot.InvoiceNotFound",message="Invoice not found.");if(result.balance_amount[1]<=0)throw(type="DuePilot.AlreadyPaid",message="This invoice is already fully paid.");}
	private void function activity(required string invoiceId,required string kind,required string summary,struct detail={}){run("INSERT INTO collection_activities(workspace_id,invoice_id,activity_type,channel,summary,detail,created_by) VALUES(:workspaceId,:invoiceId,:kind,:channel,:summary,cast(:detail as jsonb),:actor)",{workspaceId:{value:workspaceId(),sqltype:"varchar"},invoiceId:{value:arguments.invoiceId,sqltype:"varchar"},kind:{value:arguments.kind,sqltype:"varchar"},channel:{value:arguments.detail.channel?:"",sqltype:"varchar",null:!structKeyExists(arguments.detail,"channel")},summary:{value:arguments.summary,sqltype:"varchar"},detail:{value:serializeJSON(arguments.detail),sqltype:"varchar"},actor:{value:actorId(),sqltype:"varchar"}});}
	private string function actorId(){if(structKeyExists(session,"user")&&structKeyExists(session.user,"id")&&isValid("uuid",session.user.id))return session.user.id;var result=run("SELECT user_id FROM workspace_members WHERE workspace_id=:workspaceId AND status='active' ORDER BY joined_at LIMIT 1",pWorkspace());if(!result.recordCount)throw(type="DuePilot.ActorNotFound",message="No active workspace member is available.");return toString(result.user_id[1]);}
	private struct function pWorkspace(){return {workspaceId:{value:workspaceId(),sqltype:"varchar"}};}
	private struct function invoiceParams(required string invoiceId){return {workspaceId:{value:workspaceId(),sqltype:"varchar"},invoiceId:{value:arguments.invoiceId,sqltype:"varchar"}};}
	private string function initials(required string value){var parts=listToArray(trim(arguments.value)," ");return uCase(left(parts[1],1)&(parts.len()>1?left(parts[parts.len()],1):""));}
	private string function textValue(required any value){if(isStruct(arguments.value)&&structKeyExists(arguments.value,"Value"))return toString(arguments.value.Value);try{return toString(arguments.value.getValue());}catch(any ignored){}return toString(arguments.value);}
}
