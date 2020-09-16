/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : RefundController
*   Purpose: This class is to refund the products to the customer through Compensation or Cancellation.
*/
global with sharing class RefundController
{
    public Sales_Order__c SO_Obj {set; get;}
    public map<string,ItemsorderWrapper> soRelatedList {get; set;}
    // This Variable is used to Calculate SubTotal, Discount Amount and Grand total of Sales Order Line Item.
    public Decimal subTot {set; get;}
    public Decimal adjustRefundTot {set; get;}
    public Decimal disAmount {set; get;}
    public Decimal taxAmount {set; get;}
    public Decimal AdjRefund {set; get;}
    public Decimal grandTotal {set; get;}
    public Boolean isChecked {set; get;}
    public Decimal shippingChargesApply {get; set;}
    public Decimal ChargesApply {get; set;}
    public Decimal shippingFee {get; set;}
    public Decimal defaultShippingfee {get; set;}
    public map<String,Boolean> isChargesApplymap {get; set;}
    public integer adjustRefundPercentage {set; get;}
    
    public Boolean isShowedShipingErrorMessage {set; get;}
    public Boolean showShippingAlert {set; get;}
    public Boolean applayReward {set; get;}
    private Boolean applaedReward = false;
    
    // The Below Variables is used to calculate updated qyt.
    list<SO_Line_Items__c> selectedSOItemList;
    Set<SO_Line_Items__c> cancelledSOItemList;
    
    List<SO_Line_Items__c> parentBundleToUpdateForTaxIssueFix;
    map<Id,string> getqtyinv;
    map<Id,string> getPrice;
    map<Id,string> getsubTotalinv;
    map<Id,string> getdisAmtinv;
    map<Id,string> gettaxAmtinv;
    map<Id,string> getrowTinv;
    map<Id,String> getcustomDisc;
    map<Id,Boolean> getisCustomPrice;
    
    map<Id,string> getBundleQty;
    MAP<String, ItemsorderWrapper> parentWraperDataMap;
    

    // This Variable is used to Insert a records into Invoice and Invoice Line Item Object.
    public Invoice__c invObj {set; get;}
    public list<Invoice_Line_Item__c> itemInvoiceList;
    public static Transaction__c transactionObject;
    
    // This Variable is used to get the values of Refund picklist values in Invoice Object.
    public String selectRefund {get; set;}
    public String selectCompReason {get; set;}
    public String selectCanReason {get; set;}
    public String selectReason {get; set;}
    public String selectForm {get; set;}
    public String selectLocation {get; set;}
    public string trackingNumber {get; set;}
    public String selectConditioalFurniture {get; set;}
    public String selectShippingCharge {get; set;}
    public boolean isPickupNeeded {get; set;}
    
    public boolean isRefundAll {get; set;}
    public Integer itemCount {get; set;}

    // For adding custom required field
    public boolean isChangedShippingFee;
    public boolean isZeroShippingFeeBase {get; set;}
    Public Boolean isreqField {get; set;}
    Public Boolean isreqreasonField {get; set;}
    Public Boolean isreqLocationField {get; set;}
    Public Boolean isreqTrackingField {get; set;}
    Public Boolean isreqShippingCharge {get; set;}
    Public Boolean isreqConditionField {get; set;}
    Public Boolean isreqCompField {get; set;}
    Public Boolean isreqCanField {get; set;}
    Public Boolean isreqHandleField {get; set;}
    Public Boolean isreqFormField {get; set;}
    Public Boolean isreqCommField {get; set;}
    
    public Map<id,SO_Line_Items__c> soRelatedMap;
    
    //For getting Custom Discount Price
    public Decimal customDiscount {get; set;}
    public String compensationComments {get; set;}
    
    list<bundleItemsorderWrapper> BundelSOitemstemp;
    list<bundleItemsorderWrapper> bundelItems;
    list<SO_Line_Items__c> SOItemQtyList;
    
    map<Id,SO_Line_Items__c> BundelSOitems;
    map<String,String> getsoitemQty_Map;
    public Boolean checkifBundled {get; set;}
    public Boolean checkisCustomPrice {get; set;}
    public Boolean isRefundItemsExist {get; set;}
    public Boolean isDisabledRedundOption {get; set;}

    private Locker refundLocker = new Locker();
    public list<selectoption> getSelectRefundoption(){
        list<selectoption> selectRefundoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Reason_for_Refund__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        selectRefundoption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            if(f.getValue() == 'GPP Cancellation' && !isDisabledRedundOption) {
                continue;
            }
            selectRefundoption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        /*if(isDisabledRedundOption){
selectRefundoption.add(new SelectOption('GPP Cancellation', 'GPP Cancellation'));
}*/
        return selectRefundoption;
    }
    
    public list<selectoption> getSelectCompReasonoption(){
        list<selectoption> selectCompReasonoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Compensation_Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        selectCompReasonoption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectCompReasonoption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return selectCompReasonoption;
    }
    
    public list<selectoption> getSelectCanReasonoption(){
        list<selectoption> selectCanReasonoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Cancellation_Reason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        selectCanReasonoption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectCanReasonoption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return selectCanReasonoption;
    }

    public list<selectoption> getSelectShippingChargeOption(){
        list<selectoption> selectShippingChargeOnoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Shipping_Charge__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        //selectCompReasonoption.add(new SelectOption('None', '--None--'));
        //selectCompReasonoption.add(new SelectOption('One way', 'One way'));
        //selectCompReasonoption.add(new SelectOption('Both ways', 'Both ways'));
        for( Schema.PicklistEntry f : ple)
        {
            selectShippingChargeOnoption.add(new SelectOption(f.getValue(), (f.getValue()=='None') ? '--None--' : f.getLabel()));
        }
        return selectShippingChargeOnoption;
    }
    
    public list<selectoption> getSelectReasonoption(){
        list<selectoption> selectReasonoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Refund_Handle_By__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        selectReasonoption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectReasonoption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return selectReasonoption;
    }
    
    public list<selectoption> getSelectFormOfCompensationoption(){
        list<selectoption> selectFormOfCompensationoption = new list<selectoption>();
        
        selectFormOfCompensationoption.add(new SelectOption('none', '--None--'));
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Form_Of_Compensation__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            selectFormOfCompensationoption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return selectFormOfCompensationoption;
    }
    
    public list<selectoption> getSelectLocationoption() {
        list<selectoption> selectLocationoption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Location_Of_Furniture__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        selectLocationoption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectLocationoption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return selectLocationoption;
    }
    
    public list<selectoption> getSelectConditionaloption() {
        list<selectoption> selectConditionaloption = new list<selectoption>();
        
        Schema.DescribeFieldResult fieldResult = Invoice__c.Condition_Of_Furniture__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        selectConditionaloption.add(new SelectOption('none', '--None--'));
        for( Schema.PicklistEntry f : ple)
        {
            selectConditionaloption.add(new SelectOption(f.getValue(),f.getLabel()));
        }
        return selectConditionaloption;
    }
    
    public RefundController(ApexPages.StandardController controller)
    {
        isChangedShippingFee = false;
        shippingFee = 0.00;
        showShippingAlert = false;
	    isZeroShippingFeeBase = false;
        itemCount = 0;
        applayReward = true;
        isShowedShipingErrorMessage = false;
        //applayReward = false;
        customDiscount = 0.00;
        adjustRefundPercentage = 15;
        isreqField = false;
        isreqreasonField = false;
        isreqLocationField = false;
        isreqTrackingField = false;
        isreqShippingCharge = false;
        isreqConditionField = false;
        isreqCompField = false;
        isreqCanField = false;
        isreqCommField = false;
        isreqHandleField = false;
        isreqFormField = false;
        isChecked = true;
        checkisCustomPrice = false;
        isRefundItemsExist = true;
        isDisabledRedundOption = false;
        isPickupNeeded = false;
        isRefundAll = false;
        // reset to Zero for every refres
        subTot = 0;
        adjustRefundTot = 0;
        taxAmount = 0;
        disAmount = 0;
        grandTotal = 0;
        ChargesApply= 0.00;
        shippingChargesApply = 0.00;
        selectRefund = 'none';
        selectLocation = 'none';
        selectCompReason = 'none';
        selectCanReason = 'none';
        selectReason = 'none';
        selectForm = 'Original Form of Payment';
        selectShippingCharge = 'None';
        compensationComments = '';
        
        checkifBundled = false;
        invObj = new Invoice__c();
        SO_Obj = new Sales_Order__c();
        Sales_Order__c SO_ObjId = (Sales_Order__c)controller.getrecord();
        cancelledSOItemList = new Set<SO_Line_Items__c>();
        getsoitemQty_Map = new map<String,String>();
        parentWraperDataMap = new Map<String, ItemsorderWrapper>();
        parentBundleToUpdateForTaxIssueFix = new List<SO_Line_Items__c>();
        try {
            SO_Obj = [SELECT id,name,Bill_To__c, Magento_order_No__c, DiscountAmount__c, Invoices_Changed_to_Manual_Payment__c, (SELECT id,UnitPrice__c,Products__c, Bundle_Item__c, Price_For_Credit_Memo__c, Row_Total_For_Credit_Memo__c, Item__c, Tax_Amount_For_Credit_Memo__c, Bundle_Item_Relative_Discount_Amount__c FROM SO_Line_Items__r),Payment_Status__c,Order_Status__c,Promotion__r.Name,Promotion__c, Promotion__r.Discount_Amount__c,
                      Total_Quantity_Ordered__c,Order_Date__c,Sales_Representative__r.name,Customer_Name__r.name,Customer_Name__r.Phone,Billing_City__c,Payment_Method__c,
                      Billing_State__c,Billing_Street__c,Customer_Name__c,Customer_Email__c,Ship_to__c, Shipping_City__c,Shipping_Handle__c,Mobile__c, Customer_Name__r.Website, Delivery_Company__r.Shipping_Base_Fee__c, Delivery_Company__r.Additional_Item_Fee__c,
                      Shipping_State__c,Shipping_Street__c,Shipping_ZipCode__c,Billing_ZipCode__c,Grand_Total__c,No_Of_Products_Ordered__c, Total_Due__c, Total_Paid__c,
                      Order_Type__c,Transaction_ID__c,(SELECT id,Reason_for_Refund__c FROM Invoice__r), Total_Refund__c 
                      FROM Sales_Order__c where id =: SO_ObjId.id];
            System.debug('SO_Obj: '+SO_Obj);
            System.debug('Refund Page change to manual payment update SO_Obj.Total_Paid__c'+SO_Obj.Total_Paid__c);
            
            invObj.Sales_Order__c = SO_Obj.id;
            
            map<String,Refund_Process__c> isChargesApply = new map<String,Refund_Process__c>([SELECT Id,Is_Shipping_Charged_Based_on_weight__c,Name FROM Refund_Process__c]);
            isChargesApplymap = new map<String,Boolean>();
            isChargesApplymap.put('none', false);
            for(Refund_Process__c oneRF:isChargesApply.values())
            {
                isChargesApplymap.put(oneRF.Name, oneRF.Is_Shipping_Charged_Based_on_weight__c);
            }
            System.debug('isChargesApplymap: '+isChargesApplymap);
            
            for(SO_Line_Items__c oneQty:[SELECT id,name, Bundle_Item_Relative_Discount_Amount__c, Products__c,Products__r.RecordType.Name,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Price_For_Credit_Memo__c,DiscountAmount_For_Credit_Memo__c,Quantity_Refunded__c,Total_Weight_Pounds__c, Item__c, Bundle_Item__c,
                                         ProductSKU__c,Product_Name__c,Products__r.Non_Furniture_Product__c, Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Quantity_Invoiced__c, Row_Total__c, Custom_Price__c, Discount_Amount__c,
                                         ProductImageUrl__c,Custom_Price_For_Credit_Memo__c, Row_Total_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c, (SELECT id,Quantity_To_Refund__c FROM Invoice_Line_Item__r)
                                         FROM SO_Line_Items__c WHERE Sales_Order__c = :SO_Obj.id]) {
                                             getsoitemQty_Map.put(oneQty.Products__c,String.valueof(oneQty.Quantity__c));
                                         }
            
            System.debug('getsoitemQty_Map: '+getsoitemQty_Map);
            
            Id prodSimpleId = Schema.SObjectType.Products__c.getRecordTypeInfosByName().get('Simple').getRecordTypeId();
            
            soRelatedList = new map<string,ItemsorderWrapper>();
            
            BundelSOitems = new map<Id,SO_Line_Items__c>([SELECT id,name, Bundle_Item_Relative_Discount_Amount__c, DiscountAmount__c, Products__c,  Products__r.Categories__c, Products__r.RecordType.Name,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Price_For_Credit_Memo__c,DiscountAmount_For_Credit_Memo__c,Quantity_Refunded__c,Total_Weight_Pounds__c, Item__c,
                                                          ProductSKU__c,Product_Name__c,Products__r.Non_Furniture_Product__c, Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Quantity_Invoiced__c, Row_Total__c, Custom_Price__c, Discount_Amount__c, Bundle_Item__c,
                                                          ProductImageUrl__c, Sales_Order__r.Total_Paid__c, Sales_Order__r.Total_Refund__c,Row_Total_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c, (SELECT id,Quantity_To_Refund__c FROM Invoice_Line_Item__r) FROM SO_Line_Items__c WHERE Item__c!='Cancelled' AND Bundle_Item__c != null and Sales_Order__c =: SO_Obj.id]);
            
            soRelatedMap = new Map<id,SO_Line_Items__c>([SELECT id,name, Bundle_Item_Relative_Discount_Amount__c, Products__c,  Products__r.Categories__c, Products__r.RecordType.Name,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Price_For_Credit_Memo__c,DiscountAmount_For_Credit_Memo__c,Quantity_Refunded__c,Total_Weight_Pounds__c, Item__c, Bundle_Item__c,
                                                         ProductSKU__c,Product_Name__c,Products__r.Non_Furniture_Product__c, Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Quantity_Invoiced__c, Row_Total__c, Custom_Price__c, Discount_Amount__c,
                                                         ProductImageUrl__c,Custom_Price_For_Credit_Memo__c, Sales_Order__r.Total_Paid__c, Sales_Order__r.Total_Refund__c, Row_Total_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c, (SELECT id,Quantity_To_Refund__c FROM Invoice_Line_Item__r) FROM SO_Line_Items__c WHERE Sales_Order__c =: SO_Obj.id and Bundle_Item__c = null ORDER BY ProductSKU__c DESC]);
            
            
            System.debug('soRelatedMap: '+soRelatedMap);
            System.debug('BundelSOitems: '+BundelSOitems);
            soRelatedList = getsoRelatedList(soRelatedMap, BundelSOitems);
            System.debug('soRelatedList: '+soRelatedList);
            
            if(soRelatedList.isEmpty() || soRelatedList == null)
            {
                isRefundItemsExist = false;
                Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'No Refund is to Generate.'));
            }
            
            if(soRelatedList.size()==1 && soRelatedList.values().get(0).SoItem != null && soRelatedList.values().get(0).SoItem.ProductSKU__c!=null && soRelatedList.values().get(0).SoItem.ProductSKU__c.contains('GUARDIAN')) {        // soRelatedList.values().get(0).SoItem.ProductSKU__c == 'GUARDIAN'
                
                blockRefund();
                
            }
            calculateGrandTotal(0);
            //grandTotal = ((subTot + taxAmount) - (disAmount)) - adjustRefundTot;
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+', Please contact to System Administrator.'));
            System.debug('exception Controller EX : '+e.getMessage()+', Cause : '+e.getCause()+', Line Number : '+e.getLineNumber());
        }
        System.debug('soRelatedList: '+soRelatedList);
    }
    
    public void blockRefund(){
        isDisabledRedundOption = true;
        selectRefund = 'GPP Cancellation';
        isselectRefund();
    }
    
    public void getTableData(){
        BundelSOitems = new map<Id,SO_Line_Items__c>([SELECT id, name, Bundle_Item_Relative_Discount_Amount__c, Products__r.Categories__c, DiscountAmount__c, Products__c, Products__r.RecordType.Name,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Price_For_Credit_Memo__c,DiscountAmount_For_Credit_Memo__c,Quantity_Refunded__c,Total_Weight_Pounds__c, Item__c,
                                                      ProductSKU__c,Product_Name__c,Products__r.Non_Furniture_Product__c, Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Quantity_Invoiced__c,Bundle_Item__r.Product__c, Bundle_Item__c, Tax_Amount_For_Credit_Memo__c,
                                                      ProductImageUrl__c, Sales_Order__r.Total_Paid__c, Sales_Order__r.Total_Refund__c,Row_Total_For_Credit_Memo__c, (SELECT id,Quantity_To_Refund__c FROM Invoice_Line_Item__r) from SO_Line_Items__c where Bundle_Item__c != null and Sales_Order__c =: SO_Obj.id]);
        
        soRelatedMap = new Map<id,SO_Line_Items__c>([SELECT id,name,Products__c, Bundle_Item_Relative_Discount_Amount__c, Products__r.Categories__c, Products__r.RecordType.Name,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Price_For_Credit_Memo__c,DiscountAmount_For_Credit_Memo__c,Quantity_Refunded__c,Total_Weight_Pounds__c, Item__c,
                                                     ProductSKU__c,Product_Name__c,Products__r.Non_Furniture_Product__c, Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Quantity_Invoiced__c, Bundle_Item__c, Tax_Amount_For_Credit_Memo__c,
                                                     ProductImageUrl__c,Custom_Price_For_Credit_Memo__c, Sales_Order__r.Total_Paid__c, Sales_Order__r.Total_Refund__c, Row_Total_For_Credit_Memo__c, (SELECT id,Quantity_To_Refund__c FROM Invoice_Line_Item__r) from SO_Line_Items__c where Sales_Order__c =: SO_Obj.id and Bundle_Item__c = null ORDER BY ProductSKU__c DESC]);
        
    }
    
    public static map<string,ItemsorderWrapper> getsoRelatedList(Map<id,SO_Line_Items__c> soRelatedMap, map<Id,SO_Line_Items__c> BundelSOitems) {
        String Price;
        Decimal priceTemp;
        Boolean checkisCustomPrice;
        
        map<string,ItemsorderWrapper> soRelatedList = new map<string,ItemsorderWrapper>();
        for(SO_Line_Items__c SoiItem: soRelatedMap.values())
        {
            //if(soRelatedMap.containsKey(SoiItem.id) && (soRelatedMap.get(SoiItem.id).Quantity_Invoiced__c != soRelatedMap.get(SoiItem.id).Quantity_Refunded__c))
            //{
            if(SoiItem.Custom_Price_For_Credit_Memo__c != null && SoiItem.Custom_Price_For_Credit_Memo__c >= 1) {
                Price = String.valueOf(SoiItem.Custom_Price_For_Credit_Memo__c / (SoiItem.Quantity__c == 0 ? 1 : SoiItem.Quantity__c) ) ;
                checkisCustomPrice = true;
            }
            else {
                Price = String.valueOf(SoiItem.Price_For_Credit_Memo__c);
                checkisCustomPrice = false;
            }
            if (Price == null) Price = '0';
            priceTemp = Decimal.valueOf(Price);
            Price = ''+priceTemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
            
            if(SoiItem.Products__r.recordtype.name == 'Bundled' && SoiItem.Quantity_Invoiced__c != SoiItem.Quantity_Refunded__c)
            {
                Decimal parentPromo = SoiItem.DiscountAmount_For_Credit_Memo__c;
                Decimal childDiscSum = 0.00;
                Integer childCount = 0;
                list<bundleItemsorderWrapper> BundelSOitemstemp = new list<bundleItemsorderWrapper>();
                for(SO_Line_Items__c BundelItem: BundelSOitems.values()) {
                    if(SoiItem.Products__c == BundelItem.Products__c && BundelItem.Quantity_Invoiced__c != BundelItem.Quantity_Refunded__c)
                    {
                        childCount++;
                    }
                }
                
                for(SO_Line_Items__c BundelItem: BundelSOitems.values())
                {
                    if(SoiItem.Products__c == BundelItem.Products__c && BundelItem.Quantity_Invoiced__c != BundelItem.Quantity_Refunded__c)
                    {
                        //childDiscSum += BundelItem.Sub_Total__c * 100 /
                        String quantity = String.valueOf(BundelItem.Quantity__c * SoiItem.Quantity__c);
                        BundelSOitemstemp.add(new bundleItemsorderWrapper(BundelItem,quantity,'0','0.00','0.00','0.00','0.00',''+BundelItem.Total_Weight_Pounds__c));
                    }
                }
                system.debug('BundelSOitemstemp ' +BundelSOitemstemp);
                if(BundelSOitemstemp.size()>0)
                {
                    soRelatedList.put(SoiItem.Manufacturer__c + SoiItem.id,new ItemsorderWrapper(SoiItem,BundelSOitemstemp,'0',Price,'0.00','0.00','0.00','0.00',''+SoiItem.Total_Weight_Pounds__c,'0.00',checkisCustomPrice));
                }
                else
                {
                    soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new ItemsorderWrapper(SoiItem,new list<bundleItemsorderWrapper>(),'0',Price,'0.00','0.00','0.00','0.00',''+SoiItem.Total_Weight_Pounds__c,'0.00',checkisCustomPrice));
                }
            }
            else
            {
                soRelatedList.put(SoiItem.Manufacturer__c+SoiItem.id,new ItemsorderWrapper(SoiItem,new list<bundleItemsorderWrapper>(),'0',Price,'0.00','0.00','0.00','0.00',''+SoiItem.Total_Weight_Pounds__c,'0.00',checkisCustomPrice));
            }
            //}
        }
        if(!soRelatedList.isEmpty() || soRelatedList != null)
        {
            for(ItemsorderWrapper itemWrapper: soRelatedList.values()) {
                if(itemWrapper.bundleList.size() == 0 && itemWrapper.SoItem.Products__r.recordType.Name == 'Bundled') {
                    soRelatedList.remove(itemWrapper.SoItem.Manufacturer__c+itemWrapper.SoItem.id);
                }
            }
        }
        return soRelatedList;
    }
    
    public void isselectRefund() {
        
        isRefundAll = false;
        customDiscount = 0.00;
        isreqField = false;
        isreqreasonField = false;
        isreqLocationField = false;
        isreqTrackingField = false;
        isreqShippingCharge = false;
        isreqConditionField = false;
        isreqCompField = false;
        isreqCanField = false;
        isreqCommField = false;
        isreqHandleField = false;
        isreqFormField = false;
        isPickupNeeded = false;
        
        grandTotal = 0;
        System.debug('selectRefund: '+selectRefund);
        System.debug('selectLocation: '+selectLocation);
        System.debug('isChargesApplymap: '+isChargesApplymap);
        selectLocation = 'none';
        selectConditioalFurniture = 'none';
        selectCompReason = 'none';
        selectCanReason = 'none';
        selectReason = selectRefund == 'Cancellation' ? 'Renegade' : 'none';
        selectForm = 'Original Form of Payment';
        selectShippingCharge = 'None';
        shippingChargesApply = 0;
        compensationComments = '';
        itemCount = 0;
        try
        {
            soRelatedList = new map<string,ItemsorderWrapper>();
            soRelatedList = getsoRelatedList(soRelatedMap, BundelSOitems);
            
            System.debug('soRelatedList Size: '+soRelatedList.size());
            if(soRelatedList.size() == 1 && selectRefund == 'Compensation') {
                for(ItemsorderWrapper itemWrapper: soRelatedList.values()) {
                    if(itemWrapper.SoItem.Products__r.recordType.Name == 'Protection Plan') {
                        Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'No Refund is to Generate.'));
                    }
                }
            }
            else if(selectRefund == 'Cancellation' || selectRefund == 'GPP Cancellation' )
            {
                isClickedonRefund();
            }
        }
        catch(exception e)
        {
            System.debug('Error: '+e.getMessage()+' | ' + e.getLineNumber());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));
        }
    }
    
    public void recalculateAdjustment() {
        if(selectRefund == 'GPP Cancellation') {
            return;
        }
        if (adjustRefundPercentage == null) {
            adjustRefundPercentage = 0;
        }
        decimal guardianPrice = 0;
        for(ItemsorderWrapper oneItemWrapper : soRelatedList.values()) {
            if(integer.valueof(oneItemWrapper.qty) != 0) {         // oneItemWrapper.qty > '0'
                if (((oneItemWrapper.SoItem.Product_Name__c != null && oneItemWrapper.SoItem.Product_Name__c.tolowercase().contains('guardian')) || oneItemWrapper.SoItem.Products__r.Non_Furniture_Product__c)) {
                    guardianPrice += decimal.valueof(oneItemWrapper.customPrice) * integer.valueof(oneItemWrapper.qty) - decimal.valueof(oneItemWrapper.disAmount);
                    System.debug('guardianPrice detecterd: ' + guardianPrice);
                }
            }
        }
        
        Decimal rewardPoints =  0;
        
        if( applayReward && subTot >= SO_Obj.DiscountAmount__c && (subTot - guardianPrice) >= SO_Obj.DiscountAmount__c) {
            rewardPoints = SO_Obj.DiscountAmount__c;
        }
        //- (applayReward ? rewardPoints: 0)
        System.debug('subTot: ' + subTot);
        System.debug('disAmount: ' + disAmount);
        if (selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
            adjustRefundTot = (( subTot - rewardPoints - guardianPrice  - disAmount ) * adjustRefundPercentage)/100;        //- guardianPrice
        }
        
        if(isChargesApplymap.containskey(selectLocation) && isChargesApplymap.get(selectLocation) && selectRefund == 'Cancellation' && ((selectLocation == 'Delivery Hub' || selectLocation == 'Customer Location') || SO_Obj.Customer_Name__r.Website == '2'))
        {
            //grandTotal = ((subTot + taxAmount) - (disAmount )) - (adjustRefundTot + shippingChargesApply);
            calculateGrandTotal(-(rewardPoints + shippingChargesApply) );
        }
        else
        {
            //grandTotal = ((subTot + taxAmount) - (disAmount )) - adjustRefundTot;
            calculateGrandTotal(-rewardPoints);
        }
    }
    
    void calculateGrandTotal(Decimal additional){
        grandTotal = (((subTot + taxAmount) - (disAmount)) - adjustRefundTot ) + additional;
    }
    public void isselectCustomerLocation() {
        selectShippingCharge = 'none';
        shippingFee = 0.00;
        isZeroShippingFeeBase = false;
        isRefundAll = false;
        grandTotal =  0;
        System.debug('selectRefund: '+selectRefund);
        System.debug('selectLocation: '+selectLocation);
        System.debug('isChargesApplymap: '+isChargesApplymap);
        try
        {
            if(selectRefund == 'Cancellation' || selectRefund == 'GPP Cancellation') {
                //ChargesApply = shippingChargesApply;
                System.debug('ChargesApply :: '+ChargesApply);
                
                System.debug('subTot: '+subTot);
                System.debug('adjustRefundTot: '+adjustRefundTot);
                adjustRefundTot = 0;
                if (selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
                    adjustRefundTot += ((subTot - disAmount) * adjustRefundPercentage)/100;
                }
                if(selectRefund == 'Cancellation' && (selectLocation == 'Delivery Hub' || selectLocation == 'Customer Location') ){
				    isZeroShippingFeeBase = (SO_Obj.Delivery_Company__r != null && (SO_Obj.Delivery_Company__r.Shipping_Base_Fee__c != null &&  SO_Obj.Delivery_Company__r.Shipping_Base_Fee__c != 0) ) ? false : true;
			    }
                // if(isChargesApplymap.containskey(selectLocation) && isChargesApplymap.get(selectLocation) && selectRefund == 'Cancellation' && ((selectLocation == 'Delivery Hub' || selectLocation == 'Customer Location') || SO_Obj.Customer_Name__r.Website == '2'))
                // {
                // 	//grandTotal = ((subTot + taxAmount) - (disAmount)) - (adjustRefundTot + shippingChargesApply);
                // 	calculateGrandTotal(-shippingChargesApply);
                // }
                // else
                // {
				//grandTotal = ((subTot + taxAmount) - (disAmount)) - adjustRefundTot;
                calculateGrandTotal(0);
			
			    //}
            }
            
            
            soRelatedList = getsoRelatedList(soRelatedMap, BundelSOitems);
            subTot = 0;
            adjustRefundTot = 0;
            taxAmount = 0;
            disAmount = 0;
            grandTotal = 0;
            //ChargesApply= 0.00;
            
            
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));
        }
    }
    
    public void shippingChargesCalculation() {
        isShowedShipingErrorMessage = false;
        isChangedShippingFee = true;
        onChangecalcInvoice();
    }
    
        public void isClickedonRefund() {
        // reset to Zero for every refresh
        customDiscount = 0.00;
        subTot = 0;
        adjustRefundTot = 0;
        taxAmount = 0;
        disAmount = 0;
        grandTotal = 0;
        //ChargesApply= 0.00;
        //shippingChargesApply = 0;
        applayReward = false;

        soRelatedList = new map<string,ItemsorderWrapper>();
        if(isRefundAll == true) {
            applayReward = true;
            try {
                for(SO_Line_Items__c SOItemList:soRelatedMap.values()) {
                    System.debug('SOItemList: '+SOItemList);
                    if(soRelatedMap.containsKey(SOItemList.id) && (soRelatedMap.get(SOItemList.id).Quantity_Invoiced__c != soRelatedMap.get(SOItemList.id).Quantity_Refunded__c) )
                    {
                        String qty;
                        String Price;
                        Decimal priceTemp;
                        if(SOItemList.Custom_Price_For_Credit_Memo__c != null && SOItemList.Custom_Price_For_Credit_Memo__c >= 1) {
                            Price = String.valueOf(SOItemList.Custom_Price_For_Credit_Memo__c / SOItemList.Quantity__c);
                            checkisCustomPrice = true;
                        }
                        else {
                            Price = String.valueOf(SOItemList.Price_For_Credit_Memo__c);
                            checkisCustomPrice = false;
                        }
                        if((selectRefund == 'Cancellation' && checkisCustomPrice == false) && SOItemList.Products__r.RecordType.Name == 'Bundled') {
                            qty = '0';
                        }
                        else {
                            qty = ''+(SOItemList.Quantity_Invoiced__c - SOItemList.Quantity_Refunded__c);
                        }
                        priceTemp = Decimal.valueOf(Price);
                        Price = ''+priceTemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                        Decimal subTotaltemp = integer.valueOf(qty) * (Decimal.valueOf(Price));
                        Decimal subTotal = subTotaltemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                        Decimal taxAmttemp = 0.00;
                        if (subTotal > 0) {
                            taxAmttemp = SOItemList.TaxAmount__c;        //(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                        }

                        System.debug('qty: '+qty);
                        System.debug('SOItemList.DiscountAmount_For_Credit_Memo__c: '+SOItemList.DiscountAmount_For_Credit_Memo__c);
                        System.debug('SOItemList.Quantity__c: '+SOItemList.Quantity__c);
                        System.debug('integer.valueOf(qty): '+integer.valueOf(qty));
                        Decimal disAmttemp = (integer.valueOf(qty) * SOItemList.DiscountAmount_For_Credit_Memo__c) / SOItemList.Quantity__c;
                        Decimal disAmt = disAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);

                        System.debug('subTotal: '+subTotal);
                        System.debug('disAmt: '+disAmt);
                        System.debug('Tax percent: '+SOItemList.Tax_Percent__c);

                        //taxAmttemp = SOItemList.TaxAmount__c;//(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                        System.debug('taxAmttemp: '+taxAmttemp);
                        Decimal taxAmt = taxAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                        System.debug('taxAmt: '+taxAmt);

                        Decimal rowTotal = SOItemList.Row_Total_For_Credit_Memo__c;        //(subTotal + taxAmt) - disAmt;

                        String custDis = '0.00';

                        subTot += subTotal;
                        disAmount += disAmt;
                        taxAmount += taxAmt;
                        //String prodName = SOItemList.Product_Name__c;
                        if (SOItemList.Product_Name__c != null && !SOItemList.Product_Name__c.tolowercase().contains('guardian') && !SOItemList.Products__r.Non_Furniture_Product__c && selectRefund != 'Edited order' && selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
                            adjustRefundTot += ((subTotal - disAmt) * adjustRefundPercentage)/100;
                        }

                        integer weight = Integer.valueOf(SOItemList.Total_Weight_Pounds__c != null ? SOItemList.Total_Weight_Pounds__c : 0);
                        integer shippingChargesApplytemp;

                        System.debug('weight :: '+weight);
                        //shippingChargesApplytemp = integer.valueOf((integer.valueOf(qty) * SOItemList.Total_Weight_Pounds__c) / SOItemList.Quantity__c);
                        //shippingChargesApply += shippingChargesApplytemp;
                        // System.debug('shippingChargesApplytemp :: '+shippingChargesApplytemp);
                        // System.debug('shippingChargesApply :: '+shippingChargesApply);


                        if(SOItemList.Products__r.recordtype.name == 'Bundled')
                        {
                            Decimal parentPromo = SOItemList.DiscountAmount_For_Credit_Memo__c;
                            Decimal childDiscSum = 0.00;
                            //SO_Line_Items__c lastChild = new SO_Line_Items__c();

                            BundelSOitemstemp = new list<bundleItemsorderWrapper>();
                            integer index = 1;

                            for(SO_Line_Items__c BundelItem: BundelSOitems.values())
                            {
                                if(SOItemList.Products__c == BundelItem.Products__c && BundelItem.Quantity_Invoiced__c != BundelItem.Quantity_Refunded__c)
                                {
                                    String bundleQty;
                                    if((selectRefund == 'Cancellation' && checkisCustomPrice == false) && SOItemList.Products__r.RecordType.Name == 'Bundled') {
                                        bundleQty = ''+((BundelItem.Quantity__c * SOItemList.Quantity__c) - BundelItem.Quantity_Refunded__c);
                                    }
                                    else {
                                        bundleQty = '0';
                                    }

                                    Decimal bundleSubTotaltemp = integer.valueOf(bundleQty) * BundelItem.Price_For_Credit_Memo__c;
                                    Decimal bundleSubTotal = bundleSubTotaltemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);

                                    Decimal bundleTaxAmttemp = 0.00;
                                    if (bundleSubTotal > 0) {
                                        bundleTaxAmttemp = BundelItem.TaxAmount__c;        //(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                                    }

                                    Decimal bundleDisAmttemp = ((integer.valueOf(bundleQty) * (BundelItem.DiscountAmount_For_Credit_Memo__c * BundelItem.Sub_Total__c / (SOItemList.Sub_Total__c != 0 ? SOItemList.Sub_Total__c : 1) ) ) / BundelItem.Quantity__c) / SOItemList.Quantity__c;
                                    //Decimal bundleDisAmttemp = ((Decimal.valueOf(bundleQty) * BundelItem.DiscountAmount_For_Credit_Memo__c ) / BundelItem.Quantity__c) / SOItemList.Quantity__c;
                                    Decimal bundleDisAmt = bundleDisAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);

                                    bundleTaxAmttemp = BundelItem.TaxAmount__c;        //(bundleSubTotal - bundleDisAmt) * (BundelItem.Tax_Percent__c / 100);
                                    Decimal bundleTaxAmt = bundleTaxAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);

                                    Decimal bundleRowTotal = BundelItem.Row_Total_For_Credit_Memo__c;        //(bundleSubTotal + bundleTaxAmt) - bundleDisAmt;

                                    childDiscSum += bundleDisAmt;
                                    subTot += bundleSubTotal;
                                    disAmount += bundleDisAmt;
                                    taxAmount += bundleTaxAmt;

                                    if (!SOItemList.Product_Name__c.tolowercase().contains('guardian') && !SOItemList.Products__r.Non_Furniture_Product__c && selectRefund != 'Edited order' && selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
                                        adjustRefundTot += ((bundleSubTotal - bundleDisAmt) * adjustRefundPercentage)/100;
                                    }
                                    System.debug('Bundle weight :: '+BundelItem.Total_Weight_Pounds__c);
                                    /*shippingChargesApplytemp = integer.valueOf((integer.valueOf(bundleQty) * BundelItem.Total_Weight_Pounds__c) / BundelItem.Quantity__c);
                                    shippingChargesApply += shippingChargesApplytemp;
                                    System.debug('Bundle shippingChargesApplytemp :: '+shippingChargesApplytemp);
                                    System.debug('Bundle shippingChargesApply :: '+shippingChargesApply);
                                    */
                                    BundelSOitemstemp.add(new bundleItemsorderWrapper(BundelItem,String.valueOf(BundelItem.Quantity__c * SOItemList.Quantity__c),bundleQty,String.valueOf(bundleSubTotal),String.valueOf(bundleTaxAmt),String.valueOf(bundleDisAmt),String.valueOf(bundleRowTotal),String.valueOf(BundelItem.Total_Weight_Pounds__c)));
                                }
                                index++;
                            }
                            if(parentPromo!= childDiscSum) {
                                disAmount += parentPromo-childDiscSum;
                                BundelSOitemstemp.get(0).DisAmount  = String.valueOf( Decimal.valueOf(BundelSOitemstemp.get(0).DisAmount) + parentPromo - childDiscSum );
                            }
                            system.debug('BundelSOitemstemp ' +BundelSOitemstemp);
                            if(BundelSOitemstemp.size()>0)
                            {
                                soRelatedList.put(SOItemList.Manufacturer__c+SOItemList.id,new ItemsorderWrapper(SOItemList,BundelSOitemstemp,String.valueOf(qty),Price,String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),'0.00',checkisCustomPrice));
                            }
                            else
                            {
                                soRelatedList.put(SOItemList.Manufacturer__c+SOItemList.id,new ItemsorderWrapper(SOItemList,new list<bundleItemsorderWrapper>(),String.valueOf(qty),Price,String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),'0.00',checkisCustomPrice));
                            }
                        }
                        else
                        {
                            soRelatedList.put(SOItemList.Manufacturer__c+SOItemList.id,new ItemsorderWrapper(SOItemList,new list<bundleItemsorderWrapper>(),String.valueOf(qty),Price,String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),'0.00',checkisCustomPrice));
                        }
                    }
                }
                if(!soRelatedList.isEmpty() || soRelatedList != null)
                {
                    for(ItemsorderWrapper itemWrapper: soRelatedList.values()) {
                        if(itemWrapper.bundleList.size() == 0 && itemWrapper.SoItem.Products__r.recordType.Name == 'Bundled') {
                            soRelatedList.remove(itemWrapper.SoItem.Manufacturer__c+itemWrapper.SoItem.id);
                        }
                    }
                }
                System.debug('soRelatedList.isEmpty: '+soRelatedList.isEmpty());
                if(soRelatedList.isEmpty())
                {
                    Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'No Refund is to Generate.'));
                }
                //ChargesApply = shippingChargesApply;
                System.debug('ChargesApply :: '+ChargesApply);
                //AdjRefund = ((subTot - disAmount) * 15)/100;

                System.debug('subTot: '+subTot);
                System.debug('adjustRefundTot: '+adjustRefundTot);
                if(selectRefund == 'Cancellation' || selectRefund == 'GPP Cancellation') {
                    /*if(isChargesApplymap.containskey(selectLocation) && isChargesApplymap.get(selectLocation) && selectRefund == 'Cancellation' && ((selectLocation == 'Delivery Hub' || selectLocation == 'Customer Location' ) || SO_Obj.Customer_Name__r.Website == '2'))
                    {
                        //grandTotal = ((subTot + taxAmount) - (disAmount)) - (adjustRefundTot + shippingChargesApply);
                        calculateGrandTotal(-shippingChargesApply);
                    }
                    else
                    {*/
                        //grandTotal = ((subTot + taxAmount) - (disAmount)) - adjustRefundTot;
                        calculateGrandTotal(0);

                    //}
                    if (selectLocation == 'LTL Carrier Pickup due to Damage' || selectLocation == 'LTL Return Enroute to Consignment') {
                        grandTotal = (subTot + taxAmount) - (disAmount);
                        customDiscount = grandTotal;
                    }
                }
            }
            catch(exception e)
            {
                System.debug('Error: '+e.getMessage()+' '+e.getCause()+' '+e.getLineNumber());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));
            }
        }
        else if(isRefundAll == false) {
            shippingFee = 0.00;
            try {
                soRelatedList = getsoRelatedList(soRelatedMap, BundelSOitems);
            }
            catch(exception e)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));
            }
            if(soRelatedList.isEmpty())
            {
                Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'No Refund is to Generate.'));
            }
            //AdjRefund = ((subTot - disAmount) * 15)/100;

            System.debug('subTot: '+subTot);
            System.debug('adjustRefundTot: '+adjustRefundTot);
            if(selectRefund == 'Cancellation' && selectRefund == 'GPP Cancellation') {
                calculateGrandTotal(0);
                if (selectLocation == 'LTL Carrier Pickup due to Damage' || selectLocation == 'LTL Return Enroute to Consignment') {
                    grandTotal = (subTot + taxAmount) - (disAmount);
                    customDiscount = grandTotal;
                }
            }
        }
        onChangecalcInvoice();
        System.debug('soRelatedList: '+soRelatedList);
    }
    
    void calculateShippingFee(Integer nonGuardianItemCount){
		System.debug('calculateShippingFee nonGuardianItemCount: ' + nonGuardianItemCount);
        showShippingAlert = false;
        Decimal shippingBaseFee = 0;
        Decimal shippingAdditionalFee = 0;
        Decimal result = 0.00;
        
		Set<String> locationsSet = new Set<String>{'Delivery Hub', 'Customer Location'};
		if(locationsSet.contains(selectLocation) && selectShippingCharge != 'none' && nonGuardianItemCount > 0){
            List<Shipment__c> shippingForSOList = [SELECT Delivery_Company__r.Shipping_Base_Fee__c, Delivery_Company__r.Additional_Item_Fee__c 
                                                FROM Shipment__c
                                                WHERE Related_Sales_Order__c = :SO_Obj.Id AND Delivery_Company__r.Shipping_Base_Fee__c != null AND Delivery_Company__r.Shipping_Base_Fee__c != 0
                                                ]; 
            
            if(shippingForSOList.isEmpty()){
                if(!isShowedShipingErrorMessage){ //shippingFee == 0.00 &&
                    showShippingAlert = true;
                    isShowedShipingErrorMessage = true;
                }
                return;
            }

            shippingBaseFee = shippingForSOList.get(0).Delivery_Company__r.Shipping_Base_Fee__c;
            shippingAdditionalFee = shippingForSOList.get(0).Delivery_Company__r.Additional_Item_Fee__c != null ? shippingForSOList.get(0).Delivery_Company__r.Additional_Item_Fee__c : 0;

			result =+ shippingBaseFee + (shippingAdditionalFee * (nonGuardianItemCount - 1));
			System.debug('calculateShippingFee result: ' + result);
			if(selectShippingCharge == 'Both Ways'){
				result *= 2;
			}
		}
		System.debug('calculateShippingFee result: '+ result);
		defaultShippingfee = result;
        if(!isChangedShippingFee){
            shippingFee = defaultShippingfee;
        }
        isChangedShippingFee = false;
	}

    public Decimal recalcPaymentDataForBundle(List<SO_Line_Items__c> parentBundlesList, Boolean isCalcChangeInvoise){
        SO_Line_Items__c parentItem_i = parentBundlesList.get(0);
        //for(SO_Line_Items__c parentItem_i : parentBundlesList){
            ItemsorderWrapper currentParentPageData = parentWraperDataMap.get(parentItem_i.Products__c);
            parentItem_i = currentParentPageData.SoItem;
            Integer parentQuantityToRefund = Integer.valueOf(parentItem_i.Quantity_Invoiced__c);
            Decimal childBundleRefundTotalTax = 0.00;
            Decimal childBundleNonRefundTotalTax = 0.00;
            
            for(bundleItemsorderWrapper bundlePageData : currentParentPageData.bundleList){
                Integer bundleQuanRefund = Integer.valueOf(bundlePageData.bundleqty);
                Integer bundelQuanNotRefundRest = Integer.valueOf(bundlePageData.bundleSoItem.Quantity_Invoiced__c - bundlePageData.bundleSoItem.Quantity_Refunded__c - bundleQuanRefund);    
                childBundleRefundTotalTax += ((bundlePageData.bundleSoItem.TaxAmount__c / bundlePageData.bundleSoItem.Quantity_Invoiced__c ) * bundleQuanRefund).setScale(2) ;
                childBundleNonRefundTotalTax += ((bundlePageData.bundleSoItem.TaxAmount__c / bundlePageData.bundleSoItem.Quantity_Invoiced__c )  * bundelQuanNotRefundRest).setScale(2);/// bundlePageData.bundleSoItem.Quantity_Invoiced__c
            }
            Decimal differenceRefunded = parentItem_i.TaxAmount__c - childBundleRefundTotalTax;
            Decimal differenceNonRefunded =  parentItem_i.TaxAmount__c - childBundleNonRefundTotalTax;
            Decimal finalDifference =  (differenceRefunded + differenceNonRefunded) - parentItem_i.TaxAmount__c;
            Decimal newTaxAmount = parentItem_i.TaxAmount__c - finalDifference;
            if(!isCalcChangeInvoise){
                parentBundleToUpdateForTaxIssueFix.add(new SO_Line_Items__c(Id = parentItem_i.id, Tax_Amount__c = newTaxAmount ) );
                parentWraperDataMap.remove(parentItem_i.Products__c);
            }
            return finalDifference;

    }

    public void onChangecalcInvoice() {
        itemCount = 0;
        subTot = 0;
        taxAmount = 0;
        disAmount = 0;
        grandTotal = 0;
        adjustRefundTot = 0;
        shippingChargesApply = 0;
        //ChargesApply= 0.00;
        customDiscount = 0.00;
        
        
        getqtyinv = new map<id,String>();
        getPrice = new map<id,String>();
        getcustomDisc = new map<id,String>();
        getisCustomPrice = new map<id,Boolean>();
        
        try {
            for(ItemsorderWrapper oneItemWrapper : soRelatedList.values()) {
                if(oneItemWrapper.qty >= '0') {
                    for(bundleItemsorderWrapper bundleItemWrapper : oneItemWrapper.bundleList) {
                        System.debug('bundleqty: '+bundleItemWrapper.bundleqty);
                        if(bundleItemWrapper.bundleqty >= '0') {
                            getqtyinv.put(bundleItemWrapper.bundleSoItem.id,bundleItemWrapper.bundleqty);
                            getPrice.put(bundleItemWrapper.bundleSoItem.id,''+bundleItemWrapper.bundleSoItem.Row_Total_For_Credit_Memo__c);
                            getcustomDisc.put(bundleItemWrapper.bundleSoItem.id, bundleItemWrapper.customDisc);
                        }
                    }
                    getqtyinv.put(oneItemWrapper.SoItem.id,oneItemWrapper.qty);
                    getPrice.put(oneItemWrapper.SoItem.id,oneItemWrapper.customPrice);
                    getcustomDisc.put(oneItemWrapper.SoItem.id,oneItemWrapper.customDisc);
                    getisCustomPrice.put(oneItemWrapper.SoItem.id,oneItemWrapper.iscustomPriceAvailable);
                    System.debug('Qty: '+getqtyinv.get(oneItemWrapper.SoItem.id));
                    System.debug('Price: '+getPrice.get(oneItemWrapper.SoItem.id));
                }
            }
            System.debug('getqtyinv: '+getqtyinv);
            System.debug('getPrice: '+getPrice);
            
            System.debug('soRelatedMap : '+soRelatedMap.values());
            soRelatedList = new map<string,ItemsorderWrapper>();
            for(SO_Line_Items__c SOItemList:soRelatedMap.values())
            {
                boolean first = true;
                System.debug('SOItemList Id: '+SOItemList.id);
                if(soRelatedMap.containsKey(SOItemList.id) && (soRelatedMap.get(SOItemList.id).Quantity_Invoiced__c != soRelatedMap.get(SOItemList.id).Quantity_Refunded__c) )
                {
                    if(getqtyinv.containsKey(SOItemList.Id) && getPrice.containsKey(SOItemList.id))
                    {
                        String qty = getqtyinv.get(SOItemList.Id);
                        System.debug('qty: '+qty);
                        System.debug('Price: '+getPrice.get(SOItemList.Id));
                        Decimal subTotaltemp = integer.valueOf(qty) * (Decimal.valueOf(getPrice.get(SOItemList.Id)));
                        Decimal subTotal = subTotaltemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                        Decimal taxAmttemp = 0.00;
                        if (subTotal > 0) {
                            taxAmttemp = SOItemList.TaxAmount__c * integer.valueOf(qty) /  (SOItemList.Quantity__c > 0 ? SOItemList.Quantity__c : 1);        //(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                        }
                        
                        Decimal disAmttemp = (integer.valueOf(qty) * SOItemList.DiscountAmount_For_Credit_Memo__c) /  (SOItemList.Quantity__c > 0 ? SOItemList.Quantity__c : 1);
                        Decimal disAmt = disAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                        SOItemList.Tax_Percent__c = SOItemList.Tax_Percent__c == null ? 0 : SOItemList.Tax_Percent__c;
                        // Decimal taxAmttemp = SOItemList.TaxAmount__c;//(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                        Decimal taxAmt = taxAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                        
                        Decimal rowTotal = SOItemList.Row_Total_For_Credit_Memo__c;        //(subTotal + taxAmt) - disAmt;
                        
                        String custDis = getcustomDisc.get(SOItemList.id);
                        
                        subTot += subTotal;
                        disAmount += disAmt;
                        taxAmount += taxAmt;

                        Boolean isNotGuardian = false;
                        if (SOItemList.Product_Name__c != null && !SOItemList.Product_Name__c.tolowercase().contains('guardian') ){ 
                            isNotGuardian = true;
                            if(!SOItemList.Products__r.Non_Furniture_Product__c && selectRefund != 'Edited order' && selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
                                adjustRefundTot += ((subTotal - disAmt) * adjustRefundPercentage)/100;
                            }
                        }
                        
                        customDiscount += Decimal.valueOf(custDis);
                        
                        integer weight = Integer.valueOf(SOItemList.Total_Weight_Pounds__c);
                        integer shippingChargesApplytemp;
                        
                        // shippingChargesApplytemp = integer.valueOf((integer.valueOf(qty) * SOItemList.Total_Weight_Pounds__c) / (SOItemList.Quantity__c > 0 ? SOItemList.Quantity__c : 1));
                        // shippingChargesApply += shippingChargesApplytemp;
                        
                        
                        //------------------------------------------------------------------------------------------------------------------
                        
                        if(selectRefund=='Cancellation' || selectRefund=='GPP Cancellation') {
                            soRelatedMap.get(SOItemList.id).Quantity__c -= soRelatedMap.get(SOItemList.id).Quantity_Refunded__c;
                        }
                        
                        //------------------------------------------------------------------------------------------------------------------
                        
                        Decimal different = 0.00;
                        Decimal bundelDisc = 0.00;
                        if(SOItemList.Products__r.recordtype.name == 'Bundled')
                        {
                            for(SO_Line_Items__c BundelItem : BundelSOitems.values())
                            {
                                if(SOItemList.Products__c == BundelItem.Products__c)
                                {
                                    //different += ((decimal.valueOf(getqtyinv.get(BundelItem.id) !=null ? getqtyinv.get(BundelItem.id) : '0' ) * ( (BundelItem.DiscountAmount_For_Credit_Memo__c !=null ? BundelItem.DiscountAmount_For_Credit_Memo__c : 0) * BundelItem.Sub_Total__c / SOItemList.Sub_Total__c   ) )  / (BundelItem.Quantity__c !=null ? BundelItem.Quantity__c : 1 ) / (SOItemList.Quantity__c !=null ? SOItemList.Quantity__c : 1));
                                    if (SOItemList.Sub_Total__c > 0 && BundelItem.Quantity__c != 0 && SOItemList.Quantity__c != 0) {
                                        different += BundelItem.Quantity__c * ((BundelItem.DiscountAmount_For_Credit_Memo__c !=null ? BundelItem.DiscountAmount_For_Credit_Memo__c : 0) * BundelItem.Sub_Total__c / (SOItemList.Sub_Total__c != 0 ? SOItemList.Sub_Total__c : 1) ) / BundelItem.Quantity__c / SOItemList.Quantity__c;
                                    }
                                    System.debug('different: ' + different);
                                    bundelDisc = BundelItem.DiscountAmount_For_Credit_Memo__c !=null ? BundelItem.DiscountAmount_For_Credit_Memo__c : 0;
                                }
                                //different = different.setScale(2, RoundingMode.HALF_UP);
                            }
                            System.debug('bundelDisc: ' + bundelDisc);
                            System.debug('different: ' + different);
                            different = bundelDisc - different;
                            
                        }
                        System.debug('fin different: ' + different);
                        

                        
                        if(SOItemList.Products__r.recordtype.name == 'Bundled')
                        {
                            //double bundleTotal = 0;
                            BundelSOitemstemp = new list<bundleItemsorderWrapper>();
                            
                            Decimal parentPromo = SOItemList.DiscountAmount_For_Credit_Memo__c;
                            Decimal childDiscSum = 0.00;
                            integer childCount =0;
                            integer applyChildDiscCount = 0;

                            Boolean isSectional = false;
                            for(SO_Line_Items__c BundelItem: BundelSOitems.values())
                            {
                                      
                                if(SOItemList.Products__c == BundelItem.Products__c && BundelItem.Quantity_Invoiced__c != BundelItem.Quantity_Refunded__c)
                                {
                                    if(SOItemList.Products__r != null && SOItemList.Products__r.categories__c != null && SOItemList.Products__r.categories__c.toLowerCase().contains('sectional') && !isSectional){ 
                                        isSectional = true;
                                        itemCount++;
                                    }
                                    childCount += Integer.valueOf(BundelItem.Quantity_Invoiced__c - BundelItem.Quantity_Refunded__c);
                                    String quantity = String.valueOf(BundelItem.Quantity_Invoiced__c !=null ? BundelItem.Quantity_Invoiced__c : 0);
                                    //String quantity = String.valueOf((BundelItem.Quantity__c !=null ? BundelItem.Quantity__c : 0) * (SOItemList.Quantity__c !=null ? SOItemList.Quantity__c : 0) );
                                    
                                    Decimal bundleSubTotaltemp = decimal.valueOf(getqtyinv.get(BundelItem.id) !=null ? getqtyinv.get(BundelItem.id) : '0' ) * (BundelItem.Price_For_Credit_Memo__c !=null ? BundelItem.Price_For_Credit_Memo__c : 0);
                                    
                                    Decimal bundleSubTotal = bundleSubTotaltemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                                    
                                    Decimal bundleTaxAmttemp = 0.00;
                                    if (bundleSubTotal > 0 && BundelItem.Quantity__c > 0) {
                                        //bundleTaxAmttemp = BundelItem.TaxAmount__c * integer.valueOf(getqtyinv.get(BundelItem.id)) / BundelItem.Quantity__c;        //(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                                        bundleTaxAmttemp = (BundelItem.TaxAmount__c / BundelItem.Quantity_Invoiced__c) * integer.valueOf(getqtyinv.get(BundelItem.id)) ; //* integer.valueOf(getqtyinv.get(BundelItem.id)) / BundelItem.Quantity__c;        //(subTotal - disAmt) * (SOItemList.Tax_Percent__c / 100);
                                    }
                                    System.debug('getqtyinv.get(BundelItem.id): ' + getqtyinv.get(BundelItem.id));
                                    System.debug('BundelItem.DiscountAmount_For_Credit_Memo__c: ' + BundelItem.DiscountAmount_For_Credit_Memo__c);
                                    System.debug('undelItem.Sub_Total__c: ' + BundelItem.Sub_Total__c);
                                    System.debug('SOItemList.Sub_Total__c: ' + SOItemList.Sub_Total__c);
                                    System.debug('BundelItem.Quantity__c: ' + BundelItem.Quantity__c);
                                    System.debug('SOItemList.Quantity__c: ' + SOItemList.Quantity__c);
                                    //Decimal bundleDisAmttemp = SOItemList.Sub_Total__c <= 0 ? 0 : ((decimal.valueOf(getqtyinv.get(BundelItem.id) !=null ? getqtyinv.get(BundelItem.id) : '0' ) * ( (BundelItem.DiscountAmount_For_Credit_Memo__c !=null ? BundelItem.DiscountAmount_For_Credit_Memo__c : 0) * BundelItem.Sub_Total__c / SOItemList.Sub_Total__c   ) )  / (BundelItem.Quantity__c !=null ? BundelItem.Quantity__c : 1 ) / (SOItemList.Quantity__c !=null ? SOItemList.Quantity__c : 1));
                                    decimal bundleDisAmttemp;
                                    if (SOItemList.Sub_Total__c <= 0 || decimal.valueOf(getqtyinv.get(BundelItem.id)) == null || BundelItem.Bundle_Item_Relative_Discount_Amount__c == null || BundelItem.Bundle_Item_Relative_Discount_Amount__c == 0) {
                                        bundleDisAmttemp = 0;
                                    }
                                    else{
                                        bundleDisAmttemp = (BundelItem.Quantity__c !=0 ? (decimal.valueOf(getqtyinv.get(BundelItem.id)) * BundelItem.Bundle_Item_Relative_Discount_Amount__c / BundelItem.Quantity__c) : 0 ) ;
                                    //    bundleDisAmttemp = (BundelItem.Quantity__c !=0 ? decimal.valueOf(getqtyinv.get(BundelItem.id)) * BundelItem.Bundle_Item_Relative_Discount_Amount__c / BundelItem.Quantity__c : 0 ) ;
                                    }
                                    if( decimal.valueOf(getqtyinv.get(BundelItem.id)) > 0 ) {//BundelItem.Quantity_Refunded__c
                                        applyChildDiscCount+=Integer.valueOf(getqtyinv.get(BundelItem.id));
                                    }
                                    
                                    Decimal bundleDisAmt = bundleDisAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                                    
                                    //Decimal bundleTaxAmttemp = BundelItem.TaxAmount__c;//(bundleSubTotal - bundleDisAmt) * ( (BundelItem.Tax_Percent__c !=null ? BundelItem.Tax_Percent__c : 0) / 100);
                                    Decimal bundleTaxAmt = bundleTaxAmttemp.setScale(2);        //.setScale(2, RoundingMode.HALF_UP);
                                    

                                    Decimal bundleRowTotal = BundelItem.Row_Total_For_Credit_Memo__c !=null ? BundelItem.Row_Total_For_Credit_Memo__c : 0;        //(bundleSubTotal + bundleTaxAmt) - bundleDisAmt;
                                    
                                    custDis = getcustomDisc.get(BundelItem.id);
                                    
                                    customDiscount += Decimal.valueOf(custDis);
                                    
                                    childDiscSum += bundleDisAmt;
                                    subTot += bundleSubTotal;
                                    disAmount += bundleDisAmt;         //BundelItem.DiscountAmount__c!= null ? BundelItem.DiscountAmount__c : 0 ;
                                    taxAmount += bundleTaxAmt;
                                    
                                    if (SOItemList.Product_Name__c!=null && !SOItemList.Product_Name__c.tolowercase().contains('guardian') ){
                                        if(!isSectional){
                                            itemCount += Integer.valueOf(getqtyinv.get(BundelItem.id));
                                        } 
                                        if(!SOItemList.Products__r.Non_Furniture_Product__c && selectRefund != 'Edited order' && selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
                                            adjustRefundTot += ((bundleSubTotal - bundleDisAmt) * adjustRefundPercentage)/100;
                                        }
                                    }
                                    // if(BundelItem.Quantity__c != null && BundelItem.Quantity__c > 0){
                                    //     shippingChargesApplytemp = integer.valueOf( (decimal.valueOf(getqtyinv.get(BundelItem.id) != null ? getqtyinv.get(BundelItem.id) : '0') * (BundelItem.Total_Weight_Pounds__c !=null ? BundelItem.Total_Weight_Pounds__c : 0) ) / BundelItem.Quantity__c );
                                    //     shippingChargesApply += shippingChargesApplytemp;
                                    // }
                                    
                                    if(selectRefund == 'Cancellation' ) {
                                        BundelItem.Quantity__c -= BundelItem.Quantity_Refunded__c;
                                    }
                                    BundelSOitemstemp.add(new bundleItemsorderWrapper(BundelItem, quantity, getqtyinv.get(BundelItem.id), String.valueOf(bundleSubTotal),String.valueOf(bundleTaxAmt),String.valueOf(bundleDisAmt),String.valueOf(bundleRowTotal),String.valueOf(BundelItem.Total_Weight_Pounds__c), custDis));
                                    
                                }
                            }
                            System.debug('applyChildDiscCount: '+ applyChildDiscCount);
                            System.debug('childCount: '+ childCount);
                            
                            if(applyChildDiscCount==childCount && parentPromo != childDiscSum) {
                                disAmount += parentPromo - childDiscSum;
                                //BundelSOitemstemp.get(BundelSOitemstemp.size()-1).bundleSoItem.DiscountAmount__c += parentPromo-childDiscSum;
                                BundelSOitemstemp.get(0).DisAmount  = String.valueOf( Decimal.valueOf(BundelSOitemstemp.get(0).DisAmount) + parentPromo - childDiscSum );
                            }
                            system.debug('BundelSOitemstemp ' +BundelSOitemstemp);
                            if(BundelSOitemstemp.size()>0)
                            {

                                soRelatedList.put(SOItemList.Manufacturer__c+SOItemList.id,new ItemsorderWrapper(SOItemList,BundelSOitemstemp,String.valueOf(qty),getPrice.get(SOItemList.Id),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),String.valueOf(custDis),getisCustomPrice.get(SOItemList.Id)));
                                parentWraperDataMap.put(SOItemList.Products__c, new ItemsorderWrapper(SOItemList,BundelSOitemstemp,String.valueOf(qty),getPrice.get(SOItemList.Id),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),String.valueOf(custDis),getisCustomPrice.get(SOItemList.Id)));
                                taxAmount += (subTot > 0 ? recalcPaymentDataForBundle(new List<SO_Line_Items__c>{SOItemList}, true) : 0);
                            }
                            else
                            {
                                soRelatedList.put(SOItemList.Manufacturer__c+SOItemList.id,new ItemsorderWrapper(SOItemList,new list<bundleItemsorderWrapper>(),String.valueOf(qty),getPrice.get(SOItemList.Id),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),String.valueOf(custDis),getisCustomPrice.get(SOItemList.Id)));
                            }
                        }
                        else
                        {   
                            if(isNotGuardian){
                                itemCount += Integer.valueOf(getqtyinv.get(SOItemList.id));  
                            }
                            soRelatedList.put(SOItemList.Manufacturer__c+SOItemList.id,new ItemsorderWrapper(SOItemList,new list<bundleItemsorderWrapper>(),String.valueOf(qty),getPrice.get(SOItemList.Id),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal),String.valueOf(weight),String.valueOf(custDis),getisCustomPrice.get(SOItemList.Id)));
                        }
                    }
                }
            }
            if(!soRelatedList.isEmpty() || soRelatedList != null)
            {
                for(ItemsorderWrapper itemWrapper: soRelatedList.values()) {
                    if(itemWrapper.bundleList.size() == 0 && itemWrapper.SoItem.Products__r.recordType.Name == 'Bundled') {
                        soRelatedList.remove(itemWrapper.SoItem.Manufacturer__c+itemWrapper.SoItem.id);
                    }
                }
            }
            //ChargesApply = shippingChargesApply;
            System.debug('soRelatedList: '+soRelatedList);
            if(selectRefund == 'Compensation' || selectLocation == 'LTL Carrier Pickup due to Damage' || selectLocation == 'LTL Return Enroute to Consignment')
            {
                //AdjRefund = 0;
                adjustRefundTot = 0;
            }
            else {
                //AdjRefund = ((subTot - disAmount) * 15)/100;
            }
            System.debug('selectLocation: '+selectLocation);
            System.debug('subTot: '+subTot);
            System.debug('adjustRefundTot: '+adjustRefundTot);
            
            if(selectRefund == 'Cancellation' || selectRefund == 'GPP Cancellation') {
                Decimal reward = 0.00;
                if(applayReward && SO_Obj.DiscountAmount__c>0 && subTot >= SO_Obj.DiscountAmount__c  ) {
                    reward = SO_Obj.DiscountAmount__c;
                }
                Boolean conditionFlag = true;
                calculateGrandTotal(-reward);
                recalculateAdjustment();
                calculateShippingFee(itemCount);
                calculateGrandTotal( -(reward + shippingFee));

            }
            System.debug('soRelatedList.isEmpty: '+soRelatedList.isEmpty());
            if(soRelatedList.isEmpty())
            {
                Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'No Refund is to Generate.'));
            }
            if((selectLocation != 'Customer Location' && selectLocation !='Delivery Hub') || selectRefund == 'Compensation') {
                ChargesApply = 0;
            }
            System.debug('ChargesApply: '+ChargesApply);
        }
        Catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));
        }
    }
    
    public PageReference submitRefund() {
        if(refundLocker.isLocked()) {
            return null;
        }
        refundLocker.lock();

        isreqField = false;
        isreqreasonField = false;
        isreqLocationField = false;
        isreqTrackingField = false;
        isreqConditionField = false;
        isreqCompField = false;
        isreqCanField = false;
        isreqCommField = false;
        isreqHandleField = false;
        isreqFormField = false;
        isreqShippingCharge = false;
        PageReference pr;
        Transaction__c soTransaction;
        
        selectedSOItemList = new list<SO_Line_Items__c>();
        //For Simple and Main Bundle Quantity
        getqtyinv = new map<Id,String>();
        getsubTotalinv = new map<Id,String>();
        getdisAmtinv = new map<Id,String>();
        gettaxAmtinv = new map<Id,String>();
        getrowTinv = new map<Id,String>();
        getcustomDisc = new map<Id,String>();
        
        try {
            for(ItemsorderWrapper oneItem: soRelatedList.values()) {
                if(oneItem.qty == '1' || oneItem.qty > '0') {
                    selectedSOItemList.add(oneItem.SoItem);
                    getqtyinv.put(oneItem.SoItem.Id,oneItem.qty);
                    getsubTotalinv.put(oneItem.SoItem.Id,oneItem.subTotal);
                    getdisAmtinv.put(oneItem.SoItem.Id, oneItem.disAmount);         
                    gettaxAmtinv.put(oneItem.SoItem.Id,oneItem.taxAmount);
                    getrowTinv.put(oneItem.SoItem.Id,oneItem.rowTotal);
                    getcustomDisc.put(oneItem.SoItem.Id,oneItem.customDisc);
                }
                else if(oneItem.qty == '0') {
                    for(bundleItemsorderWrapper bundleItemWrapper : oneItem.bundleList) {
                        System.debug('bundleqty: '+bundleItemWrapper.bundleqty);
                        if(bundleItemWrapper.bundleqty > '0' || bundleItemWrapper.bundleqty == '1') {
                            selectedSOItemList.add(bundleItemWrapper.bundleSoItem);
                            
                            getqtyinv.put(bundleItemWrapper.bundleSoItem.id,bundleItemWrapper.bundleqty);
                            getsubTotalinv.put(bundleItemWrapper.bundleSoItem.id,bundleItemWrapper.subTotal);
                            getdisAmtinv.put(bundleItemWrapper.bundleSoItem.id,bundleItemWrapper.disAmount );
                            gettaxAmtinv.put(bundleItemWrapper.bundleSoItem.id,bundleItemWrapper.taxAmount);
                            getrowTinv.put(bundleItemWrapper.bundleSoItem.id,bundleItemWrapper.rowTotal);
                            getcustomDisc.put(bundleItemWrapper.bundleSoItem.Id, bundleItemWrapper.customDisc);
                        }
                    }
                }
            }
            
            System.debug('selectedSOItemList: '+selectedSOItemList);
            System.debug('grandTotal =  ' + grandTotal);
            System.debug('soRelatedList.values()[0].SoItem.Sales_Order__r.Total_Paid__c =  ' + soRelatedList.values()[0].SoItem.Sales_Order__r.Total_Paid__c);
            System.debug('soRelatedList.values()[0].SoItem.Sales_Order__r.Total_Refund__c =  ' + soRelatedList.values()[0].SoItem.Sales_Order__r.Total_Refund__c);
            
            if(invObj.Order_Transaction_Type__c == null) {
                isreqField = true;
                if(selectRefund == 'none') {
                    isreqreasonField = true;
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
            }
            else if( (SO_Obj.Invoices_Changed_to_Manual_Payment__c == 0 && grandTotal > (soRelatedList.values()[0].SoItem.Sales_Order__r.Total_Paid__c - soRelatedList.values()[0].SoItem.Sales_Order__r.Total_Refund__c))
                ||(SO_Obj.Invoices_Changed_to_Manual_Payment__c > 0 && grandTotal > (SO_Obj.Total_Paid__c - SO_Obj.Total_Refund__c))
            ) {
                System.debug('Refund Page change to manual payment update '+ SO_Obj.Total_Paid__c);
                System.debug('Refund Page change to manual payment update '+ SO_Obj.Total_Paid__c);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Refund amount is greater than the order amount.'));
            }
            else if(selectRefund == 'none') {
                isreqreasonField = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
            }
            else if(selectRefund != 'none') {
                System.debug('Order_Transaction_Type '+invObj.Order_Transaction_Type__c);
                soTransaction = [Select id,Amount__c,Payment_Method__c,Refunded_Amount__c,Balance_Amount__c from Transaction__c where id=:invObj.Order_Transaction_Type__c];
                System.debug('Sales Order transaction'+soTransaction);
                
                System.debug('selectLocation '+selectLocation);
                System.debug('trackingNumber '+ trackingNumber);
                
                if(selectRefund == 'Cancellation' || selectRefund == 'GPP Cancellation') {
                    System.debug('-- Select Refund is Cancellation and Payment Type is Not Null --');
                    if(selectCanReason == 'none') {
                        isreqCanField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else if (selectCanReason == 'Other - Detail in Comments Below' && (compensationComments == null || compensationComments.trim() == '')) {
                        isreqCommField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    if(selectReason == 'none' && selectRefund != 'GPP Cancellation') {
                        isreqHandleField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    if(selectLocation == 'none' && selectRefund != 'GPP Cancellation') {
                        isreqLocationField = true;
                        if(selectConditioalFurniture == 'none') {
                            isreqConditionField = true;
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else if ((selectLocation == 'LTL Return Enroute to Consignment') && (trackingNumber == null || trackingNumber == '') && selectRefund != 'GPP Cancellation') {
                        isreqTrackingField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else if(selectConditioalFurniture == 'none' && selectRefund != 'GPP Cancellation') {
                        isreqConditionField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else {
                        if(selectedSOItemList.size() > 0) {
                            System.debug('Inserting a Purchase Order');
                            
                            System.debug('soTransaction.Balance_Amount__c :  '+ soTransaction.Balance_Amount__c);
                            System.debug('Cancellation Total Amount: '+grandTotal);
                            if((SO_Obj.Invoices_Changed_to_Manual_Payment__c == 0 && soTransaction.Balance_Amount__c < grandTotal) || (SO_Obj.Invoices_Changed_to_Manual_Payment__c > 0 && grandTotal > (SO_Obj.Total_Paid__c - SO_Obj.Total_Refund__c))) {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'The refund Amount is greater than available Amount'));
                            }
                            else {
                                RecordType payableType = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Invoice_Line_Item__c' AND Name = 'Payable Line Items'];
                                
                                System.debug('SO_Obj: '+SO_Obj);
                                invObj = new Invoice__c();
                                
                                invobj.RecordTypeId = [select id from RecordType where name='payables' and sobjecttype='invoice__c'].id;
                                invObj.Customer_Name__c = SO_Obj.Customer_Name__c;
                                invObj.Email__c = SO_Obj.Customer_Email__c;
                                invobj.Items_invoiced__c = getqtyinv.size();
                                invobj.Payment_Method__c = soTransaction.Payment_Method__c;
                                if (SO_Obj.Payment_Method__c != 'Credit Card (Authorize.net)' && SO_Obj.Payment_Method__c != 'Credit Card' && SO_Obj.Payment_Method__c != 'PayPal' && SO_Obj.Payment_Method__c != 'PayPal Express Checkout') {
                                    invobj.Manual_Refund__c = true;
                                }
                                invobj.Order_Transaction_Type__c = soTransaction.id;
                                invobj.Reason_for_Refund__c = selectRefund;
                                invobj.Adjustment_Refund_Percentage__c = adjustRefundPercentage;
                                invobj.Location_Of_Furniture__c = selectLocation;
                                invobj.Condition_Of_Furniture__c = selectConditioalFurniture;
                                invobj.Tracking_Number__c = trackingNumber;
                                invobj.Refund_Handle_By__c = selectReason;
                                /*Decimal total = SO_Obj.Total_Due__c;
                                if(applayReward && total >= SO_Obj.DiscountAmount__c ){
                                    total -= SO_Obj.DiscountAmount__c;
                                }*/
                                System.debug('invObj: '+invObj);
                                //System.debug('grandTotal cancel: '+ grandTotal);
                                invobj.Credit_Memo_Refund_Amount__c = grandTotal;
                                
                                invobj.Cancellation_Reason__c = selectCanReason;
                                invobj.Comments__c = compensationComments;
                                System.debug('invObj: '+invObj);
                                invobj.ShippingCharges__c = shippingFee;
                                invobj.Default_Shipping_fee__c = defaultShippingfee;
                                if(selectLocation != 'LTL Carrier Pickup due to Damage' && selectLocation != 'LTL Return Enroute to Consignment') {
                                    invobj.Shipping_Charge__c = selectShippingCharge;
                                }
                                else{
                                    invobj.Shipping__c = 0.00;
                                }
                                system.debug('ChargesApply = ' + ChargesApply);
                                if(isChargesApplymap.containskey(selectLocation) && isChargesApplymap.get(selectLocation)) {
                                    invobj.Pickup_Needed__c = isPickupNeeded;
                                    //invobj.Total_Weight_Pounds__c = ChargesApply;
                                }
                                else {
                                    invobj.Pickup_Needed__c = false;
                                    invobj.Total_Weight_Pounds__c = 0.00;
                                }
                                if (invobj.Total_Weight_Pounds__c == null) {
                                    invobj.Total_Weight_Pounds__c = 0.00;
                                }
                                system.debug('invobj.Total_Weight_Pounds__c = ' + invobj.Total_Weight_Pounds__c);
                                invObj.Sales_Order__c = SO_Obj.id;
                                //invObj.Refund_Approval_Status__c ='Refund Approved';
                                insert invObj;
                                System.debug('invObj : '+invObj);
                                decimal invoisItemDiscount = 0.000;
                                System.debug('invObj: '+invObj);
                                if(invObj.id != null) {
                                    itemInvoiceList = new list<Invoice_Line_Item__c>();
                                    integer guardianCount = 0;
                                    for(SO_Line_Items__c SOItemList : selectedSOItemList) {
                                        if(SOItemList.ProductSKU__c != null && SOItemList.ProductSKU__c.contains('GUARDIAN')) {
                                            ++guardianCount;
                                        }
                                    }
                                    for(SO_Line_Items__c SOItemList : selectedSOItemList) {
                                        Invoice_Line_Item__c itemInvoice = new Invoice_Line_Item__c();
                                        itemInvoice.RecordTypeId = payableType.Id;
                                        itemInvoice.Invoice__c = invObj.id;
                                        itemInvoice.Sales_Order__c = SOItemList.Sales_Order__c;
                                        itemInvoice.Items_invoiced__c = SOItemList.id;
                                        String strQ2I = getqtyinv.get(SOItemList.id);
                                        itemInvoice.Quantity_To_Refund__c = Integer.valueof(strQ2I.trim());
                                        itemInvoice.Tax_Amount_Hidden__c = Decimal.valueof(gettaxAmtinv.get(SOItemList.id));

                                        if(SOItemList.Products__r.recordtype.name == 'Bundled' && parentWraperDataMap.containsKey(SOItemList.Products__c) ){
                                            itemInvoice.Tax_Amount_Hidden__c += recalcPaymentDataForBundle( new List<SO_Line_Items__c>{SOItemList}, false);
                                        }
                                        itemInvoice.Sub_Total__c = Decimal.valueof(getsubTotalinv.get(SOItemList.id));
                                        Decimal curentReward = SO_Obj.DiscountAmount__c;
                                        if(selectRefund != 'GPP Cancellation') {
                                            curentReward = (curentReward / ( (selectedSOItemList.size() - guardianCount) != 0 ? selectedSOItemList.size() - guardianCount : 1 ) ).setScale(2);
                                        }
                                        if(SOItemList.ProductSKU__c != null && SOItemList.ProductSKU__c.toLowerCase().contains('guardian')) {        // GUARDIAN
                                            curentReward = 0;
                                        }
                                        
                                        invoisItemDiscount += curentReward;
                                        itemInvoice.Discount_Amount_Hidden__c = Decimal.valueof(getdisAmtinv.get(SOItemList.id)) + (applayReward && selectRefund != 'GPP Cancellation' ? curentReward : 0);
                                        System.debug('Refund Quantity: ' + itemInvoice.Quantity_To_Refund__c);
                                        
                                        
                                        /*if(selectLocation == 'LTL Carrier Pickup due to Damage' || selectLocation == 'LTL Return Enroute to Consignment') {
                                            itemInvoice.Custom_Refund__c = Decimal.valueof(getcustomDisc.get(SOItemList.id));
                                        }*/
                                        
                                        itemInvoiceList.add(itemInvoice);
                                    }
                                    update parentBundleToUpdateForTaxIssueFix;
                                    if(applayReward && selectRefund != 'GPP Cancellation' ) {
                                        Decimal totalReward = SO_Obj.DiscountAmount__c;
                                        System.debug('totalReward: '+ SO_Obj.DiscountAmount__c);
                                        System.debug('invoisItemDiscount: '+ invoisItemDiscount.setScale(2));
                                        System.debug('invoisItemDiscount: '+ invoisItemDiscount.round(System.RoundingMode.HALF_DOWN));
                                        System.debug('invoisItemDiscount: '+ invoisItemDiscount.round(System.RoundingMode.UP));
                                        System.debug('selectedSOItemList.size(): '+ selectedSOItemList.size());
                                        
                                        itemInvoiceList.get(0).Discount_Amount_Hidden__c += ( totalReward - invoisItemDiscount.setScale(2));
                                    }
                                    
                                    Decimal tatolItemRewardPoint=0.00;
                                    System.debug('invObj: '+invObj);
                                    for(Invoice_Line_Item__c invoice_i : itemInvoiceList) {
                                        tatolItemRewardPoint += invoice_i.Discount_Amount_Hidden__c;
                                    }
                                    //itemInvoiceList.get(itemInvoiceList.size()-1).Discount_Amount_Hidden__c += (applayReward ? SO_Obj.DiscountAmount__c - tatolItemRewardPoint : 0);
                                    
                                    if(itemInvoiceList.size() != 0 || itemInvoiceList.size() > 0) {
                                        insert itemInvoiceList;
                                        System.debug('isChecked: '+isChecked);
                                        if(isChecked == true) {
                                            invobj.Notify_Customer_by_Email__c = isChecked;
                                            invobj.Number_of_Invoices_Sent__c = 1;
                                            Update invobj;
                                        }
                                        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                                        req.setComments('Please Review & Approve this Refund');
                                        req.setObjectId(invobj.Id);
                                        // Submit the approval request for the Invoice
                                        Approval.ProcessResult result = Approval.process(req);
                                        
                                        Transaction__c updateTrans = new Transaction__c();
                                        updateTrans.id = soTransaction.id;
                                        updateTrans.Refunded_Amount__c = soTransaction.Refunded_Amount__c + grandTotal;
                                        System.debug('invObj: '+invObj);
                                        update updateTrans;
                                        set<id> invoiceItems = new set<id>();
                                        
                                        for(Invoice_Line_Item__c invItems : itemInvoiceList) {
                                            invoiceItems.add(invItems.id);
                                        }
                                        UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);
                                        
                                        makeCopyForCancellation(getqtyinv);
                                        pr = new  PageReference('/'+invObj.id);
                                        pr.setRedirect(true);
                                        refundLocker.unLock();
                                        return pr;
                                    }
                                    else if(itemInvoiceList.size() == 0)
                                    {
                                        System.debug('Before Delete: '+invObj);
                                        delete invObj;
                                    }
                                    System.debug('itemInvoiceList: '+itemInvoiceList);
                                }
                            }
                            
                        }
                        else {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Select atleast one line item quantity to generate Refund'));
                        }
                    }
                }
                else if(selectRefund == 'Compensation') {
                    System.debug('-- Select Refund is Compensation and Payment Type is Not Null --');
                    if(selectReason == 'none') {
                        isreqHandleField = true;
                        if(selectCompReason == 'none') {
                            isreqCompField = true;
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else if (selectForm == 'none') {
                        isreqFormField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else if(selectCompReason == 'none') {
                        isreqCompField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else if (selectCompReason == 'Other - Detail in Comments Below' && (compensationComments == null || compensationComments.trim() == '')) {
                        isreqCommField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    else {
                        if(selectedSOItemList.size() != 0) {
                            if(customDiscount > 0) {
                                System.debug('Inserting a Refund Order');
                                System.debug('Compensation Total Amount: '+customDiscount);
                                if( (SO_Obj.Invoices_Changed_to_Manual_Payment__c == 0  && soTransaction.Balance_Amount__c < customDiscount) || (SO_Obj.Invoices_Changed_to_Manual_Payment__c > 0 && customDiscount > (SO_Obj.Total_Paid__c- SO_Obj.Total_Refund__c))) {
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'The refund Amount is greater than available Amount'));
                                }
                                else {
                                    RecordType payableType = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Invoice_Line_Item__c' AND Name = 'Payable Line Items'];
                                    
                                    invObj = new Invoice__c();
                                    
                                    invobj.RecordTypeId = [select id from RecordType where name='payables' and sobjecttype='invoice__c'].id;
                                    invObj.Customer_Name__c = SO_Obj.Customer_Name__c;
                                    invObj.Email__c = SO_Obj.Customer_Email__c;
                                    invobj.Items_invoiced__c = getqtyinv.size();
                                    invobj.Payment_Method__c = soTransaction.Payment_Method__c;
                                    if (SO_Obj.Payment_Method__c != 'Credit Card (Authorize.net)' && SO_Obj.Payment_Method__c != 'Credit Card' && SO_Obj.Payment_Method__c != 'PayPal' && SO_Obj.Payment_Method__c != 'PayPal Express Checkout') {
                                        invobj.Manual_Refund__c = true;
                                    }
                                    invobj.Order_Transaction_Type__c = soTransaction.id;
                                    invobj.Reason_for_Refund__c = selectRefund;
                                    invobj.compensation_Reason__c = selectCompReason;
                                    invobj.Refund_Handle_By__c = selectReason;
                                    invobj.Form_Of_Compensation__c = selectForm;
                                    invobj.Comments__c = compensationComments;
                                    invObj.Sales_Order__c = SO_Obj.id;
                                    invobj.Credit_Memo_Refund_Amount__c = customDiscount;
                                    //invObj.Refund_Approval_Status__c ='Refund Approved';
                                    insert invObj;
                                    
                                    system.debug('invObj: '+invObj);
                                    
                                    itemInvoiceList = new list<Invoice_Line_Item__c>();
                                    for(SO_Line_Items__c SOItemList : selectedSOItemList) {
                                        Invoice_Line_Item__c itemInvoice = new Invoice_Line_Item__c();
                                        
                                        itemInvoice.RecordTypeId = payableType.Id;
                                        itemInvoice.Invoice__c = invObj.id;
                                        itemInvoice.Sales_Order__c = SOItemList.Sales_Order__c;
                                        itemInvoice.Items_invoiced__c = SOItemList.id;
                                        String strQ2I = getqtyinv.get(SOItemList.id);
                                        itemInvoice.Quantity_To_Refund__c = Integer.valueof(strQ2I.trim());
                                        itemInvoice.Tax_Amount_Hidden__c = Decimal.valueof(gettaxAmtinv.get(SOItemList.id));
                                        itemInvoice.Sub_Total__c = Decimal.valueof(getsubTotalinv.get(SOItemList.id));
                                        itemInvoice.Discount_Amount_Hidden__c = Decimal.valueof(getdisAmtinv.get(SOItemList.id));
                                        System.debug('Refund Quantity: '+itemInvoice.Quantity_To_Refund__c);
                                        if(selectRefund == 'Compensation' ) {
                                            itemInvoice.Custom_Refund__c = Decimal.valueof(getcustomDisc.get(SOItemList.id));
                                        }
                                        itemInvoiceList.add(itemInvoice);
                                    }
                                    if(!itemInvoiceList.isEmpty() || itemInvoiceList.size() != 0) {
                                        insert itemInvoiceList;
                                        System.debug('isChecked: '+isChecked);
                                        if(isChecked == true) {
                                            invobj.Notify_Customer_by_Email__c = isChecked;
                                            invobj.Number_of_Invoices_Sent__c = 1;
                                            Update invobj;
                                        }
                                        Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
                                        req1.setComments('Please Review & Approve this Refund');
                                        req1.setObjectId(invobj.Id);
                                        // Submit the approval request for the Invoice
                                        Approval.ProcessResult result = Approval.process(req1);
                                        Transaction__c updateTrans = new Transaction__c();
                                        updateTrans.id = soTransaction.id;
                                        updateTrans.Refunded_Amount__c = soTransaction.Refunded_Amount__c + customDiscount;
                                        
                                        update updateTrans;
                                        set<id> invoiceItems = new set<id>();
                                        
                                        for(Invoice_Line_Item__c invItems : itemInvoiceList) {
                                            invoiceItems.add(invItems.id);
                                        }
                                        UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);
                                        //makeCopyForCancellation(getqtyinv);
                                        
                                        pr = new  PageReference('/'+invObj.id);
                                        pr.setRedirect(true);
                                        refundLocker.unLock();
                                        return pr;
                                    }
                                    else if(itemInvoiceList.size() == 0) {
                                        System.debug('Before Delete: '+invObj);
                                        delete invObj;
                                    }
                                    System.debug('itemInvoiceList: '+itemInvoiceList);
                                }
                            }
                            else {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please enter Compensation amount for given quantity to generate Refund'));
                            }
                        }
                        else {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Select atleast one line item quantity to generate Refund'));
                        }
                    }
                }
                else if(selectRefund == 'Edited order') {
                    if (compensationComments == null || compensationComments.trim() == '') {
                        isreqCommField = true;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Enter a value in Required Fields.'));
                    }
                    System.debug('-- Select Refund is Edited order and Payment Type is Not Null --');
                    if(selectedSOItemList.size() != 0) {
                        System.debug('Inserting a Refund Order');
                        System.debug('Compensation Total Amount: '+customDiscount);
                        RecordType payableType = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Invoice_Line_Item__c' AND Name = 'Payable Line Items'];
                        
                        invObj = new Invoice__c();
                        
                        invobj.RecordTypeId = [select id from RecordType where name='payables' and sobjecttype='invoice__c'].id;
                        invObj.Customer_Name__c = SO_Obj.Customer_Name__c;
                        invObj.Email__c = SO_Obj.Customer_Email__c;
                        invobj.Items_invoiced__c = getqtyinv.size();
                        invobj.Payment_Method__c = soTransaction.Payment_Method__c;
                        if (SO_Obj.Payment_Method__c != 'Credit Card (Authorize.net)' && SO_Obj.Payment_Method__c != 'Credit Card' && SO_Obj.Payment_Method__c != 'PayPal' && SO_Obj.Payment_Method__c != 'PayPal Express Checkout') {
                            invobj.Manual_Refund__c = true;
                        }
                        invobj.Order_Transaction_Type__c = soTransaction.id;
                        invobj.Reason_for_Refund__c = selectRefund;
                        invobj.Refund_Handle_By__c = selectReason;
                        invobj.Form_Of_Compensation__c = selectForm;
                        invobj.Comments__c = compensationComments;
                        invObj.Sales_Order__c = SO_Obj.id;
                        Decimal total = SO_Obj.Total_Due__c;
                        /*if(applayReward && total >= SO_Obj.DiscountAmount__c ){
total -= SO_Obj.DiscountAmount__c;
}*/
                        invobj.Credit_Memo_Refund_Amount__c = total;
                        //invObj.Refund_Approval_Status__c ='Refund Approved';
                        insert invObj;
                        
                        system.debug('invObj: '+invObj);
                        
                        itemInvoiceList = new list<Invoice_Line_Item__c>();
                        for(SO_Line_Items__c SOItemList : selectedSOItemList) {
                            Invoice_Line_Item__c itemInvoice = new Invoice_Line_Item__c();
                            
                            itemInvoice.RecordTypeId = payableType.Id;
                            itemInvoice.Invoice__c = invObj.id;
                            itemInvoice.Sales_Order__c = SOItemList.Sales_Order__c;
                            itemInvoice.Items_invoiced__c = SOItemList.id;
                            String strQ2I = getqtyinv.get(SOItemList.id);
                            itemInvoice.Quantity_To_Refund__c = Integer.valueof(strQ2I.trim());
                            itemInvoice.Tax_Amount_Hidden__c = Decimal.valueof(gettaxAmtinv.get(SOItemList.id));
                            itemInvoice.Sub_Total__c = Decimal.valueof(getsubTotalinv.get(SOItemList.id));
                            itemInvoice.Discount_Amount_Hidden__c = Decimal.valueof(getdisAmtinv.get(SOItemList.id)) + (applayReward ?  SO_Obj.DiscountAmount__c / selectedSOItemList.size() : 0);
                            System.debug('Refund Quantity: '+itemInvoice.Quantity_To_Refund__c);
                            //itemInvoice.Custom_Refund__c = itemInvoice.Sub_Total__c + itemInvoice.Tax_Amount_Hidden__c - itemInvoice.Discount_Amount_Hidden__c;
                            itemInvoiceList.add(itemInvoice);
                        }
                        
                        Decimal tatolItemRewardPoint=0.00;
                        
                        for(Invoice_Line_Item__c invoice_i : itemInvoiceList) {
                            tatolItemRewardPoint += invoice_i.Discount_Amount_Hidden__c.setscale(2);
                        }
                        System.debug('totalItemRewardPoint: ' + tatolItemRewardPoint);
                        itemInvoiceList.get(itemInvoiceList.size()-1).Discount_Amount_Hidden__c += (applayReward ? SO_Obj.DiscountAmount__c - tatolItemRewardPoint : 0);
                        
                        if(!itemInvoiceList.isEmpty() || itemInvoiceList.size() != 0) {
                            insert itemInvoiceList;
                            System.debug('isChecked: '+isChecked);
                            if(isChecked == true) {
                                invobj.Notify_Customer_by_Email__c = isChecked;
                                invobj.Number_of_Invoices_Sent__c = 1;
                                Update invobj;
                            }
                            Approval.ProcessSubmitRequest req1 =new Approval.ProcessSubmitRequest();
                            req1.setComments('Please Review & Approve this Refund');
                            req1.setObjectId(invobj.Id);
                            // Submit the approval request for the Invoice
                            Approval.ProcessResult result = Approval.process(req1);
                            Transaction__c updateTrans = new Transaction__c();
                            updateTrans.id = soTransaction.id;
                            updateTrans.Refunded_Amount__c = soTransaction.Refunded_Amount__c + customDiscount;
                            
                            update updateTrans;
                            set<id> invoiceItems = new set<id>();
                            
                            for(Invoice_Line_Item__c invItems : itemInvoiceList) {
                                invoiceItems.add(invItems.id);
                            }
                            UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);
                            
                            //makeCopyForCancellation(getqtyinv);
                            
                            pr = new  PageReference('/'+invObj.id);
                            pr.setRedirect(true);
                            refundLocker.unLock();
                            return pr;
                        }
                        else if(itemInvoiceList.size() == 0) {
                            System.debug('Before Delete: '+invObj);
                            delete invObj;
                        }
                        System.debug('itemInvoiceList: '+itemInvoiceList);
                        
                    }
                    else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Please Select atleast one line item quantity to generate Refund'));
                    }
                }
            }
            
        }
        Catch(Exception e)
        {
            refundLocker.unLock();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));
            System.debug('Exception E :: '+e.getMessage()+', Cause :: '+e.getCause()+', Line No. :: '+e.getLineNumber());
        }
        refundLocker.unLock();
        return pr;
    }
    
    @future (Callout=true)
    public static void refund(string salesOrderID,string InvoiceObject,string paymentMethodID,decimal grandTotal,decimal taxAmount, datetime transDate)
    {
        Set<String> paymentTypeSet = new Set<String>{'Manual Payment', 'Cardknox'};
        AuthorizeDotNetResponse responseObject = new AuthorizeDotNetResponse();
        try
        {
            System.debug('salesOrderID : '+salesOrderID);
            System.debug('InvoiceObject : '+InvoiceObject);
            System.debug('paymentMethodID : '+paymentMethodID);
            System.debug('grandTotal : '+grandTotal);
            System.debug('taxAmount : '+taxAmount);
            
            Sales_Order__c salesOrderObject = [select Customer_Name__c, id,name,Payment_Method__c, Authdotnetoldaccount__c, Grand_Total__c, Customer_Name__r.Web_Site__c, Payment_Status__c, Magento_order_No__c, Order_Status__c from Sales_Order__c where id=:salesOrderID];
            Payment_Method__c paymentMethodVar = [select id,name, Amount__c, Customer_Profile_ID__c,Payment_Profile_ID__c from Payment_Method__c where id=:paymentMethodID];
            list<Transaction__c>transactionObjects = [  SELECT id,name,TransactionId__c 
                                                        FROM Transaction__c 
                                                        WHERE 
                                                            Sales_Order__c=:salesOrderObject.id AND Payment_Method__c=:paymentMethodID AND 
                                                            (((Transaction_Type__c='CAPTURE_ONLY' OR Transaction_Type__c = 'AUTH_W_CAPTURE') 
                                                            AND Status__c='Captured') OR Sales_Order__r.Payment_Method__c IN :paymentTypeSet) limit 1];
            if (transactionObjects.size() > 0) {
                transactionObject = transactionObjects[0];
            }
            //----------------------------------------------------------------------------------------------------------------------------------------------
            List<SO_Line_Items__c> OrderLines = [select id,name, Bundle_Item_Relative_Discount_Amount__c, Product_Record_Type_Formula__c, Products__c,Products__r.RecordType.Name,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Price_For_Credit_Memo__c,DiscountAmount_For_Credit_Memo__c,Quantity_Refunded__c,Total_Weight_Pounds__c, Item__c,
                                                 ProductSKU__c,Product_Name__c,Products__r.Non_Furniture_Product__c, Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Percent__c,UnitPrice__c,Quantity_Invoiced__c, Bundle_Item__c,
                                                 ProductImageUrl__c,Custom_Price_For_Credit_Memo__c, Sales_Order__r.Total_Paid__c, Sales_Order__r.Total_Refund__c, Row_Total_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c, (SELECT id,Quantity_To_Refund__c FROM Invoice_Line_Item__r) from SO_Line_Items__c where Sales_Order__c =: salesOrderID];
            
            integer refundCount = 0;
            integer productsHaveBundled = 0;
            
            for(SO_Line_Items__c lineItem_i : OrderLines) {
                if(lineItem_i.Product_Record_Type_Formula__c == 'Bundled' && lineItem_i.Bundle_Item__c == null) {
                    productsHaveBundled++;
                }
                if(lineItem_i.Quantity_Invoiced__c == lineItem_i.Quantity_Refunded__c) {
                    refundCount++;
                }
                
            }
            
            
            //-------------------------------------------------------------------------------------------------------------------------------------------------------
            
            System.debug('salesOrderObject : '+salesOrderObject);
            System.debug('paymentMethodVar : '+paymentMethodVar);
            System.debug('transactionObject : '+transactionObject);
            
            Invoice__c updateInvoice = [Select id,Transaction_ID__c, Manual_Refund__c, Transaction_Response__c,Invoice_Status__c,authorization_Transaction__c, Notify_Customer_by_Email__c, Form_Of_Compensation__c, Reason_for_Refund__c from Invoice__c where id =:InvoiceObject];
            
            if(updateInvoice.Form_Of_Compensation__c != 'Gift Card' && !updateInvoice.Manual_Refund__c && (salesOrderObject.Payment_Method__c == 'Credit Card (Authorize.net)' || salesOrderObject.Payment_Method__c == 'Credit Card'))
            {
                string orderNumber = salesOrderObject.Magento_order_No__c != null && salesOrderObject.Magento_order_No__c != '' ? salesOrderObject.Magento_order_No__c : salesOrderObject.Id;
                AuthorizeDotNetFunctions authorizeDotNetFunctionsObject = new AuthorizeDotNetFunctions();
                responseObject = authorizeDotNetFunctionsObject.createCustomerRefundTransaction(paymentMethodVar.Customer_Profile_ID__c, paymentMethodVar.Payment_Profile_ID__c, transactionObject.TransactionId__c, string.valueOf(grandTotal), '0', transDate, orderNumber, salesOrderObject.Authdotnetoldaccount__c);
                //if (responseObject == null) return;
                System.debug('responseObject : '+responseObject);
                
                transactionObject = new Transaction__c();
                transactionObject.Invoice__c = InvoiceObject;
                transactionObject.Transaction_Type__c = 'CREDIT';
                transactionObject.Sales_Order__c = salesOrderID;
                if(paymentMethodID != null)
                    transactionObject.Payment_Method__c = paymentMethodID;
                if(responseObject != null) {
                    transactionObject.Transaction_Response__c = responseObject.responseReasonText;
                    transactionObject.Trans_AVS_Response__c = responseObject.avsResponse;
                }
                
                transactionObject.Amount__c = grandTotal;
                
                if(responseObject == null || authorizeDotNetFunctionsObject.transactionId == null || authorizeDotNetFunctionsObject.transactionId.trim() == '') {
                    transactionObject.Status__c = 'Failed';
                    if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                        salesOrderObject.Payment_Status__c = 'Refund Failed';
                    }
                    transactionObject.Refunded_Amount__c = 0;
                }
                else {
                    if (OrderLines.size() - productsHaveBundled != refundCount /*salesOrderObject.Grand_Total__c > grandTotal*/) {
                        if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                            salesOrderObject.Payment_Status__c = 'Partially Refunded';
                            salesOrderObject.Order_Status__c = 'Multiple Statuses';
                        }
                        transactionObject.Refunded_Amount__c = grandTotal;
                    }
                    else{
                        if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                            salesOrderObject.Payment_Status__c = 'Refunded';
                            salesOrderObject.Order_Status__c = 'Canceled';
                        }
                    }
                    transactionObject.Status__c = 'Refunded';
                    transactionObject.TransactionId__c = authorizeDotNetFunctionsObject.transactionId;
                }
                
                insert transactionObject;
                System.debug('Inserted transactionObject : '+transactionObject);
                
                updateInvoice.Transaction_ID__c = transactionObject.TransactionId__c;
                updateInvoice.Transaction_Response__c = transactionObject.Transaction_Response__c;
                updateInvoice.authorization_Transaction__c = transactionObject.id;
                if(responseObject == null || transactionObject.TransactionId__c == null || authorizeDotNetFunctionsObject.transactionId.trim() == '')
                {
                    updateInvoice.Invoice_Status__c='Refund-Failed';
                    updateInvoice.Notify_Customer_by_Email__c=false;
                    if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                        salesOrderObject.Payment_Status__c = 'Refund Failed';
                    }
                }
                else
                {
                    updateInvoice.Invoice_Status__c='Refund-Success';
                    //updateInvoice.Notify_Customer_by_Email__c=true;
                    Task taskVar=new Task();
                    taskVar.WhatId=salesOrderObject.id;
                    taskVar.Subject='Approved Amount ('+grandTotal+') refunded Successfully by CreditMemo: '+updateInvoice.name+' ';
                    taskVar.Status='Completed';
                    taskVar.ActivityDate=date.valueOf(updateInvoice.CreatedDate);
                    insert taskVar;
                    /*if (updateInvoice.Reason_for_Refund__c != 'Compensation'){
                        salesOrderObject.Payment_Status__c = 'Refunded';
                        salesOrderObject.Order_Status__c = 'Canceled';
                    }*/
                }
                update updateInvoice;
                update salesOrderObject;
            }
            else if(updateInvoice.Form_Of_Compensation__c != 'Gift Card' && !updateInvoice.Manual_Refund__c && (salesOrderObject.Payment_Method__c == 'PayPal' || salesOrderObject.Payment_Method__c == 'PayPal Express Checkout'))
            {
                PaypalConnect paypalObject = new PaypalConnect(salesOrderObject.Customer_Name__r.Web_Site__c);
                payPalResponse paypalResponseObject = paypalObject.refundPayment(transactionObject.TransactionId__c, string.valueOf(grandTotal), 'USD');
                system.debug('paypalResponseObject '+paypalResponseObject);
                string transactionid=paypalResponseObject.id;
                transactionObject=new Transaction__c();
                transactionObject.Invoice__c=InvoiceObject;
                transactionObject.Transaction_Type__c='CREDIT';
                transactionObject.TransactionId__c=transactionid;
                transactionObject.Sales_Order__c=salesOrderID;
                if(paymentMethodID != null)
                    transactionObject.Payment_Method__c = paymentMethodID;
                transactionObject.Transaction_Response__c = paypalResponseObject.state;
                transactionObject.Amount__c = grandTotal;
                if(transactionid == null) {
                    transactionObject.Status__c = 'Failed';
                    if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                        salesOrderObject.Payment_Status__c = 'Refund Failed';
                    }
                }
                else {
                    
                    if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                        if (OrderLines.size() - productsHaveBundled != refundCount /*salesOrderObject.Grand_Total__c > grandTotal*/) {
                            salesOrderObject.Payment_Status__c = 'Partially Refunded';
                            salesOrderObject.Order_Status__c = 'Multiple Statuses';
                        }
                        else{
                            salesOrderObject.Payment_Status__c = 'Refunded';
                            salesOrderObject.Order_Status__c = 'Canceled';
                        }
                    }
                    transactionObject.Status__c = 'Refunded';
                    transactionObject.Refunded_Amount__c = grandTotal;
                }
                
                insert transactionObject;
                update salesOrderObject;
                System.debug('Inserted transactionObject : '+transactionObject);
                
                updateInvoice.Transaction_ID__c = transactionObject.TransactionId__c;
                updateInvoice.Transaction_Response__c = transactionObject.Transaction_Response__c;
                updateInvoice.authorization_Transaction__c = transactionObject.id;
                
                if(paypalResponseObject == null)
                {
                    updateInvoice.Invoice_Status__c='Refund-Failed';
                    updateInvoice.Notify_Customer_by_Email__c=false;
                    if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                        salesOrderObject.Payment_Status__c = 'Refund Failed';
                        update salesOrderObject;
                    }
                }
                else
                {
                    updateInvoice.Invoice_Status__c='Refund-Success';
                    //updateInvoice.Notify_Customer_by_Email__c=true;
                    
                    Task taskVar=new Task();
                    taskVar.WhatId=salesOrderObject.id;
                    taskVar.Subject='Approved Amount ('+grandTotal+') refunded Successfully by CreditMemo: '+updateInvoice.name+' ';
                    taskVar.Status='Completed';
                    taskVar.ActivityDate=date.valueOf(updateInvoice.CreatedDate);
                    insert taskVar;
                }
                update updateInvoice;
            }
            else if(updateInvoice.Form_Of_Compensation__c == 'Gift Card' ||  paymentTypeSet.contains(salesOrderObject.Payment_Method__c) || updateInvoice.Manual_Refund__c)
            {
                transactionObject=new Transaction__c();
                transactionObject.Invoice__c=InvoiceObject;
                transactionObject.Transaction_Type__c='CREDIT';
                transactionObject.Sales_Order__c=salesOrderID;
                if(paymentMethodID != null && updateInvoice.Form_Of_Compensation__c != 'Gift Card' && paymentTypeSet.contains(salesOrderObject.Payment_Method__c)) {
                    transactionObject.Payment_Method__c = paymentMethodID;
                }
                else {
                    list<Payment_Method__c> paymentMethodsVar = [select id,name,Account__c, Amount__c, recordtypeid from Payment_Method__c where Account__c = :salesOrderObject.Customer_Name__c and recordtypeid = :Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Manual Payment').getRecordTypeId()];
                    if (paymentMethodsVar.size() > 0) {
                        transactionObject.Payment_Method__c = paymentMethodsVar[0].id;
                    }
                    else{
                        Payment_Method__c pm = new Payment_Method__c();
                        pm.Account__c = salesOrderObject.Customer_Name__c;
                        pm.Amount__c = paymentMethodVar.Amount__c;
                        pm.recordtypeid = Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Manual Payment').getRecordTypeId();
                        insert pm;
                        transactionObject.Payment_Method__c = pm.id;
                    }
                }
                transactionObject.Amount__c = grandTotal;
                if (updateInvoice.Reason_for_Refund__c != 'Compensation') {
                    if (OrderLines.size() - productsHaveBundled != refundCount /*salesOrderObject.Grand_Total__c > grandTotal*/) {
                        salesOrderObject.Payment_Status__c = 'Partially Refunded';
                        salesOrderObject.Order_Status__c = 'Multiple Statuses';
                    }
                    else{
                        salesOrderObject.Payment_Status__c = 'Refunded';
                        salesOrderObject.Order_Status__c = 'Canceled';
                    }
                }
                transactionObject.Status__c = 'Refunded';
                transactionObject.Refunded_Amount__c = grandTotal;
                
                insert transactionObject;
                update salesOrderObject;
                System.debug('Inserted transactionObject : '+transactionObject);
                
                updateInvoice.Invoice_Status__c='Refund-Success';
                //updateInvoice.Notify_Customer_by_Email__c=true;
                update updateInvoice;
            }
            ProcessorControl.inFutureContext = true;
        }
        Catch(Exception e)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+responseObject.responseReasonText+' '+e.getLineNumber()));
            System.debug('Exception ex :: '+e.getMessage()+', Cause :: '+e.getCause()+', Line Number :: '+e.getLineNumber());
        }
    }
    
    public void makeCopyForCancellation(Map<Id,String> SOItemsToRefundMap){
        Map<String, SO_Line_Items__c> canceledProdMap = new Map<String, SO_Line_Items__c>();
        
        Map<String, String> ProdNameToProdId  = new Map<String, String>();
        Map<id, String> ItemIdToProductNameMap = new Map<id, String>();
        
        List<SO_Line_Items__c> SoItemsList = new List<SO_Line_Items__c>(soRelatedMap.values());
        SoItemsList.addAll(BundelSOitems.values());
        for(SO_Line_Items__c currentSOItem_i : SoItemsList) {
            if(currentSOItem_i.Item__c == 'Cancelled') {
                canceledProdMap.put(currentSOItem_i.ProductSKU__c, currentSOItem_i);
            }
        }
        
        for(SO_Line_Items__c LineItem : BundelSOitems.values()) {
            if(LineItem.Item__c != 'Cancelled') {
                ItemIdToProductNameMap.put(LineItem.id, LineItem.Product_Name__c);
                
            }
            
        }
        for(Products__c product_i : [SELECT id, Name FROM Products__c WHERE Name in :ItemIdToProductNameMap.values() ]) {
            ProdNameToProdId.put(product_i.Name, product_i.id);
        }
        
        
        
        set<id> soLinesIds = new set<id>();
        for(SO_Line_Items__c currentSOItem_i : selectedSOItemList) {
            soLinesIds.add(currentSOItem_i.id);
        }
        map<id,SO_Line_Items__c> soLineMap = new map<Id,SO_Line_Items__c>([select id,name, Bundle_Item__r.Product__c, Bundle_Item__c, Products__c, Quantity_Invoiced__c, Bundle_Item_Relative_Discount_Amount__c
                                                                           from SO_Line_Items__c where id in: soLinesIds]);
        map<id,SO_Line_Items__c> soLineMapAll = new map<Id,SO_Line_Items__c>([select id,name, Bundle_Item__r.Product__c, Bundle_Item__c, Products__c, Quantity_Invoiced__c, Bundle_Item_Relative_Discount_Amount__c,
                                                                              Price__c, Tax_Amount__c, DiscountAmount__c, Price_For_Credit_Memo__c, DiscountAmount_For_Credit_Memo__c, Tax_Amount_For_Credit_Memo__c
                                                                              from SO_Line_Items__c where Sales_Order__c = : SO_Obj.id]);
        map<string, integer> numberOfBundleItems = new map<string, integer>();
        map<string, integer> numberOfCancelledBundleItems = new map<string, integer>();
        map<string, SO_Line_Items__c> bundleLineItemByProduct = new map<string, SO_Line_Items__c>();
        for (SO_Line_Items__c li : soLineMapAll.values()) {
            if (li.Bundle_Item__c != null) {
                if (!numberOfBundleItems.containskey(li.Products__c)) {
                    numberOfBundleItems.put(li.Products__c, integer.valueof(li.Quantity_Invoiced__c));
                }
                else{
                    numberOfBundleItems.put(li.Products__c, numberOfBundleItems.get(li.Products__c) + integer.valueof(li.Quantity_Invoiced__c));
                }
            }
            else{
                bundleLineItemByProduct.put(li.Products__c, li);
            }
        }
        for(SO_Line_Items__c currentSOItem_i : selectedSOItemList) {
            if (currentSOItem_i.Bundle_Item__c != null) {
                if (!numberOfCancelledBundleItems.containskey(currentSOItem_i.Products__c)) {
                    numberOfCancelledBundleItems.put(currentSOItem_i.Products__c, Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()));
                }
                else{
                    numberOfCancelledBundleItems.put(currentSOItem_i.Products__c, numberOfCancelledBundleItems.get(currentSOItem_i.Products__c) + Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()));
                }
            }
        }
        set<id> bItemIds = new set<id>();
        for(SO_Line_Items__c currentSOItem_i : soLineMap.values()) {
            if (currentSOItem_i.Bundle_Item__c != null) {
                bItemIds.add(currentSOItem_i.Bundle_Item__c);
            }
        }
        
        map<id,Bundle_Item__c> biMap = new map<id,Bundle_Item__c>([SELECT Product__c FROM Bundle_Item__c WHERE id in: bItemIds]);
        System.debug('soLineMap: '+soLineMap);
        System.debug('selectedSOItemList: '+selectedSOItemList);
        set<id> updatedbundled = new set<id>();
        map<string, SO_Line_Items__c> bundleToUpdatePrice = new map<string, SO_Line_Items__c>();
        for(SO_Line_Items__c currentSOItem_i : selectedSOItemList) {
            System.debug('currentSOItem_i.Quantity_Refunded__c: '+currentSOItem_i.Quantity_Refunded__c);
            System.debug('SOItemsToRefundMap.get(currentSOItem_i.id).trim(): '+SOItemsToRefundMap.get(currentSOItem_i.id).trim());
            System.debug('currentSOItem_i.Quantity_Invoiced__c: '+currentSOItem_i.Quantity_Invoiced__c);
            if(currentSOItem_i.Quantity_Refunded__c + Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()) < currentSOItem_i.Quantity_Invoiced__c) {
                SO_Line_Items__c newSOitem;
                
                if(canceledProdMap.containsKey(currentSOItem_i.ProductSKU__c) ) {
                    newSOitem = canceledProdMap.get(currentSOItem_i.ProductSKU__c);
                }else{
                    newSOitem = currentSOItem_i.clone(false, true, false, false);
                }
                System.debug('newSOitem: '+newSOitem);
                
                newSOitem.Item__c = 'Cancelled';
                Decimal rowTotaCreditMemoDivision = currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim());
                if(currentSOItem_i.Row_Total__c!= null){
                    newSOitem.Row_Total_For_Credit_Memo__c = currentSOItem_i.Row_Total__c  / (rowTotaCreditMemoDivision != 0 ? rowTotaCreditMemoDivision : 1);
                }else{
                    newSOitem.Row_Total_For_Credit_Memo__c = 0;
                }
                Decimal priceCreditMemoDivision = currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim());
                newSOitem.Price_For_Credit_Memo__c = currentSOItem_i.Sub_Total__c / (priceCreditMemoDivision != 0 ? priceCreditMemoDivision : 1);
                if (currentSOItem_i.Custom_Price__c != null) {
                    Decimal customPriceCreditMemoDivision = currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim());
                    newSOitem.Custom_Price_For_Credit_Memo__c = currentSOItem_i.Custom_Price__c / (customPriceCreditMemoDivision != 0 ? customPriceCreditMemoDivision : 1);
                }
                Decimal discountAmountCreditMemoDivision = currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim());
                newSOitem.DiscountAmount_For_Credit_Memo__c = currentSOItem_i.Bundle_Item_Relative_Discount_Amount__c / (discountAmountCreditMemoDivision != 0 ? discountAmountCreditMemoDivision : 1);
                Decimal TaxAmountCreditMemoDivision = currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim());
                newSOitem.Tax_Amount_For_Credit_Memo__c = (currentSOItem_i.TaxAmount__c != null ? currentSOItem_i.TaxAmount__c : 0) / (TaxAmountCreditMemoDivision != 0 ? TaxAmountCreditMemoDivision : 1);
                
                newSOitem.Invoiced_Sub_Total__c = 0;
                newSOitem.Invoiced_Discount__c = 0;
                newSOitem.Invoiced_Tax__c = 0;
                
                newSOitem.Bundle_Item__c = currentSOItem_i.Bundle_Item__c;
                
                newSOitem.Quantity__c = currentSOItem_i.Quantity_Refunded__c + Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim());
                newSOitem.Quantity_Invoiced__c = newSOitem.Quantity__c;
                newSOitem.Quantity_Refunded__c = newSOitem.Quantity_Invoiced__c;
                
                newSOitem.Uncancelled_Items_Ordered__c = currentSOItem_i.Id;
                system.debug('ItemIdToProductNameMap.containsKey(currentSOItem_i.id) = ' + ItemIdToProductNameMap.containsKey(currentSOItem_i.id));
                if(ItemIdToProductNameMap.containsKey(currentSOItem_i.id)) {
                    if (soLineMap.containskey(currentSOItem_i.id) && soLineMap.get(currentSOItem_i.id).Bundle_Item__c != null && biMap.containskey(soLineMap.get(currentSOItem_i.id).Bundle_Item__c)) {
                        newSOitem.Products__c = biMap.get(soLineMap.get(currentSOItem_i.id).Bundle_Item__c).Product__c;
                        newSOitem.Bundle_Item__c = null;
                        system.debug('currentSOItem_i.Price__c = ' + currentSOItem_i.Price__c);
                        //system.debug('bundleItem = ' + bundleItem);
                        system.debug('currentSOItem_i = ' + currentSOItem_i);
                        system.debug('bundleLineItemByProduct.get(currentSOItem_i.Products__c) = ' + bundleLineItemByProduct.get(currentSOItem_i.Products__c));
                        bundleLineItemByProduct.get(currentSOItem_i.Products__c).Price__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Price_For_Credit_Memo__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Price__c - (currentSOItem_i.Price_For_Credit_Memo__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()) );
                        bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount_For_Credit_Memo__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c - (currentSOItem_i.Tax_Amount_For_Credit_Memo__c / currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()));
                        if (bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c < 0.2) {
                            bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount_For_Credit_Memo__c = 0;
                        }
                        bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount_For_Credit_Memo__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c - (currentSOItem_i.Bundle_Item_Relative_Discount_Amount__c / currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()));
                        if (bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c < 0.2) {
                            bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount_For_Credit_Memo__c = 0;
                        }
                        
                        bundleToUpdatePrice.put(bundleLineItemByProduct.get(currentSOItem_i.Products__c).id, bundleLineItemByProduct.get(currentSOItem_i.Products__c));
                        system.debug('bundleToUpdatePrice = ' + bundleToUpdatePrice);
                    }
                    else {
                        newSOitem.Products__c = ProdNameToProdId.get(currentSOItem_i.Product_Name__c);
                    }
                }
                
                
                cancelledSOItemList.add(newSOitem);
                
            }
            else {
                
                if ((soLineMap.containskey(currentSOItem_i.id) && soLineMap.get(currentSOItem_i.id).Bundle_Item__c != null && numberOfBundleItems.containskey(soLineMap.get(currentSOItem_i.id).Products__c) && numberOfCancelledBundleItems.containskey(soLineMap.get(currentSOItem_i.id).Products__c) && numberOfBundleItems.get(soLineMap.get(currentSOItem_i.id).Products__c) == numberOfCancelledBundleItems.get(soLineMap.get(currentSOItem_i.id).Products__c))) {
                    //system.debug('updatedbundled = ' + updatedbundled);
                    //system.debug('bundleLineItemByProduct.get(currentSOItem_i.Products__c) = ' + bundleLineItemByProduct.get(currentSOItem_i.Products__c));
                    //system.debug('updatedbundled.contains(bundleLineItemByProduct.get(currentSOItem_i.Products__c).id) = ' + updatedbundled.contains(bundleLineItemByProduct.get(currentSOItem_i.Products__c).id));
                    if (!updatedbundled.contains(bundleLineItemByProduct.get(currentSOItem_i.Products__c).id)) {
                        updatedbundled.add(bundleLineItemByProduct.get(currentSOItem_i.Products__c).id);
                        SO_Line_Items__c newSOitem = new SO_Line_Items__c(id = bundleLineItemByProduct.get(currentSOItem_i.Products__c).id);
                        newSOitem.Item__c = 'Cancelled';
                        newSOitem.Uncancelled_Items_Ordered__c = currentSOItem_i.Id;
                        cancelledSOItemList.add(newSOitem);
                        system.debug('cancelledSOItemList = ' + cancelledSOItemList);
                    }
                }else if (soLineMap.containskey(currentSOItem_i.id) && soLineMap.get(currentSOItem_i.id).Bundle_Item__c != null && biMap.containskey(soLineMap.get(currentSOItem_i.id).Bundle_Item__c)) {
                    SO_Line_Items__c newSOitem = new SO_Line_Items__c(id = currentSOItem_i.id);
                    // update bundle item price
                    SO_Line_Items__c bundleItem = new SO_Line_Items__c();

                    system.debug('currentSOItem_i.Price__c = ' + currentSOItem_i.Price__c);
                    //system.debug('bundleItem = ' + bundleItem);
                    system.debug('currentSOItem_i = ' + currentSOItem_i);
                    system.debug('bundleLineItemByProduct.get(currentSOItem_i.Products__c) = ' + bundleLineItemByProduct.get(currentSOItem_i.Products__c));
                    bundleLineItemByProduct.get(currentSOItem_i.Products__c).Price__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Price_For_Credit_Memo__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Price__c - (currentSOItem_i.Price_For_Credit_Memo__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()) );
                    bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount_For_Credit_Memo__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c - (currentSOItem_i.Tax_Amount_For_Credit_Memo__c / currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()));
                    if (bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c < 0.2) {
                        bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).Tax_Amount_For_Credit_Memo__c = 0;
                    }
                    bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount_For_Credit_Memo__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c - (currentSOItem_i.Bundle_Item_Relative_Discount_Amount__c / currentSOItem_i.Quantity__c * Integer.valueOf(SOItemsToRefundMap.get(currentSOItem_i.id).trim()));
                    if (bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c < 0.2) {
                        bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount__c = bundleLineItemByProduct.get(currentSOItem_i.Products__c).DiscountAmount_For_Credit_Memo__c = 0;
                    }
                    bundleToUpdatePrice.put(bundleLineItemByProduct.get(currentSOItem_i.Products__c).id, bundleLineItemByProduct.get(currentSOItem_i.Products__c));
                    system.debug('bundleToUpdatePrice = ' + bundleToUpdatePrice);
                    newSOitem.Products__c = biMap.get(soLineMap.get(currentSOItem_i.id).Bundle_Item__c).Product__c;
                    newSOitem.Bundle_Item__c = null;
                    cancelledSOItemList.add(newSOitem);
                }
            }
            
            
            
            
        }
        
        System.debug('cancelledSOItemList: '+cancelledSOItemList);
        
        if(!cancelledSOItemList.isEmpty()) {
            upsert new List<SO_Line_Items__c>(cancelledSOItemList);
        }
        if (bundleToUpdatePrice.values().size() > 0) {
            update bundleToUpdatePrice.values();
        }
    }
    
    
    // Wrapper Class
    
    public class ItemsorderWrapper
    {
        public SO_Line_Items__c SoItem {get; set;}
        public string qty {get; set;}
        public string customPrice {get; set;}
        public string subTotal {get; set;}
        public string taxAmount {get; set;}
        public string disAmount {get; set;}
        public string rowTotal {get; set;}
        public string weight {get; set;}
        public string customDisc {get; set;}
        public Boolean iscustomPriceAvailable {get; set;}
        public list<bundleItemsorderWrapper> bundleList {get; set;}
        
        public ItemsorderWrapper(SO_Line_Items__c So,list<bundleItemsorderWrapper> bundle,string qt,String cPrice,String subT,String taxA,String disA,String rowT,String weigh,String custDisc, Boolean isCheck)
        {
            SoItem = So;
            qty = qt;
            customPrice = cPrice;
            subTotal = subT;
            rowTotal = rowT;
            taxAmount = taxA;
            disAmount = disA;
            weight = weigh;
            customDisc = custDisc;
            iscustomPriceAvailable = isCheck;
            bundleList = bundle;
        }
    }
    
    public class bundleItemsorderWrapper
    {
        public SO_Line_Items__c bundleSoItem {get; set;}
        public string quantity {get; set;}
        public string bundleqty {get; set;}
        public string subTotal {get; set;}
        public string taxAmount {get; set;}
        public string disAmount {get; set;}
        public string rowTotal {get; set;}
        public string weight {get; set;}
        public string customDisc {get; set;}
        
        public bundleItemsorderWrapper(SO_Line_Items__c So, String bqty,String qty,String subT,String taxA,String disA,String rowT,String weigh)
        {
            bundleSoItem = So;
            quantity = bqty;
            bundleqty = qty;
            subTotal = subT;
            rowTotal = rowT;
            taxAmount = taxA;
            disAmount = disA;
            weight = weigh;
            customDisc = '0.0';
        }
        
        public bundleItemsorderWrapper(SO_Line_Items__c So, String bqty,String qty,String subT,String taxA,String disA,String rowT,String weigh, String custDisc)
        {
            bundleSoItem = So;
            quantity = bqty;
            bundleqty = qty;
            subTotal = subT;
            rowTotal = rowT;
            taxAmount = taxA;
            disAmount = disA;
            weight = weigh;
            customDisc = custDisc;
        }
    }

    class Locker {
        private Boolean locked = false;

        public void lock() { locked = true; }

        public void unLock() { locked = false; }
        
        public Boolean isLocked() { return locked; }

    }
}