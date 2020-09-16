/**
 * @File Name          : GenerateInvoiceControllerTest.cls
 * @Description        : 
 * @Author             : Vladimir Zhutenko
 * @Group              : 
 * @Last Modified By   : Vladimir Zhutenko
 * @Last Modified On   : 4/7/2020, 11:22:24 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/7/2020   Vladimir Zhutenko     Initial Version
**/
@isTest
private class GenerateInvoiceControllerTest {
	@isTest
    static void testIsLockedRecord(){
        Account ac = TestUtil.createCustomerAccount();
        GenerateInvoiceController.isLockedRecord(ac.Id);
    }
}