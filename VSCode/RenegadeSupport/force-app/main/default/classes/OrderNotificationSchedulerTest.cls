@isTest
public class OrderNotificationSchedulerTest {

	static testMethod void schedule(){ 
        OrderNotificationScheduler sh1 = new OrderNotificationScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test', sch, sh1);
    }
}