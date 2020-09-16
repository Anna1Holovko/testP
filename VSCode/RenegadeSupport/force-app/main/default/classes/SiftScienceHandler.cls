public with sharing class SiftScienceHandler {
    
    public static SiftScienceHandler.Response getScore(String userId){
        Sift_Science_setting__c setting = Sift_Science_setting__c.getInstance();
        try{
            HttpRequest httpReq = new HttpRequest();
            httpReq.setHeader('Content-Type', 'application/json');
            String endPoint = setting.URL__c + '/' + userId + '/?api_key=' + setting.API_KEY__c;
            httpReq.setEndpoint(endPoint);
            httpReq.setMethod('GET');
            system.debug('endPoint = ' + endPoint);
            Http h = new Http();
            HttpResponse res = h.send(httpReq);
            String result = res.getBody().replace('"time"', '"time_x"');
            System.debug('result = ' + result);
            SiftScienceHandler.Response response = (SiftScienceHandler.Response ) JSON.deserialize(result, SiftScienceHandler.Response.class);
            return response;
        }catch (Exception e){
            system.debug('e.getmessage() = ' + e.getmessage());
			SiftScienceHandler.Response response = new SiftScienceHandler.Response();
			response.error_message = e.getmessage() + ' - ' + e.getlinenumber();
            response.error_message = userId;
            response.status = 1;
			return response;
        }
    }
    
    public class Response{
        public Integer status { get; set; }
        public String error_message  { get; set; }
        public Map<String, Scores> scores { get; set; }
        public String user_id { get; set; }
        public Boolean is_bad { get; set; }
        public Long time_x { get; set; }
        public String description  { get; set; }
    }
    
    public class Scores{
        public Decimal score { get; set; }
        public List<Reason> reasons { get; set; } 
    }
    
    public class Reason{
        public String name { get; set; }
        public String value { get; set; }
    }
    
    
    
	/*public static Response getScore(Sales_Order__c so){
	    Sift_Science_setting__c setting = Sift_Science_setting__c.getInstance();
		try{
			HttpRequest httpReq = new HttpRequest();
	        httpReq.setHeader('Content-Type', 'application/json');
	        string endPoint = setting.URL__c;
	        httpReq.setEndpoint(endPoint);
	        string body = generateRequest(so, setting);
			body = body.replace('{"', '{"$');
			body = body.replace(',"', ',"$');
	        httpReq.setBody(body);
	        httpReq.setMethod('POST');
			system.debug('endPoint = ' + endPoint);
			system.debug('body = ' + body);
	        Http h = new Http();
            HttpResponse res = Test.isRunningTest() ? null : h.send(httpReq);
			string result = res.getBody().replace('time', 'timetime');
			system.debug('result = ' + result);
			result = result.replace('$', '');
			system.debug('result = ' + result);
    		SiftScienceHandler.Response response = ((list<SiftScienceHandler.Response>)JSON.deserialize('[' + result + ']', list<SiftScienceHandler.Response>.class))[0];
			return response;
		}
		catch (exception e){
			system.debug('e.getmessage() = ' + e.getmessage());
			SiftScienceHandler.Response response = new SiftScienceHandler.Response();
			response.error_message = e.getmessage() + ' - ' + e.getlinenumber();
			return response;
		}
	}
	
	public static string generateRequest(Sales_Order__c so, Sift_Science_setting__c setting){
		Request req = new Request();
		
		req.type = '$create_order';
		req.api_key = setting.API_KEY__c;
		req.user_id = so.Email__c;
		req.order_id = so.id;
		req.user_email = so.Email__c;
		req.amount = integer.valueof(so.Grand_Total__c);
		req.currency_code = 'USD';
		req.billing_address = new Address(so.Bill_To__c, so.Billing_Phone__c, so.Billing_Street__c, so.Billing_City__c, so.Billing_State__c, so.Billing_Country__c, so.Billing_ZipCode__c);
		if (so.Payment_Type__r.RecordTypeId == Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card').getRecordTypeId() || so.Payment_Type__r.RecordTypeId == Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card (Authorize.net)').getRecordTypeId()){
			req.payment_methods = new list<Payment_method>();
			req.payment_methods.add(new Payment_method('$credit_card', '', 0, integer.valueof(so.Payment_Type__r.Last_4_digits_of_CC__c)));
		}
		req.shipping_address = new Address(so.Ship_to__c, so.Shipping_Phone__c, so.Shipping_Street__c, so.Shipping_City__c, so.Shipping_State__c, so.Shipping_Country__c, so.Shipping_ZipCode__c);
		
		return json.serialize(req);
	}
	
	public class Request {
		public string type {get; set;}
		public string api_key {get; set;}
		public string user_id {get; set;}
		
		//public string session_id {get; set;}
		public string order_id {get; set;}
		public string user_email {get; set;}
		public integer amount {get; set;}
		public string currency_code {get; set;}
		public Address billing_address {get; set;}
		public list<Payment_method> payment_methods {get; set;}
		public Address shipping_address {get; set;}
		/*public boolean expedited_shipping {get; set;}
		public string shipping_method {get; set;}
		public list<Item> items {get; set;}*/
		/*
	}
	
	public class Address {
		public string name {get; set;}
		public string phone {get; set;}
		public string address_1 {get; set;}
		//public string address_2 {get; set;}
		public string city {get; set;}
		public string region {get; set;}
		public string country {get; set;}
		public string zipcode {get; set;}
		
		public Address(string name, string phone, string address_1, string city, string region, string country, string zipcode){
			this.name = name;
			this.phone = phone;
			this.address_1 = address_1;
			this.city = city;
			this.region = region;
			this.country = country;
			this.zipcode = zipcode;
		}
	}
		
	public class Payment_method {
		public string payment_type {get; set;}
		public string payment_gateway {get; set;}
		public integer card_bin {get; set;}
		public integer card_last4 {get; set;}
		
		public Payment_method (string payment_type, string payment_gateway, integer card_bin, integer card_last4){
			
		}
	}	
		
	/*public class Item {
		public string item_id {get; set;}
		public string product_title {get; set;}
		public integer price {get; set;}
		public string upc {get; set;}
		public string sku {get; set;}
		public string brand {get; set;}
		public string manufacturer {get; set;}
		public string category {get; set;}
		public list<string> tags {get; set;}
		public integer quantity {get; set;}
	}*/
	/*
	public class Response {
		public integer status {get; set;}
		public string error_message {get; set;}
		public integer timetime {get; set;}
		public string request {get; set;}
		public Score_response score_response {get; set;}
	}
	
	public class Score_response {
		public integer status {get; set;}
		public string error_message {get; set;}
		public Scores scores {get; set;}
		public string user_id {get; set;}
		public Request latest_labels {get; set;}
		public list<string> workflow_statuses {get; set;}
	}
	
	public class Scores {
		public Payment_abuse payment_abuse {get; set;}
	}
	
	public class Payment_abuse {
		public decimal score {get; set;}
		public list<Reason> reasons {get; set;}
	}
	
	public class Reason {
		public string name {get; set;}
		public string value {get; set;}
	}*/
}