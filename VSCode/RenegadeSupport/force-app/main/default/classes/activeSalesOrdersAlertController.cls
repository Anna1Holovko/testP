public class activeSalesOrdersAlertController {
    public Sales_Order__c salesOrderObj;
    public Boolean isNotify { get; set; }
    public Boolean checkFraudAlert { get; set; }
    public Sales_Order__c salesorder;
    public Integer count{get;set;}
    public string customerName { get; set; }
    
    public activeSalesOrdersAlertController(ApexPages.StandardController controller) {
        isNotify = checkFraudAlert = false;
        this.salesOrderObj = (Sales_Order__c)controller.getrecord();
    }
    
    public void Display() {
        try {
            Sales_Order__c so = [SELECT Id, Name, CreatedDate, Order_Status__c, Customer_Name__c, Customer_Name__r.Name, White_Pages_secondary_phone_line_type__c,
                                 White_Pages_secondary_phone_carrier__c, Check_for_Fraud__c
                                 FROM Sales_Order__c WHERE Id =: salesOrderObj.Id];
            
            if (so.Order_Status__c == 'Held under Fraud Check Dept'/* && so.Check_for_Fraud__c*/) {
                if (so.White_Pages_secondary_phone_line_type__c == 'Non-fixed VOIP' ||
                    so.White_Pages_secondary_phone_carrier__c == 'Pinger' ||
                    so.White_Pages_secondary_phone_carrier__c == 'TextPlus') {
                        checkFraudAlert = true;
                    }
            }
            
            if(so.Order_Status__c != 'Completed' || so.Order_Status__c != 'Cancelled' || so.Order_Status__c != 'Draft') {
                System.debug('so.Customer_Name__c: '+so.Customer_Name__c);
                System.debug('so.name: '+so.name);
                count=getSalesOrdersCount(so.Customer_Name__c,so.name);
                if (count > 0) {
                    isNotify = true;
                    customerName=so.Customer_Name__r.name;
                }
            }
            else
                isNotify = true; 
            customerName=so.Customer_Name__r.name;
        }
        catch(Exception e) {
            system.debug('exception '+e);
        }
        
    }
    private static Integer getSalesOrdersCount(string accountID,string orderNumber) {
        integer i=[select count() from Sales_Order__c 
                   where Customer_Name__c =:accountID 
                   and order_Status__c != 'Completed' AND Order_Status__c != 'Canceled' AND Order_Status__c != 'Cancelled - Delivery area' AND Order_Status__c != 'Cancelled - Underpriced' AND Order_Status__c != 'Draft' and name!=:orderNumber];
        System.debug('I: '+i);
        return i;
    }
}