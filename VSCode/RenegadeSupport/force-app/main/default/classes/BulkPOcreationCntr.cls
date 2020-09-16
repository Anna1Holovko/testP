public class BulkPOcreationCntr  {
    public Boolean showCarrierField {get;set;}
    public Boolean isRenderRes {get;set;}
    public Boolean areYouSure {get;set;} 
    public Boolean isRenderOption {get;set;}    
    public String selectedCarrier {get;set;}
    public Date selectedArrivalDate {set; 
                                     get {
                                         if(selectedArrivalDate == null) {
                                             selectedArrivalDate = Date.today();
                                         }
                                         return selectedArrivalDate;
                                     }
                                    }
    public String salesOrders {set;get;}
    public String message {set;
                           get {
                               if(String.isNotBlank(salesOrders)) {
                                   return Label.Check_the_following_entries;
                               } else
                                   return Label.Successfully;
                           }
                          }
    public List<Sales_Order__c > salesOrderList;
    private ApexPages.StandardSetController standardController;
    private Set<Id> salesOrdIdSet = new Set<Id>();
    
    
    public List<SelectOption> getCarrierOption(){
        List<SelectOption> carrierOption = new List<SelectOption>();
        carrierOption.add(new SelectOption('','--None--'));
        Schema.DescribeFieldResult fieldResult = Sales_Order__c.Carrier__c .getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry pickListVal : ple){
            carrierOption.add(new SelectOption(pickListVal.getLabel(), pickListVal.getLabel()));
        }     
        return carrierOption;
    }
    
    public BulkPOcreationCntr(ApexPages.StandardSetController standardController) { 
        this.standardController = standardController;
        if(standardController.getSelected().isEmpty()){
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, Label.No_records_selected_Click_cancel_and_select_at_least_one_entry));
            isRenderOption = false;
        } else {
            isRenderOption = true;
            checkSelectedForFedexable((List<Sales_Order__c>)standardController.getSelected());
        }
        
        salesOrders = '';
        salesOrderList = new List<Sales_Order__c>();
        for (Sales_Order__c salesOrd_i : (List<Sales_Order__c>)standardController.getSelected()){ 
            salesOrdIdSet.add(salesOrd_i.Id);
        }
        Boolean isSameCarrierInOrders = true;
        List<Sales_Order__c> selectedSalesOrderList = (List<Sales_Order__c>) standardController.getSelected();
        salesOrdIdSet.addAll(new Map<Id, Sales_Order__c>(selectedSalesOrderList).keySet());
        selectedSalesOrderList = [
            SELECT Id, Carrier__c 
            FROM Sales_Order__c 
            WHERE Id IN :salesOrdIdSet
        ];
        System.debug(selectedSalesOrderList);
        selectedCarrier = !selectedSalesOrderList.isEmpty() ? selectedSalesOrderList[0].Carrier__c : null;
        
        for (Sales_Order__c salesOrd_i : selectedSalesOrderList){
            if (salesOrd_i.Carrier__c != selectedCarrier) {
                isSameCarrierInOrders = false;
            }
        }
        
        if (!isSameCarrierInOrders) {
            selectedCarrier = null;
        }
        
    }
    
    public PageReference userConfirmation() { 
        if(areYouSure != true){
            areYouSure = true;
        }
        return null;
    }
    
    public PageReference checkAndUpdate() {
        isRenderOption = false;
        areYouSure = false;
        isRenderRes = true;
        List<Sales_Order__c> salesOrderForUpList = [
            SELECT Id, Name, Create_PO__c, Carrier__c, Requested_Arrival_Date__c, Eligible_for_PO_bulk_creation__c
            FROM Sales_Order__c 
            WHERE Id IN: salesOrdIdSet];
        for (Sales_Order__c salesOrd_i : salesOrderForUpList) {
            if(!salesOrd_i.Eligible_for_PO_bulk_creation__c) {
                salesOrders += salesOrd_i.Name;
                salesOrders += ', ';
            }
            salesOrd_i.Create_PO__c = true;
            salesOrd_i.Carrier__c = selectedCarrier;
            salesOrd_i.Requested_Arrival_Date__c = selectedArrivalDate;
        }
        if(String.isNotBlank(salesOrders)) {
            salesOrders = salesOrders.substringBeforeLast(',');
        } else {
            update salesOrderForUpList;
        }
        return null;
    }
    
      public void checkSelectedForFedexable(List<Sales_Order__c> salesOrdersSelected) {
        Integer fedaxableOrders = 0;
        Integer nonfedaxableOrders = 0;
        Boolean isAllFedaxable = true;
        List<Id> selectedOrdersIds = new List<Id> ();
          for (Sales_Order__c salesOrd_i : salesOrdersSelected){ 
              selectedOrdersIds.add(salesOrd_i.Id);
          }  
        List<Sales_Order__c> salesOrderToCheckList = [SELECT Id, IsFedexable__c FROM Sales_Order__c WHERE Id IN: selectedOrdersIds];
        System.debug(salesOrderToCheckList.size());
        System.debug(salesOrderToCheckList);

        for (Sales_Order__c salesOrd_i : salesOrderToCheckList) {
            if(salesOrd_i.IsFedexable__c == true) {
                fedaxableOrders++;
            } else{
               nonfedaxableOrders++; 
            }
        }         
        if(fedaxableOrders > 0 && nonfedaxableOrders > 0) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Please note that some of the orders are LTL and some are White Gloves')); 
        }
          if(fedaxableOrders == 0 && nonfedaxableOrders > 0){
              showCarrierField = false;
          } else {
              showCarrierField = true;
          }
       
    }
    
}