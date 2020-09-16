@isTest
private class ShippingLocationCalloutsTest {

	/*public static Google_API__c googleAPI;
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
        
        googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
    }
	
	@isTest static void getLocationTest() {
		Account ac = TestUtil.createCustomerAccount();
		ac.Location__Longitude__s = 46.469391;
		ac.Location__Latitude__s = 30.740883;
		update ac;
		Account deliveryAccount = TestUtil.createDeliveryAccount();
		deliveryAccount.Location__Longitude__s = 46.469391;
		deliveryAccount.Location__Latitude__s = 30.740883;
		update deliveryAccount;

        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'PayPal');
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);

		ShippingLocationCallouts.getLocation(so.Shipping_Street__c,so.Shipping_City__c,so.Shipping_State__c,so.Shipping_ZipCode__c,so.id);
	}
	
	@isTest static void test_method_two() {
		Account ac = TestUtil.createCustomerAccount();ac.Location__Longitude__s = 46.469391;
		ac.Location__Latitude__s = 30.740883;
		update ac;
		Account deliveryAccount = TestUtil.createDeliveryAccount();
		deliveryAccount.Location__Longitude__s = 46.469391;
		deliveryAccount.Location__Latitude__s = 30.740883;
		update deliveryAccount;
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        Account warehouseAccount = TestUtil.createWarehouseAccount();
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c pro = TestUtil.createSimpleProduct(configPro.id,manufactureAccount.id);
        Products__c bundlePro = TestUtil.createBundleProduct();
        Bundle_Item__c bundleItem = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id);
        Payment_Method__c pm = TestUtil.createpaymentMethod(deliveryAccount.id,'PayPal');
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, pm.id);

		ShippingLocationCallouts.calculateHaversineDistance(new list<account>{ac,deliveryAccount} ,so.Id,46.469391, 30.740883, 30.740883, 30.740883,'Test');
	}*/
	
}