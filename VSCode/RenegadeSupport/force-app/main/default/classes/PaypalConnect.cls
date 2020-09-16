/*
*   Author : Pavan Vuppala | Kairos Tech
*   Class  : AuthorizeDotNetFunctions
*   Purpose: This class is used to call third party Paypal and will call from Salesforce.
*/
public class PaypalConnect 
{
    public String access_token;
    public Paypal_OAuth__c paypalObj=Paypal_OAuth__c.getinstance('Auth');
    

    Public PaypalConnect(){
        this(null);
       
    } 
    Public PaypalConnect(String accountType) 
    {
            system.debug('***accountType:' + accountType);
        if(accountType == '1' || accountType == null){
            paypalObj = Paypal_OAuth__c.getinstance('Auth');
        }else if(accountType == '2'){
            paypalObj = Paypal_OAuth__c.getinstance('Furniture ETC Auth');
        }
        HttpRequest req = new HttpRequest();
        try
        {
            system.debug('***paypalObj:' + paypalObj);
            req.setEndpoint(paypalObj.EndPoint__c+'/v1/oauth2/token');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/oauth2/token');
            
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Accept-Language', 'en_US');
            
            Blob headerValue = Blob.valueOf(paypalObj.Client_ID__c+':'+paypalObj.Client_Secret__c); //clientId:secret replaced with my paypal org creds
            //Blob headerValue = Blob.valueOf('ASohvIUu78cjMNw0DaL9dbeCqFxHOisqgt6rh-6s2xgaNz2mnfkS9WMDRxhVs98fUlsdbccKAxBPMk_y:EGjVPrG45JUuS46gc5rljENw_3aQq3S5uYL1fKcMelqLcZLf4jgkEAg2JUj0hsx2_MbEF3PlbJwCFVzT'); //clientId:secret replaced with my paypal org creds
            
            system.debug('***Header:' + headerValue);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            system.debug('***:' + EncodingUtil.base64Encode(headerValue));
            req.setHeader('Authorization', authorizationHeader);
            req.setBody('grant_type=client_credentials');
            system.debug('req ' + req);
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug('***mapBody' + response.getBody());
            Map < String, Object > mapBody = (Map < String, Object > ) JSON.deserializeUntyped(response.getBody());
            access_token = (String) mapBody.get('access_token');
            Integer expires_in = Integer.valueOF(mapBody.get('expires_in'));
            system.debug('***access_token' + access_token);
            system.debug('***expires_in' + expires_in);
            //authorizePayment(access_token,line,city,state,postal_code,number1,type,expire_month,expire_year,cvv,fname,lname,subtotal,tax,total);
        }
        catch(Exception e)
        {
            system.debug('Exception: Message - '+e.getMessage()+' Line number - '+e.getLineNumber()+' Cause - '+e.getCause());
        }
    }
    /*
    public payPalResponse authorizePayment(string line,string city,string state,string postal_code,string number1,
                                           string type, integer expire_month,integer expire_year,string cvv,string fname,
                                           string lname,string subtotal,string tax,string total) 
    {
        
        payPalResponse responseObject=new payPalResponse();
        
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint(paypalObj.EndPoint__c+'/v1/payments/payment');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/payments/payment');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept-Language', 'en_US');
            req.setHeader('Accept', 'application/json');
            // req.setHeader('intent', 'authorize');
            String bToke = 'Bearer ' + access_token;
            req.setHeader('Authorization', bToke);
            String s = createPayment.generateJSONContent(line,city,state,postal_code,number1,type,expire_month,expire_year,cvv,fname,lname,subtotal,tax,total);
            system.debug('***s:' + s);
            req.setBody(s);
            Http http = new Http();
            req.setTimeout(60000); 
            HttpResponse response = http.send(req);
            system.debug('***mapBody' + response.getBody());
            string responsetext =response.getBody();
            system.debug('****serialized:' + responsetext);
            responsetext = responsetext.replace('"currency":', '"currency1":');
            responsetext = responsetext.replace('"number":', '"number1":');
            responsetext=responsetext.replace('"card":', '"card1":');
            
            system.debug('****replaced:' + responsetext);
            
            PaypalExceptionParser exceptionObject=PaypalExceptionParser.parse(responsetext);
            if(exceptionObject.name!=null)
            { 
                system.debug('PaypalExcep '+exceptionObject);
                throw new payPalException(exceptionObject.name+' - '+exceptionObject.message);
            }
            else   
                responseObject=payPalResponse.parse(responsetext);
            
        }
        catch(Exception e)
        {
            system.debug('Exception '+e);
            responseObject=null;
        }
        return responseObject; 
    }
    */
    public payPalResponse capturePayment(string total,string TransactionId)
    {
        payPalResponse responseObject=new payPalResponse();
        try
        {
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint(paypalObj.EndPoint__c+'/v1/payments/authorization/'+TransactionId+'/capture');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/payments/authorization/'+TransactionId+'/capture');
            
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept-Language', 'en_US');
            req.setHeader('Accept', 'application/json');
            String bToke = 'Bearer ' + access_token;
            req.setHeader('Authorization', bToke);
            String s = CapturePayment.generateJSONContent(total);
            system.debug('***s:' + s);
            req.setBody(s);
            req.setTimeout(60000); 
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug('***mapBody' + response.getBody());
            string responsetext =response.getBody();
            system.debug('****serialized:' + responsetext);
            responsetext = responsetext.replace('"currency":', '"currency1":');
            responsetext = responsetext.replace('"number":', '"number1":');
            responsetext=responsetext.replace('"card":', '"card1":');
            responseObject.response = response.getBody();
            system.debug('****replaced:' + responsetext);
            
            PaypalExceptionParser exceptionObject=PaypalExceptionParser.parse(responsetext);
            if(exceptionObject.name!=null)
            { 
                system.debug('PaypalExcep '+exceptionObject);
            	responseObject.error = exceptionObject.name+' - '+exceptionObject.message;
                //throw new payPalException(exceptionObject.name+' - '+exceptionObject.message);
            }
            else
                responseObject=payPalResponse.parse(responsetext);
        }
        catch(Exception e)
        {
            responseObject.error = e.getmessage()+' - '+e.getlinenumber();
            system.debug('Exception '+e);
            //responseObject=null;
        }
        return responseObject;
    }
    
    public payPalResponse refundPayment(string CaptureTransactionId,string refundAmount,string currencyType)
    {
        payPalResponse responseObject=new payPalResponse();
        
        try{
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint(paypalObj.EndPoint__c+'/v1/payments/capture/'+CaptureTransactionId+'/refund');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/payments/capture/'+CaptureTransactionId+'/refund');
            
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept-Language', 'en_US');
            req.setHeader('Accept', 'application/json');
            String bToke = 'Bearer ' + access_token;
            req.setHeader('Authorization', bToke);
            String s = RefundPayment.generateJSONContent(refundAmount,currencyType);
            system.debug('***s:' + s);
            req.setBody(s);
            req.setTimeout(30000); 
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug('***mapBody' + response.getBody());
            string responsetext =response.getBody();
            system.debug('****serialized:' + responsetext);
            responsetext = responsetext.replace('"currency":', '"currency1":');
            responsetext = responsetext.replace('"number":', '"number1":');
            responsetext=responsetext.replace('"card":', '"card1":');
            
            system.debug('****replaced:' + responsetext);
            PaypalExceptionParser exceptionObject=PaypalExceptionParser.parse(responsetext);
            if(exceptionObject.name!=null)
            { 
                system.debug('PaypalExcep '+exceptionObject);
                throw new payPalException(exceptionObject.name+' - '+exceptionObject.message);
            }
            else
                
                responseObject=payPalResponse.parse(responsetext);
        }
        catch(Exception e)
        {
            system.debug('Exception '+e);
            responseObject=null;
        }
        
        return responseObject;
    }
    
    public payPalResponse voidPayment(string AuthorizationTransactionID)
    { 
        payPalResponse responseObject=new payPalResponse();
        try{
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint(paypalObj.EndPoint__c+'/v1/payments/authorization/'+AuthorizationTransactionID+'/void');
            //req.setEndpoint('https://api.sandbox.paypal.com/v1/payments/authorization/'+AuthorizationTransactionID+'/void');
            
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept-Language', 'en_US');
            req.setHeader('Accept', 'application/json');
            String bToke = 'Bearer ' + access_token;
            req.setHeader('Authorization', bToke);
            //string s;
            //req.setBody(s);
            req.setTimeout(30000); 
            system.debug(' pay pal req ' + req);
            Http http = new Http();
            HttpResponse response = http.send(req);
            system.debug('***mapBody' + response.getBody());
            string responsetext =response.getBody();
            system.debug('****serialized:' + responsetext);
            PaypalExceptionParser exceptionObject=PaypalExceptionParser.parse(responsetext);
            if(exceptionObject.name!=null)
            { 
                system.debug('PaypalExcep '+exceptionObject);
                throw new payPalException(exceptionObject.name+' - '+exceptionObject.message);
            }
            else
                system.debug('else - responsetext '+responsetext);
            
            responseObject=payPalResponse.parse(responsetext);
        }
        catch(Exception e)
        {
            system.debug('Exception '+e);
            responseObject=null;
        }
        return responseObject;
        
    }
}