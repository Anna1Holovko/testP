/* To Retrieve the realted Configurable items of a product in products and Pass the values to VF page ProductsRelatedList */
public class ProductsRelatedList { 
    
    public list<Products__c> relatedProducts {get; set;}
    public Map<Id, Configurable_Item__c> productSingleJunctionMap {get; set;}
    private Products__c product;
    private String productFieldId {
        get {
            if (productFieldId == null) {
                List<Product_Fields__c> fields = [SELECT Field_Id__c FROM Product_Fields__c WHERE Name = 'Product' AND sObject_Name__c = 'Configurable Item' LIMIT 1];
                if (fields.size() == 1) {
                    productFieldId = fields[0].Field_Id__c;
                }
                else {
                    system.debug('No information in custom settings');
                }
            }
            return productFieldId;
        }
        set;
    }
    
    public ProductsRelatedList(ApexPages.StandardController controller) { 
        product=(Products__c)controller.getrecord();
        product=[SELECT Name, id, RecordTypeId, RecordType.DeveloperName FROM Products__c WHERE id=:product.id];
        getRelatedProducts();
    }

    @TestVisible
    private void getRelatedProducts() {
        
        List<Configurable_Item__c> junctions = [SELECT Id, Name, Product__c, Configurable_Product__c FROM Configurable_Item__c WHERE Configurable_Product__c = :product.id];
        productSingleJunctionMap = new Map<Id, Configurable_Item__c>();

        for (Configurable_Item__c junction : junctions) {
            if (junction.Product__c != null) {
                productSingleJunctionMap.put(junction.Product__c, junction);
            }
        }

        relatedProducts = [
            SELECT Id, name, SKU__c, Select_Manufacturer__c, Select_Manufacturer__r.name,Category__c, Sub_Category__c, Sales_Price__c,
            Product_Type__c, Status__c, Master_Products__c, ProductImage__c
            FROM Products__c
            WHERE Id IN :productSingleJunctionMap.keySet()
        ];
    }
    
    public pagereference newProduct() {
        // get sobject id prefix
        String prefix = Schema.getGlobalDescribe().get('Configurable_Item__c').getDescribe().getKeyPrefix();
        String url = '/' + prefix + '/e?CF' + productFieldId + '=' + product.Name + '&CF' + product.Id + '_lkid=' + product.Id + '&retURL=%2F' + product.id + '&saveURL=%2F' + product.id;
        pagereference pagereferenceOBj = new pagereference(url);
        system.debug('ref ' + pagereferenceOBj.getUrl());
        system.debug('productFieldId ' + productFieldId);
        return pagereferenceOBj;
    } 
}