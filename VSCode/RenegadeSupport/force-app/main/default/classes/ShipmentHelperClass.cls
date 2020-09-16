/*
*   Author : Mani Kumar | Kairos Tech
*   Class  : ShipmentHelperClass
*   Purpose: This class is to change the status value for Line Item level and support for ShipmentStatusChange trigger.
*/
global class ShipmentHelperClass {
   /* public Static list<Purchase_Order__c> updatePO = new list<Purchase_Order__c>();
    public Static list<PO_Line_Items__c> updatePOItems = new list<PO_Line_Items__c>();
    public Static list<Shipment_Line_Item__c> shipmentItemsList = new list<Shipment_Line_Item__c>();
    public static list<SO_Line_Items__c> updtsalesOrderItemsList = new list<SO_Line_Items__c>();
    
    global static void updateStatusforShipmentandPOandSOItemList(List<Shipment__c> newShipList)
    {
        try{
            list<Id> getpolineItemList = new list<Id>();
            list<Id> getsolineItemList = new list<Id>();
            List<Id> getPOList = new List<Id>();
            
            map<Id,RecordType> shipmentrecordTypemap = new map<Id,RecordType>([SELECT Id,Name FROM RecordType WHERE SobjectType = 'Shipment__c']);
            
            for(Shipment_Line_Item__c oneshipmentLineItem : [Select id,PO_Line_Item__r.Purchase_Order__c,PO_Line_Item__c,PO_Line_Item__r.SO_Line_Item__c,Shipment__c from Shipment_Line_Item__c where Shipment__c In :newShipList]) 
            {
                getPOList.add(oneshipmentLineItem.PO_Line_Item__r.Purchase_Order__c);
                getpolineItemList.add(oneshipmentLineItem.PO_Line_Item__c);
                getsolineItemList.add(oneshipmentLineItem.PO_Line_Item__r.SO_Line_Item__c);
            }
            System.debug('getPOList: '+getPOList);
            System.debug('getpolineItemList: '+getpolineItemList);
            System.debug('getsolineItemList: '+getsolineItemList);
            
            list<Shipment_Line_Item__c> shipItemsList = [SELECT Id,Shipment_Item_Status__c,Shipment__c FROM Shipment_Line_Item__c where Shipment__c In :newShipList];
            list<Purchase_Order__c> POList = [SELECT Id,Status__c,Total_Items_Ordered__c,Total_PO_Items_Loaded__c FROM Purchase_Order__c where id In :getPOList];
            list<PO_Line_Items__c> POItems = [SELECT Id,SO_Line_Item__c,Purchase_Order__c,PO_Item_Status__c FROM PO_Line_Items__c where Id In :getpolineItemList];
            list<SO_Line_Items__c> soItemsList = [SELECT Id,Item__c,Sales_Order__c FROM SO_Line_Items__c where id In :getsolineItemList];
            
            System.debug('soItemsList: '+soItemsList);
            System.debug('POItems: '+POItems);
            
            for(Shipment__c newShip: newShipList)
            {
                for(Shipment_Line_Item__c oneShipID : shipItemsList)
                {
                    if(newShip.id == oneShipID.Shipment__c)
                    {
                        Shipment_Line_Item__c oneshipItem = new Shipment_Line_Item__c();
                        oneshipItem.Id = oneShipID.id;
                        if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Ship Via Delivery Company' || newShip.Carrier__c == 'White Glove') 
                        {
                            if(newShip.Shipment_Status__c == 'En Route Shipments')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Pick Up By Trucking';  
                            }
                            else if(newShip.Shipment_Status__c == 'Received By Warehouse')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Drop Off By Trucking';
                            }
                            else if(newShip.Shipment_Status__c == 'Deluxed No Issues-Waiting On Scheduling')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Deluxing No Issues';  
                            }
                            else if(newShip.Shipment_Status__c == 'Scheduled Shipments')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Routing';  
                            }
                            else if(newShip.Shipment_Status__c == 'Delivered No Issues')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Delivered No Issues';  
                            }
                        }
                        else if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Direct Shipment' || (newShip.Carrier__c != 'White Glove' && newShip.Carrier__c != Null)) {
                            if(newShip.Shipment_Status__c == 'En Route Shipments')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Routing';  
                            }
                            else if(newShip.Shipment_Status__c == 'Delivered No Issues')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Delivered No Issues';  
                            }
                        }
                        else if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Ship To HUB' || newShip.Carrier__c == Null) 
                        {
                            if(newShip.Shipment_Status__c == 'En Route Shipments')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Pick Up By Trucking';  
                            }
                            else if(newShip.Shipment_Status__c == 'Received By Warehouse')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Drop Off By Trucking';
                            }
                            else if(newShip.Shipment_Status__c == 'Scheduled Shipments')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Routing';  
                            }
                            else if(newShip.Shipment_Status__c == 'Delivered No Issues')
                            {
                                oneshipItem.Shipment_Item_Status__c = 'Delivered No Issues';  
                            }
                        }
                        
                        shipmentItemsList.add(oneshipItem);
                    }
                }
                
                for(Purchase_Order__c onePOID : POList)
                {
                    if(newShip.Purchase_Order__c == onePOID.id)
                    {
                        Purchase_Order__c onePOItem = new Purchase_Order__c();
                        onePOItem.Id = onePOID.id;
                        
                        if(onePOID.Total_Items_Ordered__c == onePOID.Total_PO_Items_Loaded__c) 
                        {
                            if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Ship Via Delivery Company' || newShip.Carrier__c == 'White Glove') 
                            {
                                if(newShip.Shipment_Status__c == 'Received By Warehouse')
                                {
                                    onePOItem.Status__c = 'Received';
                                } 
                                else if(newShip.Shipment_Status__c == 'En Route Shipments')
                                {
                                    onePOItem.Load_Date_Actual__c = System.today();                          
                                }
                            }
                            else if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Direct Shipment' || (newShip.Carrier__c != 'White Glove' && newShip.Carrier__c != Null)) 
                            {
                                if(newShip.Shipment_Status__c == 'Delivered No Issues' || newShip.Shipment_Status__c == 'Delivered With Issues')
                                {
                                    onePOItem.Status__c = 'Received';
                                } 
                            }
                            else if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Ship To HUB' || newShip.Carrier__c == Null) 
                            {
                                if(newShip.Shipment_Status__c == 'Received By Warehouse')
                                {
                                    onePOItem.Status__c = 'Received';
                                } 
                                else if(newShip.Shipment_Status__c == 'En Route Shipments')
                                {
                                    onePOItem.Load_Date_Actual__c = System.today();                          
                                }
                            }
                        }
                        
                        updatePO.add(onePOItem);
                    }
                }
                
                for(PO_Line_Items__c onepoItemID :POItems)
                {
                    if(newShip.Purchase_Order__c== onepoItemID.Purchase_Order__c)
                    {
                        PO_Line_Items__c onePOLItem = new PO_Line_Items__c();
                        onePOLItem.Id = onepoItemID.id;
                        
                        if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Ship Via Delivery Company' || newShip.Carrier__c == 'White Glove') 
                        {
                            if(newShip.Shipment_Status__c == 'Received By Warehouse')
                            {
                                onePOLItem.PO_Item_Status__c = 'Received';
                            } 
                            else if(newShip.Shipment_Status__c == 'En Route Shipments')
                            {
                                onePOLItem.PO_Item_Status__c = 'En Routed';  
                            }
                        }
                        else if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Direct Shipment' || (newShip.Carrier__c != 'White Glove' && newShip.Carrier__c != Null)) 
                        {
                            if(newShip.Shipment_Status__c == 'Delivered No Issues' || newShip.Shipment_Status__c == 'Delivered With Issues')
                            {
                                onePOLItem.PO_Item_Status__c = 'Received';
                            } 
                            else if(newShip.Shipment_Status__c == 'En Route Shipments')
                            {
                                onePOLItem.PO_Item_Status__c = 'En Routed';  
                            }
                        }
                        else if(shipmentrecordTypemap.get(newShip.RecordTypeId).name == 'Ship To HUB' || newShip.Carrier__c == Null) 
                        {
                            if(newShip.Shipment_Status__c == 'Received By Warehouse')
                            {
                                onePOLItem.PO_Item_Status__c = 'Received';
                            } 
                            else if(newShip.Shipment_Status__c == 'En Route Shipments')
                            {
                                onePOLItem.PO_Item_Status__c = 'En Routed';  
                            }
                        }
                        updatePOItems.add(onePOLItem);
                    }
                }
                for(SO_Line_Items__c oneSoItemID : soItemsList)
                {
                    SO_Line_Items__c oneSoItem = new SO_Line_Items__c();
                    oneSoItem.Id = oneSoItemID.id;
                    
                    if(newShip.Shipment_Status__c == 'Received By Warehouse')
                    {
                        oneSoItem.Item__c = 'Received By Warehouse';
                    }
                    else if(newShip.Shipment_Status__c == 'Scheduled Shipments')
                    {
                        oneSoItem.Item__c = 'Routing';
                    }
                    else if(newShip.Shipment_Status__c == 'Delivered No Issues')
                    {
                        oneSoItem.Item__c = 'Delivered No Issues';
                    }
                    updtsalesOrderItemsList.add(oneSoItem);
                }
            }
            System.debug('shipmentItemsList'+shipmentItemsList);
            //System.debug('shipmentList'+shipmentList);
            System.debug('updatePO'+updatePO);
            System.debug('updatePOItems: '+updatePOItems);
            System.debug('updtsalesOrderItemsList: '+updtsalesOrderItemsList);
            if(shipmentItemsList.size() > 0)
            {
                //update shipmentList;
                update shipmentItemsList;
                update updatePO;
                update updatePOItems;
                update updtsalesOrderItemsList;
            }
        }
        catch(Exception e) {
            system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
        }
    }*/
}