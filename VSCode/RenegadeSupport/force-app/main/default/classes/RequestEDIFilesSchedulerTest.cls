@isTest
public class RequestEDIFilesSchedulerTest {

	
	static testMethod void schedule(){ 
        RequestEDIFilesScheduler sh1 = new RequestEDIFilesScheduler();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test', sch, sh1);
    }
}