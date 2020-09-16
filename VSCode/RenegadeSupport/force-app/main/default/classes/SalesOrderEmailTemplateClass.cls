public class SalesOrderEmailTemplateClass 
{
    public Id salesOrderId {get;set;}
    public Id invoiceId {get;set;}
    public map<string,SOItemsWrapper> getSoRelatedList() 
    {
        system.debug('in getSoRelatedList');
        map<string,SOItemsWrapper> soRelatedList = new map<string,SOItemsWrapper>();
        
        list<SO_Line_Items__c> BundelSOitems = [select id,ProductImageUrl__c, FedExable__c,Products__r.Select_Manufacturer__r.name,Products__r.recordtype.name,Products__r.recordtypeid,Custom_Price__c,TaxAmount__c,Sub_Total__c,Price__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Tax_Amount__c,Bundle_Item__r.Include__c,
                                                  Products__r.Select_Manufacturer__r.Direct_Shipping__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Quantity_Invoiced__c,Sales_Order__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__r.Product__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Total_Weight_Pounds__c,
                                                  Products__r.Select_Manufacturer__r.Ship_To_HUB__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Item__c from SO_Line_Items__c where Bundle_Item__c != null and Sales_Order__c =:salesOrderId and Item__c != 'Cancelled'];
        system.debug('BundelSOitems'+BundelSOitems.size());
        for(SO_Line_Items__c SoiItem : [select id,ProductImageUrl__c, FedExable__c,Products__r.RecordType.Name,Products__r.recordtypeid,TaxAmount__c,Sub_Total__c,Price__c,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Quantity_Refunded__c,Total_Weight_Pounds__c,Products__r.Select_Manufacturer__r.Order_Communication_Type__c,Products__r.Select_Manufacturer__r.Website,Bundle_Item__r.Product__c,Products__r.Select_Manufacturer__r.Ship_To_HUB__c,Tax_Amount__c,
                                       Products__r.Select_Manufacturer__r.Direct_Shipping__c,Products__r.Select_Manufacturer__c,Promotion_Brand__c,Quantity__c,DiscountAmount__c,Row_Total__c,Custom_Price__c,Quantity_Invoiced__c,Sales_Order__c,Sales_Order__r.Order_Status__c,Tax_Percent__c,UnitPrice__c,Bundle_Item__c,Config_Product__c,Product_Name__c,ProductSKU__c,Product_Url__c,Item__c from SO_Line_Items__c where Sales_Order__c =:salesOrderId and Bundle_Item__c = null and Item__c != 'Cancelled' ORDER BY Name ASC])
        { 
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
        system.debug('soRelatedList'+soRelatedList);
        return soRelatedList;
    }
    
    public List<Invoice_Line_Item__c> getinvoiceItems()
    {
        List<Invoice_Line_Item__c> invoiceItemsList = new List<Invoice_Line_Item__c>();
        for(Invoice_Line_Item__c invoiceItem : [SELECT Name,Items_invoiced__r.ProductSKU__c,Product_Name__c,Items_invoiced__r.ProductImageUrl__c,Quantity_Refunded__c,Unit_Price__c,Discount_Amount__c,Sub_Total_Hidden__c,Custom_Refund__c,Invoice__r.Reason_for_Refund__c,Invoice__r.Discount_Amount__c,Quantity_Invoiced__c,Invoice__r.Recordtype.name FROM Invoice_Line_Item__c WHERE Invoice__c =: invoiceId AND Items_invoiced__r.Products__r.RecordType.Name!='Protection Plan' ORDER BY Name DESC ]) {
            invoiceItemsList.add(invoiceItem);
        }
        for(Invoice_Line_Item__c invoiceItem : [SELECT Name,Items_invoiced__r.ProductSKU__c,Product_Name__c,Items_invoiced__r.ProductImageUrl__c,Quantity_Refunded__c,Unit_Price__c,Discount_Amount__c,Sub_Total_Hidden__c,Custom_Refund__c,Invoice__r.Reason_for_Refund__c,Invoice__r.Discount_Amount__c,Quantity_Invoiced__c,Invoice__r.Recordtype.name FROM Invoice_Line_Item__c WHERE Invoice__c =: invoiceId AND Items_invoiced__r.Products__r.RecordType.Name='Protection Plan' ORDER BY Name DESC ]) {
            invoiceItemsList.add(invoiceItem);
        }
        return invoiceItemsList;
    }
    
    public class SOItemsWrapper
    {
        public SO_Line_Items__c SoItem {get; set;}
        public list<SO_Line_Items__c> bundleList{get; set;}  
        
        public SOItemsWrapper(SO_Line_Items__c SOI,list<SO_Line_Items__c> bundle)
        {
            SoItem = SOI;
            bundleList = bundle;
        }
    }
}