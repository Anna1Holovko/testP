public class POlineTrackingComponentController {
    
    public Id poId { 
        get{ return poId; } 
        set{
            poLineItemTOTracckingNumberMap = new Map<Id, Set<Tracking>>();
            poId = value;
            poLineItemsList = new List<PO_Line_Items__c>();
            Purchase_Order__c currentPO = [SELECT Id, Last_shipment_notification_sent_at__c FROM Purchase_Order__c WHERE Id = :poId  ];
            /*datetime d;
            if (currentPO.Last_shipment_notification_sent_at__c != null){
            	d = currentPO.Last_shipment_notification_sent_at__c.addseconds(-5);
            }*/
            for(Shipment_Line_Item__c  shipmentLI_i : [ SELECT  Tracking_Number__c,
                                                                PO_Line_Item__r.Id, 
                                                                PO_Line_Item__r.Product_Image_URL__c,
                                                                PO_Line_Item__r.Product_SKU__c,
                                                                PO_Line_Item__r.Quantity__c,
                                                                PO_Line_Item__r.Product__c,
                                                                Shipment__r.Tracking_Number__c, 
                                                                Shipment__r.Link_to_Carrier_for_template__c,
                                                                Shipment__r.Carrier_Name__c,
                                                                Shipment__r.Carrier_Information__c  
                                                        FROM Shipment_Line_Item__c 
                                                        WHERE   PO_Line_Item__r.Purchase_Order__c = :currentPO.Id AND 
                                                                Shipment__r.Shipment_notification_sent_to_customer__c = null AND Shipment__r.Tracking_Number__c != null and
                                                                //(PO_Line_Item__r.Purchase_Order__r.Last_shipment_notification_sent_at__c = null OR Shipment__r.Shipment_notification_sent_to_customer__c >= :currentPO.Last_shipment_notification_sent_at__c) AND
                                                                PO_Line_Item__r.SO_Line_Item__r.Item__c != 'Cancelled']){
                if(!poLineItemsList.contains(shipmentLI_i.PO_Line_Item__r)){
                    poLineItemsList.add(shipmentLI_i.PO_Line_Item__r);
                }
                
                if(! poLineItemTOTracckingNumberMap.containsKey(shipmentLI_i.PO_Line_Item__r.Id)){
                    poLineItemTOTracckingNumberMap.put(shipmentLI_i.PO_Line_Item__r.Id, new Set<Tracking>() );
                }
                if( shipmentLI_i.Shipment__r.Tracking_Number__c != null){
                    Tracking info = new Tracking();
                    info.carrierName = shipmentLI_i.Shipment__r.Carrier_Name__c;
                    if(String.isNotBlank(info.carrierName) && info.carrierName.tolowerCase() == 'other'){
                        info.info = shipmentLI_i.Shipment__r.Carrier_Information__c;
                    }
                    info.label = shipmentLI_i.Shipment__r.Tracking_Number__c;
                    if( shipmentLI_i.Shipment__r.Link_to_Carrier_for_template__c != null && 
                       shipmentLI_i.Shipment__r.Link_to_Carrier_for_template__c != '' && 
                       shipmentLI_i.Shipment__r.Link_to_Carrier_for_template__c.toLowerCase() != 'unknown' &&
                       shipmentLI_i.Shipment__r.Link_to_Carrier_for_template__c.toLowerCase() != 'empty'){
                           info.link = shipmentLI_i.Shipment__r.Link_to_Carrier_for_template__c;
                       }
                    
                    poLineItemTOTracckingNumberMap.get(shipmentLI_i.PO_Line_Item__r.Id).add(info);    
                }else{
                    poLineItemTOTracckingNumberMap.get(shipmentLI_i.PO_Line_Item__r.Id).add(new Tracking());
                }
            }
        } 
    }

    
    
    public List<PO_Line_Items__c> poLineItemsList { get; set; }
    
    public Map<Id, Set<Tracking>> poLineItemTOTracckingNumberMap { get; set; }
    
    
    public POlineTrackingComponentController(){
        
    }

    public class Tracking{
        public String link { get; set; } 
        public String label { get; set; }
        public String info { get; set; }
        public String carrierName { get; set; }
    }
    
}