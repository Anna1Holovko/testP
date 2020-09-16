global class OrderNotificationBatch implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
    String query;
    List<Database.SaveResult> srList = new List<Database.SaveResult>();
    Map<String, OrgWideEmailAddress> ordEmailMap ;
    
    global OrderNotificationBatch() {
        query = 'SELECT Id, Purchase_Order_ETA__c, Carrier__c, Customer_Website__c, Nearest_Delivery_Company__c, Customer_Email__c, Customer_Email_initial__c, Sales_Order__c,Sales_Order__r.Email__c, Send_ETA_Notification__c FROM Purchase_Order__c ' +(Test.isRunningTest() == false?' WHERE Send_ETA_Notification__c = true':'');
        ordEmailMap = new Map<String, OrgWideEmailAddress>();
        for(OrgWideEmailAddress orgEmail_i : [select id, Address, DisplayName from OrgWideEmailAddress]){
            ordEmailMap.put(orgEmail_i.Address, orgEmail_i);     
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        System.debug('Start');
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Purchase_Order__c> scope) {
        System.debug('scope: ' + scope);
        set<string> soIds = new set<string>();
        //System.debug('setting: ' + (Customer_ETA_Notifications__c.getAll().get('Email_Template__c').Value__c));
        List<Weekly_order_update_email__c> emailSetting = Weekly_order_update_email__c.getAll().Values();
        List<String> relatedEmails = new  List<String>();        
       // Map<Boolean, String> emailMap = new  Map<Boolean, String> ();
        for(Weekly_order_update_email__c setting_i : emailSetting){
            relatedEmails.add(setting_i.TemplateName__c);
        //    emailMap.put(setting_i.isFedex__c, setting_i.TemplateName__c);
        }
        Map<String, Id> templateMap = new Map<String, Id>();
        for(EmailTemplate template_i: [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :relatedEmails]){
            templateMap.put(template_i.DeveloperName, template_i.Id);
        }
        
        /*List<EmailTemplate> emailList = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'SF_ord_10dayETA_cnfrm_m' or DeveloperName = 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_m' or DeveloperName = 'Salesforce_ordered_10dayETA_FedE']; //SF_ord_10dayETA_cnfrm_m   
        Map<String, Id> templateMap = new Map<String, Id>();
        for(EmailTemplate email_i : emailList){
            if(email_i.DeveloperName == 'SF_ord_10dayETA_cnfrm_m'){
                templateMap.put('Coleman', email_i.Id);
            }
            if(email_i.DeveloperName == 'ETC_SF_Ash_arrvd_dt_dlvr_WG_cnfrm_m'){
                templateMap.put('Ashley', email_i.Id);
            }
             if(email_i.DeveloperName == 'Salesforce_ordered_10dayETA_FedE'){
                templateMap.put('Coleman_Fedex', email_i.Id);
            }
        }*/
        List<EmailMessage> emailMsgList = new List<EmailMessage>();
        List<Purchase_Order__c> orderToUpdate = new List<Purchase_Order__c>();
        List<Messaging.SingleEmailMessage> emailArray = new List<Messaging.SingleEmailMessage>();

        for(Purchase_Order__c order: scope) {
                soIds.add(order.Sales_Order__c);
                System.debug('order: ' + order);
                Id emailTemplateId = null;
                OrgWideEmailAddress orgEmail = null;
                
                
                if(order.Customer_Website__c == '2'){
                // emailTemplateId = templateMap.get('Coleman');
                    //emailTemplateId = templateMap.get('Ashley');
                    orgEmail = ordEmailMap.get('updates@furnitureetc.com');
                }else if(order.Customer_Website__c == '3'){
                    //emailTemplateId = templateMap.get('Coleman');
                    //emailTemplateId = templateMap.get('Ashley');
                    orgEmail = ordEmailMap.get('updates@homegallerystores.com');
                }else{
                    //emailTemplateId = templateMap.get('Coleman');
                    orgEmail = ordEmailMap.get('updates@colemanfurniture.com');
                }
                Boolean isLongETA = checkIsLongETA(order.Purchase_Order_ETA__c);
                for(Weekly_order_update_email__c emailSettings: emailSetting){
                    if(emailSettings.isFedex__c == (order.Carrier__c != null) && emailSettings.Is_long_ETA__c == isLongETA){
                        emailTemplateId = templateMap.get(emailSettings.TemplateName__c);
                    }
                }
            // emailTemplateId = templateMap.get(emailMap.get(order.Carrier__c != null));
            if(emailTemplateId != null){
                Messaging.SingleEmailMessage mailCandidate = Messaging.renderStoredEmailTemplate(emailTemplateId, null, order.Id);
                
                
                mailCandidate.setSaveAsActivity(false);
                mailCandidate.setToAddresses(new List<String> {order.Customer_Email_initial__c});
                mailCandidate.setSaveAsActivity(true);
                mailCandidate.setOrgWideEmailAddressId(orgEmail.Id);
                emailArray.add(mailCandidate);
                
                order.Last_ETA_Update__c = Date.today();
                order.Manual_override_Send_ETA_to_customer__c = false;
                orderToUpdate.add(order);
                
                EmailMessage msg = new EmailMessage();
                msg.Status = 'Sent';
                msg.RelatedToId = order.Sales_Order__c;
                msg.Subject = mailCandidate.Subject;
                if(mailCandidate.HtmlBody != null) {
                    msg.HtmlBody = mailCandidate.HtmlBody;
                }else {
                    msg.HtmlBody = mailCandidate.PlainTextBody;
                }
                msg.ToAddress = order.Customer_Email_initial__c;
                msg.FromAddress = orgEmail.Address;
                msg.FromName = orgEmail.DisplayName;
                emailMsgList.add(msg);
            }
        }
        if(!Test.isRunningTest()) {
            Messaging.sendEmail(emailArray);
        }
        
        Database.SaveResult[] srScopeList = Database.update(orderToUpdate, false);
        srList.addAll(srList);
        
        list<Task> tasksToInsert = new list<Task>();
        for (string str : soIds){
            Task taskObj = new task();
            taskObj.status = 'Completed'; 
            taskObj.WhatId = str;
            tasksToInsert.add(taskObj);
        }
        insert tasksToInsert;
        
    }
    
    global void finish(Database.BatchableContext BC) {
        if(srList.isEmpty()){
            String errorHeader = 'Hello! After update Purchase Order there were errors: \n';
            String errMsg = '';
            for(Database.SaveResult result_i: srList) {
                if(result_i.getErrors().size() >0){
                    for(Database.Error error_i : result_i.getErrors()){
                        errMsg += error_i.getMessage() + '\n';
                    } 
                }
            }
            if(String.isNotEmpty(errMsg) || Test.isRunningTest()){
                System.debug('errMsg: ' + errMsg);
                User currentUSer = [SELECT Id, Email FROM User WHERE Id = :UserInfo.getUserId()];
                System.debug('currentUSer: ' + currentUSer.Email);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.toAddresses = new String[] {currentUSer.Email};
                    message.subject = 'Errors after update';
                message.plainTextBody = errorHeader + ' ' + errMsg;
                Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
                    Messaging.sendEmail(messages);
            }
            
        }
    }
    
    global void execute(SchedulableContext sc) {
        OrderNotificationBatch b = new OrderNotificationBatch();
        Database.executebatch(b, 30);
    }
    
    private Integer parseETA(String purchaseOrderETA){
        if (purchaseOrderETA != null){
        Pattern p = Pattern.compile('(^|\\s)([0-9]+)($|\\s)');
        Matcher m = p.matcher(purchaseOrderETA);
        if (m.find()) {
            return Integer.valueOf(m.group().trim());
        } else{
            return null;
        } 
        } else{
            return null;
        }                  
    }
    private Boolean checkIsLongETA(String purchaseOrderETA){
        Integer relatedWheek = parseETA(purchaseOrderETA);
        if(relatedWheek != null){
            return (relatedWheek > 5? true:false);
        } else{
            return false;
        }           
    }
    
    
}