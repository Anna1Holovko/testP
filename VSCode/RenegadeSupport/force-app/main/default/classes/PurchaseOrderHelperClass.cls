global class PurchaseOrderHelperClass {
    public Static list<Purchase_Order__c> updatePO = new list<Purchase_Order__c>();
    public Static list<PO_Line_Items__c> updatePOItems = new list<PO_Line_Items__c>();
    public Static list<Shipment__c> shipmentList = new list<Shipment__c>();
    public Static list<Shipment_Line_Item__c> shipmentItemsList = new list<Shipment_Line_Item__c>();
    public static list<SO_Line_Items__c> updtsalesOrderItemsList = new list<SO_Line_Items__c>();
    
    
    global static void updateStatusforPoLIne(List<Purchase_Order__c> newPOList)
    {
        try{
            map<ID,ID> poItemMap = new map<ID,ID>();
            for(PO_Line_Items__c POItem : [Select id,SO_Line_Item__c from PO_Line_Items__c where Purchase_Order__c In :newPOList]) {
                poItemMap.put(POItem.Id, POItem.SO_Line_Item__c);
            }
            
            list<PO_Line_Items__c> POItems = [SELECT Id,SO_Line_Item__c,Purchase_Order__c,PO_Item_Status__c FROM PO_Line_Items__c where Purchase_Order__c In :newPOList];
            list<SO_Line_Items__c> soItemsList = [SELECT Id,Item__c,Sales_Order__c FROM SO_Line_Items__c where id In :poItemMap.values()];
            
            for(Purchase_Order__c newPO: newPOList)
            {
                for(PO_Line_Items__c onePOID : POItems)
                {
                    if(newPO.id == onePOID.Purchase_Order__c)
                    {
                        PO_Line_Items__c onepoItem = new PO_Line_Items__c();
                        onepoItem.Id = onePOID.id;
                        onepoItem.PO_Item_Status__c = 'On Order';
                        
                        updatePOItems.add(onepoItem);
                    }
                }             
                System.debug('soItemsList: '+soItemsList);
                for(SO_Line_Items__c oneSoItemID : soItemsList)
                {
                    if(newPO.Sales_Order__c == oneSoItemID.Sales_Order__c)
                    {
                        SO_Line_Items__c oneSoItem = new SO_Line_Items__c();
                        oneSoItem.Id = oneSoItemID.id;
                        oneSoItem.Item__c = 'Order From Manufacturer';
                        
                        updtsalesOrderItemsList.add(oneSoItem);
                        System.debug('updtsalesOrderItemsList: '+updtsalesOrderItemsList);
                    }
                }
            }
            System.debug('updatePOItems'+updatePOItems);
            if(updatePOItems.size() > 0)
            {
                update updatePOItems;
                update updtsalesOrderItemsList;
            }
        }
        catch(Exception e) {
            system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
        }
    }   
}