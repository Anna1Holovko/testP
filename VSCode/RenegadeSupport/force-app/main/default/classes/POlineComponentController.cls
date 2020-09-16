public class POlineComponentController {
    
    public Id poId { 
        get{ return poId; } 
        set{
            poId = value;
            poLineItemsList = [SELECT   Id, 
                               Product_Image_URL__c,
                               Product_SKU__c,
                               Quantity__c,
                               Product__c
                               FROM PO_Line_Items__c  WHERE Purchase_Order__c  =:poId and SO_Line_Item__r.Item__c != 'Cancelled'];
            poLineItemTOTracckingNumberMap = new Map<Id, Set<Tracking>>();
            for(PO_Line_Items__c poLI_i : poLineItemsList ){
                poLineItemTOTracckingNumberMap.put(poLI_i.Id, new Set<Tracking>());
            }
            
            for(Shipment_Line_Item__c  shipmentLI_i : [ SELECT  Tracking_Number__c,
                                                                PO_Line_Item__r.Id, 
                                                                Shipment__r.Tracking_Number__c, 
                                                                Shipment__r.Link_to_Carrier_for_template__c,
                                                                Shipment__r.Carrier_Name__c,
                                                                Shipment__r.Carrier_Information__c  
                                                        FROM Shipment_Line_Item__c 
                                                        WHERE   PO_Line_Item__c  IN: poLineItemsList AND 
                                                                PO_Line_Item__r.SO_Line_Item__r.Item__c != 'Cancelled']){
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
    
    
    public POlineComponentController(){
        
    }

    public class Tracking{
        public String link { get; set; } 
        public String label { get; set; }
        public String info { get; set; }
        public String carrierName { get; set; }
    }
    
}