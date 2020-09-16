/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : TestUtil
*   Purpose: This test class to have reference for all test Class for Object creation.
*/
@isTest
public class TestUtil {
    
    static Integer s_num = 1;
    
    static public String generateRandomName() {
        return SystemUtils.generateUUID();
    }
    
    static public String generateRandomEmail() {
        return SystemUtils.generateUUID() + '@renegade.tst';
    }
    
    static public Integer generateRandomNumber() {
        return Crypto.getRandomInteger();
    }
    
    @future
    public static void assignPermissionSet(Id userId, Id permissionSetId) {
        PermissionSetAssignment psAssignment = 
            new PermissionSetAssignment(
                AssigneeId = userId,
                PermissionSetId  = permissionSetId
            );
        
        insert psAssignment;
    }
    
    static String obtainRecordTypeId(String sObjectName, String recordTypeName){
        //return Schema.SObjectType.Account.getRecordTypeInfosByName().get('Development').getRecordTypeId();
        return Schema.getGlobalDescribe().get(sObjectName).getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeName).getRecordTypeId();
    }
    
    static public Contact setupCustomerContact(String fName, String lName, Id accountId) {
        
        Contact newContact = new Contact( FirstName = fName,
                                         Lastname = lName,
                                         AccountId = accountId,
                                         Email = generateRandomEmail()
                                        );
        return newContact;
    }
    
    static public Account createCustomerAccount()
    {
        /*RecordType customerRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Account' and Name='Customer' Limit 1];*/
        
        Account acct = new Account(Name = 'Default Account',
                                   RecordTypeId = obtainRecordTypeId('Account', 'Customer'),//customerRecordType.Id,
                                   Authorize_net_Profile_ID__c = ''+generateRandomNumber(),
                                   Email__c = generateRandomEmail(),
                                   Type = 'Prospect',
                                   Phone = '9562314756',
                                   BillingStreet = '260 5th Ave,',
                                   BillingCity = 'NY',
                                   BillingState = 'New York',
                                   BillingCountry = 'United States',
                                   BillingPostalCode = '10001',
                                   ShippingStreet = '260 5th Ave,',
                                   ShippingCity = 'NY',
                                   ShippingState = 'New York',
                                   ShippingCountry = 'United States',
                                   First_Name__c = 'Default',
                                   Last_Name__c = 'Account',
                                   ShippingPostalCode = '10001'
                                  );
        Database.insert(acct);
        return acct;
    }
    static public Account createDeliveryAccount()
    {
        RecordType deliveryRecordType = [SELECT Id FROM RecordType WHERE sobjecttype='Account' and Name='Delivery Company' Limit 1];
        
        Account acct = new Account(Name='Default Account',
                                   RecordTypeId=deliveryRecordType.Id,
                                   Email__c = generateRandomEmail(),
                                   Type='Prospect',
                                   Phone = '9562314756',
                                   BillingStreet = '260 5th Ave,',
                                   BillingCity = 'NY',
                                   BillingState = 'New York',
                                   BillingCountry = 'United States',
                                   BillingPostalCode = '10001',
                                   ShippingStreet = '260 5th Ave,',
                                   ShippingCity = 'NY',
                                   ShippingState = 'New York',
                                   ShippingCountry = 'United States',
                                   ShippingPostalCode = '10001',
                                   Authorize_net_Profile_ID__c='AuthId'
                                  );
        try {
            Database.insert(acct);
        }
        Catch(Exception e)
        {
            system.debug('Error: '+e.getMessage()+' '+e.getCause()+' '+e.getLineNumber());
        }
        System.debug('Delivery acct: '+acct);
        return acct;
    }
    
    static public Account createManufacturerAccount(Boolean directShip,Boolean ship2Hub, String OrderCommunicationType)
    {
        RecordType manufacturerRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Account' and Name='Manufacturer' Limit 1];
        
        Account acct = new Account( Name = 'Manufacture Account',
                                   RecordTypeId = manufacturerRecordType.Id,
                                   Email__c = generateRandomEmail(),
                                   Type='Prospect',
                                   Phone = '9562314756',
                                   BillingStreet = '260 5th Ave,',
                                   BillingCity = 'NY',
                                   BillingState = 'New York',
                                   BillingCountry = 'United States',
                                   BillingPostalCode = '10001',
                                   Authorize_net_Profile_ID__c='AuthId',
                                   Ship_To_HUB__c = ship2Hub,
                                   Direct_Shipping__c = directShip,
                                   Order_Communication_Type__c = OrderCommunicationType
                                  );
        Database.insert(acct);
        return acct;
    }
    
    static public Account createWarehouseAccount()
    {
        RecordType warehouseRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Account' and Name='Warehouse' Limit 1];
        
        Account acct = new Account( Name='Default Account',
                                   RecordTypeId=warehouseRecordType.Id,
                                   Email__c = generateRandomEmail(),
                                   Type='Prospect',
                                   Phone = '9562314756',
                                   BillingStreet = '260 5th Ave,',
                                   BillingCity = 'NY',
                                   BillingState = 'New York',
                                   BillingCountry = 'United States',
                                   BillingPostalCode = '10001',
                                   ShippingStreet = '260 5th Ave,',
                                   ShippingCity = 'NY',
                                   ShippingState = 'New York',
                                   ShippingCountry = 'United States',
                                   ShippingPostalCode = '10001'
                                  );
        Database.insert(acct);
        return acct;
    }
    
    static public Account createInternalEmployeeAccount(Id userId)
    {
        RecordType internalEmployeeRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Account' and Name='Internal Employee' Limit 1];
        
        Account acct = new Account( Name='Default Account',
                                   RecordTypeId=internalEmployeeRecordType.Id,
                                   Email__c = generateRandomEmail(),
                                   Role_Type__c='Representative',
                                   Commission_Amount__c = 100,
                                   SalesRepAsUser__c = userId
                                  );
        Database.insert(acct);
        return acct;
    }
    	
    
    static public Account createTruckingAccount()
    {
        RecordType truckingRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Account' and Name='Trucking Company' Limit 1];
        
        Account acct = new Account( Name='Default Account',
                                   RecordTypeId=truckingRecordType.Id,
                                   Email__c = generateRandomEmail(),
                                   Type='Prospect',
                                   Phone = '9562314756',
                                   BillingStreet = '260 5th Ave,',
                                   BillingCity = 'NY',
                                   BillingState = 'New York',
                                   BillingCountry = 'United States',
                                   BillingPostalCode = '10001',
                                   ShippingStreet = '260 5th Ave,',
                                   ShippingCity = 'NY',
                                   ShippingState = 'New York',
                                   ShippingCountry = 'United States',
                                   ShippingPostalCode = '10001'
                                  );
        Database.insert(acct);
        return acct;
    }
    static public Customer_Addresses__c CustomerAddress(Id ParentId,String AddressType,String Name) 
    {
        Customer_Addresses__c customerAddress = CustomerAddressNotInsert(ParentId, AddressType, Name);
        database.insert(customerAddress);
        return customerAddress;
    }
    
    static public Customer_Addresses__c CustomerAddressNotInsert(Id ParentId,String AddressType,String Name) 
    {
        Customer_Addresses__c customerAddress = new Customer_Addresses__c();
        customerAddress.Account__c = ParentId;
        customerAddress.AddressType__c = AddressType;
        customerAddress.Name = Name;
        customerAddress.Street_Address__c = '260 5th Ave,';
        customerAddress.State__c = 'New York';
        customerAddress.City__c = 'NY';
        customerAddress.Country__c = 'United States';
        customerAddress.Cell__c = '9177557877';
        customerAddress.Telephone__c='9177557877';
        customerAddress.Zip_Postal_Code__c = '10001';  
        return customerAddress;
    }
    
    static public Trucking_Rule__c createTruckingRules(Id manufactureId,Id deliveryId) {
        Trucking_Rule__c trucking = new Trucking_Rule__c();
        trucking.Selected_Delivery__c = deliveryId;
        trucking.Selected_Manufacturer__c = manufactureId;
        trucking.Truking_Selection_Note__c = '0 to 200 – Watkins,201 – Zenith';
        
        database.insert(trucking);
        
        return trucking;
    }
    
    static public Products__c createSimpleProduct(Id masterProductId, Id manufactureId) {
        /*string sku=TestUtil.generateRandomName();
        RecordType simpleRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Products__c' and Name='Simple' Limit 1];*/
        
        Products__c pro = createSimpleProductNotInsert(masterProductId, manufactureId);
        								/*new Products__c(Name ='sample test',
                                         Master_Products__c = masterProductId,
                                         Image__c='https://c.cs41.content.force.com/servlet/rtaImage?eid=a005500000120WU&feoid=00N55000000OXuL&refid=0EM5500000008wJ"',
                                         SKU__c='Kin-000'+sku,
                                         Regular_Price__c=1000,
                                         Weight__c = 100,
                                         Status__c = 'Enabled',
                                         Tier_Price_For_Bundle__c=100,
                                         Select_Manufacturer__c = manufactureId,
                                         recordtypeId = obtainRecordTypeId('Products__c', 'Simple'));*/
        
        Database.insert(pro);
        return pro;
    }
    
    static public Products__c createSimpleProductNotInsert(Id masterProductId, Id manufactureId) {
        string sku=TestUtil.generateRandomName();
        /*RecordType simpleRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Products__c' and Name='Simple' Limit 1];*/
        return new Products__c(Name ='sample test',
                                         Master_Products__c = masterProductId,
                                         Image__c='https://c.cs41.content.force.com/servlet/rtaImage?eid=a005500000120WU&feoid=00N55000000OXuL&refid=0EM5500000008wJ"',
                                         SKU__c='Kin-000'+sku,
                                         Regular_Price__c=1000,
                                         Weight__c = 100,
                                         Status__c = 'Enabled',
                                         Tier_Price_For_Bundle__c=100,
                                         Select_Manufacturer__c = manufactureId,
                                         recordtypeId = obtainRecordTypeId('Products__c', 'Simple'));
    }

    static public Products__c createConfigurableProduct(Id masterProductId, Id manufactureId) {
        string sku=TestUtil.generateRandomName();
        RecordType recordType = [
            SELECT Id
            FROM RecordType
            WHERE sobjecttype='Products__c' and Name='Configurable' Limit 1
        ];
        
        Products__c pro= new Products__c(Name ='sample test',
                                         Master_Products__c = masterProductId,
                                         Image__c='https://c.cs41.content.force.com/servlet/rtaImage?eid=a005500000120WU&feoid=00N55000000OXuL&refid=0EM5500000008wJ"',
                                         SKU__c='Kin-000'+sku,
                                         Regular_Price__c=1000,
                                         Weight__c = 100,
                                         Status__c = 'Enabled',
                                         Tier_Price_For_Bundle__c=100,
                                         Select_Manufacturer__c = manufactureId,
                                         recordtypeId = recordType.id);
        
        Database.insert(pro);
        return pro;
    }
    
    static public Products__c createSimpleProductwithoutMaster(Id manufactureId) 
    {
        string sku=TestUtil.generateRandomName();
        RecordType simpleRecordType = 
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Products__c' and Name='Simple' Limit 1];
        
        Products__c pro= new Products__c(Name ='sample test',
                                         Image__c='https://c.cs41.content.force.com/servlet/rtaImage?eid=a005500000120WU&feoid=00N55000000OXuL&refid=0EM5500000008wJ"',
                                         SKU__c='Kin-000'+sku,
                                         Regular_Price__c=1000,
                                         Status__c = 'Enabled',
                                         Sales_Price__c = 1500,
                                         Weight__c = 100,
                                         Tier_Price_For_Bundle__c=100,
                                         Select_Manufacturer__c = manufactureId,
                                         recordtypeId = simpleRecordType.id);
        
        Database.insert(pro);
        return pro;
    }
    
    static public Products__c createConfigProduct() {
        string sku=TestUtil.generateRandomName();
        RecordType ConfigureRecordType =
            [SELECT Id
             FROM RecordType
             WHERE sobjecttype='Products__c' and Name='Configurable' Limit 1];
        
        Products__c pro= new Products__c(Name ='config test',
                                         Image__c='https://c.cs41.content.force.com/servlet/rtaImage?eid=a005500000120WU&feoid=00N55000000OXuL&refid=0EM5500000008wJ"',
                                         SKU__c='Kin-000-c'+sku,
                                         Regular_Price__c=1000,
                                         Sales_Price__c = 1500,
                                         Weight__c = 100,
                                         Status__c = 'Enabled',
                                         Tier_Price_For_Bundle__c=100,
                                         recordtypeId = ConfigureRecordType.id,
                                         SKU_and_name_list__c = '[{"sku":"ASL-6490208","name":"Oversized Accent Ottoman","weight":"43","dimensions":"40\"Wx40\"Dx20\"H"}]');
        
        Database.insert(pro);
        return pro;
    }
    
    static public Products__c createBundleProduct() {
        RecordType BundledRecordType = [SELECT Id FROM RecordType WHERE sobjecttype='Products__c' AND Name='Bundled' Limit 1];
        
        Products__c pro= new Products__c(Name = 'Bundle test',
                                         Image__c = 'https://c.cs41.content.force.com/servlet/rtaImage?eid=a005500000120WU&feoid=00N55000000OXuL&refid=0EM5500000008wJ"',
                                         SKU__c = 'Kin-000-b',
                                         Regular_Price__c = 1000,
                                         Status__c = 'Enabled',
                                         Sales_Price__c = 1500,
                                         Weight__c = 100,
                                         recordtypeId = BundledRecordType.id);
        
        Database.insert(pro);
        return pro;
    }
    
    static public Products__c createprotectionProduct() {
        RecordType ProtectionRecordType = [SELECT Id FROM RecordType WHERE sobjecttype='Products__c' AND Name='Protection Plan' Limit 1];
        
        Products__c pro = new Products__c(Name = 'Protection Plan test',
                                          Image__c = 'https://c.cs41.content.force.com/servlet/rtaImage?eid=a0055000000kCIK&feoid=00N55000000OXuL&refid=0EM5500000008nH',
                                          SKU__c = 'GUARDIAN-199',
                                          Sales_Price__c = 1500,
                                          Regular_Price__c = 1000,
                                          Status__c = 'Enabled',
                                          Protection_high_range__c=10000,
                                          Protection_low_range__c=0,
                                          recordtypeId = ProtectionRecordType.id);
        
        Database.insert(pro);
        return pro;
    }
    
    static public Bundle_Item__c createBundleItemProduct(id productId,id BundleId) {
        Bundle_Item__c bundleItem = createBundleItemProductNotInsert(productId, BundleId);
        
        Database.insert(bundleItem);
        return bundleItem;
    }
    
    static public Bundle_Item__c createBundleItemProductNotInsert(id productId,id BundleId) {
        return new Bundle_Item__c(Product__c = productId,
                                                       Bundle__c = BundleId,
                                                       Order__c = 1,
                                                       Include__c = true);
    }
    
    static public Promotions__c createPromotion(String recordType, String promoType) 
    {
        Account acc = createManufacturerAccount(true,false, 'Email');
        
        Id promotionRecortypeId = Schema.SObjectType.Promotions__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
        
        Promotions__c promotion = new Promotions__c();
        promotion.recordTypeId = promotionRecortypeId;
        promotion.Name = 'Summer Code';
        promotion.Coupon_Code__c = 'SUMMER'+generateRandomNumber();
        promotion.Type__c = promoType;
        promotion.Is_Active__c = true;
        promotion.Date_Start__c = System.today();
        promotion.Date_Expire__c = System.today().addYears(2);
        if(promoType == 'General') 
        {
            promotion.Discount_Amount__c = 450;
        }
        else 
        {
            promotion.Brand__c = acc.name;
            promotion.Discount_Percent__c = 10;
        }
        promotion.Min_Sub_Total__c = 0;
        
        Database.insert(promotion);
        return promotion;
    }
    
    static public Inventory__c createInventory(id productId,Integer Quantity, id warehouseId) {
        RecordType inventoryRecordType = [SELECT Id FROM RecordType WHERE sobjecttype='Inventory__c' AND Name='Own Inventory' Limit 1];
        Inventory__c inventory = new Inventory__c(recordTypeId = inventoryRecordType.id,
                                                  Products__c = productId,
                                                  Warehouse_Name__c = warehouseId,
                                                  Product_Condition__c='Unopened',
                                                  Quantity__c = Quantity);
        
        Database.insert(inventory);
        return inventory;
    }
    
    static public Inventory__c createInventoryNotInsert(id productId,Integer Quantity, id warehouseId) {
        RecordType inventoryRecordType = [SELECT Id FROM RecordType WHERE sobjecttype='Inventory__c' AND Name='Own Inventory' Limit 1];
        Inventory__c inventory = new Inventory__c(recordTypeId = inventoryRecordType.id,
                                                  Products__c = productId,
                                                  Warehouse_Name__c = warehouseId,
                                                  Product_Condition__c='Unopened',
                                                  Quantity__c = Quantity);
        
        return inventory;
    }
    
    static public Inventory__c createDeliveryInventory(id productId,Integer Quantity, id warehouseId, string shipmentItem) {
        RecordType inventoryRecordType = [SELECT Id FROM RecordType WHERE sobjecttype='Inventory__c' AND Name='Delivery Company Inventory' Limit 1];
        Inventory__c inventory = new Inventory__c(recordTypeId = inventoryRecordType.id, Shipment_Item__c = shipmentItem,
                                                  Products__c = productId,
                                                  Warehouse_Name__c = warehouseId,
                                                  Product_Condition__c='Unopened',
                                                  Quantity__c = Quantity);
        
        Database.insert(inventory);
        return inventory;
    }
    
    static public Payment_Method__c createpaymentMethod(id accountId, String payType) {
        Recordtype PayrecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Payment_Method__c' and Name =:payType];
        
        Payment_Method__c paymentMethod = new Payment_Method__c(recordtypeId = PayrecordType.id,
                                                                Account_Number__c = generateRandomNumber(),
                                                                Amount__c = 15000,
                                                                
                                                                Account__c = accountId);
        if(payType == 'Credit Card (Authorize.net)' || payType == 'Credit Card') {
            paymentMethod.Card_Type__c = 'Visa';
            paymentMethod.Card_Verification_Number__c = '127';
            paymentMethod.Credit_Card_Number__c = ''+generateRandomNumber();
            paymentMethod.Expiration_Month__c = '06- June';
            paymentMethod.Expiration_Year__c = '2019';
            paymentMethod.Magento_Payment_Id__c = ''+generateRandomNumber();
            paymentMethod.Name_on_Account__c = 'Test Account';
            paymentMethod.Payment_Profile_ID__c = ''+generateRandomNumber();
            paymentMethod.AVS_Response__c = 'Y';
        }
        
        Database.insert(paymentMethod);
        return paymentMethod;
    }
    
    static public Sales_Order__c createsalesOrder(id customerAccountId, Id deliveryAccountId, id paymentMethodId) {
        Customer_Addresses__c customerBillingAddress = CustomerAddress(customerAccountId,'Primary Billing Address','Billing Account');
        Customer_Addresses__c customerShippingAddress = CustomerAddress(customerAccountId,'Primary Shipping Address','Shipping Account');
        Sales_Order__c salesOrder = new Sales_Order__c(Order_Status__c='Processing',
                                                       Payment_Status__c='Processing',
                                                       Customer_Name__c = customerAccountId,
                                                       Email__c = generateRandomEmail(),
                                                       Customer_Billing_Address__c = customerBillingAddress.id,
                                                       Customer_shipping_Address__c = customerShippingAddress.id,
                                                       Billing_Street__c = 'Plymouth meeting hall',
                                                       Billing_ZipCode__c = '19462',
                                                       Billing_Phone__c = '9142358645',
                                                       Ship_to__c = 'Renegade Renegade',
                                                       Send_ETA_notification_to_customer__c = true,
                                                       Send_to_a_delivery_company__c = true,
                                                       Bill_to__c = 'Renegade Renegade',
                                                       Shipping_Street__c = '210 E Trade Street',
                                                       Shipping_City__c = 'NY',
                                                       Shipping_State__c = 'New York',
                                                       Shipping_ZipCode__c = '10118',
                                                       Shipping_Phone__c = '9144563521',
                                                       Location__Latitude__s = 33.33333,
                                                       Location__Longitude__s = 33.3333,
                                                       Delivery_Company__c = deliveryAccountId,
                                                       Order_Date__c = System.now(),
                                                       Payment_Type__c = paymentMethodId);
        
        Database.insert(salesOrder);
        return salesOrder;
    }
    
    static public SO_Line_Items__c createsalesOrderLineItem(id salesOrderId, Id productId, Id configProductId,Id BundleId,Integer Quantity) {
        SO_Line_Items__c salesOrderLineItem = new SO_Line_Items__c(Sales_Order__c = salesOrderId,
                                                                   Products__c = productId,
                                                                   Config_Product__c = configProductId,
                                                                   Bundle_Item__c = BundleId,
                                                                   Item__c = 'Processing',
                                                                   Quantity__c = Quantity,
                                                                   Price__c = 2000,
                                                                   Tax_Percent__c = 8.65,
                                                                   Custom_Price__c = 0,
                                                                   Quantity_Invoiced__c = 0,
                                                                   Quantity_Refunded__c = 0);
        
        Database.insert(salesOrderLineItem);
        return salesOrderLineItem;
    }
    
    static public SO_Line_Items__c createsalesOrderLineItemNotInsert(id salesOrderId, Id productId, Id configProductId,Id BundleId,Integer Quantity) {
        SO_Line_Items__c salesOrderLineItem = new SO_Line_Items__c(Sales_Order__c = salesOrderId,
                                                                   Products__c = productId,
                                                                   Config_Product__c = configProductId,
                                                                   Bundle_Item__c = BundleId,
                                                                   Item__c = 'Processing',
                                                                   Quantity__c = Quantity,
                                                                   Price__c = 2000,
                                                                   Tax_Percent__c = 8.65,
                                                                   Custom_Price__c = 0,
                                                                   Quantity_Invoiced__c = 0,
                                                                   Quantity_Refunded__c = 0);
        
        return salesOrderLineItem;
    }
    
    static public Purchase_Order__c createpurchaseorder(id salesOrderId, String recordType) {
        Recordtype poRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Purchase_Order__c' and Name=:recordType];
        
        Purchase_Order__c po = new Purchase_Order__c(Sales_Order__c = salesOrderId,Status__c = 'On Order',Tracking_Number__c='1234');
        Database.insert(po);
        
        return po;
    }
    
    static public PO_Line_Items__c createpoitem(id Poid, Id Soitemid) {
        
        PO_Line_Items__c poi = new PO_Line_Items__c(Purchase_Order__c=Poid,SO_Line_Item__c=Soitemid,PO_Item_Status__c='On Order');
        Database.insert(poi);
        return poi;
    }
    
    static public PO_Line_Items__c createpoitemNotInsert(id Poid, Id Soitemid) {
        PO_Line_Items__c poi = new PO_Line_Items__c(Purchase_Order__c=Poid,SO_Line_Item__c=Soitemid,PO_Item_Status__c='On Order');
        
        return poi;
    }
    
    static public Shipment__c createshipment(id Poid, Id Soid, String recordtypeName) {
        RecordType shipmentRecordType = [Select id,Name from RecordType where SObjectType = 'Shipment__c' and Name =:recordtypeName];
        
        Shipment__c ship = new Shipment__c(RecordTypeId=shipmentRecordType.id,
                                           Purchase_Order__c=Poid,
                                           Related_Sales_Order__c=soid,
                                           Shipment_Status__c='Draft');
        Database.insert(ship);
        return ship;
    }
    
    static public Shipment_Line_Item__c createshipmentItem(id shipid, Id poitemid) {
        
        Shipment_Line_Item__c shipitem = new Shipment_Line_Item__c(Shipment__c=shipid,PO_Line_Item__c=poitemid,Shipment_Item_Status__c='Draft',Approval_Status__c='');
        Database.insert(shipitem);
        return shipitem;
    }
    
    static public Invoice__c createpayableInvoice(id salesOrderId) {
        Recordtype payablesRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Invoice__c' and Name = 'Payables']; 
        
        Invoice__c payableInvoice = new Invoice__c(RecordtypeId = payablesRecordType.id,
                                                   Sales_Order__c = salesOrderId,
                                                   Reason_for_Refund__c = 'Cancellation',
                                                   Location_Of_Furniture__c = 'Customer Location',
                                                   Condition_Of_Furniture__c = 'Unopened');
        
        Database.insert(payableInvoice);
        return payableInvoice;
    }
    
    static public Invoice__c createreceivablesInvoice(id salesOrderId) {
        Recordtype receivablesRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Invoice__c' and Name = 'Receivables']; 
        
        Invoice__c receivablesInvoice = new Invoice__c(RecordtypeId = receivablesRecordType.id,
                                                       Sales_Order__c = salesOrderId);
        
        Database.insert(receivablesInvoice);
        return receivablesInvoice;
    }
    
    static public Invoice_Line_Item__c createInvoiceLineItem(id salesOrderId,Id soLineItemId, Id InvoiceId) {
        Invoice_Line_Item__c invoiceLineItem = new Invoice_Line_Item__c(Sales_Order__c = salesOrderId,
                                                                        Invoice__c = InvoiceId,
                                                                        Items_invoiced__c = soLineItemId,
                                                                        Quantity_To_Refund__c = 2,
                                                                        Quantity_to_Invoice__c = 2);
        
        Database.insert(invoiceLineItem);
        return invoiceLineItem;
    }
    
    static public Case createCase(Id salesOrderId, id shipmentLineId, String supportType, String recordType) {
        Recordtype caseRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' and Name=:recordType]; 
        
        Case oneCase = new Case(RecordTypeId = caseRecordType.id, Sales_Order__c = salesOrderId,
                                Shipment_Line_Item__c = shipmentLineId, Support_Type__c = supportType);
        
        Database.insert(oneCase);
        return oneCase;
    }
    
    static public Transaction__c createTrasaction(id salesOrderId,Id paymentId, String trasactionType) {
        Transaction__c transact = new Transaction__c(TransactionId__c = ''+generateRandomNumber(),
                                                     Sales_Order__c = salesOrderId,
                                                     Payment_Method__c = paymentId,
                                                     Amount__c = 1500,
                                                     Transaction_Type__c = trasactionType);
        
        if(transact.Transaction_Type__c == 'AUTH_ONLY') {
            transact.Status__c = 'Authorized';
        }
        else if(transact.Transaction_Type__c == 'CAPTURE_ONLY') {
            transact.Status__c = 'Captured';
        }
        
        Database.insert(transact);
        return transact;
    }
    
    static public Refund_Process__c createRefundProcess(String processName,Boolean isShippingCharges) {
        //Name should either Delivery Hub, En Route and Customer Location
        Refund_Process__c refundProcess = new Refund_Process__c(Name = processName,
                                                                Is_Shipping_Charged_Based_on_weight__c = isShippingCharges);
        
        Database.insert(refundProcess);
        return refundProcess;
    }
    
    static public User createCustomerPortalUser(String portalUserName) {
        
        UserRole userRole = new UserRole(name = 'TEST ROLE executive');
        Database.insert(userRole);
        
        User userWithRole = new User(
            userRoleId = userRole.id,
            profileId  = UserInfo.getProfileId(), 
            isActive   = true,
            alias      = 'hasrole',
            email      = TestUtil.generateRandomEmail(), 
            username   = TestUtil.generateRandomEmail(), 
            lastname   = 'lastname', 
            CommunityNickname = TestUtil.generateRandomName().left(40),
            emailencodingkey  = 'UTF-8', 
            localesidkey      = 'en_US',
            languagelocalekey = 'en_US', 
            timezonesidkey    = 'America/Los_Angeles');
        
        Contact contact;
        
        System.runAs(userWithRole) {
            Account account = new Account(name = 'TEST ACCOUNT');
            Database.insert(account);
            
            contact = new Contact(AccountId = account.id,firstname='first name', lastname = 'lastname');
            Database.insert(contact);
        }
        
        User portalUser = new User(
            profileId = getCustomerPortalStandarUserProfileId(),
            contactId = contact.id,
            isActive  = true,
            alias     = 'cspu',
            email     = TestUtil.generateRandomEmail(), 
            username  = portalUserName, 
            lastname  = 'lastname', 
            CommunityNickname = TestUtil.generateRandomName().left(40),
            emailencodingkey  = 'UTF-8', 
            localesidkey      = 'en_US',
            languagelocalekey = 'en_US', 
            timezonesidkey    = 'America/Los_Angeles');
        
        return portalUser;
    }
    
    static public User createSysUser(String UserName) {
        UserRole userRole = new UserRole(name = 'Sales Dept. Staff');
        Database.insert(userRole);
        
        User sysUser = new User(
            profileId  = UserInfo.getProfileId(), 
            isActive   = true,
            alias      = 'hasrole',
            email      = TestUtil.generateRandomEmail(), 
            username   = UserName, 
            lastname   = 'lastname', 
            userRoleId = userRole.id,
            CommunityNickname = TestUtil.generateRandomName().left(40),
            emailencodingkey  = 'UTF-8', 
            localesidkey      = 'en_US',
            languagelocalekey = 'en_US', 
            timezonesidkey    = 'America/Los_Angeles');
        
        insert sysUser;
        return sysUser;
    }
    
    public static String getFakeId(Schema.SObjectType sot) {
        String result = String.valueOf(s_num++);
        
        return sot.getDescribe().getKeyPrefix() + '0'.repeat(12-result.length()) + result;
    }
    
    private static Id getCustomerPortalStandarUserProfileId() {
        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name='Customer Portal Standard User' LIMIT 1];
        
        if(profiles.size() > 0) {
            return profiles[0].Id;
        }
        return null;    
    } 
}