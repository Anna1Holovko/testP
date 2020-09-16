/**
 * @File Name          : FidelitoneManager.cls
 * @Description        : 
 * @Author             : Vladimir Zhutenko
 * @Group              : 
 * @Last Modified By   : Vladimir Zhutenko
 * @Last Modified On   : 4/7/2020, 6:09:49 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/7/2020   Vladimir Zhutenko     Initial Version
**/
public with sharing class FidelitoneManager {
	private static Integer calloutTries = 2;
    @future (callout=true)
	public static void placeOrder(String sId, Boolean isOnHold, String hubNumber, Boolean isUpdate){
		
		Fideliton_Setting__c setting = Fideliton_Setting__c.getInstance();
		
		Shipment__c s = [SELECT Name, Related_Sales_Order__c, Related_Sales_Order__r.Do_Not_update_DC_with_Retail_Value__c, Related_Sales_Order__r.Retail_value_sent_to_Fidelitone__c, Related_Sales_Order__r.Retail_Value_Sent_to_Delivery_Company__c, Related_Sales_Order__r.Magento_order_No__c, Related_Sales_Order__r.Customer_Name__c, Related_Sales_Order__r.Customer_Name__r.First_Name__c, Purchase_Order__r.Manufacturer_Name__c, 
							Related_Sales_Order__r.Sub_Total__c, Related_Sales_Order__r.Discount_AmountTotal__c, Related_Sales_Order__r.Sum_of_Retail_Value__c, Related_Sales_Order__r.Warranty_Order__c, Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c,
							Related_Sales_Order__r.Customer_Name__r.Last_Name__c, Related_Sales_Order__r.Email__c, Related_Sales_Order__r.Billing_phone__c, Related_Sales_Order__r.Shipping_Phone__c, Related_Sales_Order__r.Shipping_Mobile__c,
							Related_Sales_Order__r.Shipping_Street__c, Related_Sales_Order__r.Shipping_City__c, Related_Sales_Order__r.Shipping_State__c, Related_Sales_Order__r.Shipping_ZipCode__c,
							Related_Sales_Order__r.Location__Latitude__s, Related_Sales_Order__r.Location__Longitude__s, Related_Sales_Order__r.Note_for_Delivery_Company__C, Related_Sales_Order__r.Ship_to__c,
							(select id, Name, PO_Line_Item__r.Quantity__c, PO_Line_Item__r.Product_Cost__c, 
							PO_Line_Item__r.SO_Line_Item__r.Products__r.SKU__c, 
							PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU__c, PO_Line_Item__r.SO_Line_Item__r.Bundle_Item__c, PO_Line_Item__r.SO_Line_Item__r.Price__c, 
							PO_Line_Item__r.SO_Line_Item__r.Config_Product__c, Shipment_Product_Name__c,
							PO_Line_Item__r.SO_Line_Item__r.Config_Product__r.SKU__c, PO_Line_Item__r.Product__c, Shipment_Product_SKU__c, Shipped_Quantity_Actual__c
							from Shipment_Line_Itmes__r), Purchase_Order__c, Purchase_Order__r.Suggested_Delivery_Comapny__c, Purchase_Order__r.Suggested_Delivery_Comapny__r.Name 
							FROM Shipment__c where id = :sId];
							
		
		FidelitoneComOrders.ArrayOfOrder orders = new FidelitoneComOrders.ArrayOfOrder();
		FidelitoneComOrders.Order order = new FidelitoneComOrders.Order();
		
		order.Header = new FidelitoneComOrders.Header();
		order.Addresses = new FidelitoneComOrders.ArrayOfAddress();
		order.DetailLines = new FidelitoneComOrders.ArrayOfDetailLine();
		
		
        order.Header.OrderNUmber = s.Related_Sales_Order__r.Magento_order_No__c;
        order.Header.PurchaseOrderNumber = s.name;
        order.Header.OrderType = 'Order';
        order.Header.Whse = hubNumber;
        //order.Header.ExpectedDeliveryDate = s.Delivery_Date_Expected__c;
        //order.Header.ProductionFlag = false;
        if (isOnHold){
        	//order.Header.ExpectedDeliveryDate = system.today().adddays(1);
        	order.Header.CustomerField1 = 'On hold';
        }
        else{
        	order.Header.CustomerField1 = 'Ready for delivery';
        	//order.Header.ExpectedDeliveryDate = system.today().adddays(30);
        }
        //order.Header.CustomerField2 = 'test';
        //order.Header.CustomerField3 = 'test';
        //order.Header.StateTaxRate = 1.00;
        //order.Header.CountyTaxRate = 1.00;
        //order.Header.CityTaxRate = 1.00;
        order.Header.PaymentMethod = 'Order';
        //order.Header.PaymentID = 'test';
        order.Header.ModeOfTransportation = 'upsg – ups ground';
        //order.Header.ShippingCharge = 1.00;
        //order.Header.SalesPerson = 'test';
        order.Header.ServiceLevel = 'regular';
        //order.Header.Client = 'test';
        if (s.Related_Sales_Order__r.Note_for_Delivery_Company__C != null && s.Related_Sales_Order__r.Note_for_Delivery_Company__C != ''){
        order.Header.Comments = new FidelitoneComOrders.ArrayOfHeaderComment();
	        order.Header.Comments.HeaderComment =  new list<FidelitoneComOrders.HeaderComment>();
	        FidelitoneComOrders.HeaderComment Comment = new FidelitoneComOrders.HeaderComment();
	        Comment.Comment = s.Related_Sales_Order__r.Note_for_Delivery_Company__C;
	        order.Header.Comments.HeaderComment.add(Comment);
        }
        
        FidelitoneComOrders.Address address = new FidelitoneComOrders.Address();
        address.Name = s.Related_Sales_Order__r.Ship_to__c;//s.Related_Sales_Order__r.Customer_Name__r.First_Name__c + '-' + s.Related_Sales_Order__r.Customer_Name__r.Last_Name__c;
        address.Address1 = s.Related_Sales_Order__r.Shipping_Street__c;
        //address.Address2 = 'test';
        //address.Address3 = 'test';
        address.City = s.Related_Sales_Order__r.Shipping_City__c;
        address.State = Utilities.getStateinitial(s.Related_Sales_Order__r.Shipping_State__c);
        address.Zip = s.Related_Sales_Order__r.Shipping_ZipCode__c;
        //address.County = 'test';
        address.Country = 'US';
        address.Email = s.Related_Sales_Order__r.Email__c;
        //address.PhoneWork = 'test';
        address.PhoneHome = formatPhone(s.Related_Sales_Order__r.Shipping_phone__c);
        if (s.Related_Sales_Order__r.Shipping_Mobile__c != null){
        	address.PhoneCell = formatPhone(s.Related_Sales_Order__r.Shipping_Mobile__c);
        }
        address.AddressType = 'ShipTo';
        order.Addresses.Address = new list<FidelitoneComOrders.Address>();
        order.Addresses.Address.add(address);
        
	   	order.DetailLines.DetailLine = new list<FidelitoneComOrders.DetailLine>();
        
        
		integer index = 1;
		set<string> poIds = new set<string>();
		if(!isUpdate){
			for (Shipment_Line_Item__c li : s.Shipment_Line_Itmes__r){
				FidelitoneComOrders.DetailLine line = new FidelitoneComOrders.DetailLine();
				line.ItemCode = li.Shipment_Product_SKU__c;
				line.CustomerItemNumber = string.valueof(index);
				line.OrderQty = integer.valueof(li.Shipped_Quantity_Actual__c);
				line.UnitOfMeasure = 'Each';
				line.StopType = 'delivery';
				line.CustomerField1 = li.Shipment_Product_Name__c;
				line.CustomerField2 = s.Purchase_Order__r.Manufacturer_Name__c;
				line.CustomerField3 = li.id;
				if (!poIds.contains(li.PO_Line_Item__c)){
					line.RetailValue = 0;//double.valueof(li.PO_Line_Item__r.SO_Line_Item__r.Price__c);
					poIds.add(li.PO_Line_Item__c);
				}
				else {
					line.RetailValue = 0;
				}
				order.DetailLines.DetailLine.add(line);
				index ++;
			}
		}
		if (isUpdate || (!isOnHold && !s.Related_Sales_Order__r.Retail_value_sent_to_Fidelitone__c && !s.Related_Sales_Order__r.Do_Not_update_DC_with_Retail_Value__c)){
	        FidelitoneComOrders.DetailLine line = new FidelitoneComOrders.DetailLine();
	        line.ItemCode = 'retail_value';
	        line.CustomerItemNumber = '0';
	        line.OrderQty = 1;
	        line.UnitOfMeasure = 'Each';
	        line.StopType = 'delivery';
	        if (!isUpdate){
	        	line.RetailValue = s.Related_Sales_Order__r.Retail_Value_for_Delivery_Company__c;//s.Related_Sales_Order__r.Sub_Total__c - s.Related_Sales_Order__r.Discount_AmountTotal__c;
	        }
	        /*else{
	        	line.RetailValue = s.Related_Sales_Order__r.Sub_Total__c;
	        }*/
	        order.DetailLines.DetailLine.add(line);
		}
		
		orders.Order = new list<FidelitoneComOrders.Order>();
		orders.Order.add(order);

		String sentTo = (s.Purchase_Order__c != null  && s.Purchase_Order__r.Suggested_Delivery_Comapny__c != null) ? s.Purchase_Order__r.Suggested_Delivery_Comapny__r.Name : 'None';
		
		try {
			FidelitoneComOrders.ArrayOfString res;
			try{
				--calloutTries;
				res = sendToFidelitone(setting, orders);
				if (res.string_x == null){
					--calloutTries;
					res = sendToFidelitone(setting, orders);
				}
			}catch(Exception ex){
				if(calloutTries > 0){
					res = sendToFidelitone(setting, orders);
				}	
			}
			
	        // if suceeded 
	        if (res.string_x != null  && !string.valueof(res.string_x).tolowercase().contains('failed')){
	        	System.debug('IN IF');
				insertLog('Succeeded', string.valueof(orders), string.valueof(res), '', sId, sentTo);
    			s.Sent_to_the_delivery_company__c = system.now();
    			update s;
    			if (!isOnHold && !s.Related_Sales_Order__r.Retail_value_sent_to_Fidelitone__c){
    				Sales_Order__c so = new Sales_Order__c(id = s.Related_Sales_Order__c);
    				if (!s.Related_Sales_Order__r.Do_Not_update_DC_with_Retail_Value__c){
	    				so.Retail_value_sent_to_Fidelitone__c = true;
    				}
    				if (s.Related_Sales_Order__r.Warranty_Order__c){
    					so.Warranty_Task_Create__c = true;
    				}
    				update so;
    			}
				//return true;
	        }
	        else if(res.string_x != null ){
				insertLog('Failed', string.valueof(orders), string.valueof(res), string.valueof(res.string_x ), sId, sentTo);
	        }else{
				insertLog('Failed', string.valueof(orders), string.valueof(res), '', sId, sentTo);
			}
		}
		catch (exception e){
			System.debug('Error: ' + e.getmessage());
			insertLog('Failed', string.valueof(orders), '', e.getmessage() + ' ' + e.getlinenumber(), sId, sentTo);
		}
	}

	private static FidelitoneComOrders.ArrayOfString sendToFidelitone(Fideliton_Setting__c setting, FidelitoneComOrders.ArrayOfOrder orders){
		FidelitoneComOrders.OrdersService os = new FidelitoneComOrders.OrdersService();
		os.User_x = new FidelitoneComOrders.User_x();
		os.endpoint_x = setting.endpoint__c;
		os.timeout_x = 120000;
		os.User_x.UserName = setting.UserName__c;//'renegade';
		os.User_x.Password = setting.Password__c;//'testingsoap';
		system.debug('os my = ' + os);
		system.debug('orders = ' + orders);

		FidelitoneComOrders.ArrayOfString res;
		if(!Test.isRunningTest()) {
			res =  os.PlaceOrder(orders);
			system.debug('res = ' + res);
			system.debug('res.string_x = ' + res.string_x);	
		}else{
			res =  new FidelitoneComOrders.ArrayOfString();
			res.string_x = new String[]{'http://fidelitone.com/Orders/'};
		}
		return res;
	}
	private static String formatPhone(String phone){
		String clearPhone = phone.replaceAll('[\\D]', '');
		return clearPhone.length() <= 10 ? clearPhone : clearPhone.substring(clearPhone.length()-10);
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
}