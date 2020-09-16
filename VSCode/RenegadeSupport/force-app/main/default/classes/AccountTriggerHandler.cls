public with sharing class AccountTriggerHandler {
	public static Boolean emailSynchronized = false;
	private static list<Salesforce_Magento_Field_Mapping__mdt> mtd {get; set;}

    public static void afterInsert (list<Account> accNewList){
	    Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
	    if (accNewList[0].Email__c != null && setting.API_User_ID__c != null && !UserInfo.getUserId().contains(setting.API_User_ID__c) && accNewList[0].RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()){
			createUpdateLog(accNewList[0], 'Account created');
	    }
    }

    public static void afterUpdate (map<id, Account> accOldMap, list<Account> accNewList){
	    Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
		mtd = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Magento_field_API_name__c != null and SF_field_API_name__c != null and Process_name__c = 'Account updated'];
		system.debug('accNewList[0].Ready_for_integration__c = ' + accNewList[0].Ready_for_integration__c);
		system.debug('setting.API_User_ID__c = ' + setting.API_User_ID__c);
		system.debug('UserInfo.getUserId() = ' + UserInfo.getUserId());
	    if (accNewList[0].Email__c != null && (accNewList[0].Ready_for_integration__c || (setting.API_User_ID__c != null && !UserInfo.getUserId().contains(setting.API_User_ID__c) && fieldToUpdateWasChanged(accNewList[0], accOldMap.get(accNewList[0].id)))) && accNewList[0].RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()){
			Account acc = new Account(id = accNewList[0].id, Ready_for_integration__c = false, Resend__c = false);
			update acc;
			system.debug('acc = ' + acc);
			createUpdateLog(accNewList[0], accNewList[0].Magento_Account_Id__c != null ? 'Account updated' : 'Account created');
			system.debug('fffffffffffffffff');
	    }
        synchronizeDeliveryEmail(accOldMap.values(), new Map<Id, Account>(accNewList));
    }
    
    private static void synchronizeDeliveryEmail(List<Account> accountListOld, Map<Id, Account> accountMap) {
        system.debug('emailSynchronized: ' + emailSynchronized);
        
		Set<Id> changedAccountSet = new Set<Id>();
		for (Account account_i : accountListOld) {
			if (accountMap.get(account_i.Id).Email__c != account_i.Email__c) {
				changedAccountSet.add(account_i.Id);
			}
        }
        
        if (!changedAccountSet.isEmpty()) {
            List<Id> accountIdList = new List<Id>();
            List<String> deliveryEmailList = new List<String>();
            for (Sales_Order__c order_i : [SELECT Id, Delivery_Company__c, Delivery_company_Email__c
                                           FROM Sales_Order__c
                                           WHERE Delivery_Company__c IN :changedAccountSet]) {
                                               String accountEmail = accountMap.get(order_i.Delivery_Company__c).Email__c;
                                               if (order_i.Delivery_company_Email__c != accountEmail) {
                                                   accountIdList.add(order_i.Id);
                                                   deliveryEmailList.add(accountEmail);
                                               }
                                           }
            
            if (!accountIdList.isEmpty()) {
                if (!emailSynchronized) {
                    emailSynchronized = true;
                }
                else {
                    return;
                } 
                updateOrderDeliveryEmails(accountIdList, deliveryEmailList);
            }
        }
    }
    
    @future
    private static void updateOrderDeliveryEmails(List<Id> accountIdList, List<String> deliveryEmailList) {
        List<Sales_Order__c> orderListToUpdate = new List<Sales_Order__c>();
        for (Integer i = 0; i < accountIdList.size(); ++i) {
        	orderListToUpdate.add(new Sales_Order__c(Id = accountIdList[i], Delivery_company_Email__c = deliveryEmailList[i]));
        }
        update orderListToUpdate;
    }
    
    private static void createUpdateLog(Account account, string proc){
    	Log__c log = new Log__c();
		list<Log__c> existedlog = [select id from Log__c where Object_ID__c = :account.id and Status__c = 'Failed'];
		if (existedlog.size() > 0){
			log.id = existedlog[0].id;
		}
		log.Owner__c = 'Salesforce';
		log.Object_ID__c = account.id;
		log.Process__c = proc;
		log.Status__c = 'Sent';
		log.Data__c = getAccountData(account, proc);
		upsert log;
    }
    
    private static string getAccountData(Account account, string proc){
		list<Salesforce_Magento_Field_Mapping__mdt> mapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Magento_field_API_name__c != null and SF_field_API_name__c != null and Process_name__c = :proc];
    	string ret = '[{';
    	boolean first = true;
    	for (Salesforce_Magento_Field_Mapping__mdt field : mapping) {
    		if (!first){
    			ret += ',';
    		}
    		else {
    			ret += '"salesforceId":' + '"' + account.get('Id') + '",';
    			first = false;
    		}
    		if (account.get(field.SF_field_API_name__c) != null && account.get(field.SF_field_API_name__c) != 'null' && account.get(field.SF_field_API_name__c) != ''){
    			ret += '"' + field.Magento_field_API_name__c + '":"' + account.get(field.SF_field_API_name__c) +'"';
    		}
    		else{
    			ret += '"' + field.Magento_field_API_name__c + '":""';
    		}
    	}
    	ret += '}]';
    	return ret;
    }
    
    private static boolean fieldToUpdateWasChanged(Account newAccount, Account oldAccount){
	    for(Salesforce_Magento_Field_Mapping__mdt m : mtd) {
	        if (newAccount.get(m.SF_field_API_name__c) != oldAccount.get(m.SF_field_API_name__c) && m.SF_field_API_name__c != 'Magento_Account_Id__c'){
                system.debug(m.SF_field_API_name__c);
	        	return true;
	        }
	    }
    	return false;
    }
}