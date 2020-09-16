@isTest
private class VoidTransactionTest {
	
	@isTest static void creditCardTest() {

		Account ac = TestUtil.createCustomerAccount(); 

		Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');

		Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Order_Status__c = 'Cancelled - Delivery area';
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Payment_Method__c payMethod = TestUtil.createpaymentMethod(ac.id, 'Credit Card');
        
        Invoice__c invoice = TestUtil.createpayableInvoice(so.id);
        
        Transaction__c trans = TestUtil.createTrasaction(so.id,payMethod.id, 'CREDIT');
        trans.Invoice__c = invoice.id;
        trans.Status__c= 'Authorized';
        update trans;

        VoidTransaction.voidTransactions(so.id);
	}

	@isTest static void payPalTest() {

		Account ac = TestUtil.createCustomerAccount(); 

		Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');

		Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Order_Status__c = 'Cancelled - Delivery area';
        update so;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Payment_Method__c payMethod = TestUtil.createpaymentMethod(ac.id, 'PayPal');
        
        Invoice__c invoice = TestUtil.createpayableInvoice(so.id);
        
        Transaction__c trans = TestUtil.createTrasaction(so.id,payMethod.id, 'CREDIT');
        trans.Invoice__c = invoice.id;
        trans.Status__c= 'Authorized';
        update trans;

        VoidTransaction.voidTransactions(so.id);
	}
	
}