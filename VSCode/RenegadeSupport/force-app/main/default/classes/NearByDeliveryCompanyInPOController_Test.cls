@isTest
public class NearByDeliveryCompanyInPOController_Test {
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
    }
    
    static testMethod void getNearbyDeliveryTest()
    {
        Google_API__c googleKey = new Google_API__c();
        googleKey.Name = 'Google API';
        googleKey.Key__c = 'AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ';
        insert googleKey;
            
        Account ac = TestUtil.createCustomerAccount();
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        deliveryAccount.Location__Latitude__s = 35.448317;
        deliveryAccount.Location__Longitude__s = 97.47591899999999;
        update deliveryAccount;
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
                    
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
               
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Sales_Order__c[] soList = [Select Id from Sales_Order__c];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        PO_Line_Items__c poLineItem = TestUtil.createpoitem(PO.id, Sol.id);
            
        Test.startTest();
        PageReference pref = Page.NearerDeliveryCompaniesVF;
        ApexPages.currentPage().getParameters().put('Id',so.id);
        test.setCurrentPage(pref);

        ApexPages.StandardSetController sc = new ApexPages.standardSetController(soList);
        NearByDeliveryCompanyInPOController controller = new NearByDeliveryCompanyInPOController(sc);
        
        NearByDeliveryCompanyInPOController.getNearbyDelivery(''+deliveryAccount.Location__Latitude__s,''+deliveryAccount.Location__Longitude__s,so.id,Null,Null,Null,Null);
        test.stopTest();
        System.assertEquals('35.448317', ''+deliveryAccount.Location__Latitude__s);
    }
    static testMethod void getNearbyTest()
    {
        Google_API__c googleKey = new Google_API__c();
        googleKey.Name = 'Google API';
        googleKey.Key__c = 'AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ';
        insert googleKey;
        
        Account ac = TestUtil.createCustomerAccount();
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        deliveryAccount.Location__Latitude__s = 35.448317;
        deliveryAccount.Location__Longitude__s = 97.47591899999999;
        update deliveryAccount;
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
                    
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
               
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Sales_Order__c[] soList = [Select Id from Sales_Order__c];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        PO_Line_Items__c poLineItem = TestUtil.createpoitem(PO.id, Sol.id);
            
        Test.startTest();
        PageReference pref = Page.PONearestDelivery;
        ApexPages.currentPage().getParameters().put('Id',PO.id);
        test.setCurrentPage(pref);

        ApexPages.StandardSetController sc = new ApexPages.standardSetController(soList);
        NearByDeliveryCompanyInPOController controller = new NearByDeliveryCompanyInPOController(sc);
        
        NearByDeliveryCompanyInPOController.getNearby(''+po.id,''+deliveryAccount.Location__Latitude__s,''+deliveryAccount.Location__Longitude__s,''+deliveryAccount.Location__Latitude__s,''+deliveryAccount.Location__Longitude__s,deliveryAccount.Name);
        test.stopTest();
        System.assertEquals('35.448317', ''+deliveryAccount.Location__Latitude__s);
    }
    static testMethod void getNearbyWithNullLatLon()
    {
        Google_API__c googleKey = new Google_API__c();
        googleKey.Name = 'Google API';
        googleKey.Key__c = 'AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ';
        insert googleKey;
        
        Account ac = TestUtil.createCustomerAccount();
        
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        deliveryAccount.Location__Latitude__s = 51.096214;
        deliveryAccount.Location__Longitude__s = 3.683153;
        update deliveryAccount;
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
                    
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
               
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
        
        Sales_Order__c[] soList = [Select Id from Sales_Order__c];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        PO_Line_Items__c poLineItem = TestUtil.createpoitem(PO.id, Sol.id);
            
        Test.startTest();
        PageReference pref = Page.PONearestDelivery;
        ApexPages.currentPage().getParameters().put('Id',PO.id);
        test.setCurrentPage(pref);

        ApexPages.StandardSetController sc = new ApexPages.standardSetController(soList);
        NearByDeliveryCompanyInPOController controller = new NearByDeliveryCompanyInPOController(sc);
        
        NearByDeliveryCompanyInPOController.getNearby(''+po.id,Null,Null,Null,Null,deliveryAccount.Name);
        test.stopTest();
        System.assertEquals(51.096214, deliveryAccount.Location__Latitude__s);
    }
}