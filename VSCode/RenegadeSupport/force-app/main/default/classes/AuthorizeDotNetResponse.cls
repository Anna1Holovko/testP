public class AuthorizeDotNetResponse{

    public String responseCode {get;set;}
    public String responseSubCode {get;set;}
    public String responseReasonCode {get;set;}
    public String responseReasonText {get;set;}
    public String authorizationCode {get;set;}
    public String avsResponse {get;set;}
    public String transactionId {get;set;}
    public String invoiceNumber {get;set;}
    public String description {get;set;}
    public String amount {get;set;}
    public String method {get;set;}
    public String transactionType {get;set;}
    public String cardCodeResponse {get;set;}
    public String accountNumber {get;set;}
    public String cardType {get;set;}
    public String splitTenderId {get;set;}
    public String response {get;set;}
    public String error {get;set;}
    
    public Static AuthorizeDotNetResponse generateResponse(String directResponse){
        AuthorizeDotNetResponse response = new AuthorizeDotNetResponse();
        List<String> results = new List<String>();
        if(directResponse != null){
            results = directResponse.split(',');
            system.debug('the results are ' + results + results.size());
            if(results.size()>0){
                response.responseCode = results[0];
                response.responseSubCode = results[1]; 
                response.responseReasonCode = results[2];
                response.responseReasonText = results[3]; 
                response.authorizationCode = results[4];
                response.avsResponse = results[5];
                response.transactionId = results[6];
                response.invoiceNumber = results[7]; 
                response.description = results[8]; 
                response.amount  = results[9];
                response.method  = results[10];
                response.transactionType = results[12];
                response.cardCodeResponse = results[38];
                response.accountNumber = results[50]; 
                response.cardType = results[51];
                //response.splitTenderId = results[52];                             
            }
        }
        return response;       
    }
}