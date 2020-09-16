public with sharing class IDSManager {

    @future (callout=true)
	public static void placeOrder(string sId, boolean isOnHold, string hubNumber, boolean isUpdate, boolean isIDS, boolean isGG, boolean isDeliveright, boolean isP2P){
		
		IDS_Setting__c setting = IDS_Setting__c.getInstance();
		G_G_setting__c settingGG = G_G_setting__c.getInstance();
		Deliveright_Setting__c settingDeliveright = Deliveright_Setting__c.getInstance();
		P2P_setting__c settingP2P = P2P_setting__c.getInstance();
		
		Shipment__c s = [SELECT Name, Related_Sales_Order__r.Do_Not_update_DC_with_Retail_Value__c, Related_Sales_Order__r.Name, Related_Sales_Order__r.Magento_order_No__c, Related_Sales_Order__r.Discount_AmountTotal__c, Related_Sales_Order__r.Customer_Name__c, Related_Sales_Order__r.Customer_Name__r.First_Name__c, Purchase_Order__r.Manufacturer_Name__c,  
							Related_Sales_Order__r.Customer_Name__r.Last_Name__c, Related_Sales_Order__r.Email__c, Related_Sales_Order__r.Billing_phone__c, Related_Sales_Order__r.Shipping_Phone__c, Related_Sales_Order__r.Customer_Name__r.Website, Related_Sales_Order__r.Warranty_Order__c,
							Related_Sales_Order__r.Shipping_Street__c, Related_Sales_Order__r.Shipping_City__c, Related_Sales_Order__r.Shipping_State__c, Related_Sales_Order__r.Shipping_ZipCode__c, Related_Sales_Order__r.Shipping_Mobile__c, Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c,
							Related_Sales_Order__r.Location__Latitude__s, Related_Sales_Order__r.Location__Longitude__s, Related_Sales_Order__r.Note_for_Delivery_Company__C, Related_Sales_Order__r.createddate, Related_Sales_Order__r.Sum_of_Retail_Value__c,
							(select id, Name, PO_Line_Item__r.Quantity__c, PO_Line_Item__r.Product_Cost__c, Shipment_Product_Weight__c, Product_SKU__c, PO_Line_Item__r.SO_Line_Item__r.Quantity__c,
							Pickup_Date_Actual__c,Pickup_Date_Expected__c, 
							PO_Line_Item__r.SO_Line_Item__r.Products__r.SKU__c, PO_Line_Item__r.SO_Line_Item__r.Row_Total__c, PO_Line_Item__r.SO_Line_Item__r.ProductImageUrl__c,
							PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU__c, PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__c, PO_Line_Item__r.SO_Line_Item__r.Price__c, 
							PO_Line_Item__r.SO_Line_Item__r.Config_Product__c, Shipment_Product_Name__c, Description__c, Product_Name__c, PO_Line_Item__r.SO_Line_Item__r.name,
							PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU__c, PO_Line_Item__r.Product__c, Shipment_Product_SKU__c, Shipped_Quantity_Actual__c, Shipment_Item_Status__c
							FROM Shipment_Line_Itmes__r), Purchase_Order__c, Purchase_Order__r.Suggested_Delivery_Comapny__r.Name
							FROM Shipment__c WHERE id = :sId];
							
		
		Order order = new Order();
		if (isDeliveright){
			order.order_id = s.Related_Sales_Order__r.Magento_order_No__c + ' ' + s.Related_Sales_Order__r.Name;
		}else {
			order.order_id = s.Related_Sales_Order__r.Magento_order_No__c;
		}
		order.order_date = date.valueof(s.Related_Sales_Order__r.createddate);
		order.transaction_id = s.id;
		order.transaction_type = isUpdate ? 'update' : 'create';
		order.transaction_date = system.today();
		order.sending_party = '3479307957'; //
		order.receiving_party = '9096287737';//
		if (isGG){
			order.receiving_party = '8138396111';
		}
		if (isP2P){
			order.receiving_party = '8667876356';
		}
		order.job_work_order = null;
		order.ship_to_info = new ShippingInfo();
		order.ship_to_info.first_name = s.Related_Sales_Order__r.Customer_Name__r.First_Name__c;
		order.ship_to_info.last_name = s.Related_Sales_Order__r.Customer_Name__r.Last_Name__c;
		order.ship_to_info.street = s.Related_Sales_Order__r.Shipping_Street__c;
		order.ship_to_info.city = s.Related_Sales_Order__r.Shipping_City__c;
		order.ship_to_info.state = s.Related_Sales_Order__r.Shipping_State__c;
		order.ship_to_info.country = 'US';
		order.ship_to_info.zipcode = s.Related_Sales_Order__r.Shipping_ZipCode__c;
		order.ship_to_info.phone = s.Related_Sales_Order__r.Shipping_phone__c;
		order.ship_to_info.mobile = s.Related_Sales_Order__r.Shipping_Mobile__c;
		order.ship_to_info.email = s.Related_Sales_Order__r.Email__c;
		order.scheduled_date = null;
		order.warehouse_id = integer.valueof(hubNumber);
		order.sales_rep = s.Related_Sales_Order__r.Customer_Name__r.Website;
		if (!s.Related_Sales_Order__r.Do_Not_update_DC_with_Retail_Value__c){
			order.order_total = s.Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c;
		}
		else {
			order.order_total = 0;
		}
		order.order_notes = s.Related_Sales_Order__r.Note_for_Delivery_Company__C;
		order.delivery_directive = isOnHold ?  'On hold' : 'Ready for delivery';
		order.delivery_notes = s.Related_Sales_Order__r.Note_for_Delivery_Company__C;
		//order.order_discount = s.Related_Sales_Order__r.Discount_AmountTotal__c;
		order.order_lines = new list<ItemOrder>();
		
		map<string, ItemOrder> itemOrderMap = new map<string, ItemOrder>();
		set<string> poIds = new set<string>();
		for (Shipment_Line_Item__c li : s.Shipment_Line_Itmes__r){
	        ItemOrder itemOrder = new ItemOrder();
	        if (itemOrderMap.containskey(li.PO_Line_Item__r.SO_Line_Item__r.name)){
	        	itemOrder = itemOrderMap.get(li.PO_Line_Item__r.SO_Line_Item__r.name);
	        }
	        else{
	        	itemOrder.order_line_id = li.PO_Line_Item__r.SO_Line_Item__r.name;
	        	itemOrder.order_line_product_SKU = li.Product_SKU__c != null && li.Product_SKU__c.contains('-') ? li.Product_SKU__c.split('-',2)[1] : li.Product_SKU__c ;
	        	itemOrder.order_line_product_name= li.Product_Name__c;
	        	itemOrder.order_line_mfg_id = s.Purchase_Order__r.Manufacturer_Name__c;
	        	itemOrder.order_line_product_description = null;
	        	itemOrder.order_line_product_image = li.PO_Line_Item__r.SO_Line_Item__r.ProductImageUrl__c;
		        itemOrder.order_line_retail_price = null;
		        itemOrder.order_line_sale_price = double.valueof(li.PO_Line_Item__r.SO_Line_Item__r.Price__c);
		        itemOrder.order_line_product_quantity = integer.valueof(li.PO_Line_Item__r.SO_Line_Item__r.Quantity__c);
		        itemOrder.order_line_po = s.Purchase_Order__c;
		        itemOrder.order_line_serial_no = null;
		        itemOrder.order_line_number_of_packages = 1;
	        	
	        	itemOrder.shipment_items = new list<shipment_item>();
	        	itemOrderMap.put(li.PO_Line_Item__r.SO_Line_Item__r.name, itemOrder);
	        	order.order_lines.add(itemOrder);
	        }
	        shipment_item si = new shipment_item();
	        si.shipment_item_id = li.id;
	        si.shipment_item_SKU = li.Shipment_Product_SKU__c != null && li.Shipment_Product_SKU__c.contains('-') ? li.Shipment_Product_SKU__c.split('-',2)[1] : li.Shipment_Product_SKU__c ;
	        si.shipment_item_name = li.Shipment_Product_Name__c;
	        si.shipment_item_description = li.Description__c;
	        si.shipment_item_image = null;
	        si.shipment_item_quantity = integer.valueof(li.Shipped_Quantity_Actual__c);
	        si.shipment_item_volume = 1;
	        si.shipment_item_weight = li.Shipment_Product_Weight__c;
	        si.shipment_item_status = li.Shipment_Item_Status__c;
			si.shipment_pickup_date_actual = li.Pickup_Date_Actual__c;
			si.shipment_pickup_date_expected = li.Pickup_Date_Expected__c;
	        itemOrder.shipment_items.add(si);
		}
		
	    system.debug('order = ' + order);
		
	    string requestJson = Json.serialize(order);
		system.debug('requestJson = ' + requestJson);
		
		String sentTo = (s.Purchase_Order__c != null && s.Purchase_Order__r.Suggested_Delivery_Comapny__c != null) ? s.Purchase_Order__r.Suggested_Delivery_Comapny__r.Name : 'None';
		try {
			
      		HttpRequest req = new HttpRequest();
      		if (isIDS){
				req.setHeader('Authorization', 'Basic ' + setting.Token__c);
          		req.setEndpoint(setting.URL__c);
      		}
      		else if (isGG){
				req.setHeader('IDLS-Authorization', settingGG.Token__c);
          		req.setEndpoint(settingGG.URL__c);
      		}
      		else if (isP2P){
				req.setHeader('IDLS-Authorization', settingP2P.Token__c);
          		req.setEndpoint(settingP2P.URL__c);
      		}
      		else if (isDeliveright){
      			req.setEndpoint(settingDeliveright.URL__c);
      		}
          	req.setHeader('Content-Type', 'application/json');
          	req.setMethod('POST');
          	req.setBody(requestJson);
			req.setTimeout(120000);
          	Http h = new Http();
          	HttpResponse res = Test.isRunningTest() ? null : h.send(req);
	    	system.debug('requestJson = ' + res);
	    	system.debug('requestJson = ' + res.getbody());
      		ids_response ids_res = ((list<ids_response>)JSON.deserialize('[' + res.getbody() + ']', list<ids_response>.class))[0];

			  if (ids_res != null && ids_res.success){
				insertLog('Succeeded', requestJson, res.getbody(), ids_res.warning != null && ids_res.warning.size() > 0 ? string.valueof(ids_res.warning) : '', sId, sentTo);
    			s.Sent_to_the_delivery_company__c = system.now();
    			update s;
    			if (!isOnHold){
    				Sales_Order__c so = new Sales_Order__c(id = s.Related_Sales_Order__c);
    				if (s.Related_Sales_Order__r.Warranty_Order__c){
    					so.Warranty_Task_Create__c = true;
    				}
    				update so;
    			}
	        }
	        else if (ids_res != null && ids_res.errorMessages != null && ids_res.errorMessages.size() > 0){
				insertLog('Failed', requestJson, res.getbody(), string.valueof(ids_res.errorMessages), sId, sentTo);
	        }
	        else {
				insertLog('Failed', requestJson, res.getbody(), '', sId, sentTo);
	        }
		}
		catch (exception e){
			System.debug('Error: ' + e.getmessage());
			insertLog('Failed', requestJson, '', e.getmessage() + ' ' + e.getlinenumber(), sId, sentTo);
		}
		
	}
	
	private static void insertLog (string status, string xml, string res, string error, string sId, String sendTo){
		Log__c log = new Log__c(Process__c = 'Purchase Order Shipped', Data__c = xml, Tries__c = 1, Status__c = status, Response__c = res, Error__c = error, Object_ID__c = sId, Sent_to__c = sendTo);
		list<Log__c> eLog = [select id, Tries__c from Log__c where Object_ID__c = :sId and Process__c = 'Purchase Order Shipped'];
		if (eLog.size() > 0){
			log.id = eLog[0].id;
			log.Tries__c = eLog[0].Tries__c + 1;
		}
		upsert log;
	}
	
	public class Order{
		public string order_id {get; set;}
		public date order_date {get; set;}
		public string transaction_id {get; set;}
		public string transaction_type {get; set;}
		public date transaction_date {get; set;}
		public date scheduled_date {get; set;}
		public string sending_party {get; set;}
		public string receiving_party {get; set;} 
		public string job_work_order {get; set;}
		public ShippingInfo ship_to_info {get; set;}
		//public ShippingInfo bill_to_info {get; set;}
		public integer warehouse_id {get; set;}
		public string sales_rep {get; set;}
		public decimal order_total {get; set;}
		//public decimal order_discount {get; set;}
		public string order_notes {get; set;}
		public string delivery_directive {get; set;}
		public string delivery_notes {get; set;}
		public list<ItemOrder> order_lines {get; set;}
		
	}
	public class ShippingInfo{
		public string first_name {get; set;}
		public string last_name {get; set;}
		public string street {get; set;}
		public string city {get; set;}
		public string state {get; set;}
		public string country {get; set;}
		public string zipcode {get; set;}
		public string phone {get; set;}
		public string mobile {get; set;}
		public string email {get; set;}
	}
	public class ItemOrder{
		public string order_line_id {get; set;}
		public string order_line_product_SKU {get; set;}
		public string order_line_product_name {get; set;}
		public string order_line_mfg_id {get; set;}
		public string order_line_product_description {get; set;}
		public string order_line_product_image {get; set;}
		public string order_line_retail_price {get; set;}
		public decimal order_line_sale_price {get; set;}
		public integer order_line_product_quantity {get; set;}
		public string order_line_po {get; set;}
		public string order_line_serial_no {get; set;}
		public integer order_line_number_of_packages {get; set;}
		public list<shipment_item> shipment_items {get; set;}
	}
		
	public class shipment_item{
		public string shipment_item_id {get; set;}
		public string shipment_item_SKU {get; set;}
		public string shipment_item_name {get; set;}
		public string shipment_item_description {get; set;}
		public string shipment_item_image {get; set;}
		public integer shipment_item_quantity {get; set;}
		public integer shipment_item_volume {get; set;}
		public string shipment_item_weight {get; set;}
		public string shipment_item_status {get; set;}
		public date shipment_pickup_date_actual {get; set;}
		public date shipment_pickup_date_expected {get; set;}
	}
		
	public class ids_response{
		public boolean success {get; set;}
		public string message {get; set;}
		public integer status {get; set;}
		public list<string> errorMessages {get; set;}
		public list<string> warning {get; set;}
	}
}