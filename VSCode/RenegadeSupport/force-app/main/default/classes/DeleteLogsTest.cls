@isTest
private class DeleteLogsTest {
	
	static testMethod void batch(){ 
		Log__c log = new Log__c(Data__c = 'Test', Log_ID__c = '123456789012345678', Object_ID__c = '123456789012345678', Owner__c = 'Salesforce', Process__c = 'Account created', Status__c = 'Succeeded', Tries__c = 1);
		insert log;
		Test.setCreatedDate(log.id, Datetime.now().addDays(-8));
		DeleteLogsBatch CLB = new DeleteLogsBatch();
		Database.executeBatch(CLB);
	}
	
	static testMethod void schedule(){ 
        DeleteLogsSchedule sh1 = new DeleteLogsSchedule();
        String sch = '0 0 23 * * ?'; system.schedule('Test', sch, sh1);
    }
}