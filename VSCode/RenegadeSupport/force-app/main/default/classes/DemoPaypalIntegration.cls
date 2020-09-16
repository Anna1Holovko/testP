public class DemoPaypalIntegration {
    
    Sales_Order__c orderObject;
    
    public static AuthResponseWrapper obj;
    
    public DemoPaypalIntegration(){
        //Initializing variables
        orderObject=new Sales_Order__c();
        
        obj = new AuthResponseWrapper();
        //Accessing Custom Setting 
        Paypal_OAuth__c mc = Paypal_OAuth__c.getValues('Auth Stage');
        //Setting OAuth call variables
        string clientId=mc.Client_ID__c;
		string clientSecret=mc.Client_Secret__c;
        string endpoint = 'https://api.sandbox.paypal.com/v1/oauth2/token';
        string body='grant_type=client_credentials';
		
		Blob headerValue = Blob.valueOf(clientId +':' +clientSecret);
		String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
		
		http http = new http();
        httpRequest req = new httpRequest();
		req.setMethod('POST');
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		req.setHeader('Authorization', authorizationHeader);
        req.setBody(body);
        httpResponse Res = http.send(req);
        //Printing response
        //system.debug(res.getBody());
        
        obj=(AuthResponseWrapper)JSON.deserialize(res.getBody(), AuthResponseWrapper.class);
        //Ptrint access token
        //system.debug(obj.access_token);
    }
    
    public static string createDraftInvoice(){
        
        string endpoint='https://api.sandbox.paypal.com/v1/invoicing/invoices/';
        http http = new http();
        
		httpRequest req = new httpRequest();
		req.setMethod('POST');
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
		req.setHeader('Authorization', 'Bearer '+obj.access_token);
        req.setBody(createDummyInvoiceData());
        httpResponse Res = http.send(req);
        system.debug(res.getBody());
        
        return '';
    }
    
    public static string createDummyInvoiceData(){
        
        InvoiceWrapper dummyInvoiceObject=new InvoiceWrapper();
        	//Merchant Info
        	/*
        	cls_merchant_info merchantInfo=new cls_merchant_info();
        	merchantInfo.email='mmkarp@gmail.com';
        	merchantInfo.first_name='Mendy';
        	merchantInfo.last_name='Karp';
        	merchantInfo.business_name='Mendy Karp';
        		//Phone
        		cls_phone merchantPhone=new cls_phone();
        		merchantPhone.country_code='1';
        		merchantPhone.national_number='3479307957';
        		//Address
        		cls_address merchantAddress=new cls_address();
        		merchantAddress.line1='1234 First Street';
        		merchantAddress.city='Anytown';
        		merchantAddress.state='CA';
        		merchantAddress.postal_code='98765';
        		merchantAddress.country_code='US';
        
        	merchantInfo.phone=merchantPhone;
        	merchantInfo.address=merchantAddress;
        dummyInvoiceObject.merchant_info=merchantInfo;
		*/
        	//Items
        	cls_items[] merchantItems=new cls_items[]{};
        	cls_items item= new  cls_items();
        	item.name='Demo Item';
        	item.quantity=1;
        		//Unit Price
        		cls_unit_price itemUnitPrice=new cls_unit_price();
        		itemUnitPrice.unit_price_currency='USD';
        		itemUnitPrice.value='20';
        	item.unit_price=itemUnitPrice;
        	merchantItems.add(item);
        dummyInvoiceObject.items=merchantItems;
        dummyInvoiceObject.note='This is a demo invoice draft';
        
        string JSONobject=JSON.serialize(dummyInvoiceObject,true);
        
        system.debug('Serialized Object: '+JSONobject.replaceAll('unit_price_currency','currency'));
        
        return JSONobject.replaceAll('unit_price_currency','currency');
    }
    
    public static string sendInvoice(string salesOrderID){
        string invoiceStatus;
        if(string.isEmpty(salesOrderID)){
            invoiceStatus='No Sales Order ID found!';
            return invoiceStatus;
        }
        
        //Get SalesOrder record data and items on the order
        
        
        string InvoiceId;
        string endpoint='https://api.sandbox.paypal.com/v1/invoicing/invoices/'+InvoiceId+'/send?notify_merchant=true';
        http http = new http();
        
		httpRequest req = new httpRequest();
		req.setMethod('POST');
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
		req.setHeader('Authorization', 'Bearer '+obj.access_token);
        httpResponse Res = http.send(req);
        system.debug(res.getBody());
        
        return invoiceStatus;
        
    }
    
    public class AuthResponseWrapper{
		public String scope;
		public String nonce;
		public String access_token;
		public String token_type;
		public String app_id;
		public Integer expires_in;
	}
    
    public class InvoiceWrapper{
        public cls_merchant_info merchant_info;
		public cls_billing_info[] billing_info;
		public cls_shipping_info shipping_info;
		public cls_items[] items;
		public cls_discount discount;
		public cls_shipping_cost shipping_cost;
		public String note;
        public String terms;
    }
    
    public class cls_merchant_info {
		public String email;
		public String first_name;
		public String last_name;
		public String business_name;
		public cls_phone phone;
		public cls_address address;
	}
	public class cls_phone {
		public String country_code;
		public String national_number;
	}
	public class cls_address {
		public String line1;
		public String city;
		public String state;
		public String postal_code;
		public String country_code;
	}
	public class cls_billing_info {
		public String email;
		public String first_name;	
		public String last_name;	
	}
	public class cls_shipping_info {
		public String first_name;	
		public String last_name;	
		public cls_address address;
	}
	public class cls_items {
		public String name;	
		public Integer quantity;
		public cls_unit_price unit_price;
		public cls_tax tax;
	}
	public class cls_unit_price {
		public String unit_price_currency;	
		public String value;	
	}
	public class cls_tax {
		public String name;
		public Integer percent;
	}
	public class cls_discount {
		public Integer percent;	
	}
	public class cls_shipping_cost {
		public cls_amount amount;
	}
	public class cls_amount {
		public String amount_currency;	
		public String value;	
	}

}