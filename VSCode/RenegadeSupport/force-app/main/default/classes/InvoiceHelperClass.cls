/*
*   Author : Sowdhanya && Mani Kumar | Kairos Tech
*   Class  : InvoiceHelperClass
*   Purpose: This class is used to remove the updated Invoiced and Refunded quantity on Sales Order Line Item.
*/
global class InvoiceHelperClass {
    public static Boolean isRun = false;
    
    global static void createTaskIfAmountDiffers(Map<Id, Invoice__c> newMap, Map<Id, Invoice__c> oldMap ) {
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        Set<Id> invoiceIdSetWithNotEmptyAmount = new Set<Id>();
        
        for (Invoice__c invoice_i : newMap.values()) {
            if (invoice_i.Credit_Memo_Refund_Amount__c > 0 ) {//&& oldMap.get(invoice_i.Id).Credit_Memo_Refund_Amount__c != invoice_i.Credit_Memo_Refund_Amount__c
                invoiceIdSetWithNotEmptyAmount.add(invoice_i.Id);
            }
        }
        
        if (invoiceIdSetWithNotEmptyAmount.isEmpty()) {
            return;
        }
        
        for (Invoice__c invoice_i : [SELECT Id, Total_Refund_Cancellation__c
                                     FROM Invoice__c
                                     WHERE Id IN :invoiceIdSetWithNotEmptyAmount AND Total_Refund_Cancellation__c != 0]) {
                                         if (invoice_i.Total_Refund_Cancellation__c != newMap.get(invoice_i.Id).Credit_Memo_Refund_Amount__c) {
                                             invoiceList.add(newMap.get(invoice_i.Id));
                                         }
                                     }
        
        if (!invoiceList.isEmpty()) {
            TaskHelper.createTaskForInvoice(invoiceList);
        }
    }

    global static void InvoiceQtyUpdate(List<Invoice__c> InvList)
    {
         list<Invoice_Line_Item__c> oldsoIds;
         list<Invoice__c> oldinvIds;
    
        system.debug('testing delete');
        try {
            oldsoIds = new list<Invoice_Line_Item__c>();
            oldinvIds = new list<Invoice__c>();
            
            for(Invoice__c  inv : InvList)
            {
                oldinvIds.add(inv);
            }
            
            for(Invoice_Line_Item__c invItem:[SELECT Discount_Amount_Hidden__c,Discount_Amount__c,Id,Invoice__c,Items_invoiced__c,
                                              Name,Product_Name__c,Quantity_Invoiced__c,Quantity_Ordered__c,Quantity_to_Invoice__c,
                                              Row_Total__c,Sales_Order__c,Sub_Total_Hidden__c,Sub_Total__c,Tax_Amount_Hidden__c,
                                              Quantity_To_Refund__c, Invoice__r.RecordTypeId,
                                              Tax_Amount__c,Unit_Price__c FROM Invoice_Line_Item__c where Invoice__c In :oldinvIds]) {
                oldsoIds.add(invItem);
            }
            
            UpdateSOitemInvoicedQty.removeinvoicedSOItemUpdate(oldsoIds);
        }
        catch(exception ex) {
            System.debug('Exception ex: '+ex.getMessage()+' '+ex.getCause()+' '+ex.getLineNumber());
        }
	}

    global static void checkInvoiceStatus (List<Invoice__c> newInvoiceList, Map<Id, Invoice__c> oldInvoiceMap){

        System.debug('Update');
        set<string> transactionIds = new set<string>();
        for(Invoice__c invoiceVar: newInvoiceList)
        {
            if (invoiceVar.Order_Transaction_Type__c != null){
                transactionIds.add(invoiceVar.Order_Transaction_Type__c);
            }
        }
        List<Transaction__c> updateTransaction = new List<Transaction__c>();
        List<String> transactionTypeList = new List<String>{'AUTH_W_CAPTURE', 'CAPTURE_ONLY'};
        List<String> transactionPaymentTypeList = new List<String>{'Manual Payment', 'Cardknox', 'Zibby by Affirm'};
        Map<id,Transaction__c> transactionMap = new Map<id,Transaction__c>(
            [SELECT Id, Refunded_Amount__c, createddate 
            FROM Transaction__c 
            WHERE id IN :transactionIds AND (Transaction_Type__c IN :transactionTypeList OR Payment_Type__c IN :transactionPaymentTypeList)]
        );
        set<Id> invoiceItemList = new set<Id>();
        
        for(Invoice_Line_Item__c invoiceLineItem: [Select Id from Invoice_Line_Item__c where Invoice__c In :newInvoiceList]) {
            invoiceItemList.add(invoiceLineItem.id);
        }
        Set<Id> invoicesHaveRefundedTransactionSet = new Set<Id>();
        for(Transaction__c transaction_i : [SELECT Id, Invoice__c FROM Transaction__c WHERE Invoice__c IN :newInvoiceList AND Status__c = 'Refunded' ]){
            invoicesHaveRefundedTransactionSet.add(transaction_i.Invoice__c);
        }
        
        System.debug('Before');
        for(Invoice__c invoiceVar: newInvoiceList)
        {
            if(system.isFuture()){
                System.debug('Return');
                return;
            } 
            System.debug('Invoice');
            System.debug(invoiceVar.Refund_Approval_Status__c == 'Refund Approved' );
            System.debug(invoiceVar.Refund_Processed_Action__c != oldInvoiceMap.get(invoiceVar.Id).Refund_Processed_Action__c);

            If(/*invoiceVar.Refund_Approval_Status__c != oldInvoiceMap.get(invoiceVar.Id).Refund_Approval_Status__c &&*/ !invoicesHaveRefundedTransactionSet.contains(invoiceVar.Id) && (invoiceVar.Refund_Approval_Status__c == 'Refund Approved' || invoiceVar.Refund_Processed_Action__c != oldInvoiceMap.get(invoiceVar.Id).Refund_Processed_Action__c))
            {   
                    If(invoiceVar.Reason_for_Refund__c == 'Cancellation'  || invoiceVar.Reason_for_Refund__c == 'GPP Cancellation')
                    {
                        if (!ProcessorControl.inFutureContext){
                            RefundController.Refund(invoiceVar.Sales_Order__c,invoiceVar.id ,invoiceVar.Payment_Method__c,  invoiceVar.Total_Refund_Cancellation__c,  invoiceVar.Tax_Amount__c, transactionMap.get(invoiceVar.Order_Transaction_Type__c).createddate);
                        }
                    }
                    else if (!ProcessorControl.inFutureContext){
                        RefundController.Refund(invoiceVar.Sales_Order__c,invoiceVar.id ,invoiceVar.Payment_Method__c,  invoiceVar.Total_Refund_Compensation__c,  invoiceVar.Tax_Amount__c, transactionMap.get(invoiceVar.Order_Transaction_Type__c).createddate);
                    }

            }
            
            If(invoiceVar.Invoice_Status__c != oldInvoiceMap.get(invoiceVar.Id).Invoice_Status__c && invoiceVar.Invoice_Status__c == 'Refund-Failed') 
            {
                InvoiceHelperClass.InvoiceQtyUpdate(newInvoiceList);
                
                Transaction__c trans = new Transaction__c();
                trans.id = invoiceVar.Order_Transaction_Type__c;
                /*if(invoiceVar.Reason_for_Refund__c == 'Cancellation' || invoiceVar.Reason_for_Refund__c ==  'GPP Cancellation') {
                    System.debug('transactionMap for Cancellation: '+transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c);
                    trans.Refunded_Amount__c = transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c - invoiceVar.Total_Refund_Cancellation__c;
                }
                else if(invoiceVar.Reason_for_Refund__c == 'Compensation') {
                    trans.Refunded_Amount__c = transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c - invoiceVar.Total_Refund_Compensation__c;
                }*/
                if(transactionMap.containskey(invoiceVar.Order_Transaction_Type__c) && (invoiceVar.Reason_for_Refund__c == 'Cancellation' || invoiceVar.Reason_for_Refund__c ==  'GPP Cancellation')) {
                    System.debug('transactionMap for Cancellation: '+transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c);
                    if (invoiceVar.Total_Refund_Cancellation__c != null){
                    	trans.Refunded_Amount__c = transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c - invoiceVar.Total_Refund_Cancellation__c;
                    }
                    else {
                    	trans.Refunded_Amount__c = transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c;
                    }
                }
                else if(transactionMap.containskey(invoiceVar.Order_Transaction_Type__c) && invoiceVar.Reason_for_Refund__c == 'Compensation') {
                	if (invoiceVar.Total_Refund_Compensation__c != null){
                    	trans.Refunded_Amount__c = transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c - invoiceVar.Total_Refund_Compensation__c;
                	}
                	else{
                		trans.Refunded_Amount__c = transactionMap.get(invoiceVar.Order_Transaction_Type__c).Refunded_Amount__c;
                	}
                }
                updateTransaction.add(trans);
                Sales_Order__c so = new Sales_Order__c(id = invoiceVar.Sales_Order__c, Payment_Status__c = 'Refund Failed');
                update so;
            }
            if(updateTransaction.size() > 0) {
                update updateTransaction;
            }
        }
    }
}