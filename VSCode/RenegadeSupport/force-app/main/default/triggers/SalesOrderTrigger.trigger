trigger SalesOrderTrigger on Sales_Order__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    
    public List<Sales_Order__c> salesOrderList {get;set;}
    //old trigger
    if (Trigger.isUpdate  || Trigger.isInsert){
        
        /*if(trigger.isBefore) 
        {
            salesOrderList = new List<Sales_Order__c>();
            for(Sales_Order__c SO : Trigger.new) {
                if(trigger.isInsert) 
                {
                    if(SO.Customer_Name__c != null && (SO.Customer_Billing_Address__c != null || SO.Customer_shipping_Address__c != null ) && ((SO.Billing_ZipCode__c == null && SO.Billing_Street__c == null && SO.Billing_City__c == null) || (SO.Shipping_ZipCode__c == null && SO.Shipping_Street__c == null && SO.Shipping_City__c == null))) 
                    {
                        salesOrderList.add(SO);
                    }
                }*/
                /* if(trigger.isUpdate) 
{  
System.debug('SO.Billing_ZipCode__c :: '+SO.Billing_ZipCode__c);
if(SO.Customer_Name__c != null && (SO.Customer_Billing_Address__c != trigger.oldMap.get(SO.id).Customer_Billing_Address__c || SO.Customer_shipping_Address__c != trigger.oldMap.get(SO.id).Customer_shipping_Address__c))
{
if(SO.Customer_Billing_Address__c != null || SO.Customer_shipping_Address__c != null ) {
salesOrderList.add(SO);
}
}
} 
//SalesOrderHelperclass.customerBillingShippingAddresses(Trigger.new);
//System.debug('salesOrderList :: '+salesOrderList);
if(salesOrderList.size() > 0) {
SalesOrderHelperclass.CAautopopulateAddress(salesOrderList);
}*/
                /*getDeliverycompanyHelper.salesorderDeliverycompany(trigger.new,trigger.oldmap); 
            }
        }
        
        if(trigger.isAfter) 
        {
            if(trigger.isInsert) 
            {
                SalesOrderHelperclass.GeolocationcaluculationInsert(Trigger.new);
            } 
            if(trigger.isupdate ) 
            {  */
                /*List<Sales_Order__c> salesOrderBillingList = new List<Sales_Order__c>();
List<Sales_Order__c> salesOrderShippingList = new List<Sales_Order__c>();
for(Sales_Order__c SO : trigger.new) {
if(SO.Customer_Billing_Address__c != null && (SO.Customer_Billing_Address__c == trigger.oldMap.get(SO.Id).Customer_Billing_Address__c) && (SO.Billing_ZipCode__c != null && SO.Billing_State__c != null && SO.Billing_City__c != null)) 
{
if(SO.Billing_ZipCode__c != trigger.oldMap.get(SO.id).Billing_ZipCode__c || SO.Billing_State__c != trigger.oldMap.get(SO.id).Billing_State__c || SO.Billing_City__c != trigger.oldMap.get(SO.id).Billing_City__c) {
salesOrderBillingList.add(SO); 
}
}
if(SO.Customer_shipping_Address__c != null && (SO.Customer_shipping_Address__c == trigger.oldMap.get(SO.Id).Customer_shipping_Address__c) && (SO.Shipping_ZipCode__c != null && SO.Shipping_State__c != null && SO.Shipping_City__c != null)) {
if(SO.Shipping_ZipCode__c != trigger.oldMap.get(SO.id).Shipping_ZipCode__c || SO.Shipping_State__c != trigger.oldMap.get(SO.id).Shipping_State__c || SO.Shipping_City__c != trigger.oldMap.get(SO.id).Shipping_City__c) {
salesOrderShippingList.add(SO); 
}
}                                                                                                                                                                                                     
}
System.debug('salesOrderBillingList : '+salesOrderBillingList);
System.debug('salesOrderShippingList : '+salesOrderShippingList);
if(salesOrderBillingList.size() > 0) {
SalesOrderHelperclass.customerBillingShippingAddresses(salesOrderBillingList,new List<Sales_Order__c>()); 
}
if(salesOrderShippingList.size() > 0) {
SalesOrderHelperclass.customerBillingShippingAddresses(new List<Sales_Order__c>(),salesOrderShippingList);
}*/
             /*   SalesOrderHelperclass.GeolocationcaluculationUpdate(Trigger.new,trigger.oldmap);
            } 
        }*/
    }
    
    //new trigger
    if (Trigger.isInsert && Trigger.isBefore) {
        System.debug('before insert');
        SalesOrderTriggerHandler.beforeInsert(trigger.new);
        SalesOrderTriggerHandler.fillShippingStateInitials(trigger.new, null);
    }
    
    if (Trigger.isUpdate && Trigger.isBefore) {
        SalesOrderTriggerHandler.beforeUpdate(trigger.newMap, trigger.oldmap);
        SalesOrderTriggerHandler.fillShippingStateInitials(trigger.new, trigger.oldmap);
    }
    
    if(Trigger.isAfter && Trigger.isUpdate){
        System.debug('after update');
        SalesOrderTriggerHandler.afterUpdate(trigger.oldmap, trigger.new, trigger.newmap);
        SalesOrderTriggerHandler.updateAccountFieldOnUpdateSO(trigger.new, trigger.oldmap);
    }
    
    if(Trigger.isAfter && Trigger.isInsert){
        System.debug('after insert');
        SalesOrderTriggerHandler.afterInsert(trigger.new, trigger.newmap);
        SalesOrderTriggerHandler.updateAccountField(trigger.new, Trigger.oldMap);
    }
    
    if(Trigger.isAfter && Trigger.isDelete){
        System.debug('after delete');
        SalesOrderTriggerHandler.updateAccountField(trigger.old, null);
    }
    
    if(Trigger.isAfter && Trigger.isUndelete){
        System.debug('after undelete');
        SalesOrderTriggerHandler.updateAccountField(trigger.new, Trigger.oldMap);
    }
    
}