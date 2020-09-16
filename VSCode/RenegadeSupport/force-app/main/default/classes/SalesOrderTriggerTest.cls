@isTest
public class SalesOrderTriggerTest {
    @TestSetup static void setup(){
        Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ', URL__c = 'https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=');
        insert googleAPI;
        
        Guardian_Setting__c guardianSetting = new Guardian_Setting__c();
        guardianSetting.Token_Expiration__c = null;
        guardianSetting.Token_endpoint__c = 'https://gpp-service.com/was/Token';
        guardianSetting.End_point__c = 'https://gpp-service.com/ereg-test/transaction';
        guardianSetting.Void_endpoint__c = 'https://gpp-service.com/ereg-test/transaction';
        guardianSetting.Key__c = '123';
        insert guardianSetting;
        
        White_Pages_setting__c setting = new White_Pages_setting__c();
        setting.URL__c = 'https://proapi.whitepages.com/3.2/identity_check?';
        setting.API_KEY__c = '41683d61fb5b4ffa9280e55833acf4ae';
        insert setting;
        
        Sift_Science_setting__c science_setting = new Sift_Science_setting__c();
        science_setting.URL__c = 'https://api.siftscience.com/v204/score';
        science_setting.API_KEY__c = '4f9895adccb39be7';
        insert science_setting;
        
        Opened_SO_statuses__c openedSOstatusesSetting = new Opened_SO_statuses__c();
        openedSOstatusesSetting.Name = 'Processing';
        insert openedSOstatusesSetting;
        
        Account ac = TestUtil.createCustomerAccount();
        Payment_Method__c paymentMethod = TestUtil.createpaymentMethod(ac.Id,'Credit Card');
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_List__c = '1';
        update Pro;
        SO_Line_Items__c sol = TestUtil.createsalesOrderLineItem(so.Id,Pro.Id,null,null,5);
        insert new Shipping_Zip_Codes__c(TaxJar_Sales_Tax__c = 5, Zip_Code__c = '10118');
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.Id, 'Internal PO');
        insert new Shipment__c(Send_to_a_delivery_company__c = true, Related_Sales_Order__c = so.Id, Purchase_Order__c = po.Id);
        so.Magento_Order_ID__c = 'd';
        so.IsSoModified__c = false;
        so.Order_Status__c = 'Completed';
        so.Ready_for_integration__c = true;
        update so;
    }
    
    @isTest
    static void createGuardianPlanTest(){
        Sales_Order__c so = [SELECT id, Guardian_s_void_link__c, Guardian_Number__c FROM Sales_Order__c LIMIT 1];
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new APIMock());
        so.Order_Status__c = 'Received by Warehouse';
        so.Protection_Plan_included__c = true;
        so.Guardian_Number__c = null;
        so.Check_for_Fraud__c = false;
        update so;
        SalesOrderTriggerHandler.createGuardianPlan(new Set<Id>{so.Id});
        Test.stopTest();
        
        so = [SELECT id, Guardian_s_void_link__c, Guardian_Number__c FROM Sales_Order__c WHERE Id =: so.Id LIMIT 1];
        System.assertEquals('test', so.Guardian_s_void_link__c);
        System.assertEquals('test', so.Guardian_Number__c);        
    }
    
    @isTest
    static void updateAccontFieldTest(){
        Sales_Order__c so = [SELECT id, Guardian_s_void_link__c, Guardian_Number__c FROM Sales_Order__c LIMIT 1];
        Test.startTest();
        so.Order_Status__c = 'Processing';
        update so;
        Account acc = [SELECT Id, Number_of_Opened_Sales_Orders__c FROM Account LIMIT 1];
        System.assertEquals(1, acc.Number_of_Opened_Sales_Orders__c);
        
        delete so;
        acc = [SELECT Id, Number_of_Opened_Sales_Orders__c FROM Account LIMIT 1];
        System.assertEquals(0, acc.Number_of_Opened_Sales_Orders__c);
        
        undelete so;
        acc = [SELECT Id, Number_of_Opened_Sales_Orders__c FROM Account LIMIT 1];
        System.assertEquals(1, acc.Number_of_Opened_Sales_Orders__c);
        Test.stopTest();
    }
    
    @isTest
    static void voidGuardianPlanTest(){
        Sales_Order__c so = [SELECT id, Guardian_s_void_link__c, Guardian_Number__c FROM Sales_Order__c LIMIT 1];
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, new APIMock());
        so.Void_Guardian__c = true;
        so.Guardian_s_void_link__c = '/test';
        update so;
        Test.stopTest();
        
        so = [SELECT id, Is_Protection_Plan_Registered__c, Error_message_voiding_protection_pl__c FROM Sales_Order__c WHERE Id =: so.Id LIMIT 1];
        System.assertEquals(false, so.Is_Protection_Plan_Registered__c);      
    }
    
    @isTest
    public static void mapLocationTest(){

        Account deliveryAccount = TestUtil.createDeliveryAccount(); 
        deliveryAccount.Location__Latitude__s = 20;
        deliveryAccount.Location__Longitude__s = 20;
        update deliveryAccount;

        Shipping_Zip_Codes__c shippingZipCode = new Shipping_Zip_Codes__c();
        shippingZipCode.Zip_Code__c = '60616';
        shippingZipCode.Delivery_Company_Account__c = deliveryAccount.Id;
        insert shippingZipCode;

        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');

        Trucking_Rule__c trucking = TestUtil.createTruckingRules(manufactureAccount.Id,deliveryAccount.Id);

        //Sales_Order__c so = [SELECT Id, Shipping_Street__c, Shipping_State__c, Shipping_ZipCode__c, Shipping_City__c, Shipping_Location__Longitude__s, Shipping_Location__Latitude__s FROM Sales_Order__c LIMIT 1];
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new APIMock());
        Id customerAccountId = [SELECT Id FROM Account LIMIT 1].Id;
        Customer_Addresses__c customerBillingAddress = TestUtil.CustomerAddress(customerAccountId,'Primary Billing Address','Billing Account');
        Customer_Addresses__c customerShippingAddress = TestUtil.CustomerAddress(customerAccountId,'Primary Shipping Address','Shipping Account');
        Sales_Order__c salesOrder = new Sales_Order__c(Order_Status__c='Processing',
                                                       Payment_Status__c='Processing',
                                                       Customer_Name__c = customerAccountId,
                                                       Email__c = 'SomeMail@gmai.com',
                                                       Customer_Billing_Address__c = customerBillingAddress.id,
                                                       Customer_shipping_Address__c = customerShippingAddress.id,
                                                       Billing_Street__c = '3434 S Michigan Ave Chicago',
                                                       Billing_City__c = 'Chicago',
                                                       Billing_State__c = 'Illinois',
                                                       Billing_ZipCode__c = '60616',
                                                       Billing_Phone__c = '9142358645',
                                                       Ship_to__c = 'Renegade Renegade',
                                                       Bill_to__c = 'Renegade Renegade',
                                                       Shipping_Street__c = '3434 S Michigan Ave Chicago',
                                                       Shipping_City__c = 'Chicago',
                                                       Shipping_State__c = 'Illinois',
                                                       Shipping_ZipCode__c = '60616',
                                                       Shipping_Phone__c = '9144563521',
                                                       Delivery_Company__c = deliveryAccount.Id,
                                                       Order_Date__c = System.now(),
                                                       Payment_Type__c = null,
                                                       Manufacturer__c = manufactureAccount.Id);
        insert salesOrder;
        
        /*salesOrder.Shipping_Street__c = 'Main Ave';
        salesOrder.Shipping_City__c = 'Boston';
        salesOrder.Shipping_State__c = 'New York';
        salesOrder.Shipping_ZipCode__c = '10023';
        update salesOrder;*/
        
        
        /*so.Shipping_City__c = 'Changed';
        so.Billing_City__c = 'Changed';
        update so;*/
        
        String[] prefixes = new String[] { 'Billing', 'Shipping' };
        String[] fields = new String[] { '_Street__c', '_City__c', '_State__c', '_ZipCode__c'};
            
            Map<String, String> addresses = new Map<String, String>();
        for (String prefix_i : prefixes) {
            for (String field_i : fields) {
                if (salesOrder.get(prefix_i + field_i) != null){
                    if (!addresses.containsKey(prefix_i))
                        addresses.put(prefix_i, string.valueOf(salesOrder.get(prefix_i + field_i)) + ',');
                    else
                        addresses.put(prefix_i, addresses.get(prefix_i) + string.valueOf(salesOrder.get(prefix_i + field_i)) + (fields.indexOf(field_i) < fields.size() - 1 ? ',' : ''));
                }
            }
        }
        Map<Id, String> addressMap = new Map<Id, String>();
        addressMap.put(salesOrder.id, addresses.values()[0]);

		SalesOrderTriggerHandler.geocode(addressMap);
        Test.stopTest();
        
        Sales_Order__c so1 = [SELECT Id, Shipping_Location__Longitude__s, Shipping_Location__Latitude__s, Billing_Location__Latitude__s, Billing_Location__Longitude__s FROM Sales_Order__c WHERE ID = :salesOrder.Id LIMIT 1];
        System.assertEquals(40.0, so1.Shipping_Location__Latitude__s);
        System.assertEquals(40.0, so1.Billing_Location__Latitude__s);
        
        //System.assertEquals(null, [SELECT Id, Shipping_Location__Longitude__s, Shipping_Location__Latitude__s FROM Sales_Order__c WHERE Id = :so.Id][0].Shipping_Location__Latitude__s);
        
        
    }
    
    @isTest
    static void checkFraudTest(){
        Sales_Order__c so = [SELECT id, Guardian_s_void_link__c, Guardian_Number__c FROM Sales_Order__c LIMIT 1];
        Test.startTest(); 
        Test.setMock(HttpCalloutMock.class, new APIMock());
        so.Recheck_fraud__c = true;
        so.Email__c = 'test@mail.com';
        update so;
        Test.stopTest();
        so = [SELECT id, Sift_science__c FROM Sales_Order__c WHERE Id =: so.Id LIMIT 1];
        System.assertEquals('50', so.Sift_science__c);    
    }
    
    
    public class APIMock implements HttpCalloutMock {
        public Map<String,String> responseBodyMap;
        
        public APIMock(){
            responseBodyMap = new Map<String,String>();
            String responseBody = '{"access_token":"testtoken","expires_in":"32321"}';
            responseBodyMap.put('https://gpp-service.com/was/Token',responseBody);
            
            responseBody = '{"results":[{"Info":"Plan:test:test,test"}],"links":[{"Title":"Test2","Href":"void:test"}]}';
            responseBodyMap.put('https://gpp-service.com/ereg-test/transaction123',responseBody);
            
            responseBody = '{"results" : [{"address_components" : [{"long_name" : "3434","short_name" : "3434","types" : [ "street_number" ]},{"long_name" : "South Michigan Avenue","short_name" : "S Michigan Ave","types" : [ "route" ]},'+
            '{"long_name" : "Douglas","short_name" : "Douglas","types" : [ "neighborhood", "political" ]},{"long_name" : "Chicago","short_name" : "Chicago","types" : [ "locality", "political" ]},{"long_name" : "Cook County","short_name" : "Cook County",'+
            '"types" : [ "administrative_area_level_2", "political" ]},{"long_name" : "Illinois","short_name" : "IL","types" : [ "administrative_area_level_1", "political" ]},{"long_name" : "Соединенные Штаты Америки","short_name" : "US",'+
            '"types" : [ "country", "political" ]},{"long_name" : "60616","short_name" : "60616","types" : [ "postal_code" ]}],"formatted_address" : "3434 S Michigan Ave, Chicago, IL 60616, США","geometry" : {"location" : {'+
            '"lat" : 40,"lng" : -80},"location_type" : "ROOFTOP","viewport" : {"northeast" : {"lat" : 40,"lng" : -80},"southwest" : {"lat" : 40,"lng" : -80}}},'+
            '"place_id" : "ChIJK4D8EQwsDogRyt8AE9ySuUw","plus_code" : {"compound_code" : "R9JG+J8 Чикаго, Illinois, Соединенные Штаты","global_code" : "86HJR9JG+J8"},"types" : [ "street_address" ]}],"status" : "OK"}';
            
            //responseBody = '{"results":[{"geometry":{"location":{"lat":"40","lng":"-80"}}}]}';
            responseBodyMap.put('https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=3434+S+Michigan+Ave+Chicago%2CChicago%2CIllinois%2C60616&key=AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ', responseBody);
            
            responseBody = '{"results":[{"geometry":{"location":{"lat":"42","lng":"-71"}}}]}';
            responseBodyMap.put('https://maps.googleapis.com/maps/api/geocode/json?sensor=false&address=Main Ave,Boston,New York,10023&key=AIzaSyDKbDTprU_oGUvvtRNIl5VS18_LDIeQHA0', responseBody);
            
            responseBody = '{"results":[{"Info":"Plan:test:test,test"}],"links":[{"Title":"Test2","Href":"void:test"}]}';
            responseBodyMap.put('https://gpp-service.com/ereg-test/transaction/test',responseBody);
            
            WhitePagesHandler.Response resp = new WhitePagesHandler.Response();
            WhitePagesHandler.Address_checks addrcheck = new WhitePagesHandler.Address_checks();
            WhitePagesHandler.Phone_checks pcheck = new WhitePagesHandler.Phone_checks();
            WhitePagesHandler.Email_address_checks echeck = new WhitePagesHandler.Email_address_checks();
            WhitePagesHandler.Ip_address_checks ipcheck = new WhitePagesHandler.Ip_address_checks();
            addrcheck.error = 'Test';
            addrcheck.warnings = new List<String>{'test'};
                addrcheck.is_valid = true;
            addrcheck.diagnostics = new List<String>{'test'};
                addrcheck.is_active = true;
            addrcheck.address_to_name = 'test';
            addrcheck.resident_name = 'test';
            addrcheck.resident_age_range = 'test';
            addrcheck.is_resident_deceased = true;
            addrcheck.is_commercial = true;
            addrcheck.is_forwarder = true;
            addrcheck.type = 'test';
            pcheck.error = 'test';
            pcheck.warnings = new List<String>{'test'};
                pcheck.is_valid = true;
            pcheck.phone_to_name = 'test';
            pcheck.phone_to_address = 'test';
            pcheck.subscriber_name = 'test';
            pcheck.subscriber_age_range = 'test';
            pcheck.country_code = 'test';
            pcheck.line_type = 'test';
            pcheck.carrier = 'test';
            pcheck.is_commercial = true;
            pcheck.is_prepaid = true;
            echeck.error = 'test';
            echeck.warnings = new List<String>{'test'};
                echeck.is_valid = true;
            echeck.diagnostics = new List<String>{'test'};
                echeck.is_autogenerated = true;
            echeck.is_disposable = true; 
            echeck.email_to_name = 'test';
            echeck.registered_name = 'test';
            echeck.registered_owner_age_range = 'test';
            echeck.email_first_seen_date = system.today();
            echeck.email_first_seen_days = 1;
            echeck.email_domain_creation_date = system.today();
            echeck.email_domain_creation_days = 1;
            ipcheck.error = 'test';
            ipcheck.warnings = new List<String>{'test'};
                ipcheck.is_valid = true;
            ipcheck.is_proxy = true;
            ipcheck.distance_from_address = 5;
            ipcheck.distance_from_phone = 5;
            ipcheck.is_resident_deceased = true;
            ipcheck.is_commercial = true;
            ipcheck.is_forwarder = true;
            ipcheck.connection_type = 'test';
            
            
            resp.primary_phone_checks = pcheck;
            resp.secondary_phone_checks = pcheck;
            resp.primary_address_checks = addrcheck;
            resp.secondary_address_checks = addrcheck;
            resp.email_address_checks = echeck;
            resp.ip_address_checks = ipcheck;
            
            responseBody = JSON.serialize(resp);
            responseBodyMap.put('https://proapi.whitepages.com/3.2/identity_check',responseBody);
            
            SiftScienceHandler.Response resObject = new SiftScienceHandler.Response();
            resObject.status = 0;
            resObject.error_message = '';
            resObject.description = '';
            resObject.is_bad = false;
            resObject.time_x = DateTime.now().getTime();
            resObject.user_id = 'test@mail.com';
            resObject.scores = new Map<String, SiftScienceHandler.Scores>();
            SiftScienceHandler.Scores score = new SiftScienceHandler.Scores();
            score.score = 0.5;
            score.reasons = new List<SiftScienceHandler.Reason>();
            SiftScienceHandler.Reason reason = new SiftScienceHandler.Reason();
            reason.name = 'test';
            reason.value = '10';
            score.reasons.add(reason);
            resObject.scores.put('payment_abuse', score);
            responseBodyMap.put('https://api.siftscience.com/v204/score/'+resObject.user_id +'/',JSON.serialize(resObject).replace('"time_x":', '"time":'));
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            String endpoint = req.getEndpoint();
            if(endpoint.contains('?') && !endpoint.contains('googleapis')){
                endpoint = endpoint.split('\\?')[0];
            }
            System.debug('endpoint---->'+endpoint);
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String body = responseBodyMap.get(endpoint);
            if (String.isNotEmpty(body)) {
            	res.setBody(responseBodyMap.get(endpoint));
            }
            System.debug('responseBodyMap.get(endpoint) '+responseBodyMap.get(endpoint));
            res.setStatusCode(200);
            System.debug(res);
            return res;
        }
    }
}