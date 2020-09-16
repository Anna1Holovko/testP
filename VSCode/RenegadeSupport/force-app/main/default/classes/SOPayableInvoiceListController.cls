public class SOPayableInvoiceListController {
	static String type='Invoice__c';
	static Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
    static Schema.SObjectType leadSchema = schemaMap.get(type);
    
    /*
    @AuraEnabled
    public static ResponseWrapper obtainsPayablesInvoice(String salesOrderID){
         System.debug(salesOrderID);
        ResponseWrapper response = new ResponseWrapper();
        try{
        List<Schema.FieldSetMember>  fieldSetData = Schema.SObjectType.Invoice__c.fieldSets.SO_Payable_List.getFields();
        List<Invoice__c> invoiceList;
        //id testId= 'a0M3B000003F1XdUAK';
        String query = 'SELECT id, ';
        List<String> columnApiName = new List<String>();
        for(Schema.FieldSetMember fieldData : fieldSetData){
             columnApiName.add(fieldData.getFieldPath());
        }
        query+= String.join(columnApiName, ',');
        query+=' FROM Invoice__c WHERE Sales_Order__c = \'' +salesOrderID + '\' AND RecordType.Name = \'Payables\'';
        System.debug('query ' + query);
        invoiceList = Database.query(query);
        /*invoiceList = [SELECT id, Name, RecordType.Name, Items_invoiced__c, Customer_Name__c, Sub_Total__c, TaxAmount__c, DiscountAmount__c, Grand_Total__c 
                FROM Invoice__c 
                WHERE Sales_Order__c = :testId AND RecordType.Name = 'Payables'];
        
        Map<String, List<Object>> columnDataMap = new Map<String, List<Object>> ();
        for(Schema.FieldSetMember fieldData : fieldSetData){
            String dataType = String.valueOf(fieldData.getType()).toLowerCase();
            Map<String, String> dataAtribute = new Map<String, String>();
            if(dataType=='integer' || dataType=='double' ){
                dataType ='number';
            }
            if(fieldData.getFieldPath().contains('.') && dataType!='date'){
                dataType = 'url';
                //dataAtribute.put('lable','test'); 
            }
            columnDataMap.put(fieldData.getFieldPath(), new List<Object>{fieldData.getLabel(), dataType, dataAtribute});//.replace('.', '_')
        }
        
		Map<String, Object> resultMap = new Map<String, Object>();
        resultMap.put('columnsData', columnDataMap);
        resultMap.put('rowsData', invoiceList);
        
        response.success = true;
        response.result = resultMap;
        }catch(Exception ex){
            response.message = ex.getMessage()+' | in line: '+ex.getLineNumber(); 
        }
        return response;
    
    
    }

*/
     @AuraEnabled
    public static ResponseWrapper obtainsPayablesInvoiceList(String salesOrderID){
        ResponseWrapper response = new ResponseWrapper();
        try{
            List<Schema.FieldSetMember>  fieldSetData = Schema.SObjectType.Invoice__c.fieldSets.SO_Payable_List.getFields();
            List<String> columnApiName = new List<String>();
            
            List<Column> columnList = new List<Column>();
            for(Schema.FieldSetMember fieldData_i : fieldSetData){
                columnApiName.add(fieldData_i.getFieldPath());

                Column column_i = new Column();
                column_i.Name = fieldData_i.getLabel();
                column_i.Path = fieldData_i.getFieldPath();
                column_i.Type = String.valueOf(fieldData_i.getType());

                columnList.add(column_i);

            }    

            String query = 'SELECT Id, ' + String.join(columnApiName, ',') +' FROM Invoice__c WHERE Sales_Order__c = \'' +salesOrderID + '\' AND RecordType.Name = \'Payables\'';
            List<Invoice__c> invoiceList = Database.query(query);
            List<ObjectWrapper> responseObjectList = new List<ObjectWrapper>();
            for(Invoice__c invoice_i : invoiceList){
                ObjectWrapper responseObject_i = new ObjectWrapper();
                responseObject_i.lines = new List<ObjectLine>();
                for(Schema.FieldSetMember fieldData_i : fieldSetData){
                    ObjectLine line_i = new ObjectLine();
                    line_i.type = String.valueOf(fieldData_i.getType());
                    line_i.value = getFieldValuefromObjRec(fieldData_i.getFieldPath(), invoice_i);
                    if(fieldData_i.getFieldPath().endsWithIgnoreCase('name')){
                        line_i.urlLabel = String.valueOf(line_i.value);
                        line_i.value = getFieldValuefromObjRec(fieldData_i.getFieldPath().removeEndIgnoreCase('name')+'Id', invoice_i);
                        line_i.type= 'URL';
                    }
                    line_i.type = line_i.type.toLowerCase();
                    responseObject_i.lines.add(line_i);
                    
                }
                responseObjectList.add(responseObject_i);
            }

            Map<String, Object> resultMap = new Map<String, Object>();
            resultMap.put('columnsData', columnList);
            resultMap.put('rowsData', responseObjectList);
            
            response.success = true;
            response.result = resultMap;

        }catch(Exception ex){
            response.message = ex.getMessage()+' | in line: '+ex.getLineNumber(); 
        }
        return response;
    }

    private static Object getFieldValuefromObjRec(string objField,sObject sObj) {
        Object res = null;
        if(!objField.contains('.')) {
            if(sObj.get(objField) != null) {
                res = sObj.get(objField);
            }
            return res;
        } else {
            if(sObj.getSObject(objField.substringBefore('.')) != null) {
                return getFieldValuefromObjRec(objField.substringAfter('.').trim(), sObj.getSObject(objField.substringBefore('.').trim()));
            }
        }
        return res;
    }
    
    
    public class ResponseWrapper{
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public Object result;
        @AuraEnabled
        public String message;
        public ResponseWrapper(){
            this.success = false;
        }
    }

    public class Column{
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String Type;
        @AuraEnabled
        public String Path;
    }

    public class ObjectWrapper{
        @AuraEnabled
        public List<ObjectLine> lines;
    }

    public class ObjectLine{
        @AuraEnabled
        public Object value;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String urlLabel;
        @AuraEnabled
        public String currencyISOCode;
    }
}