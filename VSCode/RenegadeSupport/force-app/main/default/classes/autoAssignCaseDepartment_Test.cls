/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : autoAssignCaseDepartment_Test
*   Purpose: This class is to cover the scenarios for autoAssignCaseDepartment class.
*/
@istest
public class autoAssignCaseDepartment_Test {
    public static MagentoAuth__c magentoAuth;
    public static MagentoTokens__c magentoToken;
    
    @testSetup static void setUp() {
        magentoAuth = new MagentoAuth__c(Name='MagentoOAuth', AccessTokenURL__c='http://stage01.colemanfurniture.com/oauth/token',
                                        AuthorizationURL__c='http://stage01.colemanfurniture.com/admin/oauth_authorize',
                                        CallbackURL__c='https://c.cs41.visual.force.com/apex/CompleteAuth', password__c='rfgstage0987',
                                        ClientKey__c='ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',ClientSecret__c='p1khnuudmoowwiq1avhx8cjj9g573j70',
                                        RequestTokenURL__c='http://stage01.colemanfurniture.com/oauth/initiate/',
                                        RestEndpoint__c='http://stage01.colemanfurniture.com/api/rest',username__c='stage');
        insert magentoAuth;
        
        magentoToken = new MagentoTokens__c(Name='OAuth', isAccess__c=false,owner__c='00555000000IFiGAAW',
                                           secret__c='vrz4dsnqxlf7uj3cq9qs89meferbyf5g', token__c='mbxbk9y7ylsx9kh4lay7y1fvmqursrcb');
        
        insert magentoToken;
        Account acc = TestUtil.createCustomerAccount();
        TestUtil.createsalesOrder(acc.id, null, null);
    }
	
	private static Account getcustomerAcc() {
        return [SELECT Id, recordtype.Name FROM Account where recordtype.Name='Customer' LIMIT 1];
    }
    
    public static testmethod void CaseInsertion()
    {
        Account ac = getcustomerAcc(); 
        
        Sales_Order__c so = [SELECT Id,name FROM Sales_Order__c LIMIT 1];
        
        User adminUser = [select id from user where id != :userInfo.getUserId() AND isactive = true AND Profile.UserLicense.Name = 'Salesforce' limit 1];
        
        RecordType RTDept = [select id,Name from RecordType where sobjecttype = 'case' and name = 'Updates Dept.'];
        
        Case cas = TestUtil.createCase(so.Id, null, 'Change/Cancellation', 'Sales Dept.');
        
        system.runAs(adminUser) {
            cas.OwnerId = adminUser.id;
            cas.RecordTypeId = RTDept.id;
            cas.IsEscalated = true;
            update cas;
        }
    }
}