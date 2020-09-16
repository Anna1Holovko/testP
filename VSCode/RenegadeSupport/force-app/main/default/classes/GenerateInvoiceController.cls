/**
 * @File Name          : GenerateInvoiceController.cls
 * @Description        : 
 * @Author             : Vladimir Zhutenko
 * @Group              : 
 * @Last Modified By   : Vladimir Zhutenko
 * @Last Modified On   : 4/7/2020, 11:21:58 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    4/7/2020   Vladimir Zhutenko     Initial Version
**/
global class GenerateInvoiceController {
	webservice static Boolean isLockedRecord(Id recordId) {
        return Approval.isLocked(recordId);
    }
}