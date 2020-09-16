/*
*   Author : Pavan Vuppala | Kairos Tech
*   Class  : AccountRelSalesOrdersController
*   Purpose: This class is used to tracking the sales order from the customer.
*/
public class AccountRelSalesOrdersController 
{
    public List<Sales_Order__c> salesOrdersList{set;get;}
    public string SOID;
    public boolean displayPopup{set;get;}
    public map<SO_Line_Items__c,list<SO_Line_Items__c>> SoLineItems;
    public map<SO_Line_Items__c,list<SO_Line_Items__c>> SoRelatedTemp;
    public Sales_Order__c salesOrderDetails{set;get;}
    public list<Transaction__c> TransactionDetails;
    
    public AccountRelSalesOrdersController()
    {	
        salesOrderDetails = new Sales_Order__c();
        TransactionDetails = new list<Transaction__c>();
        salesOrdersList = new list<Sales_Order__c>();
        string customerID = ApexPages.currentPage().getParameters().get('customerid');
        SOID='';
        try {
            if(customerID!=null)
            {
                salesOrdersList = [select id,name,Sales_Rep_Name__c,Order_Date__c,Order_Status__c,Payment_Status__c,Grand_Total__c,Customer_Billing_Address__c,Customer_shipping_Address__c,Customer_Order_Status__c,Magento_order_No__c from Sales_Order__c  where Customer_Name__c=:[select id,Magento_Account_Id__c from account where Magento_Account_Id__c =:customerID].id ANd Magento_order_No__c != null];
            }
            system.debug('customer id ----'+customerID); 
            
            if(salesOrdersList.size() <= 0) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'No Orders found.'));
            }
        }
        catch(Exception e) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.INFO, 'No Orders found.'));
            System.debug('Exception ex: '+e.getMessage());
        }
    } 
    public list<Transaction__c> getTransactionDetails()
    {
       if(SOID!=null)
        {
            TransactionDetails = [SELECT Id, Name, OrderId__c, TransactionId__c, Transaction_Response__c, ProcessedDate__c, Sales_Order__c, Payment_Method__c,Payment_Method__r.Payment_type_image__c,Invoice__c, Amount__c, Transaction_Type__c, Status__c, AVS_Response__c, Card_Number__c, Card_Type__c, Payment_Type__c FROM Transaction__c where Sales_Order__c=:SOID and Transaction_Type__c='AUTH_ONLY' and Status__c!='Voided'];
            system.debug('TransactionDetails '+TransactionDetails);
        }
        return TransactionDetails;
    }
    
    public map<SO_Line_Items__c,list<SO_Line_Items__c>> getSoLineItems()
    {
        SoRelatedTemp = new map<SO_Line_Items__c,list<SO_Line_Items__c>>();
        
        if(SOID!=null)
        {
            TransactionDetails=[SELECT Id, Name, OrderId__c, TransactionId__c, Transaction_Response__c, ProcessedDate__c, Sales_Order__c, Payment_Method__c,Payment_Method__r.Payment_type_image__c,Invoice__c, Amount__c, Transaction_Type__c, Status__c, AVS_Response__c, Card_Number__c, Card_Type__c, Payment_Type__c FROM Transaction__c where Sales_Order__c=:SOID and Transaction_Type__c='AUTH_ONLY'];
            system.debug('TransactionDetails '+TransactionDetails);
            
            salesOrderDetails=[select id,name,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c,Ship_to__c,Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_ZipCode__c,Customer_Name__r.Name,Email__c,Customer_Order_Status__c from Sales_Order__c where id=:SOID ];
            
            list<SO_Line_Items__c> MainSOitems=[select id,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Sales_Order__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                                                    Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c,Customer_Item_Status__c from SO_Line_Items__c where Bundle_Item__c=null and Sales_Order__c =: SOID];
                
            list<SO_Line_Items__c> BundelSOitems=[select id,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Product_Record_Type__c,Custom_Price__c,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                                                      Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c,Customer_Item_Status__c from SO_Line_Items__c where Bundle_Item__c!=null and Sales_Order__c =: SOID];
                
                  
            for(SO_Line_Items__c SoiItem: MainSOitems)
            {
                if(SoiItem.Products__r.recordtype.name=='Bundled')
                {
                    list<SO_Line_Items__c> BundelSOitemstemp=new list<SO_Line_Items__c>();
                    for(SO_Line_Items__c BundelItem: BundelSOitems) 
                    {
                        if(SoiItem.Products__c == BundelItem.Products__c)
                        {
                            BundelSOitemstemp.add(BundelItem);
                        }
                    }
                    if(BundelSOitemstemp.size()>0)
                    {
                        SoRelatedTemp.put(SoiItem,BundelSOitemstemp);
                    }
                    else
                    {
                        SoRelatedTemp.put(SoiItem,new list<SO_Line_Items__c>());
                    }
                }
                else
                {
                    SoRelatedTemp.put(SoiItem,new list<SO_Line_Items__c>());
                }          
            } 
        }
        
        return SoRelatedTemp;
    }
    
    public void ShowSOLineItems()
    {
        SOID=apexpages.currentpage().getParameters().get('SOItemId');
        system.debug(SOID); 
        displayPopup = true;
    }

}