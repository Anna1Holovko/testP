global class OrderNotificationScheduler implements Schedulable {

	global void execute(SchedulableContext SC) {
    	OrderNotificationBatch b = new OrderNotificationBatch();
    	database.executebatch(b, 30);
	}
}