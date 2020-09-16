public without sharing class GuardianManager {
	
	private static Guardian_Setting__c gs;
	private static string token;
	
	public static string getToken(){
		gs = [SELECT id, Void_endpoint__c, Token__c, Key__c, Token_Expiration__c, Plan_code__c, Token_endpoint__c, Store_Number__c, Retailer_Number__c, Distributor_Number__c, Username__c, Password__c, End_point__c FROM Guardian_Setting__c];
		if (gs.Token_Expiration__c != null && gs.Token_Expiration__c > datetime.now()){
			return gs.Token__c;
		}
		else {
			
			HttpRequest httpReq = new HttpRequest();
	        httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
	        string body = 'username=' + gs.Username__c + '&password=' + gs.Password__c + '&grant_type=password';
	    	httpReq.setHeader('Content-Length', '0');
	        httpReq.setEndpoint(gs.Token_endpoint__c);
	        httpReq.setMethod('POST');
        	httpReq.setBody(body);
	        Http h = new Http();
            HttpResponse res = h.send(httpReq);
			system.debug('result = ' + res.getBody());
    		TokenResponse response = ((list<TokenResponse>)JSON.deserialize('[' + res.getBody() + ']', list<TokenResponse>.class))[0];
			
			
			//get token
			gs.Token__c = response.access_token;
			gs.Token_Expiration__c = datetime.now().addseconds(response.expires_in);
		}
		return gs.Token__c;
	}
	
	public static Response sendRequest(Sales_Order__c so, string body){
        system.debug('body = ' + body);
        Response response = fillFailedResponse();
        try{
            HttpRequest httpReq = new HttpRequest();
            httpReq.setHeader('Authorization', 'Bearer ' + token);
            httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            httpReq.setEndpoint(gs.End_point__c + gs.Key__c);
            httpReq.setHeader('Content-Length', string.valueof(body.length()));
            httpReq.setBody(body);
            //httpReq.setTimeout(12);
            system.debug('body = ' + body);
            httpReq.setMethod('POST');
            Http h = new Http();
            HttpResponse res = h.send(httpReq);
            system.debug('result = ' + res.getBody());
            response = ((list<Response>)JSON.deserialize('[' + res.getBody() + ']', list<Response>.class))[0];
            update gs;
        }catch(Exception e){
            response = fillFailedResponse();
        }
        return response;
	}
    
    private static Response fillFailedResponse(){
        Response response = new Response();
        response.results = new List<Results>();
        Results result = new Results();
        result.Info = 'FAILURE-REGISTRATION';
        response.results.add(result);
        
        return response;
    }
	
	public static Response VoidPlan(string voidLink){
		token = getToken();
		Guardian_Setting__c setting = Guardian_Setting__c.getinstance();
		HttpRequest httpReq = new HttpRequest();
        httpReq.setHeader('Authorization', 'Bearer ' + token);
        httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        httpReq.setEndpoint(gs.Void_endpoint__c + voidLink);
        httpReq.setMethod('PUT');
	    httpReq.setHeader('Content-Length', '0');
        Http h = new Http();
        HttpResponse res = h.send(httpReq);
		system.debug('result = ' + res.getBody());
		Response response = ((list<Response>)JSON.deserialize('[' + res.getBody() + ']', list<Response>.class))[0];
		return response;
	}
	
	private static string fixDate (integer d){
		if (string.valueof(d).length() == 1){
			return '0' + string.valueof(d);
		}
		else{
			return string.valueof(d);
		}
	}
	
	public static string generateBody(Sales_Order__c so){
		token = getToken();
		list<SO_Line_Items__c> lineItems = [select Product_Cost__c, Sub_Total__c, DiscountAmount__c, Row_Total__c, Quantity__c, ProductName__c, Quantity_Invoiced__c, Bundle_Item__c, Sales_Order__r.DiscountAmount__c from SO_Line_Items__c where Sales_Order__c = :so.id];
		//string plan = '';
		Request req = new Request();
		req.TransactionItems = new list<TransactionItem>();
		set<string> productToSplit = new set<string>();
		for (SO_Line_Items__c li : lineItems){
			if (li.ProductName__c == null || li.ProductName__c.contains('Protection Plan') || li.Bundle_Item__c != null){
				//plan = li.Products__r.Plan_code__c;
				continue;
			}
			productToSplit.add(li.id);
			system.debug('productToSplit = ' + productToSplit);
		}
		integer index = 1;
		decimal orderDiscount = lineItems[0].Sales_Order__r.DiscountAmount__c != null && lineItems[0].Sales_Order__r.DiscountAmount__c != 0 ? lineItems[0].Sales_Order__r.DiscountAmount__c / productToSplit.size() : 0;
		for (SO_Line_Items__c li : lineItems){
			if (li.ProductName__c == null || li.ProductName__c.contains('Protection Plan')){
				//plan = li.Products__r.Plan_code__c;
				continue;
			}
			TransactionItem ti = new TransactionItem();
			ti.ItemTransactionNumber = string.valueof(index);
			ti.WholesalePrice = string.valueof(li.Product_Cost__c);
			if (productToSplit.contains(li.id)){
				ti.RetailPrice = li.Bundle_Item__c == null && li.Quantity__c != null && li.Quantity__c > 0 ? string.valueof(((li.Sub_Total__c - li.DiscountAmount__c) / li.Quantity__c) - (orderDiscount/ li.Quantity__c))  : '0.00';
			}
			else{
			ti.RetailPrice = li.Bundle_Item__c == null && li.Quantity__c != null && li.Quantity__c > 0 ? string.valueof((li.Sub_Total__c - li.DiscountAmount__c) / li.Quantity__c)  : '0.00';
			}
			ti.Description = li.ProductName__c;
			ti.Quantity = string.valueof(li.Quantity__c);
			req.TransactionItems.add(ti);
			index ++;
		}
		req.StoreNumber = gs.Store_Number__c;
		req.RetailerNumber = gs.Retailer_Number__c;
		//req.DistributorNumber = gs.Distributor_Number__c;
		req.InvoiceNumber = so.Magento_order_No__c;
		req.InvoiceDate = fixDate(so.Order_Date__c.month()) + '-' + fixDate(so.Order_Date__c.day()) + '-' + string.valueof(so.Order_Date__c.year());
		req.ProtectionPlanSku = so.Plan_code__c;//gs.Plan_code__c;
		req.EstimatedDeliveryDate = fixDate(system.today().adddays(14).month()) + '-' + fixDate(system.today().adddays(14).day()) + '-' + string.valueof(system.today().adddays(14).year());
		req.TransactionTotal = string.valueof(so.Grand_Total__c - so.Protection_Plan_Cost__c);
		req.RetailProtectionPrice = string.valueof(so.Protection_Plan_Cost__c);
		req.Tax = string.valueof(so.TaxAmount__c);
		req.ShippingCost = string.valueof(so.Shipping_Handle__c);
		req.TotalBilledAmount = string.valueof(so.Grand_Total__c);
		req.ProtectionPlanPrice = '0.00';
		req.Payment = new Payment();
		req.Payment.Billing = new Billing();
		list<string> billName = so.Bill_To__c.split(' ', 2);
		req.Payment.Billing.CustomerInfo = new CustomerInfo();
		req.Payment.Billing.CustomerInfo.FirstName = billName[0];//so.Bill_To__c;
		req.Payment.Billing.CustomerInfo.LastName = billName[1];//so.Bill_To__c;
		req.Payment.Billing.CustomerInfo.Address_1 = so.Billing_Street__c;
		req.Payment.Billing.CustomerInfo.City = so.Billing_City__c;
		req.Payment.Billing.CustomerInfo.State = so.Billing_State__c;
		req.Payment.Billing.CustomerInfo.Zip = so.Billing_ZipCode__c;
		req.Payment.Billing.CustomerInfo.Email = so.Email__c;
		req.Payment.Billing.CustomerInfo.HomePhone = so.Billing_Phone__c;
		req.Payment.Shipping = new Shipping();
		list<string> shipName = so.Ship_To__c.split(' ', 2);
		req.Payment.Shipping.CustomerInfo = new CustomerInfo();
		req.Payment.Shipping.CustomerInfo.FirstName = shipName[0];//so.Ship_To__c;
		req.Payment.Shipping.CustomerInfo.LastName = shipName[1];//so.Ship_To__c;
		req.Payment.Shipping.CustomerInfo.Address_1 = so.Shipping_Street__c;
		req.Payment.Shipping.CustomerInfo.City = so.Shipping_City__c;
		req.Payment.Shipping.CustomerInfo.State = so.Shipping_State__c;
		req.Payment.Shipping.CustomerInfo.Zip = so.Shipping_ZipCode__c;
		req.Payment.Shipping.CustomerInfo.Email = so.Email__c;
		req.Payment.Shipping.CustomerInfo.HomePhone = so.Shipping_Phone__c;
		
		string ret = Json.Serialize(req);
		return ret;
	}
	
	
	public class Request{
		public string StoreNumber {get; set;}
		public string RetailerNumber {get; set;}
		//public string DistributorNumber {get; set;}
		public string InvoiceNumber {get; set;}
		public string InvoiceDate {get; set;}
		public string ProtectionPlanSku {get; set;}
		public string EstimatedDeliveryDate {get; set;}
		public string TransactionTotal {get; set;}
		public string RetailProtectionPrice {get; set;}
		public string Tax {get; set;}
		public string ShippingCost {get; set;}
		public string TotalBilledAmount {get; set;}
		public string ProtectionPlanPrice {get; set;}
		public list<TransactionItem> TransactionItems {get; set;}
		public Payment Payment {get; set;}
		
	}
	public class TransactionItem{
		public string ItemTransactionNumber {get; set;}
		public string WholesalePrice {get; set;}
		public string RetailPrice {get; set;}
		public string Description {get; set;}
		public string Quantity {get; set;}
	}
	public class Payment{
		public Billing Billing {get; set;}
		public Shipping Shipping {get; set;}
	}
	public class Billing{
		public CustomerInfo CustomerInfo {get; set;}
	}
	public class Shipping{
		public CustomerInfo CustomerInfo {get; set;}
	}
	public class CustomerInfo{
		public string FirstName {get; set;}
		public string LastName {get; set;}
		public string Address_1 {get; set;}
		public string State {get; set;}
		public string City {get; set;}
		public string Zip {get; set;}
		public string HomePhone {get; set;}
		public string Email {get; set;}
	}
	
	public class TokenResponse{
		public string access_token {get; set;}
		public string token_type {get; set;}
		public integer expires_in {get; set;}
	}
	
	public class Response{
		public list<Results> results {get; set;}
		public list<Links> links {get; set;}
	}
	
	public class Results{
		public string Info {get; set;}
	}
	
	public class Links{
		public string Title {get; set;}
		public string Href {get; set;}
	}
}