global class ShipmentGenerateInvoiceScheduler implements Schedulable {
    private List<String> salesOrderIdList;
    
    public ShipmentGenerateInvoiceScheduler(List<String> salesOrderIdList) {
        this.salesOrderIdList = salesOrderIdList;
    }
    
    global void execute(SchedulableContext SC) {
        InvoiceGenerationHandler.generateInvoice(salesOrderIdList);
    }
}