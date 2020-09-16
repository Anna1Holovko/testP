@isTest
private class CustomerInfoTest {
	
	@isTest static void test_Service() {
		Fideliton_Setting__c setting = new Fideliton_Setting__c();
		setting.Password__c = '12314';
		setting.UserName__c = 'Test';
		insert setting;
		Google_API__c settGoogle = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
		insert settGoogle;
		Dispatch_Track_Setting__c settDiscpatch = new Dispatch_Track_Setting__c();
		//settDiscpatch.api_key__c = 'asfadfsfasssdsdasd';
		settDiscpatch.server__c = 'teset.com';
		//settDiscpatch.code__c = 'aeas2';
		insert settDiscpatch;
		Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		Account acDel = TestUtil.createDeliveryAccount(); 


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
		CustomerInfo.createNewLog(ac.Id);
		Test.stopTest();
	}
	
}