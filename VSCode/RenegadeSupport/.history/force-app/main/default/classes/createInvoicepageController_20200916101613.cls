/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : createInvoicepageController
*   Purpose: This class is to generate a Invoice the products to the customer.
*/
global with sharing class createInvoicepageController
{  
    public Sales_Order__c SO_Obj {set;get;}
    public list<ItemsorderWrapper> SoRelatedList {set;get;}
    
    // This Variable is used to Calculate SubTotal, Discount Amount and Grand total of Sales Order Line Ite.
    public Decimal subTot {set;get;}
    public Decimal disAmount {set;get;}
    public Decimal taxAmount {set;get;}
    public Decimal grandTotal {set;get;}
    public Boolean isChecked {set;get;}
    
    // The Below Variables is used to calculate updated qyt.
    list<ItemsorderWrapper> selectedSOItem; 
    list<SO_Line_Items__c> selectedSOItemList;  
    map<SO_Line_Items__c,string> getqtyinv;
    map<SO_Line_Items__c,string> getsubTotalinv;
    map<SO_Line_Items__c,string> getdisAmtinv;
    map<SO_Line_Items__c,string> gettaxAmtinv;
    map<SO_Line_Items__c,string> getrowTinv;
    
    // This Variable is used to Insert a records into Invoice and Invoice Line Item Object.
    public Invoice__c invObj {get;set;}
    public list<Invoice_Line_Item__c> itemInvoiceList;
    private Transaction__c transactionObject;
    private list<Transaction__c> transactionObjectList;
    
    Public Boolean isreqField {get;set;}
    Public String styleVar {get;set;}
    
    public Decimal invoiceAmount {get; set;}
    private Id currentTransactionId;
    private Transaction__c currentTransaction; 

    private AppoverLockUnlockHandler approverHandler;


    public Boolean isChangeToManualPayment {get; set; }
    public Boolean hasPartialManualPayment {get; set; }
    public Payment_Method__c paymentMethodForManualChanging {get; set;}
    public List<SelectOption> pymentMethodRecordTypeList {
        get{
            return getOptionListFromSchema(Payment_Method__c.Manual_Payment_Type__c.getDescribe().getPicklistValues());
        } 
        set;
    }
    
    public String chosenManualPaymentType {
        get;
        set{
            chosenManualPaymentType = value;
            changeManualPaymnentTypeHandler(value);
        } 
    }
    public Boolean showChangeToManualPaymentPanel {get; set; }
    public Boolean showManualInvoiceAmount {get; set; }
    public Boolean showCardType {get; set; }
    public Boolean limitCardNumber {get; set; }

    Set<String> paymentMethodNotForChangingSet = new Set<String>{'Manual Payment'};
    public List<SelectOption> getSelectOptionsTypes(List<sObject> sObjectList, String valueFieldApiName, String labelFieldApiName) {
        List<SelectOption> options = new List<SelectOption>();
        for (sObject currentSobject : sObjectList) {
            options.add(new SelectOption((String)currentSobject.get(valueFieldApiName), (String)currentSobject.get(labelFieldApiName)));
        }
        return options;
    }

    public List<SelectOption> getSelectOptionsFromList(List<String> valueList) {
        List<SelectOption> options = new List<SelectOption>();
        for (String currentValue : valueList) {
            options.add(new SelectOption(currentValue, currentValue));
        }
        return options;
    }
    
    void changeManualPaymnentTypeHandler(String chosenType){
        Set<String> manualPaymentTypeToShowCardDataSet = new Set<String>{'Credit Card', 'Cardknox'};
        //show card type flag
        showCardType = manualPaymentTypeToShowCardDataSet.contains(chosenType);
        //limit card number to 4 last digits flag
        limitCardNumber = showCardType;
    }

    public List<SelectOption>  getOptionListFromSchema(List<Schema.PicklistEntry> fieldResult) {
        List<SelectOption> selectOptionList = new List<SelectOption> ();
        for( Schema.PicklistEntry curentPicklistValue : fieldResult){
            selectOptionList.add(new SelectOption(curentPicklistValue.getLabel(), curentPicklistValue.getValue()));
        }
        return selectOptionList;
    }

    public createInvoicepageController(ApexPages.StandardController controller)
    {
        pymentMethodRecordTypeList = new List<SelectOption> ();
        invoiceAmount = 0.0;
        paymentMethodForManualChanging = new Payment_Method__c();
        //getPymentMethodRecordTypeList = getSelectOptionsFromList(new List<String>{'Affirm', 'Credit Card', 'Cardknox', 'Affirm by Zibby'});
        
        // getSelectOptionsTypes(
        //     [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Payment_Method__c' AND Name != 'Manual Payment' ORDER BY name], 
        //     'Name', 
        //     'Name'
        // );
        showCardType = false;
        isChangeToManualPayment = false;
        hasPartialManualPayment = false;
        isChecked = false;
        isreqField = false;
        styleVar = Null;
        
        // reset to Zero for every refresh
        subTot = 0;
        taxAmount = 0;
        disAmount = 0;
        grandTotal = 0;
        SO_Obj = new Sales_Order__c();
        SO_Obj = (Sales_Order__c)controller.getrecord();
        try {
            //Get the related records of the sales order using sales object id
            SO_Obj = [SELECT name, Bill_To__c, Invoices_Changed_to_Manual_Payment__c, Magento_order_No__c, createddate, Authdotnetoldaccount__c, (SELECT id,UnitPrice__c,Price__c FROM SO_Line_Items__r),Payment_Status__c,Order_Status__c,Promotion__r.Name,Promotion__c, Shipping_Tax__c,
                      Total_Quantity_Ordered__c,Order_Date__c,Sales_Representative__r.name,Customer_Name__r.name,Customer_Name__r.Phone,Billing_City__c,Payment_Method__c, Customer_Name__r.Web_Site__c, TaxAmount__c,
                      Billing_State__c,Billing_Street__c, Customer_Name__c, Customer_Email__c,Ship_to__c, Shipping_City__c,Shipping_Handle__c,Mobile__c, Tax_Percentage__c, 
                      Shipping_State__c,Shipping_Street__c,Shipping_ZipCode__c,Billing_ZipCode__c,Grand_Total__c,No_Of_Products_Ordered__c, Total_Due__c, Total_Paid__c, 
                      Order_Type__c,Transaction_ID__c,Discount_AmountTotal__c, DiscountAmount__c, (SELECT id FROM Invoice__r) from Sales_Order__c where id=:SO_Obj.id];
            
            approverHandler = new AppoverLockUnlockHandler(SO_Obj.Customer_Name__c);

            isChangeToManualPayment = SO_Obj.Payment_Method__c == 'Manual Payment';
            soRelatedList = new list<ItemsorderWrapper>();
            Map<id,SO_Line_Items__c> soRelatedMap = new Map<id,SO_Line_Items__c>([select id,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c, OriginalPrice__c,Price__c,DiscountAmount__c, Discount_Amount__c, ProductSKU__c,Item__c,
                                                                                  Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Amount__c,Tax_Percent__c,UnitPrice__c,
                                                                                  Quantity_Invoiced__c, Invoiced_Sub_Total__c, Invoiced_Discount__c, Invoiced_Quantity__c, Invoiced_Tax__c, Invoiced_Total__c,
                                                                                  ProductImageUrl__c from SO_Line_Items__c where Item__c != 'Cancelled' and Sales_Order__c =: SO_Obj.id]);
            //Calculating Unit Price,Sub Total,Tax Amount,Discount Amount,Row Total...etc also quantity is assigned So related list
            for(SO_Line_Items__c soLine : [select id,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Price__c,Sub_Total__c,
                                           DiscountAmount__c, Discount_Amount__c,Product_Url__c,ProductSKU__c, Invoiced_Sub_Total__c, Invoiced_Discount__c, Invoiced_Quantity__c, Invoiced_Tax__c, Invoiced_Total__c, TaxAmount__c,Tax_Amount__c,
                                           Tax_Percent__c,Product_Name__c,Products__r.Product_Image_URL__c,UnitPrice__c,Quantity_Invoiced__c,(SELECT id,Quantity_Invoiced__c FROM Invoice_Line_Item__r), ProductImageUrl__c
                                           from SO_Line_Items__c where Item__c != 'Cancelled' and Sales_Order__c =: SO_Obj.id and Bundle_Item__c = null AND Products__r.RecordType.name != 'Protection Plan' ORDER BY ProductSKU__c ASC]) {
                                               if(soRelatedMap.containsKey(soLine.id) && soRelatedMap.get(soLine.id).Quantity__c != soRelatedMap.get(soLine.id).Quantity_Invoiced__c)
                                               {
                                                   String UP;
                                                   if(soLine.Price__c == Null) {
                                                       UP = '0';
                                                   }
                                                   else {
                                                       UP = String.valueOf(soLine.Price__c);
                                                   }
                                                   
                                                   //Creating temperory variables for calculations
                                                   Decimal subTotal;
                                                   Decimal subTotaltemp;
                                                   Decimal taxAmt;
                                                   Decimal taxAmttemp;
                                                   Decimal disAmt;
                                                   Decimal disAmttemp;
                                                   if (soLine.DiscountAmount__c == null)
                                                       soLine.DiscountAmount__c = 0;
                                                   if(soLine.Quantity_Invoiced__c != null || soLine.Quantity_Invoiced__c == 0) {
                                                       subTotal = Decimal.valueOf(UP) * (soLine.Quantity__c - soLine.Quantity_Invoiced__c);
                                                       //subTotal = subTotaltemp.setScale(2);
                                                       
                                                       taxAmt = (soLine.TaxAmount__c * (soLine.Quantity__c - soLine.Quantity_Invoiced__c)) / soLine.Quantity__c;
                                                       //taxAmt = taxAmttemp.setScale(2);
                                                       
                                                       disAmt = (soLine.DiscountAmount__c * (soLine.Quantity__c - soLine.Quantity_Invoiced__c)) / soLine.Quantity__c;
                                                       //disAmt = disAmttemp.setScale(2);
                                                   }
                                                   else {
                                                       subTotal = soLine.Quantity__c * Decimal.valueOf(UP);
                                                       //subTotal = subTotaltemp.setScale(2);
                                                       taxAmt = soLine.TaxAmount__c;
                                                       //taxAmt = taxAmttemp.setScale(2);
                                                       disAmt = soLine.DiscountAmount__c;
                                                       //disAmt = disAmttemp.setScale(2);
                                                   }
                                                   System.debug('subTotalList: '+subTotal);
                                                   System.debug('taxAmount: '+taxAmt);
                                                   System.debug('disAmt: '+disAmt);
                                                   
                                                   Decimal rowTotal = (subTotal + taxAmt) - disAmt;
                                                   System.debug('rowTotal: '+rowTotal);
                                                   subTot += subTotal;
                                                   System.debug('subTot: '+subTot);
                                                   taxAmount += taxAmt;
                                                   System.debug('taxAmount: '+taxAmount);
                                                   disAmount += disAmt;
                                                   System.debug('disAmount: '+disAmount);
                                                   
                                                   //Display Sales Order line information and  Calculations for invoice page
                                                   if(soLine.Quantity_Invoiced__c != null) {
                                                       soRelatedList.add(new ItemsorderWrapper(soLine,String.valueOf(soLine.Quantity__c - soLine.Quantity_Invoiced__c),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal)));                                                   }
                                                   else {
                                                       soRelatedList.add(new ItemsorderWrapper(soLine,String.valueOf(soLine.Quantity__c),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal)));
                                                   }
                                               }
                                           }
            for(SO_Line_Items__c soLine : [select id,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Price__c,Sub_Total__c,DiscountAmount__c,
                                           Product_Url__c,ProductSKU__c,Invoiced_Sub_Total__c, Invoiced_Discount__c, Invoiced_Quantity__c, Invoiced_Tax__c, Invoiced_Total__c,Discount_Amount__c, TaxAmount__c,Tax_Amount__c,Tax_Percent__c,Product_Name__c,
                                           Products__r.Product_Image_URL__c,UnitPrice__c,Quantity_Invoiced__c,Row_Total__c, ProductImageUrl__c from SO_Line_Items__c where Sales_Order__c =: SO_Obj.id AND Products__r.RecordType.name = 'Protection Plan']) {
                                               
                                               Decimal taxAmt;
                                               Decimal taxAmttemp;
                                               
                                               if(soRelatedMap.containsKey(soLine.id) && soRelatedMap.get(soLine.id).Quantity__c != soRelatedMap.get(soLine.id).Quantity_Invoiced__c) 
                                               {
                                                   taxAmt = soLine.TaxAmount__c;
                                                   //taxAmt = taxAmttemp.setScale(2);
                                                   
                                                   subTot += soLine.Sub_Total__c;
                                                   System.debug('subTot: '+subTot);
                                                   taxAmount += taxAmt;
                                                   System.debug('taxAmount: '+taxAmount);
                                                   if (soLine.DiscountAmount__c == null)
                                                       soLine.DiscountAmount__c = 0;
                                                   disAmount += soLine.DiscountAmount__c;
                                                   soRelatedList.add(new ItemsorderWrapper(soLine,String.valueOf(soLine.Quantity__c),String.valueOf(soLine.Sub_Total__c),String.valueOf(taxAmt),String.valueOf(soLine.DiscountAmount__c),String.valueOf(soLine.Row_Total__c)));
                                               }
                                           }
            if (taxAmount != null && SO_Obj.Shipping_Tax__c != null){                               
                taxAmount += SO_Obj.Shipping_Tax__c;
            }
            if(soRelatedList.isEmpty())
            {
                Apexpages.addMessage(new ApexPages.message(apexpages.Severity.WARNING,'No Invoice is to Generate.'));
            }
            if (SO_Obj.DiscountAmount__c == null){
            	SO_Obj.DiscountAmount__c = 0;
            }
            grandTotal = Math.abs((subTot + SO_Obj.Shipping_Handle__c) + SO_Obj.TaxAmount__c - (disAmount + SO_Obj.DiscountAmount__c));

            List<String> paymentTypeSet = new List<String>{ 'Cardknox', 'Manual Payment'}; //'Zibby by Affirm' 
            List<String> transactionTypeList = new List<String>{'AUTH_ONLY', 'authorization'};// 'Voided'
            List<Transaction__c> openTransactionList = [
                                    SELECT id, name, Amount__c, Days_opened__c, Payment_Type__c, CreatedDate, TransactionId__c,
                                    Payment_Method__c, Payment_Method__r.RecordTypeId, Payment_Method__r.Card_Type__c, Payment_Method__r.Account__c,
                                    Payment_Method__r.Last_4_digits_of_CC__c,
                                    Payment_Method__r.Credit_Card_Number__c, Payment_Method__r.Card_Verification_Number__c, Payment_Method__r.Expiration_Year__c,
                                    Payment_Method__r.Expiration_Month__c, Payment_Method__r.RecordType.Name, Payment_Method__r.Customer_Profile_ID__c,
                                    Payment_Method__r.Payment_Profile_ID__c
                                    FROM Transaction__c 
                                    WHERE Sales_Order__c=:SO_Obj.id AND (Transaction_Type__c IN :transactionTypeList )
                                    AND (Status__c='Authorized' OR  (Payment_Type__c IN: paymentTypeSet AND  Status__c != 'Captured') 
                                    OR (Status__c = 'Voided' AND Sales_Order__r.Invoices_Changed_to_Manual_Payment__c > 0)) ];//AND Payment_Type__c != 'Manual Payment'
            System.debug('new invoice logic openTransactionList: ' + openTransactionList);
            if(!openTransactionList.isEmpty()){
                List<RecordType> manualPaymentType = [SELECT Id FROM RecordType WHERE Name = 'Manual Payment'  AND sObjectType='Payment_Method__c'];
                currentTransaction = openTransactionList.get(0);
                currentTransactionId = currentTransaction.Id;
                if(!manualPaymentType.isEmpty()){
                    paymentMethodForManualChanging.RecordTypeId = manualPaymentType.get(0).Id;
                }

                //if(SO_Obj.Payment_Method__c != 'Manual Payment'){
                    paymentMethodForManualChanging.Card_Type__c = currentTransaction.Payment_Method__r.Card_Type__c;
                    paymentMethodForManualChanging.Last_4_digits_of_CC__c = currentTransaction.Payment_Method__r.Last_4_digits_of_CC__c;
                    paymentMethodForManualChanging.Credit_Card_Number__c = currentTransaction.Payment_Method__r.Credit_Card_Number__c;
                    paymentMethodForManualChanging.Expiration_Year__c = currentTransaction.Payment_Method__r.Expiration_Year__c;
                    paymentMethodForManualChanging.Expiration_Month__c = currentTransaction.Payment_Method__r.Expiration_Month__c;
               // }
                paymentMethodForManualChanging.Account__c = currentTransaction.Payment_Method__r.Account__c;
            }

            if(SO_Obj.Invoices_Changed_to_Manual_Payment__c > 0){
                hasPartialManualPayment = true;
                isChangeToManualPayment = true;
            }
            
            showChangeToManualPaymentPanel = !paymentMethodNotForChangingSet.contains(SO_Obj.Payment_Method__c) && !Apexpages.hasMessages();
            showManualInvoiceAmount = !showChangeToManualPaymentPanel;
            invoiceAmount = paymentMethodForManualChanging.Amount__c = SO_Obj.Total_Due__c;
        }
        catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,+'Please Contact to System Administrator.'));  
            System.debug('Exception ex :: '+e.getMessage()+', Cause :: '+e.getCause()+', Line Number :: '+e.getLineNumber());
        }
        System.debug('soRelatedList: '+soRelatedList);
    } 
    
    public void updateInvoiceAmount(){
        invoiceAmount = paymentMethodForManualChanging.Amount__c;
    }

    //Call this method when we submit the invoice for final calculations    
    public void updateitemInvoice() {
        // reset variables to Zero for calling this method
        subTot = 0;
        taxAmount = 0;
        disAmount = 0;
        //grandTotal = 0;
        
        //Allocating memory to store filter values of soRelatedList
        selectedSOItem = new list<ItemsorderWrapper>(); 
        selectedSOItemList = new list<SO_Line_Items__c>();  
        getqtyinv = new map<SO_Line_Items__c,String>();
        getsubTotalinv = new map<SO_Line_Items__c,String>();
        getdisAmtinv = new map<SO_Line_Items__c,String>();
        gettaxAmtinv = new map<SO_Line_Items__c,String>();
        getrowTinv = new map<SO_Line_Items__c,String>();
        try {
            //get the records from soRelatedList for the quantiy to Invoice greater than and not equal to zero
            for(ItemsorderWrapper oneItem: soRelatedList) {
                if(oneItem.qty > '0' || oneItem.qty != '0') {
                    selectedSOItem.add(oneItem);
                    selectedSOItemList.add(oneItem.SoItem);
                    getqtyinv.put(oneItem.SoItem,oneItem.qty);
                    getsubTotalinv.put(oneItem.SoItem,oneItem.subTotal);
                    getdisAmtinv.put(oneItem.SoItem,oneItem.disAmount);
                    gettaxAmtinv.put(oneItem.SoItem,oneItem.taxAmount);
                    getrowTinv.put(oneItem.SoItem,oneItem.rowTotal);
                }
            }
            System.debug('selectedSOItem: '+selectedSOItem);
            System.debug('selectedSOItem: '+selectedSOItem.size());
            System.debug('*********************************************************');
            System.debug('getqtyinv Keys: '+getqtyinv.keySet());
            System.debug('getqtyinv Values: '+getqtyinv.values());
            System.debug('getrowTinv Keys: '+getrowTinv.keySet());
            System.debug('getrowTinv Values: '+getrowTinv.values());
        }
        Catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
    }
    
    PageReference performChangeToManualPaymentInvoice(){
        PageReference pr;
        updateitemInvoice();
        //---------------- check on errors --------------
        invoiceAmount = paymentMethodForManualChanging.Amount__c;
        if(invoiceAmount > SO_Obj.Total_Due__c || invoiceAmount <= 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error, 'Invalid manual invoice amount'));
            return null;
        }
        List<Transaction__c> transactionList = new List<Transaction__c>();
        if(String.isNotBlank(currentTransactionId)){
            if(currentTransaction.Payment_Method__r.RecordType.Name == 'Credit Card (Authorize.net)' || currentTransaction.Payment_Method__r.RecordType.Name == 'Credit Card'){
                AuthorizeDotNetFunctions authorizeDotNetFunctionsObject = new AuthorizeDotNetFunctions();
                AuthorizeDotNetResponse responseObject = authorizeDotNetFunctionsObject.voidTransaction(currentTransaction.Payment_Method__r.Customer_Profile_ID__c, currentTransaction.Payment_Method__r.Payment_Profile_ID__c, currentTransaction.TransactionId__c, currentTransaction.createddate, SO_Obj.Authdotnetoldaccount__c);
                if (responseObject.transactionId != null && (responseObject.error == null || responseObject.error == '')){
                    transactionList.add(new Transaction__c(Id = currentTransactionId, Status__c = 'Voided'));
                }
                else{
                    transactionList.add(new Transaction__c(Id = currentTransactionId, Response__c = responseObject.response, Error__c = responseObject.error ));
                }
            }else{
                transactionList.add(new Transaction__c(Id = currentTransactionId, Status__c = 'Voided'));
            }
        }
        //-----------------------------------------------

        Boolean isLockedApprover = !approverHandler.unlockApprover(false);
        if(isLockedApprover){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error, 'Can\'t unlock Customer Account .'));  
            return null;
        }
        //----------- Create Invoice object ----------------
        Invoice__c changeToManualInvoice = new Invoice__c(); 
        changeToManualInvoice.Sales_Order__c = SO_Obj.id;
        changeToManualInvoice.Amount_Invoiced_changed_to_manual__c = invoiceAmount;
        changeToManualInvoice.Change_to_Manual_Payment__c = true;   
        changeToManualInvoice.Invoice_Status__c='Capture-Success';
        changeToManualInvoice.Customer_Name__c = SO_Obj.Customer_Name__c;
        changeToManualInvoice.Shipping__c = SO_Obj.Shipping_Handle__c; 
        changeToManualInvoice.Sales_Order_Discount__c = SO_Obj.DiscountAmount__c;
        if (SO_Obj.DiscountAmount__c != null && SO_Obj.Tax_Percentage__c != null){
            changeToManualInvoice.Sales_Order_Discount_Tax__c = (SO_Obj.DiscountAmount__c != null && SO_Obj.Tax_Percentage__c != null) ? SO_Obj.DiscountAmount__c/100*SO_Obj.Tax_Percentage__c : 0;//SO_Obj.DiscountAmount__c/100*SO_Obj.Tax_Percentage__c != null ? SO_Obj.DiscountAmount__c/100*SO_Obj.Tax_Percentage__c : 0;
        }
        else{
            changeToManualInvoice.Sales_Order_Discount_Tax__c = 0;
        }
        changeToManualInvoice.Shipping_Tax__c = SO_Obj.Shipping_Tax__c != null ? SO_Obj.Shipping_Tax__c : 0;
        changeToManualInvoice.Email__c = SO_Obj.Customer_Email__c;
        changeToManualInvoice.RecordTypeId = [SELECT id 
                                FROM RecordType 
                                WHERE name='receivables' AND sobjecttype='Invoice__c'].id;

        changeToManualInvoice.Notify_Customer_by_Email__c = isChecked;
        changeToManualInvoice.Number_of_Invoices_Sent__c = isChecked ? 1 : 0 ; 
        changeToManualInvoice.Items_invoiced__c = SO_Obj.Total_Due__c == invoiceAmount ? getqtyinv.size() : 0;
        
        insert changeToManualInvoice;
        //----------------------------------------------

        //------------- Create payment method ----------
        Set<String> manualPaymentTypeForLimitNumberSet = new Set<String>{'Credit Card', 'Cardknox'};
        paymentMethodForManualChanging.Amount__c = invoiceAmount;
        paymentMethodForManualChanging.Manual_Payment_Type__c = chosenManualPaymentType;
        if(paymentMethodForManualChanging.Account__c == null){
            paymentMethodForManualChanging.Account__c = SO_Obj.Customer_Name__c;
        }
        if(manualPaymentTypeForLimitNumberSet.contains(chosenManualPaymentType)){
            paymentMethodForManualChanging.Last_4_digits_of_CC__c = Decimal.valueOf(paymentMethodForManualChanging.Credit_Card_Number__c);
            paymentMethodForManualChanging.Credit_Card_Number__c = null;
        }
        insert paymentMethodForManualChanging;
        //----------------------------------------------

        //----- Create transaction ----------------
        
        Transaction__c transactionObject = new Transaction__c();
        transactionObject.Sales_Order__c = SO_Obj.Id;
        transactionObject.Amount__c = invoiceAmount;
        transactionObject.Transaction_Type__c = 'CAPTURE_ONLY';
        transactionObject.Status__c = 'Captured';
        transactionObject.Payment_Method__c = paymentMethodForManualChanging.Id;
        transactionObject.Invoice__c = changeToManualInvoice.Id;

        transactionList.add(transactionObject);
        
        
        upsert transactionList;
        //--------------------------------------------
        
        //------------- Create invoice lineItems ------
        if(invoiceAmount == SO_Obj.Total_Due__c){
            List<SO_Line_Items__c> itemSOList = new List<SO_Line_Items__c>();
            List<Invoice_Line_Item__c> invoiceLineItemsList = obatinInvoiceItems(changeToManualInvoice.Id, itemSOList);
            update itemSOList;
            insert invoiceLineItemsList;            
            UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(new Map<Id, Invoice_Line_Item__c>(invoiceLineItemsList).keySet());
        }
        //---------------------------------------------

        //----- update Sales_Order ----------------
        SO_Obj.Payment_Status__c = (SO_Obj.Total_Due__c > invoiceAmount ) ? 'Partial' : 'Received';
        SO_Obj.Payment_Method__c = 'Manual Payment'; 
        if (SO_Obj.Payment_Status__c == 'Received' && SO_Obj.Order_Status__c == 'Need Payment'){
        	SO_Obj.Order_Status__c = 'Processing';
        }
        update SO_Obj;
        //--------------------------------------------
        
        isLockedApprover = approverHandler.lockApprover(false);

        pr = new PageReference('/'+SO_Obj.id);
        pr.setRedirect(true);

        return pr;
    }

     List<Invoice_Line_Item__c> obatinInvoiceItems (String invoiceId, List<SO_Line_Items__c> itemSOList){
        RecordType receivableType = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Invoice_Line_Item__c' AND Name = 'Receivable Line Items'];
        List<Invoice_Line_Item__c> itemInvoiceList = new List<Invoice_Line_Item__c>();
        for(SO_Line_Items__c SOItemList:selectedSOItemList) 
        {
            if(!getqtyinv.containsKey(SOItemList)){
                continue;
            }
            for(SO_Line_Items__c oneSOItem:getqtyinv.keySet()) 
            {
                if(SOItemList.id == oneSOItem.id) {
                    Invoice_Line_Item__c itemInvoice = new Invoice_Line_Item__c();
                    Decimal currentSubTotal = Decimal.valueof(getsubTotalinv.get(oneSOItem));
                    Decimal currentDiscount = Decimal.valueof(getdisAmtinv.get(oneSOItem));
                    itemInvoice.RecordTypeId = receivableType.Id;
                    itemInvoice.Invoice__c = invoiceId;
                    itemInvoice.Sales_Order__c = oneSOItem.Sales_Order__c;
                    itemInvoice.Items_invoiced__c = oneSOItem.id;
                    String strQ2I = getqtyinv.get(oneSOItem);
                    itemInvoice.Quantity_to_Invoice__c = Integer.valueof(strQ2I.trim());
                    itemInvoice.Tax_Amount_Hidden__c = Decimal.valueof(gettaxAmtinv.get(oneSOItem));
                    itemInvoice.Sub_Total__c = currentSubTotal;
                    itemInvoice.Discount_Amount_Hidden__c = currentDiscount;
                    itemInvoiceList.add(itemInvoice);

                    
                    oneSOItem.Invoiced_Sub_Total__c = oneSOItem.Sub_Total__c;
                    oneSOItem.Invoiced_Discount__c = oneSOItem.Discount_Amount__c;
                    oneSOItem.Invoiced_Quantity__c = oneSOItem.Quantity__c;
                    oneSOItem.Invoiced_Tax__c = oneSOItem.TaxAmount__c;
                    oneSOItem.Invoiced_Total__c = oneSOItem.Total__c;
                    itemSOList.add(oneSOItem);
                }
            }
        }
        return itemInvoiceList;
    }
    public string captureType{get; set;}
    public boolean wasVoided{get; set;}
    public static boolean isRunning{get; set;}
    //Method to insert invoice records once its submitted
    public PageReference submitInvoice() 
    {
        if(isChangeToManualPayment || hasPartialManualPayment || (invoiceAmount != SO_Obj.Total_Due__c && SO_Obj.Payment_Method__c == 'Manual Payment')){
            return performChangeToManualPaymentInvoice(); 
        }

        if (invObj != null && invObj.id != null){
            return new PageReference('/'+invObj.id);
        }
        system.debug('isRunning = ' + isRunning);
        if (isRunning != null && isRunning) return null;
        isRunning = true;
        PageReference pr;
        invObj = new Invoice__c(); 
        Boolean isLockedApprover;
        map<id,Transaction__c> getPaymentMethodIdMap = new map<id,Transaction__c>();
        try
        {
            updateitemInvoice();
            if(SO_Obj.Payment_Status__c == 'Authorized' || SO_Obj.Payment_Status__c == 'Partial' || 
                (SO_Obj.Payment_Status__c == 'Pending' && (SO_Obj.Payment_Method__c == 'Manual Payment' || SO_Obj.Payment_Method__c == 'Cardknox' ) )
                    || ((SO_Obj.Payment_Status__c == 'Capture-Failed' || SO_Obj.Payment_Status__c == 'Capture-Failed') && (SO_Obj.Payment_Method__c == 'Credit Card' || SO_Obj.Payment_Method__c == 'Manual Payment'))
                ){// || SO_Obj.Payment_Method__c =='Zibby by Affirm'
                    Set<String> paymentTypeSet = new Set<String>{ 'Manual Payment', 'Cardknox'}; //'Zibby by Affirm',
                transactionObjectList = [select id,name,Payment_Method__c,TransactionId__c,Amount__c, Days_opened__c, Payment_Type__c, createddate from Transaction__c where Sales_Order__c=:SO_Obj.id and (Transaction_Type__c='AUTH_ONLY' OR Transaction_Type__c='authorization') AND (Status__c='Authorized' OR Payment_Type__c IN: paymentTypeSet)];//= 'Manual Payment' OR Payment_Type__c = 'Cardknox'
                list<Transaction__c> succeededTransactionObjectList = [select id, Payment_Type__c, TransactionId__c, Amount__c, createddate from Transaction__c where Sales_Order__c=:SO_Obj.id and Status__c='Captured'];
                System.debug('transactionObjectList: '+transactionObjectList);
                if(transactionObjectList.size() > 0) 
                {                  
                    isreqField = false;
                    styleVar = null;
                    
                    transactionObject = transactionObjectList[0];
                	set<string> transactioIds = new set<string>();
                    
                    for(Transaction__c oneTransaction : succeededTransactionObjectList) 
                    {
                    	if (oneTransaction.TransactionId__c != null){
                    		transactioIds.add(oneTransaction.TransactionId__c);
                    	}
                    	if (oneTransaction.Payment_Type__c == 'Affirm'   || oneTransaction.Payment_Type__c == 'Zibby by Affirm' || oneTransaction.Payment_Type__c == 'Affirm: Buy Now with 3 Easy Payments' || oneTransaction.Payment_Type__c == 'PayPal' || oneTransaction.Payment_Type__c == 'PayPal Express Checkout'){
                    		transactioIds.add(string.valueof(oneTransaction.Amount__c));
                    	}
                    }
                    
                    for(Transaction__c oneTransaction : transactionObjectList) 
                    {
                        //getPaymentMethodId.add(oneTransaction.Payment_Method__c);
                        if (!transactioIds.contains(oneTransaction.TransactionId__c) && !transactioIds.contains(string.valueof(oneTransaction.Amount__c))){
                        	getPaymentMethodIdMap.put(oneTransaction.Payment_Method__c, oneTransaction);
                        }
                    }
                    System.debug('getPaymentMethodIdMap: '+getPaymentMethodIdMap);
                    list<Payment_Method__c> paymentMethodVarList = [select id,Amount__c,name,Customer_Profile_ID__c,Payment_Profile_ID__c,recordtype.name from Payment_Method__c where id in :getPaymentMethodIdMap.keySet()];
                    
                    System.debug('paymentMethodVarList: '+paymentMethodVarList);
                    
                    //RecordType receivableType = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Invoice_Line_Item__c' AND Name = 'Receivable Line Items'];
                    invObj.Sales_Order__c = SO_Obj.id;
                    
                    invObj.Customer_Name__c = SO_Obj.Customer_Name__c;
                    invObj.Shipping__c = SO_Obj.Shipping_Handle__c;
                    invObj.Sales_Order_Discount__c = SO_Obj.DiscountAmount__c;
                    if (SO_Obj.DiscountAmount__c != null && SO_Obj.Tax_Percentage__c != null){
                    	invObj.Sales_Order_Discount_Tax__c = SO_Obj.DiscountAmount__c/100*SO_Obj.Tax_Percentage__c != null ? SO_Obj.DiscountAmount__c/100*SO_Obj.Tax_Percentage__c : 0;
                    }
                    else{
                    	invObj.Sales_Order_Discount_Tax__c = 0;
                    }
                    invObj.Shipping_Tax__c = SO_Obj.Shipping_Tax__c != null ? SO_Obj.Shipping_Tax__c : 0;
                    invObj.Email__c = SO_Obj.Customer_Email__c;
                    invobj.Items_invoiced__c = getqtyinv.size();
                    invobj.RecordTypeId = [select id from RecordType where name='receivables' and sobjecttype='Invoice__c'].id;
                    
                    transactionObjectList = new List<Transaction__c>();
                    for(Payment_Method__c paymentMethodVar : paymentMethodVarList)
                    {
                        if(paymentMethodVar.recordtype.name == 'Credit Card (Authorize.net)' || paymentMethodVar.recordtype.name == 'Credit Card')
                        {
                            AuthorizeDotNetResponse responseObject = new AuthorizeDotNetResponse();
                            Transaction__c t = getPaymentMethodIdMap.get(paymentMethodVar.id);
                            System.debug('t: '+t);
                            system.debug('SO_Obj ' + SO_Obj+'paymentMethodVar.Id ' + paymentMethodVar.Id+' getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c : '+getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c+' taxAmount : '+taxAmount);
                            //AuthorizeDotNetResponse resposeObject = capture(SO_Obj,paymentMethodVar.Id,getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c,taxAmount);
                            AuthorizeDotNetResponse resposeObject = capture(paymentMethodVar.Id, t, string.valueof(t.Amount__c), '', SO_Obj, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c, taxAmount);
                            if (wasVoided){
                                Transaction__c transactionObject = new Transaction__c();
                                transactionObject.id = t.id;
                                transactionObject.Status__c = 'Voided';
                                transactionObjectList.add(transactionObject);
                            }
                            System.debug('---------- Enter into Try Block ------------');
                            System.debug('resposeObject: '+resposeObject);
                            transactionObject = new Transaction__c();
                            
                            transactionObject.Transaction_Type__c = captureType;
                            transactionObject.Sales_Order__c = SO_Obj.ID;
                            transactionObject.Payment_Method__c = paymentMethodVar.id;
                            transactionObject.Amount__c = t.Amount__c;
                            
                            transactionObject.Response__c = resposeObject.response;
                            if(resposeObject.transactionId == null){
                                transactionObject.Status__c = 'Failed';
                                transactionObject.Error__c = resposeObject.error;
                                //transactionObject.TransactionId__c = t.TransactionId__c;
                            }
                            else {
                                transactionObject.Status__c = 'Captured';
                                transactionObject.TransactionId__c = resposeObject.transactionId;
                                transactionObject.Transaction_Response__c = resposeObject.responseReasonText;
                                transactionObject.Trans_AVS_Response__c = responseObject.avsResponse;
                            }
                            
                            transactionObjectList.add(transactionObject);
                            //break;
                        }
                        else if(paymentMethodVar.recordtype.name == 'PayPal' || paymentMethodVar.recordtype.name == 'PayPal Express Checkout')
                        {
                            payPalResponse payPalResponseOBJ = new payPalResponse();
                            PaypalConnect PaypalConnectOBJ = new PaypalConnect(SO_Obj.Customer_Name__r.Web_Site__c);                            
                            payPalResponseOBJ = capturePayPal(SO_Obj, getPaymentMethodIdMap.get(paymentMethodVar.id).TransactionId__c, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c); 
                            
                            system.debug('payPalResponseOBJ '+payPalResponseOBJ);
                            transactionObject = new Transaction__c();
                            
                            transactionObject.Transaction_Type__c = 'CAPTURE_ONLY';
                            transactionObject.Sales_Order__c = SO_Obj.ID;
                            transactionObject.Payment_Method__c = paymentMethodVar.id;
                            transactionObject.Amount__c = getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c;
                            //transactionObject.Transaction_Response__c = payPalResponseOBJ.responseReasonText;
                            transactionObject.Response__c = payPalResponseOBJ.response;
                            if(payPalResponseOBJ.id == null){ 
                                transactionObject.Status__c = 'Failed';
                                transactionObject.Error__c = payPalResponseOBJ.error;
                            }
                            else {
                                transactionObject.Status__c = 'Captured';  
                                transactionObject.TransactionId__c = payPalResponseOBJ.id;
                            }
                            
                            system.debug('resposeObject--->'+payPalResponseOBJ);
                            transactionObjectList.add(transactionObject);
                        }
                        else if( paymentMethodVar.recordtype.name == 'Zibby by Affirm' || paymentMethodVar.recordtype.name == 'Affirm' || paymentMethodVar.recordtype.name == 'Affirm: Buy Now with 3 Easy Payments')
                        {
                            string orderNumber = SO_Obj.Magento_order_No__c != null && SO_Obj.Magento_order_No__c != '' ? SO_Obj.Magento_order_No__c : SO_Obj.Id;
                            AffirmIntagrationManager.Request affirmReq = new AffirmIntagrationManager.Request(orderNumber,'','');
                            AffirmIntagrationManager.Response affirmRes;
                            if(paymentMethodVar.recordtype.name == 'Zibby by Affirm'){
                                affirmRes = AffirmIntagrationManager.captureZibbyByAffirm(SO_Obj.Transaction_ID__c, affirmReq, SO_Obj.Customer_Name__r.Web_Site__c);
                            }else{
                                affirmRes = AffirmIntagrationManager.captureWithChargeId(SO_Obj.Transaction_ID__c, affirmReq, SO_Obj.Customer_Name__r.Web_Site__c);
                            }
                            system.debug('affirmRes = ' + affirmRes);
                            transactionObject = new Transaction__c();
                            
                            transactionObject.Transaction_Type__c = 'CAPTURE_ONLY';
                            transactionObject.Sales_Order__c = SO_Obj.ID;
                            transactionObject.Payment_Method__c = paymentMethodVar.id;
                            transactionObject.Amount__c = getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c;
                            //transactionObject.Transaction_Response__c = payPalResponseOBJ.responseReasonText;
                            if(affirmRes.id == null) {
                                transactionObject.Status__c = 'Failed';
                                transactionObject.Transaction_Response__c = affirmRes.message;
                            }
                            else {
                                transactionObject.Status__c = 'Captured';  
                                transactionObject.TransactionId__c = affirmRes.id;
                            }
                            transactionObjectList.add(transactionObject);
                        }
                        else if(paymentMethodVar.recordtype.name == 'CheckoutFinance')
                        {
                        	FinanceIntegrationManager.Response financeRes = FinanceIntegrationManager.capture(SO_Obj.Transaction_ID__c);
                        	system.debug('financeRes = ' + financeRes);
                            transactionObject = new Transaction__c();
                            
                            transactionObject.Transaction_Type__c = 'CAPTURE_ONLY';
                            transactionObject.Sales_Order__c = SO_Obj.ID;
                            transactionObject.Payment_Method__c = paymentMethodVar.id;
                            transactionObject.Amount__c = getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c;
                            //transactionObject.Transaction_Response__c = payPalResponseOBJ.responseReasonText;
                            if(financeRes.chargeId == null) {
                                transactionObject.Status__c = 'Failed';
                                transactionObject.Transaction_Response__c = financeRes.message;
                            }
                            else {
                                transactionObject.Status__c = 'Captured';  
                                transactionObject.TransactionId__c = financeRes.chargeId;
                            }
                            transactionObjectList.add(transactionObject);
                        }
                        else if(paymentMethodVar.recordtype.name == 'Manual Payment' || paymentMethodVar.recordtype.name == 'Cardknox' ){//
                        	Transaction__c t = getPaymentMethodIdMap.get(paymentMethodVar.id);
                        	Transaction__c transactionObject = new Transaction__c();
                            transactionObject.id = t.id;
                        	transactionObject.Status__c = 'Captured';
                        	transactionObjectList.add(transactionObject);
                        }
                    }
                    if(invObj != null) {
                        isLockedApprover = !approverHandler.unlockApprover(false);
                        if(isLockedApprover){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error, 'Can\'t unlock Customer Account .'));  
                            return null;
                        }
                        try {
                            insert invObj;
                        }
                        catch(exception excee){
                            if (invObj.id != null)
                                return new PageReference('/'+SO_Obj.id);//new PageReference('/'+invObj.id);
                            else{
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error, excee.getmessage() + '' + excee.getlinenumber()));
                                //return null;
                            }
                        }
                        
                        invobj = [select id,Invoice_Status__c,RecordTypeId,Transaction_ID__c,Transaction_Response__c,name,CreatedDate,Sales_Order__c,Customer_Name__c,Email__c,Items_invoiced__c,Payment_Method__c,authorization_Transaction__c from Invoice__c where id=:invobj.id];
                        
                        System.debug('invObj: '+invObj);
                        System.debug('Successfully Invoice Created');
                        
                        list<Task> TaskList = new List<Task>();
                        for(Transaction__c transactionObject : transactionObjectList)
                        {
                            transactionObject.Invoice__c = invObj.id;
                            
                            Task taskVar = new Task();
                            taskVar.WhatId = SO_Obj.id;
                            if(transactionObject.TransactionId__c == null && transactionObject.Status__c == 'Failed')
                            {
                                taskVar.Subject='Order Amount('+transactionObject.Amount__c+') Capture-Failed: '+invobj.name;
                                taskVar.Status='Open';
                                taskVar.ownerid=UserInfo.getUserId();
                                TaskList.add(taskVar);
                            }
                            
                        }
                        
                        insert TaskList;
                        upsert transactionObjectList;
                        
                        List<SO_Line_Items__c> itemSOList = new List<SO_Line_Items__c>();
                        itemInvoiceList = obatinInvoiceItems(invobj.Id, itemSOList);

                        if(!itemInvoiceList.isEmpty() || itemInvoiceList.size() != 0) 
                        {
                            update itemSOList;
                            insert itemInvoiceList;
                            System.debug('itemInvoiceList: '+itemInvoiceList);
                            System.debug('isChecked: '+isChecked);
                            invobj.Notify_Customer_by_Email__c = isChecked;
                            if(isChecked == true) 
                            {
                                invobj.Number_of_Invoices_Sent__c = 1; 
                            }
                            else 
                            {
                                invobj.Number_of_Invoices_Sent__c = 0; 
                            }
                            if((transactionObject.TransactionId__c == null || transactionObject.TransactionId__c == '') && SO_Obj.Payment_Method__c != 'Manual Payment' && SO_Obj.Payment_Method__c != 'Cardknox' ) {//&& SO_Obj.Payment_Method__c != 'Zibby by Affirm'
                                invobj.Invoice_Status__c='Capture-Failed';
                                
                                SO_Obj.Payment_Status__c='Capture-Failed';
                            }
                            else {
                                invobj.Invoice_Status__c='Capture-Success';
                                
                                SO_Obj.Payment_Status__c='Received';
                                if (SO_Obj.Payment_Status__c == 'Received' && SO_Obj.Order_Status__c == 'Need Payment'){
                                    SO_Obj.Order_Status__c = 'Processing';
                                }
                                set<id> invoiceItems = new set<id>();
                                
                                
                                for(Invoice_Line_Item__c invItems : itemInvoiceList) {
                                    invoiceItems.add(invItems.id);
                                }
                                UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);
                            }
                            //SO_Obj.Promotion__c = null; //--------------------------------------------------------remove promotion from sale order after invoicing
                            update SO_Obj;
                            Update invobj;
                            
                            pr = new PageReference('/'+SO_Obj.id);//new PageReference('/'+invObj.id);
                            pr.setRedirect(true);
                            return pr;
                        }
                        else if(itemInvoiceList.size() == 0)
                        {
                            delete invObj;
                        }
                        System.debug('itemInvoiceList: '+itemInvoiceList);
                    }
                }
                else 
                {
                    isRunning = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'You cannot create Invoice, please make sure that transaction id is generated for Salesorder.'));  
                }
            }
            else 
            {
                isreqField = true;
                styleVar = 'border-left-color: #d74c3b;border-left-width: thick;';
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'You cannot create Invoice, please make sure that payment Status is Authorized.'));  
            }
            isLockedApprover = approverHandler.lockApprover(false);
        }
        Catch(Exception e) 
        {
            isLockedApprover = approverHandler.lockApprover(false);
            isRunning = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
        }
        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Test error'));
        
        if(ApexPages.hasMessages()){
            return null;
        }else{
            return pr;
        }
        
        //
    }
    
    // Capture through AuthorizeDotNet
    @TestVisible 
    //private AuthorizeDotNetResponse capture(Sales_Order__c salesOrderObject,string paymentMethodID,decimal grandTotal,decimal taxAmount)
    private AuthorizeDotNetResponse capture(string paymentMethodID, Transaction__c trans, string amount, string invoiceNumber, Sales_Order__c salesOrderObject, decimal grandTotal, decimal taxAmount)
    {
        captureType = '';
        wasVoided = false;
        AuthorizeDotNetResponse responseObject = new AuthorizeDotNetResponse();
        try
        {
            if(paymentMethodID != null) 
            {
                Payment_Method__c paymentMethodVar = [select id,name,Customer_Profile_ID__c,Payment_Profile_ID__c from Payment_Method__c where id=:paymentMethodID];
                System.debug('paymentMethodVar :: '+paymentMethodVar);
                System.debug('trans: '+trans);
                //Transaction__c trans = [select Days_opened__c from Transaction__c where id = :transactionId];
                
                //System.debug('salesOrderObject id: '+salesOrderObject.id);
                System.debug('paymentMethod id: '+paymentMethodID);
                System.debug('transactionObject: '+transactionObject);
                System.debug('trans: '+trans);
                
                AuthorizeDotNetFunctions authorizeDotNetFunctionsObject = new AuthorizeDotNetFunctions();
                system.debug('paymentMethodVar.Payment_Profile_ID__c: '+paymentMethodVar.Payment_Profile_ID__c);
                system.debug('paymentMethodVar.Customer_Profile_ID__c ' + paymentMethodVar.Customer_Profile_ID__c+' string.valueOf(grandTotal) '+string.valueOf(grandTotal)+' string.valueOf(taxAmount)  '+string.valueOf(taxAmount));
                //response object
                Transaction__c transactionObject = new Transaction__c();
                boolean insertTransaction = false;
                string orderNumber = SO_Obj.Magento_order_No__c != null && SO_Obj.Magento_order_No__c != '' ? SO_Obj.Magento_order_No__c : SO_Obj.Id;
                //if more than 7 days
                if (trans.Days_opened__c >= 7){
                    responseObject = authorizeDotNetFunctionsObject.createCustomerAuthAndCaptureTransaction(paymentMethodVar.Customer_Profile_ID__c, paymentMethodVar.Payment_Profile_ID__c, string.valueOf(grandTotal), string.valueOf(taxAmount), orderNumber, trans.createddate, SO_Obj.Authdotnetoldaccount__c);
                    //if succeeded void ther auth 
                    System.debug('111111111111: ');
                    System.debug('responseObject: ' + responseObject);
                    if (responseObject.transactionId != null && (responseObject.error == null || responseObject.error == '')){
                        captureType = 'AUTH_W_CAPTURE';
                        wasVoided = true;
                        authorizeDotNetFunctionsObject.voidTransaction(paymentMethodVar.Customer_Profile_ID__c, paymentMethodVar.Payment_Profile_ID__c, trans.TransactionId__c, trans.createddate, salesOrderObject.Authdotnetoldaccount__c);
                        System.debug('222222222222: ');
                    }
                    else{
                        insertTransaction = true;
                        transactionObject.Status__c = 'Failed';
                        transactionObject.Transaction_Type__c = 'AUTH_W_CAPTURE';
                        transactionObject.Sales_Order__c = salesOrderObject.ID;
                        transactionObject.Payment_Method__c = paymentMethodVar.id;
                        transactionObject.Amount__c = trans.Amount__c;
                        
                        transactionObject.Response__c = responseObject.response;
                        transactionObject.Error__c = responseObject.error;
                    }
                }
                //if less than 7 days or capture-failed
                if (trans.Days_opened__c < 7 || (responseObject.transactionId == null || responseObject.error != null)){
                    captureType = 'CAPTURE_ONLY';
                    responseObject = authorizeDotNetFunctionsObject.CaptureaPreviouslyAuthorizedAmount(trans.TransactionId__c, amount,orderNumber, salesOrderObject.createddate, salesOrderObject.Authdotnetoldaccount__c);
                }
                if (insertTransaction){
                    insert transactionObject;
                }
                System.debug('responseObject: '+responseObject);
            }
            else 
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'You cannot create Invoice, please make sure that payment method is added in Salesorder.'));  
            }    
        }
        Catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Exception '+e.getMessage()+' '+e.getLineNumber()));  
            system.debug('Exception'+e.getMessage()+' '+e.getLineNumber() );
        }
        return responseObject;
    }
    
    // Capture through paypal
    @TestVisible 
    private payPalResponse capturePayPal(Sales_Order__c salesOrderObject,string transactionId,decimal grandTotal)
    {
        PaypalConnect PaypalConnectOBJ = new PaypalConnect(SO_Obj.Customer_Name__r.Web_Site__c);
        payPalResponse payPalResponseOBJ = new payPalResponse();
        
        try
        {
            System.debug('salesOrderObject: '+salesOrderObject);
            System.debug('transactionObject: '+transactionObject);
            
            if(transactionId != null) 
            {
                payPalResponseOBJ = PaypalConnectOBJ.capturePayment(string.valueof(grandTotal),transactionObject.TransactionId__c);
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'You cannot create Invoice, please make sure that payment method is added in Salesorder.'));  
            }    
        }
        Catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error, 'Exception'+e.getMessage()+' '+e.getLineNumber())); 
            system.debug('Exception'+e.getMessage()+' '+e.getLineNumber() );
        }
        return payPalResponseOBJ;
    }

    // public class AppoverLockUnlockHandler{
    //     Boolean hasBeenLocked;
    //     Boolean isLockedNow;
    //     String sObjectId;

    //     public AppoverLockUnlockHandler(String sObjectId){
    //         this.sObjectId = sObjectId;
    //         isLockedNow = hasBeenLocked = Approval.isLocked(sObjectId);
    //     }

    //     public Boolean unlockApprover(Boolean forceUnlock){
    //         Boolean result = true;
    //         if((hasBeenLocked && isLockedNow) || forceUnlock){
    //             if(!Approval.unlock(sObjectId, false).isSuccess()){
    //                 result = false;
    //             }
    //         }
    //         isLockedNow = !result;
    //         return result; // !isLockedNow = !result;
    //     }

    //     public Boolean lockApprover(Boolean forceLock){
    //         Boolean result = true;                
    //         if((hasBeenLocked && !isLockedNow) || forceLock){
    //             if(!Approval.lock(sObjectId, false).isSuccess()){
    //                 result = false;
    //             }
    //         }
    //         return isLockedNow = result;
    //     }
        
    // }

    // Wrapper Class
    public class ItemsorderWrapper
    {
        public SO_Line_Items__c SoItem {get; set;}
        public string qty {get; set;}
        public string subTotal {get;set;}
        public string taxAmount {get;set;}
        public string disAmount {get;set;}
        public string rowTotal {get;set;}
        
        public ItemsorderWrapper(SO_Line_Items__c So,string qt, String subT,String taxA,String disA,String rowT) 
        {
            SoItem = So;
            qty = qt;
            subTotal = subT;
            rowTotal = rowT;
            taxAmount = taxA;
            disAmount = disA;
        }
    }
}