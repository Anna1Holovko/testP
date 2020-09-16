/*
*   Author : Mani Kumar | Kairos Tech
*   Class  : ShipmentStatusChange
*   Purpose: This trigger is to change the status value for Line Item level.
*/
trigger ShipmentStatusChange on Shipment__c (after update) {
   /* public list<Shipment__c> updateshipmentstatus;
    
    if(trigger.isAfter)
    {
        if(trigger.isupdate) 
        {
            updateshipmentstatus = new list<Shipment__c>();
            
            for(Shipment__c newShip: trigger.new)
            {
                for(Shipment__c oldShip: trigger.old)
                {
                    if(newShip.Shipment_Status__c != oldShip.Shipment_Status__c && ( newShip.Shipment_Status__c == 'En Route Shipments'|| newShip.Shipment_Status__c == 'Received By Warehouse' || newShip.Shipment_Status__c == 'Deluxed No Issues-Waiting On Scheduling'|| newShip.Shipment_Status__c == 'Scheduled Shipments'|| newShip.Shipment_Status__c == 'Routing'|| newShip.Shipment_Status__c == 'Delivered No Issues'))
                    {
                        updateshipmentstatus.add(newShip);
                    }
                } 
            }
          if(updateshipmentstatus.size() != 0)
          {
              ShipmentHelperClass.updateStatusforShipmentandPOandSOItemList(updateshipmentstatus);
          }
        }
    }*/
}