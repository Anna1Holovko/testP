global with sharing class AffirmIntagrationManager {

	public static Response captureWithChargeId(string chargeId, Request requestClass, String accountType){
	    AffirmTokens__c setting = AffirmTokens__c.getInstance();
        HttpRequest req = new HttpRequest();
        Response res = new Response();
        String responseBody = '';
        try
        {
            req.setEndpoint(setting.Endpoint__c + chargeId + '/capture');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/oauth2/token');  
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            Blob headerValue = createBlobData(JSON.serialize(setting), accountType);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            system.debug('***:' + EncodingUtil.base64Encode(headerValue));
            req.setHeader('Authorization', authorizationHeader);
            req.setBody(JSON.serialize(requestClass));
            res = responseHandle(req);
        }
        catch(Exception e)
        {
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause();// + '\n Response: ' + responseBody;
        }
		return res;
	}
	
	
	public static Response voidWithChargeId(string chargeId, String accountType){
	    AffirmTokens__c setting = AffirmTokens__c.getInstance();
        HttpRequest req = new HttpRequest();
        Response res = new Response();
        //String responseBody = '';
        try
        {
            req.setEndpoint(setting.Endpoint__c + chargeId + '/void');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/oauth2/token');
            
            req.setMethod('POST');
            Blob headerValue = createBlobData(JSON.serialize(setting), accountType);
            
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);
            
            res = responseHandle(req);
        }
        catch(Exception e)
        {
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause();// + '\n Response: ' + responseBody ;
        }
		return res;
    }

    public static Response voidZibbyWithChargeId(string chargeId, String accountType){
	    ZibbyByAffirmTokens__c setting = ZibbyByAffirmTokens__c.getInstance();
        HttpRequest req = new HttpRequest();
        Response res = new Response();
        //String responseBody = '';
        try
        {
            req.setEndpoint(setting.Endpoint__c + chargeId + '/void');
            req.setMethod('POST');
            Blob headerValue = createBlobData(JSON.serialize(setting), accountType);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);
            res = responseHandle(req);
        }
        catch(Exception e)
        {
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause();// + '\n Response: ' + responseBody ;
        }
		return res;
    }

    public static Response captureZibbyByAffirm(String chargeId, Request requestClass, String accountType){
        Response res = new Response();
        try{
            ZibbyByAffirmTokens__c setting = ZibbyByAffirmTokens__c.getInstance();
            HttpRequest req = new HttpRequest();

            req.setEndpoint(setting.Endpoint__c + chargeId + '/capture');
            //req.setEndpoint('https://sandbox.affirm.com/api/v1/transactions/'+ chargeId + '/capture');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(createBlobData(JSON.serialize(setting), accountType));
            req.setHeader('Authorization', authorizationHeader);
            req.setBody(JSON.serialize(requestClass));
            res = responseHandle(req);

        }catch(Exception e){
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause()  ;//+ '\n Response: ' + responseBody
        }
        return res;
    }
    
    static Blob createBlobData(String JSONsetting, String accountType){
        Map<String, Object> setting = (Map<String, Object>) JSON.deserializeUntyped(JSONsetting);
        Blob headerValue;
        if(accountType == '1' || accountType == null){
            headerValue = Blob.valueOf(setting.get('Public_key__c')+':'+setting.get('Private_key__c'));
        }else if(accountType == '2'){
            headerValue = Blob.valueOf(setting.get('Furniture_ETC_Public_key__c')+':'+setting.get('Furniture_ETC_Private_key__c'));
        }else if(accountType == '3'){
            headerValue = Blob.valueOf(setting.get('Home_gallery_stores_Public_key__c')+':'+setting.get('Home_gallery_stores_Private_key__c'));
        }
        return headerValue;
    }

    public static Response responseHandle(HttpRequest req){
        Response res = new Response();
        String responseBody='';
        try{
            Http http = new Http();
            HttpResponse response = http.send(req);
            responseBody = response.getBody();
            Map<String, Object> mapBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            if ((string)mapBody.get('id') != null){
                res.id = (string)mapBody.get('id');
                res.transaction_id = (mapBody.containsKey('transaction_id') ? (string)mapBody.get('transaction_id') : '');
            }
            else {
                res.message = (string)mapBody.get('message');
            }
        }catch(Exception e){
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
            res.message = 'Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause()  ;//+ '\n Response: ' + responseBody
        }
		return res;
    }

	
	global class Request{
		public string order_id {get; set;}
		// public string shipping_carrier {get; set;}
		// public string shipping_confirmation {get; set;}
		
		public Request(string order_id, string shipping_carrier, string shipping_confirmation){
			this.order_id = order_id;
			// this.shipping_carrier = shipping_carrier;
			// this.shipping_confirmation = shipping_confirmation;
		}
	}
	
	global class Response{
		//public string fee {get; set;}
		//public string created {get; set;}
		//public string currency {get; set;}
		//public integer amount {get; set;}
		//public string type {get; set;}
		public string id {get; set;}
		public string transaction_id {get; set;}
		
		public string status_code {get; set;}
		public string message {get; set;}
		public string code {get; set;}

	}
}