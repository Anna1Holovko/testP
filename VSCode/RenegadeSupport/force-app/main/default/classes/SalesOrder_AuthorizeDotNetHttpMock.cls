@isTest
global class SalesOrder_AuthorizeDotNetHttpMock implements HttpCalloutMock 
{
    global HTTPResponse respond(HTTPRequest req) 
    {
        HttpResponse res = new HttpResponse();
        
        if (req.getBody().contains('CF_PayProfiles')) 
        {
            res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerPaymentProfileResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><customerProfileId>39462304</customerProfileId><customerPaymentProfileId>35996311</customerPaymentProfileId></createCustomerPaymentProfileResponse>');
        }
        else if(req.getBody().contains('CF_AuthOnly'))
        {
          res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerProfileTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><directResponse>1,1,1,This transaction has been approved.,FC9W8Z,Y,2251976129,,,5299.00,CC,auth_only,,sandhya,sandhya,,MEGASYSTEMS INC,SUITE 5A-1204,799 E DRAGRAM,TUCSON AZ,85705,US,,,sowdhanya.karri@kairostech.com,,,,,,,,,0.00,,,,,31DA4A0E4BF084D8BA16B2DBCABF21E1,,2,,,,,,,,,,,XXXX8431,American Express,,,,,,,,,,,,,,,,</directResponse></createCustomerProfileTransactionResponse>');  
        }
        else if(req.getBody().contains('CF_Cust_PayProfiles'))
        {
          res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerProfileResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><customerProfileId>39669769</customerProfileId><customerPaymentProfileIdList><numericString>35997557</numericString></customerPaymentProfileIdList><customerShippingAddressIdList /><validationDirectResponseList /></createCustomerProfileResponse>');  
        }
        else if(req.getBody().contains('CF_void'))
        {
          res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerProfileTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><directResponse>1,1,1,This transaction has been approved.,CFC5PC,P,2251999698,,,0.00,CC,void,,,,,,,,98104,,,,,,,,,,,,,,,,,,6EF49B6611BCF0D2D43D68089871EEE1,,,,,,,,,,,,,XXXX0005,American Express,,,,,,,,,,,,,,,,</directResponse></createCustomerProfileTransactionResponse>');  
        }
        else if(req.getBody().contains('CF_Auth_Capture'))
        {
          res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerProfileTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><directResponse>1,1,1,This transaction has been approved.,T3C2FG,Y,2252174297,,,711.90,CC,auth_capture,,Laxman rao,Laxman rao,,Madhapur,Hyderabad,Hyderabad,14604,US,,,laxman.nadipilli@kairostech.com,,,,,,,,,0.00,,,,,1CD5B55996EC4F2935790760C8882702,,2,,,,,,,,,,,XXXX0005,American Express,,,,,,,,,,,,,,,,</directResponse></createCustomerProfileTransactionResponse>');
        }
        else if(req.getBody().contains('CF_Refund'))
        {
          res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerProfileTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text><message></messages><directResponse>1,1,1,This transaction has been approved.,,P,2252178305,,,1729.93,CC,credit,,Test Account,Test Account,,8996 Routes 5 and 20,Bloomfield,New York,10001,US,,,dev@kairostech.com,,,,,,,,,0.00,,,,,1D8FE66F3F57949CE1B6C8DBEBD360EA,,,,,,,,,,,,,XXXX0005,American Express,,,,,,,,,,,,,,,,</directResponse></createCustomerProfileTransactionResponse>');  
        }    
        else if(req.getBody().contains('CF_Delete'))
        {
          res.setBody('<?xml version="1.0" encoding="utf-8"?><createCustomerPaymentProfileResponse xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><customerPaymentProfileId>20000</customerPaymentProfileId><validationDirectResponse>1,1,1,This transaction has been approved.,000000,Y,2000000000,none,Test transaction for ValidateCustomerPaymentProfile.,0.01,CC,auth_only,custId123,John,Doe,,123 Main St.,Bellevue,WA,98004,USA,000-000-0000,,mark@example.com,,,,,,,,,0.00,0.00,0.00,,none,D18EB6B211FE0BBF556B271FDA6F92EE,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,</validationDirectResponse></createCustomerPaymentProfileResponse>');
        }
        else if(req.getEndpoint().contains('paypal') && req.getEndpoint().contains('capture'))
        {
          res.setBody('{"id":"6JC57802WB273564A","create_time":"2016-03-08T19:52:01Z","update_time":"2016-03-08T19:52:24Z","amount":{"total":"8549.00","currency":"USD"},"is_final_capture":true,"state":"completed","parent_payment":"PAY-3BS599448A500874RK3PSV4Q","transaction_fee":{"value":"248.22","currency":"USD"},"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/capture/6JC57802WB273564A","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/capture/6JC57802WB273564A/refund","rel":"refund","method":"POST"},{"href":"https://api.sandbox.paypal.com/v1/payments/authorization/0WP3270149701313G","rel":"authorization","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-3BS599448A500874RK3PSV4Q","rel":"parent_payment","method":"GET"}]}');
        }
        else if(req.getEndpoint().contains('paypal') && req.getEndpoint().contains('refund'))
        {
          res.setBody('{"id":"76G86112XV4247527","create_time":"2016-03-08T22:54:08Z","update_time":"2016-03-08T22:54:08Z","state":"completed","amount":{"total":"1550.50","currency":"USD"},"capture_id":"6JC57802WB273564A","parent_payment":"PAY-3BS599448A500874RK3PSV4Q","links":[{"href":"https://api.sandbox.paypal.com/v1/payments/refund/76G86112XV4247527","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-3BS599448A500874RK3PSV4Q","rel":"parent_payment","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/capture/6JC57802WB273564A","rel":"capture","method":"GET"}]}');
        }
        else if(req.getEndpoint().contains('paypal') && req.getEndpoint().contains('void'))
        {
            res.setBody('{"id":"96418959JV799345E","create_time":"2016-03-09T10:43:46Z","update_time":"2016-03-09T10:44:29Z","amount":{"total":"1194.06","currency":"USD","details":{"subtotal":"1099.00","tax":"95.06"}},"state":"voided","parent_payment":"PAY-5TM94092JE631760PK3P74YQ","links":[{"href":"https://api.sandbox.paypal.com/v1/payments/authorization/96418959JV799345E","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-5TM94092JE631760PK3P74YQ","rel":"parent_payment","method":"GET"}]}');
        }
        else if(req.getEndpoint().contains('paypal') && req.getEndpoint().contains('token'))
        {
            res.setBody('{"scope":"https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*","nonce":"2016-03-11T06:00:14ZUrQ3dlXuD8ZedUP4D1zrATNkAhoJO9JJFbeWT3N0ogM","access_token":"A101.QYXQWkWwRW87z7mwnIG-xXNaEk1tUHuwxUKeM3zEfZjROxLQ-5XRd55hzhTnBZF1.U_m6syzbhAOJQyNPePwMqnRYTFS","token_type":"Bearer","app_id":"APP-80W284485P519543T","expires_in":32400}');
        }
        return res;
    }
}