/*
*   Author : Vishnu Bijjula and Pavan Vuppala | Kairos Tech
*   Class  : ManufacturerResponseEmailHandler_Test
*   Purpose: This test class is to cover the code coverage for ManufacturerResponseEmailHandler class.
*/
@istest
public class ManufacturerResponseEmailHandler_Test {
    public static Google_API__c googleAPI;
    public static MagentoAuth__c magentoAuth;
    public static MagentoTokens__c magentoToken;
    
    @testSetup static void setUp() {
        magentoAuth = new MagentoAuth__c(Name='MagentoOAuth', AccessTokenURL__c='http://stage01.colemanfurniture.com/oauth/token',
                                        AuthorizationURL__c='http://stage01.colemanfurniture.com/admin/oauth_authorize',
                                        CallbackURL__c='https://c.cs41.visual.force.com/apex/CompleteAuth', password__c='rfgstage0987',
                                        ClientKey__c='ulzh3hgcx5pcmfkvbcd7x369bxfqjzmp',ClientSecret__c='p1khnuudmoowwiq1avhx8cjj9g573j70',
                                        RequestTokenURL__c='http://stage01.colemanfurniture.com/oauth/initiate/',
                                        RestEndpoint__c='http://stage01.colemanfurniture.com/api/rest',username__c='stage');
        insert magentoAuth;
        
        magentoToken = new MagentoTokens__c(Name='OAuth', isAccess__c=false,owner__c='00555000000IFiGAAW',
                                           secret__c='vrz4dsnqxlf7uj3cq9qs89meferbyf5g', token__c='mbxbk9y7ylsx9kh4lay7y1fvmqursrcb');
        
        insert magentoToken; 
        
        googleAPI = new Google_API__c(Name='Google API',Key__c='AIzaSyCAmP-yM5hc67O4stT-VyzMRmDTaVYfXzQ');
        insert googleAPI;
    }
    
    public static testMethod void handleInboundEmailForPO()
    {
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id);
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        PO.Ship_From__c = manufactureAccount.id;
        PO.Email_Response__c = 'Sample';
        update PO;
        
        Purchase_Order__c poList = [Select name,Ship_From__c,Email_Response__c,Manufacturer_Name__c from Purchase_Order__c where id=:PO.id];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);

        test.startTest();
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = poList.Name+ ' has Created Successfully.';
        String[] stringList = new String[]{'Test Reference'};
        
        email.references = stringList;
        
        email.fromName = 'test test';
               
        Messaging.InboundEmail.textAttachment[] textAttachments = new Messaging.InboundEmail.textAttachment[1];
        Messaging.InboundEmail.textAttachment textAttachment = new Messaging.InboundEmail.textAttachment();
        textAttachment.Filename = 'test.txt';
        
        textAttachment.Body = 'Hello, this a test email body. for testing purposes only.Phone:123456 Bye';
        textAttachments[0] =  textAttachment;
        email.textAttachments = textAttachments;
        
        Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];  
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'test.txt';
        String algorithmName = 'HMacSHA1';
        Blob b = Crypto.generateMac(algorithmName, Blob.valueOf('test'),
        Blob.valueOf('test_key'));
        binaryAttachment.Body = b;
        binaryAttachments[0] =  binaryAttachment ;
        email.binaryAttachments = binaryAttachments ;
        envelope.fromAddress = 'test@salesforce.com';
        
         // setup controller object
        ManufacturerResponseEmailHandler catcher = new ManufacturerResponseEmailHandler();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
        test.stopTest();
        System.assertEquals(result.success,true);    
    }
    public static testMethod void handleInboundEmailForCase()
    {
        Account ac = TestUtil.createCustomerAccount();  
        Account manufactureAccount = TestUtil.createManufacturerAccount(true,false, 'Email');
        
        Contact con = TestUtil.setupCustomerContact('Test', 'Name', manufactureAccount.id);
        
        Products__c Pro = TestUtil.createConfigProduct();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, Null, Null);
        
        Purchase_Order__c PO = TestUtil.createpurchaseorder(so.id,'Manufacturer PO');
        PO.Ship_From__c = manufactureAccount.id;
        update PO;
        
        Purchase_Order__c poList = [Select name,Ship_From__c,Email_Response__c,Manufacturer_Name__c from Purchase_Order__c where id=:PO.id];
        
        SO_Line_Items__c Sol = TestUtil.createsalesOrderLineItem(so.id, pro.id, null,null,5);
        
        PO_Line_Items__c POl = TestUtil.createpoitem(po.id, Sol.id);
        
        Case cas = TestUtil.createCase(so.id,Null,'Warranty','Warranty Dept.');
        Case casList = [select id,CaseNumber,Subject,Priority,OwnerId,Description,LastModifiedDate from Case where id=:cas.id];
                                       
        test.startTest();
        // Create a new email, envelope object and Attachment
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        
        email.subject = casList.CaseNumber+ ' has Created Successfully.';
        String[] stringList = new String[]{'Test Reference'};
        String[] toAddress = new String[]{'test@salesforce.com'};
            
        email.references = stringList;
        email.toAddresses = toAddress;
        email.fromName = 'test test';
               
        Messaging.InboundEmail.textAttachment[] textAttachments = new Messaging.InboundEmail.textAttachment[1];
        Messaging.InboundEmail.textAttachment textAttachment = new Messaging.InboundEmail.textAttachment();
        textAttachment.Filename = 'test.txt';
        
        textAttachment.Body = 'Hello, this a test email body. for testing purposes only.Phone:123456 Bye';
        textAttachments[0] =  textAttachment;
        email.textAttachments = textAttachments;
        
        Messaging.InboundEmail.BinaryAttachment[] binaryAttachments = new Messaging.InboundEmail.BinaryAttachment[1];  
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.Filename = 'test.txt';
        String algorithmName = 'HMacSHA1';
        Blob b = Crypto.generateMac(algorithmName, Blob.valueOf('test'),
        Blob.valueOf('test_key'));
        binaryAttachment.Body = b;
        binaryAttachments[0] =  binaryAttachment ;
        email.binaryAttachments = binaryAttachments ;
        envelope.fromAddress = 'test@salesforce.com';
        
         // setup controller object
        ManufacturerResponseEmailHandler catcher = new ManufacturerResponseEmailHandler();
        Messaging.InboundEmailResult result = catcher.handleInboundEmail(email, envelope);
        test.stopTest();
        System.assertEquals(result.success,true);    
    }
}