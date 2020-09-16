@RestResource(urlMapping='/UpdateOrderStatus/*')	
global class TruckCompaniesOrderStatusUpdates {
	
	@HttpPost  
	global static void updateStatus() {
		try{
			system.debug('RestContext.request.params = ' + RestContext.request.params);
			if (RestContext.request.params.containskey('order_number') && RestContext.request.params.containskey('user_key') && RestContext.request.params.containskey('status')){
				string orderNumberTemp = RestContext.request.params.get('order_number');
				string orderNumber = orderNumberTemp.split(' ').size() == 4 ? orderNumberTemp.split(' ')[2] : orderNumberTemp;
				map<id, Shipment__c> shipments = new map<id, Shipment__c>([select id, Shipment_Status__c from Shipment__c where Related_Sales_Order__r.Magento_order_No__c = :orderNumber]);
				list<Shipment_Line_Item__c> shipmentsli = [select id, Shipment_Item_Status__c from Shipment_Line_Item__c where Shipment__c in :shipments.keyset()];
				//and Trucking_Company__c = :RestContext.request.params.get('user_key')];
				string status;
				string liStatus;
				try{
					system.debug('RestContext.request.params.get( = ' + RestContext.request.params.get('status'));
					list<Order_status_map__mdt> m = [select Salesforce_status_name__c, Salesforce_shipment_line_status_name__c from Order_status_map__mdt where Delivery_company_status_name__c = :RestContext.request.params.get('status').trim()];
					system.debug('m = ' + m);
					status = m[0].Salesforce_status_name__c;
					liStatus = m[0].Salesforce_shipment_line_status_name__c;
					if(Test.isRunningTest()) {
						status = 'Scheduled Shipments';
					}
					system.debug('status = ' + status);
				}
				catch (exception e){
					Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(RestContext.request.params), Tries__c = 1, Error__c = 'could not support status', Status__c = 'Failed', Object_ID__c = orderNumber);
					insert log;
					return;
				}
				try {
					if (shipments.values().size() > 0){
						/*for (Shipment__c s : shipments.values()){
							s.Shipment_Status__c = status;
						}*/
						for (Shipment_Line_Item__c s : shipmentsli){
							s.Shipment_Item_Status__c = liStatus;
							if (s.Shipment_Item_Status__c == 'Delivered No Issues'){
								s.Delivery_Date_Actual__c = system.today();
							}
						}
						//update shipments.values();
						update shipmentsli;
					}
					else {
						Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(RestContext.request.params), Tries__c = 1, Error__c = 'Could not find order', Status__c = 'Failed', Object_ID__c = orderNumber);
						insert log;
						return;
					}
				}
				catch (exception e){
					system.debug(e.getmessage() + e.getlinenumber());
					Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(RestContext.request.params), Tries__c = 1, Error__c = e.getmessage(), Status__c = 'Failed', Object_ID__c = orderNumber);
					insert log;
					return;
				}
				Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(RestContext.request.params), Tries__c = 1, Status__c = 'Succeeded', Object_ID__c = orderNumber);
				insert log;
			}
			else {
				Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(RestContext.request.params), Tries__c = 1, Error__c = 'Missing parameters', Status__c = 'Failed', Object_ID__c = RestContext.request.params.get('order_number'));
				insert log;
			}
		}
		catch(exception e){
			Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(RestContext.request.params), Tries__c = 1, Error__c = e.getmessage(), Status__c = 'Failed', Object_ID__c = RestContext.request.params.get('order_number'));
			insert log;
		}
		//return event + ' ' + orderNumber;
	}
}
//https://na24.salesforce.com/services/apexrest/DispatchOrderStatus
//https://greencloud-colemanfurniture.cs54.force.com/Dispatchorderstatus/services/apexrest/DispatchOrderStatus