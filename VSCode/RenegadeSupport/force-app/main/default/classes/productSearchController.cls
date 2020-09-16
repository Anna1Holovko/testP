global class productSearchController  
{
    public list<products__c> productList{set;get;}
    public list<ProductWrapper> productWrapperList{set;get;}
    
    public list<Bundle_Item__c> bundleList{set;get;}
    public string lastPayapalId{set;get;}
    public string firstPayapalId{set;get;}
    public string storedquery{set;get;}
    public boolean displayselectionPopup{set;get;}
    public list<BundleItemWrapper> ProductRelatedBundle{set;get;}
    public map<string,list<products__c>> configlist;
    public string productName {set;get;}
    
    public productSearchController()
    {
        configlist=new map<string,list<products__c>>();
        ProductRelatedBundle=new list<BundleItemWrapper>();
        productWrapperList=new list<ProductWrapper>();
        
        productList = [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where Master_Products__c=null ORDER BY Id ASC limit 20 ];
        storedquery=  'select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where Master_Products__c=null ';
        
        system.debug('productListTemp ' +productList);
        
        if(productList.size() > 0)
        {
            lastPayapalId=productList[productList.size()-1].id;
            firstPayapalId=productList[0].id; 
            
            for(products__c pro :productList)
            {
                if(pro.Products__r !=null && pro.Products__r.size() > 0)
                {
                    configlist.put(pro.id,pro.Products__r);
                }
                productWrapperList.add(new ProductWrapper(pro,configlist));
            }
        }
        system.debug('configlist ' + configlist);
    }
    
    public void showProducts()
    {
        try
        {
            system.debug('productList ' + productList);
            String productsJSON=Apexpages.currentPage().getParameters().get('productlistfromparam');
            System.debug('productsJSON : '+productsJSON);
            if(productsJSON!='[]')
            {
                system.debug('productsJSON ' +productsJSON);
                productList=new list<products__c>();
                productWrapperList=new list<ProductWrapper>();
                
                productsJSON=productsJSON.replaceAll('&quot;', '"');
                productsJSON=productsJSON.replaceAll('&amp;', '&');
                
                if(productsJSON.contains('storedQuery'))
                {
                    storedquery=productsJSON.split('storedQuery')[1];
                    productsJSON=productsJSON.split('storedQuery')[0];                        
                }
                system.debug('productsJSON ' +productsJSON);
                productList =(List<Products__c>)JSON.deserialize(productsJSON, List<Products__c>.class);    
                system.debug('deserializedproducts ' +productList);
                if(productList.size() > 0)
                {
                    lastPayapalId=productList[productList.size()-1].id;
                    firstPayapalId=productList[0].id; 
                    
                    configlist=new map<string,list<products__c>>();
                    
                    for(products__c pro :productList)
                    {
                        if(pro.Products__r !=null && pro.Products__r.size() > 0)
                        {
                            configlist.put(pro.id,pro.Products__r);
                        } 
                        productWrapperList.add(new ProductWrapper(pro,configlist));
                    }
                    
                }
                system.debug('configlist ' + configlist);
                system.debug('productWrapperList ' + productWrapperList);
            }
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception EX : '+ex.getMessage()+', Line number :  '+ex.getLineNumber()+', Cause : '+ex.getCause());
            
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
                list<products__c> productListTemp=new list<products__c>();
                
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
                    system.debug('configJSON '+ configJSON);
                    productListTemp =(List<Products__c>)JSON.deserialize(configJSON, List<Products__c>.class);    
                    system.debug('productListTemp ' +productListTemp);
                    if(productListTemp.size() > 0)
                    {
                        for(products__c pro :productListTemp)
                        {
                            if(pro.Products__r !=null && pro.Products__r.size() > 0)
                            {
                                configlist.put(pro.id,pro.Products__r);
                            } 
                        }
                    }
                }
                system.debug('configlist ' +configlist);
                ProductRelatedBundle=new list<BundleItemWrapper>();
                for(Bundle_Item__c bundletempList :bundleList)
                {
                    ProductRelatedBundle.add(new BundleItemWrapper(bundletempList,configlist));  
                }
            }
            system.debug('ProductRelatedBundle  ' +ProductRelatedBundle);
        }
        catch(exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            System.debug('Exception E: '+ex.getMessage()+', Line Number :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
    }
    
    public void closeselectionPopup()
    {
        displayselectionPopup=false;  
    }
    
    @RemoteAction
    global static string getOptions(string SoID) 
    {
        String productsJSON ;
        String configJSON='';
        string query;
        try
        {
            system.debug('SoID ' + SoID);
            
            list<Bundle_Item__c> bundelProductsList=new list<Bundle_Item__c>();
            list<Products__c> ProductsList=new list<Products__c>();
            
            if(SoID !=null )
            {
                query = 'select id,Include__c,Name,Bundle__r.name,Bundle__c,product__r.SKU__c,product__r.Product_Image_URL__c,product__r.name,Product__c,Product__r.Tier_Price_For_Bundle__c,Product__r.Special_Price_Hidden__c,Product__r.Regular_Price__c,Product__r.Sales_Price__c,Product__r.Special_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c,Sales_Price__c,Product__r.recordtype.name from Bundle_Item__c where Bundle__c =: SoID ORDER BY order__c ASC NULLS LAST' ;
            }
            list<string> proID=new list<string>();
            
            bundelProductsList=database.query(query);
            for(Bundle_Item__c bud:bundelProductsList)
            {
                if(bud.Product__r.recordtype.name=='Configurable')
                {
                    proID.add(bud.Product__c);
                }
            }
            for(products__c pro : [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r)  from Products__c where Master_Products__c=null  and recordtype.name!='Protection Plan' and id  IN: proID ])
            {
                ProductsList.add(pro);
            }
            system.debug('bundelProductsList '+bundelProductsList);
            productsJSON = JSON.serialize(bundelProductsList);
            if(ProductsList.size() > 0)
                configJSON= JSON.serialize(ProductsList);
            
            if(configJSON!='')
            {
                productsJSON=productsJSON+' configProducts '+configJSON;
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
    
    @RemoteAction
    global static string getPrevProducts(string firstPayapalval,string query) 
    {
        String productsJSON ;
        try
        {
            system.debug('firstPayapalval ' + firstPayapalval);
            system.debug('query  ' + query);
            list<Products__c> productsList=new list<Products__c>();
            list<products__c> productListTemp=new list<products__c>();
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
                        condition='and id <\''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                    }
                    else
                        condition=' where id <\''+firstPayapalval+'\' ORDER BY Id DESC limit 20 ';
                }
            }
            
            query=query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            system.debug('query+condition  ' + query);
            
            productListTemp=database.query(query);
            
            if(productListTemp.size() > 0)
            {
                
                for(integer i=productListTemp.size()-1;i>=0;i--)
                {
                    productsList.add(productListTemp[i]);
                }
                
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
    global static string getNextProducts(string lastPayapalval,string query) 
    {
        String productsJSON ;
        try
        {
            system.debug('lastPayapalval ' + lastPayapalval);
            
            list<Products__c> productsList=new list<Products__c>();
            string condition=' ';
            
            system.debug('query  ' + query);
            if(query !=null )
            {
                if(lastPayapalval==null)
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
                        condition=' and id > \''+lastPayapalval+'\'  ORDER BY Id ASC limit 20 ';
                    }
                    else
                        condition=' where id > \''+lastPayapalval+'\'  ORDER BY Id ASC limit 20 ';
                }
            }
            
            query=query+' '+condition;
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            system.debug('query+condition  ' + query);
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
    global static string searchProducts(string sku,string productName,string manufacture) 
    {        
        String productsJSON = '';
        string query = 'select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where Master_Products__c=null ';
        string condition = '';
        string storedQuery = '';
        try{
            System.debug('sku :: '+sku+', productName :: '+productName+', manufacture :: '+manufacture);
            if(sku != '')
            {
                sku = String.escapeSingleQuotes(sku);
                sku=sku.trim();
                condition =' and SKU__c LIKE '+'\'%'+sku+'%\'';
            }  
            if(productName != '')
            {
                productName = String.escapeSingleQuotes(productName);
                productName=productName.trim();
                condition=condition+' and Name LIKE '+'\'%'+productName+'%\'';           
            }
            if(manufacture != '')
            { 
                manufacture = String.escapeSingleQuotes(manufacture);
                manufacture=manufacture.trim();
                condition=condition+'and Select_Manufacturer__r.name LIKE '+'\'%'+manufacture+'%\''; 
            }
            
            storedQuery=query+condition;
            query=query+condition+' order by id limit 20 '; 
            system.debug('query  ' +query);
            list<Products__c> productsList=new list<Products__c>();
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
    
    public class ProductWrapper 
    {
        public Products__c pro{get; set;}
        public List<selectoption> configpro{get; set;}
        public string selectedoption{get;set;}
        
        public ProductWrapper(Products__c producttemp,map<string,list<products__c>> configlist) 
        {
            pro = producttemp;
            if(configlist.containsKey(producttemp.id))
            {
                configpro =new List<selectoption>();
                for(products__c pro: configlist.get(producttemp.id))
                {                       
                    configpro.add(new selectOption(pro.id,pro.name));  
                }
            }
        }
        
    }
    
    public class BundleItemWrapper 
    {
        public Bundle_Item__c bundleitem{get;set;}
        public List<selectoption> bundelpro{get;set;}
        public string selectedBundeloption{get;set;}
        
        public BundleItemWrapper(Bundle_Item__c bundleObj, map<string,list<products__c>> configlist) 
        {
            bundleitem = bundleObj;
            bundelpro = new List<selectoption>();
            if(configlist.containsKey(bundleObj.Product__c))
            { 
                for(products__c pro: configlist.get(bundleObj.Product__c))
                {                       
                    bundelpro.add(new selectOption(pro.id,pro.name));  
                }
            }
        }
    }
    
    public PageReference goToProductslist()
    {
        pagereference pr;  
        try
        { 
            Schema.DescribeSObjectResult objectSchemaData = products__c.sObjectType.getDescribe();
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