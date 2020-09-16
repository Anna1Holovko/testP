@RestResource(urlMapping='/Acknowledgment/*')
global class PurchaseOrderAcknowledgment {
	
	@HttpPost  
	global static Response getPurchaseOrderAcknowledgment() {
		string xmlInput = RestContext.request.requestBody.toString();
		Purchase_Order__c po;
		string orderDocumentId = '';
		list<Log__c> logs;
		try{
			system.debug('xmlInput = ' + xmlInput);
			AckOrder ackOrder = new AckOrder();
			list<AckLine> ackLines = new list<AckLine>();
			Dom.Document doc = new Dom.Document();
			doc.load(xmlInput);
			for(Dom.XmlNode node :doc.getRootElement().getChildElements()){
			    if (node.getName() == 'ackOrder'){
			        ackOrder.process(node);
					system.debug('ackOrder = ' + ackOrder);
			    }
			    else if (node.getName() == 'ackLine'){
			    	AckLine ackLine = new AckLine();
			        ackLine.process(node);
					system.debug('ackLine = ' + ackLine);
					ackLines.add(ackLine);
			    }
			    orderDocumentId = ackOrder.orderDocumentId;
			}
			logs = [select Object_ID__c, Tries__c, Process__c, Data__c, Status__c, Error__c from Log__c where Object_ID__c = :orderDocumentId];
			system.debug('ackOrder.orderDocumentId = ' + ackOrder.orderDocumentId);
			try {
				po = [select id, name, Load_Date__c, Status__c, PO_acknowledged__c, Tracking_Number__c, 
					 (select id, SO_Line_Item__r.Products__r.SKU_List__c, Quantity__c, Acknowledged_order_quantity__c, Acknowledged_quantity__c, Estimated_delivery_date__c, SO_Line_Item__r.Products__r.SKU__c,
					 Discount_amount__c, Additional_charges_applied__c, Acknowledged_net_price__c, Shipping_carton_identification__c from PO_Line_Item__r) 
					 from Purchase_Order__c where name = :ackOrder.orderDocumentId];
			}
			catch(exception ex){
				Log__c log = new Log__c(Object_ID__c = orderDocumentId, Process__c = 'EDI - Acknowledgment', Data__c = xmlInput, Tries__c = 1, Status__c = 'Failed', Error__c = 'Can not find the PO');
				if (logs.size() > 0){
					log.Tries__c = logs[0].Tries__c + 1;
					log.id = logs[0].id;
				}
				upsert log;
				system.debug('ex.getmessage() = ' + ex.getmessage() + ' ' + ex.getlinenumber());
				return new Response(true, '');
			}
			updatePurchaseOrder(ackOrder, ackLines, po);
		}
		catch (exception e){
			Log__c log = new Log__c(Object_ID__c = orderDocumentId, Process__c = 'EDI - Acknowledgment', Data__c = xmlInput, Tries__c = 1, Status__c = 'Failed', Error__c = e.getmessage() + ' ' + e.getlinenumber());
			if (logs != null && logs.size() > 0){
				log.Tries__c = logs[0].Tries__c + 1;
				log.id = logs[0].id;
			}
			upsert log;
			system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getlinenumber());
			return new Response(false, e.getmessage() + ' ' + e.getlinenumber());
		}
		Log__c log = new Log__c(Object_ID__c = po.id, Process__c = 'EDI - Acknowledgment', Data__c = xmlInput, Tries__c = 1, Status__c = 'Succeeded');
		if (logs.size() > 0){
			log.Tries__c = logs[0].Tries__c + 1;
			log.id = logs[0].id;
		}
		upsert log;
		return new Response(true, '');
	}
	
	global static void updatePurchaseOrder(AckOrder ackOrder, list<AckLine> ackLines, Purchase_Order__c po){
		map<id, PO_Line_Items__c> liToUpdate = new map<id, PO_Line_Items__c>();
		if (po.PO_acknowledged__c == null){
			po.PO_acknowledged__c = system.now();
			list<Log__c> log = [select id, Status__c from Log__c where Object_ID__c = :po.id];
			if (log.size() > 0){
				log[0].Status__c = 'Succeeded';
				update log[0];
			}
		}
		Boolean isEmptyLoadDate = po.Load_Date__c == null;
		po.Tracking_Number__c = ackOrder.ackDocumentId;
		if(ackOrder.ackShipDate != null){
			po.Load_Date__c = ackOrder.ackShipDate;
		}

		if (ackOrder.actionRequestIndicatorDescription == 'Cancel'){
			po.Status__c = 'Cancelled';
		}
		else if (isEmptyLoadDate && po.Load_Date__c != null){
			po.Status__c = 'On Order';
		}
		
		po.Delivery_Date_Expected__c = ackOrder.ackArrivalDate;
		for (AckLine al : ackLines){
			system.debug('al.itemNumber =------------------------------------------------------------------------------> ' + al.itemNumber);
			for (PO_Line_Items__c li : po.PO_Line_Item__r){
				system.debug('li.SO_Line_Item__r.Products__r.SKU_List__c = ' + li.SO_Line_Item__r.Products__r.SKU_List__c);
				if ((li.SO_Line_Item__r.Products__r.SKU_List__c != null && li.SO_Line_Item__r.Products__r.SKU_List__c.contains(al.itemNumber)) || (li.SO_Line_Item__r.Products__r.SKU_List__c == null && li.SO_Line_Item__r.Products__r.SKU__c == al.itemNumber)){
					//system.debug('li.SO_Line_Item__r.Products__r.SKU_List__c.countMatches(al.itemNumber) = ' + li.SO_Line_Item__r.Products__r.SKU_List__c.countMatches(al.itemNumber));
					/*if (li.SO_Line_Item__r.Products__r.SKU_List__c.countMatches(al.itemNumber) > 1){
						li.Quantity__c = al.Acknowledged_order_quantity__c / li.SO_Line_Item__r.Products__r.SKU_List__c.countMatches(al.itemNumber);
					}
					else if (li.Quantity__c > al.Acknowledged_order_quantity__c){
						li.Quantity__c = al.Acknowledged_order_quantity__c;
					}*/
					if (li.Acknowledged_order_quantity__c == null || li.Acknowledged_order_quantity__c == 0 || li.Acknowledged_order_quantity__c < decimal.valueof(al.shipTo_quantity)){
						li.Acknowledged_order_quantity__c = decimal.valueof(al.shipTo_quantity);
					}
					if (li.Acknowledged_quantity__c == null || li.Acknowledged_quantity__c == 0 || li.Acknowledged_quantity__c < decimal.valueof(al.value)){
						li.Acknowledged_quantity__c = decimal.valueof(al.value);
					}
					li.Acknowledged_quantity__c = decimal.valueof(al.value);
					if(li.Estimated_delivery_date__c == null || li.Estimated_delivery_date__c < al.arrivalDate){
						li.Estimated_delivery_date__c = al.arrivalDate;
					}
					li.Shipping_carton_identification__c = al.itemNumber2;
					//<ackdiscount>	Update PO line item - Discounts_applied - NEW FIELD	Discounts applied
					li.Discount_amount__c = al.discountOrAllowanceAmount;
					li.Additional_charges_applied__c = al.additionalChargeAmount;
					//<additionalChargeAmount> (fnBase:monitaryAmountType)	Update PO line item - Line_item_freight_charge_amount- NEW FIELD	Line-item freight charge amount
					if (li.Acknowledged_net_price__c == null || li.Acknowledged_net_price__c == 0 || li.Acknowledged_net_price__c < al.ackprice){
						li.Acknowledged_net_price__c = al.ackprice;
					}
					if (!liToUpdate.containskey(li.id)){
						liToUpdate.put(li.id, li);
					}
				}
			}
		}
		po.EDI_Status__c = 'Success';
		update po;
		if (liToUpdate.values().size() > 0){
			update liToUpdate.values();
		}
	}
	
	global class AckOrder{
		public string orderDocumentId {get; set;}
		public date orderDocumentCreationDate {get; set;}
		public string ackDocumentId {get; set;}
		public string ackDocumentType {get; set;}
		public date ackDocumentCreationDate {get; set;}
		public string actionRequestIndicatorDescription {get; set;}
		public string buyerPartyIdentifierCode {get; set;}
		public string buyerpartyIdentifierQualifierCode {get; set;}
		public string sellerPartyIdentifierCode {get; set;}
		public string sellerpartyIdentifierQualifierCode {get; set;}
		public string shipToId {get; set;}
		public string shipToPartyIdentifierCode {get; set;}
		public string shipTopartyIdentifierQualifierCode {get; set;}
		public string shipToPartyIdentifierCode2 {get; set;}
		public string shipTopartyIdentifierQualifierCode2 {get; set;}
		public string partyName {get; set;}
		public string addressLine2 {get; set;}
		public string addressLine {get; set;}
		public string city {get; set;}
		public string stateOrProvince {get; set;}
		public string country {get; set;}
		public string postalCode {get; set;}
		public date ackShipDate {get; set;}
		public date ackArrivalDate {get; set;}
		
        public void process(Dom.XmlNode inNode){
            for(Dom.XmlNode innerNode :inNode.getChildElements()){
				system.debug('innerNode.getName() = ' + innerNode.getName());
                if(innerNode.getName() == 'orderDocument'){
                	orderDocumentId = innerNode.getAttributeValue('id', null).split(' ').size() > 1 ? innerNode.getAttributeValue('id', null).split(' ')[1] : innerNode.getAttributeValue('id', null);
                	orderDocumentCreationDate = date.valueof(innerNode.getChildElements()[0].getText());
                } else if(innerNode.getName() ==  'ackDocument'){
                	ackDocumentId = innerNode.getAttributeValue('id', null);
                	ackDocumentType = innerNode.getAttributeValue('type', null);
                    ackDocumentCreationDate = date.valueof(innerNode.getChildElements()[0].getText());
                } else if(innerNode.getName() ==  'actionRequestIndicator'){
                	actionRequestIndicatorDescription = innerNode.getAttributeValue('description', null);
                } else if(innerNode.getName() ==  'buyer'){
                	buyerPartyIdentifierCode = innerNode.getChildElements()[0].getAttributeValue('partyIdentifierCode', null);
                	buyerpartyIdentifierQualifierCode = innerNode.getChildElements()[0].getAttributeValue('partyIdentifierQualifierCode', null);
                } else if(innerNode.getName() ==  'seller'){
                	sellerPartyIdentifierCode = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('partyIdentifierCode', null);
                	sellerpartyIdentifierQualifierCode = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('partyIdentifierQualifierCode', null);
                } else if(innerNode.getName() ==  'shipTo'){
                	for(Dom.XmlNode inInnerNode :innerNode.getChildElements()){
		                shipToId = innerNode.getAttributeValue('id', null);
                		if(inInnerNode.getName() ==  'fnParty:partyIdentifier'){
		                	shipToPartyIdentifierCode = inInnerNode.getAttributeValue('partyIdentifierCode', null);
		                	shipTopartyIdentifierQualifierCode = inInnerNode.getAttributeValue('partyIdentifierQualifierCode', null);
                		}
                		else if(inInnerNode.getName() ==  'fnParty:partyName'){
                			partyName = inInnerNode.getText();
                		}
                		else if(inInnerNode.getName() ==  'fnParty:addressLine'){
                			addressLine2 = inInnerNode.getText();
                		}
                		else if(inInnerNode.getName() ==  'fnParty:city'){
                			city = inInnerNode.getText();
                		}
                		else if(inInnerNode.getName() ==  'fnParty:stateOrProvince'){
                			stateOrProvince = inInnerNode.getText();
                		}
                		else if(inInnerNode.getName() ==  'fnParty:country'){
                			country = inInnerNode.getText();
                		}
                		else if(inInnerNode.getName() ==  'fnParty:postalCode'){
                			postalCode = inInnerNode.getText();
                		}
                	}
                	//shipToPartyIdentifierCode2 = innerNode.getChildElements()[1].getAttributeValue('partyIdentifierCode', null);
                	//shipTopartyIdentifierQualifierCode2 = innerNode.getChildElements()[1].getAttributeValue('partyIdentifierQualifierCode', null);
                	
                	//addressLine = innerNode.getChildElements()[3].getText();
                } else if(innerNode.getName() ==  'ackShipDates'){
                	ackShipDate = date.valueof(innerNode.getChildElements()[0].getText());
                	ackArrivalDate = date.valueof(innerNode.getChildElements()[1].getText());
                }
            }
        }
	}
	
	global class AckLine{
		
		public string lineItemNumber {get; set;}
		public string itemNumber {get; set;}
		public string itemNumberQualifier {get; set;}
		public string itemNumber2 {get; set;}
		public string itemNumberQualifier2 {get; set;}
		public string descriptionValue {get; set;}
		public string itemDescriptionQualifier {get; set;}
		public string itemDescriptionClassification {get; set;}
		public string unitOfMeasure {get; set;}
		public string value {get; set;}
		public string shipTo_quantity {get; set;}
		public string shipToID {get; set;}
		public date arrivalDate {get; set;}
		public string markFor_quantity {get; set;}
		public string markForID {get; set;}
		public decimal discountOrAllowanceAmount {get; set;}
		public string discountOrAllowanceDescription {get; set;}
		public decimal additionalChargeAmount {get; set;}
		public string additionalChargeDescription {get; set;}
		public decimal ackprice {get; set;}
		
        public void process(Dom.XmlNode inNode){
            lineItemNumber = inNode.getAttributeValue('lineItemNumber', null);
            for(Dom.XmlNode innerNode :inNode.getChildElements()){
				system.debug('innerNode.getName() = ' + innerNode.getName());
                if(innerNode.getName() == 'ackProductID'){
					system.debug('innerNode.getChildElements() = ' + innerNode.getChildElements());
                	itemNumber = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[0].getAttributeValue('itemNumber', null) : '';
                	itemNumberQualifier = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[0].getAttributeValue('itemNumberQualifier', null) : '';
                	itemNumber2 = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[1].getAttributeValue('itemNumber', null) : innerNode.getChildElements()[0].getAttributeValue('itemNumber', null);
                	itemNumberQualifier2 = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[1].getAttributeValue('itemNumberQualifier', null) : innerNode.getChildElements()[0].getAttributeValue('itemNumberQualifier', null);
                	descriptionValue = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[2].getAttributeValue('descriptionValue', null) : innerNode.getChildElements()[1].getAttributeValue('descriptionValue', null);
                	itemDescriptionQualifier = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[2].getAttributeValue('itemDescriptionQualifier', null) : innerNode.getChildElements()[1].getAttributeValue('itemDescriptionQualifier', null);
                	itemDescriptionClassification = innerNode.getChildElements().size() == 3 ? innerNode.getChildElements()[2].getAttributeValue('itemDescriptionClassification', null) : innerNode.getChildElements()[1].getAttributeValue('itemDescriptionClassification', null);
                } 
                else if(innerNode.getName() ==  'ackQuantity'){
                	unitOfMeasure = innerNode.getAttributeValue('unitOfMeasure', null);
                	value = innerNode.getAttributeValue('value', null);
                	shipTo_quantity = innerNode.getChildElements()[0].getAttributeValue('quantity', null);
                	shipToID = innerNode.getChildElements()[0].getAttributeValue('shipToID', null);
                	arrivalDate = date.valueof(innerNode.getChildElements()[0].getAttributeValue('arrivalDate', null));
                	//markFor_quantity = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('quantity', null);
                	//markForID = innerNode.getChildElements()[0].getChildElements()[0].getAttributeValue('markForID', null);
                } 
                else if(innerNode.getName() ==  'ackUnitPrice'){
            		for(Dom.XmlNode inInnerNode :innerNode.getChildElements()){
                		if(inInnerNode.getName() == 'ackdiscount'){
		                    discountOrAllowanceAmount = decimal.valueof(inInnerNode.getChildElements()[0].getText());
		                    discountOrAllowanceDescription = inInnerNode.getChildElements()[1].getText();
                		}
                		else if (inInnerNode.getName() == 'acksurcharge'){
		                    additionalChargeAmount = decimal.valueof(inInnerNode.getChildElements()[0].getText());
		                    additionalChargeDescription = inInnerNode.getChildElements()[1].getText();
                		}
                		else if (inInnerNode.getName() == 'ackprice'){
	                    	ackprice = decimal.valueof(inInnerNode.getText());
                		}
            		}
                }
            }
        }
	}
	
	global class Response{
		public boolean success {get; set;}
		public string message {get; set;}
		
		public Response(){
			
		}
		
		public Response(boolean success, string message){
			this.success = success;
			this.message = message;
		}
	}
	
}