public class AccountCreationHandler {
    @InvocableMethod(label='Internal Account Record Creation')
    public static List<Id> create(List<Id> userIds) {
        createInternalEmployee(userIds);
        return userIds;
    }
    @future
    private static void createInternalEmployee(List<Id> userIds) {
        try {
            System.debug('createInternalEmployee');
            Id rcTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Internal Employee').getRecordTypeId();
            list<Account> accountList = new list<Account>();
            
            for(User oneUser : [Select id,name,Email from User where id In :userIds])
            {
                Account acc = new Account();
                
                acc.Name = oneUser.Name;
                acc.RecordTypeId = rcTypeId;
                //acc.Email__c = oneUser.Email;
                acc.SalesRepAsUser__c = oneUser.id;
                accountList.add(acc);
            }
            
            if(accountList.size() > 0) {
                insert accountList;
            }
        }
        catch(Exception e) {
            system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
        }
    }
}