@isTest
public class CaseSalesOrderLineItemsTest {
    public static Google_API__c googleAPI;
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
    
    static testMethod void displayPayments()
    {
        Account ac = TestUtil.createCustomerAccount();
        
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        
        Products__c configPro = TestUtil.createConfigProduct();
        
        Products__c pro = TestUtil.createSimpleProduct(Null,manufactureAccount.id);
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,2);
        Case cas = TestUtil.createCase(so.Id, null, 'Change/Cancellation', 'Sales Dept.');
        
        Test.startTest();
        PageReference pref = Page.CaseSalesOrderLineItemsPage;
        test.setCurrentPage(pref);
        ApexPages.currentPage().getParameters().put('Id',cas.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(so);   
        
        SalesOrderPaymentsController controller = new SalesOrderPaymentsController(sc);
        controller.displayPayments();
        Test.StopTest();
        system.assertEquals(0, controller.paymentList.size());
    }

    @isTest static void testGetShipmentLines() {
        Field_Set_Shipment_Line_Items__c fieldSetSetting = new Field_Set_Shipment_Line_Items__c();
        fieldSetSetting.Value__c = 'Delivery_Companies';
        insert fieldSetSetting;

        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();

        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        test.startTest();
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        Case newCase = TestUtil.createCase(so.Id, shipitem.Id, 'Change/Cancellation', 'Sales Dept.');
        ApexPages.StandardController sc = new ApexPages.StandardController(newCase);

        PageReference pageRef = sc.view();
        pageRef.getParameters().put('id', String.valueOf(newCase.Id));
        Test.setCurrentPage(pageRef);

        CaseSalesOrderLineItemsCtrl controller = new CaseSalesOrderLineItemsCtrl(sc);

        controller.processSelected();
        controller.tmpUpdateItem.Shipment_Item_Status__c = 'Deluxed With Issues';
        controller.fileName = 'test';
        controller.fileBody = 'test';
        controller.collectIds();
        controller.updateSelected();
        controller.goToNewReplacementPO();
        controller.goToNewPartPO();
        controller.newStatus = '';
        controller.selectedId  = '';
        controller.cancel();
    }
}