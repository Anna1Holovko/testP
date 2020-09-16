public with sharing class WhitePagesHandler {
	
	public static Response identityCheck(Request req){
	    White_Pages_setting__c setting = White_Pages_setting__c.getInstance();
		try{
			HttpRequest httpReq = new HttpRequest();
	        //httpReq.setHeader('Content-Type', 'application/json');
	        string endPoint = setting.URL__c + 'api_key=' + setting.API_KEY__c;
	        endPoint += '&primary.name=' + req.primary_name;
	        endPoint += '&primary.phone=' + req.primary_phone;
	        endPoint += '&primary.address.street_line_1=' + req.primary_address_street_line_1;
	        endPoint += '&primary.address.city=' + req.primary_address_city;
	        endPoint += '&primary.address.state_code=' + req.primary_address_state_code;
	        endPoint += '&primary.address.postal_code=' + req.primary_address_postal_code;
	        endPoint += '&primary.address.country_code=' + req.primary_address_country_code;
	        system.debug('req.secondary_name = ' + req.secondary_name);
	        if (req.secondary_name != null && req.secondary_name != ''){
		        endPoint += '&secondary.name=' + req.secondary_name;
		        endPoint += '&secondary.phone=' + req.secondary_phone;
		        endPoint += '&secondary.address.street_line_1=' + req.secondary_address_street_line_1;
		        endPoint += '&secondary.address.city=' + req.secondary_address_city;
		        endPoint += '&secondary.address.state_code=' + req.secondary_address_state_code;
		        endPoint += '&secondary.address.postal_code=' + req.secondary_address_postal_code;
		        endPoint += '&secondary.address.country_code=' + req.secondary_address_country_code;
	        }
		    endPoint += '&email_address=' + req.email_address;
		    endPoint += '&ip_address=' + req.ip_address;
			system.debug('endPoint = ' + endPoint);
	        while (endPoint.indexOf(' ') > -1){
	        	endPoint = endPoint.replace(' ', '+');
	        }
	        httpReq.setEndpoint(endPoint);
	        httpReq.setMethod('POST');
			system.debug('endPoint = ' + endPoint);
	        Http h = new Http();
            HttpResponse res =  h.send(httpReq); //Test.isRunningTest() ? null : h.send(httpReq);
			string result = res.getBody().replace('.', '_');
			system.debug('result = ' + result);
    		WhitePagesHandler.Response response = ((list<WhitePagesHandler.Response>)JSON.deserialize('[' + result + ']', list<WhitePagesHandler.Response>.class))[0];
			return response;
		}
		catch (exception e){
			Error err = new Error();
			err.name = string.valueof(e.getlinenumber());
			err.message = e.getmessage();
			system.debug('e.getmessage() = ' + e.getmessage());
			WhitePagesHandler.Response response = new WhitePagesHandler.Response();
			response.error = err;
			return response;
		}
	}
	public static Request generateRequest(Sales_Order__c so){
		Request req = new Request();
		req.primary_name = so.Bill_To__c;
		req.primary_phone = so.Billing_Phone__c;
		req.primary_address_street_line_1 = so.Billing_Street__c;
		req.primary_address_city = so.Billing_City__c;
		req.primary_address_state_code = so.Billing_State__c;
		req.primary_address_postal_code = so.Billing_ZipCode__c;
		req.primary_address_country_code = so.Billing_Country__c;
		req.secondary_name = so.Ship_to__c;
		req.secondary_phone = so.Shipping_Phone__c;
		req.secondary_address_street_line_1 = so.Shipping_Street__c;
		req.secondary_address_city = so.Shipping_City__c;
		req.secondary_address_state_code = so.Shipping_State__c;
		req.secondary_address_postal_code = so.Shipping_ZipCode__c;
		req.secondary_address_country_code = so.Shipping_Country__c;
		req.email_address = so.Email__c;
		req.ip_address = so.Placed_From_IP__c;
		system.debug('req = ' + req);
		return req;
	}
	
	public class Request {
		public string primary_name{get; set;}
		public string primary_phone{get; set;}
		public string primary_address_street_line_1{get; set;}
		public string primary_address_city{get; set;}
		public string primary_address_state_code{get; set;}
		public string primary_address_postal_code{get; set;}
		public string primary_address_country_code{get; set;}
		public string secondary_name{get; set;}
		public string secondary_phone{get; set;}
		public string secondary_address_street_line_1{get; set;}
		public string secondary_address_city{get; set;}
		public string secondary_address_state_code{get; set;}
		public string secondary_address_postal_code{get; set;}
		public string secondary_address_country_code{get; set;}
		public string email_address{get; set;}
		public string ip_address{get; set;}
	}
	
	public class Response {
		public Error error{get; set;}
		public Request request{get; set;}
		public Phone_checks primary_phone_checks{get; set;}
		public Phone_checks secondary_phone_checks{get; set;}
		public Address_checks primary_address_checks{get; set;}
		public Address_checks secondary_address_checks{get; set;}
		public Email_address_checks email_address_checks{get; set;}
		public Ip_address_checks ip_address_checks{get; set;}
	}
	
	public class Ip_address_checks {
		public string error{get; set;}
		public list<string> warnings{get; set;}
		public boolean is_valid{get; set;}
		public boolean is_proxy{get; set;}
		public Geolocation geolocation{get; set;}
		public integer distance_from_address{get; set;}
		public integer distance_from_phone{get; set;}
		public boolean is_resident_deceased{get; set;}
		public boolean is_commercial{get; set;}
		public boolean is_forwarder{get; set;}
		public string connection_type{get; set;}
	}
	
	public class Geolocation {
		public string postal_code{get; set;}
		public string city_name{get; set;}
		public string subdivision{get; set;}
		public string country_name{get; set;}
		public string country_code{get; set;}
		public string continent_code{get; set;}
	}
	
	public class Address_checks {
		public string error{get; set;}
		public list<string> warnings{get; set;}
		public boolean is_valid{get; set;}
		public list<string> diagnostics{get; set;}
		public boolean is_active{get; set;}
		public string address_to_name{get; set;}
		public string resident_name{get; set;}
		public string resident_age_range{get; set;}
		public boolean is_resident_deceased{get; set;}
		public boolean is_commercial{get; set;}
		public boolean is_forwarder{get; set;}
		public string type{get; set;}
	}
	
	public class Phone_checks {
		public string error{get; set;}
		public list<string> warnings{get; set;}
		public boolean is_valid{get; set;}
		public string phone_to_name{get; set;}
		public string phone_to_address{get; set;}
		public string subscriber_name{get; set;}
		public string subscriber_age_range{get; set;}
		public string country_code{get; set;}
		public boolean is_commercial{get; set;}
		public string line_type{get; set;}
		public boolean is_prepaid{get; set;}
		public string carrier{get; set;}
	}
	
	public class Email_address_checks {
		public string error{get; set;}
		public list<string> warnings{get; set;}
		public boolean is_valid{get; set;}
		public list<string> diagnostics{get; set;}
		public boolean is_autogenerated{get; set;}
		public boolean is_disposable{get; set;}
		public string email_to_name{get; set;}
		public string registered_name{get; set;}
		public string registered_owner_age_range{get; set;}
		public date email_first_seen_date{get; set;}
		public integer email_first_seen_days{get; set;}
		public date email_domain_creation_date{get; set;}
		public integer email_domain_creation_days{get; set;}
	}
	
	public class Error {
		public string message{get; set;}
		public string name{get; set;}
	}
}