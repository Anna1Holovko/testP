/*
*   Author : Pavan Vuppala | Kairos Tech
*   Class  : AuthorizeDotNetFunctions
*   Purpose: This class is used to call third party authorization and will call from Salesforce.
*/
public class AuthorizeDotNetFunctions
{
    public String customerProfileId {get;set;}
    public String customerPaymentProfileId {get;set;}
    public String transactionId {get;set;}
    public boolean isExistingCustomerProfile =false;
    public boolean isExistingPaymentProfile =false;
    
    public void createCustomerAndPaymentProfiles(String customerEmailAddress,String firstName, String lastName, String address, String city, String state, String zipcode, String country, String cardNumber, String expirationDate, String cardCode)
    {
        try{
            AuthorizeDotNetTokens__c tokenVar = AuthorizeDotNetTokens__c.getValues('Auth');
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'createCustomerProfileRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            w.writeCharacters(tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_Cust&PayProfiles');
            w.writeEndElement();
            
            w.writeStartElement(null,'profile',null);
            w.writeStartElement(null,'description',null);
            w.writeCharacters('Customer Email' + customerEmailAddress);
            w.writeEndElement();
            w.writeStartElement(null,'email',null);
            w.writeCharacters(customerEmailAddress);
            w.writeEndElement(); 
            
            w.writeStartElement(null,'paymentProfiles',null);
            w.writeStartElement(null,'billTo',null);
            w.writeStartElement(null,'firstName',null);
            w.writeCharacters(firstName);
            w.writeEndElement();
            w.writeStartElement(null,'lastName',null);
            w.writeCharacters(lastName);
            w.writeEndElement();
            w.writeStartElement(null,'address',null);
            w.writeCharacters(address);
            w.writeEndElement();
            w.writeStartElement(null,'city',null);
            w.writeCharacters(city);
            w.writeEndElement();
            w.writeStartElement(null,'state',null);
            w.writeCharacters(state);
            w.writeEndElement();
            w.writeStartElement(null,'zip',null);
            w.writeCharacters(zipCode);
            w.writeEndElement();
            w.writeStartElement(null,'country',null);
            w.writeCharacters(country);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'payment',null);
            w.writeStartElement(null,'creditCard',null);
            w.writeStartElement(null,'cardNumber',null);
            w.writeCharacters(cardNumber);
            w.writeEndElement();
            w.writeStartElement(null,'expirationDate',null);
            w.writeCharacters(expirationDate);
            w.writeEndElement();
            w.writeStartElement(null,'cardCode',null);
            w.writeCharacters(cardCode);
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            w.writeStartElement(null,'validationMode',null);
            w.writeCharacters('liveMode'); 
            w.writeEndElement();
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            Dom.XMLNode messages = xmlResponse.getChildElement('messages','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            if(resultCode == 'Error')
            {
                //throw new AuthorizeDotNetException('A profile with this ID already exists');
                system.debug('doc '+doc);
                system.debug('xmlResponse '+xmlResponse);
                String xmlResponse1 = xmlResponse.getChildElement('messages',namespace).getText();    
                
                system.debug('xmlResponse1 '+xmlResponse1);
                
                xmlResponse1 = xmlResponse1.replace('"-xmlns:xsi":', '"xmlnsxsi":');
                xmlResponse1 = xmlResponse1.replace('"-xmlns:xsd":', '"xmlnsxsd":');
                xmlResponse1 = xmlResponse1.replace('"-xmlns":', '"xmlns":'); 
                
                AuthorizeDotNetError.parse(xmlResponse1);
                
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                
                system.debug('code '+code);
                
                if(code=='E00039')
                {
                    String rawProfileText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                    if(rawProfileText <> null)
                    {
                        Pattern patternVar = Pattern.compile('(A duplicate record with ID )(\\d+)( already exists.)');
                        Matcher matcherVar = patternVar.matcher(rawProfileText);
                        if( matcherVar.matches())
                        {
                            System.debug('CustomerProfileID : '+matcherVar.group(2));  
                            customerProfileId=matcherVar.group(2);
                            isExistingCustomerProfile=true;
                        } 
                    }
                    else
                    {
                        String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                        throw new AuthorizeDotNetException(errorText);
                    } 
                }
                else
                {
                    String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                    System.debug('errorText is ' + errorText );
                    throw new AuthorizeDotNetException(errorText);
                }    
            }
            else if(resultCode == 'Ok'){
                
                customerProfileId = xmlResponse.getChildElement('customerProfileId',namespace).getText(); 
                customerPaymentProfileId = xmlResponse.getChildElement('customerPaymentProfileIdList',namespace).getChildElement('numericString',namespace).getText();
            }
            System.debug('cust prof id is ' + customerProfileId );
            System.debug('cust payment prof id is ' + customerPaymentProfileId );
        } 
        catch(AuthorizeDotNetException ae)
        {
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            throw ae;
        }
        catch(Exception ae)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Card Information-('+ae.getLineNumber()+' '+ae.getMessage()+')'));
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
        }        
    }
    
    public void createCustomerPaymentProfile(String customerProfileId,String firstName, String lastName, String address, String city, String state, String zipCode, String country, String cardNumber, String expirationDate, String cardCode)
    {
        try
        {
            AuthorizeDotNetTokens__c tokenVar=AuthorizeDotNetTokens__c.getValues('Auth');   
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'createCustomerPaymentProfileRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            w.writeCharacters(tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_PayProfiles');
            w.writeEndElement();
            
            
            w.writeStartElement(null,'customerProfileId',null);
            w.writeCharacters(customerProfileId);
            w.writeEndElement();
            
            w.writeStartElement(null,'paymentProfile',null);
            w.writeStartElement(null,'billTo',null);
            w.writeStartElement(null,'firstName',null);
            w.writeCharacters(firstName);
            w.writeEndElement();
            w.writeStartElement(null,'lastName',null);
            w.writeCharacters(lastName);
            w.writeEndElement();
            w.writeStartElement(null,'address',null);
            w.writeCharacters(address);
            w.writeEndElement();
            w.writeStartElement(null,'city',null);
            w.writeCharacters(city);
            w.writeEndElement();
            w.writeStartElement(null,'state',null);
            w.writeCharacters(state);
            w.writeEndElement();
            w.writeStartElement(null,'zip',null);
            w.writeCharacters(zipCode);
            w.writeEndElement();
            w.writeStartElement(null,'country',null);
            w.writeCharacters(country);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'payment',null);
            w.writeStartElement(null,'creditCard',null);
            w.writeStartElement(null,'cardNumber',null);
            w.writeCharacters(cardNumber);
            w.writeEndElement();
            w.writeStartElement(null,'expirationDate',null);
            w.writeCharacters(expirationDate);
            w.writeEndElement();
            w.writeStartElement(null,'cardCode',null);
            w.writeCharacters(cardCode);
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            w.writeStartElement(null,'validationMode',null);
            w.writeCharacters('liveMode'); 
            w.writeEndElement();
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            Dom.XMLNode messages = xmlResponse.getChildElement('messages','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            if(resultCode == 'Error'){
                //throw new AuthorizeDotNetException('A profile with this ID already exists');
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                
                if(code=='E00039')
                {
                    customerProfileId=xmlResponse.getChildElement('customerProfileId',namespace).getText();
                    customerPaymentProfileId = xmlResponse.getChildElement('customerPaymentProfileId',namespace).getText();
                    isExistingPaymentProfile=true;
                }
                else
                {
                    String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                    throw new AuthorizeDotNetException(errorText);
                }
            }
            else if(resultCode == 'Ok')
            {
                customerPaymentProfileId = xmlResponse.getChildElement('customerPaymentProfileId',namespace).getText();
                System.debug('OK - cust payment prof id is ' + customerPaymentProfileId );
            }
            
        }
        catch(AuthorizeDotNetException ae)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            throw ae;
        }
        catch(Exception ae )
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Card Information-('+ae.getLineNumber()+' '+ae.getMessage()+')'));
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
        }
    }
    
    public AuthorizeDotNetResponse createCustomerProfileAuthOnlyTransaction(String customerProfileId,String customerPaymentProfileId, String amount, String taxAmount, string orderNumber)//, datetime transactionDate)
    {
        AuthorizeDotNetResponse resultResponse = new AuthorizeDotNetResponse();
        try
        {
            AuthorizeDotNetTokens__c tokenVar = AuthorizeDotNetTokens__c.getValues('Auth');
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'createCustomerProfileTransactionRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            w.writeCharacters(tokenVar.New_API_Name__c);//(transactionDate < tokenVar.New_Account_Date__c ? tokenVar.API_Name__c : tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(tokenVar.New_transactionKey__c);//(transactionDate < tokenVar.New_Account_Date__c ? tokenVar.transactionKey__c : tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_AuthOnly');
            w.writeEndElement();           
            
            w.writeStartElement(null,'transaction',null);
            w.writeStartElement(null,'profileTransAuthOnly',null);
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(amount);
            w.writeEndElement();
            w.writeStartElement(null,'tax',null);
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(taxAmount);
            w.writeEndElement();
            w.writeStartElement(null,'name',null);
            w.writeCharacters('texas state tax');
            w.writeEndElement();
            w.writeStartElement(null,'description',null);
            w.writeCharacters('sales tax');
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'customerProfileId',null);
            w.writeCharacters(customerProfileId);
            w.writeEndElement();
            w.writeStartElement(null,'customerPaymentProfileId',null);
            w.writeCharacters(customerPaymentProfileId);
            w.writeEndElement();
            
            w.writeStartElement(null,'order',null);
            w.writeStartElement(null,'invoiceNumber',null);
            w.writeCharacters(orderNumber);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();    
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = tokenVar.New_Endpoint__c;//transactionDate < tokenVar.New_Account_Date__c ? tokenVar.Endpoint__c : tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            if(resultCode == 'Error'){
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                throw new AuthorizeDotNetException(errorText);
            }
            else if(resultCode == 'Ok'){
                String directResponse = xmlResponse.getChildElement('directResponse',namespace).getText();
                system.debug('the response is ' + directResponse);
                resultResponse = AuthorizeDotNetResponse.generateResponse(directResponse);
                transactionId = resultResponse.TransactionId;
            }
        }
        catch(AuthorizeDotNetException ae)
        {
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            throw ae;
        }
        catch(Exception ae )
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Card Information-('+ae.getMessage()+')'));
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
        }
        return resultResponse;
    }
    
    public AuthorizeDotNetResponse createCustomerRefundTransaction(String customerProfileId,String customerPaymentProfileId,String customerTransactionId, String amount, String taxAmount, datetime transactionDate, string orderNumber, boolean useOldAccount)
    {
        AuthorizeDotNetResponse resultResponse=new AuthorizeDotNetResponse();
        try
        {
            AuthorizeDotNetTokens__c tokenVar = AuthorizeDotNetTokens__c.getValues('Auth');
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'createCustomerProfileTransactionRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.API_Name__c : tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.transactionKey__c : tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_Refund');
            w.writeEndElement();
            
            
            w.writeStartElement(null,'transaction',null);
            w.writeStartElement(null,'profileTransRefund',null);
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(amount);
            w.writeEndElement();
            w.writeStartElement(null,'tax',null);
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(taxAmount);
            w.writeEndElement();
            w.writeStartElement(null,'name',null);
            w.writeCharacters('texas state tax');
            w.writeEndElement();
            w.writeStartElement(null,'description',null);
            w.writeCharacters('sales tax');
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'customerProfileId',null);
            w.writeCharacters(customerProfileId);
            w.writeEndElement();
            w.writeStartElement(null,'customerPaymentProfileId',null);
            w.writeCharacters(customerPaymentProfileId);
            w.writeEndElement();
            
            w.writeStartElement(null,'order',null);
            w.writeStartElement(null,'invoiceNumber',null);
            w.writeCharacters(orderNumber);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'transId',null);
            w.writeCharacters(customerTransactionId);
            w.writeEndElement();
            
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();    
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.Endpoint__c : tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            if(resultCode == 'Error'){
                //throw new AuthorizeDotNetException('A profile with this ID already exists');
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                resultResponse.responseReasonText = errorText; 
                resultResponse.avsResponse = code;
                //throw new AuthorizeDotNetException(errorText);
            }
            else if(resultCode == 'Ok'){
                String directResponse = xmlResponse.getChildElement('directResponse',namespace).getText();
                system.debug('the response is ' + directResponse);
                resultResponse = AuthorizeDotNetResponse.generateResponse(directResponse);          
                transactionId = resultResponse.TransactionId;
            }
            system.debug('the transaction id is ' + transactionId);
        }
        catch(AuthorizeDotNetException ae)
        {
            //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            resultResponse.responseReasonText = ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause(); 
            //return null;
        }
        catch(Exception ae )
        {
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
        }
        return resultResponse;
    }
    
    public AuthorizeDotNetResponse createCustomerAuthAndCaptureTransaction(String customerProfileId,String customerPaymentProfileId,String amount, String taxAmount, string orderNumber, datetime transactionDate, boolean useOldAccount)
    {
        AuthorizeDotNetResponse resultResponse=new AuthorizeDotNetResponse();
        try
        {
            AuthorizeDotNetTokens__c tokenVar = AuthorizeDotNetTokens__c.getValues('Auth');
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'createCustomerProfileTransactionRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            
            system.debug('1transactionDate = ' + transactionDate);
            system.debug('1tokenVar.New_Account_Date__c = ' + tokenVar.New_Account_Date__c);
            system.debug(transactionDate < tokenVar.New_Account_Date__c);
            w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.API_Name__c : tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.transactionKey__c : tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_Auth_Capture');
            w.writeEndElement();
            
            w.writeStartElement(null,'transaction',null);
            
            /*w.writeStartElement(null,'setting',null);
            w.writeStartElement(null,'settingName',null);
            w.writeCharacters('duplicateWindow');
            w.writeEndElement();
            w.writeStartElement(null,'settingValue',null);
            w.writeCharacters('600');
            w.writeEndElement();
            w.writeEndElement();*/
            
            w.writeStartElement(null,'profileTransAuthCapture',null);
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(amount);
            w.writeEndElement();
            w.writeStartElement(null,'tax',null);
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(taxAmount);
            w.writeEndElement();
            w.writeStartElement(null,'name',null);
            w.writeCharacters('texas state tax');
            w.writeEndElement();
            w.writeStartElement(null,'description',null);
            w.writeCharacters('sales tax');
            w.writeEndElement();
            w.writeEndElement();


            
            w.writeStartElement(null,'customerProfileId',null);
            w.writeCharacters(customerProfileId);
            w.writeEndElement();
            w.writeStartElement(null,'customerPaymentProfileId',null);
            w.writeCharacters(customerPaymentProfileId);
            w.writeEndElement();
            
            
            /*w.writeStartElement(null,'extraOptions',null);
            w.writeCharacters('![CDATA[x_duplicate_window=600]]');
            w.writeEndElement();*/
            
            
            
            
            w.writeStartElement(null,'order',null);
            w.writeStartElement(null,'invoiceNumber',null);
            w.writeCharacters(orderNumber);
            w.writeEndElement();
            w.writeEndElement();


            
            w.writeEndElement();

            w.writeEndElement();
            w.writeStartElement(null,'extraOptions',null); 
            w.writeCharacters('<![CDATA[x_duplicate_window=600]]>');
            w.writeEndElement();    
            /*w.writeStartElement(null,'transactionRequest',null); 
            w.writeStartElement(null,'transactionSettings',null);
                w.writeStartElement(null,'setting',null);
                    w.writeStartElement(null,'settingName',null);
                        w.writeCharacters('duplicateWindow');
                    w.writeEndElement();
                    w.writeStartElement(null,'settingValue',null);
                        w.writeCharacters('600');
                    w.writeEndElement();
                w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();*/
            w.writeEndElement();    
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.Endpoint__c :  tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            resultResponse.response = string.valueof(xmlResponse);
            
            if(resultCode == 'Error'){
                //throw new AuthorizeDotNetException('A profile with this ID already exists');
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                resultResponse.error = errorText;
                throw new AuthorizeDotNetException(errorText);
            }
            else if(resultCode == 'Ok'){
                
                String directResponse = xmlResponse.getChildElement('directResponse',namespace).getText();
                system.debug('the response is ' + directResponse);
                resultResponse = AuthorizeDotNetResponse.generateResponse(directResponse);
                transactionId = resultResponse.TransactionId;
            }
            
            system.debug('the transaction id is ' + transactionId);
        }
        catch(AuthorizeDotNetException ae)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            resultResponse.error = ae.getmessage() + ' ' + ae.getLineNumber();
            //   throw ae;
        }
        catch(Exception ae )
        {
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
            resultResponse.error = ae.getmessage() + ' ' + ae.getLineNumber();
        }
        return resultResponse;
    }
    
    public AuthorizeDotNetResponse voidTransaction(string customerProfileId,string customerPaymentProfileId,string transactionid, datetime transactionDate, boolean useOldAccount)
    {
        AuthorizeDotNetResponse resultResponse=new AuthorizeDotNetResponse();
        try{
            try{
                AuthorizeDotNetTokens__c tokenVar = AuthorizeDotNetTokens__c.getValues('Auth');
                XmlStreamWriter w = new XmlStreamWriter();
                w.writeStartDocument('utf-8','1.0');
                w.writeStartElement(null,'createCustomerProfileTransactionRequest',null);
                w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
                
                w.writeStartElement(null,'merchantAuthentication',null);
                w.writeStartElement(null,'name',null);
                w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.API_Name__c : tokenVar.New_API_Name__c);
                w.writeEndElement();
                w.writeStartElement(null,'transactionKey',null);
                w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.transactionKey__c : tokenVar.New_transactionKey__c);
                w.writeEndElement();
                w.writeEndElement();
                
                w.writeStartElement(null,'refId',null);
                w.writeCharacters('CF_void');
                w.writeEndElement();
                
                w.writeStartElement(null,'transaction',null);
                w.writeStartElement(null,'profileTransVoid',null);
                
                w.writeStartElement(null,'customerProfileId',null);
                w.writeCharacters(customerProfileId);
                w.writeEndElement();
                w.writeStartElement(null,'customerPaymentProfileId',null);
                w.writeCharacters(customerPaymentProfileId);
                w.writeEndElement();
                w.writeStartElement(null,'transId',null);
                w.writeCharacters(transactionid);
                w.writeEndElement();
                w.writeEndElement();
                w.writeEndElement();
                w.writeEndElement();    
                w.writeEndDocument();
                string xml = w.getXmlString();
                w.close();
                system.debug(xml);
                String endpoint = transactionDate < tokenVar.New_Account_Date__c || useOldAccount ? tokenVar.Endpoint__c : tokenVar.New_Endpoint__c;
                HttpRequest req = new HttpRequest();
                req.setMethod('POST');
                req.setEndpoint(endpoint);
                req.setHeader('Content-Type', 'text/xml');
                req.setBody(xml);
                
                Http http = new Http();
                HttpResponse res = http.send(req);
                system.debug(res.getBody());
                
                String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
                
                Dom.Document doc = res.getBodyDocument();
                
                Dom.XMLNode xmlResponse = doc.getRootElement();
                
                String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
                system.debug('the resultcode is ' + resultCode);
                
                if(resultCode == 'Error'){
                    String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                    system.debug('code '+code);
                    String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                    throw new AuthorizeDotNetException(errorText);
                }
                else if(resultCode == 'Ok'){
                    String directResponse = xmlResponse.getChildElement('directResponse',namespace).getText();
                    system.debug('the response is ' + directResponse);
                    resultResponse = AuthorizeDotNetResponse.generateResponse(directResponse);
                    transactionId = resultResponse.TransactionId;
                    system.debug('the transaction id is ' + transactionId);
                }
            }
            catch(AuthorizeDotNetException ae){
                // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
                system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
                throw ae;
                //return null;
            }
        }
        catch(Exception ae ){
            String errorMessage = 'Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage();
            resultResponse.error = errorMessage;
            system.debug(errorMessage);
        }
        return resultResponse;           
    }
    
    public AuthorizeDotNetResponse deletePaymentProfile(string customerProfileID,string paymentProfileID)
    {
        AuthorizeDotNetResponse resultResponse=new AuthorizeDotNetResponse();
        try
        {
            AuthorizeDotNetTokens__c tokenVar=AuthorizeDotNetTokens__c.getValues('Auth');
            XmlStreamWriter w = new XmlStreamWriter();
            
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'deleteCustomerPaymentProfileRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            //    w.writeAttribute(null,null,'refId','CF_Delete');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            w.writeCharacters(tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_Delete');
            w.writeEndElement();
            
            w.writeStartElement(null,'customerProfileId',null);
            w.writeCharacters(customerProfileID);
            w.writeEndElement();
            w.writeStartElement(null,'customerPaymentProfileId',null);
            w.writeCharacters(paymentProfileID);
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            if(resultCode == 'Error'){
                
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                throw new AuthorizeDotNetException(errorText);
            }
            else if(resultCode == 'Ok'){
                resultResponse.responseReasonText='Payment Profile Deleted Successfully '; 
            }
        }
        catch(AuthorizeDotNetException ae)
        {
            //   ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            throw ae;
            //return null;
        }
        catch(Exception ae )
        {
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
        }
        return resultResponse;    
    }
    
    public boolean updatePaymentProfileAddress(String firstName, String address, String city, String state, String zipcode, String country, String cardNumber, String expirationDate,string CustomerProfileID,string paymentProfileID)
    {
        boolean resultResponse=false;
        
        try{
            AuthorizeDotNetTokens__c tokenVar=AuthorizeDotNetTokens__c.getValues('Auth');   
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'updateCustomerPaymentProfileRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            w.writeCharacters(tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_Update_Payment');
            w.writeEndElement();
            
            w.writeStartElement(null,'customerProfileId',null);
            w.writeCharacters(CustomerProfileID);
            w.writeEndElement();
            
            w.writeStartElement(null,'paymentProfile',null);
            w.writeStartElement(null,'billTo',null);
            w.writeStartElement(null,'firstName',null);
            w.writeCharacters(firstname);
            w.writeEndElement();
            
            w.writeStartElement(null,'address',null);
            w.writeCharacters(address);
            w.writeEndElement();
            w.writeStartElement(null,'city',null);
            w.writeCharacters(city);
            w.writeEndElement();
            w.writeStartElement(null,'state',null);
            w.writeCharacters(state);
            w.writeEndElement();
            w.writeStartElement(null,'zip',null);
            w.writeCharacters(zipcode);
            w.writeEndElement();
            w.writeStartElement(null,'country',null);
            w.writeCharacters(country);
            w.writeEndElement();
            w.writeEndElement();
            w.writeStartElement(null,'payment',null);
            w.writeStartElement(null,'creditCard',null);
            w.writeStartElement(null,'cardNumber',null);
            w.writeCharacters(cardNumber);
            w.writeEndElement();
            w.writeStartElement(null,'expirationDate',null);
            w.writeCharacters(expirationDate);
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'customerPaymentProfileId',null);
            w.writeCharacters(paymentProfileID);
            w.writeEndElement();
            w.writeEndElement();
            w.writeStartElement(null,'validationMode',null);
            w.writeCharacters('liveMode'); 
            w.writeEndElement();
            w.writeEndDocument();
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            if(resultCode == 'Error') {
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                throw new AuthorizeDotNetException(errorText);
                //resultResponse =false;
            }
            else if(resultCode == 'Ok')
            {
                // String directResponse = xmlResponse.getChildElement('updateCustomerPaymentProfileResponse',namespace).getText();
                //system.debug('the response is ' + directResponse);
                resultResponse = true;
            }
            
        }
        catch(AuthorizeDotNetException ae)
        {
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            throw ae;
            //return false;
        }
        catch(Exception ae )
        {
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
        }
        return resultResponse;        
    } 
    
    public AuthorizeDotNetResponse CaptureaPreviouslyAuthorizedAmount(String transId, String amount, String invoiceNumber, datetime transactionDate, boolean useOldAccount)
    {
        AuthorizeDotNetResponse resultResponse = new AuthorizeDotNetResponse();
        try
        {
            AuthorizeDotNetTokens__c tokenVar = AuthorizeDotNetTokens__c.getValues('Auth');
            XmlStreamWriter w = new XmlStreamWriter();
            w.writeStartDocument('utf-8','1.0');
            w.writeStartElement(null,'createTransactionRequest',null);
            w.writeAttribute(null,null,'xmlns','AnetApi/xml/v1/schema/AnetApiSchema.xsd');
            
            w.writeStartElement(null,'merchantAuthentication',null);
            w.writeStartElement(null,'name',null);
            system.debug('transactionDate = ' + transactionDate);
            system.debug('tokenVar.New_Account_Date__c = ' + tokenVar.New_Account_Date__c);
            system.debug(transactionDate < tokenVar.New_Account_Date__c);
            w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount  ? tokenVar.API_Name__c : tokenVar.New_API_Name__c);
            w.writeEndElement();
            w.writeStartElement(null,'transactionKey',null);
            w.writeCharacters(transactionDate < tokenVar.New_Account_Date__c || useOldAccount  ? tokenVar.transactionKey__c : tokenVar.New_transactionKey__c);
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeStartElement(null,'refId',null);
            w.writeCharacters('CF_CapturePrevAuth');
            w.writeEndElement();           
            
            w.writeStartElement(null,'transactionRequest',null);
            
           /* */
            
            w.writeStartElement(null,'transactionType',null);
            w.writeCharacters('priorAuthCaptureTransaction');
            w.writeEndElement();
            w.writeStartElement(null,'amount',null);
            w.writeCharacters(Amount);
            w.writeEndElement();
            w.writeStartElement(null,'refTransId',null);
            w.writeCharacters(transId);
            w.writeEndElement();
            
            /*w.writeStartElement(null,'extraOptions',null);
            w.writeCharacters('![CDATA[x_duplicate_window=600]]');
            w.writeEndElement();
            w.writeStartElement(null,'transactionSettings',null);
            w.writeStartElement(null,'settingName',null);
            w.writeCharacters('duplicateWindow');
            w.writeEndElement();
            w.writeStartElement(null,'settingValue',null);
            w.writeCharacters('600');
            w.writeEndElement();
            w.writeEndElement();*/
            
            
            w.writeStartElement(null,'order',null);
            w.writeStartElement(null,'invoiceNumber',null);
            w.writeCharacters(invoiceNumber);
            w.writeEndElement();
            w.writeStartElement(null,'description',null);
            w.writeCharacters(' ');
            w.writeEndElement();
            w.writeEndElement();

            w.writeStartElement(null,'transactionSettings',null);
            w.writeStartElement(null,'setting',null);
            w.writeStartElement(null,'settingName',null);
            w.writeCharacters('duplicateWindow');
            w.writeEndElement();
            w.writeStartElement(null,'settingValue',null);
            w.writeCharacters('600');
            w.writeEndElement();
            w.writeEndElement();
            w.writeEndElement();
            
            w.writeEndElement();
            w.writeEndElement();    
            w.writeEndDocument();
            string xml = w.getXmlString();
            w.close();
            system.debug(xml);
            String endpoint = transactionDate < tokenVar.New_Account_Date__c || useOldAccount  ? tokenVar.Endpoint__c : tokenVar.New_Endpoint__c;
            HttpRequest req = new HttpRequest();
            req.setMethod('POST');
            req.setEndpoint(endpoint);
            req.setHeader('Content-Type', 'text/xml');
            req.setBody(xml);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            system.debug(res.getBody());
            
            String namespace = 'AnetApi/xml/v1/schema/AnetApiSchema.xsd';
            
            Dom.Document doc = res.getBodyDocument();
            
            Dom.XMLNode xmlResponse = doc.getRootElement();
            
            String resultCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
            system.debug('the resultcode is ' + resultCode);
            
            resultResponse.response = string.valueof(xmlResponse);
            if(resultCode == 'Error'){
                //return xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                String Code = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('code',namespace).getText();
                system.debug('code '+code);
                String errorText = xmlResponse.getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('text',namespace).getText();
                resultResponse.responseReasonText = errorText;
                resultResponse.error = errorText;
                throw new AuthorizeDotNetException(errorText);
            }
            else if(resultCode == 'Ok'){
                //return string.valueof(xmlResponse);
                //String directResponse = xmlResponse.getChildElement('directResponse',namespace).getText();
                system.debug('the response is ' + string.valueof(xmlResponse));
                resultResponse.responseCode = xmlResponse.getChildElement('messages',namespace).getChildElement('resultCode',namespace).getText();
                resultResponse.responseReasonText = xmlResponse.getChildElement('transactionResponse',namespace).getChildElement('messages',namespace).getChildElement('message',namespace).getChildElement('description',namespace).getText();
                resultResponse.transactionId = xmlResponse.getChildElement('transactionResponse',namespace).getChildElement('transId',namespace).getText();
                resultResponse.avsResponse = xmlResponse.getChildElement('transactionResponse',namespace).getChildElement('avsResultCode',namespace).getText();
                //resultResponse = AuthorizeDotNetResponse.generateResponse(directResponse);
                //transactionId = resultResponse.TransactionId;
            }
        }
        catch(AuthorizeDotNetException ae)
        {
            // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            resultResponse.error = ae.getmessage() + ' ' + ae.getLineNumber();
            //throw ae;
        }
        catch(Exception ae )
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,' Please enter Valid Card Information-('+ae.getMessage()+')'));
            system.debug('Exception Caught at Line number : '+ae.getLineNumber()+', Message : '+ae.getmessage());
            resultResponse.error = ae.getmessage() + ' ' + ae.getLineNumber();
        }
        return resultResponse;
    }
}