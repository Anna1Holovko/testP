@isTest
public class AccountCreationHandler_Test {
	static testmethod void createUser() {
        User user;
        test.startTest();
        user = TestUtil.createSysUser(TestUtil.generateRandomEmail());
        test.stopTest();
        System.assertEquals('lastname', user.LastName);
    }
}