/*
*   Author : Sowdhanya Karri | Kairos Tech
*   Class  : editSalesOrderController
*   Purpose: This class is used to edit a Sales Order with transaction on different Pay types.
*/
global class editSalesOrderController 
{
    public static string lastPayapalId{set;get;}
    public static string firstPayapalId{set;get;}
    public string storedquery{set;get;}
    public decimal tax {set;get;}
    public decimal originalTotalDue {set;get;}
    public map<string, decimal> taxByZipcose {set;get;}
    
    public Promotions__c promotionObj;
    
    public boolean manualPaymentPopUp{set;get;}
    
    public map<string,SelectedProductWrapper> SoRelated;
    
    public string SOItemId;
    public string OptionsId{set;get;}
    public string OptionsName{set;get;}
    
    public Sales_Order__c SalesorderObject{set;get;}
    public Sales_Order__c SalesorderObjectController{set;get;}
    
    public set<string> manufactureList;
    
    public list<SO_Line_Items__c> rollbackSOItems;
    public Sales_Order__c rollbacksalesorder;
    
    public map<string,list<products__c>> configlist;
    
    public boolean displayPopup{set;get;}
    public boolean displayselectionPopup{set;get;}
    
    public SO_Line_Items__c protectionplanSOI{set;get;}
    public list<products__c> protectionplanList; 
    
    public string paymentType{set;get;}
    public Payment_Method__c paymentMethodVar{set;get;}
    public boolean paymentMethodExisted{set;get;}
    public Payment_Method__c paymentMethodVar1{set;get;}
    public Payment_Method__c paymentMethodVar2{set;get;}
    public Payment_Method__c paymentMethodVar4{set;get;}
    
    public boolean hasCard1{set;get;}
    public boolean hasCard2{set;get;}
    public boolean hasCard3{set;get;}
    public boolean hasCard4{set;get;}
    
    public Account AccountObject;
    public map<string,string> customerCards;
    
    public list<Payment_Method__c> paymentMethodslist;
    public list<Transaction__c> transactionsList;
    public list<task> taskList;
    
    public map<id,ProductWrapper> selectedproducts;
    
    public decimal custumpricetotal;
    public map<string,decimal> customPriceMap; 
    Sales_Order__c salesordernotify;
    
    public list<BundleItemWrapper> SoRelatedBundle;
    public map<string,insertProductsWrapper> insertedproductsIds;
    public map<string,list<Bundle_Item__c>>  ProductRelatedBundleTempList {set;get;}
    public map<string,list<BundleItemWrapper>>  ProductRelatedBundle;
    public map<id,map<id,BundleItemWrapper>> BundleList;
    public map<string,ProductWrapper> productWrapperList{set;get;}
    public list<products__c> productList{set;get;}
    
    public  map<string,Tax_Percentage__c> stateTaxPercentage;
    public List<selectoption> stateList {set;get;} 
    
    public Boolean isBundleItemexist {set;get;}
    public string SOID{set;get;}
    
    public editSalesOrderController(ApexPages.StandardController controller)
    {
        isBundleItemexist = true;
        stateTaxPercentage = Tax_Percentage__c.getall();
        customPriceMap = new map<string,decimal>();
        
        stateList = new List<selectoption>();
        
        for(States__c stateValue : States__c.getall().values())
        {
            stateList.add(new selectOption(stateValue.name,stateValue.name));
        }
        
        stateList.sort();
        
        OptionsName='';
        paymentMethodslist = new list<Payment_Method__c>();
        transactionsList=new list<Transaction__c>();
        taskList =new  list<task>(); 
        AccountObject = new Account();
        customerCards = new map<string,string>();
        
        protectionplanSOI = new SO_Line_Items__c();
        protectionplanList = new list<products__c>();
        
        list<Payment_Method__c> existedPMs = [select id, Card_Type__c, Amount__c, Credit_Card_Number__c, Card_Verification_Number__c, Expiration_Month__c, Expiration_Year__c, Check_Type__c,
        									  Name_on_Account__c, Routing_Number__c, Account_Number__c, Encrypted_Card_Number__c, Payment_Profile_ID__c
        									  from Payment_Method__c where id in (select Payment_Method__c from Transaction__c where Sales_Order__c = :apexpages.currentpage().getparameters().get('id')
        									  and Transaction_Type__c = 'AUTH_ONLY' and (Payment_Type__c = 'Credit Card') and AVS_Response__c = 'Y')];
        if (existedPMs.size() > 0){
        	paymentMethodVar4 = existedPMs[0];
        	paymentMethodExisted = true;
        	//paymentType = 'CreditCard';
        	//hasCard4 = true;
        }
        else {
        	paymentMethodVar4 = new Payment_Method__c();
        	hasCard4 = false;
        }
        paymentMethodVar = new Payment_Method__c();
        paymentMethodVar1 = new Payment_Method__c();
        paymentMethodVar2 = new Payment_Method__c();
        hasCard1 = false;
        hasCard2 = false;
        hasCard3 = false;
        manualPaymentPopUp=false;
        
        SalesorderObject=new Sales_Order__c();
        SalesorderObjectController=new Sales_Order__c();
        salesordernotify=new Sales_Order__c();
        
        List<String> fieldNames=new List<String>();
        
        Map<String, Schema.SObjectField> maptt = Schema.SObjectType.Sales_Order__c.fields.getMap();
        for(String fieldName : maptt.keySet()) 
        {
            if(maptt.get(fieldName).getDescribe().isUpdateable()) 
            {
                fieldNames.add(fieldName); 
            }
        }
        if (!Test.isRunningTest()) { 
            controller.addFields(fieldNames);
        }
        SalesorderObjectController = (Sales_Order__c)controller.getrecord();
        system.debug('SalesorderObjectController ' + SalesorderObjectController);
        SalesorderObject.id = apexpages.currentpage().getparameters().get('id'); 
        system.debug('SalesorderObject ' + SalesorderObject.id);
        SOID = SalesorderObject.id;
        
        insertedproductsIds = new map<string,insertProductsWrapper>();
        ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        ProductRelatedBundle = new map<string,list<BundleItemWrapper>>();
        productWrapperList=new map<string,ProductWrapper>();
        BundleList = new map<id,map<id,BundleItemWrapper>>();
        selectedproducts = new map<id,ProductWrapper>();
        configlist = new map<string,list<products__c>>();
        manufactureList = new set<string>();
        try
        {
            if(SalesorderObject.id != null)
            {
                SalesorderObject = salesOrderList(SalesorderObject.id);
                originalTotalDue = SalesorderObject.Total_Due__c;
                SalesorderObject.Notify_Customer_with_Email__c = false;
                SalesorderObjectController.Notify_Customer_with_Email__c = true;
                SalesorderObjectController.Comments__c = SalesorderObject.Comments__c;
                SalesorderObjectController.Customer_Comments__c = SalesorderObject.Customer_Comments__c;
            }   
            
            storeRollBackPoint();
            
            list<string> PRodIds=new list<string>();
            
            for(SO_Line_Items__c soItem: SalesorderObject.SO_Line_Items__r)
            {
                PRodIds.add(soItem.Products__c);
            }
            
            productList = [select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c, Special_Tier_Price_Start_Date__c, 
                           Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,Total_Items_in_Bundle__c,
                           (select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,
                            Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,
                            Master_Products__c from Products__r),
                           (select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c,
                            Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c='Enabled' ORDER BY Order__c ASC NULLS LAST) from Products__c where Status__c='Enabled' and 
                           (Master_Products__c=null and recordtype.name!='Protection Plan') ORDER BY Id ASC limit 20 ];
            storedquery = 'select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,Total_Items_in_Bundle__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c from Products__r),(select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c ,Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c=\'Enabled\' ORDER BY Order__c ASC NULLS LAST) from Products__c where Status__c=\'Enabled\' and (Master_Products__c=null and recordtype.name!=\'Protection Plan\') ';
            
            protectionplanList = [select id,Name,SKU__c,Product_Image_URL__c,recordtype.name,Regular_Price__c,Sales_Price__c,
                                  Protection_high_range__c,Protection_low_range__c from Products__c where Status__c='Enabled' and 
                                  recordtype.name='Protection Plan'];
            
            system.debug('productList ' +productList);
                        
            productList = [select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,
                           Regular_Price__c,Special_Price_Hidden__c,Total_Items_in_Bundle__c,Select_Manufacturer__r.name,
                           Product_Image_URL__c,recordtypeid,Name,SKU__c, Special_Tier_Price_Start_Date__c, 
                           (select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,
                            Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,
                            Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),
                           (select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,
                            Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c , Bundle__r.Special_Tier_Price_For_Bundle__c, Bundle__r.Special_Tier_Price_Start_Date__c, Bundle__r.Special_Tier_Price_End_Date__c,
                            Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c='Enabled'  order by Order__c ASC NULLS LAST) from Products__c where Status__c='Enabled' and (Master_Products__c=null and  recordtype.name!='Protection Plan') and id not in :PRodIds ORDER BY Id ASC limit 20 ];            
            /* */
           getproducts();
           //getSoRelatedBundle();
            
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public static Sales_Order__c salesOrderList(id soId)
    {
        return [select id, Authdotnetoldaccount__c, SF_Order_Modified__c,Comments__c,Customer_Comments__c,name,email__c,Customer_Billing_Address__c,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c,Billing_Phone__c,Mobile__c,
                Customer_shipping_Address__c,Ship_to__c,Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_ZipCode__c,Shipping_Phone__c,Shipping_Mobile__c,
                IsSoModified__c,Notify_Customer_with_Email__c,Customer_Name__c,Grand_Total__c,Order_ETA__c,Delivery_Companies_Distance__c, DiscountAmount__c, Do_not_charge_tax__c,
                Discount_Amount_Total__c,TaxAmount__c,Shipping_Handle__c,Promotion__c,Sub_Total__c,Customer_Name__r.name,Discount_AmountTotal__c, Total_Due__c, Total_Paid__c, 
                (select id,Products__c ,Product_Name__c from SO_Line_Items__r WHERE Products__r.recordtype.name!='Bundled' ) from Sales_Order__c where id =:soId];  
    }
    
    public void isSOModified() 
    {
        if(SalesorderObject.id != null) 
        {
            SalesorderObject.SF_Order_Modified__c = false;
            update SalesorderObject;
        }
    }
   
    public void getproducts()
    {
        try
        {
            system.debug('productList ' +productList);
            
            if(productList.size() > 0)
            {
                lastPayapalId = productList[productList.size()-1].id;
                firstPayapalId = productList[0].id; 
                
                list<string> proID = new list<string>();
                
                for(products__c pro : productList)
                {
                    for(Bundle_Item__c bundletempList :pro.Bundle_Items1__r)
                    {
                        if(bundletempList.Product__r.recordtype.name == 'Configurable')
                        {
                            proID.add(bundletempList.Product__c);
                        } 
                    }
                }
                if(proID.size()>0)
                {
                    /*for(products__c pro : [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,
                                           Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,
                                           (select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,
                                            Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,
                                            Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where Master_Products__c=null and recordtype.name!='Protection Plan' and id IN: proID ])
                    {
                        if(!configlist.containsKey(pro.id))
                            configlist.put(pro.id,pro.Products__r);
                    }*/
                    
                    
	                list<Configurable_Item__c> cis = [select Configurable_Product__c, Product__c
	                							      from Configurable_Item__c  where Configurable_Product__c in :proID];
	                
	                list<string> productIds = new list<string>();
	                for (Configurable_Item__c ci : cis){
	                	productIds.add(ci.Product__c);
	                }
	                map<id, Products__c> productMap = new map<id, Products__c>([select Product_Image_URL__c, Special_Price_Hidden__c , Tier_Price_For_Bundle__c, 
	                								  Name , SKU__c, Regular_Price__c, Sales_Price__c, Special_Price__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c,
	                								  Image__c, Special_Price_From_Date__c, Special_Price_To_Date__c, Master_Products__c from Products__c where id in :productIds]);
	                for (Configurable_Item__c ci : cis){
		            	if (productMap.containskey(ci.Product__c) && productMap.get(ci.Product__c) != null){
		                	if(!configlist.containsKey(ci.Configurable_Product__c)){
		                		configlist.put(ci.Configurable_Product__c, new list<Products__c>());
		                	}
		                	configlist.get(ci.Configurable_Product__c).add(productMap.get(ci.Product__c));
		            	}
	                }
	                system.debug('configlist = '+ configlist);
                    
                    
                    
                    
                }
                for(products__c pro : productList)
                {
                    System.debug('configlist : '+configlist);
                    System.debug('selectedproducts : '+selectedproducts);
                    if(configlist.containsKey(pro.id) && configlist.get(pro.id).size() > 0) {
                        if(selectedproducts.containsKey(pro.id))
                        {
                            productWrapperList.put(pro.id,new ProductWrapper(pro,configlist,true,selectedproducts.get(pro.id).selectedoption,selectedproducts.get(pro.id).quantity));
                            system.debug('productWrapperList ' + productWrapperList);
                        }
                        else
                        {
                            productWrapperList.put(pro.id,new ProductWrapper(pro,configlist,false,null,'0'));
                            system.debug('productWrapperList ' + productWrapperList);
                        } 
                    } 
                    else {
                        if(selectedproducts.containsKey(pro.id))
                        {
                            productWrapperList.put(pro.id,new ProductWrapper(pro,new map<string,list<products__c>>(),true,selectedproducts.get(pro.id).selectedoption,selectedproducts.get(pro.id).quantity));
                            system.debug('productWrapperList ' + productWrapperList);
                        }
                        else
                        {
                            productWrapperList.put(pro.id,new ProductWrapper(pro,new map<string,list<products__c>>(),false,null,'0'));
                            system.debug('productWrapperList ' + productWrapperList);
                        } 
                    }
                    
                    if(pro.Bundle_Items1__r.size() > 0)
                    {
                        if(!ProductRelatedBundleTempList.containsKey(pro.id))
                            ProductRelatedBundleTempList.put(pro.id,pro.Bundle_Items1__r); 
                    }
                }
            }
            system.debug('configlist ' + configlist);
            system.debug('productWrapperList ' + productWrapperList);
            system.debug('ProductRelatedBundleTempList ' + ProductRelatedBundleTempList);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void storeRollBackPoint()
    {
        system.debug('storeRollBackPoint Method');
        rollbackSOItems = new list<SO_Line_Items__c>();
        try 
        {
            rollbacksalesorder = new Sales_Order__c();
            rollbacksalesorder=SalesorderObjectController;
            system.debug('rollbacksalesorder ' + rollbacksalesorder);
            rollbacksalesorder.id = SalesorderObject.id;
            rollbacksalesorder.Order_ETA__c = SalesorderObject.Order_ETA__c;
            rollbacksalesorder.Delivery_Companies_Distance__c = SalesorderObject.Delivery_Companies_Distance__c;
            rollbacksalesorder.Promotion__c = SalesorderObject.Promotion__c;
            rollbacksalesorder.SF_Order_Modified__c = SalesorderObject.SF_Order_Modified__c;
            rollbacksalesorder.Ship_to__c=SalesorderObject.Ship_to__c;
            rollbacksalesorder.Bill_To__c=SalesorderObject.Bill_To__c;
            rollbacksalesorder=SalesorderObjectController;
            //rollbacksalesorder.Protection_Plan_included__c = SalesorderObject.Protection_Plan_included__c;
            
            for(SO_Line_Items__c MainSOitems : [select id,IncludeInPricing__c,Product_Record_Type__c,Custom_Price__c,Custom_Price_For_Credit_Memo__c,TaxAmount__c,Sub_Total__c,Price__c,Price_For_Credit_Memo__c,ProductImageUrl__c,name,Products__c,Manufacturer__c,OriginalPrice__c,Product_Brand__c, FedExable__c, Last_status_before_cancel__c,
                                               Promotion_Brand__c,Quantity__c,DiscountAmount__c,DiscountAmount_For_Credit_Memo__c,Row_Total__c,Quantity_Invoiced__c, Quantity_Refunded__c, Sales_Order__c,Tax_Amount__c,Tax_Amount_For_Credit_Memo__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c, (select id, SO_Line_Item__c from PO_Line_Items__r) from SO_Line_Items__c where Sales_Order__c =: SalesorderObject.id])
            {
                if(MainSOitems.Custom_Price__c != null)
                {
                   customPriceMap.put(MainSOitems.id, MainSOitems.Custom_Price__c); 
                }
                
                MainSOitems.id = null;
                if(MainSOitems.Product_Record_Type__c == 'Protection Plan') {
                    rollbacksalesorder.Protection_Plan_included__c = true;
                }
                rollbackSOItems.add(MainSOitems);
            }
            
            
            
            system.debug('storeRollBackPoint Method End');
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public map<string,SelectedProductWrapper> getSoRelated()
    {
        system.debug('Selected Products Method');
        SoRelated = new map<string,SelectedProductWrapper>();
        
        try
        {
            if(SalesorderObject.id != null)
            {
                Set<Id> configIds = new Set<Id>();
                list<SO_Line_Items__c> MainSOitems = [select id,FedExable__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Custom_Price__c,Custom_Price_For_Credit_Memo__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,Price_For_Credit_Memo__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Products__r.Select_Manufacturer__c,
                                                      Promotion_Brand__c,Quantity__c,DiscountAmount__c,DiscountAmount_For_Credit_Memo__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Amount_For_Credit_Memo__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c,Last_status_before_cancel__c from SO_Line_Items__c where Bundle_Item__c=null and Sales_Order__c =: SalesorderObject.id order by Bundle_Item__r.Order__c];
                
                list<SO_Line_Items__c> BundelSOitems = [select id,FedExable__c,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Product_Record_Type__c,Custom_Price__c,Custom_Price_For_Credit_Memo__c,TaxAmount__c,Sub_Total__c,Price__c,Price_For_Credit_Memo__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                                                        Promotion_Brand__c,Quantity__c,DiscountAmount__c,DiscountAmount_For_Credit_Memo__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Amount_For_Credit_Memo__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c,Last_status_before_cancel__c from SO_Line_Items__c where Bundle_Item__c!=null and Sales_Order__c =: SalesorderObject.id order by Bundle_Item__r.Order__c];
                
                for(SO_Line_Items__c SoiItem : MainSOitems) {
	                system.debug('SoiItem.Products__r.recordtype.name = '+ SoiItem.Products__r.recordtype.name);
	                system.debug('SoiItem.Products__r.id = '+ SoiItem.Products__r.id);
                    if(SoiItem.Products__r.recordtype.name == 'Configurable') {
                        configIds.add(SoiItem.Products__c);
                    }
                }
                
	                system.debug('MainSOitems = '+ MainSOitems);
	                system.debug('configIds = '+ configIds);
                if(configIds.size() > 0) {
                    /*for(products__c pro : [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,
                                           Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,
                                           (select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,
                                            Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,
                                            Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where Id in :configIds]) 
                    {
                        if(!configlist.containsKey(pro.id) && pro.Products__r.size() > 0) {
                            configlist.put(pro.id,pro.Products__r);
                        }
                    }
	                }*/
	                list<Configurable_Item__c> cis = [select Configurable_Product__c, Product__c
	                							      from Configurable_Item__c  where Configurable_Product__c in :configIds and Configurable_Product__c != null and Product__c != null];
	                
	                set<string> productIds = new set<string>();
	                for (Configurable_Item__c ci : cis){
	                	productIds.add(ci.Product__c);
	                }
	                for (SO_Line_Items__c ci : BundelSOitems){
	                	productIds.add(ci.Products__c);
	                	productIds.add(ci.Bundle_Item__r.Product__c);
	                }
	                map<id, Products__c> productMap = new map<id, Products__c>([select Product_Image_URL__c, Special_Price_Hidden__c , Tier_Price_For_Bundle__c,
	                								  Name , SKU__c, Regular_Price__c, Sales_Price__c, Special_Price__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c,
	                								  Image__c, Special_Price_From_Date__c, Special_Price_To_Date__c, Master_Products__c from Products__c where id in :productIds]);
	                for (Configurable_Item__c ci : cis){
	                	if (productMap.containskey(ci.Product__c) && productMap.get(ci.Product__c) != null){
		                	if(!configlist.containsKey(ci.Configurable_Product__c)){
		                		configlist.put(ci.Configurable_Product__c, new list<Products__c>());
		                	}
		                	configlist.get(ci.Configurable_Product__c).add(productMap.get(ci.Product__c));
	                	}
	                }
	                system.debug('configlist = '+ configlist);
                
                }
                for(SO_Line_Items__c SoiItem : MainSOitems)
                {
                    if(SoiItem.Products__r.Select_Manufacturer__c != null) {
                        manufactureList.add(SoiItem.Products__r.Select_Manufacturer__r.name);
                    }
                    
                    insertedproductsIds.put(SoiItem.Products__c,new insertProductsWrapper(SoiItem.Quantity__c, SoiItem.Config_Product__c));
                    
                	system.debug('SoiItem.Products__r.recordtype.name = = '+ SoiItem.Products__r.recordtype.name == 'Bundled');
                    if(SoiItem.Products__r.recordtype.name == 'Bundled')
                    {
                        list<SO_Line_Items__c> BundelSOitemstemp = new list<SO_Line_Items__c>();
                        for(SO_Line_Items__c BundelItem: BundelSOitems) 
                        { 
                            if(SoiItem.Products__c == BundelItem.Products__c)
                            {
                                insertedproductsIds.put(BundelItem.Bundle_Item__c,new insertProductsWrapper(BundelItem.Quantity__c,BundelItem.Config_Product__c));
                                BundelSOitemstemp.add(BundelItem);
                            }
                        }
                        if(BundelSOitemstemp.size() > 0)
                        {
                            SoRelated.put(SoiItem.id,new SelectedProductWrapper(SoiItem,BundelSOitemstemp,new list<selectoption>()));
                        }
                        else
                        {         
                            SoRelated.put(SoiItem.id,new SelectedProductWrapper(SoiItem,new list<SO_Line_Items__c>(),new list<selectoption>()));
                        }
                    }
                    else
                    {
                        if(SoiItem.Config_Product__c != null)
                        {
                            List<selectoption> configpro = new List<selectoption>();
                            system.debug('Config_Product__c = '+ SoiItem.Config_Product__c);
                            system.debug('configlist = '+ configlist.keySet());
                            
                            if(configlist.containsKey(SoiItem.Products__c)) {
                                for(products__c pro: configlist.get(SoiItem.Products__c))
                                {                       
                                    configpro.add(new selectOption(pro.id,pro.name));   
                                }
                                SoRelated.put(SoiItem.id,new SelectedProductWrapper(SoiItem,new list<SO_Line_Items__c>(),configpro));
                            }
                        }
                        else
                            SoRelated.put(SoiItem.id,new SelectedProductWrapper(SoiItem,new list<SO_Line_Items__c>(),new list<selectoption>()));
                        if(SoiItem.Products__r.recordtype.name == 'Protection Plan')
                            protectionplanSOI=SoiItem;
                    } 
                } 
                showProtectionPlan();
            }
            System.debug('insertedproductsIds :: '+insertedproductsIds);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        
        system.debug('SoRelated ' + SoRelated);
        
        system.debug('Selected Products Method End');

        return SoRelated;
    }
    
    public list<BundleItemWrapper> getSoRelatedBundle()
    {
        SoRelatedBundle = new list<BundleItemWrapper>();  
        
        system.debug('OptionsId :  '+OptionsId );
        system.debug('configlist :  '+configlist );
        system.debug('ProductRelatedBundleTempList Key Contains :  '+ProductRelatedBundleTempList.containsKey(OptionsId));
        try {
        	if (!ProductRelatedBundleTempList.containsKey(OptionsId)){
        		
            productList = [select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,
                           Regular_Price__c,Special_Price_Hidden__c,Total_Items_in_Bundle__c,Select_Manufacturer__r.name,
                           Product_Image_URL__c,recordtypeid,Name,SKU__c, Special_Tier_Price_Start_Date__c, 
                           (select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,
                            Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,
                            Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),
                           (select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,
                            Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c , Bundle__r.Special_Tier_Price_For_Bundle__c, Bundle__r.Special_Tier_Price_Start_Date__c, Bundle__r.Special_Tier_Price_End_Date__c,
                            Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c='Enabled'  order by Order__c ASC NULLS LAST) from Products__c where Status__c='Enabled' and id = :OptionsId ]; 
                            getproducts();
        	}
            if(ProductRelatedBundleTempList.containsKey(OptionsId)) {
                for(Bundle_Item__c bundletempList : ProductRelatedBundleTempList.get(OptionsId))
                {
                    if(insertedproductsIds.containsKey(bundletempList.id))
                    {
                        SoRelatedBundle.add(new BundleItemWrapper(bundletempList,configlist,true,insertedproductsIds.get(bundletempList.id).quantity,insertedproductsIds.get(bundletempList.id).selectedConfigProduct));
                    } 
                    else
                    {
                        SoRelatedBundle.add(new BundleItemWrapper(bundletempList,configlist,bundletempList.Include__c,'0',null));
                    } 
                }
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Bundle Item products available.'));
            }
            system.debug('SoRelatedBundle :  '+SoRelatedBundle );
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return SoRelatedBundle;
    }
    
    public map<string,list<BundleItemWrapper>> getProductRelatedBundle()
    {
        ProductRelatedBundle = new map<string,list<BundleItemWrapper>>();
        list<BundleItemWrapper> ProductRelatedBundleTemp = new list<BundleItemWrapper>();
        try {
           System.debug('OptionsId :: '+OptionsId);
            System.debug('ProductRelatedBundleTempList containsKey :: '+ProductRelatedBundleTempList.containsKey(OptionsId));
            if(OptionsId != null) {
                if(ProductRelatedBundleTempList.containsKey(OptionsId)) {
                    for(Bundle_Item__c bundletempList : ProductRelatedBundleTempList.get(OptionsId))
                    {
                        if(BundleList.containsKey(bundletempList.Bundle__c))
                        {
                            if(BundleList.get(bundletempList.Bundle__c).containsKey(bundletempList.id))
                            {  
                                ProductRelatedBundleTemp.add(new BundleItemWrapper(bundletempList,configlist,true,BundleList.get(bundletempList.Bundle__c).get(bundletempList.id).quantity,BundleList.get(OptionsId).get(bundletempList.id).selectedBundeloption));
                            }
                            else
                            {
                                ProductRelatedBundleTemp.add(new BundleItemWrapper(bundletempList,configlist,bundletempList.Include__c,string.valueOf(integer.valueof(bundletempList.Selection_Qty__c)),null));  
                            }
                        } 
                        else
                        {
                            ProductRelatedBundleTemp.add(new BundleItemWrapper(bundletempList,configlist,bundletempList.Include__c,string.valueOf(integer.valueof(bundletempList.Selection_Qty__c)),null));
                        }  
                    }
                    
                    ProductRelatedBundle.put(OptionsId, ProductRelatedBundleTemp);
                    
                    map<id,BundleItemWrapper> bundle = new map<id,BundleItemWrapper>();
                    if(BundleList.containsKey(OptionsId))
                    {
                        BundleList.remove(OptionsId); 
                    }
                    
                    if(ProductRelatedBundle.containsKey(OptionsId)) {
                        for(BundleItemWrapper bundelitemsObj : ProductRelatedBundle.get(OptionsId))
                        { 
                            if(bundelitemsObj.selected==true)
                            {
                                bundle.put(bundelitemsObj.bundleitem.id,bundelitemsObj);
                            }
                        } 
                        BundleList.put(OptionsId,bundle);
                    }
                    else {
                        System.debug('isBundleItemexist :: '+isBundleItemexist);
                        ProductRelatedBundle.put(OptionsId, new list<BundleItemWrapper>());
                        // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Products Found.'));
                    }
                }
                else {
                    System.debug('isBundleItemexist :: '+isBundleItemexist);
                    ProductRelatedBundle.put(OptionsId, new list<BundleItemWrapper>());
                    //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Products Found.'));
                }
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return ProductRelatedBundle;
    }
    
    public void showProducts()
    {
        try
        {
            system.debug('productList ' + productList);
            String productsJSON = Apexpages.currentPage().getParameters().get('productlistfromparam');
            string configProductsJSON = '';
            
            if(productsJSON != '[]')
            {
                system.debug('productsJSON ' +productsJSON);
                
                productList = new list<products__c>();
                productWrapperList = new map<string,ProductWrapper>();
                
                list<products__c> productListTemp = new list<products__c>();
                
                productsJSON = productsJSON.replaceAll('&quot;', '"');
                productsJSON = productsJSON.replaceAll('&amp;', '&');
                productsJSON = productsJSON.replaceAll('&#39;', '\'');
                
                if(productsJSON.contains('configProducts'))
                {
                    configProductsJSON = productsJSON.split('configProducts')[1];
                    productsJSON = productsJSON.split('configProducts')[0]; 
                }
                
                if(productsJSON.contains('storedQuery'))
                {
                    storedquery = productsJSON.split('storedQuery')[1];
                    productsJSON = productsJSON.split('storedQuery')[0];                        
                }
                system.debug('productsJSON ' +productsJSON);
                productList = (List<Products__c>)JSON.deserialize(productsJSON, List<Products__c>.class);    
                system.debug('deserializedproducts ' +productList);
                if(productList.size() > 0)
                {
                	list<string> configIds = new list<string>();
                    lastPayapalId = productList[productList.size()-1].id;
                    firstPayapalId = productList[0].id; 
                    
                    if(configProductsJSON != '')
                    {
                        productListTemp = (List<Products__c>)JSON.deserialize(configProductsJSON, List<Products__c>.class);    
                        system.debug('productListTemp ' +productListTemp);
                        if(productListTemp.size() > 0)
                        {
                            for(products__c pro :productListTemp)
                            {
                            	configIds.add(pro.id);
                            }
                        }
                        
                    }
                    
                    System.debug('configlist : '+configlist);
                    for(products__c pro : productList)
                    {
                        if(!configlist.containsKey(pro.id))
                        {
                            configIds.add(pro.id);
                        }   
                    }
                        
                    list<Bundle_Item__c> bundleItems = [select Product__c from Bundle_Item__c where Bundle__c in :configIds];   
                    list<string> bundleItemIds = new list<string>();
                    for (Bundle_Item__c bi : bundleItems){
                    	bundleItemIds.add(bi.Product__c);
                    }
	                list<Configurable_Item__c> cis = [select Configurable_Product__c, Product__c
	                							      from Configurable_Item__c  where (Configurable_Product__c in :configIds or Configurable_Product__c in :bundleItemIds) and Configurable_Product__c != null and Product__c != null];
	                
	                list<string> productIds = new list<string>();
	                for (Configurable_Item__c ci : cis){
	                	productIds.add(ci.Product__c);
	                }
	                map<id, Products__c> productMap = new map<id, Products__c>([select Product_Image_URL__c, Special_Price_Hidden__c , Tier_Price_For_Bundle__c,
	                								  Name , SKU__c, Regular_Price__c, Sales_Price__c, Special_Price__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c,
	                								  Image__c, Special_Price_From_Date__c, Special_Price_To_Date__c, Master_Products__c from Products__c where id in :productIds]);
	                for (Configurable_Item__c ci : cis){
	                	if (productMap.containskey(ci.Product__c) && productMap.get(ci.Product__c) != null){
		                	if(!configlist.containsKey(ci.Configurable_Product__c)){
		                		configlist.put(ci.Configurable_Product__c, new list<Products__c>());
		                	}
		                	configlist.get(ci.Configurable_Product__c).add(productMap.get(ci.Product__c));
	                	}
	                }
	                system.debug('configlist = '+ configlist);
                    for(products__c pro : productList)
                    {
		                
		                
                        System.debug('configlist : '+configlist);
                        System.debug('selectedproducts : '+selectedproducts);
                        if(configlist.containsKey(pro.id) && configlist.get(pro.id).size() > 0) {
                            if(selectedproducts.containsKey(pro.id))
                            {
                                productWrapperList.put(pro.id,new ProductWrapper(pro,configlist,true,selectedproducts.get(pro.id).selectedoption,selectedproducts.get(pro.id).quantity));
                                system.debug('productWrapperList ' + productWrapperList);
                            }
                            else
                            {
                                productWrapperList.put(pro.id,new ProductWrapper(pro,configlist,false,null,'0'));
                                system.debug('productWrapperList ' + productWrapperList);
                            } 
                        } 
                        else {
                            if(selectedproducts.containsKey(pro.id))
                            {
                                productWrapperList.put(pro.id,new ProductWrapper(pro,new map<string,list<products__c>>(),true,selectedproducts.get(pro.id).selectedoption,selectedproducts.get(pro.id).quantity));
                                system.debug('productWrapperList ' + productWrapperList);
                            }
                            else
                            {
                                productWrapperList.put(pro.id,new ProductWrapper(pro,new map<string,list<products__c>>(),false,null,'0'));
                                system.debug('productWrapperList ' + productWrapperList);
                            } 
                        }
                        
                        if(pro.Bundle_Items1__r.size()>0)
                        {
                            if(!ProductRelatedBundleTempList.containsKey(pro.id))
                                ProductRelatedBundleTempList.put(pro.id,pro.Bundle_Items1__r); 
                        }
                    }
                }
                system.debug('configlist ' + configlist);
                system.debug('productWrapperList ' + productWrapperList);
                system.debug('ProductRelatedBundleTempList ' + ProductRelatedBundleTempList);
            }
            else
            {
                productWrapperList = new map<string,ProductWrapper>();
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void updateProduct()
    {
        list<SO_Line_Items__c> updateList = new list<SO_Line_Items__c>();
        list<SO_Line_Items__c> insertList = new list<SO_Line_Items__c>();
        Savepoint sp = database.setsavepoint();
        try
        {
            for(SelectedProductWrapper soItems : SoRelated.values())
            {
	            if (string.valueof(soItems.soi.Custom_Price__c) == '0'){
	            	soItems.soi.Custom_Price__c = null;
	            }
                updateList.add(soItems.soi);
            }
            
            if(updateList.size() > 0)
            {
                system.debug('updateList ' + updateList);
               /* if(SalesorderObject.Promotion__c != null)
                {
                    SalesorderObject.Promotion__c = null;
                    update SalesorderObject;  
                }*/
                update updateList; 
            } 
            System.debug('selectedproducts :: '+selectedproducts.values());
            System.debug('insertedproductsIds :: '+insertedproductsIds);
            System.debug('BundleList :: '+BundleList);
            System.debug('SalesorderObject :: '+SalesorderObject);
            System.debug('SalesorderObject.Do_not_charge_tax__c :: '+SalesorderObject.Do_not_charge_tax__c);
            if (SalesorderObject.Shipping_ZipCode__c != null){
            	list<Shipping_Zip_Codes__c> zipCodes = [select TaxJar_Sales_Tax__c, Zip_Code__c from Shipping_Zip_Codes__c where TaxJar_Sales_Tax__c != 0 and Zip_Code__c = :SalesorderObject.Shipping_ZipCode__c];
            	if (zipCodes.size() > 0 && zipCodes[0].TaxJar_Sales_Tax__c != null){
		            tax = zipCodes[0].TaxJar_Sales_Tax__c;
            	}
	            else{
	            	tax = 0;
	            }
            }
            else{
            	tax = 0;
            }
            System.debug('tax :: '+tax);
            for(ProductWrapper proObj : selectedproducts.values())
            {           
                System.debug('insertedproductsIds contains:: '+insertedproductsIds.containsKey(proObj.pro.id));
                if(!insertedproductsIds.containsKey(proObj.pro.id))
                {
                    System.debug('BundleList contains:: '+BundleList.containsKey(proObj.pro.id));
                    if(BundleList.containsKey(proObj.pro.id))
                    {
                        for(BundleItemWrapper bundelitemsObj : BundleList.get(proObj.pro.id).values())
                        {
                            System.debug('**********Bundle Products**********');
                            SO_Line_Items__c SOI=new SO_Line_Items__c();
                            SOI.Sales_Order__c=SalesorderObject.id;
                            if(bundelitemsObj.quantity!='0')
                                SOI.Quantity__c=integer.valueof(bundelitemsObj.quantity);
                            else
                                SOI.Quantity__c=1;
                            SOI.Products__c=bundelitemsObj.bundleitem.Bundle__c;
                            SOI.Product_Name__c=bundelitemsObj.bundleitem.Bundle_Product_Name__c;
                            SOI.ProductSKU__c=bundelitemsObj.bundleitem.SKU__c;
                            SOI.Product_Url__c=bundelitemsObj.bundleitem.ImageURL__c;
                            SOI.Bundle_Item__c=bundelitemsObj.bundleitem.id;
                            SOI.Config_Product__c=bundelitemsObj.selectedBundeloption;
		            		SOI.Tax_Percent__c = tax;
                    		SOI.Custom_Price__c = null;
                    		if (bundelitemsObj.bundleitem.Bundle__r.Special_Tier_Price_Start_Date__c <=  system.today() && bundelitemsObj.bundleitem.Bundle__r.Special_Tier_Price_End_Date__c >=  system.today()){
                    			SOI.Custom_Price__c = bundelitemsObj.bundleitem.Bundle__r.Special_Tier_Price_For_Bundle__c;
                    		}
                    		SOI.Price__c = null;
                            insertList.add(SOI);
                        }
                    }
                    System.debug('**********Simple/Config Products**********');
                    SO_Line_Items__c SOI = new SO_Line_Items__c();
                    SOI.Sales_Order__c=SalesorderObject.id;
                    SOI.Custom_Price__c = null;
                    SOI.Price__c = null;
                    if(proObj.quantity != '0')
                        SOI.Quantity__c=integer.valueof(proObj.quantity);
                    else
                        SOI.Quantity__c=1;
                    SOI.Products__c=proObj.pro.id;
                    SOI.Product_Name__c=proObj.pro.name;
                    SOI.ProductSKU__c=proObj.pro.SKU__c;
                    SOI.Product_Url__c=proObj.pro.Product_Image_URL__c;
                    SOI.Config_Product__c=proObj.selectedoption;
                    SOI.IncludeInPricing__c=true;
		            SOI.Tax_Percent__c = tax;
                    insertList.add(SOI);
                    if(selectedproducts.containsKey(proObj.pro.id))
                        selectedproducts.remove(proObj.pro.id);
                    if(BundleList.containsKey(proObj.pro.id))
                        BundleList.remove(proObj.pro.id);
                    if(productWrapperList.containsKey(proObj.pro.id))
                        productWrapperList.remove(proObj.pro.id);
                }           
            }
            System.debug('insertList :: '+insertList);
            if(insertList.size() > 0)
            {
            	
                for (SO_Line_Items__c pw : insertList){
                	system.debug('pw.Product_Name__c = ' + pw.Product_Name__c);
			        if (pw.Product_Name__c.contains('Protection Plan')){
			        	SalesorderObject.Protection_Plan_included__c = true;
			        	break;
			        }
			        SalesorderObject.Protection_Plan_included__c = false;
                }
                /*if(SalesorderObject.Promotion__c != null)
                {
                    SalesorderObject.Promotion__c = null;
                }*/
                update SalesorderObject;  
                system.debug('insertList ' + insertList);
                insert insertList;
            }
            System.debug('insertList :: '+insertList);
            System.debug('updateList :: '+updateList);
            if(updateList.size() > 0 || insertList.size() > 0)
            { 
                
                list<string> SO_Ids = new list<string>();
                SO_Ids.add(SalesorderObject.id);
                
                newPriceCalculation pc = new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null);
                pc.updatecalculation(SO_Ids); 
                
                SalesorderObject = salesOrderList(SalesorderObject.id);  
                
                showProtectionPlan();
                system.debug('protectionplanSOI ' + protectionplanSOI);
                if(protectionplanSOI != null && protectionplanSOI.id != null)
                {
                    update protectionplanSOI;
                }
                
                pc=new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null); 
                pc.updatecalculation(SO_Ids);
            }
            
            SalesorderObject = salesOrderList(SalesorderObject.id);
            for (SO_Line_Items__c pw : SalesorderObject.SO_Line_Items__r){
            	system.debug('pw.Product_Name__c = ' + pw.Product_Name__c);
		        if (pw.Product_Name__c.contains('Protection Plan')){
		        	SalesorderObject.Protection_Plan_included__c = true;
		        	break;
		        }
		        SalesorderObject.Protection_Plan_included__c = false;
            }
            update SalesorderObject;
            if (paymentMethodVar4 != null && paymentMethodVar4.Amount__c != null && paymentMethodVar4.Amount__c != 0){
            	paymentMethodVar4.Amount__c = SalesorderObject.Grand_Total__c;
            }
            
        }
        catch(exception ex)
        {
        	system.debug(ex.getmessage() + ' ' + ex.getlinenumber());
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable')); 
        }
        getSoRelated();
        updatePromocode();
    }
    
    
    public void updateOpp(){
    	 update SalesorderObject;
    	 SalesorderObject = salesOrderList(SalesorderObject.id);
    }
    
    
    public void AddProtectionPlan()
    {
        try
        {
            if(protectionplanSOI != null)
            {
                map<string,Tax_Percentage__c> stateTaxPercentage = Tax_Percentage__c.getall();
                SalesorderObject.Protection_Plan_included__c = true;
                update SalesorderObject;
                
                protectionplanSOI.Quantity__c = 1;
                /*
                if(stateTaxPercentage.get(SalesorderObject.Shipping_State__c) != null)
                {
                    protectionplanSOI.Tax_Percent__c = stateTaxPercentage.get(SalesorderObject.Shipping_State__c).Percentage__c;
                }
                else if(stateTaxPercentage.get(SalesorderObject.Shipping_City__c) != null)
                {
                    protectionplanSOI.Tax_Percent__c = stateTaxPercentage.get(SalesorderObject.Shipping_City__c).Percentage__c ;
                }
                else
                {
                    protectionplanSOI.Tax_Percent__c = 0; 
                } */
                insert protectionplanSOI;
                
                if(SalesorderObject.Promotion__c != null)
                {
                    if(promotionObj != null && promotionObj.Type__c != 'Brand' )
                    {
                        SalesorderObject.Promotion__c=null;
                        update  SalesorderObject;      
                    }
                    newPriceCalculation pc = new newPriceCalculation();                    
                    list<string> SO_Ids = new list<string>();
                    SO_Ids.add(SalesorderObject.id);
                    pc.updatecalculation(SO_Ids); 
                    pc.calculation(SO_Ids,'Rejected',null,null);
                }
                SalesorderObject = salesOrderList(SalesorderObject.id);
            }
        }
        catch(Exception e)
        {
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    } 
    
    public void addProduct()
    {
        system.debug('productID  '+apexpages.currentpage().getparameters().get('productID'));
        system.debug('OptionsId  '+OptionsId);
        system.debug('selectedproducts  '+selectedproducts);
        system.debug('productWrapperList  '+productWrapperList);
        string productID = apexpages.currentpage().getparameters().get('productID');
        try{
            if(selectedproducts.containsKey(productID) && productWrapperList.get(productID).selected == false)
            {
                selectedproducts.remove(productID);
                if(BundleList.containsKey(OptionsId))
                {
                    BundleList.remove(OptionsId); 
                }
                displayselectionPopup=false;
                productWrapperList.get(productID).quantity='0';
            }
            else if(productWrapperList.containsKey(productID) && productWrapperList.get(productID).selected == true)
            {
                if(productWrapperList.get(productID).pro.recordtype.name == 'Configurable' && productWrapperList.get(productID).selectedoption == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Config Product.'));
                    productWrapperList.get(productID).selected = false;
                }
                else if(productWrapperList.get(productID).pro.recordtype.name == 'Bundled' && productWrapperList.get(productID).pro.Total_Items_in_Bundle__c == 0) {
                    isBundleItemexist = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Products Found.'));
                }
                else
                {
                    isBundleItemexist = true;
                    if(productWrapperList.get(productID).quantity=='0')
                        productWrapperList.get(productID).quantity='1';
                    selectedproducts.put(productID,productWrapperList.get(productID));
                    system.debug('productWrapperList[productID].quantity ' + productWrapperList.get(productID).quantity);
                }  
                
                system.debug('selectedproducts '+selectedproducts);
            }
            
        }
        catch(Exception e)
        {
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
        }
    }
    
    public void addBundleProduct()
    {
        system.debug('addBundleProduct Method');
        
        map<id,BundleItemWrapper> bundle = new map<id,BundleItemWrapper>();
        try {
            if(BundleList.containsKey(OptionsId))
            {
                BundleList.remove(OptionsId); 
            }
            
            for(BundleItemWrapper bundelitemsObj : ProductRelatedBundle.get(OptionsId))
            { 
                if(bundelitemsObj.selected==true)
                {
                    if(bundelitemsObj.quantity=='0' || bundelitemsObj.quantity==null)
                        bundelitemsObj.quantity='1';
                    bundle.put(bundelitemsObj.bundleitem.id,bundelitemsObj);
                }
            } 
            
            BundleList.put(OptionsId,bundle);
            
            if(!selectedproducts.containsKey(OptionsId) && productWrapperList.get(OptionsId).selected == false )
            {
                productWrapperList.get(OptionsId).selected = true;
                
                if(productWrapperList.get(OptionsId).quantity == '0')
                {
                    productWrapperList.get(OptionsId).quantity = '1';
                }
                
                selectedproducts.put(OptionsId,productWrapperList.get(OptionsId));
                system.debug('productWrapperList[productID].quantity ' + productWrapperList.get(OptionsId).quantity);
            }
            
            system.debug('BundleList ' + BundleList);
            
            system.debug('addBundleProduct Method End');
        }
        catch(Exception e)
        {
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
        }
    }
    
    public void UpdateBundelItems()
    {
        system.debug('SOItemId '+apexpages.currentpage().getParameters().get('SOItemId'));
        system.debug('SOItemId : '+SOItemId);
        try {
            SelectedProductWrapper soitempbundel = SoRelated.get(SOItemId);        
            
            list<SO_Line_Items__c> removeList = new list<SO_Line_Items__c>();
            list<SO_Line_Items__c> updateList = new list<SO_Line_Items__c>();
            list<SO_Line_Items__c> insertList = new list<SO_Line_Items__c>();
            
            system.debug('Bundle update Method end');
            system.debug('soitempbundel  '+soitempbundel);
            system.debug('SoRelatedBundle  '+SoRelatedBundle);
            
            for(BundleItemWrapper bundelitemsObj : SoRelatedBundle)
            {
                system.debug('soitempbundel.bundelItems  '+soitempbundel.bundelItems);
                boolean existing=false;
                
                for(SO_Line_Items__c bundel : soitempbundel.bundelItems)
                {                
                    if(bundel.Bundle_Item__c==bundelitemsObj.bundleitem.id)
                    {
                        existing=true;
                        
                        system.debug('Bundle ' + bundelitemsObj);
                        if(bundelitemsObj.selected==true)
                        {
                            System.debug('Selected bundel.Config_Product__c' + bundelitemsObj.bundleitem.name);
                            bundel.Config_Product__c=bundelitemsObj.selectedBundeloption;
                            bundel.Quantity__c=integer.valueof(bundelitemsObj.quantity);
                            updateList.add(bundel);
                        }
                        else
                        {   
                            System.debug('Cancelled bundleitem.name:' + bundelitemsObj.bundleitem.name);
                            System.debug('Cancelled bundleitem.SKU__c:' + bundelitemsObj.bundleitem.SKU__c);
                        	//bundel.Item__c = 'Cancelled';
                            //updateList.add(bundel);
                            removeList.add(bundel);
                            if(insertedproductsIds.containsKey(bundel.Bundle_Item__c))
                                insertedproductsIds.remove(bundel.Bundle_Item__c);
                        }
                    }
                } 
                if(existing==false && bundelitemsObj.selected==true)
                {
                    SO_Line_Items__c SOI=new SO_Line_Items__c();
                    SOI.Sales_Order__c=SalesorderObject.id;
                    if(bundelitemsObj.quantity!='0')
                        SOI.Quantity__c=integer.valueof(bundelitemsObj.quantity);
                    else
                        SOI.Quantity__c=1;
                    SOI.Products__c=bundelitemsObj.bundleitem.Bundle__c;
                    SOI.Product_Name__c=bundelitemsObj.bundleitem.Bundle_Product_Name__c;
                    SOI.ProductSKU__c=bundelitemsObj.bundleitem.SKU__c;
                    SOI.Product_Url__c=bundelitemsObj.bundleitem.ImageURL__c;
                    SOI.Bundle_Item__c=bundelitemsObj.bundleitem.id;
                    SOI.Config_Product__c=bundelitemsObj.selectedBundeloption;
                    if (!bundelitemsObj.selected){
                    	SOI.Item__c = 'Cancelled';
                    }
                    insertList.add(SOI); 
                }
            }
            if(insertList.size() > 0)
            {
                system.debug('insertList ' + insertList);
                insert insertList; 
                //SalesorderObject.Promotion__c=null;
            }        
            
            
           

            if(updateList.size() > 0)
            {
                system.debug('updateList ' + updateList);
                update updateList; 
                //SalesorderObject.Promotion__c=null;
            }
            
             if(removeList.size() > 0)
            {
                system.debug('removeList ' + removeList);
                delete removeList; 
                //SalesorderObject.Promotion__c=null;
            }
            update SalesorderObject; 
            
            newPriceCalculation pc=new newPriceCalculation();
            list<string> SO_Ids=new list<string>();
            SO_Ids.add(SalesorderObject.id);
            pc.calculation(SO_Ids,'Rejected',null,null);
            pc.updatecalculation(SO_Ids);
            
            SalesorderObject = salesOrderList(SalesorderObject.id);
            
            showProtectionPlan();
            
            if(protectionplanSOI !=null && protectionplanSOI.id!=null)
            {                            
                SO_Ids.add(SalesorderObject.id);
                pc=new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null);
                pc.updatecalculation(SO_Ids);                    
                update protectionplanSOI;                
            }
            
            SalesorderObject = salesOrderList(SalesorderObject.id);
            displayPopup = false; 
            system.debug('Bundle update Method end');
        }
        catch(Exception e)
        {
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
        }
    }
    
    public void UnRemoveProduct(){       
    	
        list<SO_Line_Items__c> tempids = new list<SO_Line_Items__c>();
        for(string soiId: SoRelated.keyset()){
        	SO_Line_Items__c soitemp = SoRelated.get(soiId).soi;
            if(soitemp.id == apexpages.currentpage().getParameters().get('UnRemove')){
                soitemp.Item__c = soitemp.Last_status_before_cancel__c != null ? soitemp.Last_status_before_cancel__c : 'Processing';
                soitemp.Custom_Price__c = soitemp.Custom_Price_For_Credit_Memo__c;
                soitemp.DiscountAmount__c = soitemp.DiscountAmount_For_Credit_Memo__c;
                soitemp.Price__c = soitemp.Price_For_Credit_Memo__c;
                soitemp.Tax_Amount__c = soitemp.Tax_Amount_For_Credit_Memo__c;
                tempids.add(soitemp);
            }
            for(SO_Line_Items__c soitempbundel : SoRelated.get(soiId).bundelItems){
                soitempbundel.Item__c = soitempbundel.Last_status_before_cancel__c != null ? soitempbundel.Last_status_before_cancel__c : 'Processing';
                soitempbundel.Custom_Price__c = soitempbundel.Custom_Price_For_Credit_Memo__c;
                soitempbundel.DiscountAmount__c = soitempbundel.DiscountAmount_For_Credit_Memo__c;
                soitempbundel.Price__c = soitempbundel.Price_For_Credit_Memo__c;
                soitempbundel.Tax_Amount__c = soitempbundel.Tax_Amount_For_Credit_Memo__c;
                tempids.add(soitempbundel);
            }   
        }
        if (tempids.size() > 0){
        	update tempids;
        }
        SalesorderObject = salesOrderList(SalesorderObject.id);
    }
    
    public void RemoveProduct()
    {        
        try
        {            
            system.debug('apexpages.currentpage().getparameters().get(\'proItem\') :: '+ apexpages.currentpage().getParameters().get('Remove'));
            
            list<SO_Line_Items__c> tempids = new list<SO_Line_Items__c>();
            
            boolean removePromocode = false;
            boolean removeProtection = false;
            boolean checkremoveProtection;
            boolean inculdeProtectionPlan = false;
            
            for(string soiId: SoRelated.keyset())
            {
                SO_Line_Items__c soitemp = SoRelated.get(soiId).soi;
                
                if(soitemp.Product_Record_Type__c == 'Protection Plan')
                {
                    inculdeProtectionPlan=true;
                }
                if(soitemp.id == apexpages.currentpage().getParameters().get('Remove'))
                {
                    System.debug('Before insertedproductsIds remove :: '+insertedproductsIds.keySet());
                    if(insertedproductsIds.containsKey(soitemp.Products__c)) 
                    {
                        insertedproductsIds.remove(soitemp.Products__c);
                    }
                    else if(insertedproductsIds.containsKey(soitemp.Bundle_Item__c)) 
                    {
                        insertedproductsIds.remove(soitemp.Bundle_Item__c);
                    }
                    System.debug('After insertedproductsIds remove :: '+insertedproductsIds.keySet());
                    
                    manufactureList.remove(soitemp.Products__r.Select_Manufacturer__r.name);
                    soitemp.Item__c = 'Cancelled';
                    tempids.add(soitemp);
                    
                    if(soitemp.DiscountAmount__c > 0)
                    {
                        removePromocode=true;
                    }
                    if(soitemp.Product_Record_Type__c == 'Protection Plan')
                    {
                        removeProtection = true;
                        system.debug('protectionplanSOI in remove ' +protectionplanSOI);
                    }
                    for(SO_Line_Items__c soitempbundel : SoRelated.get(soiId).bundelItems)
                    {
                        manufactureList.remove(soitempbundel.Products__r.Select_Manufacturer__r.name);
                    	soitempbundel.Item__c = 'Cancelled';
                        tempids.add(soitempbundel);
                    }           
                }
            } 
            
            if(SoRelated.size() == 2 && removeProtection != true && inculdeProtectionPlan == true)
            {
                for(string soiId : SoRelated.keyset())
                {
                    SO_Line_Items__c soitemp = SoRelated.get(soiId).soi;
                    if(soitemp.id != apexpages.currentpage().getParameters().get('Remove'))
                    {
                    	soitemp.Item__c = 'Cancelled';
                        tempids.add(soitemp); 
                        removeProtection = true;
                        removePromocode = true;
                    }
                }
            }
            
            system.debug('tempids ' + tempids);
            update tempids;
            
            newPriceCalculation pc = new newPriceCalculation();
            list<string> SO_Ids = new list<string>();
            SO_Ids.add(SalesorderObject.id);
            
            if(removeProtection == true)
            {                
                protectionplanSOI.id = null;
                //protectionplanSOI.Product_Name__c = null;
                SalesorderObject.Protection_Plan_included__c = false;
                update SalesorderObject;
            }
            system.debug('removePromocode ' + removePromocode);
            if(removePromocode == true)
            {
                /*if(SalesorderObject.Promotion__c != null)
                {    
                    SalesorderObject.Promotion__c = null;
                    update SalesorderObject; 
                }*/
                pc.updatecalculation(SO_Ids); 
            }
            
            getSoRelated();
            updatePromocode();
            
            /* list<SO_Line_Items__c> updateDiscountList = new list<SO_Line_Items__c>();
                for(SelectedProductWrapper SOItem : SoRelated.values())
                {
                SOItem.soi.DiscountAmount__c = 0;
                
                updateDiscountList.add(SOItem.soi);
                }
                System.debug('updateDiscountList :: '+updateDiscountList);
                if(updateDiscountList.size() > 0) {
                update updateDiscountList;
                } 
            */
            
            if(SalesorderObject.id !=null)
            {
                SalesorderObject = salesOrderList(SalesorderObject.id);
            }
            System.debug('SalesorderObject :: '+SalesorderObject);
            showProtectionPlan();
            
            if(protectionplanSOI != null && protectionplanSOI.id != null)
            {     
                update protectionplanSOI; 
                SO_Ids.add(SalesorderObject.id);
                pc = new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null);
                pc.updatecalculation(SO_Ids);                    
                
            }
            
            if(SalesorderObject.id !=null)
            {
                SalesorderObject = salesOrderList(SalesorderObject.id);
            }
            
        }
        catch(Exception e)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
     
    }
    
    public void ShowBundelProduct()
    {
        OptionsId = apexpages.currentpage().getParameters().get('OptionsId');
        SOItemId = apexpages.currentpage().getParameters().get('SOItemId');
        
        system.debug('OptionsId on Options select'+OptionsId);
        system.debug('SOItemId on Options select'+SOItemId);        
        
        displayPopup = true;
      
    }
    
    public void updatePromocode()
    {
        Set<id> InvoicedSoLineItem = new Set<id>();
        promotionObj = new Promotions__c();
        System.debug('In UpdatePromocode');
        try
        { 
            if(SalesorderObject.Promotion__c != null)
            {
                promotionObj = [select Brand__c,Min_Sub_Total__c,Discount_Amount__c,Brands_to_Exclude__c,Type__c,Is_Active__c from Promotions__c where id=:SalesorderObject.Promotion__c ];
                System.debug('promotionObj : '+promotionObj);
                
                if(SoRelated == null || SoRelated.size() < 1)
                { 
                    SalesorderObject.Promotion__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select Products to Apply Promocode'));  
                }
                else if(promotionObj.Is_Active__c==false)
                {
                    SalesorderObject.Promotion__c = null;
                    update SalesorderObject;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(InActive)'));  
                }
                else 
                {
                    decimal subtotal = 0;
                    List<SO_Line_Items__c> LineItemsList = new List<SO_Line_Items__c>();

                    for(SelectedProductWrapper SOItem : SoRelated.values())
                    {
                        LineItemsList.add(SOItem.soi);
                    }
                    if(!LineItemsList.isEmpty())
                    InvoicedSoLineItem = checkOnInvoiced(LineItemsList);

                    for(SelectedProductWrapper SOItem : SoRelated.values())
                    {
                        if(!InvoicedSoLineItem.contains(SOItem.soi.id)){
                            subtotal = subtotal + SOItem.soi.Sub_Total__c; 
                        
			                if (string.valueof(SOItem.soi.Custom_Price__c) == '0'){
			            	    SOItem.soi.Custom_Price__c = null;
			                }
                        }
                    }
                   

                    System.debug('subtotal :: '+subtotal);
                    System.debug('promotionObj.Min_Sub_Total__c :: '+promotionObj.Min_Sub_Total__c);
                    if(subtotal < promotionObj.Min_Sub_Total__c)
                    {
                        SalesorderObject.Promotion__c = null;
                        update SalesorderObject;
                        
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(min subtotal)')); 
                    }
                    else 
                    {
                        System.debug('manufactureList : '+manufactureList);
                        if(!manufactureList.contains(promotionObj.Brand__c) && promotionObj.Type__c == 'Brand')
                        {
                            System.debug('manufactureList Contains: '+manufactureList.contains(promotionObj.Brand__c));
                            System.debug('Brand promotionObj: '+promotionObj.Type__c);
                            SalesorderObject.Promotion__c = null;
                            update SalesorderObject;
                            
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable')); 
                        }
                        else if(promotionObj.Type__c == 'Brand')
                        {
                            subtotal = 0;
                            for(SelectedProductWrapper SOItem : SoRelated.values())
                            {
                                if(SOItem.soi.Manufacturer__c==promotionObj.Brand__c && !InvoicedSoLineItem.contains(SOItem.soi.id))
                                {
                                    subtotal = subtotal + SOItem.soi.Sub_Total__c;
                                }
                            }
                            
                            if(subtotal < promotionObj.Min_Sub_Total__c )
                            {
                                System.debug('manufactureList Contains: '+manufactureList.contains(promotionObj.Brand__c));
                                System.debug('Brand promotionObj: '+promotionObj.Type__c);
                                SalesorderObject.Promotion__c = null;
                                update SalesorderObject;
                                
                                newPriceCalculation pc = new newPriceCalculation();                
                                list<string> SO_Ids = new list<string>();
                                SO_Ids.add(SalesorderObject.id);
                                pc.updatecalculation(SO_Ids); 
                                
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(min subtotal)')); 
                            }
                            else
                            {
                                update SalesorderObject;
                            }
                        }
                        else if(promotionObj.Type__c == 'General')
                        { 
                            if(subtotal < promotionObj.Discount_Amount__c) 
                            {
                                SalesorderObject.Promotion__c = null;
                                update SalesorderObject;
                                
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(Minimum Discount Amount)')); 
                            }
                            else 
                            {
                                System.debug('General promotionObj: '+promotionObj.Type__c);
                                list<string> excludeBrandsList = new list<string>();	
                                set<string> excludeBrandsSet = new set<string>();
                                
                                if(promotionObj.Brands_to_Exclude__c != null && promotionObj.Brands_to_Exclude__c != '')
                                {
                                    for(SelectedProductWrapper SOItem : SoRelated.values())
                                    {
                                        if(SOItem.soi.Products__r.Select_Manufacturer__r.name != null) 
                                        {
                                            If(!manufactureList.contains(SOItem.soi.Products__r.Select_Manufacturer__r.name)) 
                                            {
                                                system.debug('Before manufactureList '+ manufactureList);
                                                manufactureList.add(SOItem.soi.Products__r.Select_Manufacturer__r.name);
                                            }
                                            if(manufactureList.contains(null)) 
                                            {
                                                manufactureList.remove(null);
                                            }
                                        }
                                    }
                                    excludeBrandsSet.addAll(promotionObj.Brands_to_Exclude__c.split(';'));
                                    
                                    system.debug('excludeBrandsSet '+ excludeBrandsSet);
                                    system.debug('After manufactureList '+ manufactureList);
                                    
                                    if(excludeBrandsSet.containsAll(manufactureList) == true)
                                    {
                                        System.debug('manufactureList Contains: '+manufactureList.contains(promotionObj.Brand__c));
                                        System.debug('Brand promotionObj: '+promotionObj.Type__c);
                                        SalesorderObject.Promotion__c = null;
                                        update SalesorderObject;
                                        
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(exclude brands)')); 
                                    }
                                    else
                                    {
                                        subtotal = 0;
                                        decimal count = 0;
                                        
                                        list<SO_Line_Items__c> updateList = new list<SO_Line_Items__c>();
                                        list<SO_Line_Items__c> updateDiscountList = new list<SO_Line_Items__c>();
                                        
                                        for(SelectedProductWrapper SOItem : SoRelated.values())
                                        {
                                            if(excludeBrandsSet.contains(SOItem.soi.Manufacturer__c) == false && SOItem.soi.Quantity_Invoiced__c == 0 && !InvoicedSoLineItem.contains(SOItem.soi.id)) 
                                            {
                                                subtotal = subtotal + SOItem.soi.Sub_Total__c; 
                                                count = count + SOItem.soi.Quantity__c;
                                                updateList.add(SOItem.soi);
                                            }
                                            else
                                            {
                                                //SOItem.soi.DiscountAmount__c = 0;                                                
                                                //updateDiscountList.add(SOItem.soi);
                                            }
                                        }
                                        
                                        system.debug('subtotal '+ subtotal);
                                        system.debug('promotionObj.Min_Sub_Total__c '+ promotionObj.Min_Sub_Total__c);
                                        system.debug('promotionObj.Discount_Amount__c '+ promotionObj.Discount_Amount__c);
                                        
                                        if(subtotal < promotionObj.Min_Sub_Total__c)
                                        {
                                            
                                            System.debug('manufactureList Contains: '+manufactureList.contains(promotionObj.Brand__c));
                                            System.debug('Brand promotionObj: '+promotionObj.Type__c);
                                            SalesorderObject.Promotion__c = null;
                                            update SalesorderObject;
                                            
                                            newPriceCalculation pc = new newPriceCalculation();                
                                            list<string> SO_Ids = new list<string>();
                                            SO_Ids.add(SalesorderObject.id);
                                            pc.updatecalculation(SO_Ids); 
                                            
                                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(min subtotal)')); 
                                        }
                                        else if(subtotal < promotionObj.Discount_Amount__c )
                                        {
                                            System.debug('manufactureList Contains: '+manufactureList.contains(promotionObj.Brand__c));
                                            System.debug('Brand promotionObj: '+promotionObj.Type__c);
                                            SalesorderObject.Promotion__c = null;
                                            update SalesorderObject;
                                            
                                            newPriceCalculation pc = new newPriceCalculation();                
                                            list<string> SO_Ids = new list<string>();
                                            SO_Ids.add(SalesorderObject.id);
                                            pc.updatecalculation(SO_Ids); 
                                            
                                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(Discount Amount is more than select Products total)')); 
                                        }
                                        else
                                        {   
                                            double amountSum = 0;
                                            for(SO_Line_Items__c soi : updateList)
                                            {
                                                //soi.DiscountAmount__c = (promotionObj.Discount_Amount__c / count ) * soi.Quantity__c; 
                                                //soi.DiscountAmount__c = soi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP);
                                                if(!InvoicedSoLineItem.contains(soi.Id)){
                                                    Soi.Discount_Percent__c = Soi.Sub_Total__c / subtotal;
                                                    Soi.DiscountAmount__c = (Soi.Sub_Total__c / subtotal ) * promotionObj.Discount_Amount__c; 
                                                    Soi.DiscountAmount__c = Soi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP); 
                                                    amountSum += Soi.DiscountAmount__c;
                                                    updateDiscountList.add(soi);
                                                }
                                            }

                                            amountSum = promotionObj.Discount_Amount__c - amountSum;
                                            if(updateDiscountList.size()>0){
                                                updateDiscountList.get(0).DiscountAmount__c += amountSum;
                                            }

                                        }
                                        
                                        update SalesorderObject; 
                                        update updateDiscountList;
                                        
                                        newPriceCalculation pc=new newPriceCalculation();                
                                        list<string> SO_Ids=new list<string>();
                                        SO_Ids.add(SalesorderObject.id);
                                        pc.updateGeneralPromoCalculation(SO_Ids);   
                                    }
                                }
                                else
                                { 
                                    system.debug('SalesorderObject.Sub_Total__c : '+SalesorderObject.Sub_Total__c);
                                    system.debug('promotionObj.Discount_Amount__c : '+promotionObj.Discount_Amount__c);
                                    list<SO_Line_Items__c> updateDiscountList = new list<SO_Line_Items__c>();
                                    double amountSum = 0;
                                    for(SelectedProductWrapper SOItem : SoRelated.values())
                                    {
                                        if(!InvoicedSoLineItem.contains(SOItem.soi.Id)){//--------------------------------------------------------
                                            SOItem.Soi.Discount_Percent__c = SOItem.Soi.Sub_Total__c / SalesorderObject.Sub_Total__c;
                                            SOItem.Soi.DiscountAmount__c = (SOItem.Soi.Sub_Total__c / SalesorderObject.Sub_Total__c ) * promotionObj.Discount_Amount__c; 
                                            SOItem.Soi.DiscountAmount__c = SOItem.Soi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP);
                                            amountSum += SOItem.Soi.DiscountAmount__c;
                                            updateDiscountList.add(SOItem.Soi);  
                                        }
                                    }
                                    amountSum = promotionObj.Discount_Amount__c - amountSum;
                                 
                                    if(updateDiscountList.size() > 0)
                                    {
                                        updateDiscountList.get(0).DiscountAmount__c += amountSum;
                                        update updateDiscountList;
                                    }
                                    system.debug('updateDiscountList ' + updateDiscountList);
                                    update SalesorderObject;
                                    
                                    newPriceCalculation pc=new newPriceCalculation();                
                                    list<string> SO_Ids=new list<string>();
                                    SO_Ids.add(SalesorderObject.id);
                                    pc.updateGeneralPromoCalculation(SO_Ids); 
                                }
                            }
                        }
                        else
                        { 
                            update SalesorderObject;
                        }
                        
                        newPriceCalculation pc = new newPriceCalculation();                
                        list<string> SO_Ids = new list<string>();
                        SO_Ids.add(SalesorderObject.id);
                        pc.updatecalculation(SO_Ids);
                        pc.calculation(SO_Ids,'Rejected',null,null);
                    }
                }
            }
            else
            {
                SalesorderObject.Promotion__c = null;
                update SalesorderObject;
                
                newPriceCalculation pc = new newPriceCalculation();                
                list<string> SO_Ids = new list<string>();
                SO_Ids.add(SalesorderObject.id);
                pc.updatecalculation(SO_Ids);  
            }
            SalesorderObject = salesOrderList(SalesorderObject.id);
        }
        catch(Exception e)
        {
            System.debug('Error '+ e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()+', Please contact to System Administrator.'));
            
        }
        System.debug('promo end ');
    }
    
    public Set<Id> checkOnInvoiced(List<SO_Line_Items__c> SoLineItemTiCheckList){
        Set<id> InvoicedSoLineItemList = new Set<id>();
        List<Invoice_Line_Item__c> InvoiceLineItemList = [SELECT Items_invoiced__c FROM Invoice_Line_Item__c WHERE Items_invoiced__c in :SoLineItemTiCheckList AND Sales_Order__c =: SalesorderObject.id];
        for(Invoice_Line_Item__c currentInvoce_i : InvoiceLineItemList){
            InvoicedSoLineItemList.add(currentInvoce_i.Items_invoiced__c);
        }
        return InvoicedSoLineItemList;
    }

    public void showProtectionPlan()
    {
        try
        {
            system.debug('showProtectionPlan');
            system.debug('protectionplanList ' +protectionplanList);
            system.debug('protectionplanList ' +SalesorderObject);
            for(products__c pro : protectionplanList)
            {
                if(protectionplanSOI != null && protectionplanSOI.id!=null)
                {                    
                    if(pro.Protection_high_range__c >= SalesorderObject.Sub_Total__c - (protectionplanSOI.Price__c * protectionplanSOI.Quantity__c)  && pro.Protection_low_range__c <= SalesorderObject.Sub_Total__c - (protectionplanSOI.Price__c * protectionplanSOI.Quantity__c))
                    {
                        system.debug('protectionplanList '+ pro);
                        
                        protectionplanSOI.Product_Name__c=pro.Name;
                        protectionplanSOI.ProductSKU__c=pro.SKU__c;
                        protectionplanSOI.Product_Url__c=pro.Product_Image_URL__c;
                        protectionplanSOI.Product_Record_Type__c=pro.recordtype.name;
                        protectionplanSOI.OriginalPrice__c=pro.Regular_Price__c;
                        if(pro.Sales_Price__c!=null)
                            protectionplanSOI.UnitPrice__c=pro.Sales_Price__c;
                        else
                            protectionplanSOI.UnitPrice__c=pro.Regular_Price__c;
                        protectionplanSOI.Price__c=protectionplanSOI.UnitPrice__c;
                        
                        break;             
                    }
                }
                else
                {
                    if(pro.Protection_high_range__c >= SalesorderObject.Sub_Total__c  && pro.Protection_low_range__c <= SalesorderObject.Sub_Total__c )
                    {                                                                        
                        system.debug('protectionplanList '+ pro);
                        
                        protectionplanSOI=new SO_Line_Items__c();
                        protectionplanSOI.Sales_Order__c=SalesorderObject.id;
                        protectionplanSOI.Products__c=pro.id;
                        protectionplanSOI.Product_Name__c=pro.Name;
                        protectionplanSOI.ProductSKU__c=pro.SKU__c;
                        protectionplanSOI.Product_Url__c=pro.Product_Image_URL__c;
                        protectionplanSOI.Product_Record_Type__c=pro.recordtype.name;
                        protectionplanSOI.OriginalPrice__c=pro.Regular_Price__c;
                        if(pro.Sales_Price__c!=null)
                            protectionplanSOI.UnitPrice__c=pro.Sales_Price__c;
                        else
                            protectionplanSOI.UnitPrice__c=pro.Regular_Price__c;
                        protectionplanSOI.Price__c=protectionplanSOI.UnitPrice__c;
                        protectionplanSOI.IncludeInPricing__c=true;
                        break; 
                    }  
                    else
                    {
                        protectionplanSOI=new  SO_Line_Items__c();
                    }
                }
            }
            
            system.debug('showProtectionPlan protectionplanSOI '+ protectionplanSOI);
            
            system.debug('showProtectionPlan END');
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void taxCalculation()
    {
    	update SalesorderObject;
        SalesorderObject = salesOrderList(SalesorderObject.id);
        /*try {
            System.debug('*****taxCalculation*****');
            if(SalesorderObject.id != null)
            {
                map<string,Tax_Percentage__c> stateTaxPercentage = Tax_Percentage__c.getall();
                if(stateTaxPercentage.get(SalesorderObject.Shipping_State__c) != null)
                {
                    SalesorderObject.Tax_Percentage__c=stateTaxPercentage.get(SalesorderObject.Shipping_State__c).Percentage__c ;
                }
                else if(stateTaxPercentage.get(SalesorderObject.Shipping_City__c) != null)
                {
                    SalesorderObject.Tax_Percentage__c=stateTaxPercentage.get(SalesorderObject.Shipping_City__c).Percentage__c ;
                }
                else
                {
                    SalesorderObject.Tax_Percentage__c = 0; 
                }
                
                update SalesorderObject;
                
                newPriceCalculation pc = new newPriceCalculation();            
                list<string> SO_Ids=new list<string>(); 
                SO_Ids.add(SalesorderObject.id);            
                pc.calculation(SO_Ids,'Rejected',null,null); 
                
                SalesorderObject = salesOrderList(SalesorderObject.id);
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }*/
    }
    
    public void AutoFillAddress()
    {
        try
        {           
            if(SalesorderObject.Customer_Billing_Address__c != null)
            {
                Customer_Addresses__c cusAddressRecord = [select Account__r.Mobile__c,Account__r.Email__c,Name,Cell__c,City__c,Country__c,State__c,Street_Address__c,Telephone__c,Zip_Postal_Code__c from Customer_Addresses__c where id=:SalesorderObject.Customer_Billing_Address__c ] ;
                SalesorderObject.Email__c=cusAddressRecord.Account__r.Email__c;
                SalesorderObject.Mobile__c=cusAddressRecord.Account__r.Mobile__c;
                SalesorderObject.Bill_To__c=cusAddressRecord.Name;
                SalesorderObject.Billing_Phone__c=cusAddressRecord.Cell__c;
                SalesorderObject.Billing_City__c=cusAddressRecord.City__c;
                SalesorderObject.Billing_State__c=cusAddressRecord.State__c;
                SalesorderObject.Billing_Street__c=cusAddressRecord.Street_Address__c;
                SalesorderObject.Billing_ZipCode__c=cusAddressRecord.Zip_Postal_Code__c;
                SalesorderObject.Billing_Phone__c=cusAddressRecord.Telephone__c;
                
            }
            if(SalesorderObject.Customer_shipping_Address__c != null)
            {
                Customer_Addresses__c cusAddressRecord=[select Account__r.Mobile__c,Account__r.Email__c,Name,Cell__c,City__c,Country__c,State__c,Street_Address__c,Telephone__c,Zip_Postal_Code__c from Customer_Addresses__c where id=:SalesorderObject.Customer_shipping_Address__c ] ;
                SalesorderObject.Email__c=cusAddressRecord.Account__r.Email__c;
                SalesorderObject.Mobile__c=cusAddressRecord.Account__r.Mobile__c;
                SalesorderObject.Ship_to__c=cusAddressRecord.Name;
                SalesorderObject.Shipping_Phone__c=cusAddressRecord.Cell__c;
                SalesorderObject.Shipping_City__c=cusAddressRecord.City__c;
                SalesorderObject.Shipping_State__c=cusAddressRecord.State__c;
                SalesorderObject.Shipping_Street__c=cusAddressRecord.Street_Address__c;
                SalesorderObject.Shipping_ZipCode__c=cusAddressRecord.Zip_Postal_Code__c; 
                SalesorderObject.Shipping_Phone__c=cusAddressRecord.Telephone__c;
                
                /*if(stateTaxPercentage.get(SalesorderObject.Shipping_State__c)!=null)
                {
                    SalesorderObject.Tax_Percentage__c=stateTaxPercentage.get(SalesorderObject.Shipping_State__c).Percentage__c ;
                }
                else if(stateTaxPercentage.get(SalesorderObject.Shipping_City__c)!=null)
                {
                    SalesorderObject.Tax_Percentage__c=stateTaxPercentage.get(SalesorderObject.Shipping_City__c).Percentage__c ;
                }
                else
                {
                    SalesorderObject.Tax_Percentage__c=0; 
                }*/
                
                system.debug('SalesorderObject.Tax_Percentage__c=0 ' + SalesorderObject.Tax_Percentage__c);
                
                update SalesorderObject;
                
                newPriceCalculation pc=new newPriceCalculation();                
                list<string> SO_Ids=new list<string>();
                SO_Ids.add(SalesorderObject.id);
                pc.calculation(SO_Ids,'Rejected',null,null);
                pc.updatecalculation(SO_Ids); 
                
            }  
            
            SalesorderObject = salesOrderList(SalesorderObject.id);
            system.debug('SalesorderObject '+SalesorderObject);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void showDistance()
    {
        try {
            SalesorderObject = salesOrderList(SalesorderObject.id);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public PageReference submitOrder()
    {
        PageReference salesOrderRef;
        list<Transaction__c> tanscationVoidlist = new list<Transaction__c>();
        list<Task> taskCancelList = new list<Task>();
        
        try
        { 
        	boolean hasCaptured = false;
            system.debug('submit order'); 
            SalesorderObject.Order_Status__c='Processing';
            system.debug('SalesorderObject.Id '+SalesorderObject.Id);
            system.debug('SalesorderObject ' + SalesorderObject);
            Sales_Order__c SalesorderObjectObj = [select id,email__c, Authdotnetoldaccount__c, createddate, Payment_Status__c, Customer_Name__r.Web_Site__c, Customer_Billing_Address__c, Grand_Total__c, Total_Due__c,
            										Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c,Billing_Phone__c,Mobile__c, Total_Paid__c,
            										Customer_shipping_Address__c,Ship_to__c,Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_ZipCode__c, Payment_Method__c,
            										Shipping_Phone__c,Shipping_Mobile__c,Customer_Name__c,IsSoModified__c,Customer_Name__r.Authorize_net_Profile_ID__c, Do_not_charge_tax__c, 
            										Discount_AmountTotal__c,(select id,custom_price__c,Custom_Price_For_Credit_Memo__c,Products__r.recordtype.Name,Bundle_Item__c,Sales_Order__c,Last_status_before_cancel__c
            										from SO_Line_Items__r),(select id,Payment_Type__c,Payment_Method__c,TransactionId__c,Payment_Method__r.Customer_Profile_ID__c,
            										Payment_Method__r.Credit_Card_Number__c,Payment_Method__r.Payment_Profile_ID__c,Status__c from Transactions__r ),
            										(select id from tasks where (Subject like '%Follow-up the Order for%'  or subject like '%Follow Up for Payment Authorization Expiry%'  
            										or subject like '%Generate Paypal Invoice for%' ) and Status='Open') from Sales_Order__c where id=:SalesorderObject.Id ];        
            system.debug('SalesorderObject. '+SalesorderObject );
            custumpricetotal=null;
            if  (SalesorderObjectObj.Total_Due__c == originalTotalDue && !hasCard1 && !hasCard2 && !hasCard3 
			      && (
					  (SalesorderObjectObj.Payment_Method__c == 'Manual Payment'  && paymentType == 'ManualPay')
					  || (SalesorderObjectObj.Payment_Method__c == 'Cardknox'  && paymentType == 'Cardknox') 
					  || (SalesorderObjectObj.Payment_Method__c == 'Zibby by Affirm'  && paymentType == 'Zibby by Affirm') 
					  || (SalesorderObjectObj.Payment_Method__c == 'Credit Card'  && paymentType == 'CreditCard') 
					  || (SalesorderObjectObj.Payment_Method__c == 'PayPal'  && paymentType == 'PaypalInvoice') 
					  || (SalesorderObjectObj.Payment_Method__c == 'Pay by Check'  && paymentType == 'Paybycheck') 
					  || (SalesorderObjectObj.Payment_Method__c == 'Affirm'  && paymentType == 'AffirmPay')
					 )
			    ){
	            SalesorderObject.IsSoModified__c = SalesorderObjectController.Notify_Customer_with_Email__c;
	            SalesorderObject.Notify_Customer_with_Email__c=SalesorderObjectController.Notify_Customer_with_Email__c;
            	update SalesorderObject;
            	return new PageReference('/' +SalesorderObject.id);
            }
            system.debug('customPriceMap ' + customPriceMap);
            
            for(SO_Line_Items__c SOI : SalesorderObjectObj.SO_Line_Items__r)
            {
                if(customPriceMap.containsKey(SOI.id))
                {
                    if( soi.Custom_Price__c !=null && customPriceMap.get(SOI.id) != SOI.Custom_Price__c)
                    {
	                	if (custumpricetotal == null){
	                		custumpricetotal = 0;
	                	}
                        custumpricetotal = custumpricetotal+SOI.Custom_Price__c;
                    }
                }
                else
                {
                	
                	if (custumpricetotal == null){
                		custumpricetotal = 0;
                	}
                    if(SOI.Custom_Price__c==null)
                    {
                        custumpricetotal = custumpricetotal;
                    }
                    else
                    {
                        custumpricetotal = custumpricetotal+SOI.Custom_Price__c;  
                    }
                }
            }
            system.debug('custumpricetotal ' + custumpricetotal);
            
            if(SalesorderObjectObj.SO_Line_Items__r.size() == 0 )
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Products to continue'));
                return null;
            }
            else if(SalesorderObjectObj.Customer_Name__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Customer to continue'));  
                return null;
            }
            else if(paymentType == '' || paymentType == null )
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Payment Information to continue'));  
                return null;
            }
            else if(SalesorderObject.Order_ETA__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Order ETA to continue '));
                return null;
            }
            else if(SalesorderObject.email__c==null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Enter customer Details '));
                return null;
            }
            else if(SalesorderObject.Billing_Phone__c==null || SalesorderObject.Billing_Street__c==null || SalesorderObject.Billing_City__c==null || SalesorderObject.Billing_State__c==null || SalesorderObject.Billing_ZipCode__c==null)
            {
                system.debug('SalesorderObject.Bill_To__c '+SalesorderObject.Bill_To__c+' SalesorderObject.Billing_Street__c ' + SalesorderObject.Billing_Street__c+'SalesorderObject.Billing_City__c '+SalesorderObject.Billing_City__c+' SalesorderObject.Billing_State__c ' + SalesorderObject.Billing_State__c+' SalesorderObject.Billing_ZipCode__c ' + SalesorderObject.Billing_ZipCode__c);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the Customer Billing Address '));
                return null;
            }
            else if(SalesorderObject.Shipping_Phone__c==null || SalesorderObject.Shipping_Street__c==null || SalesorderObject.Shipping_City__c==null || SalesorderObject.Shipping_State__c==null || SalesorderObject.shipping_ZipCode__c==null)
            {
                system.debug('SalesorderObject.ship_To__c '+SalesorderObject.ship_To__c+' SalesorderObject.Shipping_Street__c ' + SalesorderObject.Shipping_Street__c+'SalesorderObject.Shipping_City__c '+SalesorderObject.Shipping_City__c+'SalesorderObject.Shipping_State__c '+SalesorderObject.Shipping_State__c+'SalesorderObject.Shipping_ZipCode__c '+SalesorderObject.Shipping_ZipCode__c);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the Customer Shipping Address '));
                return null;
            }
            else
            {
                AccountObject = [select id,name,Customer_Profile_Number__c,Authorize_net_Profile_ID__c,(select id,Payment_Profile_ID__c,Credit_Card_Number__c from Payment_Methods__r where  Credit_Card_Number__c!=null and Payment_Profile_ID__c!=null) from account where id=:SalesorderObject.Customer_Name__c ];
                system.debug('AccountObject '+ AccountObject );
                if(AccountObject.Payment_Methods__r != null)
                {
                    for(Payment_Method__c paymentMethod : AccountObject.Payment_Methods__r)
                    {
                        customerCards.put(paymentMethod.Credit_Card_Number__c,paymentMethod.Payment_Profile_ID__c);
                    }
                }
                
                list<transactionWrapper> VoidtransactionWrapperList=new list<transactionWrapper>(); 
                if(SalesorderObjectObj.Transactions__r.size() > 0)
                {
                    for(Transaction__c tt : SalesorderObjectObj.Transactions__r)
                    {
                        if((tt.Payment_Type__c=='Credit Card') && tt.Status__c == 'Authorized'  && SalesorderObjectObj.Payment_Status__c == 'Authorized')
                        {
                           VoidtransactionWrapperList.add(new transactionWrapper(tt.Payment_Method__r.Customer_Profile_ID__c,tt.Payment_Method__r.Payment_Profile_ID__c,tt.TransactionId__c, SalesorderObjectObj.createddate, SalesorderObjectObj.Authdotnetoldaccount__c)); 
	                        Transaction__c transactionObject = new Transaction__c();
	                        transactionObject.id = tt.Id;
	                        transactionObject.Status__c = 'Voided';
	                        tanscationVoidlist.add(transactionObject);     
                        }
                        if (tt.Status__c == 'Captured'){
                        	hasCaptured = true;
                        }
                        /*else if((tt.Payment_Type__c == 'PayPal' || tt.Payment_Type__c == 'PayPal Express Checkout') && tt.TransactionId__c != null && tt.Status__c != 'Voided')
                        {
                            voidPaypalPayments(tt, SalesorderObjectObj.Customer_Name__r.Web_Site__c);
                        }*/
                    }
                    if(VoidtransactionWrapperList.size() > 0)
                    {
                       voidPayments(VoidtransactionWrapperList); 
                    }
                }
                for(task taskData : SalesorderObjectObj.tasks )
                {
                    task taskObj = new task();
                    taskObj.id = taskData.id;
                    taskObj.status = 'Cancelled'; 
                    taskCancelList.add(taskObj);
                }
                if(SalesorderObjectObj.Grand_Total__c < SalesorderObjectObj.Total_Paid__c){// && SalesorderObjectObj.Payment_Status__c == 'Received'){
                	if (SalesorderObject.Payment_Method__c == 'Credit Card'){
                		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Refund needs to be done manually - use the credit memo button'));
                	}
                	else{
                		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Refund needs to be done manually'));
                	}
                	SalesorderObject.Payment_Status__c = 'Refund Required';
                	SalesorderObject.Create_refund_task__c = true;
                	salesOrderRef = new PageReference('/' +SalesorderObject.id);
	                salesOrderRef.setRedirect(true);
                }
                else {
	                if(paymentType == 'CreditCard')
	                {
	                    decimal total = 0;
	                    SalesorderObject.Payment_Method__c='Credit Card';
	                    list<Payment_Method__c> paymentMethods = new list<Payment_Method__c>();
	                    
	                    if(hasCard1 == false && hasCard3 == false && hasCard2 == false && hasCard4 == false)
	                    {
	                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Card to continue ')); 
	                        return null;
	                    }
	                    else
	                    {
	                        if(hasCard1 == true)
	                        {
	                            if(SalesorderObject.Customer_Name__c==null || paymentMethodVar.Card_Type__c==null || paymentMethodVar.Credit_Card_Number__c==null ||  paymentMethodVar.Card_Verification_Number__c==null || paymentMethodVar.Expiration_Month__c==null || paymentMethodVar.Expiration_Year__c==null)
	                            {
	                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter all Required Fileds in card 1'));
	                            	return null;
	                            } 
	                            else
	                            {
	                                total = total+paymentMethodVar.Amount__c;
	                            }
	                        }
	                        if(hasCard2 == true)
	                        {
	                            if(SalesorderObject.Customer_Name__c==null || paymentMethodVar1.Card_Type__c==null || paymentMethodVar1.Credit_Card_Number__c==null ||  paymentMethodVar.Card_Verification_Number__c==null || paymentMethodVar1.Expiration_Month__c==null || paymentMethodVar1.Expiration_Year__c==null)
	                            {
	                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter all Required Fileds in card 2'));
	                                return null;
	                            }
	                            else
	                            {
	                                total=total+paymentMethodVar1.Amount__c;
	                            }
	                        }
	                        if(hasCard3 == true)
	                        {
	                            if(SalesorderObject.Customer_Name__c==null || paymentMethodVar2.Card_Type__c==null || paymentMethodVar2.Credit_Card_Number__c==null ||  paymentMethodVar2.Card_Verification_Number__c==null || paymentMethodVar2.Expiration_Month__c==null || paymentMethodVar2.Expiration_Year__c==null)
	                            {
	                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter all Required Fileds in card 3'));
	                                return null;
	                            }
	                            else
	                            {
	                                total=total+paymentMethodVar2.Amount__c;
	                            }
	                        }
	                        if(hasCard4 == true)
	                        {
	                            if(SalesorderObject.Customer_Name__c==null)
	                            {
	                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter all Required Fileds in card 3'));
	                                return null;
	                            }
	                            else if(paymentMethodVar4.Amount__c==null)
	                            {
	                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter a valid amount'));
	                                return null;
	                            }
	                            else
	                            {
	                            	system.debug('total '+total);
	                                total=total+paymentMethodVar4.Amount__c;
	                            }
	                        }
	                        
	                        if(total != SalesorderObjectObj.Total_Due__c)//SalesorderObject.Grand_Total__c)
	                        {
	                            system.debug('total '+total+' SalesorderObject ' + SalesorderObject.Total_Due__c);
	                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the entered amount. ' + total+ ' Amount due is ' + SalesorderObjectObj.Total_Due__c));//' Grand Total is '+SalesorderObject.Grand_Total__c));
	                            return null;
	                        }
	                        else if(SalesorderObjectObj.email__c==null)
	                        {
	                            system.debug('SalesorderObjectObj.email__c' + SalesorderObjectObj.email__c);
	                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check customer Email '));
	                            return null;
	                        }
	                        else if(SalesorderObjectObj.Bill_To__c==null || SalesorderObjectObj.Billing_Street__c==null || SalesorderObjectObj.Billing_City__c==null || SalesorderObjectObj.Billing_State__c==null || SalesorderObjectObj.Billing_ZipCode__c==null)
	                        {
	                            system.debug('SalesorderObjectObj.Bill_To__c '+SalesorderObjectObj.Bill_To__c+' SalesorderObjectObj.Billing_Street__c ' + SalesorderObjectObj.Billing_Street__c+'SalesorderObjectObj.Billing_City__c '+SalesorderObjectObj.Billing_City__c+' SalesorderObjectObj.Billing_State__c ' + SalesorderObjectObj.Billing_State__c+' SalesorderObjectObj.Billing_ZipCode__c ' + SalesorderObjectObj.Billing_ZipCode__c);
	                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the Customer Billing Address '));
	                            return null;
	                        }
	                        else
	                        {
	                            boolean result = true;
	                            if(hasCard1 == true)
	                            {
	                                paymentMethods.add(paymentMethodVar);
	                            }
	                            if(hasCard2 == true)
	                            {
	                                paymentMethods.add(paymentMethodVar1);
	                            }
	                            if(hasCard3 == true)
	                            { 
	                                paymentMethods.add(paymentMethodVar2);
	                            }
	                            if(hasCard4 == true)
	                            { 
	                                paymentMethods.add(paymentMethodVar4);
	                            }
	                            system.debug('paymentMethods '+ paymentMethods);
	                            
	                            result = insertPaymentMethod(paymentMethods,SalesorderObject);
	                            system.debug('result '+result);
	                            if(result == false) 
	                            {
	                                return null;
	                            }
	                            else
	                            {
	                                salesOrderRef=new PageReference('/' +SalesorderObject.id);
	                                salesOrderRef.setRedirect(true);
	                                if (hasCaptured){
	                    				SalesorderObject.Payment_Status__c = 'Partial';  
	                                }
	                            }
	                        }
	                    }
	                }
	                else if(paymentType == 'Paybycheck')
	                {
	                    if(SalesorderObject.Customer_Name__c==null || paymentMethodVar.Check_Type__c==null || paymentMethodVar.Name_on_Account__c==null ||  paymentMethodVar.Routing_Number__c==null || paymentMethodVar.Account_Number__c==null)
	                    {
	                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter all Required Fileds In Payment section'));
	                        return null;
	                    }
	                    else
	                    {
                			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Changing payment method on the order will require manual payment processing'));
	                        paymentMethodVar.Account__c=SalesorderObject.Customer_Name__c;
	                        for(recordtype retypeObj:[select id, name,sobjecttype from recordtype where name='Check Payments' limit 1])
	                        {
	                            paymentMethodVar.RecordTypeId=retypeObj.id;
	                            paymentMethodVar.Amount__c=SalesorderObject.Grand_Total__c;
	                        }
	                        insert paymentMethodVar;
	                        
	                        Transaction__c transactionObject=new Transaction__c();
	                        transactionObject.Sales_Order__c=SalesorderObject.Id;
	                        transactionObject.Payment_Method__c=paymentMethodVar.ID;
	                        transactionObject.Transaction_Type__c='Cheque';
	                        transactionObject.Amount__c= SalesorderObjectObj.Total_Due__c; //SalesorderObject.Grand_Total__c;
	                        transactionObject.Status__c='Pending';
	                        insert transactionObject;
	                        
	                        SalesorderObject.Payment_Type__c=paymentMethodVar.id;
	                        update SalesorderObject;
	                        salesOrderRef=new PageReference('/' +SalesorderObject.id);
	                        salesOrderRef.setRedirect(true);
	                        
                            if (hasCaptured){
                				SalesorderObject.Payment_Status__c = 'Partial';  
                            }
	                        SalesorderObject.Payment_Method__c='Check Payments';
	                    }
	                }
	                else if(paymentType == 'PaypalInvoice')
	                {
                		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Changing payment method on the order will require manual payment processing'));
	                    salesOrderRef=new PageReference('/' +SalesorderObject.id);
	                    salesOrderRef.setRedirect(true);
	                    
                            if (hasCaptured){
                				SalesorderObject.Payment_Status__c = 'Partial';  
                            }
	                    SalesorderObject.Payment_Method__c='PayPal';
	                }
	                else if(paymentType == 'ManualPay' || paymentType == 'Cardknox' || paymentType == 'Zibby by Affirm')
	                {
						String chosenType;// = (paymentType == 'ManualPay' ? 'Manual Payment' : 'Cardknox');  
                        String accountName;
                        switch on paymentType{
                            when 'ManualPay'{
                                chosenType = 'Manual Payment';
                                accountName = 'Manual';
                            }
                            when else{
                                chosenType = paymentType;
                                accountName = paymentType;
                            }
                        }
						//String chosenType = (paymentType == 'ManualPay' ? 'Manual Payment' : 'Cardknox'); 
                		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Changing payment method on the order will require manual payment processing'));
	                    salesOrderRef=new PageReference('/' +SalesorderObject.id);
	                    salesOrderRef.setRedirect(true);
	                    
	                    string manualrecordId=[select id from Recordtype where name =: chosenType].id;
	                    Payment_Method__c paymentMethodVar=new Payment_Method__c();
	                    paymentMethodVar.recordtypeid=manualrecordId;
	                    paymentMethodVar.Name_on_Account__c = accountName;//(paymentType == 'ManualPay' ? 'Manual' : 'Cardknox');//'Manual';
	                    paymentMethodVar.Amount__c= SalesorderObjectObj.Total_Due__c; //SalesorderObject.Grand_Total__c;
	                    paymentMethodVar.Account__c=SalesorderObject.Customer_Name__c; // accid
	                    
	                    insert paymentMethodVar;
	                    
	                    Transaction__c transactionObject=new Transaction__c();
	                    transactionObject.Transaction_Type__c='AUTH_ONLY';
	                    transactionObject.Sales_Order__c=SalesorderObject.id;
	                    transactionObject.Payment_Method__c=paymentMethodVar.ID;
	                    transactionObject.Amount__c=SalesorderObject.Total_Due__c;
	                    transactionObject.Status__c='Pending';
	                    
	                    insert transactionObject;
	                    SalesorderObject.Payment_Method__c = chosenType;

                            if (hasCaptured){
                				SalesorderObject.Payment_Status__c = 'Partial';  
                            }
	                }	                
	                else if(paymentType == 'AmazonPay')
	                {
                		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Changing payment method on the order will require manual payment processing'));
	                    salesOrderRef = new PageReference('/' +SalesorderObject.id);
	                    salesOrderRef.setRedirect(true);
	                    
	                    SalesorderObject.Payment_Method__c='Amazon Payment';
	                    
                            if (hasCaptured){
                				SalesorderObject.Payment_Status__c = 'Partial';  
                            }
	                    
	                }
	                else if(paymentType == 'AffirmPay')
	                {
                		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'Changing payment method on the order will require manual payment processing'));
	                    salesOrderRef = new PageReference('/' +SalesorderObject.id);
	                    salesOrderRef.setRedirect(true);
	                    
	                    SalesorderObject.Payment_Method__c='Affirm';
	                    if (hasCaptured){
                				SalesorderObject.Payment_Status__c = 'Partial';  
                            }
	                }
                }
                
                if(tanscationVoidlist.size()>0)
                    update tanscationVoidlist;
                
                if(taskCancelList.size()>0)
                    update taskCancelList;    
                SalesorderObject.Comments__c=SalesorderObjectController.Comments__c;
                SalesorderObject.SF_Order_Modified__c = true;
                SalesorderObject.Customer_Comments__c=SalesorderObjectController.Customer_Comments__c;
                system.debug('SalesorderObject = ' + SalesorderObject);
                update SalesorderObject;
                
                if(custumpricetotal > 0)
                {
                    SalesorderObject.Is_Custom_Priced_Order__c=true; 
                    update SalesorderObject;
                    Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
                    req1.setComments('Please Review & Approve this Refund');
                    req1.setObjectId(SalesorderObject.Id);
                    
                    // Submit the approval request for the Invoice
                    Approval.ProcessResult result = Approval.process(req1);
                }
                else
                {
                    system.debug('SalesorderObject eta '+ SalesorderObject.Order_ETA__c);
                    SalesorderObject.IsSoModified__c = SalesorderObjectController.Notify_Customer_with_Email__c;
                    SalesorderObject.Notify_Customer_with_Email__c=SalesorderObjectController.Notify_Customer_with_Email__c;
                    update SalesorderObject;  
                }
            }
            
            for(SO_Line_Items__c SOI : SalesorderObjectObj.SO_Line_Items__r)
            {
                if(SOI.Products__r.recordtype.Name == 'Bundled' && SOI.Bundle_Item__c == null) 
                {
                    newPriceCalculation.getMainBundleWeight(SOI.Sales_Order__c);
                }
            }
        }
        catch(Exception e)
        {
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
        }
        system.debug('submit order end'); 
        return salesOrderRef;
    }
    
    /*public void voidPaypalPayments(Transaction__c transactionObj, String acountType)
    {
        PaypalConnect PaypalConnectObj = new PaypalConnect(acountType);
        payPalResponse payPalResponseObj = new payPalResponse();
        try {
            payPalResponseObj = PaypalConnectObj.voidPayment(transactionObj.TransactionId__c);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }*/
    
    public PageReference cancelSalesOrder()
    {
        PageReference salesOrderRef;
        
        try
        {
            if(SalesorderObject.id != null)
            {
                system.debug('rollbacksalesorder ' + rollbacksalesorder); 
                
                string promocode = rollbacksalesorder.Promotion__c;
                
                rollbacksalesorder.Promotion__c = null;
                update rollbacksalesorder;
                
                system.debug('rollbackSOItems  1 = ' + rollbackSOItems);
                Sales_Order__c SalesorderObjectObj=[select Customer_Name__c,(select id from SO_Line_Items__r) from Sales_Order__c where id=:SalesorderObject.Id ];
                /*map<string, SO_Line_Items__c> lineItemsMap = new map<string, SO_Line_Items__c>();
                
                for (SO_Line_Items__c li : SalesorderObjectObj.SO_Line_Items__r){
                	lineItemsMap.put(li.id, li);
                }*/
                delete SalesorderObjectObj.SO_Line_Items__r;
                system.debug('rollbackSOItems  2 = ' + rollbackSOItems);
                list<PO_Line_Items__c> lineItemsToUpdate = new list<PO_Line_Items__c>();
                if(rollbackSOItems.size()>0)
                {
                    upsert rollbackSOItems;
                    for (SO_Line_Items__c li : rollbackSOItems){
                    	
			            if (string.valueof(li.Custom_Price__c) == '0'){
			            	li.Custom_Price__c = null;
			            }
                    	for (PO_Line_Items__c pl : li.PO_Line_Items__r){
                    		
                    		pl.So_Line_Item__c = li.id;
                    		lineItemsToUpdate.add(pl);
                    	}
                    }
                    if (lineItemsToUpdate.size() > 0){
                    	update lineItemsToUpdate;
                    }
                    system.debug('rollbackSOItems  '+rollbackSOItems+' promocode '+ promocode);
                }
                
                newPriceCalculation pc=new newPriceCalculation();
                list<string> SO_Ids=new list<string>();
                SO_Ids.add(SalesorderObject.id);
                pc.calculation(SO_Ids,'Rejected',null,null);
                
                rollbacksalesorder.Promotion__c = promocode;
                update rollbacksalesorder;
                
                pc.updatecalculation(SO_Ids); 
                
                salesOrderRef=new PageReference('/' +SalesorderObject.id);
                salesOrderRef.setRedirect(true);
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return salesOrderRef;
    }
    
    @RemoteAction
    global static string getPrevProducts(string firstPayapalval,string query,string SOId) 
    {
        String productsJSON ;
        string configProductsJSON='';
        
        try
        {
            list<string> productids=new list<string>();
            for(SO_Line_Items__c soi: [select id,Products__c from SO_Line_Items__c where Sales_Order__c=:SOId ])
            {
                productids.add(soi.Products__c); 
            }
            
            system.debug('firstPayapalval ' + firstPayapalval);
            system.debug('query  ' + query);
            list<Products__c> productsList=new list<Products__c>();
            list<products__c> productListTemp=new list<products__c>();
            string condition=' ';
            if(query != null )
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
            
            query=query+' '+condition;
            system.debug('query+condition  ' + query);
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            
            productListTemp = database.query(query);
            
            for(integer i=productListTemp.size()-1;i>=0;i--)
            {
                productsList.add(productListTemp[i]);
            }
            system.debug('productsList '+productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
            
            list<string> proID=new list<string>();
            list<Products__c> ProductsTemp=new list<Products__c>();
            
            for(Products__c pro: productsList)
            {
                for(Bundle_Item__c bud: pro.Bundle_Items1__r)
                {
                    if(bud.Product__r.recordtype.name=='Configurable')
                    {
                        proID.add(bud.Product__c);
                    }
                } 
            }
            
            if(proID.size()>0)
            {
                for(products__c pro : [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c from Products__r)  from Products__c where Master_Products__c=null  and recordtype.name!='Protection Plan' and id  IN: proID ])
                {
                    ProductsTemp.add(pro);
                }
                
                configProductsJSON=JSON.serialize(ProductsTemp);
                productsJSON=productsJSON+' configProducts '+configProductsJSON;
                system.debug(' productsJSON config '+productsJSON );
            }
            
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return productsJSON;
    }
    
    @RemoteAction
    global static string getNextProducts(string lastPayapalval,string query,string SOId) 
    {
        String productsJSON ;
        string configProductsJSON='';
        
        try
        {
            list<string> productids = new list<string>();
            for(SO_Line_Items__c soi : [select id,Products__c from SO_Line_Items__c where Sales_Order__c=:SOId ])
            {
                productids.add(soi.Products__c); 
            }
            system.debug('lastPayapalval : ' + lastPayapalval);
            
            list<Products__c> productsList = new list<Products__c>();
            string condition=' ';
            system.debug('query  ' + query);
            if(query != null )
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
            system.debug('query+condition  ' + query);
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            productsList = database.query(query);
            system.debug('productsList  ' + productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
            
            list<string> proID=new list<string>();
            list<Products__c> ProductsTemp=new list<Products__c>();
            
            for(Products__c pro : productsList)
            {
                for(Bundle_Item__c bud: pro.Bundle_Items1__r)
                {
                    if(bud.Product__r.recordtype.name=='Configurable')
                    {
                        proID.add(bud.Product__c);
                    }
                } 
            }
            
            if(proID.size()>0)
            {
                for(products__c pro : [select id,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c from Products__r)  from Products__c where Master_Products__c=null  and recordtype.name!='Protection Plan' and id  IN: proID ])
                {
                    ProductsTemp.add(pro);
                }
                
                configProductsJSON=JSON.serialize(ProductsTemp);
                
                productsJSON=productsJSON+' configProducts '+configProductsJSON;
                
                system.debug(' productsJSON config '+productsJSON );
            }
            
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return productsJSON;
    }
    
    @RemoteAction
    global static string searchProducts(string sku,string productName,string manufacture,string SOId) 
    {        
        String productsJSON = '';
        string configProductsJSON = '';
        
        System.debug('SOId : '+SOId);        
        list<string> productids = new list<string>();
        try {
            for(SO_Line_Items__c soi : [select id,Products__c from SO_Line_Items__c where Sales_Order__c=:SOId ])
            {
                productids.add(soi.Products__c); 
            }
            System.debug('productids : '+productids);          
            
            string query = 'select id,FedExable__c,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,Total_Items_in_Bundle__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c from Products__r),(select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c ,Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c=\'Enabled\'  ORDER BY Order__c ASC NULLS LAST) from Products__c where Status__c=\'Enabled\' and (Master_Products__c=null and recordtype.name!=\'Protection Plan\') and id not in : productids';
            string condition = '';
            string storedQuery = '';
            
            if(sku != '')
            {
                sku = String.escapeSingleQuotes(sku);
                sku=sku.trim();
                condition = ' and SKU__c LIKE '+'\'%'+sku+'%\'';
            }  
            if(productName != '')
            {
                productName = String.escapeSingleQuotes(productName);
                productName = productName.trim();
                condition = condition+' and Name LIKE '+'\'%'+productName+'%\'';           
            }
            if(manufacture != '')
            { 
                manufacture = String.escapeSingleQuotes(manufacture);
                manufacture = manufacture.trim();
                condition = condition+' and Select_Manufacturer__r.name LIKE '+'\'%'+manufacture+'%\''; 
            }
            
            storedQuery = query+condition;
            query = query+condition+' order by id limit 20'; 
            system.debug('query  ' +query);
            list<Products__c> productsList=new list<Products__c>();
            productsList = database.query(query);
            System.debug('productsList : '+productsList);
            productsJSON = JSON.serialize(productsList);
            
            if(productsJSON != '[]')
            {
                productsJSON = productsJSON+' storedQuery '+storedQuery; 
            }
            system.debug('productsJSON ' +productsJSON);
            
            list<string> proID = new list<string>();
            list<Products__c> ProductsTemp = new list<Products__c>();
            
            for(Products__c pro : productsList)
            {
                if(pro.Configurable_Items__r != null && pro.recordtype.name == 'Configurable') {// Bundle_Items1__r
                    for(Configurable_Item__c  bud : pro.Configurable_Items__r)
                    {
                        //if(bud.Product__r.recordtype.name == 'Configurable')
                        //{
                            proID.add(bud.Product__c);
                        //}
                    } 
                }
            }
            
            if(proID.size() > 0)
            {
                for(products__c pro : [select id,FedExable__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c, Special_Tier_Price_For_Bundle__c, Special_Tier_Price_Start_Date__c, Special_Tier_Price_End_Date__c from Products__r) from Products__c where Master_Products__c=null and recordtype.name!='Protection Plan' and id IN: proID ])
                {
                    ProductsTemp.add(pro);
                }
                configProductsJSON = JSON.serialize(ProductsTemp);
                productsJSON = productsJSON+' configProducts '+configProductsJSON;
                
                system.debug('productsJSON config '+productsJSON );
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return productsJSON;
    }
    
    public class ProductWrapper 
    {
        public Products__c pro{get; set;}
        public List<selectoption> configpro{get; set;}
        public string selectedoption{get;set;}
        public boolean selected{set;get;}
        public string quantity{set;get;}
        
        public map<string,decimal> configSalesPrice{set;get;}
        public map<string,decimal> configSpecialPrice{set;get;}
        public map<string,decimal> configRegularPrice{set;get;}
        
        public ProductWrapper(Products__c producttemp,map<string,list<products__c>> configlist,boolean selectedValue,string selectedConfig,string qty) 
        {
            selected = selectedValue;
            pro = producttemp;
            selectedoption = selectedConfig;
            quantity = qty;
            if(selected == true & (quantity == '0' | quantity == null))
                quantity = '1';
            
            System.debug('producttemp : '+producttemp);
            if(producttemp != null) {
                System.debug('producttemp Id : '+producttemp.id);
                if(configlist.containsKey(producttemp.id))
                {
                    configpro = new List<selectoption>();
                    configSalesPrice = new map<string,decimal>();
                    configSpecialPrice = new map<string,decimal>();
                    configRegularPrice = new map<string,decimal>();
                    
                    System.debug('configlist.get(producttemp.id) : '+configlist.get(producttemp.id).size());
                    if(configlist.get(producttemp.id).size() > 0) {
                        for(products__c pro: configlist.get(producttemp.id))
                        {   
                            if(selectedoption==null)     
                                selectedoption=pro.id;
                            configpro.add(new selectOption(pro.id,pro.name));  
                            configSalesPrice.put(pro.id,pro.Sales_Price__c);
                            configSpecialPrice.put(pro.id,pro.Special_Price_Hidden__c);
                            configRegularPrice.put(pro.id,pro.Regular_Price__c);
                        }
                        System.debug('configpro : '+configpro);
                    }
                    else {
                        configpro.add(new selectOption(producttemp.id,'')); 
                        configSalesPrice.put(producttemp.id,producttemp.Sales_Price__c);
                        configSpecialPrice.put(producttemp.id,producttemp.Special_Price_Hidden__c);
                        configRegularPrice.put(producttemp.id,producttemp.Regular_Price__c);
                        System.debug('configpro : '+configpro);
                    }
                }
            }
        }
    }
    
    public class insertProductsWrapper
    {
        string quantity{set;get;}
        string selectedConfigProduct{set;get;}
        
        public insertProductsWrapper(decimal qty, string selectValue)
        {
            quantity=string.valueOf(qty);
            selectedConfigProduct=selectValue;
        }
    }
    
    public class BundleItemWrapper 
    {
        public Bundle_Item__c bundleitem{get;set;}
        public List<selectoption> bundelpro{get;set;}
        public string selectedBundeloption{get;set;}
        public boolean selected{set;get;}
        public string quantity{set;get;}
        
        public map<string,decimal> configTirePrice{set;get;}
        
        public BundleItemWrapper(Bundle_Item__c bundleObj,map<string,list<products__c>> configlist,boolean selectedValue,string qty,string selectedConfig) 
        {
            selected=selectedValue;
            bundleitem = bundleObj;
            bundelpro =new List<selectoption>();
            configTirePrice=new map<string,decimal>();
            quantity = qty;
            if(selected==true &( quantity=='0' | quantity==null))
                quantity='1';
            selectedBundeloption=selectedConfig;
            system.debug('selectedConfig: '+selectedConfig);
            if(configlist.containsKey(bundleObj.Product__c)) {
                for(products__c pro: configlist.get(bundleObj.Product__c))
                {                       
                    if(selectedBundeloption==null)     
                        selectedBundeloption=pro.id;
                    bundelpro.add(new selectOption(pro.id,pro.name));
                    configTirePrice.put(pro.id,pro.Tier_Price_For_Bundle__c);
                }
            }
        }
    }
    
    public class SelectedProductWrapper {
        public SO_Line_Items__c soi{get;set;}
        public Boolean checked{get; set;}
        public string selectedoption{get;set;}
        public List<selectoption> configpro{get; set;}
        public list<SO_Line_Items__c> bundelItems{set;get;}
        
        public SelectedProductWrapper(SO_Line_Items__c Soitemp,list<SO_Line_Items__c> bundelItemsTemp, List<selectoption> config)  {
            soi = Soitemp;
            checked = true;
            bundelItems=bundelItemsTemp;
            configpro=config;
        }
    }
    
    public void voidPayments(list<transactionWrapper> voidTransactionsList) {
        AuthorizeDotNetFunctions authorizedotnetVar=new AuthorizeDotNetFunctions();
        AuthorizeDotNetResponse responseObject=new AuthorizeDotNetResponse();
        try {
            for(transactionWrapper transactionWrapperItem:voidTransactionsList) {
                responseObject=authorizedotnetVar.voidTransaction(transactionWrapperItem.customerprofileID,transactionWrapperItem.paymentProfileID,transactionWrapperItem.authTransctionID, transactionWrapperItem.SOcreatedDate, transactionWrapperItem.SOoldAccount);
            }
        } catch(Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public boolean insertPaymentMethod(list<Payment_Method__c> paymentMethods,Sales_Order__c SalesorderObject)
    {
        boolean isValidPayment=false;
        list<transactionWrapper> VoidtransactionWrapperList=new list<transactionWrapper>(); 
		integer count=0;
		String authorizeNetProfileID;
        try
        {
            /* ***********Input Data - Start******************* */
            string paymentRecordtypeID =Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card').getRecordTypeId();
            //string paymentRecordtypeIDt =Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card').getRecordTypeId();
			Sales_Order__c SOObject=[SELECT createddate, Authdotnetoldaccount__c, Magento_order_No__c, id,name,Customer_Name__c,
									Customer_Name__r.Authorize_net_Profile_ID__c,email__c,Discount_Amount_Total__c,Grand_Total__c,Shipping_Handle__c,Sub_Total__c,
									TaxAmount__c,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c, Total_Due__c, Total_Paid__c 
									FROM sales_order__c WHERE id = :SalesorderObject.id];
									// ,(SELECT Id, Payment_Method__r.Payment_Profile_ID__c FROM Transactions__r WHERE Payment_Method__r.RecordTypeId = :paymentRecordtypeID) 
            map<string,Payment_Method__c> paymentMethodMap=new map<string,Payment_Method__c>();
			for(Payment_Method__c  paymentMethodVar : [SELECT id, Customer_Profile_ID__c, Payment_Profile_ID__c, 
														(SELECT Id FROM Transactions__r WHERE Sales_Order__c = :SalesorderObject.id LIMIT 1)
														FROM Payment_Method__c 
														WHERE account__c = :SOObject.Customer_Name__c AND recordtypeid = :paymentRecordtypeID]) {

				paymentMethodMap.put(paymentMethodVar.Payment_Profile_ID__c, paymentMethodVar);
				
				if(String.isBlank(authorizeNetProfileID) && String.isNotBlank(paymentMethodVar.Customer_Profile_ID__c) && (paymentMethodVar.Transactions__r != null && paymentMethodVar.Transactions__r.size() > 0)) {
					authorizeNetProfileID = paymentMethodVar.Customer_Profile_ID__c;
				}
            }

            string orderNumber = SOObject.Magento_order_No__c != null && SOObject.Magento_order_No__c != '' ? SOObject.Magento_order_No__c : SOObject.Id;
            /* **************Input Data - End**************** */
            
            /* **************Authorize.net Variables - Start **************** */
            AuthorizeDotNetFunctions AuthorizeDotNetFunctionsObj;
            AuthorizeDotNetResponse responseObject;
            Map<string,Payment_Method__c> finalPaymentMethodsMap=new map<string,Payment_Method__c>();
            list<Transaction__c> finalTransactionList=new list<Transaction__c>(); // Direct Insert
            Map<string,Transaction__c> finalTransactionsMap=new map<string,Transaction__c>();
            account accObject;
            list<Task> taskList=new list<Task>();
            transactionWrapper transactionWrapperObject;
            /* **************Authorize.net Variables - End**************** */
            //For 
            for(Payment_Method__c paymentMethodVarobj: paymentMethods)
            {
                count=count+1;
                AuthorizeDotNetFunctionsObj=new AuthorizeDotNetFunctions();
                responseObject=new AuthorizeDotNetResponse();
                // transactionWrapperObject=new transactionWrapper();
                
                string expirationDate;
                if (paymentMethodVarobj.id == null){
	                expirationDate = paymentMethodVarobj.Expiration_Year__c+'/'+  paymentMethodVarobj.Expiration_Month__c.substringBefore('-');
                }

				//IF customer Profile Exsist in Salesforce
				
                if(String.isNotBlank(authorizeNetProfileID) ) {
                	string customerPaymentProfileId;
                    //Payment Profile Creation
                    if (paymentMethodVarobj.id == null) {
                    	AuthorizeDotNetFunctionsObj.createCustomerPaymentProfile(authorizeNetProfileID, SOObject.Bill_To__c, '', SOObject.Billing_Street__c, SOObject.Billing_City__c, SOObject.Billing_State__c, SOObject.Billing_ZipCode__c, 'US', paymentMethodVarobj.Credit_Card_Number__c ,expirationDate, paymentMethodVarobj.Card_Verification_Number__c);
                    	customerPaymentProfileId = AuthorizeDotNetFunctionsObj.customerPaymentProfileId;
                    } else {
                    	customerPaymentProfileId = paymentMethodVarobj.Payment_Profile_ID__c;
                    }
                    

                    if(customerPaymentProfileId != null)
                    {
                        responseObject=AuthorizeDotNetFunctionsObj.createCustomerProfileAuthOnlyTransaction(authorizeNetProfileID, customerPaymentProfileId, string.valueOf(paymentMethodVarobj.Amount__c), '0.00', orderNumber);//, SOObject.createddate);
                        if(responseObject != null && responseObject.transactionId !=null)
                        {
                            VoidtransactionWrapperList.add(new transactionWrapper(authorizeNetProfileID,customerPaymentProfileId,responseObject.transactionId, SOObject.createddate, SOObject.Authdotnetoldaccount__c));      
                        }
                        //If Payment Profile Exsist in Salesforce
                        if(paymentMethodMap != null && paymentMethodMap.containsKey(customerPaymentProfileId))
                        {
                            //Auth Only Transaction 
                            if(responseObject !=null)
                            {
                                // This is a Direct Transaction because Payment profile Exsist in Saleforce
                                Transaction__c transactionObject=new Transaction__c();
                                transactionObject.Sales_Order__c=SOObject.Id;
                                transactionObject.Payment_Method__c=paymentMethodMap.get(customerPaymentProfileId).id;
                                transactionObject.Amount__c=paymentMethodVarobj.Amount__c;
                                transactionObject.TransactionId__c=responseObject.transactionId;
                                transactionObject.Trans_AVS_Response__c=responseObject.avsResponse;
                                transactionObject.Transaction_Type__c='AUTH_ONLY';
                                transactionObject.Transaction_Response__c=responseObject.responseReasonText;
                                transactionObject.Status__c='Authorized';
                                
                                finalTransactionList.add(transactionObject);
                            }
                            else
                            {
                                system.debug('If Payment Profile Exsist in Salesforce -responseObject');
                            }
                        }
                        else
                        {
                            if(responseObject != null)
                            {
                                Payment_Method__c payMethodObject=new Payment_Method__c();
                                payMethodObject.Credit_Card_Number__c=paymentMethodVarobj.Credit_Card_Number__c;
                                payMethodObject.Expiration_Month__c=paymentMethodVarobj.Expiration_Month__c;
                                payMethodObject.Expiration_Year__c=paymentMethodVarobj.Expiration_Year__c;
                                payMethodObject.Card_Type__c=paymentMethodVarobj.Card_Type__c;
                                payMethodObject.Payment_Profile_ID__c=AuthorizeDotNetFunctionsObj.customerPaymentProfileId;
                                payMethodObject.Account__c   =  SOObject.Customer_Name__c;
                                payMethodObject.RecordTypeId=paymentRecordtypeID;
                                //add to final List
                                finalPaymentMethodsMap.put(paymentMethodVarobj.Credit_Card_Number__c,payMethodObject);
                                
                                Transaction__c transactionObject=new Transaction__c();
                                transactionObject.Sales_Order__c=SOObject.Id;
                                transactionObject.TransactionId__c=responseObject.transactionId;
                                transactionObject.Amount__c=paymentMethodVarobj.Amount__c;
                                transactionObject.Trans_AVS_Response__c=responseObject.avsResponse;
                                transactionObject.Transaction_Type__c='AUTH_ONLY';
                                transactionObject.Transaction_Response__c=responseObject.responseReasonText;
                                transactionObject.Status__c='Authorized';
                                
                                finalTransactionsMap.put(paymentMethodVarobj.Credit_Card_Number__c, transactionObject);
                                
                            }
                            else
                            {
                                system.debug('If Payment Profile Doesn\'t Exsist in Salesforce -responseObject');
                            }
                        }
                    }
                    else
                    {
                        system.debug('IF customer Profile Exsist in Salesforce -AuthorizeDotNetFunctionsObj');
                    }
                }
                else
                {
                    //AuthorizeDotNetFunctionsObj.createCustomerPaymentProfile(SOObject.Customer_Name__r.Authorize_net_Profile_ID__c, SOObject.Bill_To__c, '', SOObject.Billing_Street__c, SOObject.Billing_City__c, SOObject.Billing_State__c, SOObject.Billing_ZipCode__c, 'US', paymentMethodVarobj.Credit_Card_Number__c ,expirationDate, paymentMethodVarobj.Card_Verification_Number__c);
                    AuthorizeDotNetFunctionsObj.createCustomerAndPaymentProfiles(SOObject.Email__c, SOObject.Bill_To__c, '', SOObject.Billing_Street__c, SOObject.Billing_City__c, SOObject.Billing_State__c, SOObject.Billing_ZipCode__c, 'US', paymentMethodVarobj.Credit_Card_Number__c ,expirationDate, paymentMethodVarobj.Card_Verification_Number__c);
                    accObject=new account(id=SOObject.Customer_Name__c, Authorize_net_Profile_ID__c = AuthorizeDotNetFunctionsObj.customerProfileId);
                    
                    if(AuthorizeDotNetFunctionsObj.isExistingCustomerProfile)
                    {
                        AuthorizeDotNetFunctionsObj.createCustomerPaymentProfile(AuthorizeDotNetFunctionsObj.customerProfileId, SOObject.Bill_To__c, '', SOObject.Billing_Street__c, SOObject.Billing_City__c, SOObject.Billing_State__c, SOObject.Billing_ZipCode__c, 'US', paymentMethodVarobj.Credit_Card_Number__c ,expirationDate, paymentMethodVarobj.Card_Verification_Number__c);
                    }
                    
                    if(AuthorizeDotNetFunctionsObj != null)
                    {
                        responseObject=AuthorizeDotNetFunctionsObj.createCustomerProfileAuthOnlyTransaction(AuthorizeDotNetFunctionsObj.customerProfileId, AuthorizeDotNetFunctionsObj.customerPaymentProfileId, string.valueOf(paymentMethodVarobj.Amount__c), '0.00', orderNumber);//, SOObject.createddate);
                        if(responseObject != null && responseObject.transactionId != null) {
                            VoidtransactionWrapperList.add(new transactionWrapper(AuthorizeDotNetFunctionsObj.customerProfileId,AuthorizeDotNetFunctionsObj.customerPaymentProfileId,responseObject.transactionId, SOObject.createddate, SOObject.Authdotnetoldaccount__c));      
                        }
                        
                        Payment_Method__c payMethodObject=new Payment_Method__c();
                        payMethodObject.Credit_Card_Number__c=paymentMethodVarobj.Credit_Card_Number__c;
                        payMethodObject.Expiration_Month__c=paymentMethodVarobj.Expiration_Month__c;
                        payMethodObject.Expiration_Year__c=paymentMethodVarobj.Expiration_Year__c;
                        payMethodObject.Card_Type__c=paymentMethodVarobj.Card_Type__c;
                        payMethodObject.Payment_Profile_ID__c=AuthorizeDotNetFunctionsObj.customerPaymentProfileId;
                        payMethodObject.Account__c   =  SOObject.Customer_Name__c;
                        payMethodObject.RecordTypeId=paymentRecordtypeID;
                        //add to final List
                        finalPaymentMethodsMap.put(paymentMethodVarobj.Credit_Card_Number__c,payMethodObject);
                        
                        Transaction__c transactionObject=new Transaction__c();
                        transactionObject.Sales_Order__c=SOObject.Id;
                        transactionObject.TransactionId__c=responseObject.transactionId;
                        transactionObject.Amount__c=paymentMethodVarobj.Amount__c;
                        transactionObject.Trans_AVS_Response__c=responseObject.avsResponse;
                        transactionObject.Transaction_Type__c='AUTH_ONLY';
                        transactionObject.Transaction_Response__c=responseObject.responseReasonText;
                        transactionObject.Status__c='Authorized';
                        
                        finalTransactionsMap.put(paymentMethodVarobj.Credit_Card_Number__c, transactionObject);
                    } else {
                        system.debug('IF customer Profile doesn\'t Exsist in Salesforce -AuthorizeDotNetFunctionsObj');
                    }
                    
                }
                if(responseObject != null && responseObject.avsResponse != null)
                {
                    if(responseObject.responseCode == '1')
                    {
                        
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'card -'+count+' '+responseObject.responseReasonText));
                        
                        Task taskVar=new Task();
                        taskVar.WhatId=SOObject.id;
                        taskVar.Status='Completed';
                        taskVar.Subject = 'Order Amount('+paymentMethodVarobj.Amount__c+') Authorized Successfully ';
                        taskVar.ActivityDate=system.today();
                        tasklist.add(taskVar);
                    }
                    else if(responseObject.responseCode=='2')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'card -'+count+' '+responseObject.responseReasonText));
                    }
                    else if(responseObject.responseCode=='3')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'card -'+count+' '+responseObject.responseReasonText));
                    }
                    else if(responseObject.responseCode=='4')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'card -'+count+' '+responseObject.responseReasonText));
                    } 
                }
            }    
            
            insert tasklist;
            
            if(finalTransactionList != null) {
                insert finalTransactionList;
            }
            
            if(accobject != null && accobject.id != null) {
                update accObject;
            }
            
            if(!finalPaymentMethodsMap.isEmpty())
            {
                for(Payment_Method__c paymentItem:finalPaymentMethodsMap.values())
                {
                    insert paymentItem;
                    
                    IF(finalPaymentMethodsMap.containsKey(paymentItem.Credit_Card_Number__c))
                    {
                        finalPaymentMethodsMap.get(paymentItem.Credit_Card_Number__c).Id=  paymentItem.id; 
                    }
                } 
            }

            list<Transaction__c> translist=new list<Transaction__c>();
            for(string transactionkey:finalTransactionsMap.keySet())
            {
                Transaction__c transactionItem=new Transaction__c();
                transactionItem=finalTransactionsMap.get(transactionkey);
                if(finalPaymentMethodsMap.containsKey(transactionkey))
                {
                    transactionItem.Payment_Method__c=finalPaymentMethodsMap.get(transactionkey).id;
                    translist.add(transactionItem);
                }
            }

            if(translist != null)
            {
                insert translist;  
            }
            
            isValidPayment=true;
            return isValidPayment;
        }
        catch(AuthorizeDotNetException ae)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Card -'+count+': Please enter Valid Card Information-('+ae.getMessage()+')'));
            system.debug('Catch'+ae.getLineNumber()+'--- '+ae.getMessage()+'---------'+ae.getCause());
            isValidPayment = false;
            if(VoidtransactionWrapperList != null && VoidtransactionWrapperList.size()>0)
            {
                voidPayments(VoidtransactionWrapperList);  
            }
            
            return false;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Card - '+count+' : Please enter Valid Card Information-('+e.getMessage()+ '-' + e.getlinenumber()+')')); 
            system.debug('Catch'+e.getLineNumber()+'--- '+e.getMessage()+'---------'+e.getCause());
            isValidPayment=false;
            if(VoidtransactionWrapperList != null && VoidtransactionWrapperList.size()>0)
            {
                voidPayments(VoidtransactionWrapperList);  
            }
            return isValidPayment;
        }
        //return isValidPayment;
    }
    
    public PageReference goTosalesorderlist()
    {
        pagereference pr;  
        try
        { 
            Schema.DescribeSObjectResult objectSchemaData = Sales_Order__c.sObjectType.getDescribe();
            String keyPrefix =  '/'+objectSchemaData.getKeyPrefix()+'/o';
            pr=new pagereference(keyPrefix);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return pr;
    }
    
    public class transactionWrapper
    {
        public string customerprofileID;
        public string paymentProfileID;
        public string authTransctionID;
        public datetime SOcreatedDate;
        public boolean SOoldAccount;
        
        
        public transactionWrapper(string inputCustomerprofileID,string inputPaymentProfileID,string inputAuthTransctionID,datetime inputSOcreatedDate,boolean inputSOoldAccount)
        {
            customerprofileID=inputCustomerprofileID;
            paymentProfileID=inputPaymentProfileID;
            authTransctionID= inputAuthTransctionID;
            SOcreatedDate= inputSOcreatedDate;
            SOoldAccount= inputSOoldAccount;
        }
    }

}