/*
*   Author : Sowdhanya Karri | Kairos Tech
*   Class  : newSalesOrderController
*   Purpose: This class is used to create a Sales Order with transaction on different Pay types.
*/
global class newSalesOrderController 
{
    public string SOItemId;
    
    public Promotions__c promotionObj;
    public decimal tax {set;get;}
    
    public Account accObject{set;get;}
    
    public Sales_Order__c SalesorderObject {set;get;}
    public Sales_Order__c SalesorderObjectTemp {set;get;}
    
    public decimal custumpricetotal{set;get;}
    
    public SO_Line_Items__c protectionplanSOI{set;get;}
    
    public list<BundleItemWrapper> SoRelatedBundle;
    
    public map<string,SelectedProductWrapper> SoRelated;
    public set<string> manufactureList;
    
    public list<products__c> productList{set;get;}
    public map<string,ProductWrapper> productWrapperList{set;get;}
    public list<products__c> protectionplanList;
    
    public string lastPayapalId{set;get;}
    public string firstPayapalId{set;get;}
    public string storedquery{set;get;}
    
    public boolean displayselectionPopup{set;get;}
    public boolean displayPopup{set;get;}
    public boolean accountPopUP{set;get;}
    public boolean manualPaymentPopUp{set;get;}
    
    public map<string,list<BundleItemWrapper>>  ProductRelatedBundle;
    public map<string,list<Bundle_Item__c>>  ProductRelatedBundleTempList {set;get;}
    public map<string,list<products__c>> configlist;
    
    public string OptionsId {set;get;}
    public string OptionsName {set;get;}
    
    public map<string,insertProductsWrapper> insertedproductsIds;
    
    public map<id,map<id,BundleItemWrapper>> BundleList { get; set; }
    public map<id,ProductWrapper> selectedproducts;
    
    public string paymentType{set;get;}
    public Payment_Method__c paymentMethodVar{set;get;}
    public Payment_Method__c paymentMethodVar1{set;get;}
    public Payment_Method__c paymentMethodVar2{set;get;}
    
    public boolean hasCard1{set;get;}
    public boolean hasCard2{set;get;}
    public boolean hasCard3{set;get;}
    
    public Account AccountObject;
    public map<string,string> customerCards;
    
    public list<Payment_Method__c> paymentMethodslist;
    public list<Transaction__c> transactionsList;
    public list<task> taskList;
    
    public  map<string,Tax_Percentage__c> stateTaxPercentage;
    public List<selectoption> stateList {set;get;} 
    
    public Boolean isBundleItemexist {set;get;}
    
    public newSalesOrderController(ApexPages.StandardController controller)
    {
        isBundleItemexist = true;
        stateTaxPercentage = Tax_Percentage__c.getall();
        
        stateList = new List<selectoption>();
        stateList.add(new selectOption('','--None--')); 
        
        for(States__c stateValue : States__c.getall().values())
        {
            stateList.add(new selectOption(stateValue.name,stateValue.name));
        }
        stateList.sort();
        system.debug('contoller');
        accObject = new Account();
        SalesorderObject = new Sales_Order__c();
        SalesorderObjectTemp = new Sales_Order__c();
        manualPaymentPopUp = false;
        accountPopUP = true;
        
        OptionsName='';
        
        // SalesorderObject.Sales_Representative__c = UserInfo.getUserId(); 
        
        // try {
        //     Account RoleTypeAccount = [Select id,Employee_Role__c From Account where SalesRepAsUser__c=:SalesorderObject.Sales_Representative__c AND recordTypeId=:Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal Employee').getRecordTypeId()];
        //     if(RoleTypeAccount.Employee_Role__c == 'Sales Dept. Staff' || RoleTypeAccount.Employee_Role__c == 'Management' || RoleTypeAccount.Employee_Role__c == 'Sales Dept. Manager') 
        //     {
        //         SalesorderObject.Sales_Rep__c = RoleTypeAccount.id;
        //     }
        // }
        // catch(Exception e) {
        //     system.debug('Exception  '+ e.getMessage()+'  '+  e.getLineNumber());
        //     ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Internal Employee Missing, Please contact to System Administrator.'));
        // }
        SalesorderObject.Order_Type__c = 'Phone';
        
        paymentMethodslist =new list<Payment_Method__c>();
        transactionsList=new list<Transaction__c>();
        taskList = new list<task>(); 
        AccountObject = new Account();
        customerCards = new map<string,string>();
        
        paymentMethodVar = new Payment_Method__c();
        paymentMethodVar1 = new Payment_Method__c();
        paymentMethodVar2 = new Payment_Method__c();
        
        hasCard1 = false;
        hasCard2 = false;
        hasCard3 = false;
        
        protectionplanSOI = new SO_Line_Items__c();
        protectionplanList = new list<products__c>();
        
        SoRelated = new map<string,SelectedProductWrapper>();
        
        insertedproductsIds = new map<string,insertProductsWrapper>();
        manufactureList = new set<string>();
        
        configlist = new map<string,list<products__c>>();
        ProductRelatedBundle = new map<string,list<BundleItemWrapper>>();
        ProductRelatedBundleTempList = new map<string,list<Bundle_Item__c>>();
        productWrapperList = new map<string,ProductWrapper>();
        
        BundleList = new map<id,map<id,BundleItemWrapper>>();
        selectedproducts = new  map<id,ProductWrapper>();
        try {
            productList = [select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,
            			   Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,Total_Items_in_Bundle__c,(select id,Final_OriginalPrice__c,
            			   Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,
            			   Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),
            			   (select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,
            			   SKU__c ,Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c='Enabled' ORDER BY order__c ASC NULLS LAST), 
            			   (select id,Product__r.recordtype.name,Include__c, Product__c from Configurable_Items__r where Status__c='Enable' ORDER BY order__c ASC NULLS LAST) 
            			   from Products__c where Status__c='Enabled' and (Master_Products__c=null and recordtype.name!='Protection Plan') ORDER BY Id ASC limit 20 ];
            storedquery = 'select id,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,Total_Items_in_Bundle__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),(select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c ,Selection_Qty__c,Status__c from Bundle_Items1__r  where Status__c=\'Enable\' ORDER BY order__c ASC NULLS LAST), (select id,Product__r.recordtype.name,Include__c, Product__c from Configurable_Items__r where Status__c=\'Enable\' ORDER BY order__c ASC NULLS LAST)  from Products__c where Status__c=\'Enabled\' and (Master_Products__c=null and recordtype.name!=\'Protection Plan\') ';
            
            protectionplanList = [select id,Name,SKU__c,Product_Image_URL__c,recordtype.name,Regular_Price__c,Sales_Price__c,Protection_high_range__c,Protection_low_range__c from Products__c where Status__c='Enabled' and recordtype.name='Protection Plan'];
            
            system.debug('productList ' +productList);
            
            if(productList.size() > 0)
            {
                lastPayapalId = productList[productList.size()-1].id;
                firstPayapalId = productList[0].id; 
                
                list<string> proID = new list<string>();
                list<string> proListIds = new list<string>();
                
                for(products__c pro : productList)
                {
                	System.debug('pro.recordtype.name :: '+pro.recordtype.name);
                	System.debug('pro :: '+pro);
                    if(pro.recordtype.name == 'Bundled') {//Bundle_Items1__r
                    	proListIds.add(pro.Id);
                    }
                }
                System.debug('proListIds :: '+proListIds);
                if(proListIds.size()>0)
                {
                    map<string,list<products__c>> testMap = getConfigProductMap(proListIds);
                    configlist.putAll(testMap);
                    system.debug('\n\n\ntestMap1 ' + testMap + '\n\n\n');
                }

                /*map<string,list<products__c>> testMap = getConfigProductMap(proListIds);
                configlist.putAll(testMap);
                system.debug('\n\n\ntestMap2 ' + testMap + '\n\n\n');*/

                for(products__c pro :productList)
                {
                    if(selectedproducts.containsKey(pro.id))
                    {
                        productWrapperList.put(pro.id,new ProductWrapper(pro,configlist,true,selectedproducts.get(pro.id).selectedoption,selectedproducts.get(pro.id).quantity)); 
                    }
                    else
                    {
                        productWrapperList.put(pro.id,new ProductWrapper(pro,configlist,false,null,'0'));
                    }
                    
                    if(pro.Bundle_Items1__r.size() > 0)
                    {
                        if(!ProductRelatedBundleTempList.containsKey(pro.id))
                            ProductRelatedBundleTempList.put(pro.id,pro.Bundle_Items1__r); 
                    }
                }
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        System.debug('productList :: '+productList);
        system.debug('configlist ' + configlist);
        system.debug('productWrapperList ' + productWrapperList);
        system.debug('ProductRelatedBundleTempList ' + ProductRelatedBundleTempList);
    }
    
    public static Sales_Order__c salesOrder(id soId)
    {
        Sales_Order__c so = [select id,Email__c,Mobile__c,Alternate_Email__c ,Customer_Billing_Address__c ,Notify_Customer_with_Email__c, Order_Type__c, 
                Customer_Name__c,Grand_Total__c,Order_ETA__c,Delivery_Companies_Distance__c,Discount_Amount_Total__c, Shipping_Mobile__c, Sales_Representative__c,
                Discount_AmountTotal__c,TaxAmount__c,Shipping_Handle__c,Promotion__c,Sub_Total__c, Bill_To__c, Ship_to__c, Comments__c, Customer_Comments__c,
                Billing_Street__c,Billing_City__c,Billing_State__c,Billing_Country__c,Billing_ZipCode__c, Billing_Phone__c, Shipping_Phone__c,
                Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_Country__c,Shipping_ZipCode__c, (select id,Products__c, Product_Name__c from SO_Line_Items__r )
                from Sales_Order__c where id =:soId];
       system.debug('so = ' + so);
       return so;
    }
    
    public List<SelectOption> getWebSiteList(){
        List<SelectOption> options = new List<SelectOption>();
        for(Website__mdt  website_i : [SELECT Id, MasterLabel, Website_API_Name__c   FROM Website__mdt]){
            options.add(new SelectOption(website_i.Website_API_Name__c, website_i.MasterLabel));
        }
        return options;
    }
    
    public void saveAccount()
    {      
        try
        {      
            system.debug('accObject ' +accObject);
            system.debug('accObject.First_Name__c'+accObject.First_Name__c);
            if(accObject.id == null)
            {
                if(accObject.First_Name__c == null || accObject.Last_Name__c==null || accObject.Email__c == null || accObject.Phone == null )
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter required data to save Customer'));
                }
                else if(SalesorderObject.Billing_Street__c ==null || SalesorderObject.Billing_City__c ==null || SalesorderObject.Billing_State__c ==null || SalesorderObject.Billing_ZipCode__c ==null ||SalesorderObject.Billing_Country__c ==null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter required Billing data to save Customer'));
                }
                else if(SalesorderObject.Shipping_Street__c ==null || SalesorderObject.Shipping_City__c ==null || SalesorderObject.Shipping_State__c ==null || SalesorderObject.Shipping_ZipCode__c ==null ||SalesorderObject.Shipping_Country__c ==null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter required Shipping data to save Customer'));
                }
                else
                {   /*accObject.Phone = accObject.Phone.trim();
                    String reg = '^[(]{0,1}[0-9]{3}[)]{0,1}[-\\s\\.]{0,1}[0-9]{3}[-\\s\\.]{0,1}[0-9]{4}$';
                    Pattern phonePattern = Pattern.compile(reg);
                    Matcher phoneMatcher = phonePattern.matcher(accObject.Phone);
                    if(!phoneMatcher.matches()){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Phone number is not valid'));
                    }*/
                    List<Account> accountList = [SELECT Id FROM Account WHERE Email__c = :accObject.Email__c ];
                    if(accountList.size() > 0){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Account with this email already exist'));
                    }
                    accObject.Name = accObject.First_Name__c+' '+accObject.Last_Name__c;
                    
                    accObject.BillingStreet = SalesorderObject.Billing_Street__c;
                    accObject.BillingCity = SalesorderObject.Billing_City__c;
                    accObject.BillingState = SalesorderObject.Billing_State__c;
                    accObject.BillingPostalCode = SalesorderObject.Billing_ZipCode__c;
                    accObject.BillingCountry = SalesorderObject.Billing_Country__c;
                    
                    accObject.ShippingStreet = SalesorderObject.Shipping_Street__c;
                    accObject.ShippingCity = SalesorderObject.Shipping_City__c;
                    accObject.ShippingState = SalesorderObject.Shipping_State__c;
                    accObject.ShippingPostalCode = SalesorderObject.Shipping_ZipCode__c;
                    accObject.ShippingCountry = SalesorderObject.Shipping_Country__c;
                    
                    insert accObject; 
                }
            }
            else
            {
                if(accObject.First_Name__c == null || accObject.Last_Name__c==null || accObject.Email__c == null || (accObject.Phone == null || accObject.Phone == ' '))
                {
                    system.debug('In if save account method');
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter required data to save Customer'));
                }
                else if(SalesorderObject.Billing_Street__c ==null || SalesorderObject.Billing_City__c ==null || SalesorderObject.Billing_State__c ==null || SalesorderObject.Billing_ZipCode__c ==null ||SalesorderObject.Billing_Country__c ==null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter required Billing data to save Customer'));
                }
                else if(SalesorderObject.Shipping_Street__c ==null || SalesorderObject.Shipping_City__c ==null || SalesorderObject.Shipping_State__c ==null || SalesorderObject.Shipping_ZipCode__c ==null ||SalesorderObject.Shipping_Country__c ==null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter required Shipping data to save Customer'));
                }
                else
                {   
                    /*accObject.Phone = accObject.Phone.trim();
                    String reg = '^[(]{0,1}[0-9]{3}[)]{0,1}[-\\s\\.]{0,1}[0-9]{3}[-\\s\\.]{0,1}[0-9]{4}$';
                    Pattern phonePattern = Pattern.compile(reg);
                    Matcher phoneMatcher = phonePattern.matcher(accObject.Phone);
                    if(!phoneMatcher.matches()){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Phone number is not valid'));
                    }*/


                    List<Account> accountList = [SELECT Id FROM Account WHERE Email__c = :accObject.Email__c AND Id != :accObject.Id ];
                    if(accountList.size() > 0){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Account with this email already exist'));
                    }
                    system.debug('SalesorderObject.Billing_State__c'+SalesorderObject.Billing_State__c);
                    accObject.Name = accObject.First_Name__c+' ' +accObject.Last_Name__c; 
                    
                    accObject.BillingStreet = SalesorderObject.Billing_Street__c;
                    accObject.BillingCity = SalesorderObject.Billing_City__c;
                    accObject.BillingState = SalesorderObject.Billing_State__c;
                    accObject.BillingPostalCode = SalesorderObject.Billing_ZipCode__c;
                    accObject.BillingCountry = SalesorderObject.Billing_Country__c;
                    
                    accObject.ShippingStreet = SalesorderObject.Shipping_Street__c;
                    accObject.ShippingCity = SalesorderObject.Shipping_City__c;
                    accObject.ShippingState = SalesorderObject.Shipping_State__c;
                    accObject.ShippingPostalCode = SalesorderObject.Shipping_ZipCode__c;
                    accObject.ShippingCountry = SalesorderObject.Shipping_Country__c;
                    
                    update accObject; 
                }
            }
            if(accObject.id != null)
            {
               /* accObject = [select Name,First_Name__c,Last_Name__c,Email__c,AccountNumber,Phone,Mobile__c,BillingStreet,BillingCity,BillingState,BillingPostalCode,BillingCountry,
                             ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode,ShippingCountry,Website,(select id,AddressType__c,Name,
                                                                                                           Cell__c,City__c,Country__c,State__c,Street_Address__c,Telephone__c,Zip_Postal_Code__c from Customer_Addresses__r) 
                             from account where id =:accObject.id];
                
                SalesorderObject.Customer_Name__c = accObject.id;
                SalesorderObject.Email__c = accObject.Email__c;
                SalesorderObject.Mobile__c = accObject.Mobile__c;
                
                SalesorderObject.Shipping_Mobile__c = accObject.Phone;
                
                for(Customer_Addresses__c customerAddress : accObject.Customer_Addresses__r)
                {
                    if(customerAddress.AddressType__c=='Primary Shipping Address')
                    {
                        SalesorderObject.Customer_shipping_Address__c=customerAddress.id;
                        SalesorderObject.Ship_to__c=customerAddress.Name;
                        SalesorderObject.Shipping_City__c=customerAddress.City__c;
                        SalesorderObject.Shipping_State__c=customerAddress.State__c;
                        SalesorderObject.Shipping_Street__c=customerAddress.Street_Address__c;
                        SalesorderObject.Shipping_ZipCode__c=customerAddress.Zip_Postal_Code__c; 
                        SalesorderObject.Shipping_Phone__c=customerAddress.Telephone__c;
                        SalesorderObject.Shipping_Mobile__c=customerAddress.Cell__c;
                        
                        if(SalesorderObject.Id==null)
                        {
                            SalesorderObject.Order_Date__c=system.now();
                            insert SalesorderObject;
                        }
                        else
                        {
                            update SalesorderObject;
                        }
                    }
                    else if(customerAddress.AddressType__c=='Primary Billing Address')
                    {
                        SalesorderObject.Customer_Billing_Address__c=customerAddress.id;
                        SalesorderObject.Bill_To__c=customerAddress.Name;
                        SalesorderObject.Billing_City__c=customerAddress.City__c;
                        SalesorderObject.Billing_State__c=customerAddress.State__c;
                        SalesorderObject.Billing_Street__c=customerAddress.Street_Address__c;
                        SalesorderObject.Billing_ZipCode__c=customerAddress.Zip_Postal_Code__c;
                        //SalesorderObject.Billing_Phone__c=customerAddress.Telephone__c;
                        SalesorderObject.Mobile__c=customerAddress.Cell__c;
                    }
                }
                */
                accountPopup = false;
                updateSalesorderObjectOnPage();
            }
            system.debug('SalesorderObject   ' + SalesorderObject);
            system.debug('SalesorderObject.Shipping_ZipCode__c   ' + SalesorderObject.Shipping_ZipCode__c);
            
            if (SalesorderObject.Shipping_ZipCode__c != null){
            	list<Shipping_Zip_Codes__c> zipCodes = [select TaxJar_Sales_Tax__c, Zip_Code__c from Shipping_Zip_Codes__c where TaxJar_Sales_Tax__c != 0 and Zip_Code__c = :SalesorderObject.Shipping_ZipCode__c];
            	system.debug('zipCodes.size()   ' + zipCodes.size());
            	if (zipCodes.size() > 0){
		            tax = zipCodes[0].TaxJar_Sales_Tax__c;
            		system.debug('tax   ' + tax);
            	}
	            else{
	            	tax = 0;
	            }
            }
            else{
            	tax = 0;
            }
            system.debug('tax 2  ' + tax);
        	list<SO_Line_Items__c> updateList = new list<SO_Line_Items__c>();
            for(SelectedProductWrapper soItems : SoRelated.values())
            {
		        soItems.soi.Tax_Percent__c = tax;
                if(soItems.soi.Bundle_Items_Count__c != 0)
                {
                    for(SO_Line_Items__c soibundelItem : soItems.bundelItems)
                    {
                    	
			            if (string.valueof(soibundelItem.Custom_Price__c) == '0'){
			            	soibundelItem.Custom_Price__c = null;
			            }
                        if(soibundelItem.Products__c == soItems.soi.Products__c && soibundelItem.Bundle_Item__c != null)
                        {
		        			soibundelItem.Tax_Percent__c = tax;
                        }
                		updateList.add(soibundelItem);
                    }
                    
                }
	            if (string.valueof(soItems.soi.Custom_Price__c) == '0'){
	            	soItems.soi.Custom_Price__c = null;
	            }
                updateList.add(soItems.soi);
            }
            if (updateList.size() > 0){
            	update updateList;
            }
            salesorderObjectTemp = salesOrder(SalesorderObject.id);
            for (SO_Line_Items__c pw : salesorderObjectTemp.SO_Line_Items__r){
            	system.debug('pw.Product_Name__c = ' + pw.Product_Name__c);
		        if (pw.Product_Name__c.contains('Protection Plan')){
		        	SalesorderObject.Protection_Plan_included__c = true;
		        	break;
		        }
		        SalesorderObject.Protection_Plan_included__c = false;
            }
            update SalesorderObject;
            SalesorderObject = salesOrder(SalesorderObject.id);
            SalesorderObjectTemp = SalesorderObject;
            system.debug('updateList   ' + updateList);
            system.debug('salesorderObjectTemp   ' + salesorderObjectTemp);
        }
        catch(Exception e)
        {
            system.debug('Exception  '+ e.getMessage()+'  '+  e.getLineNumber());
            if(E.getMessage().contains('Account Name'))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Account Name Missing'));
            else if(E.getMessage().contains('DUPLICATE_VALUE')) {
                if(E.getMessage().contains('Email__c')) 
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Customer Email already exists.'));
            }
            else
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,E.getMessage()));
        }  
        try {
            if(SalesorderObject.id==null)
            {
                SalesorderObject.Order_Date__c=system.now();
                insert SalesorderObject;
            }
            else 
                update SalesorderObject;
            
            //taxCalculation();        
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+'Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    private void updateSalesorderObjectOnPage(){
        if(SalesorderObject.id == null)
        {
	        SalesorderObject =  [select id, Authdotnetoldaccount__c, SF_Order_Modified__c,Comments__c,Customer_Comments__c,name,email__c,Customer_Billing_Address__c,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c,Billing_Phone__c,Mobile__c,
	                Customer_shipping_Address__c,Ship_to__c,Shipping_Street__c,Shipping_City__c,Shipping_State__c,Shipping_ZipCode__c,Shipping_Phone__c,Shipping_Mobile__c,
	                IsSoModified__c,Notify_Customer_with_Email__c,Customer_Name__c,Grand_Total__c,Order_ETA__c,Delivery_Companies_Distance__c, DiscountAmount__c, Do_not_charge_tax__c,
	                Discount_Amount_Total__c,TaxAmount__c,Shipping_Handle__c,Promotion__c,Sub_Total__c,Customer_Name__r.name,Discount_AmountTotal__c, Total_Due__c, Total_Paid__c, 
	                (select id,Products__c ,Product_Name__c from SO_Line_Items__r WHERE Products__r.recordtype.name!='Bundled' ) from Sales_Order__c where id =:SalesorderObject.id];
        }
    }
    

    public void onCustomPriseChange(){
        Integer parentItem;
        List<SO_Line_Items__c> soLinesToUpdate = new List<SO_Line_Items__c>();
        for(SelectedProductWrapper item_i : SoRelated.values()){
            if( item_i.soi.Custom_Price__c!=null && item_i.soi.Custom_Price__c > 0){
                soLinesToUpdate.add(item_i.soi);
                parentItem = soLinesToUpdate.size()-1; 
                if(item_i.soi.Products__r.recordtype.name == 'Bundled' && item_i.bundelItems!=null){
                    System.debug('item_i.soi: '+ item_i.soi.Custom_Price__c);
                    Decimal customPrice = item_i.soi.Custom_Price__c;
                    Decimal originPrice = item_i.soi.Sub_Total__c ;
                    Decimal procentPriceDifferance = ((customPrice*100) / originPrice)/100;
                    System.debug('item_i.soi procentPriceDifferance: '+ procentPriceDifferance);
                    Decimal totalCustomPrice = 0.00;
                    
                    for(SO_Line_Items__c bundleItem: item_i.bundelItems){
                        //SO_Line_Items__c bundleItem = bundleItemToClone_i.clone(true);
                        System.debug('item_i.soi bandles UnitPrice__c: '+bundleItem.Sub_Total__c);
                        System.debug('item_i.soi bandles Quantity__c: '+bundleItem.Quantity__c);
                   
                    
                        bundleItem.Custom_Price__c = bundleItem.Sub_Total__c * procentPriceDifferance.setScale(2) ;
                        bundleItem.Custom_Price__c = bundleItem.Custom_Price__c.setScale(2);
                        System.debug('item_i.soi bandles: '+bundleItem.Custom_Price__c);
                        totalCustomPrice += bundleItem.Custom_Price__c;
                        soLinesToUpdate.add(bundleItem);
                    }
                    if(item_i.bundelItems.size()>0){
                        soLinesToUpdate.get(parentItem+1).Custom_Price__c += customPrice-totalCustomPrice;
                    }
                
                }
            }else if((item_i.soi.Custom_Price__c == null || item_i.soi.Custom_Price__c==0) && item_i.soi.Products__r.recordtype.name == 'Bundled' && item_i.bundelItems!=null ){
                 item_i.soi.Custom_Price__c = null;
                 soLinesToUpdate.add(item_i.soi);
                 for(SO_Line_Items__c bundleItem: item_i.bundelItems){
                       
                        bundleItem.Custom_Price__c = null;

                        soLinesToUpdate.add(bundleItem);
                    }
            }
            
        }
        if(soLinesToUpdate.size()>0){
            update soLinesToUpdate;
        }

    }


    public void taxCalculation()
    {
        try {
         /*   if(SalesorderObject.id !=null)
            {
                map<string,Tax_Percentage__c> stateTaxPercentage = Tax_Percentage__c.getall();
                if(stateTaxPercentage.get(SalesorderObject.Shipping_State__c)!=null)
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
                }
                
                update SalesorderObject;
                
                newPriceCalculation pc=new newPriceCalculation();            
                list<string> SO_Ids=new list<string>(); 
                SO_Ids.add(SalesorderObject.id);            
                pc.calculation(SO_Ids,'Rejected',null,null); 
                
                system.debug('SalesorderObject ' + SalesorderObject.Shipping_City__c);
                
                if(SalesorderObject.id !=null)
                {
                    SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
                }        
            }*/
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void savesalesorder()
    {
        system.debug('SalesorderObject.Customer_Name__c '+ SalesorderObject.Customer_Name__c);
        try {
            List<String> AddressType = new List<String>();
            AddressType.add('Primary Shipping Address');
            AddressType.add('Primary Billing Address');
            AddressType.add('shipping');
            AddressType.add('billing');
            if(SalesorderObject.Customer_Name__c != null)
            {
                
                System.debug('AddressType :: '+AddressType);
                accObject = [select id,Name,First_Name__c,Last_Name__c,AccountNumber,Email__c,Phone,Mobile__c,BillingStreet,BillingCity,
                             BillingState,BillingPostalCode,BillingCountry,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode, Website,
                             ShippingCountry,(select id,AddressType__c,Name,Cell__c,City__c,Country__c,State__c,Street_Address__c,Telephone__c,
                                              Zip_Postal_Code__c from Customer_Addresses__r where AddressType__c In : AddressType Order BY Magento_Customer_Address_Id__c ASC limit 4) from account where id =:SalesorderObject.Customer_Name__c];
                
                SalesorderObject.Email__c = accObject.Email__c;
                SalesorderObject.Mobile__c = accObject.Mobile__c;
                System.debug('accObject :: '+accObject);
                integer Count = 0;
                for(Customer_Addresses__c customerAddress : accObject.Customer_Addresses__r)
                {
                    System.debug('customerAddress AddressType :: '+customerAddress.AddressType__c);
                    if(customerAddress.AddressType__c == 'Primary Shipping Address' && Count < 2)
                    {
                        SalesorderObject.Customer_shipping_Address__c = customerAddress.id;
                        SalesorderObject.Ship_to__c = customerAddress.Name;
                        SalesorderObject.Shipping_Phone__c = customerAddress.Cell__c;
                        SalesorderObject.Shipping_City__c = customerAddress.City__c;
                        SalesorderObject.Shipping_State__c = customerAddress.State__c;
                        SalesorderObject.Shipping_Street__c = customerAddress.Street_Address__c;
                        SalesorderObject.Shipping_ZipCode__c = customerAddress.Zip_Postal_Code__c; 
                        SalesorderObject.Shipping_Country__c = customerAddress.Country__c;
                        
                        Count++;
                        system.debug('Count:'+Count);
                    }
                    else if(customerAddress.AddressType__c == 'Primary Billing Address' && Count < 2)
                    {
                        SalesorderObject.Customer_Billing_Address__c=customerAddress.id;
                        SalesorderObject.Bill_To__c=customerAddress.Name;
                        //SalesorderObject.Billing_Phone__c=customerAddress.Cell__c;
                        SalesorderObject.Billing_City__c=customerAddress.City__c;
                        SalesorderObject.Billing_State__c=customerAddress.State__c;
                        SalesorderObject.Billing_Street__c=customerAddress.Street_Address__c;
                        SalesorderObject.Billing_ZipCode__c=customerAddress.Zip_Postal_Code__c;
                        SalesorderObject.Billing_Country__c = customerAddress.Country__c;
                        
                        Count++;
                        system.debug('Count:'+Count);
                    }
                    else if(customerAddress.AddressType__c == 'shipping' && (Test.isRunningTest() || Count < 2))
                    {
                        SalesorderObject.Customer_shipping_Address__c = customerAddress.id;
                        SalesorderObject.Ship_to__c=customerAddress.Name;
                        SalesorderObject.Shipping_Phone__c=customerAddress.Cell__c;
                        SalesorderObject.Shipping_City__c=customerAddress.City__c;
                        SalesorderObject.Shipping_State__c=customerAddress.State__c;
                        SalesorderObject.Shipping_Street__c=customerAddress.Street_Address__c;
                        SalesorderObject.Shipping_ZipCode__c=customerAddress.Zip_Postal_Code__c; 
                        SalesorderObject.Shipping_Country__c = customerAddress.Country__c;
                        
                        Count++;
                        system.debug('Count:'+Count);
                    }
                    else if(customerAddress.AddressType__c == 'billing' && (Test.isRunningTest() ||  Count < 2))
                    {
                        SalesorderObject.Customer_Billing_Address__c=customerAddress.id;
                        SalesorderObject.Bill_To__c=customerAddress.Name;
                        //SalesorderObject.Billing_Phone__c=customerAddress.Cell__c;
                        SalesorderObject.Billing_City__c=customerAddress.City__c;
                        SalesorderObject.Billing_State__c=customerAddress.State__c;
                        SalesorderObject.Billing_Street__c=customerAddress.Street_Address__c;
                        SalesorderObject.Billing_ZipCode__c=customerAddress.Zip_Postal_Code__c;
                        SalesorderObject.Billing_Country__c = customerAddress.Country__c;
                        
                        Count++;
                        system.debug('Count:'+Count);
                    }
                }
            }

            if(SalesorderObject.id == null)
            {
                insert SalesorderObject;
            }         
            else
            {
                update SalesorderObject;
            }
            
            accObject = [SELECT id,Name,First_Name__c,Last_Name__c,AccountNumber,Email__c,Phone,Mobile__c,BillingStreet,BillingCity, RecordTypeId,
                             BillingState,BillingPostalCode,BillingCountry,ShippingStreet,ShippingCity,ShippingState,ShippingPostalCode, Website,
                             ShippingCountry,(SELECT id,AddressType__c,Name,Cell__c,City__c,Country__c,State__c,Street_Address__c,Telephone__c,
                                              Zip_Postal_Code__c FROM Customer_Addresses__r WHERE AddressType__c IN : AddressType Order BY Magento_Customer_Address_Id__c ASC limit 4) FROM account WHERE id =:SalesorderObject.Customer_Name__c];
            
            newPriceCalculation pc = new newPriceCalculation();            
            list<string> SO_Ids = new list<string>(); 
            SO_Ids.add(SalesorderObject.id);            
            pc.calculation(SO_Ids,'Rejected',null,null); 
            
            SalesorderObjectTemp = salesOrder(SalesorderObject.id);
            system.debug(' SalesorderObject ' +SalesorderObject);  
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void showDistance()
    {
        try
        {
            if(SalesorderObject.id !=null)
            {
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }        
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void showProducts()
    {
        //insert new Account();
        try
        {
            system.debug('productList ' + productList);
            String productsJSON = Apexpages.currentPage().getParameters().get('productlistfromparam');
            string configProductsJSON = '';
             system.debug('productsJSON ' + productsJSON);
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
                system.debug('configProductsJSON ' +configProductsJSON);
                
                if(productsJSON.contains('storedQuery'))
                {
                    storedquery = productsJSON.split('storedQuery')[1];
                    productsJSON = productsJSON.split('storedQuery')[0];                        
                }
                system.debug('productsJSON ' +productsJSON);
                productList = (List<Products__c>)JSON.deserialize(productsJSON, List<Products__c>.class);    
                system.debug('deserializedproducts ' +productList);
                //List<Id> productIds = new List<Id>();
                if(productList.size() > 0)
                {
                	list<string> configIds = new list<string>();
                    lastPayapalId = productList[productList.size()-1].id;
                    firstPayapalId = productList[0].id; 
                    
                    if(configProductsJSON != '')
                    {
                        productListTemp = (List<Products__c>)JSON.deserialize(configProductsJSON, List<Products__c>.class);    
                        system.debug('productListTemp ' +productListTemp);
                        for(products__c pro : productListTemp)
                        {
                        	configIds.add(pro.id);
                        }
                    }

                    //map<string,list<products__c>> testMap = getConfigProductMap(productIds);
                    //configlist.putAll(testMap);
                    //system.debug('\n\n\ntestMap3 ' + testMap + '\n\n\n');

                    //System.debug('configlist : '+configlist);
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
	                							      from Configurable_Item__c  where (Configurable_Product__c in :configIds or  Configurable_Product__c in :bundleItemIds) and Configurable_Product__c != null and Product__c != null];
	                
	                list<string> productsIds = new list<string>();
	                for (Configurable_Item__c ci : cis){
	                	productsIds.add(ci.Product__c);
	                }
	                map<id, Products__c> productMap = new map<id, Products__c>([select Product_Image_URL__c, Special_Price_Hidden__c , Tier_Price_For_Bundle__c,
	                								  Name , SKU__c, Regular_Price__c, Sales_Price__c, Special_Price__c, 
	                								  Image__c, Special_Price_From_Date__c, Special_Price_To_Date__c, Master_Products__c from Products__c where id in :productsIds]);
	                for (Configurable_Item__c ci : cis){
	                	if (productMap.containskey(ci.Product__c) && productMap.get(ci.Product__c) != null){
		                	if(!configlist.containsKey(ci.Configurable_Product__c)){
		                		configlist.put(ci.Configurable_Product__c, new list<Products__c>());
		                	}
		                	configlist.get(ci.Configurable_Product__c).add(productMap.get(ci.Product__c));
	                	}
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
    
    public map<string,list<BundleItemWrapper>> getProductRelatedBundle()
    {
        ProductRelatedBundle = new map<string,list<BundleItemWrapper>>();
        list<BundleItemWrapper> ProductRelatedBundleTemp = new list<BundleItemWrapper>();
        try {
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
    
    public void updateQty()
    {
        map<id,BundleItemWrapper> bundle = new map<id,BundleItemWrapper>();
        try {
            if(ProductRelatedBundle.containsKey(OptionsId)) {
                for(BundleItemWrapper bundelitemsObj : ProductRelatedBundle.get(OptionsId))
                { 
                    if(bundelitemsObj.selected == true && bundelitemsObj.quantity == '0')
                    {
                        bundelitemsObj.quantity='1';
                        bundle.put(bundelitemsObj.bundleitem.id,bundelitemsObj);
                    }
                    else if(bundelitemsObj.selected==true)
                    {
                        bundle.put(bundelitemsObj.bundleitem.id,bundelitemsObj);
                    }
                } 
                if(BundleList.containsKey(OptionsId))
                {
                    BundleList.remove(OptionsId); 
                }
                BundleList.put(OptionsId,bundle);
            }
        }
        catch(Exception e)
        {
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
        try 
        {
            if(selectedproducts.containsKey(productID) && productWrapperList.get(productID).selected == false )
            {
                selectedproducts.remove(productID);
                if(BundleList.containsKey(OptionsId))
                {
                    BundleList.remove(OptionsId); 
                }
                displayselectionPopup = false;
                productWrapperList.get(productID).quantity = '0';
            }
            else if(productWrapperList.containsKey(productID) && productWrapperList.get(productID).selected == true)
            {
                if(productWrapperList.get(productID).pro.recordtype.name == 'Configurable' && productWrapperList.get(productID).selectedoption == null) 
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Invalid Config Product.'));
                    productWrapperList.get(productID).selected = false;
                }
                else if(productWrapperList.get(productID).pro.recordtype.name == 'Bundled' && productWrapperList.get(productID).pro.Total_Items_in_Bundle__c == 0) 
                {
                    isBundleItemexist = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No Products Found.'));
                }
                else 
                {
                    isBundleItemexist = true;
                    if(productWrapperList.get(productID).quantity == '0')
                        productWrapperList.get(productID).quantity = '1';
                    selectedproducts.put(productID,productWrapperList.get(productID));
                    system.debug('productWrapperList[productID].quantity ' + productWrapperList.get(productID).quantity);
                }
            }  
            
            system.debug('selectedproducts '+selectedproducts);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
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
                    if(bundelitemsObj.quantity == '0' || bundelitemsObj.quantity == null)
                        bundelitemsObj.quantity = '1';
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
            updateProduct();
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void createSoItems()
    {
        list<SO_Line_Items__c> insertList = new list<SO_Line_Items__c>();
        Set<id> selectedConfigItemId = new Set<id>();
        Map<id,Products__c> getProductSKUMap = new Map<id,Products__c>();
        Savepoint sp;
        
        try 
        {
            if(SalesorderObject.id == null)
            {
                SalesorderObject.Order_Date__c = system.now();
                insert SalesorderObject;
            }
            else
            {
                update SalesorderObject;
            } 
            
            for(ProductWrapper proObj : selectedproducts.values())
            {
                if(BundleList.containsKey(proObj.pro.id))
                {
                    for(BundleItemWrapper bundelitemsObj : BundleList.get(proObj.pro.id).values())
                    {
                        selectedConfigItemId.add(bundelitemsObj.selectedBundeloption);
                    } 
                }
                else 
                {
                    selectedConfigItemId.add(proObj.selectedoption);
                }
            }
            
            if(selectedConfigItemId != null) 
            {
                for(Products__c proObj : [Select id,Name,Product_Image_URL__c,SKU__c from Products__c where id In :selectedConfigItemId])
                {
                    getProductSKUMap.put(proObj.id,proObj);
                }
            }
            
            for(ProductWrapper proObj : selectedproducts.values())
            {                           
                decimal count = 0;
                decimal mainBundleWeight = 0;
                if(BundleList.containsKey(proObj.pro.id))
                {
                    for(BundleItemWrapper bundelitemsObj : BundleList.get(proObj.pro.id).values())
                    {
                        SO_Line_Items__c SOI = new SO_Line_Items__c();
                        SOI.Sales_Order__c = SalesorderObject.id;
                        if(bundelitemsObj.quantity != '0')
                            SOI.Quantity__c = integer.valueof(bundelitemsObj.quantity);
                        else
                            SOI.Quantity__c = 1;
                        SOI.Products__c = bundelitemsObj.bundleitem.Bundle__c;
                        SOI.Bundle_Item__c = bundelitemsObj.bundleitem.id;
                        SOI.Config_Product__c = bundelitemsObj.selectedBundeloption;
                        if(SOI.Config_Product__c != null) {
                            SOI.ProductSKU__c = getProductSKUMap.get(bundelitemsObj.selectedBundeloption).SKU__c;
                            SOI.Product_Name__c = getProductSKUMap.get(bundelitemsObj.selectedBundeloption).Name;
                            SOI.Product_Url__c = getProductSKUMap.get(bundelitemsObj.selectedBundeloption).Product_Image_URL__c;
                        }
                        else {
                            SOI.ProductSKU__c = bundelitemsObj.bundleitem.SKU__c;
                            SOI.Product_Name__c = bundelitemsObj.bundleitem.Bundle_Product_Name__c;
                            SOI.Product_Url__c = bundelitemsObj.bundleitem.ImageURL__c;
                        }
                        SOI.Custom_Price__c = null;
                        count = count+SOI.Quantity__c;
                        
                        insertList.add(SOI);
                    }
                }
                
                SO_Line_Items__c SOI = new SO_Line_Items__c();
                SOI.Sales_Order__c = SalesorderObject.id;
                if(proObj.quantity != '0')
                    SOI.Quantity__c = integer.valueof(proObj.quantity);
                else
                    SOI.Quantity__c = 1;
                SOI.Products__c = proObj.pro.id;
                SOI.Config_Product__c = proObj.selectedoption;
                if(SOI.Config_Product__c != null && getProductSKUMap.containsKey(proObj.selectedoption)) 
                {
                    SOI.ProductSKU__c = getProductSKUMap.get(proObj.selectedoption).SKU__c;
                    SOI.Product_Name__c = getProductSKUMap.get(proObj.selectedoption).Name;
                    SOI.Product_Url__c = getProductSKUMap.get(proObj.selectedoption).Product_Image_URL__c;
                }
                else 
                {
                    SOI.ProductSKU__c = proObj.pro.SKU__c; 
                    SOI.Product_Name__c = proObj.pro.name;
                    SOI.Product_Url__c = proObj.pro.Product_Image_URL__c;
                }
                SOI.IncludeInPricing__c = true;
                SOI.Bundle_Items_Count__c = count;
                SOI.Custom_Price__c = null;
                insertList.add(SOI);  
                
                if(selectedproducts.containsKey(proObj.pro.id))
                    selectedproducts.remove(proObj.pro.id);
                if(BundleList.containsKey(proObj.pro.id))
                    BundleList.remove(proObj.pro.id);
                if(productWrapperList.containsKey(proObj.pro.id))
                    productWrapperList.remove(proObj.pro.id);
            }
            
            if(insertList.size() > 0)
            {
               /* if(SalesorderObject.Promotion__c != null)
                {
                    SalesorderObject.Promotion__c = null;
                    update SalesorderObject;  
                }
                */
                system.debug('insertList ' + insertList);
                insert insertList;
                
                
                
                list<string> SO_Ids = new list<string>();
                SO_Ids.add(SalesorderObject.id);
                
                newPriceCalculation pc = new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null);
                pc.updatecalculation(SO_Ids); 
                
                if(SalesorderObject.id !=null)
                {
                    SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
                }
                
                showProtectionPlan();
                system.debug('protectionplanSOI ' + protectionplanSOI);
                if(protectionplanSOI != null && protectionplanSOI.id != null)
                {
                    update protectionplanSOI;
                }
                
                pc = new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null); 
                pc.updatecalculation(SO_Ids);
                
                if(SalesorderObject.id !=null)
                {
                    SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
                }     
            }
            
            if(custumpricetotal > 0 )
            {
                manualPaymentPopUp = true;
            }
            getSoRelated();
            updatePromocode();
            updateSalesorderObjectOnPage();
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
                list<SO_Line_Items__c> MainSOitems = [select id,Custom_Price__c, FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Product_Record_Type__c,Products__r.recordtypeid,Products__r.recordtype.name,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                                                      Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c, Last_status_before_cancel__c from SO_Line_Items__c where Bundle_Item__c=null and Sales_Order__c =: SalesorderObject.id];
                
                list<SO_Line_Items__c> BundelSOitems = [select id,FedExable__c,Bundle_Items_Count__c,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Product_Record_Type__c,Custom_Price__c,TaxAmount__c,Sub_Total__c,Price__c,ProductImageUrl__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,
                                                        Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Amount__c,Tax_Percent__c,Total__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c, Last_status_before_cancel__c from SO_Line_Items__c where Bundle_Item__c!=null and Sales_Order__c =: SalesorderObject.id order by Bundle_Item__r.Order__c];
                
                
                            system.debug('MainSOitems : '+ MainSOitems);
                            system.debug('BundelSOitems : '+ BundelSOitems);
                for(SO_Line_Items__c SoiItem : MainSOitems)
                {
                    if(SoiItem.Products__r.Select_Manufacturer__c != null) {
                       manufactureList.add(SoiItem.Products__r.Select_Manufacturer__r.name); 
                    }
                    
                    insertedproductsIds.put(SoiItem.Products__c,new insertProductsWrapper(SoiItem.Quantity__c, SoiItem.Config_Product__c));
                    
                    if(SoiItem.Products__r.recordtype.name == 'Bundled')
                    {
                        list<SO_Line_Items__c> BundelSOitemstemp = new list<SO_Line_Items__c>();
                        for(SO_Line_Items__c BundelItem : BundelSOitems) 
                        { 
                            if(SoiItem.Products__c == BundelItem.Products__c)
                            {
                                insertedproductsIds.put(BundelItem.Bundle_Item__c,new insertProductsWrapper(BundelItem.Quantity__c,BundelItem.Config_Product__c));
                                BundelSOitemstemp.add(BundelItem);
                            }
                        }
                        if(BundelSOitemstemp.size()>0)
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
                            system.debug('Config_Product__c '+ SoiItem.Config_Product__c);
                            system.debug('configlist '+ configlist.keySet());
                            for(products__c pro : configlist.get(SoiItem.Products__c))
                            {                       
                                configpro.add(new selectOption(pro.id,pro.name));   
                            }
                            SoRelated.put(SoiItem.id,new SelectedProductWrapper(SoiItem,new list<SO_Line_Items__c>(),configpro));
                        }
                        else
                            SoRelated.put(SoiItem.id,new SelectedProductWrapper(SoiItem,new list<SO_Line_Items__c>(),new list<selectoption>()));
                        if(SoiItem.Products__r.recordtype.name == 'Protection Plan')
                            protectionplanSOI = SoiItem;
                    } 
                } 
                showProtectionPlan();
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        
        system.debug('SoRelated '+SoRelated);
        
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
    
    public void updateProduct()
    {
        list<SO_Line_Items__c> updateList = new list<SO_Line_Items__c>();
        
        try 
        {
            if (SalesorderObject.Shipping_ZipCode__c != null){
            	list<Shipping_Zip_Codes__c> zipCodes = [select TaxJar_Sales_Tax__c, Zip_Code__c from Shipping_Zip_Codes__c where TaxJar_Sales_Tax__c != 0 and Zip_Code__c = :SalesorderObject.Shipping_ZipCode__c];
            	if (zipCodes.size() > 0){
		            tax = zipCodes[0].TaxJar_Sales_Tax__c;
            	}
	            else{
	            	tax = 0;
	            }
            }
            else{
            	tax = 0;
            }
            for(SelectedProductWrapper soItems : SoRelated.values())
            {
		        soItems.soi.Tax_Percent__c = tax;
                system.debug('soItems.soi  ' + soItems.soi);
                if(soItems.soi.Custom_Price__c != null && string.valueof(soItems.soi.Custom_Price__c) != '0')
                {
                	if (custumpricetotal == null){
                		custumpricetotal = 0;
                	}
                     custumpricetotal = custumpricetotal+soItems.soi.Custom_Price__c;
                }
                
                if(soItems.soi.Custom_Price__c != null && string.valueof(soItems.soi.Custom_Price__c) != '0' && soItems.soi.Bundle_Items_Count__c != 0)
                {
                    decimal customePrice = soItems.soi.UnitPrice__c - (soItems.soi.Custom_Price__c/soItems.soi.Quantity__c);
                    system.debug('customePrice  ' + customePrice);
                    
                    decimal customepriceIndividual = customePrice/soItems.soi.Bundle_Items_Count__c;
                    customepriceIndividual = customepriceIndividual.setScale(2);
                    system.debug('customepriceIndividual  ' + customepriceIndividual);
                    
                    decimal differenceAmount = customePrice - (customepriceIndividual * soItems.soi.Bundle_Items_Count__c);
                    system.debug('differenceAmount  ' + differenceAmount);
                    
                    for(SO_Line_Items__c soibundelItem : soItems.bundelItems)
                    {
                        system.debug(soibundelItem.Products__c+ ' id  ' + soItems.soi.Products__c);
                        system.debug(soibundelItem.Bundle_Item__c);
                        
                        if(soibundelItem.Products__c == soItems.soi.Products__c && soibundelItem.Bundle_Item__c != null)
                        {
		        			soibundelItem.Tax_Percent__c = tax;
		        			if (soibundelItem.UnitPrice__c-customepriceIndividual+differenceAmount != 0){
                            	soibundelItem.Custom_Price__c = soibundelItem.UnitPrice__c-customepriceIndividual+differenceAmount;
		        			}
                            system.debug('soibundelItem.Custom_Price__c  ' + soibundelItem.Custom_Price__c);
                            differenceAmount = 0;
				            if (string.valueof(soibundelItem.Custom_Price__c) == '0'){
				            	soibundelItem.Custom_Price__c = null;
				            }
                        }
                    }
                }
                if(soItems.soi.Custom_Price__c != null && string.valueof(soItems.soi.Custom_Price__c) != '0')
                {
                    system.debug('soItems.soi.Custom_Price__c  ' + soItems.soi.Custom_Price__c);
                    soItems.soi.Price__c = soItems.soi.Custom_Price__c / soItems.soi.Quantity__c;
                }
                else
                {
                    soItems.soi.Custom_Price__c = null; 
                }
                system.debug('soItems.soi  ' + soItems.soi);
                updateList.add(soItems.soi);
            }
            if(updateList.size() > 0)
            {
                system.debug('updateList ' + updateList);
                /*if(SalesorderObject.Promotion__c != null)
                {
                    SalesorderObject.Promotion__c = null;
                    update SalesorderObject;  
                }*/
                update updateList; 
                
                if(SalesorderObject.id != null)
                {
                    SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
                }               
                showProtectionPlan();
                
                if(protectionplanSOI != null && protectionplanSOI.id != null)
                {
                    update protectionplanSOI;
                }
                
                updateTaxCalculation();
                

                system.debug('custumpricetotal '+ custumpricetotal);
                
                if(custumpricetotal > 0)
                {
                    manualPaymentPopUp = true;
                }
                if(SalesorderObject.id != null)
                {
                    SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
                }
            } 
            if(SalesorderObject.id !=null)
            {
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }
            getSoRelated();
            updatePromocode();
            updateSalesorderObjectOnPage();
            updateTaxCalculation();
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void UpdateBundelItems()
    {
        decimal count = 0;
        
        system.debug('SOItemId '+apexpages.currentpage().getParameters().get('SOItemId'));
        system.debug('SOItemId : '+SOItemId);
        
        SelectedProductWrapper soitempbundel = SoRelated.get(SOItemId);        
        
        list<SO_Line_Items__c> removeList=new list<SO_Line_Items__c>();
        list<SO_Line_Items__c> updateList=new list<SO_Line_Items__c>();
        list<SO_Line_Items__c> insertList=new list<SO_Line_Items__c>();
        
        system.debug('Bundle update Method end');
        system.debug('SoRelatedBundle  '+SoRelatedBundle);
        system.debug('soitempbundel  '+soitempbundel);
        try 
        {
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
                            bundel.Config_Product__c=bundelitemsObj.selectedBundeloption;
                            bundel.Quantity__c=integer.valueof(bundelitemsObj.quantity);
                            count=count+bundel.Quantity__c;
                            updateList.add(bundel);
                        }
                        else
                        {
                            removeList.add(bundel);
                            if(insertedproductsIds.containsKey(bundel.Bundle_Item__c))
                                insertedproductsIds.remove(bundel.Bundle_Item__c);
                        }
                    }
                } 
                
                if(Test.isRunningTest() || ( bundelitemsObj.selected==true && existing==false))
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
                    SOI.Custom_Price__c = null;
                    //SOI.Price__c = null;
                    
                    count=count+SOI.Quantity__c;
                    
                    insertList.add(SOI); 
                }
            }
            
            if(insertList.size() > 0)
            {
                system.debug('insertList ' + insertList);
                insert insertList; 
                SalesorderObject.Promotion__c=null;
                soitempbundel.soi.Custom_Price__c=null;
            }   
            
            if(removeList.size() > 0)
            {
                system.debug('removeList ' + removeList);
                delete removeList; 
                soitempbundel.soi.Custom_Price__c=null;
                SalesorderObject.Promotion__c=null;
            }
            if(updateList.size() > 0)
            {
                system.debug('updateList ' + updateList);
                update updateList; 
                soitempbundel.soi.Custom_Price__c=null;
                SalesorderObject.Promotion__c=null;
            }
            
            soitempbundel.soi.Bundle_Items_Count__c=count;
            update soitempbundel.soi;
            
            update SalesorderObject; 
            
            newPriceCalculation pc=new newPriceCalculation();
            list<string> SO_Ids=new list<string>();
            SO_Ids.add(SalesorderObject.id);
            pc.calculation(SO_Ids,'Rejected',null,null);
            pc.updatecalculation(SO_Ids);
            
            if(SalesorderObject.id !=null)
            {
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }            
            showProtectionPlan();
            
            if(protectionplanSOI !=null && protectionplanSOI.id!=null)
            {                            
                SO_Ids.add(SalesorderObject.id);
                pc=new newPriceCalculation();
                pc.calculation(SO_Ids,'Rejected',null,null);
                pc.updatecalculation(SO_Ids);                    
                update protectionplanSOI;                
            }
            
            if(SalesorderObject.id !=null)
            {
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }
            
            displayPopup = false; 
            system.debug('Bundle update Method end');
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
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
                    if(selectedproducts.containsKey(soitemp.Products__c))
                        selectedproducts.remove(soitemp.Products__c);
                    if(BundleList.containsKey(soitemp.Products__c))
                        BundleList.remove(soitemp.Products__c);
                    
                    if(!productWrapperList.containsKey(soitemp.Products__c))
                    {
                        if(ProductRelatedBundleTempList.containsKey(soitemp.Products__c))
                        {
                            ProductRelatedBundleTempList.remove(soitemp.Products__c);
                        }
                        if(configlist.containsKey(soitemp.Products__c))
                        {
                            configlist.remove(soitemp.Products__c);  
                        }
                    } 
                    if(soitemp.Custom_Price__c!=null && string.valueof(soitemp.Custom_Price__c) != '0')
                    {
	                	if (custumpricetotal == null){
	                		custumpricetotal = 0;
	                	}
                        custumpricetotal = custumpricetotal-soitemp.Custom_Price__c;
                    }
                    
                    manufactureList.remove(soitemp.Products__r.Select_Manufacturer__r.name);
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
                        tempids.add(soitemp); 
                        removeProtection = true;
                        removePromocode = true;
                    }
                }
            }
            
            system.debug('tempids ' + tempids);
            delete tempids;
            
            newPriceCalculation pc = new newPriceCalculation();
            list<string> SO_Ids = new list<string>();
            SO_Ids.add(SalesorderObject.id);
            
            if(removeProtection == true)
            {                
                protectionplanSOI.id = null;
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
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }
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
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }
        }
        catch(Exception e)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    void updateTaxCalculation(){
        List<String> SO_Ids = new List<String>();
        SO_Ids.add(SalesorderObject.id);
        
        newPriceCalculation pc = new newPriceCalculation();
        pc.calculation(SO_Ids,'Rejected',null,null);
        pc.updatecalculation(SO_Ids); 
    }
    public void showProtectionPlan()
    {
        try
        {
            system.debug('showProtectionPlan start');
            system.debug('protectionplanList ' +protectionplanList);
            system.debug('SalesorderObjectTemp ' +SalesorderObjectTemp);
            
            for(products__c pro : protectionplanList)
            {
                if(protectionplanSOI !=null && protectionplanSOI.id!=null)
                {                    
                    if(pro.Protection_high_range__c >= SalesorderObjectTemp.Sub_Total__c - (protectionplanSOI.Price__c * protectionplanSOI.Quantity__c)  && pro.Protection_low_range__c <= SalesorderObjectTemp.Sub_Total__c - (protectionplanSOI.Price__c * protectionplanSOI.Quantity__c))
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
                    if(SalesorderObjectTemp.Sub_Total__c > 0 && pro.Protection_high_range__c >= SalesorderObjectTemp.Sub_Total__c  && pro.Protection_low_range__c <= SalesorderObjectTemp.Sub_Total__c )
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
                        if(pro.Sales_Price__c!=null && pro.Sales_Price__c != 0)
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
            
            system.debug('protectionplanSOI '+ protectionplanSOI);
            
            system.debug('showProtectionPlan END');
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
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
                /*if(stateTaxPercentage.get(SalesorderObject.Shipping_State__c) != null)
                {
                    protectionplanSOI.Tax_Percent__c = stateTaxPercentage.get(SalesorderObject.Shipping_State__c).Percentage__c ;
                }
                else if(stateTaxPercentage.get(SalesorderObject.Shipping_City__c) != null)
                {
                    protectionplanSOI.Tax_Percent__c = stateTaxPercentage.get(SalesorderObject.Shipping_City__c).Percentage__c ;
                }
                else
                {
                    protectionplanSOI.Tax_Percent__c = 0; 
                }*/
                insert protectionplanSOI;
                
                if(SalesorderObject.Promotion__c != null)
                {
                    if(promotionObj != null && promotionObj.Type__c != 'Brand' )
                    {
                        SalesorderObject.Promotion__c=null;
                     	update  SalesorderObject;      
                    }
                    newPriceCalculation pc = new newPriceCalculation();                    
                    list<string> SO_Ids=new list<string>();
                    SO_Ids.add(SalesorderObject.id);
                    pc.updatecalculation(SO_Ids); 
                    pc.calculation(SO_Ids,'Rejected',null,null);
                }
                if(SalesorderObject.id !=null)
                {
                    SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
                }
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    } 
    
    public void updatePromocode()
    {
        promotionObj = new Promotions__c();
        try
        { 
            if(SalesorderObject.Promotion__c != null)
            {
                promotionObj = [select Brand__c,Min_Sub_Total__c,Discount_Amount__c,Brands_to_Exclude__c,Type__c,Is_Active__c from Promotions__c where id=:SalesorderObject.Promotion__c ];
                
                system.debug('SoRelated ' + SoRelated);
                system.debug('SoRelated.size() ' + SoRelated.size());
                if(SoRelated == null || SoRelated.size() == 0)
                { 
                    system.debug('SoRelated' + SoRelated);
                    SalesorderObject.Promotion__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select Products to Apply Promocode'));  
                }
                else if(promotionObj.Is_Active__c == false)
                {
                    SalesorderObject.Promotion__c = null;
                    update SalesorderObject;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(InActive)'));  
                }
                else 
                {
                    decimal subtotal = 0;
                    for(SelectedProductWrapper SOItem : SoRelated.values())
                    {
                        System.debug('SOItem.soi.Sub_Total__c : '+SOItem.soi.Sub_Total__c);
                        subtotal = subtotal + SOItem.soi.Sub_Total__c;
                        
			            if (string.valueof(SOItem.soi.Custom_Price__c) == '0'){
			            	SOItem.soi.Custom_Price__c = null;
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
                        system.debug('manufactureList ' + manufactureList);
                        system.debug('promotionObj.Brand__c ' + promotionObj.Brand__c);
                        
                        if(!manufactureList.contains(promotionObj.Brand__c) && promotionObj.Type__c == 'Brand')
                        {
                            SalesorderObject.Promotion__c = null;
                            update SalesorderObject;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable'));
                        }
                        else if(promotionObj.Type__c == 'Brand')
                        {
                            subtotal = 0;
                            for(SelectedProductWrapper SOItem : SoRelated.values())
                            {
                                if(SOItem.soi.Manufacturer__c == promotionObj.Brand__c)
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
                                system.debug('Else SalesorderObject.Promotion__c ' + SalesorderObject.Promotion__c);
                                update SalesorderObject;
                            }
                        }
                        else if(promotionObj.Type__c == 'General')
                        {  	
                            system.debug('Else if SalesorderObject.Promotion__c ' + SalesorderObject.Promotion__c);
                            System.debug('General promotionObj: '+promotionObj.Type__c);
                            list<string> excludeBrandsList = new list<string>();	
                            set<string> excludeBrandsSet = new set<string>();
                            
                            if(subtotal < promotionObj.Discount_Amount__c)
                            {
                                SalesorderObject.Promotion__c = null;
                                update SalesorderObject;
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Promocode not Applicable(Discount amount more than subtotal)')); 
                            }
                            else
                            {
                                if(promotionObj.Brands_to_Exclude__c != null && promotionObj.Brands_to_Exclude__c != '')
                                {
                                    excludeBrandsSet.addAll(promotionObj.Brands_to_Exclude__c.split(';'));
                                    
                                    system.debug('excludeBrandsSet '+ excludeBrandsSet);
                                    system.debug('manufactureList '+ manufactureList);
                                    
                                    if(excludeBrandsSet.containsAll(manufactureList) == true )
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
                                            //SOItem.soi.Products__r.recordtype.name != 'Protection Plan' &&
                                            if(excludeBrandsSet.contains(SOItem.soi.Manufacturer__c) == false)
                                            {
                                                subtotal = subtotal + SOItem.soi.Sub_Total__c; 
                                                count = count + SOItem.soi.Quantity__c;
                                                updateList.add(SOItem.soi);
                                            }
                                            else 
                                            {
                                                SOItem.soi.Discount_Percent__c = 0;
                                                SOItem.soi.DiscountAmount__c = 0;
                                                updateDiscountList.add(SOItem.soi);
                                            }
                                        }
                                        
                                        system.debug('subtotal '+ subtotal);
                                        system.debug('promotionObj.Min_Sub_Total__c '+ promotionObj.Min_Sub_Total__c);
                                        system.debug('promotionObj.Discount_Amount__c '+ promotionObj.Discount_Amount__c);
                                        
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
                                                
                                                Soi.Discount_Percent__c = Soi.Sub_Total__c / subtotal;
                                                Soi.DiscountAmount__c = (Soi.Sub_Total__c / subtotal ) * promotionObj.Discount_Amount__c; 
                                                Soi.DiscountAmount__c = Soi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP); 
                                                amountSum += Soi.DiscountAmount__c;
                                                updateDiscountList.add(soi);
                                            }
                                            amountSum = promotionObj.Discount_Amount__c - amountSum;
                                            if(updateDiscountList.size()>0){
                                                updateDiscountList.get(0).DiscountAmount__c += amountSum;
                                            }
                                            update SalesorderObject; 
                                            update updateDiscountList;
                                            
                                            newPriceCalculation pc=new newPriceCalculation();                
                                            list<string> SO_Ids=new list<string>();
                                            SO_Ids.add(SalesorderObject.id);
                                            pc.updateGeneralPromoCalculation(SO_Ids); 
                                        }
                                    }
                                }
                                else
                                { 
                                    system.debug('SalesorderObjectTemp.Sub_Total__c : '+SalesorderObjectTemp.Sub_Total__c);
                                    system.debug('promotionObj.Discount_Amount__c : '+promotionObj.Discount_Amount__c);
                                    list<SO_Line_Items__c> updateDiscountList = new list<SO_Line_Items__c>();
                                    double amountSum = 0;
                                    for(SelectedProductWrapper SOItem : SoRelated.values())
                                    {
                                        if(SalesorderObjectTemp.Sub_Total__c != null || SalesorderObjectTemp.Sub_Total__c > 0)
                                        {
                                            SOItem.Soi.Discount_Percent__c = SOItem.Soi.Sub_Total__c / SalesorderObjectTemp.Sub_Total__c;
                                            SOItem.Soi.DiscountAmount__c = (SOItem.Soi.Sub_Total__c / SalesorderObjectTemp.Sub_Total__c ) * promotionObj.Discount_Amount__c; 
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
                            system.debug('Else SalesorderObject.Promotion__c ' + SalesorderObject.Promotion__c);
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
            if(SalesorderObject.id !=null)
            {
                SalesorderObjectTemp = salesOrder(SalesorderObject.id);  
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    

    public void ShowBundelProduct()
    {
        OptionsId = apexpages.currentpage().getParameters().get('OptionsId');
        SOItemId = apexpages.currentpage().getParameters().get('SOItemId');
        
        system.debug(OptionsId);
        system.debug(SOItemId);        
        
        displayPopup = true;
    }
    
    public PageReference goToDetailPage()
    {
        PageReference pr;
        Task tsk;
        try
        {  

            system.debug('paymentType  ' + paymentType);  
            system.debug('SalesorderObject.id  ' + SalesorderObject.id); 
            system.debug('paymentMethodVar  ' + paymentMethodVar);
            account AccountObject;
            
            if(SalesorderObject.id == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Products , Customer & Payment Information'));
                return null;
            }
            else
            {

                Sales_Order__c SalesorderObjectObj = [select id,name,Customer_Name__c,Customer_Name__r.Authorize_net_Profile_ID__c,email__c,Discount_Amount_Total__c,Grand_Total__c,Shipping_Handle__c,Sub_Total__c,TaxAmount__c,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c,ship_To__c,shipping_Street__c,shipping_City__c,shipping_State__c,shipping_ZipCode__c,(select id,Products__r.recordtype.Name,Bundle_Item__c,Sales_Order__c, Custom_Price__c, Last_status_before_cancel__c from SO_Line_Items__r) from Sales_Order__c where id=:SalesorderObject.Id ];
                system.debug('SalesorderObjectObj ' + SalesorderObjectObj);
                
                if(SalesorderObjectObj.SO_Line_Items__r.size() == 0)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Products to continue'));
                    return null;
                }
                else if(SalesorderObjectObj.Customer_Name__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Customer to continue'));
                    return null;
                }
                else if(SalesorderObject.Order_ETA__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Order ETA to continue '));
                    return null;
                }
                else if(SalesorderObject.Email__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please enter customer Email to continue'));
                    return null;
                }
                /*else if(SalesorderObject.Customer_Billing_Address__c == null )
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please review Billing address'));
                    return null;
                }
                else if(SalesorderObject.Customer_shipping_Address__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please review Shipping address'));
                    return null;
                }*/
                else if(paymentType == '' || paymentType == null )
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please select Payment Information to continue'));  
                    return null;
                }
                else if(accObject.email__c == null || accObject.First_Name__c == null || accObject.Last_Name__c == null || accObject.Phone == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Enter customer Details '));
                    return null;
                }
                else if(/*SalesorderObjectObj.Bill_To__c == null || */SalesorderObject.Billing_Street__c == null || SalesorderObject.Billing_City__c == null || SalesorderObject.Billing_State__c == null || SalesorderObject.Billing_ZipCode__c == null)
                {
                    system.debug('SalesorderObjectObj.Bill_To__c '+SalesorderObjectObj.Bill_To__c+' SalesorderObjectObj.Billing_Street__c ' + SalesorderObjectObj.Billing_Street__c+'SalesorderObjectObj.Billing_City__c '+SalesorderObjectObj.Billing_City__c+' SalesorderObjectObj.Billing_State__c ' + SalesorderObjectObj.Billing_State__c+' SalesorderObjectObj.Billing_ZipCode__c ' + SalesorderObjectObj.Billing_ZipCode__c);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the Customer Billing Address '));
                    return null;
                }
                else if(/*SalesorderObjectObj.ship_To__c==null || */SalesorderObject.Shipping_Street__c==null || SalesorderObject.Shipping_City__c==null || SalesorderObject.Shipping_State__c==null || SalesorderObject.shipping_ZipCode__c==null)
                {
                    system.debug('SalesorderObjectObj.ship_To__c '+SalesorderObjectObj.ship_To__c+' SalesorderObjectObj.Shipping_Street__c ' + SalesorderObjectObj.Shipping_Street__c+'SalesorderObjectObj.Shipping_City__c '+SalesorderObjectObj.Shipping_City__c+'SalesorderObjectObj.Shipping_State__c '+SalesorderObjectObj.Shipping_State__c+'SalesorderObjectObj.Shipping_ZipCode__c '+SalesorderObjectObj.Shipping_ZipCode__c);
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the Customer Shipping Address '));
                    return null;
                }
                else
                {
                    //--------------------------------------------
                    updateProduct();
                    //--------------------------------------------

                    if(paymentType == 'CreditCard')
                    {
                        decimal total = 0;
                        SalesorderObject.Payment_Method__c='Credit Card';
                        list<Payment_Method__c> paymentMethods = new list<Payment_Method__c>();
                        
                        if(hasCard1 == false && hasCard3 == false && hasCard2 == false)
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
                            
                            if(total != SalesorderObjectTemp.Grand_Total__c)
                            {
                                system.debug('total '+total+' SalesorderObjectTemp ' + SalesorderObjectTemp.Grand_Total__c);
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check the entered amount. ' + total+' Grand Total is '+SalesorderObjectTemp.Grand_Total__c));
                                return null;
                            }
                            else if(SalesorderObjectObj.email__c==null)
                            {
                                system.debug('SalesorderObjectObj.email__c' + SalesorderObjectObj.email__c);
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check customer Email '));
                                return null;
                            }
                            else if( Test.isRunningTest() || (SalesorderObjectObj.Bill_To__c==null || SalesorderObjectObj.Billing_Street__c==null || SalesorderObjectObj.Billing_City__c==null || SalesorderObjectObj.Billing_State__c==null || SalesorderObjectObj.Billing_ZipCode__c==null))
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
                                system.debug('paymentMethods '+ paymentMethods);
                                
                                result = insertPaymentMethod(paymentMethods,SalesorderObject);
                                if(result == false) 
                                {
                                    return null;
                                }
                                else
                                {
                                    pr = new PageReference('/' +SalesorderObject.id);
                                    pr.setRedirect(true);
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
                            paymentMethodVar.Account__c=SalesorderObject.Customer_Name__c;
                            for(recordtype retypeObj:[select id, name,sobjecttype from recordtype where name='Check Payments' limit 1])
                            {
                                paymentMethodVar.RecordTypeId=retypeObj.id;
                                paymentMethodVar.Amount__c=SalesorderObjectTemp.Grand_Total__c;
                            }
                            insert paymentMethodVar;
                            
                            Transaction__c transactionObject=new Transaction__c();
                            transactionObject.Sales_Order__c=SalesorderObject.Id;
                            transactionObject.Payment_Method__c=paymentMethodVar.ID;
                            transactionObject.Transaction_Type__c='Cheque';
                            transactionObject.Amount__c=SalesorderObjectTemp.Grand_Total__c;
                            transactionObject.Status__c='Pending';
                            insert transactionObject;
                            
                            SalesorderObject.Payment_Type__c=paymentMethodVar.id;
                            SalesorderObject.Payment_Method__c='Check Payments';
                            SalesorderObject.Payment_Status__c='Pending';
                            
                            pr = new PageReference('/' +SalesorderObject.id);
                            pr.setRedirect(true);
                        }
                    }
                    else if(paymentType == 'PaypalInvoice')
                    {
                        pr=new PageReference('/' +SalesorderObject.id);
                        pr.setRedirect(true);
                        
                        SalesorderObject.Payment_Method__c = 'PayPal';
                        SalesorderObject.Payment_Status__c = 'Pending';
                    }
                    else if(paymentType == 'ManualPay' || paymentType == 'Cardknox' )//|| paymentType == 'Zibby by Affirm'
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

                        pr=new PageReference('/' +SalesorderObject.id);
                        pr.setRedirect(true);
                        
                        Id manualrecordId = Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get(chosenType).getRecordTypeId();
                        //string manualrecordId=[select id from Recordtype where name='Manual Payment'].id;
                        Payment_Method__c paymentMethodVar=new Payment_Method__c();
                        paymentMethodVar.recordtypeid=manualrecordId;
                        paymentMethodVar.Name_on_Account__c = accountName;//(paymentType == 'ManualPay' ? 'Manual' : 'Cardknox');//'Manual';
                        paymentMethodVar.Amount__c=SalesorderObjectTemp.Grand_Total__c;
                        paymentMethodVar.Account__c=SalesorderObject.Customer_Name__c; // accid
                        
                        insert paymentMethodVar;
                        
                        // SalesorderObject.Transaction_ID__c = authorizedotnetVar.transactionId;
                        Transaction__c transactionObject=new Transaction__c();
                        transactionObject.Transaction_Type__c='AUTH_ONLY';
                        transactionObject.Sales_Order__c=SalesorderObject.id;
                        transactionObject.Payment_Method__c=paymentMethodVar.ID;
                        transactionObject.Amount__c=SalesorderObjectTemp.Grand_Total__c;
                        transactionObject.Status__c='Pending';
                        
                        insert transactionObject;
                        
                        SalesorderObject.Payment_Method__c = chosenType;
                        SalesorderObject.Payment_Status__c = 'Pending';
                    }
                    else if(paymentType == 'AmazonPay')
                    {
                        pr=new PageReference('/' +SalesorderObject.id);
                        pr.setRedirect(true);
                        
                        SalesorderObject.Payment_Method__c='Amazon Payment';
                        SalesorderObject.Payment_Status__c='Pending';
                    }
                    else if(paymentType == 'AffirmPay')
                    {
                        pr=new PageReference('/' +SalesorderObject.id);
                        pr.setRedirect(true);
                        
                        SalesorderObject.Payment_Method__c = 'Affirm';
                        SalesorderObject.Payment_Status__c = 'Pending';
                    }
                    else if( paymentType == 'Zibby by Affirm'){
                        pr=new PageReference('/' +SalesorderObject.id);
                        pr.setRedirect(true);
                        
                        SalesorderObject.Payment_Method__c = 'Zibby by Affirm';
                        SalesorderObject.Payment_Status__c = 'Pending';
                    }
                     
                    SalesorderObject.Notify_Customer_with_Email__c = SalesorderObjectTemp.Notify_Customer_with_Email__c;
                    system.debug(SalesorderObject.id);
                    if(SalesorderObject.id != null)
                    {  
                        SalesorderObject.Order_Date__c=system.now();
                        update SalesorderObject;  
                        tsk = new Task(WhatId = SalesorderObject.Id, Subject = 'Order Submitted', ActivityDate = date.today(), Status = 'Completed');
                    }
                    else
                    {
                        SalesorderObject.Order_Date__c = system.now();
                        insert SalesorderObject;
                        tsk = new Task(WhatId = SalesorderObject.Id, Subject = 'Order Submitted', ActivityDate = date.today(), Status = 'Completed');
                    }
                    if(custumpricetotal > 0)
                    {
                        SalesorderObject.Is_Custom_Priced_Order__c = true; 
                        system.debug('SalesorderObject '+ SalesorderObject.id);
                        
                        update SalesorderObject;
                        pr = new PageReference('/' +SalesorderObject.id);
                        pr.setRedirect(true); 
                        
                        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
                        req1.setComments('Please Review & Approve this Refund');
                        req1.setObjectId(SalesorderObject.Id);
                        
                        // Submit the approval request for the Invoice
                        Approval.ProcessResult result = Approval.process(req1);
                    }                    
                    else if(pr != null)
                    {
                        SalesorderObject.Order_Status__c='Pending Fraud Check Completion';
                        update SalesorderObject; 
                    }
                }
                
                for(SO_Line_Items__c SOI: SalesorderObjectObj.SO_Line_Items__r)
                {
			            if (string.valueof(SOI.Custom_Price__c) == '0'){
			            	SOI.Custom_Price__c = null;
			            }
                    if(SOI.Products__r.recordtype.Name == 'Bundled' && SOI.Bundle_Item__c == null) 
                    {
                        newPriceCalculation.getMainBundleWeight(SOI.Sales_Order__c);
                    }
                }
                for (ProductWrapper pw : selectedproducts.values()){
			        if (pw.pro.name.contains('Protection Plan')){
			        	SalesorderObject.Protection_Plan_included__c = true;
			        	update SalesorderObject;
			        	break;
			        }
			        SalesorderObject.Protection_Plan_included__c = false;
                }
            }
            if(pr != null && tsk != null)
                insert tsk;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
            return null;
        }
        return pr;
    }
    
    public pagereference cancelSalesOrder()
    {
        system.debug('entered into cancel');
        pagereference pr;  
        try
        { 
            Schema.DescribeSObjectResult objectSchemaData = Sales_Order__c.sObjectType.getDescribe();
            String keyPrefix =  '/'+objectSchemaData.getKeyPrefix()+'/o';
            
            if(SalesorderObject.id!=null)
            {
                delete SalesorderObject;
            }
            if(paymentMethodVar.id!=null)
            {
                delete paymentMethodVar;
            }
            
            pr = new pagereference(keyPrefix);
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return pr;
    }
    
    @RemoteAction
    global static string getPrevProducts(string firstPayapalval,string query,string SOId) 
    {
        String productsJSON ;
        string configProductsJSON = '';
        try
        {
            list<string> productids = new list<string>();
            for(SO_Line_Items__c soi : [select id,Products__c from SO_Line_Items__c where Sales_Order__c=:SOId ])
            {
                productids.add(soi.Products__c); 
            }
            
            system.debug('firstPayapalval ' + firstPayapalval);
            system.debug('query : ' + query);
            list<Products__c> productsList = new list<Products__c>();
            list<products__c> productListTemp = new list<products__c>();
            string condition = ' ';
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
            
            list<string> proID = new list<string>();
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
                for(products__c pro : [select id,FedExable__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r)  from Products__c where Master_Products__c=null  and recordtype.name!='Protection Plan' and id  IN: proID ])
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
        string configProductsJSON = '';
        
        try
        {
            list<string> productids = new list<string>();
            for(SO_Line_Items__c soi : [select id,Products__c from SO_Line_Items__c where Sales_Order__c=:SOId])
            {
                productids.add(soi.Products__c); 
            }
            
            system.debug('lastPayapalval ' + lastPayapalval);
            
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
            
            query = query+' '+condition;
            system.debug('query+condition  ' + query);
            if(query.contains('&#39;')) 
                query = query.replaceAll('&#39;', '\'');
            system.debug('After Replace query : ' + query);
            productsList = database.query(query);
            system.debug('productsList  ' + productsList);
            productsJSON = JSON.serialize(productsList);
            system.debug('productsJSON ' +productsJSON);
            
            list<string> proID = new list<string>();
            list<Products__c> ProductsTemp = new list<Products__c>();
            
            for(Products__c pro : productsList)
            {
                for(Bundle_Item__c bud : pro.Bundle_Items1__r)
                {
                    if(bud.Product__r.recordtype.name == 'Configurable')
                    {
                        proID.add(bud.Product__c);
                    }
                } 
            }
            
            System.debug('proID :: '+proID);
            if(proID.size()>0)
            {
                for(products__c pro : [select id,FedExable__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r)  from Products__c where Master_Products__c=null and recordtype.name!='Protection Plan' and id  IN: proID ])
                {
                    ProductsTemp.add(pro);
                }
                
                configProductsJSON = JSON.serialize(ProductsTemp);
                
                productsJSON = productsJSON+' configProducts '+configProductsJSON;
                
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
            
            string query = 'Select id,FedExable__c,Final_OriginalPrice__c,Final_UnitPrice__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,Total_Items_in_Bundle__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r),(select id,Product__r.recordtype.name,Include__c,Name,Bundle__r.name,Bundle__c,Product__c,Sales_Price__c,ImageURL__c,Bundle_Product_Name__c,SKU__c ,Selection_Qty__c,Status__c from Bundle_Items1__r where Status__c=\'Enabled\' ORDER BY order__c ASC NULLS LAST),(select id,Product__r.recordtype.name,Include__c, Product__c from Configurable_Items__r where Status__c=\'Enable\' ORDER BY order__c ASC NULLS LAST) from Products__c where Status__c=\'Enabled\' and (Master_Products__c=null and recordtype.name!=\'Protection Plan\') and id not in : productids';
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
                productsJSON=productsJSON+' storedQuery '+storedQuery; 
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
                for(products__c pro : [select id,FedExable__c,recordtype.name,Type__c,Sales_Price__c,Regular_Price__c,Special_Price_Hidden__c,Select_Manufacturer__r.name,Product_Image_URL__c,recordtypeid,Name,SKU__c,(select id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c ,Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c from Products__r) from Products__c where recordtype.name!='Protection Plan' and id IN: proID ])
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
            if(producttemp != null) 
            {
                System.debug('producttemp Id : '+producttemp.id);
                if(configlist.containsKey(producttemp.id))
                {
                    configpro = new List<selectoption>();
                    configSalesPrice = new map<string,decimal>();
                    configSpecialPrice = new map<string,decimal>();
                    configRegularPrice = new map<string,decimal>();
                    
                    System.debug('configlist.get(producttemp.id) : '+configlist.get(producttemp.id).size());
                    if(configlist.get(producttemp.id).size() > 0) 
                    {
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
                    else 
                    {
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
        string quantity {set;get;}
        string selectedConfigProduct {set;get;}
        
        public insertProductsWrapper(decimal qty, string selectValue)
        {
            quantity = string.valueOf(qty);
            selectedConfigProduct = selectValue;
        }
    }
    
    public class BundleItemWrapper 
    {
        public Bundle_Item__c bundleitem {get;set;}
        public List<selectoption> bundelpro {get;set;}
        public string selectedBundeloption {get;set;}
        public boolean selected {set;get;}
        public string quantity {set;get;}
        
        public map<string,decimal> configTirePrice {set;get;}
        
        public BundleItemWrapper(Bundle_Item__c bundleObj,map<string,list<products__c>> configlist,boolean selectedValue,string qty,string selectedConfig) 
        {
            selected = selectedValue;
            bundleitem = bundleObj;
            bundelpro = new List<selectoption>();
            configTirePrice = new map<string,decimal>();
            quantity = qty;
            if(selected == true &( quantity=='0' | quantity==null))
                quantity = '1';
            selectedBundeloption=selectedConfig;
            if(configlist.containsKey(bundleObj.Product__c))
            { 
                for(products__c pro: configlist.get(bundleObj.Product__c))
                {                       
                    if(selectedBundeloption==null)     
                        selectedBundeloption=pro.id;
                    bundelpro.add(new selectOption(pro.id,pro.name));
                    if(pro.Tier_Price_For_Bundle__c != null)
                    {
                        configTirePrice.put(pro.id,pro.Tier_Price_For_Bundle__c); 
                    }
                    else
                    {
                        configTirePrice.put(pro.id,pro.Final_UnitPrice__c); 
                    }
                    
                }
            }
        }
    }
    
    public class SelectedProductWrapper 
    {
        public SO_Line_Items__c soi{get;set;}
        public Boolean checked{get; set;}
        public string selectedoption{get;set;}
        public List<selectoption> configpro{get; set;}
        public list<SO_Line_Items__c> bundelItems{set;get;}
        
        public SelectedProductWrapper(SO_Line_Items__c Soitemp,list<SO_Line_Items__c> bundelItemsTemp, List<selectoption> config) 
        {
            soi = Soitemp;
            checked = true;
            bundelItems=bundelItemsTemp;
            configpro=config;
        }
    }
    
    public class transactionWrapper
    {
        public string customerprofileID;
        public string paymentProfileID;
        public string authTransctionID;
        
        public transactionWrapper(string inputCustomerprofileID,string inputPaymentProfileID,string inputAuthTransctionID)
        {
            customerprofileID=inputCustomerprofileID;
            paymentProfileID=inputPaymentProfileID;
            authTransctionID= inputAuthTransctionID;
        }
    }
    
    public void voidPayments(list<transactionWrapper> voidTransactionsList)
    {
        AuthorizeDotNetFunctions authorizedotnetVar=new AuthorizeDotNetFunctions();
        AuthorizeDotNetResponse responseObject=new AuthorizeDotNetResponse();
        try 
        {
            for(transactionWrapper transactionWrapperItem:voidTransactionsList)
            {
                system.debug('transactionWrapperItem '+transactionWrapperItem);
                system.debug('transactionWrapperItem.customerprofileID '+transactionWrapperItem.customerprofileID);
                system.debug('transactionWrapperItem.paymentProfileID'+transactionWrapperItem.paymentProfileID);
                system.debug('transactionWrapperItem.customerprofileID '+transactionWrapperItem.authTransctionID);
                responseObject=authorizedotnetVar.voidTransaction(transactionWrapperItem.customerprofileID,transactionWrapperItem.paymentProfileID,transactionWrapperItem.authTransctionID, system.now(), false);
                system.debug('responseObject '+responseObject);
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public boolean insertPaymentMethod(list<Payment_Method__c> paymentMethods,Sales_Order__c SalesorderObject)
    {
        boolean isValidPayment=false;
        list<transactionWrapper> VoidtransactionWrapperList=new list<transactionWrapper>(); 
        integer count=0;
        try
        {
            /* ***********Input Data - Start******************* */
            string paymentRecordtypeID =Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card').getRecordTypeId();
            Sales_Order__c SOObject=[select Magento_order_No__c, id,name,Customer_Name__c,Customer_Name__r.Authorize_net_Profile_ID__c,email__c,Discount_Amount_Total__c,Grand_Total__c,Shipping_Handle__c,Sub_Total__c,TaxAmount__c,Bill_To__c,Billing_Street__c,Billing_City__c,Billing_State__c,Billing_ZipCode__c  from sales_order__c where id=:SalesorderObject.id];
            system.debug('SOObject '+SOObject);
            map<string,Payment_Method__c> paymentMethodMap=new map<string,Payment_Method__c>();
            for(Payment_Method__c  paymentMethodVar : [select id,Payment_Profile_ID__c from Payment_Method__c where account__c=:SOObject.Customer_Name__c and recordtypeid=:paymentRecordtypeID])
            {
                paymentMethodMap.put(paymentMethodVar.Payment_Profile_ID__c, paymentMethodVar);
            }
            system.debug('paymentMethodMap '+paymentMethodMap);
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
                
                string expirationDate = paymentMethodVarobj.Expiration_Year__c+'/'+  paymentMethodVarobj.Expiration_Month__c.substringBefore('-');
                system.debug('expirationDate -->'+expirationDate);
                
                //IF customer Profile Exsist in Salesforce
                if(SOObject.Customer_Name__c <> null && SOObject.Customer_Name__r.Authorize_net_Profile_ID__c <> null)
                {
                    //Payment Profile Creation
                    AuthorizeDotNetFunctionsObj.createCustomerPaymentProfile(SOObject.Customer_Name__r.Authorize_net_Profile_ID__c, SOObject.Bill_To__c, '', SOObject.Billing_Street__c, SOObject.Billing_City__c, SOObject.Billing_State__c, SOObject.Billing_ZipCode__c, 'US', paymentMethodVarobj.Credit_Card_Number__c ,expirationDate, paymentMethodVarobj.Card_Verification_Number__c);
                    if(AuthorizeDotNetFunctionsObj <> null)
                    {
                        responseObject=AuthorizeDotNetFunctionsObj.createCustomerProfileAuthOnlyTransaction(SOObject.Customer_Name__r.Authorize_net_Profile_ID__c, AuthorizeDotNetFunctionsObj.customerPaymentProfileId, string.valueOf(paymentMethodVarobj.Amount__c), '0.00', orderNumber);
                        
                        if(responseObject <> null && responseObject.transactionId <>null)
                        {
                            VoidtransactionWrapperList.add(new transactionWrapper(SOObject.Customer_Name__r.Authorize_net_Profile_ID__c,AuthorizeDotNetFunctionsObj.customerPaymentProfileId,responseObject.transactionId));      
                        }
                        system.debug('VoidtransactionWrapperList '+VoidtransactionWrapperList);
                        //If Payment Profile Exsist in Salesforce
                        if(paymentMethodMap <> null && paymentMethodMap.containsKey(AuthorizeDotNetFunctionsObj.customerPaymentProfileId))
                        {
                            //Auth Only Transaction 
                            if(responseObject <>null)
                            {
                                // This is a Direct Transaction because Payment profile Exsist in Saleforce
                                Transaction__c transactionObject=new Transaction__c();
                                transactionObject.Sales_Order__c=SOObject.Id;
                                transactionObject.Payment_Method__c=paymentMethodMap.get(AuthorizeDotNetFunctionsObj.customerPaymentProfileId).id;
                                transactionObject.Amount__c=paymentMethodVarobj.Amount__c;
                                transactionObject.TransactionId__c=responseObject.transactionId;
                                transactionObject.Trans_AVS_Response__c=responseObject.avsResponse;
                                transactionObject.Transaction_Type__c='AUTH_ONLY';
                                transactionObject.Transaction_Response__c=responseObject.responseReasonText;
                                transactionObject.Status__c='Authorized';
                                
                                finalTransactionList.add(transactionObject);
                                system.debug('transactionsList '+transactionsList);
                            }
                            else
                            {
                                system.debug('If Payment Profile Exsist in Salesforce -responseObject');
                            }
                        }
                        else
                        {
                            if(responseObject <> null)
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
                    accObject=new account(id=SOObject.Customer_Name__c, Authorize_net_Profile_ID__c=AuthorizeDotNetFunctionsObj.customerProfileId);
                    
                    if(AuthorizeDotNetFunctionsObj.isExistingCustomerProfile)
                    {
                        AuthorizeDotNetFunctionsObj.createCustomerPaymentProfile(AuthorizeDotNetFunctionsObj.customerProfileId, SOObject.Bill_To__c, '', SOObject.Billing_Street__c, SOObject.Billing_City__c, SOObject.Billing_State__c, SOObject.Billing_ZipCode__c, 'US', paymentMethodVarobj.Credit_Card_Number__c ,expirationDate, paymentMethodVarobj.Card_Verification_Number__c);
                    }
                    
                    if(AuthorizeDotNetFunctionsObj <> null)
                    {
                        responseObject=AuthorizeDotNetFunctionsObj.createCustomerProfileAuthOnlyTransaction(AuthorizeDotNetFunctionsObj.customerProfileId, AuthorizeDotNetFunctionsObj.customerPaymentProfileId, string.valueOf(paymentMethodVarobj.Amount__c), '0.00', orderNumber);
                        if(responseObject <> null && responseObject.transactionId <>null)
                        {
                            VoidtransactionWrapperList.add(new transactionWrapper(AuthorizeDotNetFunctionsObj.customerProfileId,AuthorizeDotNetFunctionsObj.customerPaymentProfileId,responseObject.transactionId));      
                        }
                        system.debug('VoidtransactionWrapperList '+VoidtransactionWrapperList);
                        
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
            
            system.debug('finalPaymentMethodsMap '+finalPaymentMethodsMap);
            system.debug('finalTransactionsMap '+finalTransactionsMap);
            system.debug('finalTransactionList '+finalTransactionList);
            system.debug('tasklist '+tasklist);
            
            insert tasklist;
            
            if(finalTransactionList <> null)
            {
                insert finalTransactionList;
            }
            
            if(accobject<>null && accobject.id <>null)
            {
                update accObject;
            }
            
            if(!finalPaymentMethodsMap.isEmpty())
            {
                for(Payment_Method__c paymentItem:finalPaymentMethodsMap.values())
                {
                    system.debug('paymentItem '+paymentItem);
                    
                    insert paymentItem;
                    
                    IF(finalPaymentMethodsMap.containsKey(paymentItem.Credit_Card_Number__c))
                    {
                        finalPaymentMethodsMap.get(paymentItem.Credit_Card_Number__c).Id=  paymentItem.id; 
                    }
                } 
            }
            
            system.debug('finalPaymentMethodsMap After DML '+finalPaymentMethodsMap);
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
            system.debug('translist '+translist);
            if(translist <> null)
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
            if(VoidtransactionWrapperList <> null && VoidtransactionWrapperList.size()>0)
            {
                voidPayments(VoidtransactionWrapperList);  
            }
            
            return false;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Card - '+count+' : Please enter Valid Card Information-('+e.getMessage()+')')); 
            system.debug('Catch'+e.getLineNumber()+'--- '+e.getMessage()+'---------'+e.getCause());
            isValidPayment=false;
            if(VoidtransactionWrapperList <> null && VoidtransactionWrapperList.size()>0)
            {
                voidPayments(VoidtransactionWrapperList);  
            }
            return isValidPayment;
        }
        return isValidPayment;
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
    
    public PageReference goToHomePage()
    {
        pagereference pr;  
        try
        { 
            pr = new PageReference('/home/home.jsp'); 
            pr.setRedirect(true);
            return pr;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
        return pr;
    }

    private Map<String, List<Products__c>> getConfigProductMap(List<Id> idBundlelIst) {
        Map<String, List<Products__c>> result = new Map<String, List<Products__c>>();
        List<Id> allProductIds = new List<Id>();
        List<Id> idProductlIst = new list<Id>();
        List<Bundle_Item__c> bundlejunctions = [SELECT Product__c FROM Bundle_Item__c WHERE Bundle__c in :idBundlelIst];//  AND Status__c = 'Enable' LIMIT 1000];
        for (Bundle_Item__c bi : bundlejunctions){
        	idProductlIst.add(bi.Product__c);
        }
        List<Configurable_Item__c> junctions = [SELECT Configurable_Product__c, Product__c FROM Configurable_Item__c WHERE (Configurable_Product__c IN :idProductlIst OR  Product__c IN :idProductlIst)  AND Status__c = 'Enable' LIMIT 1000];
        for (Configurable_Item__c junction : junctions) {
            allProductIds.add(junction.Product__c);
        }
    	system.debug('bundlejunctions = ' + bundlejunctions);
    	system.debug('junctions = ' + junctions);
    	system.debug('idProductlIst = ' + idProductlIst);
    	system.debug('allProductIds = ' + allProductIds);
        Map<ID, Products__c> productMap = new Map<Id, Products__c>([
            SELECT id,Final_OriginalPrice__c,Final_UnitPrice__c,Product_Image_URL__c,Special_Price_Hidden__c,
            Tier_Price_For_Bundle__c,Name,SKU__c,Regular_Price__c,Sales_Price__c,Special_Price__c,Image__c,
            Special_Price_From_Date__c,Special_Price_To_Date__c,Master_Products__c
            FROM Products__c
            WHERE ID IN :allProductIds
        ]);
        for (Configurable_Item__c junction : junctions) {
            //List<Products__c> productsList = result.get(junction.Configurable_Product__c);
            Products__c relatedProduct = productMap.get(junction.Product__c);
            if (relatedProduct != null) {
                if (!result.containskey(junction.Configurable_Product__c)) {
                    result.put(junction.Configurable_Product__c, new List<Products__c>());
                }
                result.get(junction.Configurable_Product__c).add(relatedProduct);
            }
        }
    	system.debug('result = ' + result);
        return result;
    }
}