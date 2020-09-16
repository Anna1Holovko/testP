@isTest
private class FidelitonOrderStatusUpdatesTest {

     @testSetup static void setUp() {
        Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert settGoogle;
     }
    
    @isTest static void updateStatusTest() {
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;
        
        Shipment_Line_Item__c item = new Shipment_Line_Item__c();
        item.Shipment__c = ship.id;
        item.Shipment_Item_Status__c = 'Delivered No Issues';
        item.Delivery_Date_Actual__c = Date.today()-4;
        insert item;

        FidelitonOrderStatusUpdates.Image newImage = new FidelitonOrderStatusUpdates.Image();
		newImage.image = 'test';
		newImage.image_name = 'test';

		List<FidelitonOrderStatusUpdates.Image> imageList = new List<FidelitonOrderStatusUpdates.Image>();
		imageList.add(newImage);

        FidelitonOrderStatusUpdates.OrderLineItem olItem = new FidelitonOrderStatusUpdates.OrderLineItem();
        olItem.images = imageList;
		olItem.id = item.Id;
		olItem.status = 'Finished';
		olItem.scheduled_delivery_date = '' + item.Delivery_Date_Actual__c;

		List<FidelitonOrderStatusUpdates.OrderLineItem> itemList = new List<FidelitonOrderStatusUpdates.OrderLineItem>();
		itemList.add(olItem);

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = order.Magento_order_No__c;
		newOrder.user_key = 'test';
		newOrder.line_items = itemList;

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }

    @isTest static void errorNoShipment() {

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = 'none';
		newOrder.user_key = 'test';
		newOrder.line_items = new List<FidelitonOrderStatusUpdates.OrderLineItem>();

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
    @isTest static void errorNoOrder() {

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = null;
		newOrder.user_key = null;
		newOrder.line_items = new List<FidelitonOrderStatusUpdates.OrderLineItem>();

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
    @isTest static void errorNoItems() {
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = order.Magento_order_No__c;
		newOrder.user_key = 'test';
		newOrder.line_items = new List<FidelitonOrderStatusUpdates.OrderLineItem>();

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
    @isTest static void errorExeption1() {

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
    @isTest static void errorExeption2() {

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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;
        
        Shipment_Line_Item__c item = new Shipment_Line_Item__c();
        item.Shipment__c = ship.id;
        item.Shipment_Item_Status__c = 'Delivered No Issues';
        item.Delivery_Date_Actual__c = Date.today()-4;
        insert item;

        FidelitonOrderStatusUpdates.Image newImage = new FidelitonOrderStatusUpdates.Image();
		newImage.image = 'test';
		newImage.image_name = 'test';

		List<FidelitonOrderStatusUpdates.Image> imageList = new List<FidelitonOrderStatusUpdates.Image>();
		imageList.add(newImage);

        FidelitonOrderStatusUpdates.OrderLineItem olItem = new FidelitonOrderStatusUpdates.OrderLineItem();
        olItem.images = imageList;
		olItem.id = item.Id;
		olItem.scheduled_delivery_date = '' + item.Delivery_Date_Actual__c;

		List<FidelitonOrderStatusUpdates.OrderLineItem> itemList = new List<FidelitonOrderStatusUpdates.OrderLineItem>();
		itemList.add(olItem);

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = order.Magento_order_No__c;
		newOrder.user_key = 'test';
		newOrder.line_items = itemList;

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
        @isTest static void errorExeption3() {
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

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;
        
        Shipment_Line_Item__c item = new Shipment_Line_Item__c();
        item.Shipment__c = ship.id;
        item.Shipment_Item_Status__c = 'Delivered No Issues';
        item.Delivery_Date_Actual__c = Date.today()-4;
        insert item;

        FidelitonOrderStatusUpdates.Image newImage = new FidelitonOrderStatusUpdates.Image();


		List<FidelitonOrderStatusUpdates.Image> imageList = new List<FidelitonOrderStatusUpdates.Image>();
		imageList.add(newImage);

        FidelitonOrderStatusUpdates.OrderLineItem olItem = new FidelitonOrderStatusUpdates.OrderLineItem();
        olItem.images = imageList;
		olItem.id = item.Id;
		olItem.status = 'Finished';
		olItem.scheduled_delivery_date = '' + item.Delivery_Date_Actual__c;

		List<FidelitonOrderStatusUpdates.OrderLineItem> itemList = new List<FidelitonOrderStatusUpdates.OrderLineItem>();
		itemList.add(olItem);

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = order.Magento_order_No__c;
		newOrder.user_key = 'test';
		newOrder.line_items = itemList;

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
    @isTest static void errorExeption4() {
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
        
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Sent_to_the_delivery_company__c = Date.today()-2;
        ship.Related_Sales_Order__c = order.Id;
        ship.Send_to_a_delivery_company__c = true;
        update ship;
        
        Shipment_Line_Item__c item = new Shipment_Line_Item__c();
        item.Shipment__c = ship.id;
        item.Shipment_Item_Status__c = 'Delivered No Issues';
        item.Delivery_Date_Actual__c = Date.today()-4;
        insert item;

        FidelitonOrderStatusUpdates.OrderLineItem olItem = new FidelitonOrderStatusUpdates.OrderLineItem();
		olItem.id = item.Id;
		olItem.status = 'F\nisd';
		olItem.scheduled_delivery_date = '' + item.Delivery_Date_Actual__c;

		List<FidelitonOrderStatusUpdates.OrderLineItem> itemList = new List<FidelitonOrderStatusUpdates.OrderLineItem>();
		itemList.add(olItem);

		FidelitonOrderStatusUpdates.Order newOrder = new FidelitonOrderStatusUpdates.Order();
		newOrder.order_number = order.Magento_order_No__c;
		newOrder.user_key = 'test';
		newOrder.line_items = itemList;

        RestContext.request = new RestRequest();

        FidelitonOrderStatusUpdates.updateStatus(newOrder);
    }
    
}