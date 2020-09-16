public with sharing class ShipmentTackingManager { 
    public static IShipmentTrackingService.ResponseWrapperTrackingService track(String shipmentId, String trackingType){
        IShipmentTrackingService.ResponseWrapperTrackingService result = new IShipmentTrackingService.ResponseWrapperTrackingService();
        try{
            Type trackingServiceType = Type.forName(trackingType);
            IShipmentTrackingService trackingService = (IShipmentTrackingService)trackingServiceType.newInstance();
            trackingService.setTrackingNumber(shipmentId);
            result = trackingService.track();
        }catch(Exception ex){
            String errorMessage = 'Error: ' + ex.getMessage() +' | ' + ex.getStackTraceString();
            System.debug(errorMessage);
        }
        return result;
    }

    public static Date parseStringToDate(String dateString){
        return date.newinstance( Integer.valueOf(dateString.subString(0,4)), Integer.valueOf(dateString.subString(4,6)), Integer.valueOf(dateString.subString(6)) );
    }
}