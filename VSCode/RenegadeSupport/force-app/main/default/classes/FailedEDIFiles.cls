@RestResource(urlMapping='/Failed/*')
global class FailedEDIFiles {

	@HttpPost  
	global static Response getFailed() {
		try{
			
			string xmlInput = RestContext.request.requestBody.toString();
			string poName = xmlInput.split('document id="')[1].split('"')[0].split(' ').size () > 1 ? xmlInput.split('document id="')[1].split('"')[0].split(' ')[1] : xmlInput.split('document id="')[1].split('"')[0];
			system.debug('xmlInput = ' + xmlInput);
			Purchase_Order__c po = [select id, EDI_Status__c from Purchase_Order__c where name = :poName];
			po.EDI_Status__c = 'Failed';
			update po;
			system.debug('po = ' + po);
			Log__c log = [select ID, Status__c from Log__c where Object_ID__c = :po.id and Status__c = 'Sent'];
			system.debug('log = ' + log);
			log.Status__c = 'Failed';
			update log;
		}
		catch (exception e){
			system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getlinenumber());
			return new Response(false, e.getmessage() + ' ' + e.getlinenumber());
		}
		return new Response(true, '');
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