global with sharing class CustomLookupController {
    @AuraEnabled
    global static List<Account> obtainAccounts(String accountName){
        accountName = '%'+accountName+'%';
        return [SELECT Name FROM Account WHERE Name LIKE :accountName];
    }
    
    @AuraEnabled
    global static List<sObject> obtainRecords(String sObjectName, String filterField, String searchValue, Boolean isDefaultSearch){
        String queryCondition = ' ';
        if(!isDefaultSearch){
            searchValue = '%'+searchValue+'%';
            queryCondition +=  ' WHERE ' + filterField + ' LIKE :searchValue';
        }else {
            queryCondition = ' WHERE Id = :searchValue ';
            
        }
        String query = 'SELECT Id, '+filterField + ' FROM '+sObjectName + queryCondition; 
        System.debug(query);
        System.debug(searchValue);
        return Database.query(query);
    }

}