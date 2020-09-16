global class InventoryAvailabilityUpdateBatch implements Database.Batchable<sObject> {
    List<String> productConditionList = new List<String> { 'Resellable', 'Unopened' };
    
    global List<Inventory__c> start(Database.BatchableContext bc) {
        return [SELECT id FROM Inventory__c WHERE Quantity__c > 0 AND Product_condition__c IN :productConditionList AND Update_inventory_on_product__c = false];//Database.getQueryLocator('SELECT id FROM Inventory__c');
    }

    global void execute(Database.BatchableContext bc, List<Inventory__c> inventoryList) {
        for(Inventory__c currentInventory_i : inventoryList) {
            currentInventory_i.Update_inventory_on_product__c = true;
        }
        update inventoryList;
    }    
    
    global void finish(Database.BatchableContext bc) {
    }    
}