public class SOInvoicePaymentsController {
    
    public string invoiceid{set;get;}
    
    public list<Transaction__c> paymentList{set;get;}
    
    public SOInvoicePaymentsController(ApexPages.StandardController controller)
    {
        paymentList = new list<Transaction__c>();  
        Invoice__c dd=(Invoice__c)controller.getrecord();
        system.debug('dd  '+dd);
        invoiceid=dd.id; 
        displayPayments();
    }
    
    public void displayPayments()
    {
        try 
        {
            system.debug('invoiceid is --'+invoiceid);
            
            Invoice__c invoiceObj=new Invoice__c();
            
            if(invoiceid !=null)
            {
                invoiceObj=[select id,recordtype.name from Invoice__c where id=:invoiceid]; 
            }
            
            if(invoiceObj.recordtype.name == 'Payables') 
            {
                paymentList=new list<Transaction__c>();
                
                for(Transaction__c transactionObj : [SELECT Id, Name, OrderId__c, TransactionId__c, Transaction_Response__c, ProcessedDate__c, Sales_Order__c, Payment_Method__c, Invoice__c, Amount__c, Transaction_Type__c, Status__c, AVS_Response__c, Card_Number__c, Card_Type__c, Payment_Type__c FROM Transaction__c where Invoice__c=:invoiceid and (Status__c='Refunded' and Transaction_Type__c='CREDIT')]) 
                { 
                    paymentList.add(transactionObj);
                }
                System.debug('paymentList: '+paymentList.size());
                if(paymentList.size() == 0) {
                    Apexpages.addMessage(new ApexPages.message(apexpages.Severity.INFO,'No Transactions are Created.'));
                }
                
                system.debug('paymentList for Payables type'+paymentList);
            }
            else if(invoiceObj.recordtype.name == 'Receivables')
            {
                paymentList=new list<Transaction__c>();
                
                for(Transaction__c transactionObj : [SELECT Id, Name, OrderId__c, TransactionId__c, Transaction_Response__c, ProcessedDate__c, Sales_Order__c, Payment_Method__c, Invoice__c, Amount__c, Transaction_Type__c, Status__c, AVS_Response__c, Card_Number__c, Card_Type__c, Payment_Type__c FROM Transaction__c where Invoice__c=:invoiceid and (Status__c='Captured' and (Transaction_Type__c='CAPTURE_ONLY' or Transaction_Type__c='AUTH_W_CAPTURE'))]) 
                { 
                    paymentList.add(transactionObj);
                }
                System.debug('paymentList: '+paymentList.size());
                if(paymentList.size() == 0) {
                    Apexpages.addMessage(new ApexPages.message(apexpages.Severity.INFO,'No Transactions are Created.'));
                }
                system.debug('paymentList for Capture type'+paymentList);
            }
            
        }
        catch(Exception ex) {
            System.debug('Exception Ex: '+ex.getMessage()+', Cause: '+ex.getCause()+' at Line Number: '+ex.getLineNumber());
        }
    }
}