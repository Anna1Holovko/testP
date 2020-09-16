global class EmailCaseHandler implements QuickAction.QuickActionDefaultsHandler{
    Map<String, List<Setting>> actionNameToSettingMap;
    global EmailCaseHandler() {
        this.actionNameToSettingMap = new Map<String, List<Setting>>();
        for(Case_Email_Override_Setting__mdt setting_i : [SELECT Email_Action_Name__c, Rule__c FROM Case_Email_Override_Setting__mdt]){
            List<Setting> caseSettingList = (List<Setting>) JSON.deserialize(setting_i.Rule__c, List<Setting>.class);
            actionNameToSettingMap.put(setting_i.Email_Action_Name__c, caseSettingList);
        }
    }
        // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
        Map<QuickAction.SendEmailQuickActionDefaults, List<Setting>> emailActionToSettingMap = new Map<QuickAction.SendEmailQuickActionDefaults, List<Setting>> ();
        
        for(QuickAction.QuickActionDefaults action_i : defaults){
            if( action_i instanceof QuickAction.SendEmailQuickActionDefaults && 
                action_i.getTargetSObject().getSObjectType() == EmailMessage.sObjectType && 
                actionNameToSettingMap != null && actionNameToSettingMap.containsKey(action_i.getActionName()) && 
                action_i.getActionType().contains('Email')){
                    emailActionToSettingMap.put( (QuickAction.SendEmailQuickActionDefaults)action_i,  actionNameToSettingMap.get(action_i.getActionName()));
            }
        }
        if(emailActionToSettingMap.size() > 0){
            for(QuickAction.SendEmailQuickActionDefaults emailAction : emailActionToSettingMap.keySet()){
                this.overrideCaseEmailField(emailAction, emailActionToSettingMap.get(emailAction));
            }
        }
    }
    

    private void overrideCaseEmailField(QuickAction.SendEmailQuickActionDefaults sendEmailDefaults, List<Setting> settingList){
        Set<String> fieldSet = new Set<String>();
        Map<String, List<Rule>> emailFieldToRulesMap = new Map<String, List<Rule>>();
        for(Setting setting_i : settingList){
            for(Rule rule_i : setting_i.rules){
                if(String.isNotEmpty(rule_i.caseField)){
                    fieldSet.add(rule_i.caseField);
                }
                if(rule_i.isFromField == true && String.isNotEmpty(rule_i.setValue)){
                    fieldSet.add(rule_i.setValue);
                }
            }
            emailFieldToRulesMap.put(setting_i.emailField, setting_i.rules);
        }

        String query = 'SELECT Id, ' + String.join(new List<String>(fieldSet), ', ') + ' FROM Case WHERE Id =\'' + sendEmailDefaults.getContextId() +'\'';
        List<Case> caseList = DataBase.query(query);
        if(caseList.size() > 0){
            Case currentCase = caseList.get(0);
            EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject(); 
            for(String emailField_i : emailFieldToRulesMap.keySet()){
                Rule defaultRule = null;   
                Boolean isSet = false;
                for(Rule rule_i : emailFieldToRulesMap.get(emailField_i)){
                    if(rule_i.isDefault){
                        defaultRule = rule_i;
                    }
                    isSet = updateEmailField(currentCase, rule_i, emailField_i, emailMessage);
                    
                }
                if(isSet == false && defaultRule != null){
                    updateEmailField(currentCase, defaultRule, emailField_i, emailMessage);
                }
            }
        }

    }

    private Boolean updateEmailField(sObject currentObject, Rule rule, String emailField, EmailMessage emailMessage ) {
        Boolean isSet = false;
        String caseFieldValue = '';
        if(rule.caseField != null){
            caseFieldValue = this.getFieldValuefromObjRec(rule.caseField, currentObject);
        }
        if(rule.isFromField != null && rule.isFromField){
            
            String setValue = this.getFieldValuefromObjRec(rule.setValue, currentObject); 
            if( ((String.isNotEmpty(caseFieldValue) && caseFieldValue == rule.equalValue) || (String.isEmpty(caseFieldValue))) && String.isNotEmpty(setValue) ){
                emailMessage.put(emailField, setValue);
                isSet = true;
            }
        }else if((String.isNotEmpty(caseFieldValue) && caseFieldValue == rule.equalValue)){
            emailMessage.put(emailField, rule.setValue);
            isSet = true;
        }
        return isSet;
    }

    private string getFieldValuefromObjRec(string objField,sObject sObj) {
        String res = '';
        if(!objField.contains('.')) {
            if(sObj.get(objField) != null) {
                res = string.valueOf(sObj.get(objField));
            }
            return res;
        } else {
            if(sObj.getSObject(objField.substringBefore('.')) != null) {
                return getFieldValuefromObjRec(objField.substringAfter('.').trim(), sObj.getSObject(objField.substringBefore('.').trim()));
            }
        }
        
        return res;
    }

    class Setting{
        public String emailField { get; set; }
        public List<Rule> rules { get; set; }
    }
    class Rule{
        public String caseField { get; set; }
        public String equalValue { get; set; }
        public String setValue { get; set; }
        public Boolean isDefault { get; set; }
        public Boolean isFromField { get; set; }
    }
}