global with sharing class IntegrationAccountHelper {

	
	global class Log{
		public Data Data {get; set;}
		public string LogID {get; set;}
		public string Process {get; set;}
	}
	
	global class Data{
		public string name {get; set;}
		public string customerId {get; set;}
		public string magentoId {get; set;}
		public string salesforceId {get; set;}
		
		
		//Account fields
		public string billing_street {get; set;}
		public string billing_city {get; set;}
		public string billing_country_id {get; set;}
		public string billing_postcode {get; set;}
		public string billing_region {get; set;}
		public string billing_phone {get; set;}
		public string billing_cell {get; set;}
		public string email {get; set;}
		public string firstname {get; set;}
		public string lastname {get; set;}
		public string phone {get; set;}
		public string shipping_street {get; set;}
		public string shipping_city {get; set;}
		public string shipping_country_id {get; set;}
		public string shipping_postcode {get; set;}
		public string shipping_region {get; set;}
		public string shipping_phone {get; set;}
		public string shipping_cell {get; set;}
		public string middlename {get; set;}
		public string sales_rep_name {get; set;}
		public string customergroup {get; set;}
		public string company_name {get; set;}
		public string magento_sales_rep_id {get; set;}
		public string website_id {get; set;}
		
	}
}