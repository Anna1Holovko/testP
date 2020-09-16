/**
 * @File Name          : PurchaseOrderOutboundFrom.cls
 * @Description        : 
 * @Author             : Synebo
 * @Group              : 
 * @Last Modified By   : Synebo
 * @Last Modified On   : 4/20/2020, 12:58:37 PM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/14/2020   Synebo     Initial Version
**/
public with sharing class PurchaseOrderOutboundFrom {
	
	public static Order ord {get; set;}
	public static Purchase_Order__c po {get; set;}
	public static list<LineItem> lis {get; set;}
	public static EDI_Map__mdt ediMap {get; set;}
	public static boolean isAshley {get; set;}
	public static boolean isLiberty {get; set;}
	public static boolean isParkerHouse {get; set;}
	
	@future (callout=true)
    public static void sendForm(string objId){
        sendFormGeneral(objId);
    }
    
    public static void sendFormNotfuture(string objId){
        sendFormGeneral(objId);
    }
    
    public static void sendFormGeneral(string objId){
		list<Log__c> logs = [select id, Tries__c from Log__c where Object_ID__c = :objId];
		LogTriggerHandler.wasCangeManually = false;
		Heroku_setting__c setting = Heroku_setting__c.getinstance();
		string xmlString;
		
		String poShipFrom;
		String responseFromServer = '';
		try {
			xmlString = GenerateForm(objId);
			if(po != null && po.Ship_From__c!= null){
				poShipFrom = po.Ship_From__r.Name;
			}
			xmlString = xmlString.split('>', 2)[1];
			system.debug ('xmlString = ' + xmlString);
			string body = generateBody(xmlString, objId);
			system.debug ('body = ' + body);
			
			HttpRequest httpReq = new HttpRequest();
            Blob headerValue = Blob.valueOf(setting.Username__c+':'+setting.Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            system.debug('***:' + EncodingUtil.base64Encode(headerValue));
            httpReq.setHeader('Authorization', authorizationHeader);
	        httpReq.setHeader('Content-Type', 'application/json');
	        httpReq.setEndpoint(ediMap.End_point__c);
	        httpReq.setBody(body);
	        httpReq.settimeout(80000);
	        httpReq.setMethod('POST');
	        Http h = new Http();
            HttpResponse res = Test.isRunningTest() ? null : h.send(httpReq);
			system.debug('result = ' + res.getBody());
			responseFromServer = res.getBody();
    		Response response = ((list<Response>)JSON.deserialize('[' + res.getBody() + ']', list<Response>.class))[0];
			System.debug('reponse: '+ JSON.serializePretty(response));
			Log__c log = new Log__c(Process__c = 'EDI - PO created', Data__c = xmlString, Object_ID__c = objId, Tries__c = 1, Status__c = 'Sent', Response__c = res.getBody(), Error__c = '',  Sent_to__c = poShipFrom);
			if (logs.size() > 0){
				log.id = logs[0].id;
				log.Tries__c = logs[0].Tries__c + 1;
			}
			if (!response.success && response.message != 'File already exist'){
				log.Status__c = 'Failed';
				log.Error__c = response.message;
			}
			else if (response.success){
				Purchase_Order__c po = new Purchase_Order__c();
				po.id = objId;
				po.PO_sent_to_Manufacturer__c = system.now();
				po.EDI_Status__c = 'Sent';
				update po;
			}
			upsert log;
		}
		catch (exception e){
			system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getlinenumber());
			Log__c log = new Log__c(Process__c = 'EDI - PO created', Data__c = xmlString, Error__c = e.getmessage() + ' ' + e.getlinenumber(), Object_ID__c = objId, Tries__c = 1, Status__c = 'Failed', Sent_to__c = poShipFrom);
			log.Response__c = responseFromServer;
			if (logs.size() > 0){
				log.id = logs[0].id;
				log.Tries__c = logs[0].Tries__c + 1;
			}
			system.debug('log = ' + log);
			upsert log;
		}
	}
	
	public static string generateBody(string xmlString, string objId){
		Request req = new Request();
		req.username = ediMap.Username__c;
		req.password = ediMap.Password__c;
		req.secured = ediMap.Secured__c;
		req.url = ediMap.URL__c;
		req.port = ediMap.Port__c;
		req.contentRaw = EncodingUtil.base64Encode(Blob.valueof(xmlString));
		req.fileName = ediMap.X850_file_name__c + '-' + objId + '.xml';
		req.path = ediMap.X850_path__c;
		return json.serialize(req);
	}
	
	public static string GenerateForm(string objId){
		generateOrderAndLineItems(objId);
		Dom.Document doc = new Dom.Document();
		doc.createRootElement('furnPO:order', '', '');
		Dom.XmlNode node = doc.getRootElement();
		if (!isLiberty && !isParkerHouse){
			node.setAttribute('xsi:schemaLocation', 'http://support.furnishnet.com/xml/schemas/FurnPO_v1.8 http://xml.ashleyfurniture.com/xml/schemas/FurnXMLPO_v1.8.xsd');
			node.setAttribute('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance');
		}
		node.setAttribute('xmlns:fnParty', 'http://support.furnishnet.com/xml/schemas/fnParty_v1.4');
		node.setAttribute('xmlns:fnItem', 'http://support.furnishnet.com/xml/schemas/fnItem_v1.4');
		node.setAttribute('xmlns:fnBase', 'http://support.furnishnet.com/xml/schemas/fnBase_v1.4');
		node.setAttribute('xmlns:furnPO', 'http://support.furnishnet.com/xml/schemas/FurnPO_v1.8');
		
			Dom.XmlNode orderNode = node.addChildElement('Order', '', '');
			orderNode.setAttribute('comment', ord.comment);
				Dom.XmlNode documentNode = orderNode.addChildElement('document', '', '');
				documentNode.setAttribute('id', ord.document_id);
				documentNode.setAttribute('type', ord.document_type);
				documentNode.setAttribute('language', ord.document_language);
					Dom.XmlNode creationDateNode = documentNode.addChildElement('creationDate', '', '');
					creationDateNode.addTextNode(ord.creationDate);
				Dom.XmlNode actionRequestIndicatorNode = orderNode.addChildElement('actionRequestIndicator', '', '');
				actionRequestIndicatorNode.setAttribute('description', ord.description);
				Dom.XmlNode currencyNode = orderNode.addChildElement('currency', '', '');
				currencyNode.addTextNode(ord.currenc);
				Dom.XmlNode buyerNode = orderNode.addChildElement('buyer', '', '');
					Dom.XmlNode partyIdentifierrNode = buyerNode.addChildElement('fnParty:partyIdentifier', '', '');
					partyIdentifierrNode.setAttribute('partyIdentifierCode', ord.buyerPartyIdentifierCode);
					partyIdentifierrNode.setAttribute('partyIdentifierQualifierCode', ord.buyerPartyIdentifierrQualifierCode);
				Dom.XmlNode sellerNode = orderNode.addChildElement('seller', '', '');
					Dom.XmlNode sellerIdentificationNode = sellerNode.addChildElement('sellerIdentification', '', '');
						Dom.XmlNode sellerPartyIdentifierrNode = sellerIdentificationNode.addChildElement('fnParty:partyIdentifier', '', '');
							sellerPartyIdentifierrNode.setAttribute('partyIdentifierCode', ord.sellerPartyIdentifierCode);
							sellerPartyIdentifierrNode.setAttribute('partyIdentifierQualifierCode', ord.sellerPartyIdentifierrQualifierCode);
				if (!isAshley){
					Dom.XmlNode suggestedTruckingCompanyNode = orderNode.addChildElement('suggestedTruckingCompany', '', '');
					if (ord.suggestedTruckingCompany != null){
						suggestedTruckingCompanyNode.addTextNode(ord.suggestedTruckingCompany);
					}
				}
						
				Dom.XmlNode shipToNode = orderNode.addChildElement('shipTo', '', '');
				if (isAshley || isLiberty || isParkerHouse){
					shipToNode.setAttribute('id', ord.shipToId);
						Dom.XmlNode shipTpIdentificationNode1 = shipToNode.addChildElement('fnParty:partyIdentifier', '', '');
						shipTpIdentificationNode1.setAttribute('partyIdentifierCode', ord.shipToPartyIdentifierCode);
						shipTpIdentificationNode1.setAttribute('partyIdentifierQualifierCode', ord.shipToPartyIdentifierrQualifierCode);
						Dom.XmlNode shipTpIdentificationNode2 = shipToNode.addChildElement('fnParty:partyIdentifier', '', '');
						shipTpIdentificationNode2.setAttribute('partyIdentifierCode', ord.shipToPartyIdentifierCode2);
						shipTpIdentificationNode2.setAttribute('partyIdentifierQualifierCode', ord.shipToPartyIdentifierrQualifierCode2);
				}
				else if (ord.suggestedDeliveryCompany != null){
					shipToNode.setAttribute('name', ord.suggestedDeliveryCompany);
					Dom.XmlNode shipToStreetNode1 = shipToNode.addChildElement('fnParty:street', '', '');
					shipToStreetNode1.addTextNode(ord.suggestedDeliveryCompanyStreet);
					Dom.XmlNode shipToCityNode1 = shipToNode.addChildElement('fnParty:city', '', '');
					shipToCityNode1.addTextNode(ord.suggestedDeliveryCompanyCity);
					Dom.XmlNode shipToStateOrProvinceNode1 = shipToNode.addChildElement('fnParty:stateOrProvince', '', '');
					shipToStateOrProvinceNode1.addTextNode(Utilities.getStateinitial(ord.suggestedDeliveryCompanyState));
					Dom.XmlNode shipToPostalCodeNode1 = shipToNode.addChildElement('fnParty:postalCode', '', '');
					shipToPostalCodeNode1.addTextNode(ord.suggestedDeliveryCompanyPostalCode);
				}
				Dom.XmlNode markForNode = orderNode.addChildElement('markFor', '', '');
				markForNode.setAttribute('id', ord.markForId);
				markForNode.setAttribute('shippingInstructions', ord.markForShippingInstructions);
					Dom.XmlNode markForPartyIdentifierNode = markForNode.addChildElement('fnParty:partyIdentifier', '', '');
					markForPartyIdentifierNode.setAttribute('partyIdentifierCode', ord.markForPartyIdentifierCode);
					markForPartyIdentifierNode.setAttribute('partyIdentifierQualifierCode', ord.markForPartyIdentifierrQualifierCode);
					Dom.XmlNode partyNameNode = markForNode.addChildElement('fnParty:partyName', '', '');
					partyNameNode.addTextNode(ord.partyName);
					Dom.XmlNode addressLineNode = markForNode.addChildElement('fnParty:addressLine', '', '');
					addressLineNode.addTextNode(ord.addressLine);
					Dom.XmlNode cityNode = markForNode.addChildElement('fnParty:city', '', '');
					cityNode.addTextNode(ord.city);
					Dom.XmlNode stateOrProvinceNode = markForNode.addChildElement('fnParty:stateOrProvince', '', '');
					stateOrProvinceNode.addTextNode(Utilities.getStateinitial(ord.stateOrProvince));
					Dom.XmlNode countryNode = markForNode.addChildElement('fnParty:country', '', '');
					if (ord.country == 'USA'){
						countryNode.addTextNode(ord.country);
					}
					
					Dom.XmlNode postalCodeNode = markForNode.addChildElement('fnParty:postalCode', '', '');
					postalCodeNode.addTextNode(ord.postalCode);
					Dom.XmlNode partyContactNode = markForNode.addChildElement('partyContact', '', '');
						Dom.XmlNode electronicContactNode = partyContactNode.addChildElement('electronicContact', '', '');
						electronicContactNode.setAttribute('electronicContactQualifier', ord.electronicContactQualifier);
						electronicContactNode.setAttribute('electronicContactValue', ord.electronicContactValue);
						Dom.XmlNode telephoneContactNode = partyContactNode.addChildElement('telephoneContact', '', '');
						telephoneContactNode.setAttribute('telephoneNumberType', ord.telephoneNumberType);
							Dom.XmlNode telephoneNumberNode = telephoneContactNode.addChildElement('telephoneNumber', '', '');
							telephoneNumberNode.addTextNode(ord.telephoneNumber);
				Dom.XmlNode shipDatesNode = orderNode.addChildElement('shipDates', '', '');
					Dom.XmlNode requestedArrivalDateNode = shipDatesNode.addChildElement('requestedArrivalDate', '', '');
					requestedArrivalDateNode.addTextNode(ord.requestedArrivalDate);
					//Dom.XmlNode otherDateNode = shipDatesNode.addChildElement('otherDate', '', '');
					//otherDateNode.setAttribute('otherDateQualifier', ord.otherDateQualifier);
					//otherDateNode.addTextNode(ord.otherDate);
				
				//systemReference here
				/*Dom.XmlNode systemReferenceNode = orderNode.addChildElement('systemReference', '', '');
					Dom.XmlNode systemReferenceDescriptionNode = systemReferenceNode.addChildElement('systemReferenceDescription', '', '');
					systemReferenceDescriptionNode.addTextNode(ord.systemReferenceValue1);
					Dom.XmlNode systemReferenceValue = systemReferenceNode.addChildElement('systemReferenceValue', '', '');*/
					/*systemReferenceValue.addTextNode(ord.systemReferenceValue1);*/
				Dom.XmlNode systemReferenceNode2 = orderNode.addChildElement('systemReference', '', '');
					Dom.XmlNode systemReferenceDescriptionNode2 = systemReferenceNode2.addChildElement('systemReferenceDescription', '', '');
					systemReferenceDescriptionNode2.addTextNode(ord.systemReferenceDescription2);
					Dom.XmlNode systemReferenceValue2 = systemReferenceNode2.addChildElement('systemReferenceValue', '', '');
					systemReferenceValue2.addTextNode(ord.systemReferenceValue2);
				Dom.XmlNode systemReferenceNode3 = orderNode.addChildElement('systemReference', '', '');
					Dom.XmlNode systemReferenceDescriptionNode3 = systemReferenceNode3.addChildElement('systemReferenceDescription', '', '');
					systemReferenceDescriptionNode3.addTextNode(ord.systemReferenceDescription3);
					Dom.XmlNode systemReferenceValue3 = systemReferenceNode3.addChildElement('systemReferenceValue', '', '');
					systemReferenceValue3.addTextNode(ord.systemReferenceValue3);
				/*Dom.XmlNode systemReferenceNode4 = orderNode.addChildElement('systemReference', '', '');
					Dom.XmlNode systemReferenceDescriptionNode4 = systemReferenceNode4.addChildElement('systemReferenceDescription', '', '');
					systemReferenceDescriptionNode4.addTextNode(ord.systemReferenceDescription4);
					Dom.XmlNode systemReferenceValue4 = systemReferenceNode4.addChildElement('systemReferenceValue', '', '');
					systemReferenceValue4.addTextNode(ord.systemReferenceValue4);*/
				Dom.XmlNode systemReferenceNode5 = orderNode.addChildElement('systemReference', '', '');
					Dom.XmlNode systemReferenceDescriptionNode5 = systemReferenceNode5.addChildElement('systemReferenceDescription', '', '');
					systemReferenceDescriptionNode5.addTextNode(ord.systemReferenceDescription5);
					Dom.XmlNode systemReferenceValue5 = systemReferenceNode5.addChildElement('systemReferenceValue', '', '');
					systemReferenceValue5.addTextNode(ord.systemReferenceValue5);
				Dom.XmlNode systemReferenceNode6 = orderNode.addChildElement('systemReference', '', '');
					Dom.XmlNode systemReferenceDescriptionNode6 = systemReferenceNode6.addChildElement('systemReferenceDescription', '', '');
					systemReferenceDescriptionNode6.addTextNode(ord.systemReferenceDescription6);
					Dom.XmlNode systemReferenceValue6 = systemReferenceNode6.addChildElement('systemReferenceValue', '', '');
					systemReferenceValue6.addTextNode(ord.systemReferenceValue6);
				Dom.XmlNode shipComplete = orderNode.addChildElement('shipComplete', '', '');
					shipComplete.addTextNode('ShipOnlyCompleteOrder');
		integer indexMaster = 0;
		set<string> usedIds = new set<string>();
		for (LineItem li : lis){
			Dom.XmlNode LineNode = node.addChildElement('Line', '', '');
			LineNode.setAttribute('lineItemNumber', li.lineItemNumber);
			LineNode.setAttribute('comment', li.comment);
				Dom.XmlNode productIDNode = LineNode.addChildElement('productID', '', '');
					Dom.XmlNode productIDItemIdentifierNode1 = productIDNode.addChildElement('itemIdentifier', '', '');
					productIDItemIdentifierNode1.setAttribute('itemNumber', li.itemNumber);
					productIDItemIdentifierNode1.setAttribute('itemNumberQualifier', li.itemNumberQualifier);
					Dom.XmlNode productIDItemIdentifierNode2 = productIDNode.addChildElement('itemIdentifier', '', '');
					productIDItemIdentifierNode2.setAttribute('itemNumber', li.itemNumber2);
					productIDItemIdentifierNode2.setAttribute('itemNumberQualifier', li.itemNumberQualifier2);
					Dom.XmlNode itemDescriptionNode = productIDNode.addChildElement('itemDescription', '', '');
					itemDescriptionNode.setAttribute('descriptionValue', li.descriptionValue);
					itemDescriptionNode.setAttribute('itemDescriptionQualifier', li.itemDescriptionQualifier);
				Dom.XmlNode requestedQuantityNode = LineNode.addChildElement('requestedQuantity', '', '');
				requestedQuantityNode.setAttribute('unitOfMeasure', li.unitOfMeasure);
				requestedQuantityNode.setAttribute('value', li.value);
					Dom.XmlNode shipToLocationNode = requestedQuantityNode.addChildElement('shipToLocation', '', '');
					shipToLocationNode.setAttribute('quantity', li.quantity);
					shipToLocationNode.setAttribute('shipToID', li.shipToID);
					shipToLocationNode.setAttribute('arrivalDate', li.arrivalDate);
						Dom.XmlNode markForLocationNode = shipToLocationNode.addChildElement('markForLocation', '', '');
						markForLocationNode.setAttribute('quantity', li.quantity);
						markForLocationNode.setAttribute('markForID', li.markForID);
					Dom.XmlNode pieceIdentificationNode = requestedQuantityNode.addChildElement('pieceIdentification', '', '');
					pieceIdentificationNode.setAttribute('assignment', li.assignment);
					for (integer i = 0; i < integer.valueof(li.quantity); i++){
						Dom.XmlNode pieceIdentificationNumberNode = pieceIdentificationNode.addChildElement('pieceIdentificationNumber', '', '');
						string numberStr = '0';
						integer iInt = i < 10 ? i : 9;
						integer indexMasterInt = indexMaster < 10 ? indexMaster : 9;
						if (!usedIds.contains(string.valueof(iInt) + string.valueof(indexMasterInt))){
							numberStr = string.valueof(iInt) + string.valueof(indexMasterInt);
							usedIds.add(numberStr);
						}
						else{
							for(integer k = 0; k < 10; k ++){
								for(integer j = 0; j < 10; j ++){
									if (!usedIds.contains(string.valueof(k) + string.valueof(j))){
										numberStr = string.valueof(k) + string.valueof(j);
										usedIds.add(numberStr);
										break;
									}
								}
								if (numberStr != '0'){
									break;
								}
							}
						}
						pieceIdentificationNumberNode.addTextNode(li.pieceIdentificationNumber + numberStr);
					}
				Dom.XmlNode unitPriceyNode = LineNode.addChildElement('unitPrice', '', '');
					Dom.XmlNode discountNode = unitPriceyNode.addChildElement('discount', '', '');
						Dom.XmlNode discountOrAllowanceAmountNode = discountNode.addChildElement('discountOrAllowanceAmount', '', '');
						discountOrAllowanceAmountNode.addTextNode(li.discountOrAllowanceAmount);
						Dom.XmlNode discountOrAllowancePercentNode = discountNode.addChildElement('discountOrAllowancePercent', '', '');
						discountOrAllowancePercentNode.setAttribute('chargeOrAllowancePercent', li.chargeOrAllowancePercent);
						discountOrAllowancePercentNode.setAttribute('chargeOrAllowanceQualifier', li.chargeOrAllowanceQualifier);
						Dom.XmlNode discountOrAllowanceDescriptionNode = discountNode.addChildElement('discountOrAllowanceDescription', '', '');
						discountOrAllowanceDescriptionNode.addTextNode(li.discountOrAllowanceDescription);
					Dom.XmlNode surchargeNode = unitPriceyNode.addChildElement('surcharge', '', '');
						Dom.XmlNode additionalChargeAmountNode = surchargeNode.addChildElement('additionalChargeAmount', '', '');
						additionalChargeAmountNode.addTextNode(li.additionalChargeAmount);
						Dom.XmlNode additionalChargeDescriptionNode = surchargeNode.addChildElement('additionalChargeDescription', '', '');
						additionalChargeDescriptionNode.addTextNode(li.additionalChargeDescription);
					Dom.XmlNode priceNode = unitPriceyNode.addChildElement('price', '', '');
					priceNode.addTextNode(li.price);
					indexMaster++;
		}
		system.debug('doc.toXmlString() = ' + doc.toXmlString());
		return doc.toXmlString();
	}
	
	public static void generateOrderAndLineItems(string poId){
		po = [SELECT id, Name, Ship_From__c, Ship_From__r.Name, Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c, Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c, Sales_Order__c, Sales_Order__r.Name, Sales_Order__r.Customer_Full_Name__c,
								Sales_Order__r.Shipping_Street__c, Sales_Order__r.Shipping_City__c, Sales_Order__r.Shipping_State__c, Sales_Order__r.Shipping_Country__c, Suggested_Trucking__r.name, Notes__c, Sales_Order__r.Ship_to__c, 
								Sales_Order__r.Shipping_ZipCode__c, Sales_Order__r.Email__c, Sales_Order__r.Shipping_Phone__c, Requested_delivery_date__c, Carrier__c, Replacement_PO__c,
								Suggested_Delivery_Comapny__r.Name, Suggested_Delivery_Comapny__r.ShippingStreet, Suggested_Delivery_Comapny__r.ShippingCity, Suggested_Delivery_Comapny__r.ShippingState, Suggested_Delivery_Comapny__r.ShippingPostalCode, 
								(SELECT id, Name, SO_Line_Item__r.Products__r.sku_and_name_list__c, Quantity__c, Product_Cost__c, SO_Line_Item__r.Products__r.SKU__c, SO_Line_Item__r.Bundle_Item__r.Product__r.sku_and_name_list__c, SKU_name_and_list__c,
								SO_Line_Item__r.Bundle_Item__r.Product__r.SKU__c, SO_Line_Item__r.Bundle_Item__c, SO_Line_Item__r.Config_Product__c, SO_Line_Item__r.Config_Product__r.sku_and_name_list__c, SO_Line_Item__r.Config_Product__r.SKU__c
								FROM PO_Line_Item__r), Sales_Order__r.Magento_order_No__c, Liberty_Hub__c,
								Ship_From__r.Send_cost_per_SKU__c FROM Purchase_Order__c WHERE id = :poId];
		system.debug('po = ' + po);
		ediMap = [SELECT actionRequestIndicator_description__c, buyer_partyIdentifierCode__c, buyer_partyIdentifierQualifierCode__c, Currency__c, Inactive__c, 
							   Line_additionalChargeAmount__c, Line_additionalChargeDescription__c, Line_arrivalDate__c, Line_Buyer_itemNumber__c, Line_Buyer_itemNumberQualifier__c, 
							   Line_chargeOrAllowanceQualifier__c, Line_comment__c, Line_descriptionValue__c, Line_discountOrAllowancePercent__c, Line_itemDescriptionQualifier__c, 
							   Line_itemNumber__c, Line_itemNumberQualifier__c, Line_markForID__c, Line_markForLocation_quantity__c, Line_pieceIdentification_assignment__c, 
							   Line_pieceIdentificationNumber__c, Line_price__c, Line_shipToID__c, Line_shipToLocation_quantity__c, Line_unitOfMeasure__c, Line_value__c, 
							   Manufacturer_ID__c, markFor_electronicContactQualifier__c, markFor_electronicContactValue__c, markFor_fnParty_addressLine__c, markFor_fnParty_city__c, 
							   markFor_fnParty_country__c, markFor_fnParty_partyName__c, markFor_fnParty_postalCode__c, markFor_fnParty_stateOrProvince__c, markFor_ID__c, 
							   markFor_partyIdentifierCode__c, markFor_partyIdentifierQualifierCode__c, markFor_shippingInstructions__c, markFor_telephoneNumber__c, 
							   markFor_telephoneNumberType__c, Order_Creation_Date__c, Order_Document_id__c, Order_Language__c, Order_Type__c, Process__c, Seller_partyIdentifierCode__c, 
							   Seller_partyIdentifierQualifierCode__c, Ship_to_ID__c, shipDates_requestedArrivalDate__c, Shipto_BUYERpartyIdentifierCode__c, discountOrAllowanceAmount__c,
							   Shipto_BUYERpartyIdentifierQualifierCode__c, Shipto_partyIdentifierCode__c, Shipto_partyIdentifierQualifierCode__c, systemReferenceDescription1__c, 
							   systemReferenceDescription2__c, systemReferenceDescription3__c, systemReferenceDescription4__c, systemReferenceDescription5__c, systemReferenceDescription6__c, 
							   systemReferenceValue1__c, systemReferenceValue2__c, systemReferenceValue3__c, systemReferenceValue4__c, systemReferenceValue5__c	,systemReferenceValue6__c,
							   End_point__c ,Username__c, Password__c, URL__c, Port__c, X850_path__c, X850_file_name__c, DeveloperName, Secured__c
							   FROM EDI_Map__mdt WHERE Manufacturer_ID__c = :po.Ship_From__c];
		if (ediMap.Inactive__c){
			return;
		}
		isAshley = ediMap.DeveloperName.contains('Ashley');
		isLiberty = ediMap.DeveloperName.contains('Liberty');
		isParkerHouse = ediMap.DeveloperName.contains('parker_house');
		boolean express = po.Carrier__c != null;
		ord = new Order();
		ord.comment = String.isNotBlank(po.Notes__c) ? po.Notes__c: '';//'';
		ord.document_id = po.Sales_Order__r.Magento_order_No__c != null ? po.Sales_Order__r.Magento_order_No__c + ' ' + po.name : po.name;
		if (po.Replacement_PO__c){
			ord.document_id += isLiberty ? ' RE' : ' Repl'; 
		}
		ord.document_type = ediMap.Order_Type__c != null ? ediMap.Order_Type__c : '';
		ord.document_language = ediMap.Order_Language__c != null ? ediMap.Order_Language__c : '';
		ord.creationDate = string.valueof(system.today());
		ord.description = ediMap.actionRequestIndicator_description__c != null ? ediMap.actionRequestIndicator_description__c : '';
		ord.currenc = ediMap.Currency__c != null ? ediMap.Currency__c : '';
		ord.buyerPartyIdentifierrQualifierCode = ediMap.buyer_partyIdentifierQualifierCode__c != null ? ediMap.buyer_partyIdentifierQualifierCode__c : '';
		ord.buyerPartyIdentifierCode = ediMap.buyer_partyIdentifierCode__c != null ? ediMap.buyer_partyIdentifierCode__c : '';
		if (isLiberty){
			if (PO.Liberty_Hub__c == 'Atlanta'){
				ord.sellerPartyIdentifierrQualifierCode = 'ATL';
				ord.sellerPartyIdentifierCode = '52738532';
			}
			if (PO.Liberty_Hub__c == 'Chicago'){
				ord.sellerPartyIdentifierrQualifierCode = 'CHI';
				ord.sellerPartyIdentifierCode = '52738531';
			}
		}
		else {
			ord.sellerPartyIdentifierrQualifierCode = ediMap.Seller_partyIdentifierQualifierCode__c != null ? ediMap.Seller_partyIdentifierQualifierCode__c : '';
			ord.sellerPartyIdentifierCode = ediMap.Seller_partyIdentifierCode__c != null ? ediMap.Seller_partyIdentifierCode__c : '';
		}
		if (isLiberty || isParkerHouse){
			ord.shipToId = !express && po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c) : '';
			ord.shipToPartyIdentifierCode = !express && po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c) : '';
		}
		else{
			ord.shipToId = !express && po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c) : '';
			ord.shipToPartyIdentifierCode = !express && po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c) : '';
		}
		ord.shipToPartyIdentifierrQualifierCode = ediMap.Shipto_partyIdentifierQualifierCode__c != null ? ediMap.Shipto_partyIdentifierQualifierCode__c : '';
		ord.shipToPartyIdentifierCode2 = ediMap.Shipto_BUYERpartyIdentifierCode__c != null ? ediMap.Shipto_BUYERpartyIdentifierCode__c : '';
		ord.shipToPartyIdentifierrQualifierCode2 = ediMap.Shipto_BUYERpartyIdentifierQualifierCode__c != null ? ediMap.Shipto_BUYERpartyIdentifierQualifierCode__c : '';
		ord.markForId = po.Sales_Order__r.Magento_order_No__c != null ? po.Sales_Order__r.Magento_order_No__c : po.Sales_Order__c;
		ord.markForShippingInstructions = po.Sales_Order__r.Name != null ? po.Sales_Order__r.Name : '';
		if (isLiberty || isParkerHouse){
			ord.markForPartyIdentifierCode = !express && po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c) : '';
		}
		else{
			ord.markForPartyIdentifierCode = !express && po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c) : '';
		}
		ord.markForPartyIdentifierrQualifierCode = ediMap.markFor_partyIdentifierQualifierCode__c != null ? ediMap.markFor_partyIdentifierQualifierCode__c : '';
		ord.partyName = express && po.Sales_Order__r.Ship_to__c  != null ? po.Sales_Order__r.Ship_to__c : '';
		ord.addressLine = express && po.Sales_Order__r.Shipping_Street__c != null ? po.Sales_Order__r.Shipping_Street__c : '';
		ord.city = express && po.Sales_Order__r.Shipping_City__c != null ? po.Sales_Order__r.Shipping_City__c : '';
		ord.stateOrProvince = express && po.Sales_Order__r.Shipping_State__c != null ? po.Sales_Order__r.Shipping_State__c : '';
		ord.country = express && po.Sales_Order__r.Shipping_Country__c != null ? po.Sales_Order__r.Shipping_Country__c : '';
		ord.postalCode = express && po.Sales_Order__r.Shipping_ZipCode__c != null ? po.Sales_Order__r.Shipping_ZipCode__c.length() > 5 ? po.Sales_Order__r.Shipping_ZipCode__c.substring(0,5) : po.Sales_Order__r.Shipping_ZipCode__c : '';
		ord.electronicContactQualifier = ediMap.markFor_electronicContactQualifier__c != null ? ediMap.markFor_electronicContactQualifier__c : '';
		ord.electronicContactValue = express && po.Sales_Order__r.Email__c != null ? po.Sales_Order__r.Email__c : '';
		ord.telephoneNumberType = ediMap.markFor_telephoneNumberType__c != null ? ediMap.markFor_telephoneNumberType__c : '';
		ord.telephoneNumber = express && po.Sales_Order__r.Shipping_Phone__c != null ? po.Sales_Order__r.Shipping_Phone__c : '';
		ord.requestedArrivalDate = po.Requested_delivery_date__c != null ? string.valueof(po.Requested_delivery_date__c) : string.valueof(system.today().adddays(14));
		//ord.otherDate = 
		//ord.otherDateQualifier = 
		ord.systemReferenceDescription1 = ediMap.systemReferenceDescription1__c != null ? ediMap.systemReferenceDescription1__c : '';
		ord.systemReferenceValue1 = ediMap.systemReferenceValue1__c != null ? ediMap.systemReferenceValue1__c : '';
		ord.systemReferenceDescription2 = ediMap.systemReferenceDescription2__c != null ? ediMap.systemReferenceDescription2__c : '';
		ord.systemReferenceValue2 = ediMap.systemReferenceValue2__c != null ? ediMap.systemReferenceValue2__c : '';
		ord.systemReferenceDescription3 = ediMap.systemReferenceDescription3__c != null ? ediMap.systemReferenceDescription3__c : '';
		ord.systemReferenceValue3 = ediMap.systemReferenceValue3__c != null ? ediMap.systemReferenceValue3__c : '';
		//ord.systemReferenceDescription4 = ediMap.systemReferenceDescription4__c != null ? ediMap.systemReferenceDescription4__c : '';
		//ord.systemReferenceValue4 = ediMap.systemReferenceValue4__c != null ? ediMap.systemReferenceValue4__c : '';
		ord.systemReferenceDescription5 = ediMap.systemReferenceDescription5__c != null ? ediMap.systemReferenceDescription5__c : '';
		ord.systemReferenceValue5 = ediMap.systemReferenceValue5__c != null ? ediMap.systemReferenceValue5__c : '';
		ord.systemReferenceDescription6 = ediMap.systemReferenceDescription6__c != null ? ediMap.systemReferenceDescription6__c : '';
		ord.systemReferenceValue6 = ediMap.systemReferenceValue6__c != null ? ediMap.systemReferenceValue6__c : '';
		
		lis = new list<LineItem>();
		Map<String, Decimal> productsSkuToPriceMap = new Map<String, Decimal>();
		integer index = 1;
		for (PO_Line_Items__c li : po.PO_Line_Item__r){
			map<string, integer> skuQuantity = new map<string, integer>();
			string skuStr = li.SKU_name_and_list__c != null ? li.SKU_name_and_list__c : li.SO_Line_Item__r.Config_Product__c != null ? li.SO_Line_Item__r.Config_Product__r.sku_and_name_list__c : li.SO_Line_Item__r.Bundle_Item__c != null ? li.SO_Line_Item__r.Bundle_Item__r.Product__r.sku_and_name_list__c : li.SO_Line_Item__r.Products__r.sku_and_name_list__c;
			if (skuStr != null && skuStr != ''){
					list<productInfo> productsInfo = (list<productInfo>)json.deserialize(skuStr, list<productInfo>.class);
					for (productInfo pi : productsInfo){
						if (!skuQuantity.containsKey(pi.sku)){
							skuQuantity.put(pi.sku, 0);
						}
						skuQuantity.put(pi.sku, skuQuantity.get(pi.sku) + 1);
						if (pi.cost != null){
							if(!productsSkuToPriceMap.containsKey(pi.sku)){
								productsSkuToPriceMap.put(pi.sku, pi.cost);
								//productsSkuToPriceMap.put(pi.sku, 0);
							}
							//changed to avoid sending double price for set products
							//productsSkuToPriceMap.put(pi.sku, productsSkuToPriceMap.get(pi.sku) + pi.cost);
						}

					}
			}
			else{
				skuQuantity.put(li.SO_Line_Item__c != null ? li.SO_Line_Item__r.Config_Product__r.SKU__c : li.SO_Line_Item__r.Bundle_Item__c != null ? li.SO_Line_Item__r.Bundle_Item__r.Product__r.SKU__c : li.SO_Line_Item__r.Products__r.SKU__c, 1);
			}
			system.debug('skuQuantity = ' + skuQuantity);
			for (string sku : skuQuantity.keyset()){
				LineItem l = new LineItem();
				l.lineItemNumber = string.valueof(index);
				l.comment = li.Name != null ? li.name : '';
				l.itemNumber = sku != null ? sku.contains('-') ? sku.split('-',2)[1] : sku : '';
				l.itemNumberQualifier = ediMap.Line_itemNumberQualifier__c != null ? ediMap.Line_itemNumberQualifier__c : '';
				l.itemNumber2 = sku != null ? sku : '';
				l.itemNumberQualifier2 = ediMap.Line_Buyer_itemNumberQualifier__c != null ? ediMap.Line_Buyer_itemNumberQualifier__c : '';
				l.descriptionValue = ediMap.Line_descriptionValue__c != null ? ediMap.Line_descriptionValue__c : '';
				l.itemDescriptionQualifier = ediMap.Line_itemDescriptionQualifier__c != null ? ediMap.Line_itemDescriptionQualifier__c : '';
				l.unitOfMeasure = ediMap.Line_unitOfMeasure__c != null ? ediMap.Line_unitOfMeasure__c : '';
				l.value = li.Quantity__c != null ? string.valueof(li.Quantity__c * skuQuantity.get(sku)) : '';//ediMap.Line_value__c != null ? ediMap.Line_value__c : '';
				l.quantity = li.Quantity__c != null ? string.valueof(li.Quantity__c * skuQuantity.get(sku)) : '';
				if (isLiberty || isParkerHouse){
					l.shipToID = !express && po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Liberty_Ship_to_ID__c) : '';
				}
				else{
					l.shipToID = !express && po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c != null ? string.valueof(po.Suggested_Delivery_Comapny__r.Ashley_Ship_to_ID__c) : '';
				}
				l.arrivalDate = po.Requested_delivery_date__c != null ? string.valueof(po.Requested_delivery_date__c) : string.valueof(system.today().adddays(14));
				l.markForID = po.Sales_Order__r.Magento_order_No__c != null ? po.Sales_Order__r.Magento_order_No__c : po.Sales_Order__c;//li.id != null ? li.id : '';
				l.assignment = ediMap.Line_pieceIdentification_assignment__c != null ? ediMap.Line_pieceIdentification_assignment__c : '';
				l.pieceIdentificationNumber =  li.id != null ? string.valueof(li.id) : '';
				l.discountOrAllowanceAmount = ediMap.discountOrAllowanceAmount__c != null ? string.valueof(ediMap.discountOrAllowanceAmount__c) : '';
				l.chargeOrAllowancePercent = ediMap.Line_discountOrAllowancePercent__c != null ? string.valueof(ediMap.Line_discountOrAllowancePercent__c) : '';
				l.chargeOrAllowanceQualifier = ediMap.Line_chargeOrAllowanceQualifier__c != null ? ediMap.Line_chargeOrAllowanceQualifier__c : '';
				l.discountOrAllowanceDescription = '';
				l.additionalChargeAmount = ediMap.Line_additionalChargeAmount__c != null ? string.valueof(ediMap.Line_additionalChargeAmount__c) : '';
				l.additionalChargeDescription = ediMap.Line_additionalChargeDescription__c != null ? ediMap.Line_additionalChargeDescription__c : '';
				String productCost = li.Product_Cost__c != null ? String.valueOf(li.Product_Cost__c) : '';
				if(po.Ship_From__c != null && po.Ship_From__r.Send_cost_per_SKU__c == true && productsSkuToPriceMap.containsKey(sku)){
					productCost = String.valueOf(productsSkuToPriceMap.get(sku));
				}
				l.price = productCost; //li.Product_Cost__c != null ? string.valueof(li.Product_Cost__c) : '';
				lis.add(l);
				index++;
			}
		}
		ord.suggestedTruckingCompany = Utilities.getCarrierCorde(po.Carrier__c != null ? po.Carrier__c : po.Suggested_Trucking__r.name) ;
		ord.suggestedDeliveryCompany = po.Suggested_Delivery_Comapny__r.name;
		ord.suggestedDeliveryCompanyStreet = po.Suggested_Delivery_Comapny__r.ShippingStreet;
		ord.suggestedDeliveryCompanyCity = po.Suggested_Delivery_Comapny__r.ShippingCity;
		ord.suggestedDeliveryCompanyState = po.Suggested_Delivery_Comapny__r.ShippingState;
		ord.suggestedDeliveryCompanyPostalCode = po.Suggested_Delivery_Comapny__r.ShippingPostalCode!= null && po.Suggested_Delivery_Comapny__r.ShippingPostalCode.length() > 5 ? po.Suggested_Delivery_Comapny__r.ShippingPostalCode.substring(0,5) : po.Suggested_Delivery_Comapny__r.ShippingPostalCode;
		system.debug('ord = ' + string.valueof(ord));
		system.debug('lis = ' + string.valueof(lis));
	}
	

	public class LineItem{
		public string lineItemNumber {get; set;}
		public string comment {get; set;}
		public string itemNumber {get; set;}
		public string itemNumberQualifier {get; set;}
		public string itemNumber2 {get; set;}
		public string itemNumberQualifier2 {get; set;}
		public string descriptionValue {get; set;}
		public string itemDescriptionQualifier {get; set;}
		public string unitOfMeasure {get; set;}
		public string value {get; set;}
		public string quantity {get; set;}
		public string shipToID {get; set;}
		public string arrivalDate {get; set;}
		public string markForID {get; set;}
		public string assignment {get; set;}
		public string pieceIdentificationNumber {get; set;}
		public string discountOrAllowanceAmount {get; set;}
		public string chargeOrAllowancePercent {get; set;}
		public string chargeOrAllowanceQualifier {get; set;}
		public string discountOrAllowanceDescription {get; set;}
		public string additionalChargeAmount {get; set;}
		public string additionalChargeDescription {get; set;}
		public string price {get; set;}
	}
	
	public class Order{
		public string comment {get; set;}
		public string document_id {get; set;}
		public string document_type {get; set;}
		public string document_language {get; set;}
		public string creationDate {get; set;}
		public string description {get; set;}
		public string currenc {get; set;}
		public string buyerPartyIdentifierrQualifierCode {get; set;}
		public string buyerPartyIdentifierCode {get; set;}
		public string sellerPartyIdentifierrQualifierCode {get; set;}
		public string sellerPartyIdentifierCode {get; set;}
		public string shipToId {get; set;}
		public string shipToPartyIdentifierCode {get; set;}
		public string shipToPartyIdentifierrQualifierCode {get; set;}
		public string shipToPartyIdentifierCode2 {get; set;}
		public string shipToPartyIdentifierrQualifierCode2 {get; set;}
		public string markForId {get; set;}
		public string markForShippingInstructions {get; set;}
		public string markForPartyIdentifierCode {get; set;}
		public string markForPartyIdentifierrQualifierCode {get; set;}
		public string partyName {get; set;}
		public string addressLine {get; set;}
		public string city {get; set;}
		public string stateOrProvince {get; set;}
		public string country {get; set;}
		public string postalCode {get; set;}
		public string electronicContactQualifier {get; set;}
		public string electronicContactValue {get; set;}
		public string telephoneNumberType {get; set;}
		public string telephoneNumber {get; set;}
		public string requestedArrivalDate {get; set;}
		//public string otherDate {get; set;}
		//public string otherDateQualifier {get; set;}
		public string systemReferenceDescription1 {get; set;}
		public string systemReferenceValue1 {get; set;}
		public string systemReferenceDescription2 {get; set;}
		public string systemReferenceValue2 {get; set;}
		public string systemReferenceDescription3 {get; set;}
		public string systemReferenceValue3 {get; set;}
		//public string systemReferenceDescription4 {get; set;}
		//public string systemReferenceValue4 {get; set;}
		public string systemReferenceDescription5 {get; set;}
		public string systemReferenceValue5 {get; set;}
		public string systemReferenceDescription6 {get; set;}
		public string systemReferenceValue6 {get; set;}
		public string suggestedTruckingCompany {get; set;}
		public string suggestedDeliveryCompany {get; set;}
		public string suggestedDeliveryCompanyStreet {get; set;}
		public string suggestedDeliveryCompanyCity {get; set;}
		public string suggestedDeliveryCompanyState {get; set;}
		public string suggestedDeliveryCompanyPostalCode {get; set;}
	}
	
	public class Request{
		public string username {get; set;}
		public string password {get; set;}
		public string url {get; set;}
		public string port {get; set;}
		public boolean secured {get; set;}
		public string contentRaw {get; set;}
		public string fileName {get; set;}
		public string path {get; set;}
		//https://ftp-synch.herokuapp.com/api/v1/store
	}
	
	public class Response{
		public boolean success {get; set;}
		public string message {get; set;}
		
		public Response(){
			
		}
		
		public Response(boolean success, string message){
			this.success = success;
			this.message = message;
		}
	}
	
    public class productInfo{
    	public string sku {get; set;}
    	public string name {get; set;}
    	public string weight {get; set;}
		public string dimensions {get; set;}
		public Decimal cost {get; set;}
    	
    	public productInfo(string sku, string name, string weight, string dimensions, Decimal cost){
    		this.sku = sku;
    		this.name = name;
    		this.weight = weight;
			this.dimensions = dimensions;
			this.cost = cost;
    	}
    }
}