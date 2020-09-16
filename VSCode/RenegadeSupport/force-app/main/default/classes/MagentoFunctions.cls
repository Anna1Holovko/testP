public class MagentoFunctions{
    
   /* private String token;
    private String tokenSecret;
    
    private String nonce;
    private String timestamp;
    private String signature;
    private String consumerKey;
    private String consumerSecret;
    
    private Map<String,String> parameters = new Map<String,String>();
   
    public string executeRestFunction(String endpoint, String method,Map<String,String> params,string body,string requestType)
    {
        string customerID='';
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        string endpointTemp=req.getEndpoint();
        HttpResponse res = null;
        if(requestType=='Customer')
        {
            string nonce=generateRandomString(6);
            String timestamp = String.valueOf(DateTime.now().getTime()/1000);
            endpoint='http://colemanfurniture.com/api/rest/customers';
            String signature =generateSignature('POST',endpoint,nonce, timestamp);
            
            string resultHeader = 'OAuth realm="https%3A%2F%2Fc.na24.visual.force.com%2Fapex%2FCompleteAuth",oauth_consumer_key="zv19krmu79fqjpljzvgwny5wino9p5rf",oauth_token="m4tfy4qbr2swujg77mcysilr3jh3jxwg",oauth_signature_method="HMAC-SHA1",oauth_timestamp="' + timestamp + '",'+'oauth_nonce="'+nonce+'",oauth_version="1.0"'+',oauth_signature="'+signature+'"';
            
            req.setMethod('POST');
            req.setHeader('Authorization', resultHeader);
            req.setHeader('Content-Type','application/json');
            req.setBody(body);  
            req.setEndpoint(endpoint);
            
            if(!Test.isRunningTest())
            {
                res = h.send(req);
            }
            else
            {
                res=new HttpResponse();
                res.setStatusCode(301);
                res.setBody('{}');
                res.setHeader('Location',' /api/rest/customers/123456');
            }
            
            system.debug('req Method'+req.getMethod());
            system.debug('req'+req);
            System.debug('Request header set to: '+req.getHeader('Authorization'));
            system.debug('The endpoint is ' + req.getEndpoint());
            system.debug('Response '+res);
            
            if(res.getStatusCode()>300 && res.getStatusCode()<315) 
            {
                String loc = res.getHeader('Location');
                system.debug('loc '+loc);
                system.debug('loc '+loc.remove('/api/rest/customers/'));
                customerID=loc.remove('/api/rest/customers/');
              system.debug('customerID '+customerID);
                endpointTemp=endpoint+'/'+customerID; 
                system.debug('location '+endpointTemp);
                if(loc <> null) 
                {
                    req = new HttpRequest();
                    nonce=generateRandomString(6);
                    timestamp = String.valueOf(DateTime.now().getTime()/1000);
                    signature =generateSignature('GET',endpointTemp,nonce, timestamp);
                    resultHeader = 'OAuth realm="https%3A%2F%2Fc.na24.visual.force.com%2Fapex%2FCompleteAuth",oauth_consumer_key="zv19krmu79fqjpljzvgwny5wino9p5rf",oauth_token="m4tfy4qbr2swujg77mcysilr3jh3jxwg",oauth_signature_method="HMAC-SHA1",oauth_timestamp="' + timestamp + '",'+'oauth_nonce="'+nonce+'",oauth_version="1.0"'+',oauth_signature="'+signature+'"';
                    req.setHeader('Authorization', resultHeader);
                    req.setEndpoint(endpointTemp);
                    req.setMethod('GET');
                    if(!Test.isRunningTest())
                    {
                        res = h.send(req);
                    }
                    system.debug('getStatusCode '+res.getStatusCode());
                    system.debug('res '+res.getBody());
                
               } 
        }
     
        }   
        else if(requestType=='address')
        {
            nonce=generateRandomString(6);
            timestamp = String.valueOf(DateTime.now().getTime()/1000);
            signature =generateSignature('POST',endpoint,nonce, timestamp);
            
            string resultHeader = 'OAuth realm="https%3A%2F%2Fc.na24.visual.force.com%2Fapex%2FCompleteAuth",oauth_consumer_key="zv19krmu79fqjpljzvgwny5wino9p5rf",oauth_token="m4tfy4qbr2swujg77mcysilr3jh3jxwg",oauth_signature_method="HMAC-SHA1",oauth_timestamp="' + timestamp + '",'+'oauth_nonce="'+nonce+'",oauth_version="1.0"'+',oauth_signature="'+signature+'"';
            req.setMethod('POST');
            req.setHeader('Authorization', resultHeader);
            req.setHeader('Content-Type','application/json');
            req.setBody(body);  
            req.setEndpoint(endpoint);
            
            if(!Test.isRunningTest())
            {
                res = h.send(req);
            }
            else
            {
                res=new HttpResponse();
                res.setStatusCode(1);
                res.setBody('{}');
            }
            system.debug('req Method'+req.getMethod());
            system.debug('req'+req);
            System.debug('Request header set to: '+req.getHeader('Authorization'));
            system.debug('The endpoint is ' + req.getEndpoint());
            system.debug('Response '+res);
            system.debug('Response Body '+res.getBody());
            
            if(res.getStatusCode()>300 && res.getStatusCode()<315) 
            {
                String loc = res.getHeader('Location');
                system.debug('loc '+loc);
                system.debug('loc '+loc.remove('/api/rest/customers/'));
                customerID=loc.remove('/api/rest/customers/');
                system.debug('customerAddress ID '+customerID);
                
            }
            
            } 
        return customerID;      
    } 
    
    public string  createNewCustomerInMagento(string body)
    {
        MagentoAuth__c magentoAuth = MagentoAuth__c.getInstance('MagentoOAuth');
        
        system.debug('customerRequest '+body);
        if(magentoAuth == null)
        {
            throw new MagentoAuthException('Magento Auth not set | Please contact system admin');
        }
        
        String endpoint = magentoAuth.RestEndpoint__c + '/customers';
        
      //HttpResponse res = executeRestFunction(endpoint,'POST',null,body,'Customer');
         string res = executeRestFunction(endpoint,'POST',null,body,'Customer');
        
        if(test.isRunningTest())
        {
            res='test';
          /*  res=new HttpResponse();
            res.setStatusCode(1);
            res.setBody('{}');
        }
      //  String responseBody = res.getBody();
        //MagentoCustomerParser ResponseObject=MagentoCustomerParser.parse(responseBody);
        //system.debug('ResponseObject '+ResponseObject);
        
        return res;
    }
    
    public void createCustomerAddress(string body,string customerID)
    {
        MagentoAuth__c magentoAuth = MagentoAuth__c.getInstance('MagentoOAuth');
        
        system.debug('customerRequest '+body);
        if(magentoAuth == null){
            throw new MagentoAuthException('Magento Auth not set | Please contact system admin');
        }
        String endpoint = magentoAuth.RestEndpoint__c + '/customers/'+customerID+'/addresses';
      string res= executeRestFunction(endpoint,'POST',null,body,'address');
    }
    
    public String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    public string generateSignature(string method,string endpoint,string nonce, string timestamp)
    {
        string HTTPmethod=method; 
        string URL=endpoint;//'http://colemanfurniture.com/api/rest/customers';
        string oauth_nonce= 'oauth_nonce=' + nonce;
        string oauth_signature_method='oauth_signature_method=HMAC-SHA1';
        string oauth_timestamp='oauth_timestamp=' + timestamp;
        string oauth_version='oauth_version=1.0';
        string oauth_consumer_key='oauth_consumer_key=zv19krmu79fqjpljzvgwny5wino9p5rf';
        string oauth_token='oauth_token=m4tfy4qbr2swujg77mcysilr3jh3jxwg';
        string baseoauthString = oauth_consumer_key + '&' + oauth_nonce + '&' + oauth_signature_method + '&' + oauth_timestamp + '&' + oauth_token + '&' + oauth_version;
        baseoauthstring =encodingUtil.urlEncode(baseoauthstring, 'UTF-8');
        string basestring =EncodingUtil.urlEncode(HTTPmethod,'UTF-8')+'&'+EncodingUtil.urlEncode(URL, 'UTF-8')+'&' + baseoauthstring;
        system.debug('basestring '+basestring);
        
        string key='2agp266zrkl0arus9l2eotchv2bw9wl8&72tsv9h35hpwd84g8xvj1cxixqwk0e91'  ;
        blob sig=Crypto.generateMac('HMAC-SHA1', blob.valueOf(basestring), blob.valueOf(key));
        
        System.debug('base64: '+EncodingUtil.base64encode(sig));
        
        string signature =EncodingUtil.base64encode(sig); //EncodingUtil.urlEncode(EncodingUtil.base64encode(sig), 'UTF-8');
        System.debug('Signature: '+signature);
        return signature;
    }*/
}