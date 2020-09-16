/*
*   Author : Vishnu Bijjula and Pavan Vuppala | Kairos Tech
*   Class  : ManufacturerResponseEmailHandler
*   Purpose: This class is to Handle Email Communication for PO Manufacturer and Case Communication Email.
*/
global class ManufacturerResponseEmailHandler implements Messaging.InboundEmailHandler  
{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        try
        {
            Purchase_Order__c POVar = new Purchase_Order__c();
            Case CaseVar = new Case();
            
            EmailMessage emailMsg = new EmailMessage(); 
            
            // Creating Activity History            
            Task taskObj=new Task();
            list<string> ls=new list<String>();
            String myPlainText= '';
            String emailsubject= '';
            String fromAddress= '';
            string replyto='';
            
            // Add the email plain text into the local variable
            emailsubject= email.subject;
            System.debug('emailsubject: '+emailsubject);
            
            fromAddress= email.fromAddress;
            myPlainText= email.plainTextBody;
            ls=email.references;
            replyto=email.inReplyTo;
            string msgid=email.messageId;
            
            Pattern pattervar = Pattern.compile('((PO-)\\d{6})');
            System.debug('pattervar: '+pattervar);
            
            Matcher matchrvar = pattervar.matcher(emailsubject);
            System.debug('matchrvar: '+matchrvar);
            Boolean isMatchFound = matchrvar.find();
            System.debug('isMatchFound: '+isMatchFound);
            
            if(isMatchFound == true) {
                //if(matchrvar.matches()) {
                System.debug('************Purchase Order**************');
                string PoNumber = matchrvar.group(1);
                System.debug('PoNumber: '+PoNumber);
                PoNumber=PoNumber.trim();
                system.debug('matchrvar.group(2)---'+matchrvar.group(2)+'-----matchrvar.group(1)---'+matchrvar.group(1));
                
                //list<string> PoNumber=emailsubject.split(' ');
                POVar = [select id,Email_Response__c,name,Manufacturer_Name__c,LastModifiedDate,Ship_From__c,CreatedById from Purchase_Order__c where name=:PoNumber limit 1];
                System.debug('POVar: '+POVar);
                
                Contact contactvar=[select id from contact where accountid=:povar.Ship_From__c limit 1];
                System.debug('contactvar: '+contactvar);
                taskObj.Subject = 'Manufacturer Email Response Received.';
                taskObj.Description = POVar.Manufacturer_Name__c +' has replied to PO '+povar.name+' at'+system.Datetime.now();
                
                POVar.Response_Received__c=true;
                update POVar;
                
                taskObj.OwnerId = POVar.CreatedById;
                taskObj.Status='Open';
                taskObj.Description=myPlainText;
                taskObj.Priority='High';
                taskObj.WhatId=POVar.id;
                taskObj.WhoId=contactvar.id;
                taskObj.ReminderDateTime=POVar.LastModifiedDate;
                
                insert taskObj;
                
                // Creating note
                note n = new note();
                
                n.parentId=poVar.id; //Id of the opportunity for which you want to add this note
                n.body=myPlainText; // body of the note. this should be populated from the notes field that you have shown in the screenshot
                n.title=povar.name+'_'+povar.Manufacturer_Name__c+'_'+system.Datetime.now(); // the title of the note
                
                insert n; //insert the record
            }
            else
            {
                System.debug('************Case Object**************');
                
                Pattern casepattervar = Pattern.compile('(\\d{8})');
                System.debug('casepattervar: '+casepattervar);
                
                Matcher casematchrvar = casepattervar.matcher(emailsubject);
                System.debug('casematchrvar: '+casematchrvar);
                
                Boolean isMatchFound1 = casematchrvar.find();
                System.debug('isMatchFound1: '+isMatchFound1);
                
                if(isMatchFound1 == true)
                {
                    System.debug('casematchrvar: '+casematchrvar.group(1));
                    string CNumber = casematchrvar.group(1);
                    CNumber = CNumber.trim();
                    //system.debug('matchrvar.group(2)---'+matchrvar.group(2)+'-----matchrvar.group(1)---'+matchrvar.group(1));
                    
                    System.debug('CNumber: '+CNumber);
                    CaseVar = [select id,Subject,Priority,OwnerId,Description,LastModifiedDate from Case where CaseNumber=:CNumber limit 1];
                    System.debug('Case : '+CaseVar);
                    
                    //emailMsg.FromAddress = 'support@kairostech.com';
                    emailMsg.FromAddress = email.fromAddress;
                    emailMsg.FromName = email.fromName;
                    emailMsg.ToAddress = email.toAddresses[0];
                    emailMsg.Subject = email.subject;
                    emailMsg.HtmlBody = email.htmlBody;
                    emailMsg.TextBody = email.plainTextBody;
                    emailMsg.ParentId = CaseVar.id;
                    
                    emailMsg.Status = '2';
                    
                    if(emailMsg != Null) {
                        insert emailMsg;
                        
                        //Map<Id,user> userroleIds = new Map<id,user>();
                        //Map<Id,Group> GroupIds = new Map<id,Group>([SELECT DeveloperName,Id,Name,OwnerId,RelatedId,Type FROM Group]);
                        Map<Id,user> userIds = new Map<id,user>([select id,UserRoleId from user where Profile.UserLicense.Name='Salesforce']);
                        System.debug('userIds: '+userIds);
                        //for(User oneUser :userIds.values()) {
                       //     userroleIds.put(oneUser.UserRoleId, oneUser);
                        //}
                        
                        if(CaseVar.OwnerId != Null) {
                            List<Task> taskList = new List<Task>();
                            if(userIds.containsKey(CaseVar.OwnerId)) {
                                Task oneTask = new Task();
                                
                                oneTask.WhatId = CaseVar.id;
                                oneTask.OwnerId = CaseVar.OwnerId;
                                oneTask.Subject = 'New Reply from Customer';
                                oneTask.priority = CaseVar.Priority;
                                oneTask.status = 'Open';
                                oneTask.ActivityDate = date.valueOf(CaseVar.LastModifiedDate);
                                oneTask.description = emailMsg.TextBody;
                                oneTask.IsReminderSet = true;
                                
                                taskList.add(oneTask); 
                            }
                            else {
                                String userGroupIds = 'SELECT GroupId,Id,UserOrGroupId FROM GroupMember';
                                userGroupIds = userGroupIds+' Where GroupId=\''+CaseVar.OwnerId+'\'';
                                System.debug('userGroupIds: '+userGroupIds);
                                List<GroupMember> getCaseQueueId = Database.query(userGroupIds);
                                System.debug('getCaseQueueId: '+getCaseQueueId);
                                System.debug('getCaseQueueId Size: '+getCaseQueueId.size());
                                
                                for(GroupMember oneUser : getCaseQueueId) {
                                    Task oneTask = new Task();
                                    
                                    oneTask.WhatId = CaseVar.id;
                                    oneTask.OwnerId = oneUser.UserOrGroupId;
                                    oneTask.Subject = 'New Reply from Customer';
                                    oneTask.priority = CaseVar.Priority;
                                    oneTask.status = 'Open';
                                    oneTask.ActivityDate = date.valueOf(CaseVar.LastModifiedDate);
                                    oneTask.description = emailMsg.TextBody;
                                    oneTask.IsReminderSet = true;
                                    
                                    taskList.add(oneTask);                                    
                                }
                            }
                            System.debug('taskList: '+taskList);
                            if(taskList.size() != 0 && taskList != Null) {
                                insert taskList;
                            }
                        }
                    }
                }
                else
                {
                    system.debug('casematchrvar.find() ' + casematchrvar.find());
                }
            }
            
            // Save attachments, if any
            
            list<Attachment> attachmentList = new list<Attachment>();
            
            Attachment attachment = new Attachment();
            
            System.debug('Text Attachment: '+email.textAttachments);
            System.debug('poVar id: '+poVar.id);
            System.debug('CaseVar id: '+CaseVar.id);
            if(email.textAttachments != Null)
            {
                for (Messaging.Inboundemail.TextAttachment tAttachment: email.textAttachments)
                {
                    attachment.Name = tAttachment.fileName;
                    attachment.Body = Blob.valueOf(tAttachment.body);
                    if(poVar.id != Null) {
                        attachment.ParentId = poVar.id;
                    }
                    else if(CaseVar.id != Null) {
                        attachment.ParentId = CaseVar.id;
                    }
                    attachmentList.add(attachment);
                }
            }
            System.debug('Binary Attachment: '+email.binaryAttachments);
            If(email.binaryAttachments != Null)
            {
                for (Messaging.Inboundemail.BinaryAttachment bAttachment: email.binaryAttachments) 
                {
                    attachment.Name = bAttachment.fileName;
                    attachment.Body = bAttachment.body;
                    if(poVar.id != Null) {
                        attachment.ParentId = poVar.id;
                    }
                    else if(CaseVar.id != Null) {
                        attachment.ParentId = CaseVar.id;  
                    }
                    attachmentList.add(attachment);
                }
            }
            
            if(attachmentList != null)
            {
                insert attachmentList; 
            }
        }
        catch(exception e)
        {
            system.debug('EmailHandler: Line Number: '+e.getLineNumber()+', messsage: ' +e.getMessage()+', Cause: '+e.getCause());
        }
        return result;
    }
}