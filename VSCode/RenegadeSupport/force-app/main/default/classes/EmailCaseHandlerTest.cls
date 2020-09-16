@isTest
private class EmailCaseHandlerTest  {
    @isTest
    static void testEmailHandler(){
        Account ac = TestUtil.createCustomerAccount();
        ac.Renegade_Website__c = 'Coleman Furniture';
        update ac;
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        Case curentCase = TestUtil.createCase(so.Id, null, 'Change/Cancellation', 'Sales Dept.');
        curentCase.Account = ac;
        update curentCase;
        
        String defaultsAsJSON = '[{"targetSObject":{"attributes":{"type":"EmailMessage"},"TextBody":"",'
            + '"FromName":"Test","FromAddress":"test@example.com","HtmlBody":"<html><body></body></html>","BccAddress":"test@example.com",'
            + '"CcAddress":"","ToAddress":"test@example.com","Subject":"Testing"},"contextId":"'+curentCase.Id+'","actionType":"Email",'
            + '"actionName":"Case.Email_Customer","fromAddressList":["salesforce@test.com"]}]';
        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = 
            (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(defaultsAsJSON, List<QuickAction.SendEmailQuickActionDefaults>.class);
        Test.startTest();
        (new EmailCaseHandler()).onInitDefaults(defaultsSettings); 
        
        Test.stopTest();
        
        
    }
}