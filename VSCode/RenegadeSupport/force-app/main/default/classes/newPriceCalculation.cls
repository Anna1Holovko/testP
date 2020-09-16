/*
*   Author : Sowdhanya Karri | Kairos Tech
*   Class  : newPriceCalculation
*   Purpose: This class is to caliculate the new Price of Sales Order.
*/
public class newPriceCalculation 
{ 
    public void approvalProcessCalculation(list<string> salesorderids)
    {
        calculation(salesorderids,'Approved for Custom Discount','','');
        updatecalculation(salesorderids);
    }
    
    Public void calculation(list<string> SoiOBje,string status,string BundelRecordTypeId,string SimpleRecordTypeId)
    {
        try
        {             
            list<SO_Line_Items__c> SoiList = new list<SO_Line_Items__c>();
            Set<SO_Line_Items__c> bundleSoiSet = new Set<SO_Line_Items__c>();
            map<string,Tax_Percentage__c> stateTaxPercentage = Tax_Percentage__c.getall();
            
            for(Sales_Order__c SO : [select id,Promotion__c,(select id,Quantity__c,Product_Record_Type__c,Bundle_Item__r.Product__r.FedExable__c,
                                                Config_Product__r.FedExable__c,Products__r.FedExable__c,Product_Record_Type_Formula__c,
                                                IncludeInPricing__c,Products__r.Sales_Price__c,Products__r.Special_Price_Hidden__c,
                                                Products__r.Regular_Price__c,Config_Product__r.Sales_Price__c,Bundle_Item__r.Product__r.Sales_Price__c,
                                                Config_Product__r.Special_Price_Hidden__c,Bundle_Item__r.Product__r.Special_Price_Hidden__c,
                                                Config_Product__r.Regular_Price__c,Bundle_Item__r.Product__r.Regular_Price__c,Config_Product__r.Tier_Price_For_Bundle__c,
                                                Bundle_Item__r.Product__r.Tier_Price_For_Bundle__c,Products__r.Special_Price_To_Date__c,Products__r.Special_Price_From_Date__c,
                                                Config_Product__r.Special_Price_To_Date__c,Config_Product__r.Special_Price_From_Date__c,Bundle_Item__r.Product__r.Special_Price_To_Date__c,
                                                Bundle_Item__r.Product__r.Special_Price_From_Date__c,Bundle_Item__r.Product__r.Select_Manufacturer__r.Name,Products__c,
                                                Config_Product__r.Name,Config_Product__r.SKU__c,Config_Product__r.Product_Image_URL__c,
                                                Bundle_Item__c,Bundle_Item__r.Product__c,Config_Product__c,Sales_Order__r.Promotion__r.Discount_Amount__c,
                                                Sales_Order__r.Promotion__r.Discount_Percent__c,DiscountAmount__c,Sales_Order__r.Promotion__r.Brand__c,Sales_Order__c, Bundle_Item_Relative_Discount_Amount__c,
                                                Sales_Order__r.Promotion__r.Type__c,OriginalPrice__c,UnitPrice__c,Custom_Price__c,Price__c,Sales_Order__r.Shipping_State__c,
                                                Sales_Order__r.Shipping_City__c,Tax_Percent__c,Tax_Amount__c,Sub_Total__c from SO_Line_Items__r where Item__c != 'Cancelled') from Sales_Order__c where id IN : SoiOBje])
            {
                for(SO_Line_Items__c Soi : SO.SO_Line_Items__r)
                {
                    System.debug('Soi : '+Soi);
                    // Tier Price, Special Price , Sales Price and Regular Price
                    if(status != 'Approved for Custom Discount') 
                    {
                        if(Soi.Bundle_Item__c != null)
                        {
                            if(Soi.Config_Product__c != null)
                            {
                                Soi.FedExable__c = Soi.Config_Product__r.FedExable__c;
                                Soi.UnitPrice__c = Soi.Config_Product__r.Tier_Price_For_Bundle__c;
                                Soi.OriginalPrice__c = Soi.Config_Product__r.Regular_Price__c;
                            }
                            else
                            {
                                Soi.FedExable__c = Soi.Bundle_Item__r.Product__r.FedExable__c;
                                Soi.UnitPrice__c = Soi.Bundle_Item__r.Product__r.Tier_Price_For_Bundle__c;
                                Soi.OriginalPrice__c = Soi.Bundle_Item__r.Product__r.Regular_Price__c;
                            }                       
                        }                  
                        else if(Soi.Config_Product__c != null)
                        {
                            system.debug('Config_Product__c ');
                            Soi.IncludeInPricing__c=true;
                            Soi.FedExable__c=Soi.Config_Product__r.FedExable__c;
                            IF(Soi.Config_Product__r.Special_Price_Hidden__c != 0)
                            {
                                system.debug('special Config_Product__c ');
                                if(Soi.Config_Product__r.Sales_Price__c != 0 ||  Soi.Config_Product__r.Sales_Price__c !=null)
                                {
                                    Soi.OriginalPrice__c = Soi.Config_Product__r.Sales_Price__c;
                                }
                                else
                                {
                                    Soi.OriginalPrice__c = Soi.Config_Product__r.Regular_Price__c;
                                }
                                
                                Soi.UnitPrice__c = Soi.Config_Product__r.Special_Price_Hidden__c;
                            }                    
                            else if(Soi.Config_Product__r.Sales_Price__c != 0 && Soi.Config_Product__r.Sales_Price__c != null)
                            {
                                system.debug('Sales_Price__c Config_Product__c ');
                                Soi.OriginalPrice__c=Soi.Config_Product__r.Regular_Price__c;
                                Soi.UnitPrice__c=Soi.Config_Product__r.Sales_Price__c;           
                            }
                            else
                            {
                                system.debug('Regular_Price__c Config_Product__c ');
                                Soi.OriginalPrice__c = Soi.Config_Product__r.Regular_Price__c;
                                Soi.UnitPrice__c = Soi.Config_Product__r.Regular_Price__c; 
                            } 
                        }
                        else if(Soi.Products__c != null)
                        {
                            Soi.IncludeInPricing__c = true;
                            Soi.FedExable__c = Soi.Products__r.FedExable__c;
                            if(Soi.Product_Record_Type_Formula__c == 'Simple')
                            {
                                IF(Soi.Products__r.Special_Price_Hidden__c != 0)
                                {
                                    if(Soi.Products__r.Sales_Price__c != 0 )
                                    {
                                        Soi.OriginalPrice__c = Soi.Products__r.Sales_Price__c;
                                    }
                                    else
                                    {
                                        Soi.OriginalPrice__c = Soi.Products__r.Regular_Price__c;
                                    }
                                    
                                    Soi.UnitPrice__c = Soi.Products__r.Special_Price_Hidden__c;
                                }   
                                else if(Soi.Products__r.Sales_Price__c != 0 )
                                {
                                    Soi.OriginalPrice__c = Soi.Products__r.Regular_Price__c;
                                    Soi.UnitPrice__c = Soi.Products__r.Sales_Price__c;           
                                }
                                else
                                {
                                    Soi.OriginalPrice__c = Soi.Products__r.Regular_Price__c;
                                    Soi.UnitPrice__c = Soi.Products__r.Regular_Price__c; 
                                }
                            }                                               
                        }                                
                    }
                    
                    // Custom Price
                    /*if(Soi.Custom_Price__c == null)
                    {
                        Soi.Custom_Price__c = null;
                    }*/
                    System.debug('Soi.Custom_Price__c : '+Soi.Custom_Price__c);
                    System.debug('Soi.Price__c : '+Soi.Price__c);
                    System.debug('Soi.UnitPrice__c : '+Soi.UnitPrice__c);
                    if(Soi.Custom_Price__c != null && status != 'Approved for Custom Discount')
                    {                   
                        Soi.Price__c = Soi.Custom_Price__c/Soi.Quantity__c; 
                    }    
                    else 
                    {
                        Soi.Price__c = Soi.Price__c == null || Soi.Price__c == 0 ? Soi.UnitPrice__c : Soi.Price__c; 
                    }
                    System.debug('22Soi.Custom_Price__c : '+Soi.Custom_Price__c);
                    /*if (Soi.Price__c == 0){
                    	Soi.Price__c = Soi.UnitPrice__c;
                    }*/
                    System.debug('Inner SOI : '+Soi);
                    System.debug('Promotion : '+SO.Promotion__c);
                    /*if(SO.Promotion__c == null) {
                        Soi.DiscountAmount__c = 0;
                    }*/
                    
                    Decimal subTotaltemp = Soi.Quantity__c * Soi.Price__c;
                    Decimal subTotal = subTotaltemp.setScale(2, RoundingMode.HALF_UP);
                    //Tax Percent
                    if(Soi.Bundle_Item__c == null)
                    {
                        if(Soi.Product_Record_Type_Formula__c == 'Bundled') {
                           bundleSoiSet.add(Soi); 
                        }
                        Soi.IncludeInPricing__c = true;
                        System.debug('stateTaxPercentage : '+stateTaxPercentage);
                        if(Soi.Tax_Percent__c != null && stateTaxPercentage.containsKey(Soi.Sales_Order__r.Shipping_State__c) && stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_State__c) != null)
                        {
                            system.debug('Soi.Sales_Order__r.Shipping_State__c ' + Soi.Sales_Order__r.Shipping_State__c);
                            // //Soi.Tax_Percent__c = stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_State__c).Percentage__c ;
                            // if (Soi.DiscountAmount__c != null){
                            // 	Soi.Tax_Amount__c = ((subTotal - Soi.DiscountAmount__c)*Soi.Tax_Percent__c)/100;
                            // }
                            // else {
                            // 	Soi.Tax_Amount__c = (subTotal*Soi.Tax_Percent__c)/100;
                            // }
                            Soi.Tax_Amount__c = chooseTaxCalculation(Soi.DiscountAmount__c, subTotal, Soi.Tax_Percent__c);
                            System.debug('Tax_Percent__c : '+Soi.Tax_Percent__c);
                            System.debug('Tax_Amount__c : '+Soi.Tax_Amount__c);
                        }
                        else if(Soi.Tax_Percent__c != null && stateTaxPercentage.containsKey(Soi.Sales_Order__r.Shipping_City__c) && stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_City__c) != null)
                        {
                            system.debug('Soi.Sales_Order__r.Shipping_City__c ' + Soi.Sales_Order__r.Shipping_City__c);
                            // //Soi.Tax_Percent__c = stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_City__c).Percentage__c ;
                            // if (Soi.DiscountAmount__c != null){
                            // 	Soi.Tax_Amount__c = ((subTotal - Soi.DiscountAmount__c)*Soi.Tax_Percent__c)/100;
                            // }
                            // else {
                            // 	Soi.Tax_Amount__c = (subTotal*Soi.Tax_Percent__c)/100;
                            // }
                             Soi.Tax_Amount__c = chooseTaxCalculation(Soi.DiscountAmount__c, subTotal, Soi.Tax_Percent__c);
                            System.debug('Tax_Percent__c : '+Soi.Tax_Percent__c);
                            System.debug('Tax_Amount__c : '+Soi.Tax_Amount__c);
                        }
                        else if (Soi.Tax_Percent__c != null)
                        {
                           /* if (Soi.DiscountAmount__c != null){
                            	Soi.Tax_Amount__c = ((subTotal - Soi.DiscountAmount__c)*Soi.Tax_Percent__c)/100;
                            }
                            else {
                            	Soi.Tax_Amount__c = (subTotal*Soi.Tax_Percent__c)/100;
                            }
                            */
                            Soi.Tax_Amount__c = chooseTaxCalculation(Soi.DiscountAmount__c, subTotal, Soi.Tax_Percent__c);
		                            
                        }  
                        else
                        {
                            Soi.Tax_Percent__c = 0;
                            Soi.Tax_Amount__c = 0;
                        }  
                    } 
                    
                    if(Soi.Config_Product__c != null) {
                        Soi.ProductSKU__c = Soi.Config_Product__r.SKU__c;
                        Soi.Product_Name__c = Soi.Config_Product__r.Name;
                        Soi.Product_Url__c = Soi.Config_Product__r.Product_Image_URL__c;
                    }
                    
                    if(Soi != null)
                        SoiList.add(Soi);
                }
            }
            
            if(SoiList != null)
            {
                update SoiList;
                
                list<SO_Line_Items__c> bundleSoiList = new list<SO_Line_Items__c>();
                Map<String,list<SO_Line_Items__c>> bundleItemMap = getbundleItemMap(SoiOBje);        
                System.debug('bundleItemMap : '+bundleItemMap);
                System.debug('bundleItemMap Size : '+bundleItemMap.size());
                
                System.debug('bundleSoiSet : '+bundleSoiSet);
                System.debug('bundleSoiSet Size : '+bundleSoiSet.size());
                if(bundleSoiSet.size() > 0) {
                    for(SO_Line_Items__c Soi : bundleSoiSet) {
                        if(bundleItemMap.containsKey(''+Soi.Products__c+Soi.Sales_Order__c)) 
                        {   
                            Decimal totalTax = 0.00;
                            System.debug('bundleItemMap value Size : '+bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c).size());
                            System.debug('bundleItemMap.get(Soi.Products__c+Soi.Sales_Order__c) : '+bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c));
                            for(SO_Line_Items__c bundleSoi : bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c)) {
                                Decimal subTotaltemp = bundleSoi.Quantity__c * bundleSoi.Price__c;
                                Decimal subTotal = subTotaltemp.setScale(2, RoundingMode.HALF_UP);
                                if(Soi.Custom_Price__c == null) {
                                    if(Soi.Tax_Percent__c != null && stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_State__c) != null)
                                    {
                                        ////bundleSoi.Tax_Percent__c = stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_State__c).Percentage__c ;
			                            // if (bundleSoi.Bundle_Item_Relative_Discount_Amount__c != null){ //DiscountAmount__c != null){
			                            // 	bundleSoi.Tax_Amount__c = ((subTotal - bundleSoi.Bundle_Item_Relative_Discount_Amount__c)*bundleSoi.Tax_Percent__c)/100;
			                            // }
			                            // else {
			                            // 	bundleSoi.Tax_Amount__c = (subTotal*bundleSoi.Tax_Percent__c)/100;
			                            // }
                                        bundleSoi.Tax_Amount__c = chooseTaxCalculation(bundleSoi.Bundle_Item_Relative_Discount_Amount__c, subTotal, Soi.Tax_Percent__c);
		                            
                                    }
                                    else if(Soi.Tax_Percent__c != null && stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_City__c) != null)
                                    {
                                        ////bundleSoi.Tax_Percent__c = stateTaxPercentage.get(Soi.Sales_Order__r.Shipping_City__c).Percentage__c ;
                                        // if (bundleSoi.Bundle_Item_Relative_Discount_Amount__c != null){
			                            // 	bundleSoi.Tax_Amount__c = ((subTotal - bundleSoi.Bundle_Item_Relative_Discount_Amount__c)*bundleSoi.Tax_Percent__c)/100;
			                            // }
			                            // else {
			                            // 	bundleSoi.Tax_Amount__c = (subTotal*bundleSoi.Tax_Percent__c)/100;
			                            // }
                                        bundleSoi.Tax_Amount__c = chooseTaxCalculation(bundleSoi.Bundle_Item_Relative_Discount_Amount__c, subTotal, Soi.Tax_Percent__c);
                                    }
			                        else if (bundleSoi.Tax_Percent__c != null)
			                        {
			                            // if (bundleSoi.Bundle_Item_Relative_Discount_Amount__c != null){
			                            // 	bundleSoi.Tax_Amount__c = ((subTotal - bundleSoi.Bundle_Item_Relative_Discount_Amount__c)*bundleSoi.Tax_Percent__c)/100;
			                            // }
			                            // else {
			                            // 	bundleSoi.Tax_Amount__c = (subTotal*bundleSoi.Tax_Percent__c)/100;
			                            // }
                                        bundleSoi.Tax_Amount__c = chooseTaxCalculation(bundleSoi.Bundle_Item_Relative_Discount_Amount__c, subTotal, Soi.Tax_Percent__c);
			                        }  
                                    else
                                    {
                                        bundleSoi.Tax_Percent__c = 0; 
                                        bundleSoi.Tax_Amount__c = 0;
                                    }

                                    System.debug('create Order bundle Tax_Amount__c: ' + bundleSoi.Tax_Amount__c);
                                }
		                        else if (Soi.Tax_Percent__c != null)
		                        {
                                    bundleSoi.Tax_Amount__c = chooseTaxCalculation(bundleSoi.Bundle_Item_Relative_Discount_Amount__c, subTotal, bundleSoi.Tax_Percent__c);
		                            // if (bundleSoi.Bundle_Item_Relative_Discount_Amount__c != null){
			                        //     	bundleSoi.Tax_Amount__c = ((subTotal - bundleSoi.Bundle_Item_Relative_Discount_Amount__c)*bundleSoi.Tax_Percent__c)/100;
			                        //     }
		                            // else {
		                            // 	bundleSoi.Tax_Amount__c = (subTotal*bundleSoi.Tax_Percent__c)/100;
		                            // }
			                            
		                        }  
                                else
                                {
                                    bundleSoi.Tax_Percent__c = 0; 
                                    bundleSoi.Tax_Amount__c = 0;
                                }
                                totalTax += bundleSoi.Tax_Amount__c;
                                bundleSoiList.add(bundleSoi);
                            }
                            System.debug('create Order bundle1 totalTax: ' + totalTax);
                            System.debug('create Order bundle2 totalTax: ' + Soi.Tax_Amount__c);
                            System.debug('create Order bundleSoiList: ' + bundleSoiList);
                            if(bundleSoiList.size() > 1 && Soi.Tax_Amount__c.setScale(2,RoundingMode.DOWN) != 0){
                                for(Integer element = bundleSoiList.size()-1; element >= 0; element-- ){
                                    Decimal currentTaxAmnt = bundleSoiList.get(element).Tax_Amount__c;
                                    System.debug('create Order bundleSoiList: ' +  currentTaxAmnt);
                                    if(currentTaxAmnt > 0){
        
                                        bundleSoiList.get(element).Tax_Amount__c = (currentTaxAmnt + (Soi.Tax_Amount__c.setScale(2,RoundingMode.DOWN) - totalTax)).setScale(2,RoundingMode.DOWN);
                                        System.debug('create Order bundleSoiList after: ' +  bundleSoiList.get(element).Tax_Amount__c);
                                        break;
                                    }
                                }
                            }

                            
                        }
                    }
                }
                system.debug('bundleSoiList  : '+bundleSoiList);
                if(bundleSoiList.size() > 0){
                    update bundleSoiList;
                }
            }
            system.debug('SoiList : '+SoiList);
            
            if(SoiList != null)
            {
                list<SO_Line_Items__c> Soibundleupdatelist = new list<SO_Line_Items__c>();
                
                for(SO_Line_Items__c Soi : [select UnitPrice__c,Product_Record_Type__c,Custom_Price__c,Products__c,Sub_Total__c,Quantity__c,OriginalPrice__c,Price__c,Product_Record_Type_Formula__c from SO_Line_Items__c where Product_Record_Type_Formula__c ='Bundled' and Bundle_Item__c = null and  id IN : SoiList]) 
                {
                    SO_Line_Items__c SoiBundel = new SO_Line_Items__c();                  
                    SoiBundel = Soi;
                    SoiBundel.UnitPrice__c = 0;
                    SoiBundel.OriginalPrice__c = 0;
                    
                    for(SO_Line_Items__c SoibundelItem : SoiList)
                    {
                        if(SoibundelItem.Products__c == Soi.Products__c && SoibundelItem.Bundle_Item__c != null)
                        {
                            SoiBundel.UnitPrice__c=SoiBundel.UnitPrice__c+(SoibundelItem.UnitPrice__c*SoibundelItem.Quantity__c);
                            SoiBundel.OriginalPrice__c=	SoiBundel.OriginalPrice__c+(SoibundelItem.OriginalPrice__c*SoibundelItem.Quantity__c);
                        }
                    }
                    SoiBundel.Price__c = SoiBundel.UnitPrice__c;
                    if( Soi.Custom_Price__c !=null && status != 'Approved for Custom Discount')
                    {                   
                        Soi.Price__c=Soi.Custom_Price__c/Soi.Quantity__c; 
                    } 
                    else 
                    {
                        Soi.Price__c = Soi.Price__c == null || Soi.Price__c == 0 ? Soi.UnitPrice__c : Soi.Price__c; 
                    }
                    if (Soi.Tax_Percent__c != null)
                    {
                        // if (Soi.DiscountAmount__c != null){
                        //     	Soi.Tax_Amount__c = ((Soi.Price__c - Soi.DiscountAmount__c)*Soi.Tax_Percent__c)/100;
                        //     }
                        // else {
                        // 	Soi.Tax_Amount__c = (Soi.Price__c*Soi.Tax_Percent__c)/100;
                        // }
                        Soi.Tax_Amount__c = chooseTaxCalculation(Soi.DiscountAmount__c, Soi.Price__c, Soi.Tax_Percent__c);
                    }
                    Soibundleupdatelist.add(SoiBundel);
                    System.debug('create Order bundle2 totalTax: ' + Soi.Tax_Amount__c);
                    System.debug('create Order bundle2 TaxAmount__c: ' + Soi.TaxAmount__c);
                }
                update Soibundleupdatelist;
                System.debug('Soibundleupdatelist : '+Soibundleupdatelist);
            }            
        }        
        catch (exception ex)
        {
            system.debug(' Exception  msg '+ ex.getMessage() +' line Number  '+ ex.getLineNumber() );
        }
    }
    Decimal chooseTaxCalculation(Decimal BundleItemRelativeDiscountAmount, Decimal totalPrice, Decimal taxPercent  ){
        Decimal result = 0;
        if (BundleItemRelativeDiscountAmount != null){
            result = ((totalPrice - BundleItemRelativeDiscountAmount)*taxPercent)/100;
        }
        else {
            result = (totalPrice * taxPercent)/100;
        }
        return result.setScale(2, RoundingMode.HALF_UP);
    }
    public void updatecalculation(list<string> SoiIds)
    {
        list<SO_Line_Items__c> SoiUpdateList = new list<SO_Line_Items__c>();
        
        try {
        Map<String,list<SO_Line_Items__c>> bundleItemMap = getbundleItemMap(SoiIds);        
        System.debug('bundleItemMap : '+bundleItemMap);
        
        for(Sales_Order__c SO : [select id,Promotion__r.Brand__c,Total_Quantity_Ordered__c,Promotion__r.Discount_Percent__c,Promotion__r.Discount_Amount__c,
                                 Promotion__r.Type__c, Promotion__r.Min_Sub_Total__c,Sub_Total__c,
                                 (SELECT id,Products__r.Select_Manufacturer__r.Name,Config_Product__r.Select_Manufacturer__r.Name,Bundle_Item__r.Product__r.Select_Manufacturer__r.Name,
                                  Bundle_Item__c,Config_Product__c,Custom_Discount__c,Custom_Price__c,DiscountAmount__c,Discount_Amount__c,Item__c, Bundle_Item_Relative_Discount_Amount__c,
                                  OriginalPrice__c,Price__c,ProductImageUrl__c,Products__c,Quantity__c,Sales_Commission_Hidden__c,Sales_Commission__c,
                                  Sales_Order__c,Sub_Total__c,TaxAmount__c,Tax_Percent__c,Total__c,UnitPrice__c,Unit_Price__c, Discount_Percent__c,
                                  Product_Record_Type_Formula__c FROM SO_Line_Items__r where Bundle_Item__c = null and Quantity_Invoiced__c = 0) from Sales_Order__c where id in : SoiIds])
        {
            for(SO_Line_Items__c Soi : SO.SO_Line_Items__r)
            {
                if(SO.Promotion__c == null)
                {
                    /*Soi.Discount_Percent__c = 0;
                    Soi.DiscountAmount__c = 0;  
                    
                    if(bundleItemMap.containsKey(''+Soi.Products__c+Soi.Sales_Order__c)) 
                    {
                        System.debug('bundleItemMap.get(Soi.Products__c+Soi.Sales_Order__c) : '+bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c));
                        for(SO_Line_Items__c bundleSoi : bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c)) {
                            bundleSoi.Discount_Percent__c = 0;
                            bundleSoi.DiscountAmount__c = 0;
                            
                            SoiUpdateList.add(bundleSoi); 
                        }
                        System.debug('SoiUpdateList : '+SoiUpdateList);
                    }*/
                }
                else 
                {
                    if((SO.Promotion__r.Type__c == 'Brand' && SO.Promotion__r.Brand__c != null) && Soi.Products__r.Select_Manufacturer__r.Name == SO.Promotion__r.Brand__c)
                    {
                        System.debug('Soi.Sales_Order__r.Promotion__r.Type__c : ' + SO.Promotion__r.Type__c);
                        System.debug('Soi.Custom_Price__c : ' + Soi.Custom_Price__c);
                        
                        Soi.Discount_Percent__c = SO.Promotion__r.Discount_Percent__c;
                        Soi.DiscountAmount__c = (SO.Promotion__r.Discount_Percent__c * Soi.Sub_Total__c) / 100;
                        Soi.DiscountAmount__c = Soi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP);
                        if((Soi.Custom_Price__c == null) && bundleItemMap.containsKey(''+Soi.Products__c+Soi.Sales_Order__c)) 
                        {
                            System.debug('bundleItemMap.get(Soi.Products__c+Soi.Sales_Order__c) : '+bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c));
                            for(SO_Line_Items__c bundleSoi : bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c)) {
                                bundleSoi.Discount_Percent__c = SO.Promotion__r.Discount_Percent__c;
                                bundleSoi.DiscountAmount__c = (SO.Promotion__r.Discount_Percent__c * bundleSoi.Sub_Total__c) / 100;
                                bundleSoi.DiscountAmount__c = bundleSoi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP); //
                                SoiUpdateList.add(bundleSoi); 
                            }
                        
                            System.debug('SoiUpdateList : '+SoiUpdateList);
                        }
                    }
                    else if(SO.Promotion__r.Type__c == 'General')
                    {
                        /* 
                        system.debug('Soi.Sales_Order__r.Promotion__r.Type__c' + SO.Promotion__r.Type__c);
                        Soi.Discount_Percent__c = Soi.Sub_Total__c / SO.Sub_Total__c;
                        Soi.DiscountAmount__c = (Soi.Sub_Total__c / SO.Sub_Total__c ) * SO.Promotion__r.Discount_Amount__c; 
                        Soi.DiscountAmount__c = Soi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP); 
                        */
                    }
                    else 
                    {
                       /* system.debug('Soi.Sales_Order__r.Promotion__r.Type__c' + SO.Promotion__r.Type__c);
                        Soi.Discount_Percent__c = 0;
                        Soi.DiscountAmount__c = 0;  
                        
                        if(bundleItemMap.containsKey(''+Soi.Products__c+Soi.Sales_Order__c)) 
                        {
                            System.debug('bundleItemMap.get(Soi.Products__c+Soi.Sales_Order__c) : '+bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c));
                            for(SO_Line_Items__c bundleSoi : bundleItemMap.get(''+Soi.Products__c+Soi.Sales_Order__c)) {
                                bundleSoi.Discount_Percent__c = 0;
                                bundleSoi.DiscountAmount__c = 0;
                                
                                SoiUpdateList.add(bundleSoi); 
                            }
                            System.debug('SoiUpdateList : '+SoiUpdateList);
                        }*/
                    } 
                }
                /*if(Soi.Custom_Price__c == null)
                {
                    Soi.Custom_Price__c = null;
                }*/
                SoiUpdateList.add(Soi); 
                System.debug('Before Update SoiUpdateList : '+SoiUpdateList);
            }
        }
        update SoiUpdateList; 
            System.debug('After Update SoiUpdateList : '+SoiUpdateList);
        }
        catch(Exception e) {
            system.debug('Exception ex : '+e.getMessage()+', Cause : '+e.getCause()+', line number : ' + e.getLineNumber());
        }
    }
        
    @future
    public static void getMainBundleWeight(Id SalesOrderId) 
    {
        List<AggregateResult> mainBundleWeightList = new List<AggregateResult>();
        try 
        {
            mainBundleWeightList = [Select SUM(Total_Weight_Pounds__c) totalWeight,Products__c product from SO_Line_Items__c where Sales_Order__c=:SalesOrderId AND Bundle_Item__c != null Group By Products__c];
            System.debug('mainBundleWeightList :: '+mainBundleWeightList);
            
            List<SO_Line_Items__c> updateSoitems = new List<SO_Line_Items__c>();
            if(mainBundleWeightList.size() > 0) 
            {
                for(SO_Line_Items__c Soitem : [Select id,Products__c,Bundle_Weight__c from SO_Line_Items__c where Sales_Order__c=:SalesOrderId AND (Product_Record_Type_Formula__c = 'Bundled' AND Bundle_Item__c = null)]) 
                {
                    System.debug('Soitem Product :: '+Soitem.Products__c);
                    for(AggregateResult result : mainBundleWeightList) 
                    {
                        System.debug('result Product :: '+result.get('product'));
                        if(result.get('product') == Soitem.Products__c) 
                        {
                            SO_Line_Items__c oneSoitem = new SO_Line_Items__c();
                            oneSoitem.id = Soitem.id;
                            oneSoitem.Bundle_Weight__c = Integer.valueOf(result.get('totalWeight'));
                            
                            updateSoitems.add(oneSoitem);
                        }
                    }
                } 
            }
            System.debug('updateSoitems :: '+updateSoitems);
            System.debug('updateSoitems size :: '+updateSoitems.size());
            if(updateSoitems.size() > 0) 
            {
                update updateSoitems;
            }
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage()+', Please contact to System Administrator.'));
            system.debug(' '+e.getMessage() +' line number  ' + e.getLineNumber());
        }
    }
    
    public void updateGeneralPromoCalculation(list<string> SoiIds)
    {
        list<SO_Line_Items__c> SoiUpdateList = new list<SO_Line_Items__c>();
        try {
            Map<String,list<SO_Line_Items__c>> bundleItemMap = getbundleItemMap(SoiIds); 
            
            for(SO_Line_Items__c SoiItem : [SELECT id,Product_Record_Type_Formula__c,Products__r.Select_Manufacturer__r.Name,Sales_Order__r.Promotion__r.Discount_Amount__c,
                                            Config_Product__r.Select_Manufacturer__r.Name,Bundle_Item__r.Product__r.Select_Manufacturer__r.Name, Bundle_Item_Relative_Discount_Amount__c,
                                            Bundle_Item__c,Config_Product__c,Custom_Discount__c,Custom_Price__c,DiscountAmount__c,Discount_Amount__c,Item__c,
                                            OriginalPrice__c,Price__c,ProductImageUrl__c,Products__c,Quantity__c,Sales_Commission_Hidden__c,Sales_Order__r.Promotion__c,
                                            Sales_Commission__c,Sales_Order__c,Sales_Order__r.Sub_Total__c,Sub_Total__c,TaxAmount__c,Tax_Percent__c,Total__c,UnitPrice__c,
                                            Unit_Price__c FROM SO_Line_Items__c where Bundle_Item__c = null AND Product_Record_Type_Formula__c = 'Bundled' and Quantity_Invoiced__c = 0 AND Sales_Order__c IN: SoiIds])
            {
                System.debug('Promotion : '+SoiItem.Sales_Order__r.Promotion__c);
                System.debug('Promotion Discount : '+SoiItem.Sales_Order__r.Promotion__r.Discount_Amount__c);
                /*if(SoiItem.Sales_Order__r.Promotion__c == null)
                {
                    SoiItem.DiscountAmount__c = 0;  
                    SoiItem.Discount_Percent__c = 0;
                }
                else*/ if((SoiItem.Custom_Price__c == null) && bundleItemMap.containsKey(''+SoiItem.Products__c+SoiItem.Sales_Order__c)) 
                {
                    for(SO_Line_Items__c bundleSoi : bundleItemMap.get(''+SoiItem.Products__c+SoiItem.Sales_Order__c)) {
                        bundleSoi.Discount_Percent__c = SoiItem.Sub_Total__c / SoiItem.Sales_Order__r.Sub_Total__c;
                        bundleSoi.DiscountAmount__c = bundleSoi.Discount_Percent__c * SoiItem.Sales_Order__r.Promotion__r.Discount_Amount__c;
                        bundleSoi.DiscountAmount__c = bundleSoi.DiscountAmount__c.setScale(2, RoundingMode.HALF_UP);
                        
                        SoiUpdateList.add(bundleSoi); 
                    }
                }
                /*if(SoiItem.Custom_Price__c == null || SoiItem.Custom_Price__c == 0.00)
                {
                    SoiItem.Custom_Price__c=null;
                }*/
                SoiUpdateList.add(SoiItem);
            }
            
            update SoiUpdateList; 
        }
        catch(Exception e) {
            system.debug('Exception ex : '+e.getMessage()+', Cause : '+e.getCause()+', line number : ' + e.getLineNumber());
        }
    }
    
    public static Map<String,list<SO_Line_Items__c>> getbundleItemMap(list<string> SoiIds)
    {
        Map<String,list<SO_Line_Items__c>> bundleItemMap = new Map<String,list<SO_Line_Items__c>>();
        List<SO_Line_Items__c> bundleSOItemList = new List<SO_Line_Items__c>();
        try {
            for(SO_Line_Items__c bundleItemSOI : [SELECT id,Products__r.Select_Manufacturer__r.name,Product_Record_Type_Formula__c,Products__r.recordtypeid,Product_Record_Type__c,Custom_Price__c,TaxAmount__c,Sub_Total__c,name,Products__c,Products__r.name,Manufacturer__c,Price__c, Tax_Percent__c,
                                                  Tax_Amount__c, Discount_Percent__c,Quantity__c,DiscountAmount__c,Sales_Order__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c, Bundle_Item_Relative_Discount_Amount__c from SO_Line_Items__c where Bundle_Item__c != null and Sales_Order__c in :SoiIds order by Products__c]) 
            {
                System.debug('bundleItemSOI : '+bundleItemSOI);
                if(bundleItemMap.containsKey(''+bundleItemSOI.Products__c+bundleItemSOI.Sales_Order__c)) {
                    bundleSOItemList.add(bundleItemSOI);
                    bundleItemMap.put(''+bundleItemSOI.Products__c+bundleItemSOI.Sales_Order__c, bundleSOItemList); 
                }  
                else {
                    bundleSOItemList = new List<SO_Line_Items__c>();
                    bundleSOItemList.add(bundleItemSOI);
                    
                    bundleItemMap.put(''+bundleItemSOI.Products__c+bundleItemSOI.Sales_Order__c, bundleSOItemList); 
                }
            }
        }
        catch(Exception e) {
            system.debug('Exception ex : '+e.getMessage()+', Cause : '+e.getCause()+', line number : ' + e.getLineNumber());
        }
        return bundleItemMap;
    }
}