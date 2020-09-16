/*
*   Author : Mani Kumar | Kairos Tech
*   Class  : ShipmentLineStatusChange
*   Purpose: This trigger is to have validation, approval process and Case creation.
*/
trigger ShipmentLineStatusChange on Shipment_Line_Item__c (before update, after update) {
    /*public list<Shipment_Line_Item__c> updateshipmentLinestatusList;
    public list<Shipment_Line_Item__c> caseCreationList;
    
    if(trigger.isBefore)
    {
        if(trigger.isupdate)
        {
            Set<Id> shipmentWithFile = new Set<Id>();
            Set<Id> shipmentIds = new Set<Id>();
            for(Shipment_Line_Item__c shipment_i : trigger.new){
                shipmentIds.add(shipment_i.Id);
            }
            for(Attachment att_i : [SELECT Id,Name,ParentId FROM Attachment WHERE ParentId In :shipmentIds]){
                shipmentWithFile.add(att_i.ParentId);
            }
            for(ContentDocumentLink contDoc_i : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :shipmentIds]){
                shipmentWithFile.add(contDoc_i.LinkedEntityId);
            }
            for(Shipment_Line_Item__c newShipItem:trigger.new) {
                if(newShipItem.Damage_Action__c == 'Repair' || (newShipItem.Damage_Action__c == 'Replacement' || newShipItem.Damage_Action__c == 'Parts Needed')) 
                {
                    if(!shipmentWithFile.contains(newShipItem.Id)) {
                        newShipItem.addError('Please attach damaged product images');
                    }
                }
            }
        }
    }*/
    
    /*if(trigger.isAfter)
    {
        if(trigger.isupdate)
        {
            updateshipmentLinestatusList = new list<Shipment_Line_Item__c>();
            caseCreationList = new list<Shipment_Line_Item__c>();
            
            //User sysAdmin = [Select id, Profile.Name from User where id=:userInfo.getUserId()];
            for(Shipment_Line_Item__c newShipItem: trigger.new)
            {
                System.debug('newShipItem New Status: '+newShipItem.Shipment_Item_Status__c);
                System.debug('newShipItem New: '+newShipItem.Approval_Status__c);
                System.debug('newShipItem Old: '+trigger.oldmap.get(newShipItem.id).Approval_Status__c);
                /*if(newShipItem.Approval_Status__c == null && (Userinfo.getUserType() == 'PowerCustomerSuccess') && (newShipItem.Shipment_Item_Status__c == 'Deluxed With Issues' || newShipItem.Shipment_Item_Status__c == 'In Home Follow Up')) {
                    Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                    req.setComments('Please Review & Approve this Shipment LineItem');
                    req.setObjectId(newShipItem.Id);
                    // Submit the approval request for the Invoice
                    Approval.ProcessResult result = Approval.process(req);
                }
                System.debug('newShipItem.Shipment_Item_Status__c: '+newShipItem.Shipment_Item_Status__c);
                System.debug('trigger.oldmap.get(newShipItem.id).Shipment_Item_Status__c: '+trigger.oldmap.get(newShipItem.id).Shipment_Item_Status__c);
                if((newShipItem.Shipment_Item_Status__c != trigger.oldmap.get(newShipItem.id).Shipment_Item_Status__c) && ((newShipItem.Shipment_Item_Status__c == 'Deluxed With Issues' || newShipItem.Shipment_Item_Status__c == 'In Home Follow Up')))
                {
                    caseCreationList.add(newShipItem);
                }
                /*if((newShipItem.Shipment_Item_Status__c != trigger.oldmap.get(newShipItem.id).Shipment_Item_Status__c) && (newShipItem.Shipment_Item_Status__c == 'Deluxing with Issue' || newShipItem.Shipment_Item_Status__c == 'Deluxing No Issues'|| newShipItem.Shipment_Item_Status__c == 'Scheduled for Delivery'|| newShipItem.Shipment_Item_Status__c == 'En Route'|| newShipItem.Shipment_Item_Status__c == 'Delivered No Issues'||newShipItem.Shipment_Item_Status__c == 'Pick Up By Trucking'||newShipItem.Shipment_Item_Status__c == 'Delivered With Issues'))
                {
                    updateshipmentLinestatusList.add(newShipItem);
                }
            } 
                System.debug('caseCreationList: '+caseCreationList);
            if(caseCreationList.size() > 0) {
                ShipmentLineItemHelper.caseCreation(caseCreationList);
            }
            /*if(updateshipmentLinestatusList.size() > 0)
            {
                ShipmentLineItemHelper.updateStatusforSOLineitemList(updateshipmentLinestatusList);
            }
        }
    }*/
}