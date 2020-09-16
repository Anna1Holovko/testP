@isTest
private class TruckCompaniesOrderStatusUpdatesTest {

     @testSetup static void setUp() {
        Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert settGoogle;
        Dispatch_Track_Setting__c settDiscpatch = new Dispatch_Track_Setting__c();
        //settDiscpatch.api_key__c = 'asfadfsfasssdsdasd';
        settDiscpatch.server__c = 'teset.com';
        //settDiscpatch.code__c = 'aeas2';
        insert settDiscpatch;
     }
    
    @isTest static void updateStatusTest() {
        System.debug('test1');
        Account ac = TestUtil.createCustomerAccount(); 
        Account acTruck = TestUtil.createTruckingAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        System.debug('acc: ' + ac.Id);
        ship.Trucking_Company__c = acTruck.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;
        
        Shipment_Line_Item__c item = new Shipment_Line_Item__c();
        item.Shipment__c = ship.id;
        item.Shipment_Item_Status__c = 'Delivered No Issues';
        item.Delivery_Date_Actual__c = Date.today()-4;
        insert item;

        Shipment__c shipNew = [SELECT Id, Related_Sales_Order__r.Magento_order_No__c, Trucking_Company__c FROM Shipment__c WHERE Id = :ship.Id];
        Order_status_map__mdt stMap = [Select id, Delivery_company_status_name__c FROM Order_status_map__mdt LIMIT 1];

        RestContext.request = new RestRequest();
        RestContext.request.params.put('order_number', shipNew.Related_Sales_Order__r.Magento_order_No__c);
        RestContext.request.params.put('user_key', shipNew.Trucking_Company__c);
        RestContext.request.params.put('status', stMap.Delivery_company_status_name__c);

        TruckCompaniesOrderStatusUpdates.updateStatus();
    }

    @isTest static void updateStatusTestException2() {
        System.debug('test1');
        Account ac = TestUtil.createCustomerAccount(); 
        Account acTruck = TestUtil.createTruckingAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        System.debug('acc: ' + ac.Id);
        ship.Trucking_Company__c = acTruck.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;


        Shipment__c shipNew = [SELECT Id, Related_Sales_Order__r.Magento_order_No__c, Trucking_Company__c FROM Shipment__c WHERE Id = :ship.Id];
        Order_status_map__mdt stMap = [Select id, Delivery_company_status_name__c FROM Order_status_map__mdt LIMIT 1];

        RestContext.request = new RestRequest();
        RestContext.request.params.put('order_number', shipNew.Related_Sales_Order__r.Magento_order_No__c);
        RestContext.request.params.put('user_key', shipNew.Trucking_Company__c);
        RestContext.request.params.put('statasus', stMap.Delivery_company_status_name__c);

        TruckCompaniesOrderStatusUpdates.updateStatus();
    }

    @isTest static void updateStatusTestException3() {
        System.debug('test1');
        Account ac = TestUtil.createCustomerAccount(); 
        Account acTruck = TestUtil.createTruckingAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        //ship.Hold_Shipment__c  = true;
        System.debug('acc: ' + ac.Id);
        ship.Trucking_Company__c = acTruck.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;


        Shipment__c shipNew = [SELECT Id, Related_Sales_Order__r.Magento_order_No__c, Trucking_Company__c FROM Shipment__c WHERE Id = :ship.Id];
        Order_status_map__mdt stMap = [Select id, Delivery_company_status_name__c,Salesforce_status_name__c, Salesforce_shipment_line_status_name__c FROM Order_status_map__mdt WHERE Salesforce_shipment_line_status_name__c != '' LIMIT 1];
        System.debug(stMap);
        System.debug([Select id, Delivery_company_status_name__c,Salesforce_status_name__c, Salesforce_shipment_line_status_name__c FROM Order_status_map__mdt]);

        RestContext.request = new RestRequest();
        RestContext.request.params.put('order_number', shipNew.Related_Sales_Order__r.Magento_order_No__c);
        RestContext.request.params.put('user_key', shipNew.Trucking_Company__c);
        RestContext.request.params.put('status', 'Scheduled Shipments');

        TruckCompaniesOrderStatusUpdates.updateStatus();
    }


    @isTest static void updateStatusTestException() {
        System.debug('test2');

        RestContext.request = new RestRequest();
        RestContext.request.params.put('order_number', 'asasdasd');
        RestContext.request.params.put('user_key', 'asdasadasdas');
        RestContext.request.params.put('status', 'none');


        TruckCompaniesOrderStatusUpdates.updateStatus();
    }

    @isTest static void updateStatusTestFirstTry() {
                System.debug('test3');
        Account ac = TestUtil.createCustomerAccount(); 
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');

        Order_status_map__mdt stMap = [Select id, Delivery_company_status_name__c FROM Order_status_map__mdt LIMIT 1];

        RestContext.request = new RestRequest();
        RestContext.request.params.put('status', stMap.Delivery_company_status_name__c);

        TruckCompaniesOrderStatusUpdates.updateStatus();
    }

    @isTest static void updateStatusTestSecondTry() {
        Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        System.debug('acc: ' + ac.Id);
        ship.Send_to_a_delivery_company__c = true;
        update ship;


        Order_status_map__mdt stMap = [Select id, Delivery_company_status_name__c FROM Order_status_map__mdt LIMIT 1];

        RestContext.request = new RestRequest();
        RestContext.request.params.put('order_number', ship.Related_Sales_Order__r.Magento_order_No__c);
        RestContext.request.params.put('user_key', ship.Trucking_Company__c);
        RestContext.request.params.put('status', stMap.Delivery_company_status_name__c);

        TruckCompaniesOrderStatusUpdates.updateStatus();
    }
    
}