@isTest
public class ManageShipmentLineItemsControllerTest {
    @testsetup
    static void setup(){
        insert new List<ObjectTypeToFieldSet_for_shl_component__c>{
            new ObjectTypeToFieldSet_for_shl_component__c(Name='Case', Field_Set_name__c='Delivery_Company'),
            new ObjectTypeToFieldSet_for_shl_component__c(Name='Shipment__c', Field_Set_name__c='DeliveryCompanyToUpdate'),
            new ObjectTypeToFieldSet_for_shl_component__c(Name='Sales_Order__c', Field_Set_name__c='Delivery_Company')
            };
    }
    
    @isTest
    static void obtainShipmentLinesTest(){
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);

        Field_Set_Shipment_Line_Items__c setting = new Field_Set_Shipment_Line_Items__c();
        setting.Value__c = 'DeliveryCompanyToUpdate';
        insert setting;

        ResponseWrapper response =  ManageShipmentLineItemsController.obtainShipmentLines(ship.Id);
        
        System.assertEquals(true, response.success);
        
    }       
    
     @isTest
    static void obtainMetadataTest(){
        
        String response =  ManageShipmentLineItemsController.obtainMetadata('Case');
        
        System.assertEquals(true, response.contains('true'));
        
    }   
    
     @isTest
    static void updateShipmentLinesTest(){
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        ResponseWrapper response =  ManageShipmentLineItemsController.updateShipmentLines(new List<String>{shipitem.Id}, '{"Shipment_Item_Status__c":"Draft"}');
        
        System.assertEquals(true, response.success);
        
    } 
    
     @isTest
    static void splitShipmentLinesTest(){
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        ResponseWrapper response =  ManageShipmentLineItemsController.splitShipmentLines(shipitem.Id, 3, 2);
        
        System.assertEquals(true, response.success);
        
    } 
    
     @isTest
    static void connectAttachemntsTest(){
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
                
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

        Shipment__c ship = TestUtil.createshipment(po.id, So.id,'Ship Via Delivery Company');
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(ship.id, POl.id);
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        ContentVersion contentVersionInserted = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1]; 
        
        ResponseWrapper response =  ManageShipmentLineItemsController.connectAttachemnts(new List<String>{contentVersionInserted.ContentDocumentId}, new List<String>{shipitem.Id});
        
        System.assertEquals(true, response.success);
        
        response =  ManageShipmentLineItemsController.connectAttachemnts(new List<String>{contentVersion.Id}, new List<String>{shipitem.Id});
        
        System.assertEquals(false, response.success);
        
    } 
    
     @isTest
    static void deleteAttachemntsTest(){
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test',
            PathOnClient = 'Test.jpg',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersion;
        
        ContentVersion contentVersionInserted = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1]; 
        
        ResponseWrapper response =  ManageShipmentLineItemsController.deleteAttachemnts(new List<String>{contentVersionInserted.ContentDocumentId});
        
        System.assertEquals(true, response.success);
        
        response =  ManageShipmentLineItemsController.deleteAttachemnts(new List<String>{contentVersion.Id});
        
        System.assertEquals(false, response.success);
        
    }
}