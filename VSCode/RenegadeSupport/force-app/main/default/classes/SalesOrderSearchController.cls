global class SalesOrderSearchController {
    public list<sales_order__c> salesOrdersList{set;get;}
    
    public string lastPayapalId{set;get;}
    public string firstPayapalId{set;get;}
    public string storedquery{set;get;}
    public boolean displayselectionPopup{set;get;}
    
    public string OptionsId{set;get;}
    public string status{set;get;}
    public string OrderNumber{set;get;}
    
    public SalesOrderSearchController()
    {
        status = '';
        salesOrdersList = [select id,name,Magento_order_No__c,Order_Date__c,Email__c,Bill_To__c,Ship_to__c,Payment_Status__c,Sales_Rep_Name__c,Grand_Total__c,order_status__c,Customer_Name__r.name,(select id,Name,Bundle_Item__c,Sales_Order__c,ProductImageUrl__c,Product_Name__c,Manufacturer__c,Item__c,UnitPrice__c,Products__r.recordtype.name,Products__c from SO_Line_Items__r) from sales_order__c ORDER BY Id ASC limit 20 ];
        storedquery = 'Select id,name,Magento_order_No__c,Order_Date__c,Email__c,Bill_To__c,Ship_to__c,Payment_Status__c,Sales_Rep_Name__c,Grand_Total__c,order_status__c,Customer_Name__r.name,(select id,Name,Bundle_Item__c,Sales_Order__c,ProductImageUrl__c,Product_Name__c,Manufacturer__c,Item__c,UnitPrice__c,Products__r.recordtype.name,Products__c from SO_Line_Items__r) from sales_order__c where name != null ';
        
        system.debug('salesOrdersListTemp : '+salesOrdersList);
        
        if(salesOrdersList.size() > 0)
        {
            lastPayapalId = salesOrdersList[salesOrdersList.size()-1].id;
            firstPayapalId = salesOrdersList[0].id; 
        }
    }
    
    public map<string,SOItemsWrapper> getSoRelatedList() 
    {
        system.debug('in getSoRelatedList');
        map<string,SOItemsWrapper> soRelatedList = new map<string,SOItemsWrapper>();
        
        if(OptionsId != null) {
            list<SO_Line_Items__c> BundelSOitems = [select id,FedExable__c,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Custom_Price__c,TaxAmount__c,Sub_Total__c,Price__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Tax_Amount__c,Bundle_Item__r.Include__c,
                                                    Products__r.Select_Manufacturer__r.Direct_Shipping__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Total_Weight_Pounds__c,
                                                    Products__r.Select_Manufacturer__r.Ship_To_HUB__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Item__c from SO_Line_Items__c where Bundle_Item__c != null and Sales_Order__c =:OptionsId];
            system.debug('BundelSOitems'+BundelSOitems.size());
            for(SO_Line_Items__c SoiItem : [select id,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,Tax_Amount__c,
                                            Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.name,Tax_Percent__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where Sales_Order__c =:OptionsId and Bundle_Item__c = null ORDER BY Name ASC])
            { 
                OrderNumber = SoiItem.Sales_Order__r.name;
                if(SoiItem.Products__r.recordtype.name == 'Bundled')
                {
                    list<SO_Line_Items__c> BundelSOitemstemp = new list<SO_Line_Items__c>();
                    for(SO_Line_Items__c BundelItem : BundelSOitems) 
                    { 
                        if(SoiItem.Products__c == BundelItem.Products__c)
                        {                        
                            BundelSOitemstemp.add(BundelItem);
                        }
                    }
                    system.debug('BundelSOitemstemp ' +BundelSOitemstemp); 
                    if(BundelSOitemstemp.size()>0)
                    {
                        soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(SoiItem,BundelSOitemstemp));
                    }
                    else
                    {  
                        soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(SoiItem,new list<SO_Line_Items__c>()));
                    }
                }
                else
                {                                
                    soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new SOItemsWrapper(SoiItem,new list<SO_Line_Items__c>()));                
                }
            }
        }
        system.debug('soRelatedList'+soRelatedList);
        return soRelatedList;
    }
    
    public void showProducts()
    {
        try
        {
            system.debug('salesOrdersList ' + salesOrdersList);
            String productsJSON = Apexpages.currentPage().getParameters().get('productlistfromparam');
            if(productsJSON!='[]')
            {
                system.debug('productsJSON ' +productsJSON);
                salesOrdersList=new list<sales_order__c>();
                
                productsJSON = productsJSON.replaceAll('&quot;', '"');
                productsJSON = productsJSON.replaceAll('&amp;', '&');
                
                if(productsJSON.contains('storedQuery'))
                {
                    storedquery = productsJSON.split('storedQuery')[1];
                    productsJSON = productsJSON.split('storedQuery')[0];                        
                }
                system.debug('productsJSON ' +productsJSON);
                salesOrdersList =(List<sales_order__c>)JSON.deserialize(productsJSON, List<sales_order__c>.class);    
                system.debug('deserializedproducts ' +salesOrdersList);
                if(salesOrdersList.size() > 0)
                {
                    lastPayapalId = salesOrdersList[salesOrdersList.size()-1].id;
                    firstPayapalId = salesOrdersList[0].id; 
                }
            }
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()+'   '+ex.getLineNumber()));
        }
    }
    
    public void showpopup()
    {
        displayselectionPopup=true; 
    }
    
    public void closeselectionPopup()
    {
        displayselectionPopup = false;  
    }
    
    @RemoteAction
    global static string getPrevProducts(string firstPayapalval,string query) 
    {
        String productsJSON ;
        try
        {
            system.debug('firstPayapalval ' + firstPayapalval);
            system.debug('query  ' + query);
            list<sales_order__c> productsList=new list<sales_order__c>();
            list<sales_order__c> salesOrdersListTemp=new list<sales_order__c>();
            string condition=' ';
            
            if(query != null )
            {
                if(firstPayapalval == null)
                {
                    condition = ' order by id limit 20';
                }
                else
                {
                    condition = ' and id < \''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                }
            }
            
            query = query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            system.debug('query+condition  ' + query);
            
            salesOrdersListTemp = database.query(query);
            
            for(integer i=salesOrdersListTemp.size()-1;i>=0;i--)
            {
                productsList.add(salesOrdersListTemp[i]);
            }
            system.debug('productsList '+productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception EX : '+ex.getMessage()+', Line number :  '+ex.getLineNumber()+', Cause : '+ex.getCause());
        }
        return productsJSON;
    }
    
    @RemoteAction
    global static string getNextProducts(string lastPayapalval,string query) 
    {
        String productsJSON ;
        try
        {
            system.debug('lastPayapalval ' + lastPayapalval);
            
            list<sales_order__c> productsList = new list<sales_order__c>();
            string condition=' ';
            system.debug('query : ' + query);
            
            if(query != null )
            {
                if(lastPayapalval == null)
                {
                    condition = ' order by id limit 20';
                }
                else
                {
                    if(query.contains('where')) {
                        condition = ' and id > \''+lastPayapalval+'\' ORDER BY Id ASC limit 20';
                    }
                    else
                    	condition = ' where id > \''+lastPayapalval+'\' ORDER BY Id ASC limit 20';
                }
            }
            
            query = query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            
            system.debug('query+condition  ' + query);
            productsList = database.query(query);
            system.debug('productsList  ' + productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception EX : '+ex.getMessage()+', Line number :  '+ex.getLineNumber()+', Cause : '+ex.getCause());
        }
        return productsJSON;
    }
    
    @RemoteAction
    global static string searchProducts(string Status,string orderNumber,string customerName,string Email) 
    {        
        String productsJSON = '';
        try {
            string query = 'select id,name,Magento_order_No__c,Order_Date__c,Email__c,Bill_To__c,Ship_to__c,Payment_Status__c,Sales_Rep_Name__c,Grand_Total__c,order_status__c,Customer_Name__r.name,(select id,Name,ProductImageUrl__c,Product_Name__c,Manufacturer__c,Item__c,UnitPrice__c from SO_Line_Items__r)  from sales_order__c where name != null  ';
            string condition = '';
            string storedQuery = '';
            
            if(Status != '')
            {
                Status = Status.trim();
                condition = ' and Order_Status__c LIKE '+'\'%'+Status+'%\'';
            }  
            if(orderNumber != '')
            {
                orderNumber = String.escapeSingleQuotes(orderNumber);
                orderNumber = orderNumber.trim();
                condition = condition+' and (Name LIKE '+'\'%'+orderNumber+'%\' or Magento_order_No__c LIKE '+'\'%'+orderNumber+'%\')';           
            }
            if(customerName != '')
            { 
                customerName = String.escapeSingleQuotes(customerName);
                customerName = customerName.trim();
                condition = condition+' and Customer_Name__r.name LIKE '+'\'%'+customerName+'%\''; 
            }
            if(Email != '')
            { 
                Email = String.escapeSingleQuotes(Email);
                Email = Email.trim();
                condition = condition+' and Email__c LIKE \'%'+Email+'%\''; 
            }
            if(condition.contains('&#39;')) 
                condition = condition.replaceAll('&#39;', '\'');
            storedQuery = query + condition;
            query = query+condition+' order by id limit 20 '; 
            system.debug('query : ' +query);
            list<sales_order__c> productsList = new list<sales_order__c>();
            productsList = database.query(query);
            productsJSON = JSON.serialize(productsList);
            
            if(productsJSON != '[]')
            {
                productsJSON = productsJSON+' storedQuery '+storedQuery; 
            }
            
            system.debug('productsJSON ' +productsJSON);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception EX : '+ex.getMessage()+', Line number :  '+ex.getLineNumber()+', Cause : '+ex.getCause());
        }
        return productsJSON;
    }    
    
    public PageReference goTosalesorderlist()
    {
        pagereference pr;  
        try
        { 
            Schema.DescribeSObjectResult objectSchemaData = Sales_Order__c.sObjectType.getDescribe();
            String keyPrefix =  '/'+objectSchemaData.getKeyPrefix()+'/o';
            pr = new pagereference(keyPrefix);
        }
        catch(exception ex)
        {
            system.debug(ex.getLineNumber()+' msg '+ ex.getMessage());
        }
        return pr;
    }
    
    public class SOItemsWrapper
    {
        public SO_Line_Items__c SoItem {get; set;}
        public list<SO_Line_Items__c> bundleList {get; set;}  
        
        public SOItemsWrapper(SO_Line_Items__c SOI,list<SO_Line_Items__c> bundle)
        {
            SoItem = SOI;
            bundleList = bundle;
        }
    }
}