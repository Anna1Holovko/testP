public with sharing class CustomDynamicTableManager {
    
    
    public static List<Column> obtainColumns(List<Schema.FieldSetMember> fieldSetData){
        ResponseWrapper response = new ResponseWrapper();
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
        return columnList;
    }

    public static List<ObjectWrapper>  obtainObjectList(List<SObject> objectList, List<Schema.FieldSetMember> fieldSetData){
        List<ObjectWrapper> responseObjectList = new List<ObjectWrapper>();
        for(SObject obj_i : objectList){
            ObjectWrapper responseObject_i = new ObjectWrapper();
            responseObject_i.lines = new List<ObjectLine>();
            for(Schema.FieldSetMember fieldData_i : fieldSetData){
                ObjectLine line_i = new ObjectLine();
                line_i.type = String.valueOf(fieldData_i.getType());
                line_i.value = getFieldValuefromObjRec(fieldData_i.getFieldPath(), obj_i);
                if(fieldData_i.getFieldPath().endsWithIgnoreCase('name')){
                    line_i.urlLabel = String.valueOf(line_i.value);
                    line_i.value = getFieldValuefromObjRec(fieldData_i.getFieldPath().removeEndIgnoreCase('name')+'Id', obj_i);
                    line_i.type= 'URL';
                }
                line_i.type = line_i.type.toLowerCase();
                responseObject_i.lines.add(line_i);
                
            }
            responseObject_i.obj = obj_i;
            responseObjectList.add(responseObject_i);
        }
        return responseObjectList;
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
        @AuraEnabled
        public Object obj;
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