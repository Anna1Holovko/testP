public class bolcontroller {
    
    public Shipment__c shipment{set;get;}
    public list<Shipment_Line_Item__c> shplineitems;
    public decimal quantity{set;get;}  
    public decimal weight{set;get;}
    public bolcontroller()
    {
        try
        { 
            shipment= new Shipment__c();
            quantity=0;
            weight=0;
            if(apexpages.currentPage().getparameters().get('id') !='')
            {
                shipment=[select id, name,Delivery_Company__c,Trucking_Company_name__c,Customer_Name__c,Carrier__c,	
                          Magento_order_No__c,recordtype.name,Delivery_Company_Name__c,Purchase_Order__r.name,
                          Purchase_Order__r.Ship_From__r.name,Purchase_Order__r.Ship_From__r.BillingStreet,
                          Purchase_Order__r.Ship_From__r.BillingCity,Purchase_Order__r.Ship_From__r.BillingState,
                          Purchase_Order__r.Ship_From__r.BillingCountry,Purchase_Order__r.Ship_From__r.BillingPostalCode,
                          Purchase_Order__r.Ship_From__r.Phone,Total_Cubed_Ft__c, Related_Sales_Order__r.Magento_order_No__c,
                          Related_Sales_Order__r.Ship_to__c,Related_Sales_Order__r.Shipping_Street__c,
                          Related_Sales_Order__r.Shipping_City__c,Related_Sales_Order__r.Shipping_State__c,
                          Related_Sales_Order__r.Shipping_ZipCode__c,Related_Sales_Order__r.Shipping_Phone__c,
                          Delivery_Company__r.Name,Delivery_Company__r.ShippingStreet,Delivery_Company__r.ShippingCity,
                          Delivery_Company__r.ShippingState,Delivery_Company__r.ShippingCountry,Delivery_Company__r.Phone,
                          Delivery_Company__r.ShippingPostalcode from Shipment__c where id=:apexpages.currentPage().getparameters().get('id')]; 
                String fileName = 'BOL_' + shipment.name + '.pdf';
                Apexpages.currentPage().getHeaders().put('content-disposition', 'filename=' + fileName);
            }
        }
        catch(exception ex)
        {
            system.debug('Error in Line Number '+ex.getLineNumber()+' Error message '+ex.getMessage());
        }
    }
    
    public list<Shipment_Line_Item__c> getshplineitems() 
    {
        try
        {
            shplineitems = new list<Shipment_Line_Item__c>();
            if(apexpages.currentpage().getparameters().get('id')!=''){
                for(Shipment_Line_Item__c shplineitemsObj : [select id,Name,Product_Name__c,Product_SKU__c,Quantity__c,Shipment_Item_Status__c,Damage_Action__c,Repair_Amount__c, Shipment_Product_Weight__c, Shipment_Product_Name__c,
                                                             Shipped_Quantity_Actual__c,Weight_Pounds__c,Shipment_Product_SKU__c,Box_Info__c,Cubed_Ft__c, Shipment_Product_Quantity__c from Shipment_Line_Item__c 
                                                             where Shipment__c=:apexpages.currentpage().getparameters().get('id')])
                {
                    shplineitems.add(shplineitemsObj);
                    quantity=quantity+shplineitemsObj.Shipped_Quantity_Actual__c;
                    if (shplineitemsObj.Shipment_Product_Weight__c != null && shplineitemsObj.Shipment_Product_Weight__c != ''){
                    	Decimal w = decimal.valueof(shplineitemsObj.Shipment_Product_Weight__c.replaceAll('[^0-9.]', ''));
	                    if (shplineitemsObj.Shipment_Product_Quantity__c != null && shplineitemsObj.Shipment_Product_Quantity__c != 0){
	                    	w = w * shplineitemsObj.Shipment_Product_Quantity__c;
	                    	shplineitemsObj.Shipment_Product_Weight__c = string.valueof(w);
	                    }
                    	weight=weight + w;
                    }
                   // quantity=quantity+shplineitemsObj.Quantity__c;
                   // weight=weight+(shplineitemsObj.Quantity__c * shplineitemsObj.Weight_Pounds__c);
                }
            }
        }
        catch(exception ex)
        {
            system.debug('Error in Line Number '+ex.getLineNumber()+' Error message '+ex.getMessage());
        }
        return shplineitems;
    }
}