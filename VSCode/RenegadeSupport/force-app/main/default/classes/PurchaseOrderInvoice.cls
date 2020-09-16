@RestResource(urlMapping='/Invoice/*')
global class PurchaseOrderInvoice {

	@HttpPost  
	global static Response getPurchaseOrderInvoice() {
		string advanceInvoice = RestContext.request.requestBody.toString();
		string document_id = 'Invoice';
		system.debug('xmlInput = ' + advanceInvoice);
		list<Log__c> logs;
		try{
			Dom.Document doc = new Dom.Document();
			doc.load(advanceInvoice);
			for(Dom.XmlNode node :doc.getRootElement().getChildElements()){
			    if (node.getName() == 'Invoice'){
            		for(Dom.XmlNode innerNode :node.getChildElements()){
            			if (node.getName() == 'InvoiceHeader'){
            				//Get SHLs IDs
            			}
            		}
			    }
			}
			logs = [select Object_ID__c, Tries__c, Process__c, Data__c, Status__c, Error__c from Log__c where Object_ID__c = :document_id];
			try {
                //System.debug('poNames '+poNames);
				//get SHLs
			}
			catch(exception ex){
				Log__c log = new Log__c(Object_ID__c = document_id, Process__c = 'EDI - Invoice', Data__c = advanceInvoice, Tries__c = 1, Status__c = 'Failed', Error__c = 'Can not find the SHL');
				if (logs.size() > 0){
					log.Tries__c = logs[0].Tries__c + 1;
					log.id = logs[0].id;
				}
				upsert log;
				system.debug('ex.getmessage() = ' + ex.getmessage() + ' ' + ex.getlinenumber());
				//return new Response(true, '');
			}

			/* Update SHL
			for (Purchase_Order__c po : pos){
				po.Status__c = 'Shipped';
				po.Load_Date_Actual__c = system.today();
				posByNameMap.put(po.name, po);
			}
			update pos;*/
		}
		catch (exception e){
			Log__c log = new Log__c(Object_ID__c = document_id, Process__c = 'EDI - Invoice', Data__c = advanceInvoice, Tries__c = 1, Status__c = 'Failed', Error__c = e.getmessage() + ' ' + e.getlinenumber());
			if (logs.size() > 0){
				log.Tries__c = logs[0].Tries__c + 1;
				log.id = logs[0].id;
			}
			upsert log;
			system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getlinenumber());
			return new Response(false, e.getmessage() + ' ' + e.getlinenumber());
		}
		Log__c log = new Log__c(Object_ID__c = document_id, Process__c = 'EDI - Invoice', Data__c = advanceInvoice, Tries__c = 1, Status__c = 'Succeeded');
		if (logs.size() > 0){
			log.Tries__c = logs[0].Tries__c + 1;
			log.id = logs[0].id;
		}
		upsert log;
		//return new Response(true, '');
		return new Response(false, '');
	}
	
	global class Response{
		public boolean success {get; set;}
		public string message {get; set;}
		
		public Response(){
			
		}
		
		public Response(boolean success, string message){
			this.success = success;
			this.message = message;
		}
	}
}