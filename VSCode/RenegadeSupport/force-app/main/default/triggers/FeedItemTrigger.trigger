trigger FeedItemTrigger on FeedItem (before insert) {
    switch on Trigger.operationType {
        when BEFORE_INSERT {
            FeedItemTriggerHandler.beforeInsert(Trigger.new);
        }
    }
}