@isTest
private class SO_Line_ItemTriggerHandlerTest {
    @testSetup
    static void setup() {
        Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Shipping_ZipCode__c = '10101';
        update so;
        
        Shipping_Zip_Codes__c zipCode = new Shipping_Zip_Codes__c();
        zipCode.Zip_Code__c = '10101';
        zipCode.TaxJar_Sales_Tax__c = 10;
        insert zipCode;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
    }
    @isTest
    static void afterInsertTest() {
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c LIMIT 1][0];
        Products__c pro = [SELECT Id FROM Products__c LIMIT 1][0];
        
        Test.startTest();
        
        SO_Line_Items__c Sol = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                    Products__c = pro.id,
                                                    Config_Product__c = null,
                                                    Bundle_Item__c = null,
                                                    Item__c = 'Processing',
                                                    Quantity__c = 5,
                                                    Price__c = 20,
                                                    Custom_Price__c = 0,
                                                    Quantity_Invoiced__c = 0,
                                                    Quantity_Refunded__c = 0);
        insert Sol;
        
        SO_Line_Items__c Sol2 = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                     Products__c = pro.id,
                                                     Config_Product__c = null,
                                                     Bundle_Item__c = null,
                                                     Item__c = 'Processing',
                                                     Quantity__c = 6,
                                                     Price__c = 22,
                                                     Custom_Price__c = 0,
                                                     Quantity_Invoiced__c = 0,
                                                     Quantity_Refunded__c = 0);
        insert Sol2;
        
        Test.stopTest();
        
        Decimal value = [SELECT Sum_of_Retail_Value__c FROM Sales_Order__c WHERE Id =: so.id].Sum_of_Retail_Value__c;
        Decimal value2 = (Decimal)[SELECT SUM(Retail_Value_for_Delivery_Company__c) su FROM SO_Line_Items__c GROUP BY Sales_Order__c][0].get('su');
        System.assertEquals(value, value2);
    }
    
    @isTest
    static void afterInsertCancelledTest() {
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c LIMIT 1][0];
        Products__c pro = [SELECT Id FROM Products__c LIMIT 1][0];
        
        Test.startTest();
        
        SO_Line_Items__c Sol = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                    Products__c = pro.id,
                                                    Config_Product__c = null,
                                                    Bundle_Item__c = null,
                                                    Item__c = 'Cancelled',
                                                    Quantity__c = 5,
                                                    Price__c = 20,
                                                    Custom_Price__c = 0,
                                                    Quantity_Invoiced__c = 0,
                                                    Quantity_Refunded__c = 0);
        insert Sol;
        
        SO_Line_Items__c Sol2 = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                     Products__c = pro.id,
                                                     Config_Product__c = null,
                                                     Bundle_Item__c = null,
                                                     Item__c = 'Cancelled',
                                                     Quantity__c = 6,
                                                     Price__c = 22,
                                                     Custom_Price__c = 0,
                                                     Quantity_Invoiced__c = 0,
                                                     Quantity_Refunded__c = 0);
        insert Sol2;
        
        Test.stopTest();
        
        Decimal value = [SELECT Sum_of_Retail_Value__c FROM Sales_Order__c WHERE Id =: so.id].Sum_of_Retail_Value__c;
        Decimal value2 = (Decimal)[SELECT SUM(Retail_Value_for_Delivery_Company__c) su FROM SO_Line_Items__c GROUP BY Sales_Order__c][0].get('su');
        System.assertEquals(value, value2);
    }
    
    @isTest
    static void afterInsertCancelledBundleTest() {
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c LIMIT 1][0];
        Products__c pro = [SELECT Id FROM Products__c LIMIT 1][0];
        Products__c configPro = TestUtil.createConfigProduct();
        Products__c bundlePro = TestUtil.createBundleProduct();
        
        Test.startTest();
        
        SO_Line_Items__c Sol = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                    Products__c = pro.id,
                                                    Config_Product__c = configPro.Id,
                                                    Bundle_Item__c = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id).Id,
                                                    Item__c = 'Cancelled',
                                                    Quantity__c = 5,
                                                    Price__c = 20,
                                                    Custom_Price__c = 0,
                                                    Quantity_Invoiced__c = 0,
                                                    Quantity_Refunded__c = 0);
        insert Sol;
        
        SO_Line_Items__c Sol2 = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                     Products__c = pro.id,
                                                     Config_Product__c = configPro.Id,
                                                     Bundle_Item__c = TestUtil.createBundleItemProduct(configPro.id, bundlePro.id).Id,
                                                     Item__c = 'Cancelled',
                                                     Quantity__c = 6,
                                                     Price__c = 22,
                                                     Custom_Price__c = 0,
                                                     Quantity_Invoiced__c = 0,
                                                     Quantity_Refunded__c = 0);
        insert Sol2;
        
        Test.stopTest();
    }
    
    @isTest
    static void afterInsertCancelledUpdateTest() {
        Sales_Order__c so = [SELECT Id FROM Sales_Order__c LIMIT 1][0];
        Products__c pro = [SELECT Id FROM Products__c LIMIT 1][0];
        
        Test.startTest();
        
        SO_Line_Items__c Sol = new SO_Line_Items__c(Sales_Order__c = so.id,
                                                    Products__c = pro.id,
                                                    Config_Product__c = null,
                                                    Bundle_Item__c = null,
                                                    Item__c = 'Processing',
                                                    Quantity__c = 5,
                                                    Price__c = 20,
                                                    Custom_Price__c = 0,
                                                    Quantity_Invoiced__c = 0,
                                                    Quantity_Refunded__c = 0);
        insert Sol;
        
        Sol.Item__c = 'Cancelled';
        Sol.Product_Name__c += ' Protection Plan';
        update Sol;
        
        Test.stopTest();
    }
    
    @isTest
    static void beforeUpdateTest() {
        Id pId = [SELECT Id FROM Products__c LIMIT 1].Id;
        SO_Line_Items__c item = new SO_Line_Items__c(Sales_Order__c = [SELECT Id FROM Sales_Order__c LIMIT 1].Id,
                                                    Products__c = pId,
                                                     //p.id,
                                                    Config_Product__c = pId,
                                                    Bundle_Item__c = null,
                                                    Item__c = 'Processing',
                                                    Quantity__c = 5,
                                                    Price__c = 20,
                                                    Custom_Price__c = 0,
                                                    Quantity_Invoiced__c = 0,
                                                    Quantity_Refunded__c = 0);
        insert item;
        
        item = [SELECT Total_Weight_Pounds_For_Rollup__c, Total_Weight_Pounds__c FROM SO_Line_Items__c LIMIT 1];
        
        System.assertEquals(500, item.Total_Weight_Pounds_For_Rollup__c);
        
        item.Quantity__c = 4;
        
        update item;
        
        item = [SELECT Total_Weight_Pounds_For_Rollup__c, Total_Weight_Pounds__c FROM SO_Line_Items__c LIMIT 1];
        
        System.assertEquals(400, item.Total_Weight_Pounds_For_Rollup__c);
    }
}