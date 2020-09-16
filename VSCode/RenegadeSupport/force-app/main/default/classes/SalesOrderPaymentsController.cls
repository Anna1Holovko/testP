public class SalesOrderPaymentsController 
{
    public string salesorderid{set;get;}
    public list<Transaction__c> paymentList{set;get;}
    public final List<String> TRANSACTION_VALID_STATUS_LIST = new List<String>{'Captured', 'Authorized', 'Pending'};
    public final List<String> TRANSACTION_VALID_TYPE_LIST = new List<String>{'Cheque', 'AUTH_ONLY', 'authorization', 'AUTH_W_CAPTURE'};
    public SalesOrderPaymentsController(ApexPages.StandardController controller)
    {
        paymentList = new list<Transaction__c>();       
        Sales_Order__c dd=(Sales_Order__c)controller.getrecord();
        salesorderid=dd.id; 
        system.debug('dd  '+dd);
        displayPayments();
    }
    public void displayPayments()
    {
        try {
           //Status__c='Captured' or Status__c='Authorized' or Status__c='Pending'
           // Transaction_Type__c='Cheque' or Transaction_Type__c='AUTH_ONLY' or Transaction_Type__c='authorization' or Transaction_Type__c = 'AUTH_W_CAPTURE'
            system.debug('salesorderid is --'+salesorderid);
            paymentList = [SELECT Id, Name, OrderId__c, TransactionId__c, Transaction_Response__c, ProcessedDate__c, Sales_Order__c, Payment_Method__c,
                        Payment_Method__r.Payment_type_image__c,Invoice__c, Amount__c, Transaction_Type__c, Status__c, AVS_Response__c, Card_Number__c, 
                        Card_Type__c, Payment_Type__c, Payment_Method__r.Check_Type__c,Payment_Method__r.Name_on_Account__c,Payment_Method__r.Routing_Number__c,
                        Payment_Method__r.Account_Number__c, Payment_Method__r.Manual_Payment_Type__c
                    FROM Transaction__c 
                    WHERE Sales_Order__c=:salesorderid  
                    AND (( Status__c IN :TRANSACTION_VALID_STATUS_LIST AND Transaction_Type__c IN :TRANSACTION_VALID_TYPE_LIST )
                    OR (Status__c = 'Voided' AND Sales_Order__r.Invoices_Changed_to_Manual_Payment__c > 0)
                    OR (Status__c = 'Captured' AND Transaction_Type__c = 'CAPTURE_ONLY' AND Payment_Type__c = 'Manual Payment')
                    )
                    
                    ]; 
            System.debug('paymentList: '+paymentList.size());
            if(paymentList.size() == 0) {
                Apexpages.addMessage(new ApexPages.message(apexpages.Severity.INFO,'No Transactions are Created.'));
            }
        }
        catch(Exception ex) {
            System.debug('Exception Ex: '+ex.getMessage()+', Cause: '+ex.getCause()+' at Line Number: '+ex.getLineNumber());
        }
    }
}