public with sharing class TrackingServiceUPS extends IShipmentTrackingService {
    private final String METHOD = 'GET';
    private final List<String> RESPONSE_PARSE_DATE_PATH_LIST = new List<String>{ 'trackResponse', 'shipment', '0', 'package', '0', 'deliveryDate', '0', 'date' };
    private final List<String> RESPONSE_PARSE_ACUAL_DELIVERY_DATE_PATH_LIST = new List<String>{ 'trackResponse', 'shipment', '0', 'package', '0', 'activity', '0', 'date'};
    private final List<String> RESPONSE_ERROR_PATH_LIST = new List<String>{ 'response', 'errors', '0', 'message' };
    private final List<String> RESPONSE_WARNINGS_PATH_LIST = new List<String>{ 'trackResponse', 'shipment', '0', 'warnings', '0', 'message' };
    private final List<String> RESPONSE_PARSE_STATUS_PATH_LIST = new List<String>{ 'trackResponse', 'shipment', '0', 'package', '0', 'activity', '0', 'status', 'description' };
    
    Tracking_Service_UPS__c settings = Tracking_Service_UPS__c.getOrgDefaults();

    public String obtainEndpoint() {
        return settings.Endpoint__c + trackingNumber;
    }
    
    public Map<String, String> obtainHeaders() {
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'application/json');
        headers.put('AccessLicenseNumber', settings.AccessLicenseNumber__c);
        return headers;
    }
    
    public String obtainMethod() {
        return METHOD;
    }
    
    public String obtainBody() {
        return '';
    }

    public ResponseWrapperTrackingService parseResponse(String input){
        
        ResponseWrapperTrackingService responseWrapper = new ResponseWrapperTrackingService();

        if(input.contains('errors')){
            responseWrapper.errorMessage = String.valueOf(responseRetriever(input, RESPONSE_ERROR_PATH_LIST));
        }else if(input.contains('warnings')){
            responseWrapper.errorMessage = String.valueOf(responseRetriever(input, RESPONSE_WARNINGS_PATH_LIST));
        }else{
            responseWrapper.deliveryStatus =  String.valueOf(responseRetriever(input, RESPONSE_PARSE_STATUS_PATH_LIST));
            responseWrapper.stringDate = String.valueOf(responseRetriever(input, RESPONSE_PARSE_DATE_PATH_LIST));
            responseWrapper.scheduleDate = parseStringToDate(responseWrapper.stringDate);
            responseWrapper.actualDeliveryDate =  parseStringToDate(String.valueOf( responseRetriever(input, RESPONSE_PARSE_ACUAL_DELIVERY_DATE_PATH_LIST) ));
        }

        return responseWrapper;//String.valueOf(responseResult);
    }   

    Object responseRetriever(String input, List<String> responsePathParserList){
        Object responseResult = JSON.deserializeUntyped(input);
        try{
            for(String currentPath_i : responsePathParserList){
                responseResult = /* Pattern.matches('^[a-zA-Z]+$', currentPath_i) */!currentPath_i.isNumeric() ? ((Map<String, Object>) responseResult).get(currentPath_i) : ((List<Object>) responseResult).get(Integer.valueOf(currentPath_i));
            }
        } catch(Exception ex) {
            responseResult = ex.getMessage() + ' in line: ' + ex.getLineNumber();
        }
        return responseResult;
    }
}