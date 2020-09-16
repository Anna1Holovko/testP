public class EmailManager {
    public static void send(String errorText, String emailListGroup) {
        List<String> emailList = new List<String>();
        ErrorMailingSettings__c ems = ErrorMailingSettings__c.getValues(emailListGroup);
        if (ems != null && string.isNotEmpty(ems.EmailList__c)) {
            for (String email_i : ems.EmailList__c.split(';')) {
                emailList.add(email_i);
            }
        }
        if (emailList.isEmpty()) {
            emailList.add(UserInfo.getUserEmail());
        }
        send(emailList, errorText);
    }
    
    public static void send(List<String> emailList, String errorText) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(emailList);
        
        email.setSubject('Errors Report');
        
        email.setHtmlBody(errorText);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}