global with sharing class CaseCreationFlowHandler {
    @InvocableMethod(label='Create Case Milestone' )//description='Returns the list of account names corresponding to the specified account IDs.'
    global static void createMilestoneCase(List<MilestoneCaseDataWrapper> milestoneCaseDataList) {
        MilestoneCaseDataWrapper milestoneCaseData = milestoneCaseDataList.get(0);
        List<MilestoneType> milestoneTypeList = [SELECT Id, Name FROM MilestoneType WHERE Id = :milestoneCaseData.MilestoneTypeID];
        if(milestoneTypeList.isEmpty()){
            System.debug('CaseCreationFlowHandler: can\'t find milestone type');
            return;
        }
        //Case caseToUpdate = [SELECT Id, AccountId FROM Case WHERE Id = :milestoneCaseData.CaseId LIMIT 1];
        //String caseAccountId = caseToUpdate.AccountId;

        Case caseToCreateMilistone = new Case(
            Id = milestoneCaseData.CaseId, 
            Milestone_trigger_field__c = milestoneTypeList.get(0).Name
        );
        update caseToCreateMilistone;
        List<CaseMilestone> currentCaseMilestoneList = [SELECT Id, TargetResponseInMins 
                                                        FROM CaseMilestone 
                                                        WHERE MilestoneTypeId = :milestoneCaseData.MilestoneTypeID 
                                                        AND CaseId = :milestoneCaseData.CaseId AND IsCompleted = false];
        if(!currentCaseMilestoneList.isEmpty()){
            CaseMilestone currentCaseMillestone = currentCaseMilestoneList.get(0);
            currentCaseMillestone.startDate = milestoneCaseData.TargetDate.addMinutes(Integer.valueOf(-currentCaseMillestone.TargetResponseInMins));
            update currentCaseMillestone;
        }
    }

    global class MilestoneCaseDataWrapper{
        @InvocableVariable(label='Case Id')
        global ID CaseId;

        @InvocableVariable(label='Milistone Type Id')
        global ID MilestoneTypeID;

        @InvocableVariable (label='Target Date')
        global Datetime TargetDate;

    }
}