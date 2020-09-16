@isTest
public class InvoiceTriggerTest {
    @isTest
    static void createTaskIfAmountDiffersTest() {
        insert new InvoiceTaskSettings__c(Name = 'Subject', Value__c = 'Call');
        Account ac = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'PayPal');
        
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        SO_Line_Items__c Sol2 = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        
        InvoiceHelperClass.isRun = true;
        Invoice__c Inv = TestUtil.createpayableInvoice(so.id);
        Invoice__c inv2 = TestUtil.createreceivablesInvoice(so.Id);
        
        Transaction__c transac = TestUtil.createTrasaction(so.Id, pm.Id, 'CAPTURE_ONLY');
        Inv.Order_Transaction_Type__c = transac.Id;
        Inv2.Order_Transaction_Type__c = TestUtil.createTrasaction(so.Id, pm.Id, 'CAPTURE_ONLY').Id;
        
        //update new List<Invoice__c> {Inv, Inv2};
            
        Invoice_Line_Item__c InvLineItem = TestUtil.createInvoiceLineItem(so.id,Sol.Id, Inv.id);
        Invoice_Line_Item__c InvLineItem2 = TestUtil.createInvoiceLineItem(so.id,Sol2.Id, Inv2.id);
        InvLineItem.Custom_Refund__c = 2;
        InvLineItem2.Custom_Refund__c = 2;
        
        Sol.Quantity__c = 5;
        Sol.Quantity_Refunded__c = 0;
        
        Sol2.Quantity__c = 5;
        Sol2.Quantity_Refunded__c = 0;
        update new List<SO_Line_Items__c> { sol, sol2 };
        update InvLineItem;
        update InvLineItem2;
        
        Test.startTest();
        
        InvoiceHelperClass.isRun = false;
        update new List<Invoice__c> { inv, inv2 };
        
        Test.stopTest();
        
        InvoiceHelperClass.isRun = false;
        inv.Invoice_Status__c = 'Refund-Failed';
        inv2.Invoice_Status__c = 'Refund-Failed';
        inv.Credit_Memo_Refund_Amount__c = 5;
        inv2.Credit_Memo_Refund_Amount__c = 5;
        update new List<Invoice__c> { inv, inv2 };
        
        delete inv;
    }
}