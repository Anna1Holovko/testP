global class ETACalculatorController {
	@InvocableMethod(label='Calculate ETA')
    global static List<OutputParameters> calculate(List<InputParameters> inputList) {
        InputParameters input = inputList[0];
        OutputParameters result =  calculate(input.accountId, input.zipCode, input.loadDate);
        
        return new List<OutputParameters>{ result };
    }
    
    global static OutputParameters calculate(Id accountId, String zipCode, Date loadDate) {
        OutputParameters result = new OutputParameters();
        Date resultDate = loadDate;
        String fieldName = [SELECT ETA_group__c FROM Account WHERE Id =: accountId LIMIT 1].ETA_group__c;
        if (string.isNotEmpty(fieldName)) {
            String query = 'SELECT ' + fieldName + ' FROM Shipping_Zip_Codes__c WHERE Zip_Code__c = \'' + zipCode + '\' LIMIT 1';
            List<Shipping_Zip_Codes__c> shippingZipCodeList = Database.query(query);
            if (shippingZipCodeList.isEmpty()) {
                return null;
            }
            result.zoneXEtaGroup = (String)shippingZipCodeList[0].get(fieldName);
            if (string.isEmpty(result.zoneXEtaGroup)) {
                return null;
            }
            if (result.zoneXEtaGroup.contains('Week')) {
                Integer weeksToAdd = 0;
                if (result.zoneXEtaGroup.contains('-')) {
                    weeksToAdd = Integer.valueOf(result.zoneXEtaGroup.substringAfter('- ').substringBefore(' W'));
                }
                else {
                    weeksToAdd = Integer.valueOf(result.zoneXEtaGroup.substringBefore(' W'));
                }
                resultDate = resultDate.addDays(7 * weeksToAdd);
            }
        }
        Decimal days = Date.today().daysBetween(resultDate);
        Integer weeks = (Integer)(days/7).round(System.RoundingMode.UP);

        result.resultDate = resultDate;
        result.zoneXEtaGroup = weeks + ' weeks';
        return result;
    }
    
    global class OutputParameters {
        @InvocableVariable
        global Date resultDate;
        @InvocableVariable
        global String zoneXEtaGroup;
    }
    
    global class InputParameters {
        @InvocableVariable
        global Id accountId;
        @InvocableVariable
        global String zipCode;
        @InvocableVariable
        global Date loadDate;
        
    }
}