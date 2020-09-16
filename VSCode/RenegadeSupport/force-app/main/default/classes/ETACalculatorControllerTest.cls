@isTest
public class ETACalculatorControllerTest {
    @isTest
    public static void calculateTest() {
        Account a = TestUtil.createDeliveryAccount();
        a.ETA_group__c = 'Zone_1_ETA_Group__c';
        update a;
        Shipping_Zip_Codes__c z = new Shipping_Zip_Codes__c(Zone_1_ETA_Group__c = '3 - 4 Weeks', Zip_Code__c = '13370');
        insert z;
        
        Test.startTest();
        
        ETACalculatorController.InputParameters input = new ETACalculatorController.InputParameters();
        input.accountId = a.Id;
        input.loadDate = Date.today();
        input.zipCode = z.Zip_Code__c;
        Date result = ETACalculatorController.calculate(new List<ETACalculatorController.InputParameters> { input })[0].resultDate;
        
        Test.stopTest();
        
        System.assertEquals(Date.today().addDays(28), result);
        
        z.Zone_1_ETA_Group__c = '6 Weeks';
        update z;
        input.zipCode = z.Zip_Code__c;
        result = ETACalculatorController.calculate(new List<ETACalculatorController.InputParameters> { input })[0].resultDate;
        
        System.assertEquals(Date.today().addDays(42), result);
    }
}