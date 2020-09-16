public with sharing class FeedCommentTriggerHandler {    
    public static void beforeInsert(List<FeedComment> feedItemList) {
        DeliverightChatterManager.handleFeedItemsOrComments((List<CommentMention>)JSON.deserialize(JSON.serialize(feedItemList), List<CommentMention>.class));
    }
    
    public class CommentMention extends DeliverightChatterManager.Mention
    {
        String rawCommentBody;
        String parentId;
        String commentBody;
        public override String getParentId() {
            return parentId;
        }
        public override String getMessage() {
            return commentBody;
        }
        public override Set<Id> getUserIds()
        {
            Set<Id> userIds = new Set<Id>();
            if(String.isNotBlank(rawCommentBody)){
                Matcher m = RAW_MENTION.matcher(rawCommentBody);
                while (m.find()) {
                    userIds.add(m.group(1));
                }
            }
            return userIds;
        }
    }
}