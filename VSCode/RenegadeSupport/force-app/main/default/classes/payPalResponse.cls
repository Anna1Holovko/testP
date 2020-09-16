public class payPalResponse{
	public String id;	//PAY-2GA36205SG5336543KZNAN2Q
	public String create_time;	//2015-11-28T19:56:26Z
	public String update_time;	//2015-11-28T19:56:27Z
	public String state;	//approved
	public String intent;	//authorize
	public cls_payer payer;
	public cls_transactions[] transactions;
	public cls_links[] links;
    public string authorizationID;
    public String response {get;set;}
    public String error {get;set;}
	
    class cls_payer {
		public String payment_method;	//credit_card
		public cls_funding_instruments[] funding_instruments;
	}
	class cls_funding_instruments {
		public cls_credit_card credit_card;
	}
	class cls_credit_card {
		public String type1;	//visa
		public String number1;	//xxxxxxxxxxxx4010
		public String expire_month;	//10
		public String expire_year;	//2019
		public String first_name;	//Betsy
		public String last_name;	//Buyer
		public cls_billing_address billing_address;
	}
	class cls_billing_address {
		public String line1;	//111 First Street
		public String city;	//Saratoga
		public String state;	//CA
		public String postal_code;	//95070
		public String country_code;	//US
	}
	class cls_transactions {
		public cls_amount amount;
		public String description;	//This is the payment transaction description.
		public cls_related_resources[] related_resources;
	}
	class cls_amount {
		public String total;	//7.47
		public String currency1;	//USD
		public cls_details details;
	}
	class cls_details {
		public String subtotal;	//7.41
		public String tax;	//0.03
		public String shipping;	//0.03
	}
	class cls_related_resources {
		public cls_authorization authorization;
	}
	public class cls_authorization {
		public String id;	//2TS79030UJ594043X
      	public String create_time;	//2015-11-28T19:56:26Z
		public String update_time;	//2015-11-28T19:56:28Z
		public cls_amount amount;
		public String state;	//authorized
		public String parent_payment;	//PAY-2GA36205SG5336543KZNAN2Q
		public String valid_until;	//2015-12-27T19:56:26Z
		public cls_links[] links;
		public cls_processor_response processor_response;
		public cls_fmf_details fmf_details;
        
        
	}
	class cls_links {
		public String href;	//https://api.sandbox.paypal.com/v1/payments/payment/PAY-2GA36205SG5336543KZNAN2Q
		public String rel;	//self
		public String method;	//GET
	}
	class cls_processor_response {
		public String avs_code;	//X
		public String cvv_code;	//M
	}
	class cls_fmf_details {
	}
	public static payPalResponse parse(String json){
		return (payPalResponse) System.JSON.deserialize(json, payPalResponse.class);
	}

	/*static testMethod void testParse() {
		String json=		'{"id":"PAY-2GA36205SG5336543KZNAN2Q","create_time":"2015-11-28T19:56:26Z","update_time":"2015-11-28T19:56:27Z","state":"approved","intent":"authorize","payer":{"payment_method":"credit_card","funding_instruments":[{"credit_card":{"type":"visa","number":"xxxxxxxxxxxx4010","expire_month":"10","expire_year":"2019","first_name":"Betsy","last_name":"Buyer","billing_address":{"line1":"111 First Street","city":"Saratoga","state":"CA","postal_code":"95070","country_code":"US"}}}]},"transactions":[{"amount":{"total":"7.47","currency":"USD","details":{"subtotal":"7.41","tax":"0.03","shipping":"0.03"}},"description":"This is the payment transaction description.","related_resources":[{"authorization":{"id":"2TS79030UJ594043X","create_time":"2015-11-28T19:56:26Z","update_time":"2015-11-28T19:56:28Z","amount":{"total":"7.47","currency":"USD","details":{"subtotal":"7.41","tax":"0.03","shipping":"0.03"}},"state":"authorized","parent_payment":"PAY-2GA36205SG5336543KZNAN2Q","valid_until":"2015-12-27T19:56:26Z","links":[{"href":"https://api.sandbox.paypal.com/v1/payments/authorization/2TS79030UJ594043X","rel":"self","method":"GET"},{"href":"https://api.sandbox.paypal.com/v1/payments/authorization/2TS79030UJ594043X/capture","rel":"capture","method":"POST"},{"href":"https://api.sandbox.paypal.com/v1/payments/authorization/2TS79030UJ594043X/void","rel":"void","method":"POST"},{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-2GA36205SG5336543KZNAN2Q","rel":"parent_payment","method":"GET"}],"processor_response":{"avs_code":"X","cvv_code":"M"},"fmf_details":{}}}]}],"links":[{"href":"https://api.sandbox.paypal.com/v1/payments/payment/PAY-2GA36205SG5336543KZNAN2Q","rel":"self","method":"GET"}]}';
		payPalResponse obj = parse(json);
		System.assert(obj != null);
	}*/
}