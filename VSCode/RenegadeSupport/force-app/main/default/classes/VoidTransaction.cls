global with sharing class VoidTransaction {
    
    WebService static String voidTransactions(string soId){
        
        Sales_Order__c so = [select id, Authdotnetoldaccount__c, Order_Status__c, Payment_Status__c, Customer_Name__r.Web_Site__c, (select id,custom_price__c,Products__r.recordtype.Name,Bundle_Item__c,Sales_Order__c 
                             from SO_Line_Items__r),(select id,Payment_Type__c,Payment_Method__c,TransactionId__c,Payment_Method__r.Customer_Profile_ID__c, Amount__c, createddate,
                             Payment_Method__r.Credit_Card_Number__c,Payment_Method__r.Payment_Profile_ID__c,Status__c from Transactions__r )
                             from Sales_Order__c where id = :soId];  
        if(so.Order_Status__c != 'Canceled' && so.Order_Status__c != 'Cancelled - Delivery area' && so.Order_Status__c != 'Cancelled - Underpriced'){
            return 'Payment status is not Canceled';
        }
        if(so.Transactions__r.size() == 0){
            return 'There are no transactions';
        }
        if(so.Transactions__r.size() > 1){
            return 'You cannot void a transactions when there is more than 1 transaction';
        }
        list<Transaction__c> succeededTransactionObjectList = [select id, Payment_Type__c, TransactionId__c, Amount__c, createddate, Sales_Order__r.Customer_Name__r.Web_Site__c from Transaction__c 
                                                               where Sales_Order__c=:soId and Status__c='Captured'];
        set<string> transactioIds = new set<string>();
        for(Transaction__c oneTransaction : succeededTransactionObjectList){
            transactioIds.add(string.valueof(oneTransaction.Amount__c));
        }
        list<Transaction__c> transToUpdateList = new list<Transaction__c>();
        for (Transaction__c t : so.Transactions__r){
            if (!transactioIds.contains(string.valueof(t.Amount__c)) && t.Status__c == 'Authorized'){
                try {
                    Transaction__c transactionObject = new Transaction__c();
                    transactionObject.id = t.Id;
                    if((t.Payment_Type__c=='Credit Card')){
                        AuthorizeDotNetFunctions authorizedotnetVar=new AuthorizeDotNetFunctions();
                        AuthorizeDotNetResponse responseObject=new AuthorizeDotNetResponse();
                        responseObject = authorizedotnetVar.voidTransaction(t.Payment_Method__r.Customer_Profile_ID__c,t.Payment_Method__r.Payment_Profile_ID__c,t.TransactionId__c, t.createddate, so.Authdotnetoldaccount__c);
                        system.debug('responseObject '+responseObject);
                        transactionObject.Transaction_Response__c=responseObject.responseReasonText;
	                    transactionObject.Status__c = 'Voided';
	                    transToUpdateList.add(transactionObject);
                    }else if(t.Payment_Type__c == 'PayPal' || t.Payment_Type__c == 'PayPal Express Checkout'){
                        PaypalConnect PaypalConnectObj = new PaypalConnect(so.Customer_Name__r.Web_Site__c);
                        payPalResponse payPalResponseObj = new payPalResponse();
                        payPalResponseObj = PaypalConnectObj.voidPayment(t.TransactionId__c);
                        transactionObject.Transaction_Response__c = payPalResponseObj.response;
	                    transactionObject.Status__c = 'Voided';
	                    transToUpdateList.add(transactionObject);
                    }else if(t.Payment_Type__c == 'Affirm' || t.Payment_Type__c == 'Affirm: Buy Now with 3 Easy Payments'){
                        AffirmIntagrationManager.Response affirmRes = AffirmIntagrationManager.voidWithChargeId(t.TransactionId__c, so.Customer_Name__r.Web_Site__c);
                        transactionObject.Transaction_Response__c = affirmRes.message;
	                    transactionObject.Status__c = 'Voided';
                        transToUpdateList.add(transactionObject);
                    }else if(t.Payment_Type__c == 'Zibby by Affirm'){
                        AffirmIntagrationManager.Response affirmRes = AffirmIntagrationManager.voidZibbyWithChargeId(t.TransactionId__c, so.Customer_Name__r.Web_Site__c);
                        transactionObject.Transaction_Response__c = affirmRes.message;
	                    transactionObject.Status__c = 'Voided';
                        transToUpdateList.add(transactionObject); 
                    }else if(t.Payment_Type__c == 'CheckoutFinance'){
                        FinanceIntegrationManager.Response financeRes = FinanceIntegrationManager.voidWithChargeId(t.TransactionId__c);
                        transactionObject.Transaction_Response__c = financeRes.message;
	                    transactionObject.Status__c = 'Voided';
	                    transToUpdateList.add(transactionObject);
                    }
                }
                catch(exception e){
                    return e.getmessage() + ' ' + e.getlinenumber();
                }
            }
        }
        if (transToUpdateList.size() > 0){
            update transToUpdateList;
            so.Payment_Status__c = 'Voided';
            update so;
            return 'Voided successfully';
        }
        return 'There are no teansactions to void';
    }
}