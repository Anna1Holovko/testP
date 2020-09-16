@isTest
private class IntegrationManagerTest {
	
	static testMethod void createNewLogAccount() {
		IntegrationManager.Log log = new IntegrationManager.Log();
		log.LogID = '123123123';
		log.Process = 'Account created';
		IntegrationManager.Data dat = new IntegrationManager.Data();
		dat.billing_cell = '89687567';
		dat.billing_city = 'Los Angeles';
		dat.billing_country_id = 'US';
		dat.billing_phone = '34643756776857';
		dat.billing_postcode = '233452';
		dat.billing_region = 'Arkansas';
		dat.billing_street = '2 downing street';
		dat.customergroup = '1';
		dat.email = 'test@testtt.com';
		dat.firstname = 'Mentch';
		dat.lastname = 'Kurant';
		dat.magentoId = '65183';
		dat.magento_sales_rep_id = '0';
		dat.shipping_city = 'San Jose';
		dat.shipping_country_id = 'US';
		dat.shipping_phone = '89687567';
		dat.shipping_postcode = '95131';
		dat.shipping_region = 'Arizona';
		dat.shipping_street = '4 main st';
		dat.website_id = '1';
		
		WebsiteId_To_Website_Name_Setting__c sett= new WebsiteId_To_Website_Name_Setting__c(name='1', Website_Name__c = 'Coleman Furniture');
        insert sett;
		//salesforceId=0010S000007IP6xQAG
		Test.startTest();	
		IntegrationManager.response res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Failed');
		log.Data = dat;
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
		system.debug('res = ' + res);
		log.Data.salesforceId = res.responseData[0].salesforceId;
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
		log.LogID = '123123124';
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
		log.LogID = '123123124';
		log.Data.magentoId = '';
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
        Test.stopTest();
	}
	
	@isTest
    static void createOldOrderFromLogTest(){
        IntegrationManager.order_item ordIt = new IntegrationManager.order_item();
        ordIt.base_image = 'test';
        ordIt.magento_productId  = 'test';
        ordIt.magento_configurable_product = 'test';
        
        IntegrationManager.Order ord= new IntegrationManager.Order();
        ord.billing_cell = 'test';
        ord.created_date = 'test';
    	ord.callerId  = 'test';
        
        IntegrationManager.related_item relIt= new IntegrationManager.related_item();
        relIt.magento_productId = 'test';
    	relIt.magento_configurable_product = 'test';
	}
	
	static testMethod void createNewLogProduct() {
		IntegrationManager.Log log = new IntegrationManager.Log();
		log.LogID = '123123124';
		log.Process = 'Product created_updated';
		IntegrationManager.Data dat = new IntegrationManager.Data();
		IntegrationManager.product pro = new IntegrationManager.product();
		list<IntegrationManager.product> pros = new list<IntegrationManager.product>();
		
		//simple product
		pro.magentoId = '123454332';
		pro.sku = '123454332';
		pro.name = '123454332';
		pro.mpn = '123454332';
		pro.upc = '123454332';
		pro.tier_price_for_bundle = 22;
		pro.type = 'simple';
		pro.cost = 22;
		pro.price = 22;
		pro.special_price = 22;
		pro.special_price_start_date = system.today();
		pro.special_price_end_date = system.today();
		pro.special_tier_price = 22;
		pro.weight = 22;
		pro.status = 'status';
		pro.discontinued = '123454332';
		pro.visibility = '123454332';
		pro.description = '123454332';
		pro.carton_dimensions = '123454332';
		pro.Box = '123454332';
		pro.qty = 22;
		pro.estimated_shipping = 22;
		pro.estimated_set_shipping = 22;
		pro.dimensions = '123454332';
		pro.dropshipped = '123454332';
		pro.ships = '123454332';
		pro.fedexable = '123454332';
		pro.delivery = '123454332';
		pro.ashley_express = '123454332';
		pro.base_image = '123454332';
		pro.url_key = '123454332';
		pro.tax_class = '123454332';
		pro.breakeven = '123454332';
		pro.categories = '123454332';
		pro.manufacturer = '123454332';
		pro.pricing_type = '123454332';
		pro.special_tier_price_end_date = system.today();
		pro.special_tier_price_start_date = system.today();
		pro.websites = '123454332';
		pro.regular_price = 22;
		pro.set_includes = '123454332';
		pros.add(pro);
		
		log.Data = dat;
		log.Data.products = pros;
		Test.startTest();
		//Create only simple product
		IntegrationManager.response res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
  		system.debug('res = ' + res);
  		
  		
		//configurable product
		IntegrationManager.product configurablePro = new IntegrationManager.product();
		configurablePro.magentoId = '123454333';
		configurablePro.sku = '123454333';
		configurablePro.name = '123454332';
		configurablePro.mpn = '123454332';
		configurablePro.upc = '123454332';
		configurablePro.tier_price_for_bundle = 22;
		configurablePro.type = 'configurable';
		configurablePro.cost = 22;
		configurablePro.price = 22;
		configurablePro.special_price = 22;
		configurablePro.special_price_start_date = system.today();
		configurablePro.special_price_end_date = system.today();
		configurablePro.special_tier_price = 22;
		configurablePro.weight = 22;
		configurablePro.status = 'status';
		configurablePro.discontinued = '123454332';
		configurablePro.visibility = '123454332';
		configurablePro.description = '123454332';
		configurablePro.carton_dimensions = '123454332';
		configurablePro.Box = '123454332';
		configurablePro.qty = 22;
		configurablePro.estimated_shipping = 22;
		configurablePro.estimated_set_shipping = 22;
		configurablePro.dimensions = '123454332';
		configurablePro.dropshipped = '123454332';
		configurablePro.ships = '123454332';
		configurablePro.fedexable = '123454332';
		configurablePro.delivery = '123454332';
		configurablePro.ashley_express = '123454332';
		configurablePro.base_image = '123454332';
		configurablePro.url_key = '123454332';
		configurablePro.tax_class = '123454332';
		configurablePro.breakeven = '123454332';
		configurablePro.categories = '123454332';
		configurablePro.manufacturer = '123454332';
		configurablePro.pricing_type = '123454332';
		configurablePro.special_tier_price_end_date = system.today();
		configurablePro.special_tier_price_start_date = system.today();
		configurablePro.websites = '123454332';
		configurablePro.regular_price = 22;
		configurablePro.set_includes = '123454332';
		pros.add(configurablePro);
		IntegrationManager.associated ass = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> asses = new list<IntegrationManager.associated>();
		asses.add(ass);
		configurablePro.associated_attributes = asses;
		
		//Create a configurable with simple product
		log.LogID = '123123125';
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
  		system.debug('1res = ' + res);
  		
  		
		//bundle product
		IntegrationManager.product bundlePro = new IntegrationManager.product();
		bundlePro.magentoId = '123454339';
		bundlePro.sku = '123454339';
		bundlePro.name = '123454332';
		bundlePro.mpn = '123454332';
		bundlePro.upc = '123454332';
		bundlePro.tier_price_for_bundle = 22;
		bundlePro.type = 'bundle';
		bundlePro.cost = 22;
		bundlePro.price = 22;
		bundlePro.special_price = 22;
		bundlePro.special_price_start_date = system.today();
		bundlePro.special_price_end_date = system.today();
		bundlePro.special_tier_price = 22;
		bundlePro.weight = 22;
		bundlePro.status = 'status';
		bundlePro.discontinued = '123454332';
		bundlePro.visibility = '123454332';
		bundlePro.description = '123454332';
		bundlePro.carton_dimensions = '123454332';
		bundlePro.Box = '123454332';
		bundlePro.qty = 22;
		bundlePro.estimated_shipping = 22;
		bundlePro.estimated_set_shipping = 22;
		bundlePro.dimensions = '123454332';
		bundlePro.dropshipped = '123454332';
		bundlePro.ships = '123454332';
		bundlePro.fedexable = '123454332';
		bundlePro.delivery = '123454332';
		bundlePro.ashley_express = '123454332';
		bundlePro.base_image = '123454332';
		bundlePro.url_key = '123454332';
		bundlePro.tax_class = '123454332';
		bundlePro.breakeven = '123454332';
		bundlePro.categories = '123454332';
		bundlePro.manufacturer = '123454332';
		bundlePro.pricing_type = '123454332';
		bundlePro.special_tier_price_end_date = system.today();
		bundlePro.special_tier_price_start_date = system.today();
		bundlePro.websites = '123454332';
		bundlePro.regular_price = 22;
		bundlePro.set_includes = '123454332';
		pros.add(bundlePro);
		IntegrationManager.associated assb = new IntegrationManager.associated('123454332');
		IntegrationManager.associated assc = new IntegrationManager.associated('123454333');
		list<IntegrationManager.associated> assesb = new list<IntegrationManager.associated>();
		assesb.add(assb);
		assesb.add(assc);
		bundlePro.associated_attributes = assesb;
		
		//Create a bundle with configurable and simple product
		log.LogID = '123123126';
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
  		system.debug('2res = ' + res);
		
		//Update a bundle with configurable and simple product
		log.LogID = '123123127';
		res = IntegrationManager.createNewLog(log);
  		system.assertequals(res.status, 'Succeeded');
  		system.debug('3res = ' + res);
        Test.stopTest();
	}
	
	static testMethod void createNewLogOrder() {
		//create account 
		IntegrationManager.Log logAcc = new IntegrationManager.Log();
		logAcc.LogID = '123123123';
		logAcc.Process = 'Account created';
		IntegrationManager.Data dat = new IntegrationManager.Data();
		dat.billing_cell = '89687567';
		dat.billing_city = 'Los Angeles';
		dat.billing_country_id = 'US';
		dat.billing_phone = '34643756776857';
		dat.billing_postcode = '233452';
		dat.billing_region = 'Arkansas';
		dat.billing_street = '2 downing street';
		dat.customergroup = '1';
		dat.email = 'test@testtt.com';
		dat.firstname = 'Mentch';
		dat.lastname = 'Kurant';
		dat.magentoId = '65183';
		dat.magento_sales_rep_id = '0';
		dat.shipping_city = 'San Jose';
		dat.shipping_country_id = 'US';
		dat.shipping_phone = '89687567';
		dat.shipping_postcode = '95131';
		dat.shipping_region = 'Arizona';
		dat.shipping_street = '4 main st';
		dat.website_id = '1';
        dat.shipping_cell = 'test';
        dat.middlename = 'test';
        dat.sales_rep_name = 'test';
        //dat.created_date = 'test';
        dat.company_name = 'test';
        dat.name = 'test';
        //dat.customerId {get; set;}
        
		logAcc.Data = dat;
        test.startTest();
		IntegrationManager.response accountres = IntegrationManager.createNewLog(logAcc);
  		system.assertequals(accountres.status, 'Succeeded');
  		
  		
  		
  		Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
  		
		IntegrationManager.Log logProd = new IntegrationManager.Log();
		logProd.LogID = '123123124';
		logProd.Process = 'Product created_updated';
		dat = new IntegrationManager.Data();
		IntegrationManager.product pro = new IntegrationManager.product();
		list<IntegrationManager.product> pros = new list<IntegrationManager.product>();
		
		//simple product
		pro.magentoId = '123454332';
		pro.sku = '123454332';
		pro.name = '123454332';
		pro.mpn = '123454332';
		pro.upc = '123454332';
		pro.tier_price_for_bundle = 22;
		pro.type = 'simple';
		pro.cost = 22;
		pro.price = 22;
		pro.special_price = 22;
		pro.special_price_start_date = system.today();
		pro.special_price_end_date = system.today();
		pro.special_tier_price = 22;
		pro.weight = 22;
		pro.status = 'status';
		pro.discontinued = '123454332';
		pro.visibility = '123454332';
		pro.description = '123454332';
		pro.carton_dimensions = '123454332';
		pro.Box = '123454332';
		pro.qty = 22;
		pro.estimated_shipping = 22;
		pro.estimated_set_shipping = 22;
		pro.dimensions = '123454332';
		pro.dropshipped = '123454332';
		pro.ships = '123454332';
		pro.fedexable = '123454332';
		pro.delivery = '123454332';
		pro.ashley_express = '123454332';
		pro.base_image = '123454332';
		pro.url_key = '123454332';
		pro.tax_class = '123454332';
		pro.breakeven = '123454332';
		pro.categories = '123454332';
		pro.manufacturer = '123454332';
		pro.pricing_type = '123454332';
		pro.special_tier_price_end_date = system.today();
		pro.special_tier_price_start_date = system.today();
		pro.websites = '123454332';
		pro.regular_price = 22;
		pro.set_includes = '123454332';
		pros.add(pro);
		
		logProd.Data = dat;
		logProd.Data.products = pros;
		
		//Create only simple product
		IntegrationManager.response sres = IntegrationManager.createNewLog(logProd);
  		
  		
  		
		//configurable product
		IntegrationManager.product configurablePro = new IntegrationManager.product();
		configurablePro.magentoId = '123454333';
		configurablePro.sku = '123454333';
		configurablePro.name = '123454332';
		configurablePro.mpn = '123454332';
		configurablePro.upc = '123454332';
		configurablePro.tier_price_for_bundle = 22;
		configurablePro.type = 'configurable';
		configurablePro.cost = 22;
		configurablePro.price = 22;
		configurablePro.special_price = 22;
		configurablePro.special_price_start_date = system.today();
		configurablePro.special_price_end_date = system.today();
		configurablePro.special_tier_price = 22;
		configurablePro.weight = 22;
		configurablePro.status = 'status';
		configurablePro.discontinued = '123454332';
		configurablePro.visibility = '123454332';
		configurablePro.description = '123454332';
		configurablePro.carton_dimensions = '123454332';
		configurablePro.Box = '123454332';
		configurablePro.qty = 22;
		configurablePro.estimated_shipping = 22;
		configurablePro.estimated_set_shipping = 22;
		configurablePro.dimensions = '123454332';
		configurablePro.dropshipped = '123454332';
		configurablePro.ships = '123454332';
		configurablePro.fedexable = '123454332';
		configurablePro.delivery = '123454332';
		configurablePro.ashley_express = '123454332';
		configurablePro.base_image = '123454332';
		configurablePro.url_key = '123454332';
		configurablePro.tax_class = '123454332';
		configurablePro.breakeven = '123454332';
		configurablePro.categories = '123454332';
		configurablePro.manufacturer = '123454332';
		configurablePro.pricing_type = '123454332';
		configurablePro.special_tier_price_end_date = system.today();
		configurablePro.special_tier_price_start_date = system.today();
		configurablePro.websites = '123454332';
		configurablePro.regular_price = 22;
		configurablePro.set_includes = '123454332';
		list<IntegrationManager.product> proc = new list<IntegrationManager.product>();
		proc.add(configurablePro);
		IntegrationManager.associated ass = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> asses = new list<IntegrationManager.associated>();
		asses.add(ass);
		configurablePro.associated_attributes = asses;
		logProd.Data.products = proc;
		
		//Create a configurable with simple product
		logProd.LogID = '123123125';
		IntegrationManager.response cres = IntegrationManager.createNewLog(logProd);
  		
  		
		//bundle product
		IntegrationManager.product bundlePro = new IntegrationManager.product();
		bundlePro.magentoId = '123454339';
		bundlePro.sku = '123454339';
		bundlePro.name = '123454332';
		bundlePro.mpn = '123454332';
		bundlePro.upc = '123454332';
		bundlePro.tier_price_for_bundle = 22;
		bundlePro.type = 'bundle';
		bundlePro.cost = 22;
		bundlePro.price = 22;
		bundlePro.special_price = 22;
		bundlePro.special_price_start_date = system.today();
		bundlePro.special_price_end_date = system.today();
		bundlePro.special_tier_price = 22;
		bundlePro.weight = 22;
		bundlePro.status = 'status';
		bundlePro.discontinued = '123454332';
		bundlePro.visibility = '123454332';
		bundlePro.description = '123454332';
		bundlePro.carton_dimensions = '123454332';
		bundlePro.Box = '123454332';
		bundlePro.qty = 22;
		bundlePro.estimated_shipping = 22;
		bundlePro.estimated_set_shipping = 22;
		bundlePro.dimensions = '123454332';
		bundlePro.dropshipped = '123454332';
		bundlePro.ships = '123454332';
		bundlePro.fedexable = '123454332';
		bundlePro.delivery = '123454332';
		bundlePro.ashley_express = '123454332';
		bundlePro.base_image = '123454332';
		bundlePro.url_key = '123454332';
		bundlePro.tax_class = '123454332';
		bundlePro.breakeven = '123454332';
		bundlePro.categories = '123454332';
		bundlePro.manufacturer = '123454332';
		bundlePro.pricing_type = '123454332';
		bundlePro.special_tier_price_end_date = system.today();
		bundlePro.special_tier_price_start_date = system.today();
		bundlePro.websites = '123454332';
		bundlePro.regular_price = 22;
		bundlePro.set_includes = '123454332';
		pros.add(bundlePro);
		IntegrationManager.associated assb = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> assesb = new list<IntegrationManager.associated>();
		IntegrationManager.associated assc = new IntegrationManager.associated('123454333');
		assesb.add(assb);
		assesb.add(assc);
		bundlePro.associated_attributes = assesb;
		
		//Create a bundle with simple product
		logProd.LogID = '123123126';
		IntegrationManager.response bres = IntegrationManager.createNewLog(logProd);
  		
  		
		
		IntegrationManager.Log log = new IntegrationManager.Log();
		log.LogID = '123777';
		log.Process = 'Order created';
		IntegrationManager.Data datOrd = new IntegrationManager.Data();
		IntegrationManager.Order ord = new IntegrationManager.Order();
        datOrd.order = ord;
		log.Data = datOrd;
		ord.customerId = accountres.responseData[0].salesforceId;
		ord.magentoId = '1123';
		system.debug('ord = ' + ord);
		ord.billing_city = 'miami beach';
		ord.billing_name = 'mend';
		ord.billing_fax = '3546665454';
		ord.billing_telephone = '3456657676';
		ord.billing_region = 'fl';
		ord.billing_postcode = '33139';
		ord.billing_street = 'main';
		ord.customer_group = '1';
		ord.customer_comments = 'hjhj';
		ord.email = 'mmm@greenclou.com';
		ord.is_email_sent = true;
		ord.remote_ip = '000';
		ord.cc_digits = 1234;
		ord.cc_type = 'Visa';
		ord.avs_response = 'avs';
		ord.created_at = '2017-08-29 17:47:13';
		ord.status = 'pending';
		ord.store_name = 'Main Website\nMain Website Store\nColeman Furniture';
		ord.sales_rep_name = 'rep';
		ord.shipping_cell = '1800544400';
		ord.shipping_city = 'Tel avif';
		ord.shipping_fax = '9987768787';
		ord.shipping_name = 'Mendush';
		ord.shipping_telephone = '7188865656';
		ord.shipping_region = 'FL';
		ord.shipping_street = 'Main';
		ord.shipping_postcode = '12345';
		ord.transaction_id = '123';
		ord.payment_method = 'Credit Card (Authorize.net)';
		ord.increment_id = '1123';
		ord.shipping_amount = 20;
		ord.discount_amount = 20;
		ord.coupon_code = 'jhj';
		ord.subtotal = 200;
		ord.shipping_company ='js';
        ord.billing_company ='hs';
    	/*ord.created_date ='03-01-2019';
        ord.shipping_tax = 5;
        */ord.Paypal_Email_Attribute ='asdfa@gmail.com';
        ord.device_type ='hs'; 
        
        
		IntegrationManager.order_item ois = new IntegrationManager.order_item();
		ois.productId = sres.responseData[0].salesforceId;
        ois.product_name = 'Test';
		ois.discount_amount = 1;
		ois.original_price = 200;
		ois.price = 100;
		ois.Product_sku = 'AA';
		ois.qty_ordered = 1;
		ois.tax_amount = 5;
		ois.commission_amount = 7;
        
		//public list<related_item> related_products {get; set;}
		list<IntegrationManager.order_item> order_items = new list<IntegrationManager.order_item>();
		order_items.add(ois);
		ord.order_items = order_items;
		IntegrationManager.response res = IntegrationManager.createNewLog(log);
		
		
		
		IntegrationManager.order_item oib = new IntegrationManager.order_item();
		oib.productId = bres.responseData[0].salesforceId;

        ois.product_name = 'Test';
		oib.discount_amount = 1;
		oib.original_price = 200;
		oib.price = 100;
		oib.Product_sku = 'AA';
		oib.qty_ordered = 1;
		oib.tax_amount = 5;
		oib.commission_amount = 7;

        
      
		IntegrationManager.related_item ri = new IntegrationManager.related_item();
		ri.productId = sres.responseData[0].salesforceId;
        ri.quantity = '2';
        ri.product_name = 'Test2';
        ri.price = 5;
        ri.product_sku ='test';
		list<IntegrationManager.related_item> related_products = new list<IntegrationManager.related_item>();
		related_products.add(ri);
		oib.related_products = related_products;
		order_items.add(oib);
		
		log.LogID = '123778';
		res = IntegrationManager.createNewLog(log);
		
		ri.configurable_product = cres.responseData[0].salesforceId;
		
		log.LogID = '123779';
		res = IntegrationManager.createNewLog(log);
		
		ois.configurable_product = cres.responseData[0].salesforceId;
		log.LogID = '123780';
		res = IntegrationManager.createNewLog(log);
		
		//OrderManager.createNewLog(res.responseData[0].salesforceId);
		log.LogID = '12377788';
		log.Process = 'oldOrder';
		ord.magentoId = '112345';
		res = IntegrationManager.createNewLog(log);
        Test.stopTest();
	}
    
    
    @isTest
    static void sendLogToMagentoTest(){
        Account acc = TestUtil.createCustomerAccount();
        Account deliveryAcc = TestUtil.createDeliveryAccount();
        
        Payment_Method__c payMeth = TestUtil.createpaymentMethod(acc.id, 'Manual Payment');
        Sales_Order__c ord = TestUtil.createsalesOrder(acc.id, deliveryAcc.id, payMeth.id);
        
        Log__c log = new Log__c();
        log.Data__c='Data:[billing_cell=null, billing_city=null, billing_country_id=null, billing_phone=null, billing_postcode=null, \r\n billing_region=null, billing_street=null, \r company_name=null, created_date=null, customerId=null, '+
            'customergroup=null, email=null, firstname=null, lastname=null, magentoId=null, magento_sales_rep_id=null, middlename=null, name=null, order=Order:[Paypal_Email_Attribute=null, avs_response=Y, billing_cell=null, billing_city=Honululu,'+
            ' billing_company=, billing_fax=null, billing_name=Tayyab Javed, billing_postcode=34843, billing_region=Hawaii, billing_street=Block St, billing_telephone=938544554, cc_digits=1111, cc_type=VI, coupon_code=null, created_at=2018-10-08 08:26:01,'+
            ' created_date=2018-10-08 08:26:01, customerId=0013B00000V8TrYQAV, customer_comments=null, customer_group=NOT LOGGED IN, device_type=null, discount_amount=0, email=tayyab321@gmail.com, increment_id=275821, is_email_sent=true, magentoId=222222,'+
            ' order_items=(order_item:[Product_sku=EEI-610-EXP-MOC-SET, base_image=null, commission_amount=null, configurable_product=, created_date=2018-10-08 08:26:01, discount_amount=0.0000, magento_configurable_product=null, magento_productId=10577, '+
            'original_price=2775.2490, price=2775.2490, productId=a0H3B000008BngQUAS, product_name=Venice Outdoor Rattan 8 Piece Set In Espresso with Mocha Cushions, qty_ordered=1.0000, related_products=null, tax_amount=0.0000, tax_percent=null], '+
            'order_item:[Product_sku=GUARDIAN, base_image=null, commission_amount=null, configurable_product=, created_date=2018-10-08 08:26:01, discount_amount=0.0000, magento_configurable_product=null, magento_productId=39039, original_price=99.7420, price=0.0000, '+
            'productId=a0H3B000008BnfxUAC, product_name=Guardian 5 Year Protection Plan, qty_ordered=1.0000, related_products=null, tax_amount=0.0000, tax_percent=null]), payment_id=1829110240, payment_method=Credit Card, profile_id=1914902959, remote_ip=39.36.174.204,'+
            ' sales_rep_name=, shipping_amount=258.0000, shipping_cell=null, shipping_city=Honululu, shipping_company=, shipping_fax=null, shipping_name=Tayyab Javed, shipping_postcode=34843, shipping_region=Hawaii, shipping_street=Block St, shipping_tax=0.0000,'+
            ' shipping_telephone=938544554, status=processing, store_name=Coleman Furniture, subtotal=2775.0000, transaction_id=60109575185], phone=null, products=null, sales_rep_name=null, salesforceId=null, shipping_cell=null, shipping_city=null,'+
            ' shipping_country_id=null, \n shipping_phone=null, shipping_postcode=null, shipping_region=null, shipping_street=null, website_id=null]';   
        log.Error__c='';
            log.Log_ID__c = '55555';
            log.Object_ID__c = ord.id;
            log.Owner__c = 'Magento';
            log.Process__c = 'Order created'; 
            log.Response__c='null \n Response:[error=, responseData=(ResponseData:[error=null, magentoId=222222, salesforceId=a0M3B000003NYRIUA4]), status=Succeeded]';
            log.Tries__c=0;
            log.Status__c='Succeeded';
        
        insert log;
        Test.startTest();
			IntegrationManager.sendLogToMagento(log.id);
        	log.Process__c = 'Order updated';  
        	update log;
        	IntegrationManager.sendLogToMagento(log.id);
			
        	
    	Test.stopTest();
    }
    @isTest 
    static void  sendLogToMagentoAccCreateTest(){
        Account acc = TestUtil.createCustomerAccount();
        Account deliveryAcc = TestUtil.createDeliveryAccount();
        
        Payment_Method__c payMeth = TestUtil.createpaymentMethod(acc.id, 'Manual Payment');
        Sales_Order__c ord = TestUtil.createsalesOrder(acc.id, deliveryAcc.id, payMeth.id);
        
        Log__c log = new Log__c();
        log.Data__c='Data:[billing_cell=null, billing_city=null, billing_country_id=null, billing_phone=null, billing_postcode=null, \r\n billing_region=null, billing_street=null, \r company_name=null, created_date=null, customerId=null, '+
            'customergroup=null, email=null, firstname=null, lastname=null, magentoId=null, magento_sales_rep_id=null, middlename=null, name=null, order=Order:[Paypal_Email_Attribute=null, avs_response=Y, billing_cell=null, billing_city=Honululu,'+
            ' billing_company=, billing_fax=null, billing_name=Tayyab Javed, billing_postcode=34843, billing_region=Hawaii, billing_street=Block St, billing_telephone=938544554, cc_digits=1111, cc_type=VI, coupon_code=null, created_at=2018-10-08 08:26:01,'+
            ' created_date=2018-10-08 08:26:01, customerId=0013B00000V8TrYQAV, customer_comments=null, customer_group=NOT LOGGED IN, device_type=null, discount_amount=0, email=tayyab321@gmail.com, increment_id=275821, is_email_sent=true, magentoId=222222,'+
            ' order_items=(order_item:[Product_sku=EEI-610-EXP-MOC-SET, base_image=null, commission_amount=null, configurable_product=, created_date=2018-10-08 08:26:01, discount_amount=0.0000, magento_configurable_product=null, magento_productId=10577, '+
            'original_price=2775.2490, price=2775.2490, productId=a0H3B000008BngQUAS, product_name=Venice Outdoor Rattan 8 Piece Set In Espresso with Mocha Cushions, qty_ordered=1.0000, related_products=null, tax_amount=0.0000, tax_percent=null], '+
            'order_item:[Product_sku=GUARDIAN, base_image=null, commission_amount=null, configurable_product=, created_date=2018-10-08 08:26:01, discount_amount=0.0000, magento_configurable_product=null, magento_productId=39039, original_price=99.7420, price=0.0000, '+
            'productId=a0H3B000008BnfxUAC, product_name=Guardian 5 Year Protection Plan, qty_ordered=1.0000, related_products=null, tax_amount=0.0000, tax_percent=null]), payment_id=1829110240, payment_method=Credit Card, profile_id=1914902959, remote_ip=39.36.174.204,'+
            ' sales_rep_name=, shipping_amount=258.0000, shipping_cell=null, shipping_city=Honululu, shipping_company=, shipping_fax=null, shipping_name=Tayyab Javed, shipping_postcode=34843, shipping_region=Hawaii, shipping_street=Block St, shipping_tax=0.0000,'+
            ' shipping_telephone=938544554, status=processing, store_name=Coleman Furniture, subtotal=2775.0000, transaction_id=60109575185], phone=null, products=null, sales_rep_name=null, salesforceId=null, shipping_cell=null, shipping_city=null,'+
            ' shipping_country_id=null, \n shipping_phone=null, shipping_postcode=null, shipping_region=null, shipping_street=null, website_id=null]';   
        log.Error__c='';
            log.Log_ID__c = '55555';
            log.Object_ID__c = acc.id;
            log.Owner__c = 'Magento';
            log.Process__c = 'Account created'; 
            log.Response__c='null \n Response:[error=, responseData=(ResponseData:[error=null, magentoId=222222, salesforceId=a0M3B000003NYRIUA4]), status=Succeeded]';
            log.Tries__c=0;
            log.Status__c='Succeeded';
        
        insert log;
        Test.startTest();
        	IntegrationManager.sendLogToMagento(log.id);
        Test.stopTest();
    }
    @isTest
    static void createUpdateConfigProdTest(){
        IntegrationManager.Log logAcc = new IntegrationManager.Log();
		logAcc.LogID = '123123123';
		logAcc.Process = 'Account created';
		IntegrationManager.Data dat = new IntegrationManager.Data();
		dat.billing_cell = '89687567';
		dat.billing_city = 'Los Angeles';
		dat.billing_country_id = 'US';
		dat.billing_phone = '34643756776857';
		dat.billing_postcode = '233452';
		dat.billing_region = 'Arkansas';
		dat.billing_street = '2 downing street';
		dat.customergroup = '1';
		dat.email = 'test@testtt.com';
		dat.firstname = 'Mentch';
		dat.lastname = 'Kurant';
		dat.magentoId = '65183';
		dat.magento_sales_rep_id = '0';
		dat.shipping_city = 'San Jose';
		dat.shipping_country_id = 'US';
		dat.shipping_phone = '89687567';
		dat.shipping_postcode = '95131';
		dat.shipping_region = 'Arizona';
		dat.shipping_street = '4 main st';
		dat.website_id = '1';
		logAcc.Data = dat;
        test.startTest();
		IntegrationManager.response accountres = IntegrationManager.createNewLog(logAcc);
  		system.assertequals(accountres.status, 'Succeeded');
  		
  		
  		
  		Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
  		
		IntegrationManager.Log logProd = new IntegrationManager.Log();
		logProd.LogID = '123123124';
		logProd.Process = 'Product created_updated';
		dat = new IntegrationManager.Data();
		IntegrationManager.product pro = new IntegrationManager.product();
		list<IntegrationManager.product> pros = new list<IntegrationManager.product>();
		
		//simple product
		pro.magentoId = '123454332';
		pro.sku = '123454332';
		pro.name = '123454332';
		pro.mpn = '123454332';
		pro.upc = '123454332';
		pro.tier_price_for_bundle = 22;
		pro.type = 'simple';
		pro.cost = 22;
		pro.price = 22;
		pro.special_price = 22;
		pro.special_price_start_date = system.today();
		pro.special_price_end_date = system.today();
		pro.special_tier_price = 22;
		pro.weight = 22;
		pro.status = 'status';
		pro.discontinued = '123454332';
		pro.visibility = '123454332';
		pro.description = '123454332';
		pro.carton_dimensions = '123454332';
		pro.Box = '123454332';
		pro.qty = 22;
		pro.estimated_shipping = 22;
		pro.estimated_set_shipping = 22;
		pro.dimensions = '123454332';
		pro.dropshipped = '123454332';
		pro.ships = '123454332';
		pro.fedexable = '123454332';
		pro.delivery = '123454332';
		pro.ashley_express = '123454332';
		pro.base_image = '123454332';
		pro.url_key = '123454332';
		pro.tax_class = '123454332';
		pro.breakeven = '123454332';
		pro.categories = '123454332';
		pro.manufacturer = '123454332';
		pro.pricing_type = '123454332';
		pro.special_tier_price_end_date = system.today();
		pro.special_tier_price_start_date = system.today();
		pro.websites = '123454332';
		pro.regular_price = 22;
		pro.set_includes = '123454332';
		pro.estimated_freight=1;
        pro.overweight_fee =1;
        pro.estimated_individual_wg =1;
        pro.estimated_final_shipping =1;
        pro.estimated_set_freight =1;
        pro.estimated_set_wg =1;
        pro.estimated_final_set_shipping =1;
        pro.set_cost =1;
        pro.sale_cost =1;
    	pro.sale_cost_valid_until = Date.today();
        pro.sku_list ='test';
    	pro.sku_and_name_list = 'test';
        pro.do_not_delete =false;
        pro.color = 'red';
        pro.furniture_type ='hs';
        pro.sofa_type ='test';
        pro.sku_type ='hs';
        pro.family_collection = 'hs';
        pro.specialTierPriceForBundle ='hs';
        
        
        pro.cartons =5;
        pro.units_per_cartons =1;
        
        pros.add(pro);
        
        
        
		
		logProd.Data = dat;
		logProd.Data.products = pros;
		
		//Create only simple product
		IntegrationManager.response sres = IntegrationManager.createNewLog(logProd);
  		
  		
  		
		//configurable product
		IntegrationManager.product configurablePro = new IntegrationManager.product();
		configurablePro.magentoId = '123454333';
		configurablePro.sku = '123454333';
		configurablePro.name = '123454332';
		configurablePro.mpn = '123454332';
		configurablePro.upc = '123454332';
		configurablePro.tier_price_for_bundle = 22;
		configurablePro.type = 'configurable';
		configurablePro.cost = 22;
		configurablePro.price = 22;
		configurablePro.special_price = 22;
		configurablePro.special_price_start_date = system.today();
		configurablePro.special_price_end_date = system.today();
		configurablePro.special_tier_price = 22;
		configurablePro.weight = 22;
		configurablePro.status = 'status';
		configurablePro.discontinued = '123454332';
		configurablePro.visibility = '123454332';
		configurablePro.description = '123454332';
		configurablePro.carton_dimensions = '123454332';
		configurablePro.Box = '123454332';
		configurablePro.qty = 22;
		configurablePro.estimated_shipping = 22;
		configurablePro.estimated_set_shipping = 22;
		configurablePro.dimensions = '123454332';
		configurablePro.dropshipped = '123454332';
		configurablePro.ships = '123454332';
		configurablePro.fedexable = '123454332';
		configurablePro.delivery = '123454332';
		configurablePro.ashley_express = '123454332';
		configurablePro.base_image = '123454332';
		configurablePro.url_key = '123454332';
		configurablePro.tax_class = '123454332';
		configurablePro.breakeven = '123454332';
		configurablePro.categories = '123454332';
		configurablePro.manufacturer = '123454332';
		configurablePro.pricing_type = '123454332';
		configurablePro.special_tier_price_end_date = system.today();
		configurablePro.special_tier_price_start_date = system.today();
		configurablePro.websites = '123454332';
		configurablePro.regular_price = 22;
		configurablePro.set_includes = '123454332';
		list<IntegrationManager.product> proc = new list<IntegrationManager.product>();
		proc.add(configurablePro);
		IntegrationManager.associated ass = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> asses = new list<IntegrationManager.associated>();
		asses.add(ass);
		configurablePro.associated_attributes = asses;
		logProd.Data.products = proc;
		
		//Create a configurable with simple product
		logProd.LogID = '123123125';
		IntegrationManager.response cres = IntegrationManager.createNewLog(logProd);
  		
  		
		//bundle product
		IntegrationManager.product bundlePro = new IntegrationManager.product();
		bundlePro.magentoId = '123454339';
		bundlePro.sku = '123454339';
		bundlePro.name = '123454332';
		bundlePro.mpn = '123454332';
		bundlePro.upc = '123454332';
		bundlePro.tier_price_for_bundle = 22;
		bundlePro.type = 'bundle';
		bundlePro.cost = 22;
		bundlePro.price = 22;
		bundlePro.special_price = 22;
		bundlePro.special_price_start_date = system.today();
		bundlePro.special_price_end_date = system.today();
		bundlePro.special_tier_price = 22;
		bundlePro.weight = 22;
		bundlePro.status = 'status';
		bundlePro.discontinued = '123454332';
		bundlePro.visibility = '123454332';
		bundlePro.description = '123454332';
		bundlePro.carton_dimensions = '123454332';
		bundlePro.Box = '123454332';
		bundlePro.qty = 22;
		bundlePro.estimated_shipping = 22;
		bundlePro.estimated_set_shipping = 22;
		bundlePro.dimensions = '123454332';
		bundlePro.dropshipped = '123454332';
		bundlePro.ships = '123454332';
		bundlePro.fedexable = '123454332';
		bundlePro.delivery = '123454332';
		bundlePro.ashley_express = '123454332';
		bundlePro.base_image = '123454332';
		bundlePro.url_key = '123454332';
		bundlePro.tax_class = '123454332';
		bundlePro.breakeven = '123454332';
		bundlePro.categories = '123454332';
		bundlePro.manufacturer = '123454332';
		bundlePro.pricing_type = '123454332';
		bundlePro.special_tier_price_end_date = system.today();
		bundlePro.special_tier_price_start_date = system.today();
		bundlePro.websites = '123454332';
		bundlePro.regular_price = 22;
		bundlePro.set_includes = '123454332';
		pros.add(bundlePro);
		IntegrationManager.associated assb = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> assesb = new list<IntegrationManager.associated>();
		IntegrationManager.associated assc = new IntegrationManager.associated('123454333');
		assesb.add(assb);
		assesb.add(assc);
		bundlePro.associated_attributes = assesb;
		
		//Create a bundle with simple product
		logProd.LogID = '123123126';
		IntegrationManager.response bres = IntegrationManager.createNewLog(logProd);
  		
  		
		

			IntegrationManager.createUpdateConfigProd(logProd);
        	
			
        	
    	Test.stopTest();
	}
	
	@isTest
    static void usePhoneFieldTest(){
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Billing_phone__c = '34643756776857';
        acc.Shipping_phone__c = '34643756776857';
        acc.phone = '34643756776857';
        acc.Phone_Internal__c = '34643756776857';
        acc.Billing_cell__c = '34643756776857';
        acc.Mobile__c = '34643756776857';
        acc.Shipping_cell__c = '34643756776857';
        insert acc;
        
        List<Id> fixedSearchResults = new List<Id>{acc.Id};
        
        Test.setFixedSearchResults(fixedSearchResults);

        IntegrationManager.Log logAcc = new IntegrationManager.Log();
		logAcc.LogID = '123123123';
		logAcc.Process = 'Account created';
		IntegrationManager.Data dat = new IntegrationManager.Data();
		dat.billing_cell = '89687567';
		dat.billing_city = 'Los Angeles';
		dat.billing_country_id = 'US';
		dat.billing_phone = '34643756776857';
		dat.billing_postcode = '233452';
		dat.billing_region = 'Arkansas';
		dat.billing_street = '2 downing street';
		dat.customergroup = '1';
		dat.email = 'test@testtt.com';
		dat.firstname = 'Mentch';
		dat.lastname = 'Kurant';
		dat.magentoId = '65183';
		dat.magento_sales_rep_id = '0';
		dat.shipping_city = 'San Jose';
		dat.shipping_country_id = 'US';
		dat.shipping_phone = '89687567';
		dat.shipping_postcode = '95131';
		dat.shipping_region = 'Arizona';
		dat.shipping_street = '4 main st';
		dat.website_id = '1';
		logAcc.Data = dat;
        test.startTest();
		IntegrationManager.response accountres = IntegrationManager.createNewLog(logAcc);
  		system.assertequals(accountres.status, 'Succeeded');
	}

	static testMethod void createNewLogOrderFail() {
		//create account 
		IntegrationManager.Log logAcc = new IntegrationManager.Log();
		logAcc.LogID = '123123123';
		logAcc.Process = 'Account created';
		IntegrationManager.Data dat = new IntegrationManager.Data();
		dat.billing_cell = '89687567';
		dat.billing_city = 'Los Angeles';
		dat.billing_country_id = 'US';
		dat.billing_phone = '34643756776857';
		dat.billing_postcode = '233452';
		dat.billing_region = 'Arkansas';
		dat.billing_street = '2 downing street';
		dat.customergroup = '1';
		dat.email = 'test@testtt.com';
		dat.firstname = 'Mentch';
		dat.lastname = 'Kurant';
		dat.magentoId = '65183';
		dat.magento_sales_rep_id = '0';
		dat.shipping_city = 'San Jose';
		dat.shipping_country_id = 'US';
		dat.shipping_phone = '89687567';
		dat.shipping_postcode = '95131';
		dat.shipping_region = 'Arizona';
		dat.shipping_street = '4 main st';
		dat.website_id = '1';
        dat.shipping_cell = 'test';
        dat.middlename = 'test';
        dat.sales_rep_name = 'test';
        //dat.created_date = 'test';
        dat.company_name = 'test';
        dat.name = 'test';
        //dat.customerId {get; set;}
        
		logAcc.Data = dat;
        test.startTest();
		IntegrationManager.response accountres = IntegrationManager.createNewLog(logAcc);
  		system.assertequals(accountres.status, 'Succeeded');
  		
  		
  		
  		Google_API__c googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
  		
		IntegrationManager.Log logProd = new IntegrationManager.Log();
		logProd.LogID = '123123124';
		logProd.Process = 'Product created_updated';
		dat = new IntegrationManager.Data();
		IntegrationManager.product pro = new IntegrationManager.product();
		list<IntegrationManager.product> pros = new list<IntegrationManager.product>();
		
		//simple product
		pro.magentoId = '123454332';
		pro.sku = '123454332';
		pro.name = '123454332';
		pro.mpn = '123454332';
		pro.upc = '123454332';
		pro.tier_price_for_bundle = 22;
		pro.type = 'simple';
		pro.cost = 22;
		pro.price = 22;
		pro.special_price = 22;
		pro.special_price_start_date = system.today();
		pro.special_price_end_date = system.today();
		pro.special_tier_price = 22;
		pro.weight = 22;
		pro.status = 'status';
		pro.discontinued = '123454332';
		pro.visibility = '123454332';
		pro.description = '123454332';
		pro.carton_dimensions = '123454332';
		pro.Box = '123454332';
		pro.qty = 22;
		pro.estimated_shipping = 22;
		pro.estimated_set_shipping = 22;
		pro.dimensions = '123454332';
		pro.dropshipped = '123454332';
		pro.ships = '123454332';
		pro.fedexable = '123454332';
		pro.delivery = '123454332';
		pro.ashley_express = '123454332';
		pro.base_image = '123454332';
		pro.url_key = '123454332';
		pro.tax_class = '123454332';
		pro.breakeven = '123454332';
		pro.categories = '123454332';
		pro.manufacturer = '123454332';
		pro.pricing_type = '123454332';
		pro.special_tier_price_end_date = system.today();
		pro.special_tier_price_start_date = system.today();
		pro.websites = '123454332';
		pro.regular_price = 22;
		pro.set_includes = '123454332';
		pros.add(pro);
		
		logProd.Data = dat;
		logProd.Data.products = pros;
		
		//Create only simple product
		IntegrationManager.response sres = IntegrationManager.createNewLog(logProd);
  		
  		
  		
		//configurable product
		IntegrationManager.product configurablePro = new IntegrationManager.product();
		configurablePro.magentoId = '123454333';
		configurablePro.sku = '123454333';
		configurablePro.name = '123454332';
		configurablePro.mpn = '123454332';
		configurablePro.upc = '123454332';
		configurablePro.tier_price_for_bundle = 22;
		configurablePro.type = 'configurable';
		configurablePro.cost = 22;
		configurablePro.price = 22;
		configurablePro.special_price = 22;
		configurablePro.special_price_start_date = system.today();
		configurablePro.special_price_end_date = system.today();
		configurablePro.special_tier_price = 22;
		configurablePro.weight = 22;
		configurablePro.status = 'status';
		configurablePro.discontinued = '123454332';
		configurablePro.visibility = '123454332';
		configurablePro.description = '123454332';
		configurablePro.carton_dimensions = '123454332';
		configurablePro.Box = '123454332';
		configurablePro.qty = 22;
		configurablePro.estimated_shipping = 22;
		configurablePro.estimated_set_shipping = 22;
		configurablePro.dimensions = '123454332';
		configurablePro.dropshipped = '123454332';
		configurablePro.ships = '123454332';
		configurablePro.fedexable = '123454332';
		configurablePro.delivery = '123454332';
		configurablePro.ashley_express = '123454332';
		configurablePro.base_image = '123454332';
		configurablePro.url_key = '123454332';
		configurablePro.tax_class = '123454332';
		configurablePro.breakeven = '123454332';
		configurablePro.categories = '123454332';
		configurablePro.manufacturer = '123454332';
		configurablePro.pricing_type = '123454332';
		configurablePro.special_tier_price_end_date = system.today();
		configurablePro.special_tier_price_start_date = system.today();
		configurablePro.websites = '123454332';
		configurablePro.regular_price = 22;
		configurablePro.set_includes = '123454332';
		list<IntegrationManager.product> proc = new list<IntegrationManager.product>();
		proc.add(configurablePro);
		IntegrationManager.associated ass = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> asses = new list<IntegrationManager.associated>();
		asses.add(ass);
		configurablePro.associated_attributes = asses;
		logProd.Data.products = proc;
		
		//Create a configurable with simple product
		logProd.LogID = '123123125';
		IntegrationManager.response cres = IntegrationManager.createNewLog(logProd);
  		
  		
		//bundle product
		IntegrationManager.product bundlePro = new IntegrationManager.product();
		bundlePro.magentoId = '123454339';
		bundlePro.sku = '123454339';
		bundlePro.name = '123454332';
		bundlePro.mpn = '123454332';
		bundlePro.upc = '123454332';
		bundlePro.tier_price_for_bundle = 22;
		bundlePro.type = 'bundle';
		bundlePro.cost = 22;
		bundlePro.price = 22;
		bundlePro.special_price = 22;
		bundlePro.special_price_start_date = system.today();
		bundlePro.special_price_end_date = system.today();
		bundlePro.special_tier_price = 22;
		bundlePro.weight = 22;
		bundlePro.status = 'status';
		bundlePro.discontinued = '123454332';
		bundlePro.visibility = '123454332';
		bundlePro.description = '123454332';
		bundlePro.carton_dimensions = '123454332';
		bundlePro.Box = '123454332';
		bundlePro.qty = 22;
		bundlePro.estimated_shipping = 22;
		bundlePro.estimated_set_shipping = 22;
		bundlePro.dimensions = '123454332';
		bundlePro.dropshipped = '123454332';
		bundlePro.ships = '123454332';
		bundlePro.fedexable = '123454332';
		bundlePro.delivery = '123454332';
		bundlePro.ashley_express = '123454332';
		bundlePro.base_image = '123454332';
		bundlePro.url_key = '123454332';
		bundlePro.tax_class = '123454332';
		bundlePro.breakeven = '123454332';
		bundlePro.categories = '123454332';
		bundlePro.manufacturer = '123454332';
		bundlePro.pricing_type = '123454332';
		bundlePro.special_tier_price_end_date = system.today();
		bundlePro.special_tier_price_start_date = system.today();
		bundlePro.websites = '123454332';
		bundlePro.regular_price = 22;
		bundlePro.set_includes = '123454332';
		pros.add(bundlePro);
		IntegrationManager.associated assb = new IntegrationManager.associated('123454332');
		list<IntegrationManager.associated> assesb = new list<IntegrationManager.associated>();
		IntegrationManager.associated assc = new IntegrationManager.associated('123454333');
		assesb.add(assb);
		assesb.add(assc);
		bundlePro.associated_attributes = assesb;
		
		//Create a bundle with simple product
		logProd.LogID = '123123126';
		IntegrationManager.response bres = IntegrationManager.createNewLog(logProd);
  		
  		
		
		IntegrationManager.Log log = new IntegrationManager.Log();
		log.LogID = '123777';
		log.Process = 'Order created';
		IntegrationManager.Data datOrd = new IntegrationManager.Data();
		IntegrationManager.Order ord = new IntegrationManager.Order();
        datOrd.order = ord;
		log.Data = datOrd;
		ord.customerId = accountres.responseData[0].salesforceId;
		ord.magentoId = '1123';
		system.debug('ord = ' + ord);
		ord.billing_city = 'miami beach';
		ord.billing_name = 'mend';
		ord.billing_fax = '3546665454';
		ord.billing_telephone = '3456657676';
		ord.billing_region = 'fl';
		ord.billing_postcode = '33139';
		ord.billing_street = 'main';
		ord.customer_group = '1';
		ord.customer_comments = 'hjhj';
		ord.email = 'mmm@greenclou.com';
		ord.is_email_sent = true;
		ord.remote_ip = '000';
		ord.cc_digits = 1234;
		ord.cc_type = 'Visa';
		ord.avs_response = 'avs';
		ord.created_at = '2017-08-29 17:47:13';
		ord.status = 'pending';
		ord.store_name = 'Main Website\nMain Website Store\nColeman Furniture';
		ord.sales_rep_name = 'rep';
		ord.shipping_cell = '1800544400';
		ord.shipping_city = 'Tel avif';
		ord.shipping_fax = '9987768787';
		ord.shipping_name = 'Mendush';
		ord.shipping_telephone = '7188865656';
		ord.shipping_region = 'FL';
		ord.shipping_street = 'Main';
		ord.shipping_postcode = '12345';
		ord.transaction_id = '123';
		ord.payment_method = 'Credit Card (Authorize.net)';
		ord.increment_id = '1123';
		ord.shipping_amount = 20;
		ord.discount_amount = 20;
		ord.coupon_code = 'jhj';
		ord.subtotal = 200;
		ord.shipping_company ='js';
        ord.billing_company ='hs';
    	/*ord.created_date ='03-01-2019';
        ord.shipping_tax = 5;
        */ord.Paypal_Email_Attribute ='asdfa@gmail.com';
        ord.device_type ='hs'; 
        
        
		IntegrationManager.order_item ois = new IntegrationManager.order_item();
		ois.productId = googleAPI.Id;
        ois.product_name = 'Test';
		ois.discount_amount = 1;
		ois.original_price = 200;
		ois.price = 100;
		ois.Product_sku = 'AA';
		ois.qty_ordered = 1;
		ois.tax_amount = 5;
		ois.commission_amount = 7;
        
		//public list<related_item> related_products {get; set;}
		list<IntegrationManager.order_item> order_items = new list<IntegrationManager.order_item>();
		order_items.add(ois);
		ord.order_items = order_items;
		IntegrationManager.response res = IntegrationManager.createNewLog(log);
		
		
		
		IntegrationManager.order_item oib = new IntegrationManager.order_item();
		oib.productId = googleAPI.Id;

        ois.product_name = 'Test';
		oib.discount_amount = 1;
		oib.original_price = 200;
		oib.price = 100;
		oib.Product_sku = 'AA';
		oib.qty_ordered = 1;
		oib.tax_amount = 5;
		oib.commission_amount = 7;
        oib.cost = 20;
        oib.base_image = 'Image';
        
      
		IntegrationManager.related_item ri = new IntegrationManager.related_item();
		ri.productId = sres.responseData[0].salesforceId;
        ri.quantity = '2';
        ri.product_name = 'Test2';
        ri.price = 5;
        ri.product_sku ='test';
		list<IntegrationManager.related_item> related_products = new list<IntegrationManager.related_item>();
		related_products.add(ri);
		oib.related_products = related_products;
		order_items.add(oib);
		
		log.LogID = '123778';
		res = IntegrationManager.createNewLog(log);
		
		ri.configurable_product = cres.responseData[0].salesforceId;
		
		log.LogID = '123779';
		res = IntegrationManager.createNewLog(log);
		
		ois.configurable_product = cres.responseData[0].salesforceId;
		log.LogID = '123780';
		res = IntegrationManager.createNewLog(log);
		
		//OrderManager.createNewLog(res.responseData[0].salesforceId);
		log.LogID = '12377788';
		log.Process = 'oldOrder';
		ord.magentoId = '112345';
		res = IntegrationManager.createNewLog(log);
        Test.stopTest();
	}
}