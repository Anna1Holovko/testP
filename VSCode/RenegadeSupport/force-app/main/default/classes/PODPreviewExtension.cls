public with sharing class PODPreviewExtension {

    public String pdfURL { get; set; }
	
    private Sales_Order__c  salesOrder;
    private ApexPages.StandardController stdController;
    private Boolean isOnlyWG;

    public PODPreviewExtension(ApexPages.StandardController stdController) {
        this.isOnlyWG = false;
        if(!Test.isRunningTest()) stdController.addFields(new List<String> {'id', 'Name'});
        this.salesOrder = (Sales_Order__c)stdController.getRecord();
        
        List<AggregateResult> shipmentList = [SELECT count(Id), Delivery_Company__c FROM Shipment__c WHERE Carrier__c != 'LTL'/*'FedEx'*/ and Related_Sales_Order__c = : this.salesOrder.Id GROUP BY Delivery_Company__c  ];
        List<AggregateResult> shipmentWithNullList = [SELECT count(Id), Delivery_Company__c FROM Shipment__c WHERE Carrier__c = null and Related_Sales_Order__c = : this.salesOrder.Id GROUP BY Delivery_Company__c  ];
        if(shipmentList.size() == 1){
            fillPODPage();
        }else{
            if(shipmentList.size() > 0 && shipmentWithNullList.size() > 0){
                this.isOnlyWG = true;
                fillPODPage();
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There seems to be an issue with this order that requires Renegade\'s attention. Please contact your Renegade represntative'));
            }
        }
        this.stdController = stdController;
    }

    void fillPODPage(){
        PageReference pdfPageReference =  Page.POD_pdfPage;
        pdfPageReference.getParameters().put('id', this.salesOrder.id);
        pdfPageReference.getParameters().put('isOnlyWG', String.valueOf(this.isOnlyWG));
        this.pdfURL = ApexPages.currentPage().getHeaders().get('Host') + pdfPageReference.getUrl();
    }

    public void saveAttachment(){
        if(!ApexPages.hasMessages()){
            Attachment podAttachment = new Attachment();
            podAttachment.ParentId = salesOrder.id;
            podAttachment.ContentType = 'application/pdf';
            podAttachment.name = 'POD ' + salesOrder.Name + '_' + Datetime.now() + '.pdf';

            PageReference pdfPageReference =  Page.POD_pdfPage;
            pdfPageReference.getParameters().put('id',salesOrder.id);        
            pdfPageReference.setRedirect(true);
            
            Blob bodyContent = !Test.isRunningTest() ? pdfPageReference.getContentAsPDF() : Blob.valueof('Test String');
            
            podAttachment.body = bodyContent;
            insert podAttachment;
        }
    }

    public PageReference cancel(){
        return this.stdController.cancel();
    }   

    
}