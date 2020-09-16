public class PaypalInvoiceObjectClass {
    
    public cls_merchant_info merchant_info;
    public cls_billing_info[] billing_info;
	public cls_shipping_info shipping_info;
	public cls_items[] items;
	public cls_discount discount;
	public cls_shipping_cost shipping_cost;
	public String note;
	public String terms;
    
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