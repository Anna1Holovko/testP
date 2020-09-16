public class BOLExtension {

    public shipment__c shipmentVar;
    public string iframeurl{set;get;}
    
    public BOLExtension(apexpages.StandardController sc)
    {
        shipmentVar=(shipment__c)sc.getRecord();
        iframeurl='/apex/bolpdfpage1?id='+shipmentVar.id;
       
    }
    
    public PageReference pdf() 
    {
        PageReference pr;
        try 
        {
            pr=new PageReference('/'+shipmentVar.id);
              system.debug('input Id----------' +shipmentVar.id);
              Shipment__c shipmentobj=[select id,name from Shipment__c where id=:shipmentVar.id];
            //  system.debug('input qt---------' +qt);
            
            Attachment myAttach = new Attachment();
            myAttach.ParentId = shipmentVar.id;//Id of the object to which the page is attached
            myattach.ContentType='application/pdf';
            myAttach.name = +shipmentobj.name+'_'+system.Datetime.now()+'.pdf';
            PageReference pdfPageReference =  Page.bolpdfpage1;//myPdfPage is the name of your pdf page
            pdfPageReference.getParameters().put('id',shipmentVar.id);        
            //pdfPageReference.setRedirect(true);
            
            Blob bodyContent;
            
            
            if (!Test.isRunningTest()){
                bodyContent = pdfPageReference.getContentAsPDF();
            }
            else{
                 bodyContent = Blob.valueof('Some random String');
            }
            
            system.debug('Body content--------' +bodyContent);
            
            myAttach.body = bodyContent;
            insert myAttach;
            
            myAttach=[select id,CreatedDate from Attachment where id=: myAttach.id];
            myAttach.name = +shipmentobj.name+'_'+myAttach.CreatedDate+'.pdf';
            update myAttach;
           
        } 
        catch (Exception e) 
        {
            system.debug('Exception'+e.getMessage());
                
            //apexpages.addMessage(new apexpages.Message(apexpages.Severity.ERROR,'The email couldn\'t be sent either due to invalid email address or incorrect email. Please check you customer details.'));
        }
        return pr;
    }
    
    public PageReference cancel() 
    {
        PageReference pr;
        try 
        {
            pr=new PageReference('/'+shipmentVar.id);
        } 
        catch (Exception e) 
        {
            system.debug('Exception'+e.getMessage());
            //apexpages.addMessage(new apexpages.Message(apexpages.Severity.ERROR,'The email couldn\'t be sent either due to invalid email address or incorrect email. Please check you customer details.'));
        }
        return pr;
    }    
}