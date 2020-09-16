public with sharing class DispatchManager {
	
    @future (callout=true)
    public static void sendShipmentToDispatch (string sId, boolean isOnHold, string business_code, string location_code, string api_key){
		Shipment__c s;
		
    	try{
    		s = [select Related_Sales_Order__c, Related_Sales_Order__r.Magento_order_No__c, Related_Sales_Order__r.Customer_Name__c, Related_Sales_Order__r.Customer_Name__r.First_Name__c,
								Related_Sales_Order__r.Customer_Name__r.Last_Name__c, Related_Sales_Order__r.Email__c, Related_Sales_Order__r.Billing_phone__c, Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c,
								Related_Sales_Order__r.Shipping_Street__c, Related_Sales_Order__r.Shipping_City__c, Related_Sales_Order__r.Shipping_State__c, Related_Sales_Order__r.Shipping_ZipCode__c,
								Related_Sales_Order__r.Location__Latitude__s, Related_Sales_Order__r.Location__Longitude__s, Related_Sales_Order__r.Note_for_Delivery_Company__C, 
								Purchase_Order__c, Purchase_Order__r.Suggested_Delivery_Comapny__c, Purchase_Order__r.Suggested_Delivery_Comapny__r.Name, 
								(select id, Name, PO_Line_Item__r.SO_Line_Item__r.Products__r.SKU_List__c, PO_Line_Item__r.Quantity__c, PO_Line_Item__r.Product_Cost__c, 
								PO_Line_Item__r.SO_Line_Item__r.Products__r.SKU__c, PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU_List__c, 
								PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU__c, PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__c, 
								PO_Line_Item__r.SO_Line_Item__r.Config_Product__c, PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU_List__c, 
								PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU__c, PO_Line_Item__r.Product__c, Shipment_Product_SKU__c, Shipment_Product_Quantity__c, Shipment_Product_Name__c
								from Shipment_Line_Itmes__r), Delivery_Company__r.DispatchTrack_Account_Name__c from Shipment__c where id = :sId];
    	}
    	catch (exception e){
			return;
		}
		String sentTo = (s.Purchase_Order__c != null  && s.Purchase_Order__r.Suggested_Delivery_Comapny__c != null) ? s.Purchase_Order__r.Suggested_Delivery_Comapny__r.Name : 'None';
    	try{
    		string xml = generateXML(s, isOnHold);
    		boolean succeededToSent = DispatchManager.sendToDispatch(xml, s.id, business_code, location_code, api_key, sentTo);
    		if (succeededToSent){
    			s.Sent_to_the_delivery_company__c = system.now();
    			update s;
			}
    	}
    	catch (exception e){ 
    		system.debug('e = ' + e.getmessage() + e.getlinenumber());
			insertLog('Failed', '', '', e.getmessage() + ' ' + e.getlinenumber(), sId, sentTo);
    	}
    }
	public static boolean sendToDispatch (string xml, string poId, string business_code, string location_code, string api_key, String sentTo){
		
		try {
		    Dispatch_Track_Setting__c setting = Dispatch_Track_Setting__c.getInstance();
	        String endpoint = 'https://' + setting.server__c +'/api/v1/imports/add_order';
	        HttpRequest req = new HttpRequest();
	        req.setMethod('POST');
	        //string body =  EncodingUtil.base64Encode(Blob.valueOf('code=4bf360181defad498&api_key=' + setting.api_key__c + '&data=' + xml));
	        //string body =  'business_code=rf360&location_code=deliverybydesignrenegadefurniture&api_key=' + setting.api_key__c + '&data=' + xml;
	        string body =  'business_code=' + business_code + '&location_code=' + location_code + '&api_key=' + api_key + '&data=' + xml;
	        req.setEndpoint(endpoint);
	        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
	        req.setBody(body);
	        
	        Http http = new Http();
	        HttpResponse res = http.send(req);
	        system.debug(res);
	        
	        
	        //Dom.Document doc = res.getBodyDocument();
	        
	        //Dom.XMLNode xmlResponse = doc.getRootElement();
	        
	        // if suceeded 
	        if (res.getStatusCode() == 200){
				insertLog('Succeeded', xml, res.getbody(), '', poId, sentTo);
				return true;
	        }
	        else {
				insertLog('Failed', xml, res.getbody(), '', poId, sentTo);
				return false;
	        }
		}
		catch(exception e){
			insertLog('Failed', xml, '', e.getmessage() + ' ' + e.getlinenumber(), poId, sentTo);
			return false;
		}
	}
	
	private static void insertLog (string status, string xml, string res, string error, string poId, String sendTo){
		Log__c log = new Log__c(Process__c = 'Purchase Order Shipped', Data__c = xml, Tries__c = 1, Status__c = status, Response__c = res, Error__c = error, Object_ID__c = poId, Sent_to__c = sendTo);
		list<Log__c> eLog = [select id, Tries__c from Log__c where Object_ID__c = :poId and Process__c = 'Purchase Order Shipped'];
		if (eLog.size() > 0){
			log.id = eLog[0].id;
			log.Tries__c = eLog[0].Tries__c + 1;
		}
		upsert log;
	}
	
	/*public static void exportData(){
	    Dispatch_Track_Setting__c setting = Dispatch_Track_Setting__c.getInstance();
        String endpoint = 'https://' + setting.server__c +'//api/v1/exports/orders.xml';
	        //String endpoint = 'https://' + setting.server__c +'/api/v1/imports/add_order';
	        HttpRequest req = new HttpRequest();
	        req.setMethod('POST');
	        //string body =  EncodingUtil.base64Encode(Blob.valueOf('code=4bf360181defad498&api_key=' + setting.api_key__c + '&data=' + xml));
	        string body =  'business_code=rf360&location_code=deliverybydesignrenegadefurniture&api_key=' + setting.api_key__c;// + '&date=2018-05-07';
	        req.setEndpoint(endpoint);
	        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
	        req.setBody(body);
	        
	        system.debug(req);
	        Http http = new Http();
	        HttpResponse res = http.send(req);
	        system.debug(res.getbody());
	}*/

	public static string generateXML(Shipment__c s, boolean isOnHold){
		
    	list<Shipment_Line_Item__c> slis = [select Shipment_Product_SKU__c, Shipment_Product_Quantity__c, PO_Line_Item__r.Product__c, Shipment_Product_Name__c from Shipment_Line_Item__c where (Shipment__r.Related_Sales_Order__c = :s.Related_Sales_Order__c and Shipment__r.Sent_to_the_delivery_company__c != null) or Shipment__c = :s.id];
		
		Dom.Document doc = new Dom.Document();
		doc.createRootElement('service_order', '', '');
		Dom.XmlNode node = doc.getRootElement();
		
		Dom.XmlNode numberNode = node.addChildElement('number', '', '');
		numberNode.addTextNode(s.Related_Sales_Order__r.Magento_order_No__c);
		Dom.XmlNode accountNode = node.addChildElement('account', '', '');
		String accountName = 'Renegade Furniture';
		if(s.Delivery_Company__r != null && String.isNotBlank(s.Delivery_Company__r.DispatchTrack_Account_Name__c)){
			accountName = s.Delivery_Company__r.DispatchTrack_Account_Name__c;
		}
		accountNode.addTextNode(accountName);
		Dom.XmlNode service_typeNode = node.addChildElement('service_type', '', '');
		service_typeNode.addTextNode('Delivery');
		Dom.XmlNode descriptionNode = node.addChildElement('description', '', '');
		descriptionNode.addTextNode('');
		
		Dom.XmlNode customerNode = node.addChildElement('customer', '', '');
		Dom.XmlNode customer_idNode = customerNode.addChildElement('customer_id', '', '');
		customer_idNode.addTextNode(s.Related_Sales_Order__r.Customer_Name__c);
		Dom.XmlNode first_nameNode = customerNode.addChildElement('first_name', '', '');
		first_nameNode.addTextNode(s.Related_Sales_Order__r.Customer_Name__r.First_Name__c);
		Dom.XmlNode last_nameNode = customerNode.addChildElement('last_name', '', '');
		last_nameNode.addTextNode(s.Related_Sales_Order__r.Customer_Name__r.Last_Name__c);
		Dom.XmlNode email = customerNode.addChildElement('email', '', '');
		email.addTextNode(s.Related_Sales_Order__r.Email__c);
		Dom.XmlNode phone1 = customerNode.addChildElement('phone1', '', '');
		if (s.Related_Sales_Order__r.Billing_phone__c != null){
			phone1.addTextNode(s.Related_Sales_Order__r.Billing_phone__c);
		}
		Dom.XmlNode phone2 = customerNode.addChildElement('phone2', '', '');
		phone2.addTextNode('');
		Dom.XmlNode phone3 = customerNode.addChildElement('phone3', '', '');
		phone3.addTextNode('');
		Dom.XmlNode address1 = customerNode.addChildElement('address1', '', '');
		address1.addTextNode(s.Related_Sales_Order__r.Shipping_Street__c);
		Dom.XmlNode address2 = customerNode.addChildElement('address2', '', '');
		address2.addTextNode('');
		Dom.XmlNode city = customerNode.addChildElement('city', '', '');
		city.addTextNode(s.Related_Sales_Order__r.Shipping_City__c);
		Dom.XmlNode state = customerNode.addChildElement('state', '', '');
		state.addTextNode(s.Related_Sales_Order__r.Shipping_State__c);
		Dom.XmlNode zip = customerNode.addChildElement('zip', '', '');
		zip.addTextNode(s.Related_Sales_Order__r.Shipping_ZipCode__c);
		Dom.XmlNode latitude = customerNode.addChildElement('latitude', '', '');
		if (s.Related_Sales_Order__r.Location__Latitude__s != null){
			latitude.addTextNode(string.valueof(s.Related_Sales_Order__r.Location__Latitude__s));
		}
		Dom.XmlNode longitude = customerNode.addChildElement('longitude', '', '');
		if (s.Related_Sales_Order__r.Location__Longitude__s != null){
			longitude.addTextNode(string.valueof(s.Related_Sales_Order__r.Location__Longitude__s));
		}
		
		
		Dom.XmlNode ExtraHoldStatus = customerNode.addChildElement('extra', '', '');
		Dom.XmlNode ShipmentHoldStatus = ExtraHoldStatus.addChildElement('ShipmentHoldStatus', '', '');
		system.debug('isOnHold = ' + isOnHold);
        if (isOnHold){
			ShipmentHoldStatus.addTextNode('On hold');
        }
        else{
			ShipmentHoldStatus.addTextNode('Ready for delivery');
        }
        
		// need to change
		if (s.Related_Sales_Order__r.Note_for_Delivery_Company__c != null){
			Dom.XmlNode notes  = node.addChildElement('notes', '', '');
			notes.setAttribute('count', '1');
			
			Dom.XmlNode note  = notes.addChildElement('note', '', '');
			note.setAttribute('created_at', '');
			note.setAttribute('author', '');
			note.setAttribute('note_type', 'Public');
			note.addTextNode(s.Related_Sales_Order__r.Note_for_Delivery_Company__c);
		}
		
		Dom.XmlNode items  = node.addChildElement('items', '', '');
		
		integer index = 1;
		for (Shipment_Line_Item__c li : slis){
			/*map<string, integer> skuQuantity = new map<string, integer>();
			system.debug('li.PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU_List__c = ' + li.PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU_List__c);
			string skuStr = li.PO_Line_Item__r.SO_Line_Item__r.Config_Product__c != null ? li.PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU_List__c : li.PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__c != null ? li.PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU_List__c : li.PO_Line_Item__r.SO_Line_Item__r.Products__r.SKU_List__c;
			if (skuStr != null && skuStr != '' && skuStr.split(',').size() > 0){
				for (string sku : skuStr.split(',')){
					if (!skuQuantity.containskey(sku)){
						skuQuantity.put(sku, 0);
					}
					skuQuantity.put(sku, skuQuantity.get(sku) + 1);
				}
			}
			else{
				skuQuantity.put(li.PO_Line_Item__r.SO_Line_Item__c != null ? li.PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU__c : li.PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__c != null ? li.PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU__c : li.PO_Line_Item__r.SO_Line_Item__r.Products__r.SKU__c, 1);
			}
			system.debug('skuQuantity = ' + skuQuantity);
			for (string sku : skuQuantity.keyset()){
				
				system.debug('sku = ' + sku);*/
				Dom.XmlNode item  = items.addChildElement('item', '', '');
				
				Dom.XmlNode sale_sequence  = item.addChildElement('sale_sequence', '', '');
				sale_sequence.addTextNode(string.valueof(index));
				Dom.XmlNode item_id = item.addChildElement('item_id', '', '');
				item_id.addTextNode(li.Shipment_Product_SKU__c);
				Dom.XmlNode serial_number  = item.addChildElement('serial_number', '', '');
				serial_number.addTextNode('');
				Dom.XmlNode description = item.addChildElement('description', '', '');
				description.addTextNode(li.Shipment_Product_Name__c != null && li.Shipment_Product_Name__c != '' ?  li.PO_Line_Item__r.Product__c + ' - ' + li.Shipment_Product_Name__c : li.PO_Line_Item__r.Product__c);
				Dom.XmlNode quantity  = item.addChildElement('quantity', '', '');
				quantity.addTextNode(string.valueof(li.Shipment_Product_Quantity__c));
				Dom.XmlNode location  = item.addChildElement('location', '', '');
				location.addTextNode('');
				Dom.XmlNode cube  = item.addChildElement('cube', '', '');
				cube.addTextNode('');
				Dom.XmlNode setup_time  = item.addChildElement('setup_time', '', '');
				setup_time.addTextNode('');
				Dom.XmlNode weight = item.addChildElement('weight', '', '');
				weight.addTextNode('');
				Dom.XmlNode price = item.addChildElement('price', '', '');
				price.addTextNode('');
				Dom.XmlNode countable = item.addChildElement('countable', '', '');
				countable.addTextNode('');
				Dom.XmlNode item_store_code = item.addChildElement('item_store_code', '', '');
				item_store_code.addTextNode('');
				
				index++;
			//}
		}
		
		Dom.XmlNode pre_reqs = node.addChildElement('pre_reqs', '', '');
		pre_reqs.addTextNode('');
		Dom.XmlNode amount = node.addChildElement('amount', '', '');
		amount.addTextNode('');
		Dom.XmlNode cod_amount = node.addChildElement('cod_amount', '', '');
		cod_amount.addTextNode('');
		Dom.XmlNode service_unit = node.addChildElement('service_unit', '', '');
		service_unit.addTextNode('');
		Dom.XmlNode delivery_date = node.addChildElement('delivery_date', '', '');
		/*if (isOnHold){
			delivery_date.addTextNode(string.valueof(system.today().addyears(30)));
		}
		else {
			delivery_date.addTextNode(string.valueof(system.today().adddays(1)));
		}*/
		Dom.XmlNode driver_id = node.addChildElement('driver_id', '', '');
		driver_id.addTextNode('');
		Dom.XmlNode truck_id = node.addChildElement('truck_id', '', '');
		truck_id.addTextNode('');
		Dom.XmlNode origin = node.addChildElement('origin', '', '');
		origin.addTextNode('');
		Dom.XmlNode stop_number = node.addChildElement('stop_number', '', '');
		stop_number.addTextNode('');
		Dom.XmlNode stop_time = node.addChildElement('stop_time', '', '');
		stop_time.addTextNode('');
		Dom.XmlNode service_time = node.addChildElement('service_time', '', '');
		service_time.addTextNode('');
		Dom.XmlNode request_time_window_start = node.addChildElement('request_time_window_start', '', '');
		request_time_window_start.addTextNode('');
		Dom.XmlNode request_time_window_end = node.addChildElement('request_time_window_end', '', '');
		request_time_window_end.addTextNode('');
		Dom.XmlNode delivery_time_window_start = node.addChildElement('delivery_time_window_start', '', '');
		delivery_time_window_start.addTextNode('');
		Dom.XmlNode delivery_time_window_end = node.addChildElement('delivery_time_window_end', '', '');
		delivery_time_window_end.addTextNode('');
		Dom.XmlNode delivery_charge = node.addChildElement('delivery_charge', '', '');
		delivery_charge.addTextNode('');
		Dom.XmlNode taxes = node.addChildElement('taxes', '', '');
		taxes.addTextNode('');
		Dom.XmlNode store_code = node.addChildElement('store_code', '', '');
		store_code.addTextNode('');
		
		system.debug('doc.toXmlString() = ' + doc.toXmlString());
		
		string xmlStr = doc.toXmlString();
		xmlStr = xmlStr.replace(' xmlns=""', '');
		return xmlStr;
	}
}