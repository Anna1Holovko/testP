global with sharing class FinanceIntegrationManager {

	public static Response capture(string transactionId){
	    Finance_Setting__c setting = Finance_Setting__c.getInstance();
        HttpRequest req = new HttpRequest();
        Response res = new Response();
        try
        {
            req.setEndpoint(setting.URL__c + transactionId + '/settles');
            
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Authorization', 'Bearer ' + setting.Private_Key__c);
            req.setHeader('Content-Length', '0');
            system.debug('req ' + req);
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug('response' + response);
            system.debug('***mapBody' + response.getBody());
            Map<String, Object> mapBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if ((string)mapBody.get('id') != null){
            	res.id = (string)mapBody.get('id');
            	res.chargeId = (string)mapBody.get('chargeId');
            }
            else {
            	res.message = (string)mapBody.get('message');
            }
        }
        catch(Exception e)
        {
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause();
        }
		
		return res;
	}
	
	
	public static Response voidWithChargeId(string chargeId){
	    Finance_Setting__c setting = Finance_Setting__c.getInstance();
        HttpRequest req = new HttpRequest();
        Response res = new Response();
        try
        {
            req.setEndpoint(setting.URL__c + chargeId + '/voids');
            
            req.setMethod('POST');
             
            req.setHeader('Authorization', 'Bearer ' + setting.Private_Key__c);
            req.setHeader('Content-Length', '0');
            system.debug('req ' + req);
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug('response' + response);
            system.debug('response.getBody()' + response.getBody());
            system.debug('***mapBody' + response.getBody());
            Map<String, Object> mapBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if ((string)mapBody.get('id') != null){
            	res.id = (string)mapBody.get('id');
            	res.chargeId = (string)mapBody.get('chargeId');
            }
            else {
            	res.message = (string)mapBody.get('message');
            }
        }
        catch(Exception e)
        {
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause();
        }
		return res;
	}
	
	global class Response{
		public string updatedAt {get; set;}
		public string createdAt {get; set;}
		public string id {get; set;}
		public string chargeId {get; set;}
		
		public string message {get; set;}
		public string code {get; set;}

	}
}