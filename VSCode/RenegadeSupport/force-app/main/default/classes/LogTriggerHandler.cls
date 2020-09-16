public with sharing class LogTriggerHandler {

	public static boolean wasCangeManually = true;
    public static void afterUpdate (map<id, Log__c> logOldMap, list<Log__c> logNewList){
        Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
    	if (logNewList[0].Status__c == 'Sent' && logOldMap.get(logNewList[0].id).Status__c != 'Sent'){// && (setting.API_User_ID__c == null || UserInfo.getUserId().contains(setting.API_User_ID__c))){
    		if (wasCangeManually && logNewList[0].Process__c == 'EDI - PO created'){
    			PurchaseOrderOutboundFrom.sendForm(logNewList[0].Object_ID__c);
    		}
    		else if (logNewList[0].Process__c == 'Account created' || logNewList[0].Process__c == 'Account updated' || logNewList[0].Process__c == 'Order updated'){
    			IntegrationManager.sendLogToMagento(logNewList[0].id);
    		}
    	}
    	
    }
    
    public static void afterInsert (list<Log__c> logNewList){
        Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
    	if (logNewList[0].Status__c == 'Sent' && (logNewList[0].Process__c == 'Account created' || logNewList[0].Process__c == 'Account updated' || logNewList[0].Process__c == 'Order updated')){// && (setting.API_User_ID__c == null || UserInfo.getUserId().contains(setting.API_User_ID__c))){
    		IntegrationManager.sendLogToMagento(logNewList[0].id);
    	}
    }
}