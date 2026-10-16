<cfscript>
function dpMoney( required numeric amount ){
	return "INR " & numberFormat( arguments.amount, ",999" );
}

function dpStatusLabel( required string status ){
	var labels = {
		paid     : "Paid",
		partial  : "Part paid",
		overdue  : "Overdue",
		due_soon : "Due soon",
		disputed : "Disputed",
		open     : "Open"
	};
	return labels.keyExists( arguments.status ) ? labels[ arguments.status ] : arguments.status;
}

function dpStatusClass( required string status ){
	var classes = {
		paid     : "success",
		partial  : "info",
		overdue  : "danger",
		due_soon : "warning",
		disputed : "purple",
		open     : "neutral"
	};
	return classes.keyExists( arguments.status ) ? classes[ arguments.status ] : "neutral";
}

function dpDueLabel( required struct invoice ){
	if ( invoice.status == "paid" ) return "Paid";
	if ( invoice.daysOverdue > 0 ) return "#invoice.daysOverdue# days overdue";
	if ( invoice.daysUntilDue == 0 ) return "Due today";
	return "Due in #invoice.daysUntilDue# days";
}
</cfscript>
