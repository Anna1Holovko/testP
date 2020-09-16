@isTest
public class SOPayableInvoiceListControllerTest {
/*
    @isTest
    static void SuccessTest(){
        Account acc = TestUtil.createCustomerAccount();
        acc.Name = 'Test1';
        Account accCustomer= TestUtil.createCustomerAccount();
        accCustomer.Name = 'Test2';
        Account accDelivery= TestUtil.createDeliveryAccount();
        accDelivery.Name = 'Test3';
        
      
       
        Payment_Method__c paymentMeth = TestUtil.createpaymentMethod(acc.id, 'Manual Payment');
       
            
        Sales_Order__c ord = TestUtil.createsalesOrder(accCustomer.id, accDelivery.id, paymentMeth.id);
       
        Invoice__c inv = TestUtil.createpayableInvoice(ord.id);
       
        SOPayableInvoiceListController.ResponseWrapper response =  SOPayableInvoiceListController.obtainsPayablesInvoice(ord.id);
       
        System.assertEquals(true, response.success);
        
    }*/
     @isTest
    static void obtainsPayablesInvoiceListTest(){
        Account acc = TestUtil.createCustomerAccount();
        acc.Name = 'Test1';
        Account accCustomer= TestUtil.createCustomerAccount();
        accCustomer.Name = 'Test2';
        Account accDelivery= TestUtil.createDeliveryAccount();
        accDelivery.Name = 'Test3';
        
        /*insert  acc;
        insert accCustomer;
        insert accDelivery;
        */
        //insert new List<Account>{acc, accCustomer, accDelivery};
        Payment_Method__c paymentMeth = TestUtil.createpaymentMethod(acc.id, 'Manual Payment');
        //insert paymentMeth;    
            
        Sales_Order__c ord = TestUtil.createsalesOrder(accCustomer.id, accDelivery.id, paymentMeth.id);
        //insert ord;
        Invoice__c inv = TestUtil.createpayableInvoice(ord.id);
        //insert inv;
        SOPayableInvoiceListController.ResponseWrapper response =  SOPayableInvoiceListController.obtainsPayablesInvoiceList(ord.id);
       
        System.assertEquals(true, response.success);
        
    }
    
/*
@isTest
    static void FailTest(){

        SOPayableInvoiceListController.ResponseWrapper response =  SOPayableInvoiceListController.obtainsPayablesInvoice(null);
       
        System.assertEquals(false, response.success);
        
    }        
    */
    @isTest
    static void obtainsPayablesInvoiceListFailTest(){

        SOPayableInvoiceListController.ResponseWrapper response =  SOPayableInvoiceListController.obtainsPayablesInvoiceList(null);
       
        System.assertEquals(false, response.success);
        
    }        
}