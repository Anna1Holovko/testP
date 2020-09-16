trigger UpdateInvoiceQty on Invoice_Line_Item__c (before delete) 
{
    if(trigger.isdelete) 
    { 
        UpdateSOitemInvoicedQty.removeinvoicedSOItemUpdate(trigger.old);
    }
}