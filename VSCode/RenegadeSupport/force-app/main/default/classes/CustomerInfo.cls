@RestResource(urlMapping='/CustomerInfo/*')
global with sharing class CustomerInfo {

	@HttpPost  
	global static CustomerInfoRes createNewLog(string customerId) {
		CustomerInfoRes res = new CustomerInfoRes();
		res.orders = new list<order>();
		list<Sales_Order__c> salesOrders = [SELECT Magento_Order_ID__c, Grand_Total__c, Customer_Order_Status__c, Magento_order_No__c, Order_Date__c,
						Ship_to__c, Shipping_Street__c, Shipping_City__c, Shipping_State__c, Discount_AmountTotal__c, Coupon_Code__c, TaxAmount__c, Shipping_Handle__c, Sub_Total__c,
						Shipping_Phone__c, Shipping_ZipCode__c, Shipping_Mobile__c, Billing_Street__c, Billing_City__c, Billing_State__c, Billing_Phone__c, Billing_ZipCode__c, createddate,
						Payment_Method__c, Payment_Type__r.Card_Type__c, Payment_Type__r.Last_4_digits_of_CC__c, Delivery_Company__r.Name, Delivery_Company__r.Phone
						FROM Sales_Order__c 
						WHERE Customer_Name__c = :customerId 
						ORDER BY createddate DESC];
		system.debug('salesOrders = ' + salesOrders);
		map<id, SO_Line_Items__c> lis = new map<id, SO_Line_Items__c>([SELECT ProductSKU__c, Cancelled_Status__c, ProductName__c, Price__c, Quantity__c, Sub_Total__c, 
										ProductImageUrl__c, Bundle_Item__c, Products__c,
									  Row_Total__c, Product_Name__c, Sales_Order__c, Customer_Item_Status__c, Sales_Order__r.Magento_order_No__c 
									  FROM SO_Line_Items__c WHERE Sales_Order__r.Customer_Name__c = :customerId]);
		system.debug('lis = ' + lis);
		list<PO_Line_Items__c> polis = [SELECT SO_Line_Item__c, Purchase_Order__c, Purchase_Order__r.Current_ETA_for_Customer__c, Purchase_Order__r.Carrier__c, 
										Purchase_Order__r.Suggested_Delivery_Comapny__r.Name	, Purchase_Order__r.Suggested_Delivery_Comapny__r.Phone,	
										(SELECT Shipment__r.Tracking_Number__c, Shipment_Item_Status__c,
											Shipment__r.Trucking_Company__c 
										FROM Shipment_Line_Items__r) 
										FROM PO_Line_Items__c WHERE SO_Line_Item__c in :lis.keyset()];
		system.debug('polis = ' + polis);
		set<string> poIds = new set<string>();
		for(PO_Line_Items__c po : polis){
			poIds.add(po.Purchase_Order__c);
		}
		map<id,Purchase_Order__c> posMap = new map<id,Purchase_Order__c>([SELECT Current_ETA_for_Customer__c, Carrier__c FROM Purchase_Order__c WHERE id IN :poIds]);
		
		map<string, order> ordersMap = new map<string, order>();
		for (Sales_Order__c so : salesOrders){
			order o = new order();
			o.salesOrder = so;
			res.orders.add(o);
			ordersMap.put(so.id, o);
		}
		system.debug('ordersMap = ' + ordersMap);
		map<string, orderLine> orderLinesMap = new map<string, orderLine>();
		for (SO_Line_Items__c li : lis.values()){
			if (!orderLinesMap.containskey(li.id)){
				orderLine ol = new orderLine();
				ol.salesOrdersLineItem = li;
				ol.purchaseOrderLineItems = new list<PO_Line_Items__c>();
				orderLinesMap.put(li.id, ol);
				if (ordersMap.get(li.Sales_Order__c).orderLines == null){
					ordersMap.get(li.Sales_Order__c).orderLines = new list<orderLine>();
				}
				ordersMap.get(li.Sales_Order__c).orderLines.add(ol);
				system.debug('ordersMap.get(li.Sales_Order__c) = ' + ordersMap.get(li.Sales_Order__c));
			}
		}
		system.debug('posMap = ' + posMap);
		for (PO_Line_Items__c po : polis) {
			orderLinesMap.get(po.SO_Line_Item__c).carrier = po.Purchase_Order__r.Carrier__c;
			orderLinesMap.get(po.SO_Line_Item__c).current_ETA_for_Customer = posMap.get(po.Purchase_Order__c).Current_ETA_for_Customer__c;
			for (Shipment_Line_Item__c sli : po.Shipment_Line_Items__r){
				
				if (orderLinesMap.get(po.SO_Line_Item__c).carrier != null && sli.Shipment__r.Tracking_Number__c != null) {
					orderLinesMap.get(po.SO_Line_Item__c).current_ETA_for_Customer = null;
				} else if (sli.Shipment_Item_Status__c == 'En Route To Local Delivery Company') {
					orderLinesMap.get(po.SO_Line_Item__c).current_ETA_for_Customer = '1-2 Weeks';
				} else if (sli.Shipment_Item_Status__c == 'At Local Delivery Company') {
					orderLinesMap.get(po.SO_Line_Item__c).current_ETA_for_Customer = '1 Week';
				} 

				system.debug('sli.Shipment__r.Tracking_Number__c = ' + sli.Shipment__r.Tracking_Number__c);
				if(sli.Shipment__r.Trucking_Company__c == null){
					orderLinesMap.get(po.SO_Line_Item__c).trackingNumber = sli.Shipment__r.Tracking_Number__c;
				}
				break;
			}
			system.debug('po = ' + po);
			orderLinesMap.get(po.SO_Line_Item__c).purchaseOrderLineItems.add(po);
			system.debug('orderLinesMap.get(po.SO_Line_Item__c) = ' + orderLinesMap.get(po.SO_Line_Item__c));
		}
		system.debug('ordersMap = ' + ordersMap);
		system.debug('res = ' + res);
		return res;
	}
	
	global class CustomerInfoRes{
		public list<order> orders{ get; set;}
	}
	global class order {
		public Sales_Order__c salesOrder{ get; set;}
		public list<orderLine> orderLines { get; set;}
	}
	global class orderLine {
		public SO_Line_Items__c salesOrdersLineItem { get; set;}
		public string carrier { get; set;}
		public string trackingNumber { get; set;}
		public string current_ETA_for_Customer { get; set;}
		public list<PO_Line_Items__c> purchaseOrderLineItems { get; set;}
	}
}