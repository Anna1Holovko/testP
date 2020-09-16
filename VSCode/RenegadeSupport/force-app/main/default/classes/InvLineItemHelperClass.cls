global class InvLineItemHelperClass {
	/*
    global static void InvoiceqtyUpdate(List<Invoice_Line_Item__c > InvNewList){
        list<Invoice_Line_Item__c> newsoIds;
         try {
                newsoIds = new list<Invoice_Line_Item__c>();
                
                for(Invoice_Line_Item__c  inv : InvNewList)
                {
                    newsoIds.add(inv);
                }
                UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(newsoIds);
            }
            Catch(Exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
            }
        
    }
    
    global static void removeQtyUpdate(List<Invoice_Line_Item__c> InvOldList)
    {
        list<Invoice_Line_Item__c> oldsoIds;
        system.debug('testing delete');
        try {
            oldsoIds = new list<Invoice_Line_Item__c>();
            
            for(Invoice_Line_Item__c  inv : InvOldList)
            {
                oldsoIds.add(inv);
            }
            
            UpdateSOitemInvoicedQty.removeinvoicedSOItemUpdate(oldsoIds);
        }
        Catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
        
    }
    */
}