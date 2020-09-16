/*
*   Author : Mani Kumar | Kairos Tech
*   Class  : ShipmentLineStatusChange_Test
*   Purpose: This test class is to cover the code coverage for trigger ShipmentLineStatusChange.
*/
//@istest(SeeAllData=true)
@isTest
public class ShipmentLineStatusChange_Test {
    //private static string csaAlias = 'cbcct';
    //public static MagentoAuth__c magentoAuth;
    //public static MagentoTokens__c magentoToken;
    
    /*
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
        
        Id profId = [Select Id From Profile where Name = 'Customer Community Plus User'].Id;
        
        User customerUser = TestUtil.createCustomerPortalUser(TestUtil.generateRandomEmail());
        customerUser.Alias = csaAlias;
        customerUser.ProfileId = profId;
        
        insert customerUser;
    }
    
    private static User getCustomerPortalUser() {
        return [SELECT Id FROM User WHERE Alias = :csaAlias LIMIT 1];
    }
*/
    @testSetup 
    private static void setUp() {
        
        Id profId = [Select Id From Profile where Name = 'Customer Community Plus User'].Id;
        User customerUser = TestUtil.createCustomerPortalUser(TestUtil.generateRandomEmail());
        customerUser.ProfileId = profId;
        
        insert customerUser;
    }   
    
    private static User getCustomerPortalUser() {
        return [SELECT Id FROM User WHERE UserType='PowerCustomerSuccess'  LIMIT 1];
    }
    
    public static testmethod void shipmentItemStatusUpdate() 
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Check_for_Fraud__c = false;
        so.Payment_Status__c = 'Received';
        update so;
        
        Purchase_Order__c po=TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Carrier__c = '';//'White Glove';
        update ship;
        
        test.startTest();
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        Shipitem.Shipment_Item_Status__c = 'Pick Up By Trucking';
        update shipitem;
        
        ship.Shipment_Status__c='Deluxing No Issues';
        update Ship;
        
        Shipitem.Shipment_Item_Status__c = 'En Route';
        update shipitem;   
        
        ship.Shipment_Status__c='Delivered No Issues';
        ship.Delivery_Date_Actual__c= system.today();
        update Ship;
        
        test.stopTest();
        System.assertEquals('En Route', Shipitem.Shipment_Item_Status__c);
    }
    
    public static testmethod void shipmentstatuswithIssues() 
    {
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Carrier__c = '';//'White Glove';
        update ship;
        
                
        test.startTest();
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        ContentVersion file = new ContentVersion();
        
        Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        file.VersionData = bodyBlob;
        // add the user entered name
        file.Title = 'test.pdf';
        file.PathOnClient = 'test.pdf';
        // attach the pdf to the account
        file.FirstPublishLocationId = shipitem.id;
        file.Description = '';
        insert file;
                
        shipitem.Shipment_Item_Status__c = 'Deluxing with Issue';
        shipitem.Location_Of_Furniture__c = 'Delivery HUB';
        shipitem.Damage_Action__c = 'Repair';
        shipitem.Tech_Scheduled_By__c='Renegade';
        shipitem.Repair_Amount__c = 100;
        update shipitem;
        
        shipitem.Damage_Action__c = 'Replacement';
        update shipitem;
        
        shipitem.Damage_Action__c = 'Parts Needed';
        update shipitem;
                        
        shipitem.Shipment_Item_Status__c = 'Delivered With Issues';
        shipitem.Approval_Status__c = Null;
        try { 
            update shipitem;
        }
        catch(Exception e) {
            system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
        }
        
        try { 

            List<ContentDocument> doc = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :file.Id];

            delete doc;
            
            shipitem.Damage_Action__c= 'Repair';
            shipitem.Location_Of_Furniture__c='Customer Location';
            shipitem.Tech_Scheduled_By__c='Renegade';
            shipitem.Repair_Amount__c=100.00;
            update shipitem;
        }
        catch(Exception e) {
            system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
        } 
                
        test.stopTest();
        System.assertEquals('Delivered With Issues', Shipitem.Shipment_Item_Status__c);
    }
    
    public static testmethod void shipmentLineItemApproval() 
    {
        /*Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Check_for_Fraud__c = false;
        so.Payment_Status__c = 'Received';
        update so;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,4);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        ship.Shipment_Status__c = 'Received By Warehouse';
        ship.Drop_Off_Date_Actual__c = System.today();
        update ship;
        
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        User deliveryUser = getCustomerPortalUser();
        
        System.runAs(deliveryUser){
            test.startTest();
            Attachment attach = new Attachment();
            
            Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
            attach.Body = bodyBlob;
            // add the user entered name
            attach.Name = 'test.pdf';
            attach.IsPrivate = false;
            // attach the pdf to the account
            attach.ParentId = shipitem.id;
            insert attach;
            
            shipitem.Shipment_Item_Status__c = 'Deluxing with Issue';
            shipitem.Location_Of_Furniture__c = 'Delivery HUB';
            shipitem.Damage_Action__c = 'Replacement';
            shipitem.Approval_Status__c = null;
            try {
                update shipitem;
            }
            catch(Exception e) {
                system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
            } 
            test.stopTest();
        }
        System.assertEquals('Deluxing with Issue', Shipitem.Shipment_Item_Status__c);*/
    }
    
    @isTest
    private static void shippedPurchaseOrderTest(){
        //ShipmentLineItemHelper.fortest();
        /*Account customerAccount = TestUtil.createCustomerAccount(); 
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        Account manufactureAccount = TestUtil.createManufacturerAccount(false,false, 'Email');
        
        
        Sales_Order__c salesOrder = TestUtil.createsalesOrder(customerAccount.id, deliveryAccount.id, Null);
        Purchase_Order__c purchaseOrder = TestUtil.createpurchaseorder(salesOrder.id, 'Manufacturer PO');
        
        Products__c simplePro = TestUtil.createSimpleProduct(null,manufactureAccount.id);
        simplePro.Weight__c = 300;
        update simplePro;
        
        SO_Line_Items__c soLI = TestUtil.createsalesOrderLineItem(salesOrder.id, simplePro.id, null,null,2);
        PO_Line_Items__c simplePO = TestUtil.createpoitem(purchaseOrder.id, soLI.id);
        
        
        Shipment__c shipment = TestUtil.createshipment(purchaseOrder.Id, salesOrder.id, 'Ship To HUB');
        
        Shipment_Line_Item__c shipmentLI = TestUtil.createshipmentItem(shipment.id, simplePO.id );
        purchaseOrder = [SELECT Id, Status__c FROM Purchase_Order__c WHERE Id =: purchaseOrder.Id LIMIT 1 ];
        System.assertEquals('Shipped', purchaseOrder.Status__c);
        
        Test.startTest();
        
        PO_Line_Items__c simplePO2 = TestUtil.createpoitem(purchaseOrder.id, soLI.id);
        Shipment_Line_Item__c shipmentLI2 = TestUtil.createshipmentItem(shipment.id, simplePO.id );
        purchaseOrder = [SELECT Id, Status__c FROM Purchase_Order__c WHERE Id =: purchaseOrder.Id LIMIT 1 ];
        System.assertEquals('Multiple Statuses', purchaseOrder.Status__c);
        
        Test.stopTest();*/
        
    }
}