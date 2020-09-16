@isTest
class DeliveryCompanyStatusUpdatesTest {
	@isTest
    static void createNewLogTest(){
        RestRequestTest(JSON.serialize(CreateOrder(false, true)));
        DeliveryCompanyStatusUpdates.createNewLog();
    }
    
    @isTest
    static void createNewLogTest2(){
        RestRequestTest(JSON.serialize(CreateOrder(false, false)));
        DeliveryCompanyStatusUpdates.createNewLog();
    }

    @isTest
    static void createNewLogFailTest(){
        RestRequestTest('{"hello":"world"}');
        DeliveryCompanyStatusUpdates.createNewLog();
        
    }
    @isTest
    static void createNewLogWithZeroItemsTest(){
        RestRequestTest(JSON.serialize(CreateOrder(true, true)));
        DeliveryCompanyStatusUpdates.createNewLog();
    }
    
     static void RestRequestTest(String requestBody){
        RestResponse response = new RestResponse();
        RestRequest request = new RestRequest();
        request.requestUri =
            'https://yourInstance.salesforce.com/services/apexrest/status_update/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf(requestBody);
        RestContext.request = request;
        RestContext.response = response;

        
    }
    static DeliveryCompanyStatusUpdates.Order CreateOrder(boolean forFail, Boolean withImages){
       // 
        List<Account> acc = new List<Account> { 
            new Account(Name = 'TestCustm123123')
            //new Account(Name = 'TestDeliver1231231')
            };
        Account accDelivery = TestUtil.createDeliveryAccount();  
        Account acc1 = new Account(Name = 'TestCustm123123');        
        Account acc2 = new Account(Name = 'tDeliver1231231');
        insert acc;
        Payment_Method__c payMeth = TestUtil.createpaymentMethod(acc[0].id, 'Cash On Delivery');
        Sales_Order__c salesOrd = TestUtil.createsalesOrder(acc[0].id, accDelivery.id, payMeth.id);
        Purchase_Order__c pursarOrd =  TestUtil.createpurchaseorder(salesOrd.id, 'Internal PO'); 
        Shipment__c shipm = TestUtil.createshipment(pursarOrd.id, salesOrd.id, 'Direct Shipment');
        Account accManuf = TestUtil.createManufacturerAccount(true,false, 'Email');
        Products__c prod = TestUtil.createSimpleProductwithoutMaster(accManuf.id);
        Products__c confProd = TestUtil.createConfigProduct();
        
        Bundle_Item__c bundelItem = TestUtil.createBundleItemProduct(prod.id, prod.id);
        SO_Line_Items__c soLineItems = TestUtil.createsalesOrderLineItem(salesOrd.id, prod.id, confProd.id, bundelItem.id, 29);

        
        PO_Line_Items__c polineItem = TestUtil.createpoitem(pursarOrd.id, soLineItems.id);
        Shipment_Line_Item__c shipitem = TestUtil.createshipmentItem(shipm.id, polineItem.id);
     	//shipitem.Shipment_Item_Status__c ='Delivered No Issues';
        //update shipitem;
        DeliveryCompanyStatusUpdates.image img = new  DeliveryCompanyStatusUpdates.image();
        img.image = 'test';
        img.image_name = 'test';
        
        DeliveryCompanyStatusUpdates.orderLineItem  ordLineItm= new DeliveryCompanyStatusUpdates.orderLineItem();
     	ordLineItm.delivery_schedule_comments = 'TestComments';
        ordLineItm.receive_date = date.today();
        ordLineItm.scheduling_date = date.today();
        ordLineItm.shipment_item_id = 'Test';
        ordLineItm.shipment_item_status = 'Delivered No Issues';
        if (withImages) {
            ordLineItm.images = new List<DeliveryCompanyStatusUpdates.image>{img};
        }
        if(forFail){
            ordLineItm.shipment_item_id = '';
        }else{
            ordLineItm.shipment_item_id = shipitem.id;
        }
        
        DeliveryCompanyStatusUpdates.Order ordObj = new  DeliveryCompanyStatusUpdates.Order();
        ordObj.Comments = 'Test Comment';
        ordObj.order_id = salesOrd.Id;
        ordObj.sending_party = 'Teste';
        ordObj.receiving_party = 'Testes';
        ordObj.warehouse_id = 'Testes';
        ordObj.order_line_shipment_item = new List<DeliveryCompanyStatusUpdates.orderLineItem> {ordLineItm};
        //ordObj.deleteImage();
		return ordObj;
    }
}