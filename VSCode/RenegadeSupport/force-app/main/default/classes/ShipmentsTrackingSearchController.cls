global class ShipmentsTrackingSearchController {
    public list<Shipment__c> ShipmentList{set;get;}
    
    public list<Bundle_Item__c> bundleList{set;get;}
    public  string lastPayapalId{set;get;}
    public  string firstPayapalId{set;get;}
    public  string storedquery{set;get;}
    public boolean displayselectionPopup{set;get;}
    public map<string,list<Shipment_Line_Item__c>> OrderItemsMap{set;get;}    
    public string OrderNumber{set;get;}
    public string OptionsId{set;get;}
    public string status{set;get;}
    
    public ShipmentsTrackingSearchController()
    {
        OrderItemsMap=new map<string,list<Shipment_Line_Item__c>>();
        status='';   
        ShipmentList = [SELECT name,Delivery_Company_Name__c,Delivery_Date_Actual__c,Trucking_Company_name__c,Shipment_Status__c,Ship_From__c,(select id,Name,Product_Image_URL__c,Product_Name__c,Quantity__c,Shipment_Item_Status__c from Shipment_Line_Itmes__r) from Shipment__c ORDER BY Id ASC limit 20 ];
        storedquery=  'SELECT name,Delivery_Company_Name__c,Delivery_Date_Actual__c,Trucking_Company_name__c,Shipment_Status__c,Ship_From__c,(select id,Name,Product_Image_URL__c,Product_Name__c,Quantity__c,Shipment_Item_Status__c from Shipment_Line_Itmes__r) from Shipment__c where name !=null ';
        
        system.debug('ShipmentListTemp ' +ShipmentList);
        
        if(ShipmentList.size() > 0)
        {
            lastPayapalId=ShipmentList[ShipmentList.size()-1].id;
            firstPayapalId=ShipmentList[0].id; 
            
            for(Shipment__c pro :ShipmentList)
            {
                
                if(pro.Shipment_Line_Itmes__r !=null && pro.Shipment_Line_Itmes__r.size() > 0)
                {
                    OrderItemsMap.put(pro.id,pro.Shipment_Line_Itmes__r);
                }
            }
        }
        system.debug('OrderItemsMap ' + OrderItemsMap);
    }
    
    public void showProducts()
    {
        try
        {
            system.debug('ShipmentList ' + ShipmentList);
            String productsJSON=Apexpages.currentPage().getParameters().get('productlistfromparam');
            system.debug('productsJSON :' +productsJSON);
            if(productsJSON!='[]')
            {
                system.debug('productsJSON ' +productsJSON);
                ShipmentList=new list<Shipment__c>();
                
                productsJSON=productsJSON.replaceAll('&quot;', '"');
                productsJSON=productsJSON.replaceAll('&amp;', '&');
                
                if(productsJSON.contains('storedQuery'))
                {
                    storedquery=productsJSON.split('storedQuery')[1];
                    productsJSON=productsJSON.split('storedQuery')[0];                        
                }
                system.debug('productsJSON ' +productsJSON);
                ShipmentList =(List<Shipment__c>)JSON.deserialize(productsJSON, List<Shipment__c>.class);    
                system.debug('deserializedproducts ' +ShipmentList);
                if(ShipmentList.size() > 0)
                {
                    lastPayapalId=ShipmentList[ShipmentList.size()-1].id;
                    firstPayapalId=ShipmentList[0].id; 
                    
                    OrderItemsMap=new map<string,list<Shipment_Line_Item__c>>();
                    
                    for(Shipment__c pro :ShipmentList)
                    {
                        if(pro.Shipment_Line_Itmes__r !=null && pro.Shipment_Line_Itmes__r.size() > 0)
                        {
                            OrderItemsMap.put(pro.id,pro.Shipment_Line_Itmes__r);
                        }
                    }
                    
                }
                system.debug('OrderItemsMap ' + OrderItemsMap);
            }
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()+'   '+ex.getLineNumber()));
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
            
            list<Shipment__c> productsList=new list<Shipment__c>();
            list<Shipment__c> ShipmentListTemp=new list<Shipment__c>();
            string condition=' ';
            
            if(query !=null )
            {
                if(firstPayapalval==null)
                {
                    if(query.contains('where')) {
                        condition=' order by id limit 20';
                    }
                    else
                        condition=' where order by id limit 20';
                }
                else
                {
                    if(query.contains('where')) {
                        condition=' and id <\''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                    }
                    else
                        condition=' where id <\''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                }
            }
            
            query=query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            ShipmentListTemp=database.query(query);
            
            for(integer i=ShipmentListTemp.size()-1;i>=0;i--)
            {
                productsList.add(ShipmentListTemp[i]);
            }
            system.debug('productsList '+productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()+'   '+ex.getLineNumber()));
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
            
            list<Shipment__c> productsList=new list<Shipment__c>();
            string condition=' ';
            system.debug('query  ' + query);
            if(query !=null )
            {
                if(lastPayapalval==null)
                {
                    if(query.contains('where')) {
                        condition='order by id limit 20';
                    }
                    else
                        condition=' where order by id limit 20';
                }
                else
                {
                    if(query.contains('where')) {
                        condition=' and id >\''+lastPayapalval+'\' ORDER BY Id ASC limit 20 ';
                    }
                    else
                        condition=' where id >\''+lastPayapalval+'\' ORDER BY Id ASC limit 20 ';
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
        string query='SELECT name,Delivery_Company_Name__c,Delivery_Date_Actual__c,Trucking_Company_name__c,Shipment_Status__c,Ship_From__c,(select id,Name,Product_Image_URL__c,Product_Name__c,Quantity__c,Shipment_Item_Status__c from Shipment_Line_Itmes__r) from Shipment__c where name !=null  ';
        string condition='';
        string storedQuery='';
        try{
            if(Status != '')
            {
                Status=Status.trim();
                condition =' and Shipment_Status__c LIKE '+'\'%'+Status+'%\'';
            }  
            if(orderNumber != '')
            {
                orderNumber = String.escapeSingleQuotes(orderNumber);
                orderNumber=orderNumber.trim();
                condition=condition+' and Name LIKE '+'\'%'+orderNumber+'%\'';           
            }
            if(manufacturerName != '')
            { 
                manufacturerName = String.escapeSingleQuotes(manufacturerName);
                manufacturerName=manufacturerName.trim();
                condition=condition+' and Ship_From__c LIKE '+'\'%'+manufacturerName+'%\''; 
            }
            
            storedQuery=query+condition;
            query=query+condition+' order by id limit 20 '; 
            
            system.debug('query  ' +query);
            
            list<Shipment__c> productsList=new list<Shipment__c>();
            productsList =database.query(query);
            productsJSON = JSON.serialize(productsList);
            
            if(productsJSON!='[]')
            {
                productsJSON=productsJSON+' storedQuery '+storedQuery; 
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
    
    public PageReference goToShipmentslist()
    {
        pagereference pr;  
        try
        { 
            Schema.DescribeSObjectResult objectSchemaData = Shipment__c.sObjectType.getDescribe();
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