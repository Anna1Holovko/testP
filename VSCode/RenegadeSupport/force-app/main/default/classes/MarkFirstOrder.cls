global class MarkFirstOrder {
@InvocableMethod
    public static void markOrder(List<String> accountId) {
      Integer numOfOrders = [SELECT COUNT() FROM Sales_Order__c WHERE Customer_Name__c in: accountId];
   	  Sales_Order__c SO = [SELECT Id, First_Order__c FROM Sales_Order__c WHERE Customer_Name__c in: accountId LIMIT 1];
      if(numOfOrders==1){
      	try{
        	Sales_Order__c updateSO = new Sales_Order__c(Id = SO.Id, First_Order__c = True);
            update updateSO;
        } catch(DmlException e) {
        	System.debug('The following exception has occurred: ' + e.getMessage());
        }
      }
   }
}