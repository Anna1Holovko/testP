@isTest
public class DeliverightChatterManagerTest {
    @testSetup
    private static void setup() {
        update new User(Id = UserInfo.getUserId(), SO_chatter_API_endpoint__c = 'Test');
        //insert new Deliveright_Setting__c(SetupOwnerId=UserInfo.getOrganizationId(), Comment_URL__c ='Some Value');
        
        Account ac = TestUtil.createCustomerAccount();
        Account deliveryAccount = TestUtil.createDeliveryAccount();
        
        Sales_Order__c so = TestUtil.createsalesOrder(ac.id, deliveryAccount.id, Null);
    }
    
	@isTest
    private static void testItem() {
        FeedItem fi = new FeedItem(Body = '{@' + UserInfo.getUserId() + '}',
                                   ParentId = [SELECT Id FROM Sales_Order__c LIMIT 1].Id);

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        insert fi;
        
        Test.stopTest();
    }
    
    @isTest
    private static void testComment() {
        FeedItem fi = new FeedItem(Body = 'No mentions body.',
                                   ParentId = [SELECT Id FROM Sales_Order__c LIMIT 1].Id);
        insert fi;
        
        FeedComment fc = new FeedComment(CommentBody = '{@' + UserInfo.getUserId() + '}',
                                         FeedItemId = fi.Id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        
        insert fc;
        
        Test.stopTest();
    }
}