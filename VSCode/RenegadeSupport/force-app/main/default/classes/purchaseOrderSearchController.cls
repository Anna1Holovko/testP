global class purchaseOrderSearchController  
{ 
    public list<Purchase_Order__c> purchaseOrdersList{set;get;}
    
    public list<Bundle_Item__c> bundleList{set;get;}
    public string lastPayapalId{set;get;}
    public string firstPayapalId{set;get;}
    public string storedquery{set;get;}
    public boolean displayselectionPopup{set;get;}
    public map<string,list<PO_Line_Items__c>> OrderItemsMap{set;get;}    
    public string OptionsId{set;get;}
    public string OrderNumber{set;get;}
    public string status{set;get;}
    
    public purchaseOrderSearchController()
    {
        OrderItemsMap=new map<string,list<PO_Line_Items__c>>();
        status='';
        purchaseOrdersList = [SELECT Id,Load_Date__c,Manufacturer_Name__c,Name,Sales_Order__r.Name,Status__c,Total_Items_Ordered__c,(select id,name,Product_Image_URL__c,Product__c,Quantity__c,So_Line_Item_Number__c,Product_SKU__c from PO_Line_Item__r) from Purchase_Order__c ORDER BY Id ASC limit 20 ];
        storedquery=  'SELECT Id,Load_Date__c,Manufacturer_Name__c,Name,Sales_Order__r.Name,Status__c,Total_Items_Ordered__c,(select id,name,Product_Image_URL__c,Product__c,Quantity__c,So_Line_Item_Number__c,Product_SKU__c from PO_Line_Item__r) from Purchase_Order__c';
        
        system.debug('purchaseOrdersListTemp ' +purchaseOrdersList);
        
        if(purchaseOrdersList.size() > 0)
        {
            lastPayapalId=purchaseOrdersList[purchaseOrdersList.size()-1].id;
            firstPayapalId=purchaseOrdersList[0].id; 
            
            for(Purchase_Order__c pro :purchaseOrdersList)
            {
                if(pro.PO_Line_Item__r !=null && pro.PO_Line_Item__r.size() > 0)
                {
                    OrderItemsMap.put(pro.id,pro.PO_Line_Item__r);
                }
            }
        }
        system.debug('OrderItemsMap ' + OrderItemsMap);
    }
    
    public void showProducts()
    {
        try
        {
            system.debug('purchaseOrdersList ' + purchaseOrdersList);
            String productsJSON = Apexpages.currentPage().getParameters().get('productlistfromparam');
            if(productsJSON != '[]')
            {
                system.debug('productsJSON ' +productsJSON);
                purchaseOrdersList = new list<Purchase_Order__c>();
                
                productsJSON = productsJSON.replaceAll('&quot;', '"');
                productsJSON = productsJSON.replaceAll('&amp;', '&');
                
                if(productsJSON.contains('storedQuery'))
                {
                    storedquery = productsJSON.split('storedQuery')[1];
                    productsJSON = productsJSON.split('storedQuery')[0];                        
                }
                system.debug('productsJSON ' +productsJSON);
                purchaseOrdersList = (List<Purchase_Order__c>)JSON.deserialize(productsJSON, List<Purchase_Order__c>.class);    
                system.debug('deserializedproducts ' +purchaseOrdersList);
                if(purchaseOrdersList.size() > 0)
                {
                    lastPayapalId = purchaseOrdersList[purchaseOrdersList.size()-1].id;
                    firstPayapalId = purchaseOrdersList[0].id; 
                    
                    OrderItemsMap = new map<string,list<PO_Line_Items__c>>();
                    
                    for(Purchase_Order__c pro : purchaseOrdersList)
                    {
                        if(pro.PO_Line_Item__r != null && pro.PO_Line_Item__r.size() > 0)
                        {
                            OrderItemsMap.put(pro.id,pro.PO_Line_Item__r);
                        }
                    }
                }
                system.debug('OrderItemsMap ' + OrderItemsMap);
            }
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception E: '+ex.getMessage()+', Line Number :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
            
        }
    }
    
    public void showBundelProducts()
    {
        try
        {
            displayselectionPopup=true;
            String configJSON='';
            
            system.debug('bundleList ' + bundleList);
            String productsJSON=Apexpages.currentPage().getParameters().get('productbundlelistfromparam');
            
            if(productsJSON!='[]')
            {
                system.debug('productsJSON ' +productsJSON);
                bundleList=new list<Bundle_Item__c>();
                list<Purchase_Order__c> purchaseOrdersListTemp=new list<Purchase_Order__c>();
                
                productsJSON=productsJSON.replaceAll('&quot;', '"');
                productsJSON=productsJSON.replaceAll('&amp;', '&');
                
                if(productsJSON.contains('configProducts'))
                {
                    configJSON=productsJSON.split('configProducts')[1];
                    productsJSON=productsJSON.split('configProducts')[0];                        
                }
                
                system.debug('productsJSON ' +productsJSON);
                bundleList =(List<Bundle_Item__c>)JSON.deserialize(productsJSON, List<Bundle_Item__c>.class);    
                system.debug('deserializedproducts ' +bundleList);
                
                if(configJSON!='')
                {
                    purchaseOrdersListTemp =(List<Purchase_Order__c>)JSON.deserialize(configJSON, List<Purchase_Order__c>.class);    
                    system.debug('purchaseOrdersListTemp ' +purchaseOrdersListTemp);
                    if(purchaseOrdersListTemp.size() > 0)
                    {
                        for(Purchase_Order__c pro :purchaseOrdersListTemp)
                        {
                            if(pro.PO_Line_Item__r !=null && pro.PO_Line_Item__r.size() > 0)
                            {
                                OrderItemsMap.put(pro.id,pro.PO_Line_Item__r);
                            } 
                        }
                    }
                }
                system.debug('OrderItemsMap ' +OrderItemsMap);
                
            }
            
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception E: '+ex.getMessage()+', Line Number :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
    }
    
    public void showpopup()
    {
        displayselectionPopup=true; 
        system.debug('OptionsId ' + OptionsId);
        system.debug('OrderItemsMap ' +  OrderItemsMap.keySet());
    }
    
    public void closeselectionPopup()
    {
        displayselectionPopup=false;  
    }
    
    
    @RemoteAction
    global static string getPrevPurchaseOrders(string firstPayapalval,string query) 
    {
        String productsJSON ;
        try
        {
            system.debug('firstPayapalval ' + firstPayapalval);
            system.debug('query  ' + query);
            list<Purchase_Order__c> productsList=new list<Purchase_Order__c>();
            list<Purchase_Order__c> purchaseOrdersListTemp=new list<Purchase_Order__c>();
            string condition=' ';
            
            if(query != null)
            {
                if(firstPayapalval == null)
                {
                    if(query.contains('where')) {
                        condition = ' order by id limit 20';
                    }
                    else 
                        condition = ' where order by id limit 20';
                }
                else
                {
                    if(query.contains('where')) {
                        condition = ' and id <\''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                    }
                    else 
                    	condition = ' where id <\''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                }
            }
            
            query = query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            purchaseOrdersListTemp = database.query(query);
            
            for(integer i=purchaseOrdersListTemp.size()-1;i>=0;i--)
            {
                productsList.add(purchaseOrdersListTemp[i]);
            }
            system.debug('productsList '+productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception E: '+ex.getMessage()+', Line Number :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
        return productsJSON;
    }
    
    @RemoteAction
    global static string getNextPurchaseOrders(string lastPayapalval,string query) 
    {
        String productsJSON ;
        try
        {
            system.debug('lastPayapalval ' + lastPayapalval);
            
            list<Purchase_Order__c> productsList=new list<Purchase_Order__c>();
            string condition=' ';
            system.debug('query  ' + query);
            if(query !=null )
            {
                if(lastPayapalval==null)
                {
                    if(query.contains('where')) {
                        condition = ' order by id limit 20';
                    }
                    else
                    condition=' where order by id limit 20';
                }
                else
                {
                    if(query.contains('where')) {
                        condition=' and id >\''+lastPayapalval+'\'  ORDER BY Id ASC limit 20 ';
                    }
                    else
                    condition=' where id >\''+lastPayapalval+'\'  ORDER BY Id ASC limit 20 ';
                }
            }
            
            query=query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            productsList =database.query(query);
            system.debug('productsList  ' + productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
            
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception E: '+ex.getMessage()+', Line Number :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
        return productsJSON;
    }
    
    @RemoteAction
    global static string searchPurchaseOrders(string Status,string orderNumber,string  manufacturerName) 
    {        
        String productsJSON='';
        string query = 'SELECT Id,Load_Date__c,Manufacturer_Name__c,Name,Sales_Order__r.Name,Status__c,Total_Items_Ordered__c,(select id,name,Product_Image_URL__c,Product__c,Quantity__c,So_Line_Item_Number__c,Product_SKU__c from PO_Line_Item__r) from Purchase_Order__c where name !=null  ';
        string condition='';
        string storedQuery=' ';
        System.debug('Status: '+Status);
        try{
            if(Status != '')
            {
                Status=Status.trim();
                condition =' and Status__c LIKE '+'\'%'+Status+'%\'';
            }  
            if(orderNumber != '')
            {
                orderNumber = String.escapeSingleQuotes(orderNumber);
                orderNumber = orderNumber.trim();
                condition = condition+' and Name LIKE '+'\'%'+orderNumber+'%\'';           
            }
            if(manufacturerName != '')
            { 
                manufacturerName = String.escapeSingleQuotes(manufacturerName);
                manufacturerName = manufacturerName.trim();
                condition = condition+' and Manufacturer_Name__c LIKE '+'\'%'+manufacturerName+'%\''; 
            }
            
            storedQuery = query;
            query = query+condition+' order by id limit 20 '; 
            system.debug('query  ' +query);
            list<Purchase_Order__c> productsList = new list<Purchase_Order__c>();
            productsList = database.query(query);
            system.debug('productsList  ' +productsList);
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
            System.debug('Exception E: '+ex.getMessage()+', Line Number :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
        return productsJSON;
    }    
    
    public PageReference goToPurchaseorderList(){
        pagereference pr;  
        try
        { 
            Schema.DescribeSObjectResult objectSchemaData = Purchase_Order__c.sObjectType.getDescribe();
            String keyPrefix =  '/'+objectSchemaData.getKeyPrefix()+'/o';
            pr=new pagereference(keyPrefix);
        }
        catch(exception ex)
        {
            system.debug(ex.getLineNumber()+' msg '+ ex.getMessage());
        }
        return pr;
    }
}