public with sharing class TrackingServiceFedEx extends IShipmentTrackingService {
    private final String METHOD = 'POST';
    Tracking_Service_FedEx__c settings = Tracking_Service_FedEX__c.getOrgDefaults();
    
    public String obtainEndpoint() {
        return settings.Endpoint__c;
    }

    public Map<String, String> obtainHeaders() {
        Map<String, String> headers = new Map<String, String>();
        headers.put('Content-Type', 'text-xml');
        return headers;
    }

    public String obtainMethod() {
        return METHOD;
    }

    public ResponseWrapperTrackingService parseResponse(String input) {
        ResponseWrapperTrackingService responseWrapper = new ResponseWrapperTrackingService();
        responseWrapper.stringDate =  obtainScheduleDate(input);
        responseWrapper.scheduleDate = parseStringToDate( responseWrapper.stringDate);
        responseWrapper.deliveryStatus = obtainStatus(input);
        responseWrapper.actualDeliveryDate = obtainActualDeliveryDate(input);
        responseWrapper.errorMessage = obtainErrorMessage(input);
        return responseWrapper;
    }

    String formatDate(String unformattedDate) {
        return unformattedDate != null ? unformattedDate.substring(0, 10).replaceAll('-','') : null;
    }

    String obtainStatus(String xmlInput){
        return XmlParser.obtainValue(xmlInput, new List<XmlParser.ParserSetting> {new XmlParser.ParserSetting('StatusDetail', -1), new XmlParser.ParserSetting('Description', 3)} );
    }

    String obtainErrorMessage(String xmlInput){
        return XmlParser.obtainValue(xmlInput, new List<XmlParser.ParserSetting> {new XmlParser.ParserSetting('TrackDetails', -1), new XmlParser.ParserSetting('Notification', 2), new XmlParser.ParserSetting('Message', 5)} );
    }

    String obtainScheduleDate(String xmlInput) {
        return formatDate(XmlParser.obtainValue(xmlInput, new List<XmlParser.ParserSetting> {new XmlParser.ParserSetting('DatesOrTimes', -1), new XmlParser.ParserSetting('Type', 2), new XmlParser.ParserSetting('ESTIMATED_DELIVERY'), new XmlParser.ParserSetting('DateOrTimestamp', 2)} ) );
    }

    Date obtainActualDeliveryDate(String xmlInput){
        String stringDate = formatDate( XmlParser.obtainValue(xmlInput, new List<XmlParser.ParserSetting> {new XmlParser.ParserSetting('DatesOrTimes', -1), new XmlParser.ParserSetting('Type', 2), new XmlParser.ParserSetting('ACTUAL_DELIVERY'), new XmlParser.ParserSetting('DateOrTimestamp', 2)} ));
        return parseStringToDate(stringDate);
    }

    public String obtainBody() {
        Dom.Document doc = new Dom.Document();
		doc.createRootElement('soapenv:Envelope', '', '');
        Dom.XmlNode node = doc.getRootElement();
        node.setAttribute('xmlns:urn', 'urn:enterprise.soap.sforce.com');
        node.setAttribute('xmlns:soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
        node.setAttribute('xmlns:v16', 'http://fedex.com/ws/track/v16'); {
            node.addChildElement('soapenv:Header', '', '');

            Dom.XmlNode bodyNode = node.addChildElement('soapenv:Body', '', '');

            Dom.XmlNode trackRequestNode = bodyNode.addChildElement('v16:TrackRequest', '', ''); {
                Dom.XmlNode webAuthDetailNode = trackRequestNode.addChildElement('v16:WebAuthenticationDetail', '', ''); {
                    Dom.XmlNode parentCredentialNode = webAuthDetailNode.addChildElement('v16:ParentCredential', '', ''); {
                        Dom.XmlNode keyNode = parentCredentialNode.addChildElement('v16:Key', '', '');
                        Dom.XmlNode passwordNode = parentCredentialNode.addChildElement('v16:Password', '', '');
                    }

                    Dom.XmlNode userCredentialNode = webAuthDetailNode.addChildElement('v16:UserCredential', '', ''); {
                        Dom.XmlNode keyNode = userCredentialNode.addChildElement('v16:Key', '', '');
                        keyNode.addTextNode(settings.Key__c);

                        Dom.XmlNode passwordNode = userCredentialNode.addChildElement('v16:Password', '', '');
                        passwordNode.addTextNode(settings.Password__c);
                    }
                }
                Dom.XmlNode clientDetailNode = trackRequestNode.addChildElement('v16:ClientDetail', '', ''); {
                    Dom.XmlNode accountNumberNode = clientDetailNode.addChildElement('v16:AccountNumber', '', '');
                    accountNumberNode.addTextNode(settings.AccountNumber__c);

                    Dom.XmlNode meterNumberNode = clientDetailNode.addChildElement('v16:MeterNumber', '', '');
                    meterNumberNode.addTextNode(settings.MeterNumber__c);
                }
                Dom.XmlNode transactionDetailNode = trackRequestNode.addChildElement('v16:TransactionDetail', '', ''); {
                    Dom.XmlNode customerTransactionIdNode = transactionDetailNode.addChildElement('v16:CustomerTransactionId', '', '');
                    customerTransactionIdNode.addTextNode(this.trackingNumber);

                    Dom.XmlNode localizationNode = transactionDetailNode.addChildElement('v16:Localization', '', ''); {
                        Dom.XmlNode languageCodeNode = localizationNode.addChildElement('v16:LanguageCode', '', '');
                        languageCodeNode.addTextNode('EN');

                        Dom.XmlNode localeCodeNode = localizationNode.addChildElement('v16:LocaleCode', '', '');
                        localeCodeNode.addTextNode('US');
                    }
                }
                Dom.XmlNode versionNode = trackRequestNode.addChildElement('v16:Version', '', ''); {
                    Dom.XmlNode serviceIdNode = versionNode.addChildElement('v16:ServiceId', '', '');
                    serviceIdNode.addTextNode('trck');

                    Dom.XmlNode majorNode = versionNode.addChildElement('v16:Major', '', '');
                    majorNode.addTextNode('16');

                    Dom.XmlNode intermediateNode = versionNode.addChildElement('v16:Intermediate', '', '');
                    intermediateNode.addTextNode('0');

                    Dom.XmlNode minorNode = versionNode.addChildElement('v16:Minor', '', '');
                    minorNode.addTextNode('0');
                }
                Dom.XmlNode selectionDetailsNode = trackRequestNode.addChildElement('v16:SelectionDetails', '', ''); {

                    Dom.XmlNode packageIdentifierNode = selectionDetailsNode.addChildElement('v16:PackageIdentifier', '', ''); {
                        Dom.XmlNode typeNode = packageIdentifierNode.addChildElement('v16:Type', '', '');
                        typeNode.addTextNode('TRACKING_NUMBER_OR_DOORTAG');

                        Dom.XmlNode valueNode = packageIdentifierNode.addChildElement('v16:Value', '', '');
                        valueNode.addTextNode(trackingNumber);
                    }

                    selectionDetailsNode.addChildElement('v16:ShipmentAccountNumber', '', '');

                    selectionDetailsNode.addChildElement('v16:SecureSpodAccount', '', '');

                    Dom.XmlNode processingOptionsNode = trackRequestNode.addChildElement('v16:ProcessingOptions', '', ''); {
                        processingOptionsNode.addTextNode('INCLUDE_DETAILED_SCANS');
                    }
                }
            }
        }

        return doc.toXmlString().remove('<?xml version="1.0" encoding="UTF-8"?>');
    }
}