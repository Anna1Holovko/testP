public class DeliverightChatterManager {
    public static final String USER_PREFIX = SObjectType.User.getKeyPrefix();
    public static final String SALES_ORDER_PREFIX = SObjectType.Sales_Order__c.getKeyPrefix();
    public static final String EXPRESSION = '\\{@(' + USER_PREFIX +'[0-9a-zA-Z]{15})\\}';
    public static Pattern RAW_MENTION = Pattern.compile(EXPRESSION);
    
    public static void postAtChatter(String salesOrderId, String message, String senderName) {
        if(String.isNotBlank(salesOrderId)){
            List<String> parseOrderIdList = salesOrderId.split(' ');//,"order_id":"593476 SO-572205"
            List<User> userList = [SELECT Id, SO_chatter_API_endpoint__c FROM User WHERE Id = : UserInfo.getUserId()];
            if(parseOrderIdList.size() > 1 && String.isNotBlank(userList.get(0).SO_chatter_API_endpoint__c)){
                String orderName = parseOrderIdList.get(1);
                List<Sales_Order__c> orderList = [SELECT Id FROM Sales_Order__c WHERE Name = :orderName];
                if(orderList.size() > 0){
                    insert new FeedItem(Body = senderName + ', ' + message, ParentId = orderList.get(0).Id);
                }
            }
        }
    }
    
    public static void handleFeedItemsOrComments(List<Mention> mentionList) {
        Map<Id, List<Mention>> userIdToMentionMap = new Map<Id, List<Mention>>();
        
        for (Mention mention_i : mentionList){
            Set<Id> idSet = mention_i.getUserIDs();
            if (mention_i.getParentId().startsWith(SALES_ORDER_PREFIX)) {
                for (Id id_i : idSet) {
                    if (!userIdToMentionMap.containsKey(id_i)) {
                        userIdToMentionMap.put(id_i, new List<Mention>());
                    }
                    userIdToMentionMap.get(id_i).add(mention_i);
                }
            }
        }
        
        if (!userIdToMentionMap.isEmpty()) {
        	Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, SO_chatter_API_endpoint__c FROM User WHERE Id IN :userIdToMentionMap.keySet()]);
            Map<Id, Id> salesOrderIdToUserIdMap = new Map<Id, Id>();
            for (User user_i : userMap.values()) {
                if (String.isBlank(user_i.SO_chatter_API_endpoint__c)) {
                    userIdToMentionMap.remove(user_i.Id);
                }
            }
            
            for (Id id_i : userIdToMentionMap.keySet()) {
                List<Mention> mentionList_i = userIdToMentionMap.get(id_i);
                for (Mention mention_i : mentionList_i) {
                	salesOrderIdToUserIdMap.put(mention_i.getParentId(), id_i);
                }
            }
            
            List<Sales_Order__c> salesOrderNoList = [SELECT Id, Magento_Order_No__c, Name FROM Sales_Order__c WHERE Id IN :salesOrderIdToUserIdMap.keySet()];
            
            List<OrderToSend> orderToSendList = new List<OrderToSend>();
            for (Sales_Order__c salesOrder_i : salesOrderNoList) {
                Id userId = salesOrderIdToUserIdMap.get(salesOrder_i.Id);
                List<Mention> mentionList_i = userIdToMentionMap.get(userId);
                for (Mention mention_i : mentionList_i) {
                    OrderToSend orderToSend_i = new OrderToSend(salesOrder_i.Magento_Order_No__c,
                                                                salesOrder_i.Magento_Order_No__c + ' ' + salesOrder_i.Name,
                                                                mention_i.getMessage(),
                                                                userMap.get(userId).SO_chatter_API_endpoint__c,
                                                                userMap.get(userId).Name);
                    orderToSendList.add(orderToSend_i);
                }
            }
            
            if (!orderToSendList.isEmpty()) {
                sendMessages(orderToSendList);
            }
        }
    }
    
    private static void sendMessages(List<OrderToSend> orderToSendList) {
        //Deliveright_Setting__c settingDeliveright = Deliveright_Setting__c.getInstance();
        
        for(OrderToSend orderToSend_i : orderToSendList){
            //String endpoint = settingDeliveright.Comment_URL__c.replace('<Magento_order_No__c>', orderToSend_i.orderId);
            sendMessage(orderToSend_i.endpoint, orderToSend_i.comment, orderToSend_i.po_id, orderToSend_i.sender);
        }
    }
    
    @future(callout=true)
    private static void sendMessage(String endpoint, String comment, String po_id, String sender) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('POST');
        comment = String.isNotBlank(comment)    ? comment.stripHtmlTags() 
                                                : comment;
        req.setBody(JSON.serialize(new Map<String, String> { 'comments' => comment, 'po_number' => po_id, 'sender' => sender }));
        req.setTimeout(120000);
        Http h = new Http();
        HttpResponse res = h.send(req);
    }
    
    public abstract class Mention
    {
        String rawBody;
        String parentId;
        String body;
        String rawCommentBody;
        String commentBody;
        public abstract String getParentId();
        public abstract String getMessage();
        public abstract Set<Id> getUserIDs();
    }

    public class OrderToSend{
        public String orderId { get; set; }
        public String po_id { get; set; }
        public String comment { get; set; }
        public String endpoint { get; set; }
        public String sender { get; set; }
        
        public OrderToSend(String orderId, String po_id, String comment, String endpoint, String sender){
            this.orderId = orderId;
            this.po_id = po_id;
            this.comment = comment;
            this.endpoint = endpoint;
            this.sender = sender;
        }
    }
}