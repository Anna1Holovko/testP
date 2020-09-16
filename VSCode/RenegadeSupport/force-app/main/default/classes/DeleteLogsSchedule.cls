global class DeleteLogsSchedule implements Schedulable {

	global void execute(SchedulableContext SC) {
		Id batchJobId = Database.executeBatch(new DeleteLogsBatch(), 200);
	}
}