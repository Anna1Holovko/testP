global class RequestEDIFilesScheduler implements Schedulable {

	global void execute(SchedulableContext SC) {
		EDIManager.sendFilesRequest();
	}
}