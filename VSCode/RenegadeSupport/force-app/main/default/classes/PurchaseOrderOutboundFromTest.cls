@isTest
public class PurchaseOrderOutboundFromTest {
    
    static testMethod void PurchaseOrderOutboundFrom(){
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Ship_From__c = [select Manufacturer_ID__c from EDI_Map__mdt limit 1].Manufacturer_ID__c;
        update po;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        PurchaseOrderOutboundFrom.sendForm(po.id);
    }
    
    
    static testMethod void PurchaseOrderAcknowledgment(){
        Account ac = TestUtil.createCustomerAccount(); 
        Products__c Pro = TestUtil.createConfigProduct();
        Pro.SKU_List__c = '1';
        update Pro;
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Ship_From__c = [select Manufacturer_ID__c from EDI_Map__mdt limit 1].Manufacturer_ID__c;
        update po;
        po = [SELECT Id,Name FROM Purchase_Order__c WHERE Id = :po.Id];
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        Log__c log = new Log__c();
        log.Object_ID__c = po.Id;
        insert log;
        String xmlRaw = '<poAck xmlns="http://support.furnishnet.com/xml/schemas/fnPOAck_v1.7" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:fnBase="http://support.furnishnet.com/xml/schemas/fnBase_v1.5" xmlns:fnItem="http://support.furnishnet.com/xml/schemas/fnItem_v1.5" xmlns:fnParty="http://support.furnishnet.com/xml/schemas/fnParty_v1.4" xsi:schemaLocation="http://support.furnishnet.com/xml/schemas/fnPOAck_v1.7 http://support.furnishnet.com/xml/schemas/fn_poAck_v1.7.xsd"><ackOrder xmlns=""><orderDocument id="{0}"><creationDate>2016-02-01</creationDate></orderDocument><ackDocument id="C456789" type="855"><creationDate>2016-02-01</creationDate></ackDocument><actionRequestIndicator description="Create" /><ackCurrency/><buyer><fnParty:partyIdentifier partyIdentifierCode="providedByAshley" partyIdentifierQualifierCode="SenderAssigned" /></buyer><seller><sellerIdentification><fnParty:partyIdentifier partyIdentifierCode="052738531" partyIdentifierQualifierCode="DUNS" /></sellerIdentification></seller><shipTo id="providedByAshley"><fnParty:partyIdentifier partyIdentifierCode="alternateShipTo" partyIdentifierQualifierCode="ReceiverAssigned" /><fnParty:partyIdentifier partyIdentifierCode="providedByAshley" partyIdentifierQualifierCode="SenderAssigned" /><fnParty:partyName>Furniture Retailer Name</fnParty:partyName><fnParty:addressLine>Suite 12</fnParty:addressLine><fnParty:addressLine>213 Street Ave.</fnParty:addressLine><fnParty:city>Anytown</fnParty:city><fnParty:stateOrProvince>ST</fnParty:stateOrProvince><fnParty:country>USA</fnParty:country><fnParty:postalCode>000000000</fnParty:postalCode></shipTo><ackShipDates><ackShipDate>2016-02-07</ackShipDate><ackArrivalDate>2016-02-10</ackArrivalDate></ackShipDates></ackOrder><ackLine lineItemNumber="2" xmlns=""><ackProductID><itemIdentifier itemNumber="{1}" itemNumberQualifier="BuyerAssigned"/><itemIdentifier itemNumber="1234536" itemNumberQualifier="SellerAssigned"/><itemDescription descriptionValue="FULL SLEEPER" itemDescriptionQualifier="SellerAssigned" itemDescriptionClassification="Product"/></ackProductID><ackQuantity unitOfMeasure="Each" value="2"><shipToLocation quantity="2" shipToID="01" arrivalDate="2004-01-10"><markForLocation quantity="2" markForID="14982000"/></shipToLocation></ackQuantity><ackUnitPrice><ackdiscount><discountOrAllowanceAmount>2.00</discountOrAllowanceAmount><discountOrAllowanceDescription>Discount</discountOrAllowanceDescription></ackdiscount><acksurcharge><additionalChargeAmount>30.00</additionalChargeAmount><additionalChargeDescription>Freight</additionalChargeDescription></acksurcharge><ackprice>377.99</ackprice></ackUnitPrice></ackLine><ackLine lineItemNumber="3" xmlns=""><ackProductID><itemIdentifier itemNumber="105124402" itemNumberQualifier="BuyerAssigned"/><itemIdentifier itemNumber="1234586" itemNumberQualifier="SellerAssigned"/><itemDescription descriptionValue="REC LOVESEAT" itemDescriptionQualifier="SellerAssigned" itemDescriptionClassification="Product"/></ackProductID><ackQuantity unitOfMeasure="Each" value="3"><shipToLocation quantity="3" shipToID="01" arrivalDate="2004-01-10"><markForLocation quantity="3" markForID="14982000"/></shipToLocation></ackQuantity><ackUnitPrice><ackdiscount><discountOrAllowanceAmount>3.00</discountOrAllowanceAmount><discountOrAllowanceDescription>Discount</discountOrAllowanceDescription></ackdiscount><acksurcharge><additionalChargeAmount>35.00</additionalChargeAmount><additionalChargeDescription>Freight</additionalChargeDescription></acksurcharge><ackprice>411.99</ackprice></ackUnitPrice></ackLine><ackLine lineItemNumber="4" xmlns=""><ackProductID><itemIdentifier itemNumber="102124409" itemNumberQualifier="BuyerAssigned"/><itemIdentifier itemNumber="1234588" itemNumberQualifier="SellerAssigned"/><itemDescription descriptionValue="REC SOFA" itemDescriptionQualifier="SellerAssigned" itemDescriptionClassification="Product"/></ackProductID><ackQuantity unitOfMeasure="Each" value="4"><shipToLocation quantity="4" shipToID="01" arrivalDate="2004-01-10"><markForLocation quantity="4" markForID="14982000"/></shipToLocation></ackQuantity><ackUnitPrice><ackdiscount><discountOrAllowanceAmount>4.00</discountOrAllowanceAmount><discountOrAllowanceDescription>Discount</discountOrAllowanceDescription></ackdiscount><acksurcharge><additionalChargeAmount>40.00</additionalChargeAmount><additionalChargeDescription>Freight</additionalChargeDescription></acksurcharge><ackprice>435.99</ackprice></ackUnitPrice></ackLine></poAck>';
        xmlRaw = String.format(xmlRaw, new List<String>{po.Name,'1'});      
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(xmlRaw);
        request.httpMethod = 'POST';
        RestContext.request = request;
        PurchaseOrderAcknowledgment.getPurchaseOrderAcknowledgment();
        System.assertEquals(1,[SELECT Id FROM Purchase_Order__c WHERE EDI_Status__c = 'Success' AND Id = :po.Id].size());
    }
    
    private static String PurchaseOrderShipNoticeTestPrepare(){
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        so.Payment_Status__c = 'Received';
        so.Check_for_Fraud__c = false;
        update so;
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        
        po.Ship_From__c = [select Manufacturer_ID__c from EDI_Map__mdt limit 1].Manufacturer_ID__c;
        po.Load_Date__c = Date.today();
        update po;
        po = [SELECT Id, Name FROM Purchase_Order__c LIMIT 1];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        PO_Line_Items__c poLI2 = TestUtil.createpoitem(po.Id, Sol.Id);
        
        string xmlRaw = '<fnASN:advanceShipNotice xmlns:fnASN="http://support.furnishnet.com/xml/schemas/fnASN_v1.7" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:fnBase="http://support.furnishnet.com/xml/schemas/fnBase_v1.5" xmlns:fnItem="http://support.furnishnet.com/xml/schemas/fnItem_v1.5" xmlns:fnParty="http://support.furnishnet.com/xml/schemas/fnParty_v1.4" xsi:schemaLocation="http://support.furnishnet.com/xml/schemas/fn_ASN_v1.7 http://support.furnishnet.com/xml/schemas/fn_ASN_v1.7.xsd">'+
            			'<shipment><document id="{0}" type="856"><creationDate>2018-03-13</creationDate><creationTime>21:21:57</creationTime></document><documentStructure documentStructureQualifier="ShipmentOrderItemPack" /><shipmentReferenceNumber referenceNumberValue="{1}" referenceNumberQualifier="BillOfLadingNumber" /><shipmentReferenceNumber referenceNumberValue="25341-1" referenceNumberQualifier="CarrierReferenceNumber" /><shipDate shipDateQualifier="Estimated" shipDate="2018-03-14" />' + 
            			'<buyer><fnParty:partyIdentifier partyIdentifierCode="3302800" partyIdentifierQualifierCode="SenderAssigned" /><fnParty:partyName>NAIXIN FURNITURE INC</fnParty:partyName><fnParty:addressLine>85 5TH AVENUE</fnParty:addressLine><fnParty:city>PATERSON</fnParty:city><fnParty:stateOrProvince>NJ</fnParty:stateOrProvince><fnParty:country>USA</fnParty:country><fnParty:postalCode>07524</fnParty:postalCode></buyer><seller><sellerIdentification><fnParty:partyIdentifier partyIdentifierCode="052738531" partyIdentifierQualifierCode="DUNS" />' + 
            			'</sellerIdentification></seller><carrier><carrierIdentification><fnParty:partyIdentifier partyIdentifierCode="RATE SHOP" partyIdentifierQualifierCode="SenderAssigned" /></carrierIdentification><transitTime unitOfMeasure="CalendarDays" value="1" /></carrier><shipTo id=""><fnParty:partyIdentifier partyIdentifierCode="" partyIdentifierQualifierCode="SenderAssigned" /><fnParty:partyName>NAIXIN FURNITURE INC</fnParty:partyName><fnParty:addressLine>85 5TH AVENUE</fnParty:addressLine><fnParty:city>PATERSON</fnParty:city><fnParty:stateOrProvince>NJ</fnParty:stateOrProvince><fnParty:country>USA</fnParty:country>' + 
            			'<fnParty:postalCode>07524</fnParty:postalCode></shipTo><order><orderReferenceNumber referenceNumberValue="{1}" referenceNumberQualifier="PurchaseOrderNumber" /><orderReferenceNumber referenceNumberValue="{1}" referenceNumberQualifier="SellerSalesOrderNumber" /><item><itemInformation><itemIdentifier itemNumber="D440-024" itemNumberQualifier="SellerAssigned" /><itemIdentifier itemNumber="024052408584" itemNumberQualifier="UPC" /><itemDescription descriptionValue="STOOL (2/CN)" itemDescriptionQualifier="SellerAssigned" />' + 
            			'</itemInformation><itemReferenceNumber referenceNumberValue="544000899767" referenceNumberQualifier="SerialNumber" /><itemReferenceNumber referenceNumberValue="544000899768" referenceNumberQualifier="SerialNumber" /><itemReferenceNumber referenceNumberValue="1ZE176770313493291" referenceNumberQualifier="TrackingID" /><itemReferenceNumber referenceNumberValue="1ZE176770313493291" referenceNumberQualifier="TrackingID" /><itemReferenceNumber referenceNumberValue="2" referenceNumberQualifier="PurchaseOrderLineNumber" />' + 
            			'<itemQuantity><unitsShipped unitOfMeasure="Each" value="2"><pieceIdentification assignment="SellerAssigned"><pieceIdentificationNumber>00000240520799508571</pieceIdentificationNumber><pieceIdentificationNumber>00000240520799508564</pieceIdentificationNumber></pieceIdentification></unitsShipped></itemQuantity></item></order><order><orderReferenceNumber referenceNumberValue="446304" referenceNumberQualifier="PurchaseOrderNumber" /><orderReferenceNumber referenceNumberValue="{1}" eferenceNumberQualifier="SellerSalesOrderNumber" />' + 
            			'<item><itemInformation><itemIdentifier itemNumber="D440-024" itemNumberQualifier="SellerAssigned" /><itemIdentifier itemNumber="024052408584" itemNumberQualifier="UPC" /><itemDescription descriptionValue="STOOL (2/CN)" itemDescriptionQualifier="SellerAssigned" /></itemInformation><itemReferenceNumber referenceNumberValue="544000899493" referenceNumberQualifier="SerialNumber" /><itemReferenceNumber referenceNumberValue="544000899494" referenceNumberQualifier="SerialNumber" /><itemReferenceNumber referenceNumberValue="1ZE176770313493335" referenceNumberQualifier="TrackingID" />' + 
            			'<itemReferenceNumber referenceNumberValue="1ZE176770313493335" referenceNumberQualifier="TrackingID" /><itemReferenceNumber referenceNumberValue="2" referenceNumberQualifier="PurchaseOrderLineNumber" /><itemQuantity><unitsShipped unitOfMeasure="Each" value="2"><pieceIdentification assignment="SellerAssigned"><pieceIdentificationNumber>00000240520799508625</pieceIdentificationNumber><pieceIdentificationNumber>00000240520799508618</pieceIdentificationNumber></pieceIdentification></unitsShipped></itemQuantity></item>' + 
            			'</order><order><orderReferenceNumber referenceNumberValue="446567" referenceNumberQualifier="PurchaseOrderNumber" /><orderReferenceNumber referenceNumberValue="C998064" referenceNumberQualifier="SellerSalesOrderNumber" /><item><itemInformation><itemIdentifier itemNumber="D440-024" itemNumberQualifier="SellerAssigned" /><itemIdentifier itemNumber="024052408584" itemNumberQualifier="UPC" /><itemDescription descriptionValue="STOOL (2/CN)" itemDescriptionQualifier="SellerAssigned" /></itemInformation><itemReferenceNumber referenceNumberValue="544000899771" referenceNumberQualifier="SerialNumber" />' + 
            			'<itemReferenceNumber referenceNumberValue="544000899772" referenceNumberQualifier="SerialNumber" /><itemReferenceNumber referenceNumberValue="1ZE176770313493380" referenceNumberQualifier="TrackingID" /><itemReferenceNumber referenceNumberValue="1ZE176770313493380" referenceNumberQualifier="TrackingID" /><itemReferenceNumber referenceNumberValue="2" referenceNumberQualifier="PurchaseOrderLineNumber" /><itemQuantity><unitsShipped unitOfMeasure="Each" value="2"><pieceIdentification assignment="SellerAssigned"><pieceIdentificationNumber>00000240520799508687</pieceIdentificationNumber><pieceIdentificationNumber>00000240520799508670</pieceIdentificationNumber></pieceIdentification></unitsShipped></itemQuantity></item></order></shipment></fnASN:advanceShipNotice>';
		xmlRaw = xmlRaw.replaceAll('00000240520799508571', POl.Id + '123');
        xmlRaw = xmlRaw.replaceAll('00000240520799508625', POl.Id + '123');
        xmlRaw = xmlRaw.replaceAll('00000240520799508687', POl.Id + '123');
        xmlRaw = xmlRaw.replaceAll('00000240520799508670', poLI2.Id + '123');
        xmlRaw = xmlRaw.replaceAll('00000240520799508618', poLI2.Id + '123');
        xmlRaw = xmlRaw.replaceAll('00000240520799508564', poLI2.Id + '123');
        
        System.debug('po name - ' + po.Name);   
        xmlRaw = String.format(xmlRaw, new List<String>{po.Name, po.Name});
        return xmlRaw;
    }
    
    static testMethod void PurchaseOrderShipNoticeOne(){
        Test.startTest();
        
        string xmlRaw = PurchaseOrderShipNoticeTestPrepare();
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(xmlRaw);
        request.httpMethod = 'POST';
        RestContext.request = request;
        PurchaseOrderShipNotice.Response res =  PurchaseOrderShipNotice.getPurchaseOrderShipNotice();
        //System.assertEquals(true, res.success);
        
        Test.stopTest();
    }
    
    static testMethod void PurchaseOrderShipNoticeTwo(){
        Test.startTest();
        
        string xmlRaw = PurchaseOrderShipNoticeTestPrepare();
        xmlRaw = xmlRaw.remove(xmlRaw.substringBetween('</itemInformation>', '<itemQuantity>'));
        xmlRaw = xmlRaw.remove(xmlRaw.substringBetween('</itemInformation>', '<itemQuantity>'));
        xmlRaw = xmlRaw.remove(xmlRaw.substringBetween('</itemInformation>', '<itemQuantity>'));
        system.debug('qwe: ' + xmlRaw);
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(xmlRaw);
        request.httpMethod = 'POST';
        RestContext.request = request;
        PurchaseOrderShipNotice.Response res =  PurchaseOrderShipNotice.getPurchaseOrderShipNotice();
        //System.assertEquals(true, res.success);
        
        Test.stopTest();
    }
    
    
    static testMethod void FailedEDIFiles(){
        
        Account ac = TestUtil.createCustomerAccount(); 
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c po = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        po.Ship_From__c = [select Manufacturer_ID__c from EDI_Map__mdt limit 1].Manufacturer_ID__c;
        update po;
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        Test.startTest();
        PurchaseOrderOutboundFrom.sendForm(po.id);
        Test.stopTest();
        po = [SELECT Id,Name FROM Purchase_Order__c WHERE Id = :po.Id];
        Log__c log = [SELECT Id FROM Log__c WHERE Object_ID__c = :po.Id]; 
        log.Status__c = 'Sent';
        update log;
        string xmlRaw = '<furnPO:order xsi:schemaLocation="http://support.furnishnet.com/xml/schemas/FurnPO_v1.8 http://xml.ashleyfurniture.com/xml/schemas/FurnXMLPO_v1.8.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:fnParty="http://support.furnishnet.com/xml/schemas/fnParty_v1.4" xmlns:fnItem="http://support.furnishnet.com/xml/schemas/fnItem_v1.4" xmlns:fnBase="http://support.furnishnet.com/xml/schemas/fnBase_v1.4" xmlns:furnPO="http://support.furnishnet.com/xml/schemas/FurnPO_v1.8" xmlns=""><Order comment=""><document id="{0}" type="850" language="EN"><creationDate>2018-02-11</creationDate></document><actionRequestIndicator description="Create" /><currency>USD</currency><buyer><fnParty:partyIdentifier partyIdentifierCode="3302800" partyIdentifierQualifierCode="ReceiverAssigned" /></buyer><seller><sellerIdentification><fnParty:partyIdentifier partyIdentifierCode="52738531" partyIdentifierQualifierCode="DUNS" /></sellerIdentification></seller><shipTo id=""><fnParty:partyIdentifier partyIdentifierCode="" partyIdentifierQualifierCode="ReceiverAssigned" /><fnParty:partyIdentifier partyIdentifierCode="ASHL" partyIdentifierQualifierCode="SenderAssigned" /></shipTo><markFor id="a0M0S000000g3XqUAI" shippingInstructions="SO-347496"><fnParty:partyIdentifier partyIdentifierCode="" partyIdentifierQualifierCode="ReceiverAssigned" /><fnParty:partyName></fnParty:partyName><fnParty:addressLine></fnParty:addressLine><fnParty:city></fnParty:city><fnParty:stateOrProvince></fnParty:stateOrProvince><fnParty:country></fnParty:country><fnParty:postalCode></fnParty:postalCode><partyContact><electronicContact electronicContactQualifier="EmailAddress" electronicContactValue="" /><telephoneContact telephoneNumberType="Home"><telephoneNumber></telephoneNumber></telephoneContact></partyContact></markFor><shipDates><requestedArrivalDate>2018-03-11</requestedArrivalDate></shipDates><systemReference><systemReferenceDescription>OrderType</systemReferenceDescription><systemReferenceValue>Ship Complete Order</systemReferenceValue></systemReference><systemReference><systemReferenceDescription>Division</systemReferenceDescription><systemReferenceValue></systemReferenceValue></systemReference><systemReference><systemReferenceDescription>TrackingID</systemReferenceDescription><systemReferenceValue></systemReferenceValue></systemReference><systemReference><systemReferenceDescription>ConsumerDeliveryDate</systemReferenceDescription><systemReferenceValue>Ship Complete Order</systemReferenceValue></systemReference><systemReference><systemReferenceDescription>Warehouse</systemReferenceDescription><systemReferenceValue></systemReferenceValue></systemReference><systemReference><systemReferenceDescription>ShipmentServiceLevel</systemReferenceDescription><systemReferenceValue></systemReferenceValue></systemReference></Order><Line lineItemNumber="1" comment="POL-4134"><productID><itemIdentifier itemNumber="Kin-000-c891fec7fed6d485415adb6db622034a4" itemNumberQualifier="SellerAssigned" /><itemIdentifier itemNumber="Kin-000-c891fec7fed6d485415adb6db622034a4" itemNumberQualifier="BuyerAssigned" /><itemDescription descriptionValue="" itemDescriptionQualifier="BuyerAssigned" /></productID><requestedQuantity unitOfMeasure="Each" value="1"><shipToLocation quantity="" shipToID="" arrivalDate=""><markForLocation quantity="" markForID="a0D0S000000taoPUAQ" /></shipToLocation><pieceIdentification assignment="BuyerAssigned"><pieceIdentificationNumber>0</pieceIdentificationNumber></pieceIdentification></requestedQuantity><unitPrice><discount><discountOrAllowanceAmount>0.00</discountOrAllowanceAmount><discountOrAllowancePercent chargeOrAllowancePercent="0" chargeOrAllowanceQualifier="ItemListCost" /><discountOrAllowanceDescription></discountOrAllowanceDescription></discount><surcharge><additionalChargeAmount>0</additionalChargeAmount><additionalChargeDescription></additionalChargeDescription></surcharge><price>0.00</price></unitPrice></Line></furnPO:order>';
        xmlRaw = String.format(xmlRaw, new List<String>{po.Name});
        RestRequest request = new RestRequest();
        request.requestBody = Blob.valueOf(xmlRaw);
        request.httpMethod = 'POST';
        RestContext.request = request;
        FailedEDIFiles.getFailed();
        System.assertEquals(1, [select ID, Status__c from Log__c where Object_ID__c = :po.id and Status__c = 'Failed'].size());
        System.assertEquals(1, [select id, EDI_Status__c from Purchase_Order__c where name = :po.Name AND EDI_Status__c = 'Failed'].size());
    }    
}