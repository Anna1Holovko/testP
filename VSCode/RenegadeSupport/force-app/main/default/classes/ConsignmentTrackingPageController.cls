public class ConsignmentTrackingPageController {
    
    public WrapperShipmentLineItem[] shipmentLineItemlist{get;set;}
    private shipment__c shipmentRecord;
    public Shipment_Line_Item__c recordToUpdate{get;set;}
    public boolean showError{get;set;}
    public integer selectedRecordCount{get; set;}
    private map<string, string[]> fieldDependencyMap;
    
    /* Initializing variables in constructor */
    public ConsignmentTrackingPageController(ApexPages.StandardController stdController){
        showError=false;
        selectedRecordCount=0;
        
        //Initializing the field Dependency Map
        fieldDependencyMap = new map<string, string[]>();
        fieldDependencyMap.put('Item_Condition__c', new string[]{'Item_s_Popularity__c'});
        fieldDependencyMap.put('Received_reimbursement_from_3rd_party__c', new string[]{'Received_Reimbursement_Amount__c'});
        fieldDependencyMap.put('Consignment_Status__c', new string[]{'Method_of_Transport__c','Pickup_Drop_off_Cost__c','Consignment_Schedule_Date__c'});
        fieldDependencyMap.put('Item_status_at_consignment__c', new string[]{'Renegade_received_check__c','Check_amount__c','Check_date__c','Check_number__c','Reason_for_Disposed_Donated__c'});
        //system.debug(fieldDependencyMap);
        
        recordToUpdate = new Shipment_Line_Item__c();
        recordToUpdate.Shipment_Item_Status__c='Send to Consignment';
        
        shipmentLineItemlist = new WrapperShipmentLineItem[]{};
        this.shipmentRecord = (shipment__c)stdController.getRecord();
        system.debug('Shipment RecordId: '+shipmentRecord.Id);
        
        Shipment_Line_Item__c[] SLIs = getSLIs(shipmentRecord.Id);
        if(SLIs.size()>0){
            for(Shipment_Line_Item__c SLI: SLIs){
                WrapperShipmentLineItem wrapperSLI = new WrapperShipmentLineItem(SLI);
                shipmentLineItemlist.add(wrapperSLI);
            }
        }
	}
    
    /* Getting  the shipment line item details */
    public Shipment_Line_Item__c[] getSLIs(Id ShipmentId){
        string[] fieldlist=new string[]{};
        fieldlist = getConsignmentRelatedFields();
        string fieldsToQuery;
        for(string fieldname : fieldList){
            if(string.isEmpty(fieldsToQuery))
                fieldsToQuery=fieldname;
            else
                fieldsToQuery=fieldsToQuery+','+fieldname;
        }
        string query = 'select '+fieldsToQuery+',id,name,Product_Name__c,Quantity__c,Image__c,Shipment_Product_Name__c,Shipment_Product_SKU__c,Scheduled_Delivery_Date__c from Shipment_Line_Item__c where Shipment__c=:ShipmentId';
        
        return Database.query(query);
    }
    
    public void updateShipmentLineItemStatus(){
        boolean noItemSelected=true;
        integer selectCount=0;
        
        for(WrapperShipmentLineItem WSLI : shipmentLineItemlist){
            if(WSLI.isSelected==true){
                recordToUpdate=WSLI.SLI;
                selectCount++;
                noItemSelected=false;
            }
        }
        
        selectedRecordCount=selectCount;
        if(selectCount>1){
            recordToUpdate = new Shipment_Line_Item__c();
        	recordToUpdate.Shipment_Item_Status__c='Send to Consignment';
        }
        
    }
    
    public void checkForErrors(){
        system.debug(recordToUpdate.Shipment_Item_Status__c);
        boolean noItemSelected=true;
        integer selectCount=0;
        for(WrapperShipmentLineItem WSLI : shipmentLineItemlist){
            if(WSLI.isSelected==true){
                selectCount++;
                noItemSelected=false;
            }
        }
        
        if(noItemSelected==true){
            showError = true;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select Shipment Line Item'));
        }
    }
    
    public pagereference updateLineItems(){
        
            Shipment_Line_Item__c[] SLIsToUpdate = new Shipment_Line_Item__c[]{}; 
            for(WrapperShipmentLineItem WSLI : shipmentLineItemlist){
                if(WSLI.isSelected==true){
                    string[] fieldlist=new string[]{};
                    fieldlist = getConsignmentRelatedFields();
                    for(string fieldname : fieldList){
                        system.debug('FieldName: '+fieldName);
                        Map<String, Schema.SObjectField> fieldMap =  Schema.SObjectType.shipment_line_item__c.fields.getMap();
                        Schema.DisplayType fielddataType = fieldMap.get(fieldname).getDescribe().getType();
                        
                        if(fielddataType.name()=='BOOLEAN' && recordToUpdate.get(fieldname)==NULL)
							WSLI.SLI.put(fieldname,false);
                        else{
                            if(recordToUpdate.get(fieldname)!=NULL)
                        		WSLI.SLI.put(fieldname,recordToUpdate.get(fieldname));
                        }
                    }
                    SLIsToUpdate.add(WSLI.SLI);
                }
            }
            if(SLIsToUpdate.size()>0)
                update SLIsToUpdate;
        
        PageReference pageRef = new pageReference('/apex/ConsignmentTrackingPage?id='+shipmentRecord.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public pagereference cancel(){
        PageReference pageRef = new pageReference('/apex/ConsignmentTrackingPage?id='+shipmentRecord.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public static string[] getConsignmentRelatedFields(){
        //Getting fields from fieldset
        Schema.FieldSet fs1 = Schema.SObjectType.Shipment_line_item__c.fieldSets.getMap().get('Consignment_Tracking_Fields');
        FieldSetMember[] fsmList=fs1.getFields();
        string[] fieldNames=new string[]{};
            for(FieldSetMember fsm: fsmList){
                fieldNames.add(fsm.getFieldPath());
            }
        return fieldNames;
    }
    
    public class WrapperShipmentLineItem {
        public Shipment_Line_Item__c SLI {get; set;}
        public Boolean isSelected {get; set;}

        public WrapperShipmentLineItem(Shipment_Line_Item__c ship){
            this.SLI = ship;
            this.isSelected = false;
        }
    }
}