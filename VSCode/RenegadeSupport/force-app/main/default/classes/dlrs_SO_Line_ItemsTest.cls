/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_SO_Line_ItemsTest
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_SO_Line_ItemsTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new SO_Line_Items__c());
    }
}