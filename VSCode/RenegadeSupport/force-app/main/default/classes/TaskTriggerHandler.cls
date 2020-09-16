public with sharing class TaskTriggerHandler {

	public static void afterInsert(list<Task> newTasks){
		set<string> SOToUpdateRelatedPOsIds = new set<string>();
		for (Task t : newTasks){
			if (t.Subject == 'ETA Confirmation Sent'){
				SOToUpdateRelatedPOsIds.add(t.whatid);
			}
		}
		if (SOToUpdateRelatedPOsIds.size() > 0){
			updatePOsETA(SOToUpdateRelatedPOsIds);
		}
	}
	
	private static void updatePOsETA(set<string> SOToUpdateRelatedPOsIds){
		list<Purchase_Order__c> pos = [select Last_ETA_Update__c from Purchase_Order__c where Sales_Order__c in :SOToUpdateRelatedPOsIds];
		if (pos.size() == 0) return;
		for (Purchase_Order__c po : pos){
			po.Last_ETA_Update__c = system.today();
		}
		update pos;
	}
}