@isTest
private class PurchaseOrderNotificationCtrlTest {
	
	@isTest static void test_controller() {
		Account deliveryAccount = TestUtil.createDeliveryAccount();
		Account customerAccount = TestUtil.createCustomerAccount(); 
		Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
		Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        

		Products__c configPro = TestUtil.createConfigProduct();
        Products__c simplePro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
		 Products__c protectionPro = TestUtil.createprotectionProduct();


        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        SO_Line_Items__c simpleSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c, 
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:Sol.id];
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, configPro.id,null,2);
        SO_Line_Items__c configSolItems = [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,
                                           Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c,
                                           Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,
                                           Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,
                                           Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,
                                           DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,
                                           UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where id=:configSol.id];
        
        SO_Line_Items__c protectionSol = TestUtil.createsalesOrderLineItem(salesOrder.id, protectionPro.id, null,null,1);

		
        
		Purchase_Order__c po = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');
		Purchase_Order__c po2 = TestUtil.createpurchaseorder(salesOrder.id,'Manufacturer PO');

		PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
		POl.Partial_product_ordered__c = true;
		POl.SKU_name_and_list__c = '[{"weight":"75","sku":"ASL-B138-58","name":"King/Cal King Panel Headboard","dimensions":"84"},{"weight":"39.6","sku":"ASL-B138-97","name":"King Panel Rails","dimensions":"88"}]';
		update POl;
		PO_Line_Items__c POl2 = TestUtil.createpoitem(po2.id, Sol.id);
		

		PurchaseOrderNotificationCtrl controller = new PurchaseOrderNotificationCtrl();
		controller.poId = po.Id;
		controller.getPoLineItems();

		controller = new PurchaseOrderNotificationCtrl();
		controller.poId = po2.Id;
		controller.getPoLineItems();
	}
	
}