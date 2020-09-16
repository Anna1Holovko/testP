@isTest
private class InvoiceLineItemTriggerHandlerTest {

    public static testMethod void newInvoice() {
        Account ac = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        
        //Products Creation
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        
        //Payment Method Creation
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'PayPal');
        
        //SalesOrder Creation
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
                
		//SalesOrder Line Item Creation
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        SO_Line_Items__c configSol = TestUtil.createsalesOrderLineItem(so.id, pro.id, configPro.id,null,2);
        
        SO_Line_Items__c bundleSol = TestUtil.createsalesOrderLineItem(so.id, bundlePro.id, null,bundleItem.id,2);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        //Transaction Creation
        Transaction__c tracAuthOnly = TestUtil.createTrasaction(so.id,pm.id,'AUTH_ONLY');
        Transaction__c tracCaptureOnly = TestUtil.createTrasaction(so.id,pm.id,'CAPTURE_ONLY');
        
        Invoice__c Inv = TestUtil.createpayableInvoice(so.id);
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
    }
}