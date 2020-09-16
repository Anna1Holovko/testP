public with sharing class PopulateAccountRenegadeWebsiteBatch {
    static void populateRenegadeWebsite(){
        //List<Account> accountWithEmptyRenegadeWebsiteList = [SELECT Id, Web_Site__c FROM Account WHERE Web_Site__c != null AND Renegade_Website__c == null];
        Map<String, WebsiteId_To_Website_Name_Setting__c> websiteIdToWebsiteNameMap = WebsiteId_To_Website_Name_Setting__c.getAll();
        List<Account> accountToUpdateList = new List<Account>();
        for(Account currentAccount_i : [SELECT Id, Web_Site__c FROM Account WHERE Web_Site__c != null AND Renegade_Website__c = null]){
            if(websiteIdToWebsiteNameMap.containsKey(currentAccount_i.Web_Site__c)){
                currentAccount_i.Renegade_Website__c = websiteIdToWebsiteNameMap.get(currentAccount_i.Web_Site__c).Website_Name__c;
                accountToUpdateList.add(currentAccount_i);
            }
        } 
        update accountToUpdateList;
    }
}