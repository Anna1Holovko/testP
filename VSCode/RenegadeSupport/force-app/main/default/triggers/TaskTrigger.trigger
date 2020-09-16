trigger TaskTrigger on Task (before insert,after insert,before update) 
{
	if (Trigger.isAfter && Trigger.isInsert) {
            TaskHelper.updateObjectName(trigger.newmap.keyset());
            TaskTriggerHandler.afterInsert(trigger.new);
		}
		
		/*if(Trigger.isAfter && Trigger.isDelete){
		}
		
		if(Trigger.isAfter && Trigger.isUndelete){
		}*/
		
		if(Trigger.isAfter && Trigger.isUpdate){
		}
		
		if(Trigger.isInsert && Trigger.isBefore){
            try 
            {
                System.debug(trigger.newmap);
                TaskHelper.updateUserLookup(trigger.new,trigger.newmap.keyset());
            }
            catch(Exception e) 
            {
                system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
            }  
		}
		
		if (Trigger.isUpdate && Trigger.isBefore) {
            try 
            {
                TaskHelper.updateUserLookup(trigger.new,trigger.newmap.keyset());
            }
            catch(Exception e) 
            {
                system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
            }  
		}
    
}