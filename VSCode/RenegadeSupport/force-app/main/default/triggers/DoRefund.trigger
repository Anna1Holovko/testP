/*
*   Author : Vishnu Bijjula and Pavan Vuppala | Kairos Tech
*   Class  : DoRefund
*   Purpose: This trigger is to call refund callout and update Refunded, Deducting amount when Refund-Failed and Invoiced quantity on SO Line Items when it Deleted.
*/
trigger DoRefund on Invoice__c (before delete, after update) 
{
    System.debug('DoRefundTrigger');
    //InvoiceTriggerHandler invoiceHandler = new InvoiceTriggerHandler();
    
    if(trigger.isBefore)
    {
        if(trigger.isDelete){
            //invoiceHandler.onBeforeDelete(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
            InvoiceHelperClass.InvoiceQtyUpdate(trigger.old);
        }
    }

    if(trigger.isAfter)
    {    
        if(trigger.isUpdate){
            if(!InvoiceHelperClass.isRun){
                InvoiceHelperClass.isRun = true;
                InvoiceHelperClass.checkInvoiceStatus(Trigger.new, Trigger.oldMap);
                
                InvoiceHelperClass.createTaskIfAmountDiffers(Trigger.newMap, Trigger.oldMap);
            }//invoiceHandler.onAfterUpdate(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
        }
    }
}