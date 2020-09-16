public with sharing class FeedItemTriggerHandler {    
    public static void beforeInsert(List<FeedItem> feedItemList) {
        DeliverightChatterManager.handleFeedItemsOrComments((List<ItemMention>)JSON.deserialize(JSON.serialize(feedItemList), List<ItemMention>.class));
    }
    
    public class ItemMention extends DeliverightChatterManager.Mention
    {
        String rawBody;
        String parentId;
        String body;
        public override String getParentId() {
            return parentId;
        }
        public override String getMessage() {
            return body;
        }
        public override Set<Id> getUserIds()
        {
            Set<Id> userIds = new Set<Id>();
            if(String.isNotBlank(rawBody)){
                Matcher m = RAW_MENTION.matcher(rawBody);
                while (m.find()) {
                    userIds.add(m.group(1));
                }
            }
            return userIds;
        }
    }
}