public with sharing class ManageShipmentLineItemsController {
    
    private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';

    @AuraEnabled
    public static ResponseWrapper obtainShipmentLines(String objectId) {

        ResponseWrapper response = new ResponseWrapper();

        try{

            String type = ((Id)objectId).getSobjectType().getDescribe().getName();
            
            List<Shipment__c> shipmentList = new List<Shipment__c>();
            if(type == 'Shipment__c'){
                shipmentList = [SELECT Id, Related_Sales_Order__c  FROM Shipment__c WHERE Id = :objectId];
            }
            else if(type == 'Sales_Order__c'){
                shipmentList = [SELECT Id, Related_Sales_Order__c  FROM Shipment__c WHERE Related_Sales_Order__c = :objectId];
            }
            else if(type == 'Case'){
                shipmentList = [SELECT Id, Related_Sales_Order__c  FROM Shipment__c WHERE Related_Sales_Order__c in (SELECT Sales_Order__c FROM Case  where id = :objectId)];
            }

            //Field_Set_Shipment_Line_Items__c fieldSetSetting = Field_Set_Shipment_Line_Items__c.getInstance();
            Map<String, ObjectTypeToFieldSet_for_shl_component__c> objectToFieldSetNameMap = ObjectTypeToFieldSet_for_shl_component__c.getAll();
            Map<String, Schema.FieldSet> fieldSetMap = Schema.SObjectType.Shipment_Line_Item__c.fieldSets.getMap();
            String paramsToSelect = '';
            Set<String> fieldApiSet = new Set<String>{  'Shipment__c', 'Shipment__r.Id', 'Shipment__r.Related_Sales_Order__c', 'Drop_Off_Date_Actual__c',
                                                        'Drop_Off_Date_Expected__c', 'Replacement_Drop_off_Date_Expected__c', 'Replacement_Drop_off_Date_Actual__c',
                                                        'Scheduled_Delivery_Date__c', 'Tech_Scheduled_By__c', 'Repair_Amount__c', 'Repair_Date_Expected__c', 
                                                        'Repair_Date_Actual__c', 'Status_Of_Tech_Needed__c', 'Parts_Information__c', 'Parts_Arrival_Expected__c', 
                                                        'Parts_Arrival_Date_Actual__c','Parts_Are_Shipping__c', 'Tech_Needed_Create_Date__c', 'Shipment_Product_Quantity__c',
                                                        'Tech_Request_Submitted_Date__c', 'Tech_Appointment_Confirmed__c', 'Delivery_Date_Actual__c', 'Consignment_Center__c'};
            for(Schema.FieldSetMember fieldSet_i : fieldSetMap.get(objectToFieldSetNameMap.get(type).Field_Set_name__c).getFields()) {
                fieldApiSet.add(fieldSet_i.getFieldPath());
            }
            for(Schema.FieldSetMember fieldSet_i : fieldSetMap.get('DeliveryCompanyToUpdate').getFields()) {
                fieldApiSet.add(fieldSet_i.getFieldPath());
            }

            if(type == 'Sales_Order__c'){
                fieldApiSet.add('Furniture_Condition__c');
            }
            else if(type == 'Case'){
                fieldApiSet.add('Scheduled_Delivery_Date__c');
            }

            String userType = UserInfo.getUserType();  
            paramsToSelect = String.join(new List<String>(fieldApiSet), ', ');
            String extraCondition = '';

            if(userType == 'PowerCustomerSuccess'){
                List<User> partnerUser = [SELECT Contact.Account.ID FROM User WHERE Id = :UserInfo.getUserId()];
                extraCondition = 'AND Shipment__r.Carrier__c = \'\' AND (Shipment__r.Delivery_Company__c = \'' + partnerUser[0].Contact.Account.Id + '\' OR Shipment__r.Delivery_Company__r.Parentid = \'' + partnerUser[0].Contact.Account.Id + '\')';
            }
            String query = 'SELECT ' + paramsToSelect + ' FROM Shipment_Line_Item__c WHERE Shipment__c in:shipmentList ' + extraCondition + ' ORDER BY Shipment__c';

            List<Shipment_Line_Item__c> shipmentLineItemList = Database.query(query);

            Map<String, Object> resultMap = new Map<String, Object>();

            resultMap.put('salesOrderId', shipmentList[0].Related_Sales_Order__c);
            resultMap.put('columnsData', CustomDynamicTableManager.obtainColumns(fieldSetMap.get(objectToFieldSetNameMap.get(type).Field_Set_name__c).getFields()));
            resultMap.put('rowsData', CustomDynamicTableManager.obtainObjectList(shipmentLineItemList, fieldSetMap.get(objectToFieldSetNameMap.get(type).Field_Set_name__c).getFields()));
            resultMap.put('type', type);
            resultMap.put('fieldSettings', obtainDisplayFieldsSettingsMap());

            response.success = true;
            response.result = resultMap;
        }
        catch(Exception e){
            response.message = parseError(e.getMessage());
            System.debug('Error :: ManageShipmentLineItemsController : '+ e.getMessage()+ ' in line '+ e.getLineNumber());
        }

        return response;
    }

    private static Map<String, Map<String, List<String>>> obtainDisplayFieldsSettingsMap(){
        Map<String, Map<String, List<String>>> result = new Map<String, Map<String, List<String>>> ();
        for(SHL_component_field_displaying_setting__mdt currentFieldSettingsData : [SELECT Field_api_name__c, Damage_action_values_list__c, Status_value_list__c FROM SHL_component_field_displaying_setting__mdt] ){
            result.put(currentFieldSettingsData.Field_api_name__c, 
                new Map<String, List<String>>{
                    'statusValue' => currentFieldSettingsData.Status_value_list__c != null ? clearList(currentFieldSettingsData.Status_value_list__c.split('\\n')) : new List<String>(),
                    'damageValue' => currentFieldSettingsData.Damage_action_values_list__c != null ? clearList(currentFieldSettingsData.Damage_action_values_list__c.split('\\n')) : new List<String>() 
                }
            );
        }
        return result;
    }

    private static List<String> clearList(List<String> stringList){
        List<String> clearedList = new List<String>();
        for(String currentString_i : stringList){
            clearedList.add(currentString_i.trim());
        }
        return clearedList;
    }
    @AuraEnabled
    public static String obtainMetadata(String type) {

        ResponseWrapper response = new ResponseWrapper();

        try{
            List<SelectOptionWrapper> shipmentItemStatusPicklist= new List<SelectOptionWrapper>();
            Schema.DescribeFieldResult fieldResult = Shipment_Line_Item__c.Shipment_Item_Status__c.getDescribe();
            List<Schema.PicklistEntry> entryList = fieldResult.getPicklistValues();

            List<SIStatusExcludeValues__c> statusExcludeList = SIStatusExcludeValues__c.getAll().values();
            String excValues = '';
            for(SIStatusExcludeValues__c excludeValue_i : statusExcludeList){
                excValues = excValues + ' : ' + excludeValue_i.Name ;
            }
            String userType = UserInfo.getUserType();   

            for( Schema.PicklistEntry pickListVal_i : entryList){
                if(!(type == 'Shipment__c' && userType != 'Standard' && excValues.contains(pickListVal_i.getLabel()))){
                    SelectOptionWrapper entry = new SelectOptionWrapper(pickListVal_i.getValue(), pickListVal_i.getLabel());
                    shipmentItemStatusPicklist.add(entry);
                }
            }

            Map<String, Object> resultMap = new Map<String, Object>();

            resultmap.put('Shipment_Item_Status__c', shipmentItemStatusPicklist);
            resultmap.put('Status_Of_Tech_Needed__c', obtainPicklist('Status_Of_Tech_Needed__c'));
            resultmap.put('Furniture_Condition__c', obtainPicklist('Furniture_Condition__c'));

            Map<String, Map<String,List<PicklistEntryWrapper>>> dependencyMap = new Map<String, Map<String,List<PicklistEntryWrapper>>>();

            dependencyMap.put('Damage_Action__c', obtainDependentPicklist('Shipment_Line_Item__c', 'Shipment_Item_Status__c', 'Damage_Action__c'));
            dependencyMap.put('Location_Of_Furniture__c', obtainDependentPicklist('Shipment_Line_Item__c', 'Damage_Action__c', 'Location_Of_Furniture__c'));
            dependencyMap.put('Tech_Scheduled_By__c', obtainDependentPicklist('Shipment_Line_Item__c', 'Damage_Action__c', 'Tech_Scheduled_By__c'));
            dependencyMap.put('No_Fit_Status__c', obtainDependentPicklist('Shipment_Line_Item__c', 'Damage_Action__c', 'No_Fit_Status__c'));
            dependencyMap.put('Sent_Tech_Report__c', obtainDependentPicklist('Shipment_Line_Item__c', 'Damage_Action__c', 'Sent_Tech_Report__c'));
            
            resultMap.put('dependencyMap', dependencyMap);

            response.success = true;
            response.result = resultMap;
        }
        catch(Exception e){
            response.success = false;
            response.message = parseError(e.getMessage());
        }
        
        return JSON.serialize(response);
    }


    @AuraEnabled 
    public static Map<String,List<PicklistEntryWrapper>> obtainDependentPicklist(String ObjectName, string parentField, string childField) {
        Map<String,List<PicklistEntryWrapper>> pickListMap = new Map<String,List<PicklistEntryWrapper>>();
 
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(ObjectName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(parentField) || !objFieldMap.containsKey(childField)){
            return pickListMap;     
        }
        
        List<PicklistEntryWrapper> depEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objFieldMap.get(ChildField).getDescribe().getPicklistValues()), List<PicklistEntryWrapper>.class);
        List<String> controllingValues = new List<String>();
        
        for (Schema.PicklistEntry pickListVal_i : objFieldMap.get(parentField).getDescribe().getPicklistValues()) {
            pickListMap.put(pickListVal_i.getLabel(), new List<PicklistEntryWrapper>());
            controllingValues.add(pickListVal_i.getLabel());
        }
        
        for (PicklistEntryWrapper entryWrap_i : depEntries) {
            String validForBits = base64ToBits(entryWrap_i.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    pickListMap.get(controllingValues.get(i)).add(entryWrap_i);
                }
            }
        }
        
        return pickListMap;
    }

    @AuraEnabled 
    public static ResponseWrapper updateShipmentLines(List<String> shipmentLineIdList, String updatedLine) {
        ResponseWrapper response = new ResponseWrapper();

        Savepoint sp = Database.setSavepoint();
        try{

            Map<String, Object> updatedLineMap = (Map<String, Object>)JSON.deserializeUntyped(updatedLine);

            List<Shipment_Line_Item__c> shipmentLineToUpdateList = new List<Shipment_Line_Item__c>();

            SObjectType objectType = Schema.getGlobalDescribe().get('Shipment_Line_Item__c');
            Map<String,Schema.SObjectField> lineMap = objectType.getDescribe().fields.getMap();

            for(String shipmentId_i : shipmentLineIdList){
                Shipment_Line_Item__c newItem = new Shipment_Line_Item__c();
                for(String field_i : updatedLineMap.keySet()){
                    Schema.SObjectField fieldSchema = lineMap.get(field_i);
                    Schema.DisplayType fieldType = fieldSchema.getDescribe().getType();
                    if(updatedLineMap.get(field_i) == null){
                        newItem.put(field_i, null);
                    }
                    else if(fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Currency){
                        newItem.put(field_i, Decimal.valueOf(String.valueOf(updatedLineMap.get(field_i))));
                    }
                    else if(fieldType == Schema.DisplayType.Date){
                        newItem.put(field_i, Date.valueOf(String.valueOf(updatedLineMap.get(field_i))));
                    }
                    else{
                        newItem.put(field_i, String.valueOf(updatedLineMap.get(field_i)));
                    }
                }
                newItem.Id = shipmentId_i;
                shipmentLineToUpdateList.add(newItem);
            }

            update shipmentLineToUpdateList;

            response.success = true;

        } catch(Exception e) {
            Database.rollback(sp);
            exceptionHandler(e, response);
        }
        return response;
    }

    // static void handelDmlResult(List<Database.SaveResult> saveResultList, ResponseWrapper response){
    //     Set<String> errorFields = new Set<String>();
    //     Set<String> errorMessegess = new Set<String>();
    //     System.debug('handelDmlResult');  
    //     Boolean hasError = false;
    //     for(Database.SaveResult saveResult_i : saveResultList){
    //         if(!saveResult_i.isSuccess()){
    //             hasError = true;
    //             for(Database.Error err : saveResult_i.getErrors()) {
    //                 System.debug('The following error has occurred.');                    
    //                 System.debug(err.getStatusCode() + ': ' + err.getMessage());
    //                 errorMessegess.add(err.getMessage());
    //                 System.debug('Account fields that affected this error: ' + err.getFields());
    //                 errorFields.addAll(err.getFields());
    //             }
    //         }
    //     }
    //     if(hasError){
    //         response.result = errorFields;
    //         response.message = String.join(new List<String>(errorMessegess), ' | ');
    //         response.success = false;
    //     }
    // }

    static void exceptionHandler(Exception ex, ResponseWrapper response){
        response.message = parseError(ex.getMessage() + ' : ' + ex.getStackTraceString());
        response.success = false;
        if(response.message.indexOf('[') != -1 && response.message.indexOf(']') != -1){
            response.result = response.message.substringBetween('[',']').split(',');
        }        
    }

    @AuraEnabled 
    public static ResponseWrapper splitShipmentLines(String selectedLineId, Integer firstGroup, Integer secondGroup) {

        ResponseWrapper response = new ResponseWrapper();

        Savepoint sp = Database.setSavepoint();
        try{
                        
            Schema.DescribeSObjectResult describeResult = Schema.describeSObjects(new List<String>{'Shipment_Line_Item__c'})[0];
            List<String> fields = new List<String>();
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            for (String field_i : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldData = fieldMap.get(field_i).getDescribe();
                if (fieldData.isUpdateable() && fieldData.getName() != 'Id') {
                    fields.add(fieldData.getName());
                }
            }
            String query = 'SELECT ' + String.join(fields, ',') + ' FROM Shipment_Line_Item__c WHERE Id = \'' + selectedLineId + '\'';

            Shipment_Line_Item__c selectedLine = (Shipment_Line_Item__c)Database.query(query)[0];

            Shipment_Line_Item__c newLine = selectedLine.clone(false, true, false, false);
            newLine.Id = null;
            newLine.Shipped_Quantity_Actual__c = newLine.Shipment_Product_Quantity__c = secondGroup;
            
            selectedLine.Shipped_Quantity_Actual__c = selectedLine.Shipment_Product_Quantity__c = firstGroup;

            upsert new List<Shipment_Line_Item__c>{selectedLine, newLine};

            response.success = true;

        } catch(Exception e) {
            Database.rollback(sp);
            response.success = false;
            response.message = parseError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled 
    public static ResponseWrapper connectAttachemnts(List<String> documentIdList, List<String> shipmentIdList) {

        ResponseWrapper response = new ResponseWrapper();

        try{
            List<ContentDocumentLink> linkToInsertList = new List<ContentDocumentLink>();
            for(String docId_i : documentIdList){
                for(String shipmentId_i : shipmentIdList){
                    ContentDocumentLink docLink = new ContentDocumentLink(  linkedEntityId = shipmentId_i,
                                                                            contentDocumentId = docId_i,
                                                                            shareType = 'V');
                    linkToInsertList.add(docLink);
                }
            }
            insert linkToInsertList;
            response.success = true;
        }
        catch(Exception e){
            response.success = false;
            response.message = parseError(e.getMessage());
        }
        return response;
    }

    @AuraEnabled 
    public static ResponseWrapper deleteAttachemnts(List<String> documentIdList) {

        ResponseWrapper response = new ResponseWrapper();

        try{
            List<ContentDocument > docToDeleteList = new List<ContentDocument >();
            for(String docId_i : documentIdList){
                ContentDocument  doc = new ContentDocument (Id = docId_i);
                docToDeleteList.add(doc);
            }
            delete docToDeleteList;
            response.success = true;
        }
        catch(Exception e){
            response.success = false;
            response.message = parseError(e.getMessage());
        }
        
        return response;
    }
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }

    public static List<SelectOptionWrapper> obtainPicklist(String field) {
        List<SelectOptionWrapper> picklistList= new List<SelectOptionWrapper>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get('Shipment_Line_Item__c').getDescribe().fields.getMap().get(field).getDescribe();
        List<Schema.PicklistEntry> entryList = fieldResult.getPicklistValues();       
        for( Schema.PicklistEntry pickListVal : entryList){
            picklistList.add(new SelectOptionWrapper(pickListVal.getValue(), pickListVal.getLabel()));
        }
        return picklistList;
    }

    public static String parseError(String errorMsg){
        if(errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errorMsg = errorMsg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
        }
        return errorMsg;
    }
    
    public class PicklistEntryWrapper{
        public String active;
        public String defaultValue;
        public String label;
        public String value;
        public String validFor;
        
    }

    public class SelectOptionWrapper{
        public String label;
        public String value;

        public SelectOptionWrapper(String value, String label){
            this.value = value;
            this.label = label;
        }
        
    }

}