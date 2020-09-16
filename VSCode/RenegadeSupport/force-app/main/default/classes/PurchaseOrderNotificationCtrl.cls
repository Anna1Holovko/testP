public class PurchaseOrderNotificationCtrl {
	
    public Id poId {get;set;}
    public List<poLineItem> getPoLineItems()
    {
        List<poLineItem> ret = new List<poLineItem>();
        List<PO_Line_Items__c> poLineItems;
        poLineItems = [SELECT Partial_product_ordered__c, SKU_name_and_list__c, Product_Image_URL__c, Quantity__c, Product_SKU__c, Product__c, Parts_Description__c, Parts_ordered__c FROM PO_Line_Items__c WHERE Purchase_Order__c =: poId and SO_Line_Item__r.Item__c != 'Cancelled'];
        if (poLineItems != null && poLineItems.size() >0){
	        
	        for (PO_Line_Items__c li : poLineItems){
	        	if (!li.Partial_product_ordered__c){
		        	poLineItem pli = new poLineItem();
	        		pli.image = li.Product_Image_URL__c;
	        		pli.quantity = li.Quantity__c;
	        		pli.sku = li.Product_SKU__c;
	        		pli.name = li.Product__c;
	        		if (li.Parts_ordered__c){
	        			pli.is_part = true;
	        			pli.description = li.Parts_Description__c;
	        		}
	        		ret.add(pli);
	        	}
        		else {
        			for (productInfo pi : (list<productInfo>)json.deserialize(li.SKU_name_and_list__c, list<productInfo>.class)){
		        		poLineItem pli = new poLineItem();
		        		pli.image = li.Product_Image_URL__c;
		        		pli.quantity = li.Quantity__c;
		        		pli.sku = pi.sku;
		        		pli.name = pi.name;
	        			ret.add(pli);
        			}
	        	}
        	}
        	return ret;
    	}
        return new List<poLineItem>();
    }
	public class poLineItem {
		public string image {get; set;}
		public decimal quantity {get; set;}
		public string sku {get; set;}
		public string name {get; set;}
		public string description {get; set;}
		public boolean is_part {get; set;}
	}
    
    public class productInfo{
    	public string sku {get; set;}
    	public string name {get; set;}
    	public string weight {get; set;}
		public string dimensions {get; set;}
		public Decimal cost {get; set;}
    }
}