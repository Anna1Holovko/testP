@RestResource(urlMapping='/fidUpdateOrderStatus/*') 
global class FidelitonOrderStatusUpdates {

    @HttpPost  
    global static string updateStatus(order status_update) {
        
        try{
            set<string> lineItemStatuses = new set<string>();
            map<string, Order_status_map__mdt> orderStatusMapByStatus = new map<string, Order_status_map__mdt>();
            map<string, orderLineItem> lineItemById = new map<string, orderLineItem>();
            for (orderLineItem li : status_update.line_items){
                lineItemStatuses.add(li.status);
                lineItemById.put(li.id, li);
            }
            system.debug('status_update = ' + status_update);
            if (status_update.order_number != null && status_update.user_key != null){
                map<id, Shipment__c> shipments = new map<id, Shipment__c>([select id, Shipment_Status__c from Shipment__c where Related_Sales_Order__r.Magento_order_No__c = :status_update.order_number]);
                list<Shipment_Line_Item__c> shipmentsli = [select id, Shipment_Item_Status__c, PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c from Shipment_Line_Item__c where Shipment__c in :shipments.keyset()];
                try{
                    System.debug(lineItemStatuses);
                    list<Order_status_map__mdt> m = [select Salesforce_status_name__c, Salesforce_shipment_line_status_name__c, Delivery_company_status_name__c from Order_status_map__mdt where Delivery_company_status_name__c in :lineItemStatuses];
                    for (Order_status_map__mdt ma : m){
                        orderStatusMapByStatus.put(ma.Delivery_company_status_name__c, ma);
                    }
                }
                catch (exception e){
                    status_update.deleteImage();
                    Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = 'could not support status', Status__c = 'Failed', Object_ID__c = status_update.order_number);
                    insert log;
                    return e.getmessage();
                }
                try {
                    if (shipments.values().size() > 0){
                        list<Attachment> attToInsert = new list<Attachment>();
                        for (Shipment_Line_Item__c s : shipmentsli){
                            if (lineItemById.containskey(s.id)){
                                if (lineItemById.get(s.id).status == 'POD Image Created' && lineItemById.get(s.id).images != null && lineItemById.get(s.id).images.size() > 0){
                                    for(image i : lineItemById.get(s.id).images){
                                        try {
                                            Attachment myAttach = new Attachment();
                                            myAttach.ParentId = s.PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c;
                                            myAttach.name = i.image_name+ '.jpg';
                                            myAttach.body = EncodingUtil.base64Decode(i.image);
                                            attToInsert.add(myAttach);
                                        }
                                        catch (exception eImage){
                                            
                                        }
                                    }
                                }
                                else{
                                    try{
                                        if (orderStatusMapByStatus.get(lineItemById.get(s.id).status).Salesforce_shipment_line_status_name__c != null && orderStatusMapByStatus.get(lineItemById.get(s.id).status).Salesforce_shipment_line_status_name__c != ''){
                                            s.Shipment_Item_Status__c = orderStatusMapByStatus.get(lineItemById.get(s.id).status).Salesforce_shipment_line_status_name__c;
                                        }
                                    }
                                    catch (exception e){
                                        status_update.deleteImage();
                                        Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = 'could not support status', Status__c = 'Failed', Object_ID__c = status_update.order_number);
                                        insert log;
                                        return 'could not support status';
                                    }
                                    if (s.Shipment_Item_Status__c == 'Delivered No Issues'){
                                        s.Delivery_Date_Actual__c = system.today();
                                    }
                                }
                            }
                        }
                        update shipmentsli;
                        if (attToInsert.size() > 0){
                            insert attToInsert;
                        }
                    }
                    else {
                        status_update.deleteImage();
                        Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = 'Could not find order', Status__c = 'Failed', Object_ID__c = status_update.order_number);
                        insert log;
                        return 'Could not find order';
                    }
                    if (shipmentsli.size() == 0){
                        status_update.deleteImage();
                        Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = 'Could not find line item', Status__c = 'Failed', Object_ID__c = status_update.order_number);
                        insert log;
                        return 'Could not find line item';
                    }
                }
                catch (exception e){
                    system.debug(e.getmessage() + e.getlinenumber());
                    status_update.deleteImage();
                    Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = e.getmessage() + e.getlinenumber(), Status__c = 'Failed', Object_ID__c = status_update.order_number);
                    insert log;
                    return e.getmessage() + e.getlinenumber();
                }
                status_update.deleteImage();
                Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Status__c = 'Succeeded', Object_ID__c = status_update.order_number);
                insert log;
            }
            else {
                status_update.deleteImage();
                Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = 'Missing parameters', Status__c = 'Failed', Object_ID__c = status_update.order_number);
                insert log;
            }
        }
        catch(exception e){
            status_update.deleteImage();
            Log__c log = new Log__c(Process__c = 'Order Status Updated', Data__c = string.valueof(Json.serialize(status_update)), Tries__c = 1, Error__c = e.getmessage() + e.getlinenumber(), Status__c = 'Failed', Object_ID__c = status_update.order_number);
            insert log;
            return e.getmessage() + e.getlinenumber();
        }
        return 's';
    }
    
    global class order{
        public string order_number {get; set;}
        public string user_key {get; set;}
        public list<orderLineItem> line_items {get; set;}
        
        public void deleteImage(){
            if(line_items !=null){
                for (orderLineItem li : line_items){
                    if (li.images != null && li.images.size() > 0){
                        for (image i : li.images){
                            i.image = '1';
                        }
                    }
                } 
            }
            
        }
    }
    
    global class orderLineItem{
        public list<image> images {get; set;}
        public string id {get; set;}
        public string status {get; set;}
        public string scheduled_delivery_date {get; set;}
    }
    
    global class image{
        public string image {get; set;}
        public string image_name {get; set;}
        public string image_link{get;set;}
    }
}