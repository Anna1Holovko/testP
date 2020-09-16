public without sharing class SalesOrderLineItemsController {

	private final sObject mysObject;
    public List<WrapperShipmentLine> shipmentLineList {get; set;}
    public List<Shipment_Line_Item__c> shipmentLineToUpdateList {get; set;}
    public String newStatus {get; set;}
    public List<SelectOption> pickListValuesList {get; set;}
    public List<String> fieldSets {get; set;}
    public Boolean showError {get; set;}
    public Shipment_Line_Item__c tmpUpdateItem {get; set;}
    public String fieldSetToUpdate {get; set;}
    public map<id, String> statusMap {get; set;}
   // public Attachment deluxingAttachment { get; set; }

    public String fileName {get; set;}
    public String fileBody {get; set;}
    public String userType {get; set;}
    public String urlToNewPo { get; set; } 
    public String selectedId { get; set; } 

    public Boolean isDelivery {get; set;}
    public Boolean isAllDrop_Off_Null{get; set;}

    public String selectedIDs { get; set; }
    public String parentIDs { get; set; }
    
    public Boolean canSplit { get; set; }
    public Boolean atLeastOneItemSelected { get; set; }
    public Integer shipmentProductQuantity { get; set; }
    public Integer splitAmount1 { get; set; }
    public Integer splitAmount2 { get; set; }
    public List<String> statusExcludeValues { get; set; }

    public SalesOrderLineItemsController(ApexPages.StandardController stdController) {
        List<SIStatusExcludeValues__c> statusExcludeList = [Select Name from SIStatusExcludeValues__c];
        statusExcludeValues = new List<String>();
       for(SIStatusExcludeValues__c ste:statusExcludeList){
        statusExcludeValues.add(ste.name);
        }
       // statusExcludeValues = statusExcludeList;
        isAllDrop_Off_Null = true;
        userType = UserInfo.getUserType();
        this.mysObject = (sObject)stdController.getRecord();
        urlToNewPo = '';
        getFieldName();
        getShipmentLines(ApexPages.currentPage().getParameters().get('id'), false);
        getPicklistValue();
        showError = true;
        if (shipmentLineList.size() > 0){
          tmpUpdateItem = shipmentLineList[0].shipment;
          /*tmpUpdateItem.Shipment_Item_Status__c = 'Draft';
          tmpUpdateItem.Damage_Action__c = '';
          tmpUpdateItem.Location_Of_Furniture__c = '';
          tmpUpdateItem.Tech_Scheduled_By__c = '';*/
      }
        fieldSetToUpdate = 'DeliveryCompanyToUpdate';
        
        Profile deliveryProfile = [select name from profile where name = 'Delivery Community Profile' LIMIT 1];
        isDelivery = UserInfo.getProfileId() == deliveryProfile.Id;
    }

    public void pageRefresh(){
        getShipmentLines(ApexPages.currentPage().getParameters().get('id'), true);
    }  
    
    public List<WrapperShipmentLine> getShipmentLines(String salesOrderId, boolean runAgain) {
        
        System.debug('salesOrderId: ' + salesOrderId);
        List<Shipment__c> shipmentList = [SELECT Id, Delivery_Company__c  FROM Shipment__c WHERE Related_Sales_Order__c = :salesOrderId];
        System.debug('shipmentList: ' + shipmentList);
        Field_Set_Shipment_Line_Items__c fieldSetSetting = Field_Set_Shipment_Line_Items__c.getInstance();
        System.debug('fieldSetSetting: ' + fieldSetSetting.Value__c);

        Map<String, Schema.FieldSet> fieldSetMap = Schema.SObjectType.Shipment_Line_Item__c.fieldSets.getMap();
        Set<String> fieldApiSet = new Set<String>();
        String paramsToSelect = '';
        
        for(Schema.FieldSetMember f : fieldSetMap.get(fieldSetSetting.Value__c).getFields()) {
            fieldApiSet.add(f.getFieldPath());
        }
        for(Schema.FieldSetMember f : fieldSetMap.get('DeliveryCompanyToUpdate').getFields()) {
            fieldApiSet.add(f.getFieldPath());
            
        }
        fieldApiSet.add('Shipment__c');
        fieldApiSet.add('Shipment__r.Id');
        fieldApiSet.add('Shipment__r.Related_Sales_Order__c');
        fieldApiSet.add('Drop_Off_Date_Actual__c');
        if (!fieldApiSet.contains('Drop_Off_Date_Expected__c')){
          fieldApiSet.add('Drop_Off_Date_Expected__c');
        }
        fieldApiSet.add('Replacement_Drop_off_Date_Expected__c');
        fieldApiSet.add('Replacement_Drop_off_Date_Actual__c');
        fieldApiSet.add('Furniture_Condition__c');

        fieldApiSet.add('Scheduled_Delivery_Date__c');
        fieldApiSet.add('Tech_Scheduled_By__c');
        fieldApiSet.add('Repair_Amount__c');
        fieldApiSet.add('Repair_Date_Expected__c');
        fieldApiSet.add('Repair_Date_Actual__c');
        fieldApiSet.add('Status_Of_Tech_Needed__c');
        fieldApiSet.add('Parts_Information__c');
        fieldApiSet.add('Parts_Arrival_Expected__c');
        fieldApiSet.add('Parts_Arrival_Date_Actual__c');
        fieldApiSet.add('Parts_Are_Shipping__c');
        fieldApiSet.add('Tech_Needed_Create_Date__c');
        fieldApiSet.add('Tech_Request_Submitted_Date__c');
        fieldApiSet.add('Tech_Appointment_Confirmed__c');
        fieldApiSet.add('Delivery_Date_Actual__c');
        fieldApiSet.add('Shipment_Product_Quantity__c');
        
        paramsToSelect = String.join(new List<String>(fieldApiSet), ' , ');
        //String deliveryCompany = '';
        //if(shipmentList.size() > 0 && shipmentList.get(0).Delivery_Company__c != null){
        //    deliveryCompany = shipmentList.get(0).Delivery_Company__c;
        //}
    String extraCondition = '';
        if(userType == 'PowerCustomerSuccess'){
            List<User> partnerUser = [SELECT Contact.Account.Id FROM User WHERE Id = :UserInfo.getUserId()];
            extraCondition = 'AND Shipment__r.Carrier__c != \'LTL\' AND (Shipment__r.Delivery_Company__c = \'' + partnerUser[0].Contact.Account.Id + '\' or Shipment__r.Delivery_Company__r.Parentid = \'' + partnerUser[0].Contact.Account.Id + '\')';
        }
        String query = 'SELECT ' + paramsToSelect + ' FROM Shipment_Line_Item__c WHERE Shipment__c in:shipmentList ' + extraCondition + ' ORDER BY Shipment__c';
        //String query = tmpQuery.replace(', FROM', ' FROM');
        System.debug('query: ' + query);


        if(shipmentLineList == null || runAgain) {
            shipmentLineList = new List<WrapperShipmentLine>();
            for(Shipment_Line_Item__c c:  Database.query(query)) {
              if (statusMap == null){
              statusMap = new map<id, String>();
              }
            System.debug('c: ' + c);
              statusMap.put(c.id, c.Shipment_Item_Status__c);
                WrapperShipmentLine wrapper = new WrapperShipmentLine(c);
                wrapper.isSelected = false;
                shipmentLineList.add(wrapper);
            }
        }
        System.debug('shipmentLineList: ' + shipmentLineList);
        System.debug('statusMap: ' + statusMap);
        return shipmentLineList;
    }

    public void getFieldName(){
        Field_Set_Shipment_Line_Items__c fieldSetSetting = Field_Set_Shipment_Line_Items__c.getInstance();
        System.debug('fieldSetSetting: ' + fieldSetSetting.Value__c);

        Map<String, Schema.FieldSet> fieldSetMap = Schema.SObjectType.Shipment_Line_Item__c.fieldSets.getMap();
        System.debug(fieldSetMap);
        fieldSets = new List<String>();
        for(Schema.FieldSetMember f : fieldSetMap.get(fieldSetSetting.Value__c).getFields()) {
            fieldSets.add(f.getFieldPath());
        }
    }
/****************************Start**********************************/
    public List<SelectOption> getPicklistValue(){
       pickListValuesList= new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Shipment_Line_Item__c.Shipment_Item_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
        }     
        System.debug('pickListValuesList: ' + pickListValuesList);
        return pickListValuesList;
    }
    
    public void updateSelected() {
        
        System.debug('shipmentLineToUpdateList: ' + shipmentLineToUpdateList);
        System.debug('tmpUpdateItem: ' + tmpUpdateItem);
        //String status = newStatus.substring(1, newStatus.length()-1);
        //for(Shipment_Line_Item__c shipment: shipmentLineToUpdateList) {
        //    shipment.Shipment_Item_Status__c = newStatus;
        //}
        selectedIDs = '';
        for(WrapperShipmentLine wrapper: shipmentLineList) {
            wrapper.isSelected = false;
        }
        Savepoint sp = Database.setSavepoint();
        try{

            /*if(shipmentLineToUpdateList.size() > 1 && (tmpUpdateItem.Shipment_Item_Status__c == 'Deluxed With Issues' || tmpUpdateItem.Shipment_Item_Status__c ==  'In Home Follow Up')){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Can\'t update multiple shipment with "deluxing with issue" status'));
              for(Shipment_Line_Item__c c:  shipmentLineToUpdateList) {
                c.Shipment_Item_Status__c = statusMap.get(c.id);
              }
                return;
            } */   

            Schema.FieldSet updateFieldSet = Schema.SObjectType.Shipment_Line_Item__c.fieldSets.getMap().get(fieldSetToUpdate);
            System.debug('updateFieldSet: ' + updateFieldSet);
            for(Shipment_Line_Item__c shipItem_i : shipmentLineToUpdateList){
                selectedIDs += shipItem_i.id +';'; 
                for(Schema.FieldSetMember field_i : updateFieldSet.getFields()){
                    if(field_i.getFieldPath().contains('.')){
                        Object fieldToset = tmpUpdateItem.getSObject(field_i.getFieldPath().substringBefore('.').trim()).get(field_i.getFieldPath().substringAfter('.').trim());
                        shipItem_i.getSObject(field_i.getFieldPath().substringBefore('.').trim()).put(field_i.getFieldPath().substringAfter('.').trim(), fieldToset);
                        //shipItem_i.putSObject(field_i.getFieldPath(), tmpUpdateItem.get(field_i.getFieldPath()));
                    }else{
                        shipItem_i.put(field_i.getFieldPath(), tmpUpdateItem.get(field_i.getFieldPath()));
                    }   

                    
                }
                if(tmpUpdateItem.Shipment_Item_Status__c == 'Scheduled Delivery'){
                    shipItem_i.Scheduled_Delivery_Date__c = tmpUpdateItem.Scheduled_Delivery_Date__c;
                }
                if(tmpUpdateItem.Shipment_Item_Status__c == 'Delivered No Issues'){
                    shipItem_i.Delivery_Date_Actual__c = tmpUpdateItem.Delivery_Date_Actual__c;
                }
                if ((tmpUpdateItem.Shipment_Item_Status__c == 'At Local Delivery Company' || tmpUpdateItem.Shipment_Item_Status__c == 'Scheduled Delivery')  
                                                        || ((tmpUpdateItem.Shipment_Item_Status__c == 'Deluxed No Issues' 
                                                        || tmpUpdateItem.Shipment_Item_Status__c == 'Deluxed With Issues' 
                                                        || tmpUpdateItem.Shipment_Item_Status__c == 'In Home Follow Up'
                                                        || tmpUpdateItem.Shipment_Item_Status__c == 'Send to Consignment'
                                                        || tmpUpdateItem.Shipment_Item_Status__c == 'Refused Delivery' || tmpUpdateItem.Shipment_Item_Status__c == 'Delivered No Issues') && isAllDrop_Off_Null == true)){
                  shipItem_i.Drop_Off_Date_Actual__c = tmpUpdateItem.Drop_Off_Date_Actual__c;
                }
                shipItem_i.Repair_Date_Expected__c = tmpUpdateItem.Repair_Date_Expected__c;
                shipItem_i.Replacement_Drop_off_Date_Expected__c = tmpUpdateItem.Replacement_Drop_off_Date_Expected__c;
                shipItem_i.Replacement_Drop_off_Date_Actual__c = tmpUpdateItem.Replacement_Drop_off_Date_Actual__c;
            }
            System.debug(fileBody);
            System.debug(fileName);

            selectedId = shipmentLineToUpdateList.get(0).Id;
            //if(fileName != null && (tmpUpdateItem.Shipment_Item_Status__c == 'Deluxed With Issues' || tmpUpdateItem.Shipment_Item_Status__c ==  'In Home Follow Up' || tmpUpdateItem.Shipment_Item_Status__c == 'Refused Delivery')){
            //    Attachment deluxingAttachment = new Attachment();
            //    deluxingAttachment.Name = fileName;
            //    String dat = fileBody.substringAfterLast(',');
            //    fileBody = null;
            //    deluxingAttachment.Body = EncodingUtil.base64Decode(dat);
            //    deluxingAttachment.ParentId = shipmentLineToUpdateList.get(0).Id;
            //    insert deluxingAttachment;
            //}
            if(shipmentLineToUpdateList.size() > 0){
                if(shipmentLineToUpdateList.get(0).Shipment__r != null){
                    update shipmentLineToUpdateList.get(0).Shipment__r;
                }
            }


            update shipmentLineToUpdateList;
            
               
            getShipmentLines(ApexPages.currentPage().getParameters().get('id'), true);
            if (shipmentLineList.size() > 0){
                tmpUpdateItem.Shipment_Item_Status__c = statusMap.get(shipmentLineList[0].shipment.id);
            }
        } catch(Exception e) {
            Database.rollback(sp);
          getShipmentLines(ApexPages.currentPage().getParameters().get('id'), true);
          tmpUpdateItem = shipmentLineList[0].shipment;
            if (e.getMessage().contains('Please')){
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please' + e.getMessage().split('Please', 2)[1]) );
            }
            else{
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage() + e.getStackTraceString()));
            }
        }
        clearFile(); 
    }

    public void collectIds() {
        selectedIDs = '';
        parentIDs = '';
        for(Shipment_Line_Item__c shipItem_i : shipmentLineToUpdateList){
            selectedIDs += shipItem_i.id +';';
            parentIDs += shipItem_i.Shipment__c +';'+shipItem_i.Shipment__r.Related_Sales_Order__c;
        } 
    }
    
    public void clearFile(){
        fileBody = null;
        fileName = null; 
    }
    
    public void cancel(){
        shipmentLineList = getShipmentLines(ApexPages.currentPage().getParameters().get('id'), true);
        tmpUpdateItem = shipmentLineList[0].shipment;
    }

    public void processSelected() {
        System.debug('processSelected');
        String salesOrderId = ApexPages.currentPage().getParameters().get('id');
        List<Shipment__c> shipmentList = [SELECT Id, Delivery_Company__c FROM Shipment__c WHERE Related_Sales_Order__c = :salesOrderId];
        System.debug('shipmentList: ' + shipmentList);
        Field_Set_Shipment_Line_Items__c fieldSetSetting = Field_Set_Shipment_Line_Items__c.getInstance();
        System.debug('fieldSetSetting: ' + fieldSetSetting.Value__c);

        List<Shipment_Line_Item__c> selectedContacts = new List<Shipment_Line_Item__c>();
        for(WrapperShipmentLine wrap: getShipmentLines(salesOrderId, false)) {
            if(wrap.isSelected == true) {
                selectedContacts.add(wrap.shipment);
            }
            else {
              wrap.shipment.Shipment_Item_Status__c = statusMap.get(wrap.shipment.id);
            }
        }

        System.debug('These are the selected Contacts...');
        shipmentLineToUpdateList= new List<Shipment_Line_Item__c>();
        isAllDrop_Off_Null = true;
        for(Shipment_Line_Item__c shipment: selectedContacts) {
            shipmentLineToUpdateList.add(shipment);
            System.debug('shipment: ' + shipment);
            if(shipment.Drop_Off_Date_Actual__c != null){
                isAllDrop_Off_Null = false;
            }
        }

        System.debug('selectedContacts: ' + selectedContacts);
        if(selectedContacts.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select Shipment Line Item'));
            showError = true;

        }else {
            showError = false;

        }

            
    }
  
    public void goToNewReplacementPO(){
        urlToNewPo = '';
        List<Id> selectedID = new List<Id>();
        String salesOrderId = ApexPages.currentPage().getParameters().get('id');
        for(WrapperShipmentLine wrap: getShipmentLines(salesOrderId, false)) {
            if(wrap.isSelected == true) {
                selectedID.add(wrap.shipment.Id);
            }
        }

        if(selectedID.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select Shipment Line Item'));
            showError = true;
            return;

        }else {
            showError = false;

        }

        
        PageReference pdfPageReference =  Page.ReplacePurchaseOrderPage;
        pdfPageReference.getParameters().put('solids', String.join(selectedID, ','));
        pdfPageReference.getParameters().put('id', salesOrderId);
        urlToNewPo = ApexPages.currentPage().getHeaders().get('Host') + pdfPageReference.getUrl();
    }
  
    public void goToNewPartPO(){
        urlToNewPo = '';
        List<Id> selectedID = new List<Id>();
        String salesOrderId = ApexPages.currentPage().getParameters().get('id');
        for(WrapperShipmentLine wrap: getShipmentLines(salesOrderId, false)) {
            if(wrap.isSelected == true) {
                selectedID.add(wrap.shipment.Id);
            }
        }

        if(selectedID.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please select Shipment Line Item'));
            showError = true;
            return;

        }else {
            showError = false;

        }

        
        PageReference pdfPageReference =  Page.ReplacePartPage;
        pdfPageReference.getParameters().put('solids', String.join(selectedID, ','));
        pdfPageReference.getParameters().put('id', salesOrderId);
        urlToNewPo = ApexPages.currentPage().getHeaders().get('Host') + pdfPageReference.getUrl();
    }

    public void splitSaveHandle() {
        String currentId = ApexPages.currentPage().getParameters().get('id');
        system.debug(splitAmount1 + ';' + splitAmount2);
        for (WrapperShipmentLine wrap : shipmentLineList) {
            if (wrap.isSelected) {
                system.debug(wrap.shipment);
                if (splitAmount1 + splitAmount2 == wrap.shipment.Shipment_Product_Quantity__c && splitAmount1 > 0 && splitAmount2 > 0) {
                    Shipment_Line_Item__c newShipment = (Shipment_Line_Item__c)wrap.shipment.clone(false, true, false, false);
                    
                    Schema.DescribeSObjectResult describeResult = Schema.describeSObjects(new List<String>{'Shipment_Line_Item__c'})[0];
          List<String> fields = new List<String>();
                    Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
                    for (String field_i : fieldMap.keySet()) {
                        Schema.DescribeFieldResult fieldData = fieldMap.get(field_i).getDescribe();
                        if (fieldData.isUpdateable() && fieldData.getName() != 'Id') {
                            fields.add(fieldData.getName());
                        }
                    }
                    
                    String sliId = wrap.shipment.Id;
                    String query = 'SELECT ' + String.join(fields, ',') + ' FROM Shipment_Line_Item__c WHERE Id =: sliId';
                    newShipment = (Shipment_Line_Item__c)Database.query(query)[0];
                    newShipment.Id = null;
                    newShipment.Shipped_Quantity_Actual__c = newShipment.Shipment_Product_Quantity__c = splitAmount2;
                    
                    //wrap.shipment.Shipment_Item_Status__c = 'Cancelled';
                    wrap.shipment.Shipped_Quantity_Actual__c = wrap.shipment.Shipment_Product_Quantity__c = splitAmount1;
                    
                    canSplit = atLeastOneItemSelected = showError = false;
                    insert newShipment;
                    update wrap.shipment;
                }
                else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Sum of both fields must be equal Quantity of Shipment Line Item'));
                    showError = true;
                }
            }
        }
        pageRefresh();
    }
    
    public void splitButtonHandle() {
        Integer selectedCount = 0;
        for (WrapperShipmentLine wrap : shipmentLineList) {
            if (wrap.isSelected) {
                ++selectedCount;
            }
        }
        
        if (selectedCount > 1) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING, 'To split please select only 1 Shipment Line Item'));
            showError = true;
        }else {
            showError = false;
        }
    }

    public void selectionCount() {
        Integer selectedCount = 0, selectedQuantityCount = 0;
        for (WrapperShipmentLine wrap : shipmentLineList) {
            if (wrap.isSelected) {
                ++selectedCount;
                if (wrap.shipment.Shipment_Product_Quantity__c > 1) {
                    shipmentProductQuantity = (Integer)wrap.shipment.Shipment_Product_Quantity__c;
                    ++selectedQuantityCount;
                }
            }
        }
        canSplit = selectedQuantityCount > 0;
        atLeastOneItemSelected = selectedCount > 0;
        if (selectedQuantityCount > 0) {
            splitAmount1 = 1;
            splitAmount2 = shipmentProductQuantity - 1;
            system.debug('splitAmount: ' + splitAmount1 + ';' + splitAmount2);
        }
        system.debug('selectedCount: ' + selectedCount);
        system.debug('selectedQuantityCount: ' + selectedQuantityCount);
    }
    
  public class WrapperShipmentLine {
        public Shipment_Line_Item__c shipment {get; set;}
        public Boolean isSelected {get; set;}

        public WrapperShipmentLine(Shipment_Line_Item__c ship){
            this.shipment = ship;
            this.isSelected = false;
        }
    }
}