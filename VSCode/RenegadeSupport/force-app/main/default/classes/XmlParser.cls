public class XmlParser {
	XmlStreamReader xmlReader;   
    
    public XmlParser(XmlStreamReader xmlReader){
        this.xmlReader = xmlReader;
    }
    
    public Boolean moveToXmlTag(String tagName, Integer stepsLimit){
        Boolean result = false;
        Boolean isSafeToGetNextXmlElement = true;
        Integer steps = 0;
        while (isSafeToGetNextXmlElement) {
            if(stepsLimit > 0 && steps > stepsLimit){
                break;
            }
            if (xmlReader.getEventType() == XmlTag.START_ELEMENT) {
                ++steps;
                if (tagName == xmlReader.getLocalName()) {
                    result = true;
                    isSafeToGetNextXmlElement = false;
                    break;
                }
            }
            if (xmlReader.hasNext() && isSafeToGetNextXmlElement) {
                xmlReader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
            
        }
        return result;
    }
    
    public String getXmlTagValue(){
        String result;
        Boolean isSafeToGetNextXmlElement = true;
        while (isSafeToGetNextXmlElement) {
            if (xmlReader.getEventType() == XmlTag.CHARACTERS) {
                result = xmlReader.getText();
                isSafeToGetNextXmlElement = false;
                break;
            }
            
            if (xmlReader.hasNext() && isSafeToGetNextXmlElement) {
                xmlReader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return result;
    }

    public static String obtainValue(String xmlInput, List<ParserSetting> parserRulesList) {
        String result;
        XmlStreamReader xmlReader = new XmlStreamReader(xmlInput);
        XmlParser parser = new XmlParser(xmlReader);
        boolean isSafeToGetNextXmlElement = true;

        while (isSafeToGetNextXmlElement) {
            Integer steps = parserRulesList.size();
            String buffValue;
            for(ParserSetting currentRule_i : parserRulesList){
                --steps;
                if(!currentRule_i.isConditionValue){
                    if(!parser.moveToXmlTag(currentRule_i.tagName, currentRule_i.searchLimit)){
                        break;
                    }
                } else if( currentRule_i.tagValueCondition != (buffValue = parser.getXmlTagValue())) {
                    break;
                } 
            }

            if(steps == 0) {
                isSafeToGetNextXmlElement = false;
                result = parser.getXmlTagValue();
            }

            if (xmlReader.hasNext() && isSafeToGetNextXmlElement) {
                xmlReader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return result;
    }

    public class ParserSetting {
        public String tagName;
        public Integer searchLimit;
        public Boolean isConditionValue;
        public String tagValueCondition;

        public ParserSetting(String tagName, Integer searchLimit) {
            this.tagName = tagName;
            this.searchLimit = searchLimit;
            this.tagValueCondition = tagValueCondition;
            this.isConditionValue = false;
        }

        public ParserSetting(String tagValueCondition) {
            this.tagValueCondition = tagValueCondition;
            this.isConditionValue = true;
        }
    }
}