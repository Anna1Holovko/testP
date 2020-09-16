@isTest
private class ProductsTriggerHandlerTest {

	static testmethod void updateSkuNameList() {
		
        Account ac = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        //Products Creation
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        
        pro.SKU_1__c = 'sdfsdfsdf';
        update pro;
	}
}