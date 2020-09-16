/* To Retrieve the realted bundle items of a product in products and Pass the values to VF page BundleRelatedList */

public class BundleRelatedList { 
    
    Public list<Bundle_Item__c> BiRelated;
    public Products__c PO_Obj=new Products__c();
    public BundleRelatedList(ApexPages.StandardController controller)
    { 
        PO_Obj=(Products__c)controller.getrecord(); 
        PO_Obj=[select Name,id,RecordTypeId from Products__c where id=:PO_Obj.id];  
        system.debug(PO_Obj);  
    }
    public list<Bundle_Item__c> getBiRelated() 
    {
        return [select Include__c,name,SKU__c,Order__c,Sales_Price__c,Product__c,Product__r.Name,Product__r.ProductImage__c,Status__c from Bundle_Item__c where Bundle__c =: PO_Obj.id and Status__c='Enabled' ORDER BY order__c ASC NULLS LAST];
    } 
    public pagereference newBundleItem() 
    {  
        // get sobject id prefix
        String prefix = Schema.getGlobalDescribe().get('Bundle_Item__c').getDescribe().getKeyPrefix();
        System.debug('prefix: '+prefix);
        
        String getBundleFieldId = [Select Field_Id__c from Product_Fields__c where name='Bundle' AND sObject_Name__c='Bundle Item' limit 1].Field_Id__c;
        System.debug('getBundleFieldId: '+getBundleFieldId);
        
        string url='/'+prefix+'/e?CF'+getBundleFieldId+'='+PO_Obj.Name+'&CF'+getBundleFieldId+'_lkid='+PO_Obj.Id+'&retURL=%2F'+PO_Obj.id;
        pagereference pagereferenceOBj = new pagereference(url);     
        return pagereferenceOBj;  
    } 
}