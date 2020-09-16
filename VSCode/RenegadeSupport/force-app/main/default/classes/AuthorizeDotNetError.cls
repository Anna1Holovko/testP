public class AuthorizeDotNetError 
{
	public cls_createCustomerProfileResponse createCustomerProfileResponse;
	class cls_createCustomerProfileResponse {
		public String xmlnsxsi;	//http://www.w3.org/2001/XMLSchema-instance
		public String xmlnsxsd;	//http://www.w3.org/2001/XMLSchema
		public String xmlns;	//AnetApi/xml/v1/schema/AnetApiSchema.xsd
		public cls_messages messages;
	}
	class cls_messages {
		public String resultCode;	//Error
		public cls_message[] message;
	}
	class cls_message {
		public String code;	//E00015
		public String text;	//The field length is invalid for Card Number.
	}
	public static AuthorizeDotNetError parse(String directResponse)
    {
        AuthorizeDotNetError response = new AuthorizeDotNetError();
        List<String> results = new List<String>();
        if(directResponse != null){
            results = directResponse.split(',');
            system.debug('the results are ' + results + results.size());
            if(results.size()>0)
            {
                                           
            }
        }
        return response;       
    }
}