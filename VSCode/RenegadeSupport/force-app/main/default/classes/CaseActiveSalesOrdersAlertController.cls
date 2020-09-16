public with sharing class CaseActiveSalesOrdersAlertController {
    public string salesOrderObjId;
    public Boolean isNotify {get;set;}
    public Sales_Order__c salesorder;
    public Integer count{get;set;}
    public string customerName{get;set;}
    
    public CaseActiveSalesOrdersAlertController(ApexPages.StandardController controller) 
    {
        isNotify = false;
        this.salesOrderObjId = [select Sales_Order__c from Case  where id = :ApexPages.currentPage().getParameters().get('id') limit 1].Sales_Order__c;
    }
    
    public void Display()
    {
        try
        {
            Sales_Order__c so = [select id,name,CreatedDate,Order_Status__c,Customer_Name__c,Customer_Name__r.name from Sales_Order__c where id=:salesOrderObjId];
            
            if(so.Order_Status__c != 'Completed' || so.Order_Status__c != 'Cancelled' || so.Order_Status__c != 'Draft')
            {
                System.debug('so.Customer_Name__c: '+so.Customer_Name__c);
                System.debug('so.name: '+so.name);
                count=getSalesOrdersCount(so.Customer_Name__c,so.name);
                if(count>0)
                {
                    isNotify = true;
                    customerName=so.Customer_Name__r.name;
                }
            }
            else
                isNotify = true; 
            customerName=so.Customer_Name__r.name;
        }
        catch(Exception e)
        {
            system.debug('exception '+e);
        }
        
    }
    private static Integer getSalesOrdersCount(string accountID,string orderNumber)
    {
        integer i=[select count() from Sales_Order__c 
                   where Customer_Name__c =:accountID 
                   and order_Status__c != 'Completed' AND Order_Status__c != 'Cancelled' AND Order_Status__c != 'Draft' and name!=:orderNumber];
        System.debug('I: '+i);
        return i;
    }
}