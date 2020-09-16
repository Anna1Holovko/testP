@isTest
private class TaxJarManagerTest {
    
    @testSetup static void setUp() {
        TaxJar_Setting__c settings = TaxJar_Setting__c.getOrgDefaults();
        settings.Token__c = 'Some Value';
        settings.URL__c = 'http://tets.com';
        upsert settings TaxJar_Setting__c.Id;
        Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert settGoogle;
        
        
    }
    
    
    @isTest static void submitTransactionTestError() {        
        Account ac = TestUtil.createCustomerAccount(); 
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        Sales_Order__c order = new Sales_Order__c();
        order.Magento_order_No__c = '12312';
        order.Customer_Name__c = ac.Id;
        order.Email__c = '12312@gmail.com';
        order.Billing_phone__c = '+382569654456';
        order.Shipping_Phone__c = '+382522654456';
        order.Shipping_Street__c = 'test 1';
        order.Shipping_City__c = 'test';
        order.Shipping_State__c = 'te';
        order.Shipping_ZipCode__c = '65895';
        order.Note_for_Delivery_Company__C = 'asdasdaqw qawdqa wdas dqwd asdrgs dcsa dfsd';
        insert order;        
        
        
        Test.startTest();
        TaxJarManager.submitTransaction(order.id);
        Test.stopTest();
    }
    
    @isTest static void submitTransactionTest() {
        
        Account ac = TestUtil.createCustomerAccount(); 
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        Sales_Order__c order = new Sales_Order__c();
        order.Magento_order_No__c = '12312';
        order.Customer_Name__c = ac.Id;
        order.Email__c = '12312@gmail.com';
        order.Billing_phone__c = '+382569654456';
        order.Shipping_Phone__c = '+382522654456';
        order.Shipping_Street__c = 'test 1';
        order.Shipping_City__c = 'test';
        order.Shipping_State__c = 'te';
        order.Shipping_ZipCode__c = '65895';
        order.Note_for_Delivery_Company__C = 'asdasdaqw qawdqa wdas dqwd asdrgs dcsa dfsd';
        insert order;    
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(order.id, pro.id, null,null,4);
        Sol.Quantity_Invoiced__c = 4;
        update Sol;

        
        Test.setMock(HttpCalloutMock.class, new HTTPResponseTaxJarManager());
        Test.startTest();
        TaxJarManager.submitTransaction(order.Id);
        Test.stopTest();
    }
    
    
    public class HTTPResponseTaxJarManager implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response 
            HttpResponse res = new HttpResponse(); 
            res.setHeader('Content-Type', 'application/json'); 
            TaxJarManager.Response resJSON = new TaxJarManager.Response();
            resJSON.detail = '';
            resJSON.error = 'test';
            resJSON.order = new TaxJarManager.Order();
            TaxJarManager.Order order = new TaxJarManager.Order();
            order.transaction_id = '';
            order.user_id = 1;
            order.transaction_date = '';
            order.transaction_reference_id = '';
            order.customer_id = '';
            order.from_country = '';
            order.from_zip = '';
            order.from_state = '';
            order.from_city = '';
            order.from_street = '';
            order.to_country = '';
            order.to_zip = '';
            order.to_state = '';
            order.to_city = '';
            order.to_street = '';
            order.amount = 1;
            order.shipping = 1;
            order.sales_tax = 1;
            order.discount = '21';
            order.line_items = new List<TaxJarManager.LineItem>();
            
            TaxJarManager.LineItem item = new TaxJarManager.LineItem();
            item.id = 1;
            item.quantity = 1;
            item.product_identifier = '';
            item.product_tax_code = '';
            item.description = '';
            item.unit_price = 1;
            item.discount = 0;
            item.sales_tax = 1;
            
            order.line_items.add(item);
            resJSON.status = 'test';
            
            resJSON.order = order;
            res.setBody(JSON.serialize(resJSON)); 
            res.setStatusCode(200); 
            
            return res;
        }
    }
}