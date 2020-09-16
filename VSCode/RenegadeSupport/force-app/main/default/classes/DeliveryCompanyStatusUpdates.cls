@RestResource(urlMapping='/status_update/*')
global with sharing class DeliveryCompanyStatusUpdates {

    static final String ORDER_STATUS_UPDATED_PROCESS = 'Order Status Updated';
    static final String FAILED = 'Failed';
    static final String SUCCEEDED = 'Succeeded';
    

    @HttpPost  
    global static void createNewLog() {
        try{    
            order ord = (order) JSON.deserialize(RestContext.request.requestBody.toString(), order.class);
            if (String.isNotBlank(ord.Comments)) {
                DeliverightChatterManager.postAtChatter(ord.order_id, ord.Comments, ord.sender);
            }
            set<string> lineItemStatuses = new set<string>();
            map<string, Order_status_map__mdt> orderStatusMapByStatus = new map<string, Order_status_map__mdt>();
            map<string, orderLineItem> lineItemById = new map<string, orderLineItem>();
            System.debug('ord = '  + ord);
            if(ord.order_line_shipment_item != null){
                for (orderLineItem item_i : ord.order_line_shipment_item){
                    lineItemStatuses.add(item_i.shipment_item_status);
                    lineItemById.put(item_i.shipment_item_id, item_i);
                }
            }
            System.debug('lineItemById = '  + lineItemById);
            list<Shipment_Line_Item__c> shipmentsli = [SELECT id, Shipment_Item_Status__c, PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c FROM Shipment_Line_Item__c WHERE id IN :lineItemById.keyset()];
            try{
                System.debug(lineItemStatuses);
                System.debug('shipmentsli = '  + shipmentsli);
                list<Order_status_map__mdt> m = [SELECT Salesforce_status_name__c, Salesforce_shipment_line_status_name__c, Delivery_company_status_name__c FROM Order_status_map__mdt WHERE Delivery_company_status_name__c IN :lineItemStatuses];
                for (Order_status_map__mdt ma : m){
                    orderStatusMapByStatus.put(ma.Delivery_company_status_name__c, ma);
                }
            }
            catch (exception ex){
                //status_update.deleteImage();
                updateLog(ord.order_id, RestContext.request.requestBody.toString(), 'could not support status', FAILED );
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.statusCode = 400;
                RestContext.response.responseBody = Blob.valueOf(json.serialize(new Response('Failed', 'Could not find line item ' + ex.getmessage())));
                return;
            }
            if (shipmentsli.size() == 0){
                updateLog(ord.order_id, RestContext.request.requestBody.toString(), 'Could not find line item', FAILED );
                RestContext.response.addHeader('Content-Type', 'application/json');
                RestContext.response.responseBody = Blob.valueOf(json.serialize(new Response('Success', '')));
                return;
            }
            
            list<Attachment> attToInsert = new list<Attachment>();
            for (Shipment_Line_Item__c item_i : shipmentsli){
                if (lineItemById.containskey(item_i.id)){
                    try{
                        if (orderStatusMapByStatus.get(lineItemById.get(item_i.id).shipment_item_status).Salesforce_shipment_line_status_name__c != null && orderStatusMapByStatus.get(lineItemById.get(item_i.id).shipment_item_status).Salesforce_shipment_line_status_name__c != ''){
                            item_i.Shipment_Item_Status__c = orderStatusMapByStatus.get(lineItemById.get(item_i.id).shipment_item_status).Salesforce_shipment_line_status_name__c;
                            //insert link as attachment/file under the sales order
                        }
                        if (lineItemById.get(item_i.id).images != null && lineItemById.get(item_i.id).images.size() > 0){
                            for(image i : lineItemById.get(item_i.id).images){
                                try {
                                    Attachment myAttach = new Attachment();
                                    myAttach.ParentId = item_i.PO_Line_Item__r.SO_Line_Item__r.Sales_Order__c;
                                    myAttach.name = i.image_name+ '.jpg';
                                    myAttach.body = EncodingUtil.base64Decode(ImageRead(i.link));
                                    attToInsert.add(myAttach);
                                }
                                catch (exception eImage){
                                    updateLog(ord.order_id, RestContext.request.requestBody.toString(), 'could not insert image - ' + eImage.getmessage(), FAILED );
                                    return;
                                }
                            }
                        }
                    }
                    catch (exception ex){
                        updateLog(ord.order_id, RestContext.request.requestBody.toString(), 'could not support status', FAILED );
                        RestContext.response.addHeader('Content-Type', 'application/json');
                        RestContext.response.statusCode = 400;
                        RestContext.response.responseBody = Blob.valueOf(json.serialize(new Response('Failed', 'could not support status')));
                        return;
                    }
                    if (item_i.Shipment_Item_Status__c == 'Delivered No Issues'){
                        item_i.Delivery_Date_Actual__c = system.today();
                    }
                    if (item_i.Shipment_Item_Status__c == 'At Local Delivery Company'){
                        item_i.Drop_Off_Date_Actual__c = system.today();
                    }
                    if (item_i.Shipment_Item_Status__c == 'Scheduled Delivery'){
                        item_i.Scheduled_Delivery_Date__c = lineItemById.get(item_i.id).delivery_schedule_date != null ? lineItemById.get(item_i.id).delivery_schedule_date : lineItemById.get(item_i.id).scheduling_date;
                    }
                }
            }
            update shipmentsli;
            system.debug('attToInsert = ' + attToInsert);
            if (attToInsert.size() > 0){
                insert attToInsert;
            }
            updateLog(ord.order_id, RestContext.request.requestBody.toString(), '', SUCCEEDED );
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.responseBody = Blob.valueOf(json.serialize(new Response('Success', '')));
        }
        catch (exception e){
            updateLog('', RestContext.request.requestBody.toString(), e.getmessage() + ' ' + e.getlinenumber(), FAILED );
            RestContext.response.addHeader('Content-Type', 'application/json');
            RestContext.response.statusCode = 400;
            String responseStatus =  'Failed'; 
            if(e.getmessage().containsIgnoreCase('Cannot update status on items that are \'Hold as Stock\' or \'Retagged\'') ) {
                responseStatus = 'Success';
                RestContext.response.statusCode = 200;
            }
            RestContext.response.responseBody = Blob.valueOf(json.serialize(new Response(responseStatus, e.getmessage())));
        }
        
    }

    static void updateLog(String objectId, String data, String error, String status){
        Log__c log = new Log__c(Process__c = ORDER_STATUS_UPDATED_PROCESS,
                                Object_ID__c = objectId,
                                Data__c = data,
                                Status__c = status,
                                Error__c = error,
                                Tries__c = 1);
        if(String.isNotBlank(objectId)){
            List<Log__c> logList = [SELECT Id, Tries__c FROM Log__c WHERE Process__c = :ORDER_STATUS_UPDATED_PROCESS AND Object_ID__c = :objectId]; 
            if(logList.size() > 0){
                log.Id = logList.get(0).Id;
                if(logList.get(0).Tries__c != null ){
                    log.Tries__c = logList.get(0).Tries__c + 1;
                }
            }
        }                        
        
        upsert log; 
    }
    
    global class Response{
        public string status {get; set;}
        public string error {get; set;}
        public Response (string status, string error){
            this.status = status;
            this.error = error;
        }
    }
    
    global class order{
        public string sending_party {get; set;}
        public string receiving_party {get; set;}
        public string warehouse_id {get; set;}
        public string order_id {get; set;}
        public String comments { get; set; }
        public String sender { get; set; }
        public list<orderLineItem> order_line_shipment_item {get; set;}
        
        /*public void deleteImage(){
            if(order_line_shipment_item !=null){
                for (orderLineItem li : order_line_shipment_item){
                    if (li.images != null && li.images.size() > 0){
                        for (image i : li.images){
                            i.image = '1';
                        }
                    }
                } 
            }
            
        }*/
    }
    
    global class orderLineItem{
        public List<Image> images {get; set;}
        public String order_line_id {get; set;}
        public String shipment_item_id {get; set;}
        public String shipment_item_status {get; set;}
        public Date receive_date {get; set;}
        public Date scheduling_date {get; set;}
        public String delivery_schedule_comments {get; set;}
        public Date delivery_schedule_date {get; set;}
    }
    
    global class Image{
        public String image {get; set;}
        public String link {get; set;}
        public String image_name {get; set;}
    }
    
    public static String ImageRead(String link){
    
        String base64Data = '';
        String base64DataName = '';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(link);
        req.setMethod('GET');
        Http http = new Http();
        HttpResponse res = http.send(req);
        Blob image = res.getBodyAsBlob();
        system.debug('image****'+image);    
        base64Data =  EncodingUtil.base64Encode(image); 
        return base64Data; 
    }
}