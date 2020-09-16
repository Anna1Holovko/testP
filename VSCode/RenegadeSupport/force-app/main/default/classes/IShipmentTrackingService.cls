public abstract class IShipmentTrackingService {
    //public String trackingServiceName;
    public String trackingNumber;

    abstract String obtainBody();
    
    abstract Map<String, String> obtainHeaders();
    
    abstract String obtainMethod();
    
    abstract String obtainEndpoint();

    abstract ResponseWrapperTrackingService parseResponse(String input);

    public ResponseWrapperTrackingService track() {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(obtainEndpoint());
        request.setMethod(obtainMethod());
        Map<String, String> headers = obtainHeaders();
        for (String header_i : headers.keySet()) {
            request.setHeader(header_i, headers.get(header_i));
        }
        String requestBody = obtainBody();
        if (String.isNotBlank(requestBody)) {
            request.setBody(requestBody);
        }
        HttpResponse response = http.send(request);   
        return parseResponse(response.getBody());
    }

    public void setTrackingNumber(String trackingNumber){
        this.trackingNumber = trackingNumber;
    }

    public Date parseStringToDate(String dateString){
        return String.isBlank(dateString) || !dateString.isNumeric() ? null : date.newinstance( Integer.valueOf(dateString.subString(0,4)), Integer.valueOf(dateString.subString(4,6)), Integer.valueOf(dateString.subString(6)) );
    }

    public class ResponseWrapperTrackingService {
        public Date scheduleDate;
        public Date actualDeliveryDate;
        public String stringDate;
        public String deliveryStatus;
        public String errorMessage;
    }
}