/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : MFOverdueANDOnOrderSchedulableHelper
*   Purpose: This helper class is used to get the count of On Order and Overdue based on manufacturer on purchase Order and send Notification to Manufacturer email.
*/
global class MFOverdueANDOnOrderSchedulableHelper 
{
    global static void updateonOrderAndOverdueCount(Set<id> poList)
    { 
        Set<id> manufacturerId = new Set<id>();        
        try 
        {            
            for(Purchase_Order__c PO : [Select id,Ship_From__c from Purchase_Order__c where id = :poList AND Status__c = 'On Order']) 
            {
                manufacturerId.add(PO.Ship_From__c);
            }
            System.debug('manufacturerId: '+manufacturerId);
            
            String templateName = '%OverDue And Open Order Notification';
            EmailTemplate template = [select Id,Name,Subject,body from EmailTemplate where name like :templateName+'%' limit 1];
            
            updateContactAndsendEmail(manufacturerId,poList,template.id);
        }
        catch(Exception e) 
        {
            system.debug('EXception: Line Number: '+e.getLineNumber()+', messsage: ' +e.getMessage()+', Cause: '+e.getCause());
        }
    }
    
    @future
    global static void updateContactAndsendEmail(set<id> manufacturerId,Set<Id> poList, Id templateId) 
    {
        List<Contact> updateContact = new List<Contact>();
        List<Id> contactIds = new List<Id>();
        
        try 
        {
            for(Contact con : [Select id,Account.Name,AccountId,Total_On_Order__c,Total_Overdue__c,Email from Contact where AccountId=:manufacturerId AND Email != null]) 
            {
                integer onOrder=0;
                integer overDue=0;
                
                for(Purchase_Order__c  po: [Select id,Load_Date__c,Tracking_Number__c,Load_Date_Actual__c  from Purchase_Order__c where id In :poList AND Ship_From__c=:con.AccountId])
                {
                    if(po.Load_Date_Actual__c < System.today())
                    {
                        overDue=overDue+1;
                    }
                    if(po.Tracking_Number__c != null) {
                        onOrder=onOrder+1;
                    }
                }
                con.Total_On_Order__c=onOrder;
                con.Total_Overdue__c=overDue;
                
                System.debug('Manufacturer Account: '+con.Account.Name);
                updateContact.add(con);
                contactIds.add(con.id);
            }
            System.debug('updateContact: '+updateContact);
            if(updateContact.size() > 0 && updateContact != null) 
            {
                update updateContact; 
                                
                Messaging.MassEmailMessage mail = new Messaging.MassEmailMessage();
                mail.saveAsActivity = false;
                
                mail.setTargetObjectIds(contactIds);
                mail.setTemplateId(templateId);
                
                mail.setUseSignature(false);
                mail.setSaveAsActivity(false);
                
                // Send the email
                Messaging.sendEmail(new Messaging.MassEmailMessage[] { mail });
            }
        }
        catch(Exception e) 
        {
            system.debug('EXception: Line Number: '+e.getLineNumber()+', messsage: ' +e.getMessage()+', Cause: '+e.getCause());
        }
    }
}