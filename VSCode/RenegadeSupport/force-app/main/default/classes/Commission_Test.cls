@isTest
public class Commission_Test {
    
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';
    
    public static testmethod void CommissionTeast()
    {
        User SysUser = TestUtil.createSysUser(TestUtil.generateRandomEmail());
        
        System.runAs(SysUser) {
        insert new MagentoAuth__c(Name='MagentoOAuth', AccessTokenURL__c='http://stage01.colemanfurniture.com/oauth/token',
                                    AuthorizationURL__c='http://stage01.colemanfurniture.com/admin/oauth_authorize',
                                    CallbackURL__c='https://c.cs41.visual.force.com/apex/CompleteAuth', password__c='rfgstage0987',
                                    ClientKey__c='ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',ClientSecret__c='p1khnuudmoowwiq1avhx8cjj9g573j70',
                                    RequestTokenURL__c='http://stage01.colemanfurniture.com/oauth/initiate/',
                                    RestEndpoint__c='http://stage01.colemanfurniture.com/api/rest',username__c='stage');
            Products__c simpleProduct = TestUtil.createSimpleProduct(null, null);
            
            Account internalAccount = TestUtil.createInternalEmployeeAccount(SysUser.id);
            Account customerAccount = TestUtil.createCustomerAccount();
            Sales_Order__c SO = TestUtil.createsalesOrder(customerAccount.Id, null, null);
            SO.Sales_Rep__c = internalAccount.id;
            SO.Commission_Added_Rep__c = false;
            SO.Payment_Status__c = 'Received';
            SO.Order_Status__c='Multiple Statuses';
            SO.Protection_Plan_included__c=true;
            Update SO;
            
            SO_Line_Items__c soline = TestUtil.createsalesOrderLineItem(SO.id, simpleProduct.id,null,null,5);
            test.startTest();
            String jobId = System.schedule( 'SelfSchedule', CRON_EXP, new Commission());
            
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
            test.stopTest();
            System.assertEquals(CRON_EXP,ct.CronExpression);
        }
    }
}