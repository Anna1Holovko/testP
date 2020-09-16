@isTest
public class EmailManagerTest {
	@isTest
    public static void testSend() {
        EmailManager.send('Everything is fine.', 'Test1');
        system.assertEquals(1, Limits.getEmailInvocations());
        
        insert new ErrorMailingSettings__c(Name = 'Test2', EmailList__c = '');
        EmailManager.send('Everything is fine.', 'Test2');
        system.assertEquals(2, Limits.getEmailInvocations());
        
        insert new ErrorMailingSettings__c(Name = 'Test3', EmailList__c = 'email1@mail.com;email2@mail.com');
        EmailManager.send('Everything is fine.', 'Test3');
        system.assertEquals(3, Limits.getEmailInvocations());        
    }
}