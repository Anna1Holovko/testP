@isTest
private class OrderNotificationBatchTest {
    @testSetup 
    static void setup() {
        List<EmailTemplate> templateList = new List<EmailTemplate> ();
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = 'SF_ord_10dayETA_cnfrm_m';
        validEmailTemplate.DeveloperName = 'SF_ord_10dayETA_cnfrm_m';
        validEmailTemplate.TemplateType = 'text';
        validEmailTemplate.FolderId = UserInfo.getUserId();
        
        templateList.add(validEmailTemplate);
        
        EmailTemplate validEmailTemplate1 = new EmailTemplate();
        validEmailTemplate1.isActive = true;
        validEmailTemplate1.Name = 'SF_ord_10dayETA_cnfrm_mLONG';
        validEmailTemplate1.DeveloperName = 'SF_ord_10dayETA_cnfrm_mLONG';
        validEmailTemplate1.TemplateType = 'text';
        validEmailTemplate1.FolderId = UserInfo.getUserId();
        
        templateList.add(validEmailTemplate1);
        
        EmailTemplate validEmailTemplate2 = new EmailTemplate();
        validEmailTemplate2.isActive = true;
        validEmailTemplate2.Name = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_m';
        validEmailTemplate2.DeveloperName = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_m';
        validEmailTemplate2.TemplateType = 'text';
        validEmailTemplate2.FolderId = UserInfo.getUserId();
        
        templateList.add(validEmailTemplate2);
        
        EmailTemplate validEmailTemplate3 = new EmailTemplate();
        validEmailTemplate3.isActive = true;
        validEmailTemplate3.Name = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_mLONG';
        validEmailTemplate3.DeveloperName = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_mLONG';
        validEmailTemplate3.TemplateType = 'text';
        validEmailTemplate3.FolderId = UserInfo.getUserId();
        
        templateList.add(validEmailTemplate3);
        insert templateList;
    }

    static testmethod void test() {        
        List<Weekly_order_update_email__c> settingList = new List<Weekly_order_update_email__c>();
        settingList.add(new Weekly_order_update_email__c(Name = 'fedexNotLongETA', isFedex__c = true, TemplateName__c = 'Salesforce_ordered_10dayETA_FedE'));
        settingList.add(new Weekly_order_update_email__c(Name = 'notfedexNotLongETA', isFedex__c = false, TemplateName__c = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_m'));
         settingList.add(new Weekly_order_update_email__c(Name = 'fedexLongETA', isFedex__c = false, TemplateName__c = 'SF_ord_10dayETA_cnfrm_mLONG', Is_long_ETA__c	= true));
         settingList.add(new Weekly_order_update_email__c(Name = 'notfedexLongETA', isFedex__c = false, TemplateName__c = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_mLONG', Is_long_ETA__c	 = true));
        insert settingList;
        Magento_Integration_Setting__c setting = new Magento_Integration_Setting__c(API_User_ID__c = 'sdf', Oauth_version__c = '1.0', Oauth_token__c = '9z0finib6b54efwvaoysys0mf355qxh0', Oauth_signature_method__c = 'HMAC-SHA1', Oauth_signature__c = '6rPjBUYswr2Ri43mAn/Vg7gMZR4=', Oauth_nonce__c = 'fOIwp7', Oauth_consumer_key__c = 'ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',End_Point__c ='http://stage01.colemanfurniture.com/api/rest/salesforce/customer');
        insert setting;
        Account ac = TestUtil.createCustomerAccount();
        ac.Email__c = 'test@mail.com'; 
        update ac;
        Products__c Pro = TestUtil.createConfigProduct();
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c poNew = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        poNew.Purchase_Order_ETA__c = '6 - 7 Weeks';
        update poNew;
        Test.startTest();
        OrderNotificationBatch notif = new OrderNotificationBatch();
        Id batchId = Database.executeBatch(notif, 10);
	    Test.stopTest();
        String jobId = System.schedule('myJobTestJobName', '0 0 0 15 3 ? 2022', notif); 
    }
    
}