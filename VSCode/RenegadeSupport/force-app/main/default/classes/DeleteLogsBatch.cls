global with sharing class DeleteLogsBatch implements Database.Batchable<SObject>, Database.Stateful {
	
    // private date d = system.today().adddays(-7);
	// private string dstr = string.valueof(d).substring(0,10) + 'T00:00:00Z';
    //public string query = 'SELECT id FROM Log__c WHERE Status__c = \'Succeeded\' and CreatedDate < ' + dstr; // query Of Smoker
    public String query = 'SELECT id FROM Log__c WHERE (Status__c = \'Succeeded\' AND CreatedDate < LAST_WEEK) OR (Status__c = \'Failed\' AND LastModifiedDate < LAST_MONTH)'; //query Of Healthy Person
	
    global Database.querylocator start(Database.BatchableContext BC){
        system.debug('query = ' + query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        system.debug('scope = ' + scope);
    	delete scope;
    }
    
    global void finish(Database.BatchableContext BC){
    }
}