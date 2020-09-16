global with sharing class Commission implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        TotalCommissionUpdateOnAccount();
        
        Commission.start();
        
        // abort me and start again
        if(sc != null){
            System.abortJob( sc.getTriggerId() );
        }
    }
    
    global void TotalCommissionUpdateOnAccount() 
    {
        list<account> AccountsCommissionAmount = new list<account>();
        List<Sales_Order__c> soList = new List<Sales_Order__c>();
        map<string,list<Sales_Order__c>> AccountsList = new map<string,list<Sales_Order__c>>();
        try 
        {
            for(account accountVar: [select id,name,(select id,name,Commission_Amount__c,Sales_Rep__c,Sales_Rep__r.Commission_Amount__c,Commission_Added_Rep__c from Sales_Order1__r where Payment_Status__c = 'Received' and Commission_Added_Rep__c =false) from account where (Employee_Role__c='Sales Dept. Staff' OR Employee_Role__c='Sales Dept. Manager') and RecordTypeId in (SELECT Id FROM RecordType WHERE SobjectType = 'account' AND Name = 'Internal Employee')])
            {
                if(accountVar.Sales_Order1__r != null && accountVar.Sales_Order1__r.size() > 0)
                {
                    AccountsList.put(accountVar.id,accountVar.Sales_Order1__r);   
                }               
            }
            system.debug('AccountsList ' + AccountsList.values());
            
            for(string Acc : AccountsList.keyset())
            {
                account accObj=new account();
                decimal commission=0;
                for(Sales_Order__c SOvar: AccountsList.get(Acc))
                {
                    if(commission==0)
                    {
                        commission=SOvar.Sales_Rep__r.Commission_Amount__c;
                    }                    
                    Sales_Order__c SOtemp=new Sales_Order__c();                    
                    accObj.id=acc;                                                   
                    SOtemp.id=SOvar.id;
                    SOtemp.Commission_Added_Rep__c = true; 
                   // System.debug('Commission_Amount__c: '+SOvar.Commission_Amount__c);
                    commission=commission+SOvar.Commission_Amount__c;
                  //  System.debug('commission: '+commission);
                    soList.add(SOtemp);
                }
                accObj.Commission_Amount__c=commission; 
                AccountsCommissionAmount.add(accObj);
            } 
            if(AccountsCommissionAmount != null || AccountsCommissionAmount.size() > 0)
            {
                update AccountsCommissionAmount;
            }
            if(soList != null || soList.size() > 0)
            {
                update soList;
            }
            
        }
        catch(Exception e)
        {
            system.debug('Exception Caught'+e.getMessage()+' at '+e.getLineNumber());
        }
    }
    global static void start()  
    {
        // start keepalive again in 10 mints
        Datetime sysTime = System.now().addHours(1);      
        String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
        System.schedule( 'Commission SelfSchedule ' + sysTime, chronExpression, new Commission() );   
    }
}