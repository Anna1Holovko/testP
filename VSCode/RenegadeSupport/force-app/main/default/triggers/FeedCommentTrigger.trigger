trigger FeedCommentTrigger on FeedComment (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            FeedCommentTriggerHandler.beforeInsert(Trigger.new);
        }
    }
}