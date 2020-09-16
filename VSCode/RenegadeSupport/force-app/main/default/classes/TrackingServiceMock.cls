@isTest
global class TrackingServiceMock implements HttpCalloutMock {
   	Map<String, ResponseDataWrapper> trackingNumberToBodyResponseMap;
    String trackingServiceName;
    
    public TrackingServiceMock(Map<String, responseDataWrapper> trackingNumberToBodyResponseMap, String trackingServiceName){
        this.trackingNumberToBodyResponseMap = trackingNumberToBodyResponseMap;
        this.trackingServiceName = trackingServiceName.toUpperCase();
    }
    
    global HTTPResponse respond(HTTPRequest request) {
        String trackingNumber = getTrackingNumber(request);
        HttpResponse response = new HttpResponse();
        ResponseDataWrapper responseData = trackingNumberToBodyResponseMap.get(trackingNumber);
        if(responseData != null){
            Map<String, String> headerMap = responseData.headerMap; 
            for(String headerName : headerMap.keySet()){
                response.setHeader(headerName, headerMap.get(headerName));
            }
            response.setBody(responseData.responseBody);
            response.setStatusCode(responseData.statusCode);
        }
        return response; 
    }
    
    String getTrackingNumber(HTTPRequest request){
        String endpoint = request.getEndpoint();
        String trackingNumber;
        switch on trackingServiceName{
            when 'UPS' {
                trackingNumber = endpoint.substring(endpoint.lastIndexOf('/') + 1);
            }
            when 'FEDEX' {
                trackingNumber = getFedExTrackingNumber(request.getBody());
            }
            when else {               
            }
        }
        
        return trackingNumber;
    }
    
    String getFedExTrackingNumber(String xmlInput){
        String trackingNumber;
        XmlStreamReader xmlReader = new XmlStreamReader(xmlInput);
        XmlParser parser = new XmlParser(xmlReader);
        boolean isSafeToGetNextXmlElement = true;
        
        while (isSafeToGetNextXmlElement) {
            if (parser.moveToXmlTag('SelectionDetails', -1) && parser.moveToXmlTag('PackageIdentifier', 2) && parser.moveToXmlTag('Value', 2)){
                    trackingNumber = parser.getXmlTagValue();
                    isSafeToGetNextXmlElement = false;
                	break;
            }
            if (xmlReader.hasNext() && isSafeToGetNextXmlElement) {
                xmlReader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return trackingNumber;
    }
    
    public class ResponseDataWrapper{
        public Map<String, String> headerMap;
        public String responseBody;
		public Integer statusCode;
        public String trackingServiceName;
        
        public ResponseDataWrapper(Map<String, String> headerMap, String responseBody, Integer statusCode, String trackingServiceName){
            this.headerMap = headerMap;
            this.responseBody = responseBody;
            this.statusCode = statusCode;
            this.trackingServiceName = trackingServiceName;
        }
    }
}