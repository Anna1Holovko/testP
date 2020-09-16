public  class POD_PDFController {
	public Sales_Order__c salesOrder{ get; set; }
    public String logoId{ get; set; }
    public String orgId{ get; set; }
    
	public List<Shipment_Line_Item__c> shipmentItemList { get; set; }
	public POD_PDFController() {
        List<document> docList = [select id, Url, IsPublic from document where DeveloperName = 'PODpdfLogo'];
        if(docList.size() > 0){
            logoId = docList.get(0).Id;
        }
        orgId = UserInfo.getOrganizationId();
		Id salesOrderId = ApexPages.currentPage().getParameters().get('id');
		Boolean isOnlyWG = ApexPages.currentPage().getParameters().containsKey('isOnlyWG') ? Boolean.valueOf(ApexPages.currentPage().getParameters().get('isOnlyWG')) : false;

		String salesOrderQuery =   	'SELECT Id, ' +
									'Name, ' +
									'Ship_to__c, ' +
									'Shipping_Street__c , ' +
									'Shipping_City__c, ' +
									'Shipping_State__c, ' +
									'Shipping_ZipCode__c, ' +
									'Shipping_Phone__c, ' + 
									'Magento_order_No__c, ' + 
									'Customer_Name__c, ' + 
									'Customer_Name__r.Name, ' + 
									'Customer_shipping_Address__r.City__c , ' +
									'Customer_shipping_Address__r.Street_Address__c  , ' +
									'Customer_shipping_Address__r.Zip_Postal_Code__c  , ' +
									'Customer_shipping_Address__r.State__c , ' +
									'Customer_shipping_Address__r.Telephone__c , ' +
										'(SELECT Id, Delivery_Company__r.Name, ' + 
										'Delivery_Company__r.ShippingStreet, ' + 
										'Delivery_Company__r.ShippingCity, ' +
										'Delivery_Company__r.ShippingState, ' + 
										'Delivery_Company__r.ShippingCountry, ' + 
										'Delivery_Company__r.Phone, ' +
										'Delivery_Company__r.ShippingPostalcode  FROM Shipments__r where Carrier__c  ' + (isOnlyWG ? ' = null ': ' != \'LTL\' ' ) + ' LIMIT 1) ' + 
									'FROM Sales_Order__c WHERE Id =:salesOrderId';
		salesOrder = Database.query(salesOrderQuery);

		Set<String> statuses = PODShipmentLineItemExcludedStatuses__c.getAll().keySet();
		String shipmentLinesQuery = 	'SELECT  Id, ' +
												'Name, ' + 
												'Product_Name__c, ' + 
												'Product_SKU__c, ' + 
												'Quantity__c, ' + 
												'Shipment_Item_Status__c, ' + 
												'Damage_Action__c, ' +
												'Repair_Amount__c, ' + 
												'Shipment_Product_Weight__c, ' + 
												'Shipment_Product_Name__c, ' + 
												'Shipped_Quantity_Actual__c, ' + 
												'Weight_Pounds__c, ' + 
												'Shipment_Product_SKU__c, ' +
												'Box_Info__c, ' + 
												'Cubed_Ft__c, ' + 
												'Shipment_Product_Quantity__c ' + 
										'FROM Shipment_Line_Item__c ' + 
										'WHERE Shipment_Item_Status__c NOT IN :statuses AND Shipment__r.Related_Sales_Order__c =: salesOrderId and Shipment__r.Carrier__c   ' + (isOnlyWG ? ' = null ': ' != \'LTL\' ' ) + ' AND  PO_Line_Item__r.SO_Line_Item__r.Products__r.Non_Furniture_Product__c = false';

		shipmentItemList = Database.query(shipmentLinesQuery);
        /*salesOrder = [SELECT Id,
                      		Name, 
                      		Ship_to__c,
                      		Shipping_Street__c ,
                      		Shipping_City__c,
                      		Shipping_State__c,
                      		Shipping_ZipCode__c,
                      		Shipping_Phone__c, 
                      		Magento_order_No__c , 
                      		Customer_Name__c, 
                      		Customer_Name__r.Name, 
                      		Customer_shipping_Address__r.City__c ,
                      		Customer_shipping_Address__r.Street_Address__c  ,
                      		Customer_shipping_Address__r.Zip_Postal_Code__c  ,
                      		Customer_shipping_Address__r.State__c ,
                      		Customer_shipping_Address__r.Telephone__c ,
                      		(SELECT Id, Delivery_Company__r.Name, 
							Delivery_Company__r.ShippingStreet, 
							Delivery_Company__r.ShippingCity,
							Delivery_Company__r.ShippingState, 
							Delivery_Company__r.ShippingCountry, 
							Delivery_Company__r.Phone,
							Delivery_Company__r.ShippingPostalcode  FROM Shipments__r where Carrier__c != 'LTL' LIMIT 1) FROM Sales_Order__c WHERE Id =:salesOrderId];
        /*salesOrder = [SELECT Id, 
							Name, 
							Delivery_Company__c, 
							Delivery_Date_Actual__c,
							Trucking_Company_name__c, 
							Customer_Name__c, Carrier__c,	
							Magento_order_No__c, 
							recordtype.name, 
							Delivery_Company_Name__c, 
							Purchase_Order__r.name,
                    		Purchase_Order__r.Shipping_Address_Customer__c, 
							Purchase_Order__r.Ship_From__r.name, 
							Purchase_Order__r.Ship_From__r.ShippingStreet,
							Purchase_Order__r.Ship_From__r.ShippingCity, 
							Purchase_Order__r.Ship_From__r.ShippingState,
							Purchase_Order__r.Ship_From__r.ShippingCountry, 
							Purchase_Order__r.Ship_From__r.ShippingPostalcode,
							Purchase_Order__r.Ship_From__r.Phone,
							Total_Cubed_Ft__c, 
							Related_Sales_Order__r.Magento_order_No__c,
							Related_Sales_Order__r.Ship_to__c, 
							Related_Sales_Order__r.Shipping_Street__c,
							Related_Sales_Order__r.Shipping_City__c, 
							Related_Sales_Order__r.Shipping_State__c,
							Related_Sales_Order__r.Shipping_ZipCode__c, 
							Related_Sales_Order__r.Shipping_Phone__c,
							Delivery_Company__r.Name, 
							Delivery_Company__r.ShippingStreet, 
							Delivery_Company__r.ShippingCity,
							Delivery_Company__r.ShippingState, 
							Delivery_Company__r.ShippingCountry, 
							Delivery_Company__r.Phone,
							Delivery_Company__r.ShippingPostalcode 
					FROM Shipment__c 
					WHERE Id = :shipmentID]; 

		shipmentItemList = [SELECT 	Id, 
									Name, Product_Name__c, 
									Product_SKU__c, 
									Quantity__c, 
									Shipment_Item_Status__c, 
									Damage_Action__c,
									Repair_Amount__c, 
									Shipment_Product_Weight__c, 
									Shipment_Product_Name__c, 
									Shipped_Quantity_Actual__c, 
									Weight_Pounds__c, 
									Shipment_Product_SKU__c,
									Box_Info__c, 
									Cubed_Ft__c, 
									Shipment_Product_Quantity__c 
							FROM Shipment_Line_Item__c 
							WHERE Shipment__r.Related_Sales_Order__c =: salesOrderId and Shipment__r.Carrier__c != 'LTL' and  PO_Line_Item__r.SO_Line_Item__r.Products__r.Non_Furniture_Product__c = false];*/						
		String fileName = 'POD_' + salesOrder.name + '.pdf';
		Apexpages.currentPage().getHeaders().put('content-disposition', 'filename=' + fileName);
	}
}