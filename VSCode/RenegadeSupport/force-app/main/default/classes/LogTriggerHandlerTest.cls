@isTest
private class LogTriggerHandlerTest {
	
	static testMethod void sendAccountLog() {
		Magento_Integration_Setting__c setting = new Magento_Integration_Setting__c(API_User_ID__c = UserInfo.getUserId(), Oauth_version__c = '1.0', Oauth_token__c = '9z0finib6b54efwvaoysys0mf355qxh0', Oauth_signature_method__c = 'HMAC-SHA1', Oauth_signature__c = '6rPjBUYswr2Ri43mAn/Vg7gMZR4=', Oauth_nonce__c = 'fOIwp7', Oauth_consumer_key__c = 'ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',End_Point__c ='http://stage01.colemanfurniture.com/api/rest/salesforce/customer');
		insert setting;
		Account a = new Account(Name = 'Mantch', Email__c = 'mkurant@greencloudus.com', First_Name__c = 'Mantch', Last_Name__c = 'Kurant');
		insert a;
		Log__c log = new Log__c();
		log.Log_ID__c = '12345';
		log.Data__c = '[{"\r\nsalesforceId":"' + a.id + '",\r"billing_city":"New \nYork city","billing_country_id":"US","billing_postcode":"10005","billing_region":"New York","billing_street":"New Yorkwer","billing_cell":"null","billing_phone":"3213123213","company_name":"null","customergroup":"1","email":"babar321@321.com","firstname":"Aftadd","lastname":"Naveeddj","magentoId":"","magento_sales_rep_id":"null","middlename":"null","sales_rep_name":"null","shipping_city":"New York","shipping_country_id":"US","shipping_postcode":"10005","shipping_region":"New York","shipping_phone":"3213123213","shipping_street":"New York","shipping_cell":"null","website_id":"null"}]';
		log.Process__c = 'Account created';
		log.Object_ID__c = a.id;
		log.Status__c = 'Sent';
		insert log;
		log.Status__c = 'Failed';
		update log;
		log.Status__c = 'Sent';
		update log;
	}
	
	static testMethod void sendDefectLog() {
		Magento_Integration_Setting__c setting = new Magento_Integration_Setting__c(API_User_ID__c = UserInfo.getUserId(), Oauth_version__c = '1.0', Oauth_token__c = '9z0finib6b54efwvaoysys0mf355qxh0', Oauth_signature_method__c = 'HMAC-SHA1', Oauth_signature__c = '6rPjBUYswr2Ri43mAn/Vg7gMZR4=', Oauth_nonce__c = 'fOIwp7', Oauth_consumer_key__c = 'ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',End_Point__c ='http://stage01.colemanfurniture.com/api/rest/salesforce/customer');
		insert setting;
		Account a = new Account(Name = 'Mantch', Email__c = 'mkurant@greencloudus.com', First_Name__c = 'Mantch', Last_Name__c = 'Kurant');
		insert a;
		Log__c log = new Log__c();
		log.Log_ID__c = '12345';
		log.Data__c = '[{"\r\nsalesforceId":' + a.id + '",\r"billing_city":"New \nYork city","billing_country_id":"US","billing_postcode":"10005","billing_region":"New York","billing_street":"New Yorkwer","billing_cell":"null","billing_phone":"3213123213","company_name":"null","customergroup":"1","email":"babar321@321.com","firstname":"Aftadd","lastname":"Naveeddj","magentoId":"","magento_sales_rep_id":"null","middlename":"null","sales_rep_name":"null","shipping_city":"New York","shipping_country_id":"US","shipping_postcode":"10005","shipping_region":"New York","shipping_phone":"3213123213","shipping_street":"New York","shipping_cell":"null","website_id":"null"}]';
		log.Process__c = 'Account created';
		log.Object_ID__c = a.id;
		log.Status__c = 'Sent';
		insert log;
	}
}