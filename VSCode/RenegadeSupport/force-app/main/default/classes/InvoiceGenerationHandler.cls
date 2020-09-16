public with sharing class InvoiceGenerationHandler {
    static String captureType;
    static Boolean wasVoided;
    static Boolean isChecked = true; 
    static Map<String, Decimal> salesOrderToTaxAmount;
    static Map<String, List<ItemsorderWrapper>> salesOrderToItemSoWrapperMap;

    static Map<String, List<ItemsorderWrapper>> selectedSOItem;
    static Map<String, List<SO_Line_Items__c>>    selectedSOItemList;
    static Map<String, map<SO_Line_Items__c,String>>    getqtyinv;
    static Map<String, Map<SO_Line_Items__c, String>>   getsubTotalinv;
    static Map<String, Map<SO_Line_Items__c, String>>   getdisAmtinv;
    static Map<String, Map<SO_Line_Items__c,String>>    gettaxAmtinv;
    static Map<String, Map<SO_Line_Items__c, String>> getrowTinv;

    static Map<String, List<Invoice_Line_Item__c>> itemInvoiceList = new Map<String, List<Invoice_Line_Item__c>>();
    static Map<String, List<SO_Line_Items__c>> itemSOList  = new Map<String, List<SO_Line_Items__c>>();
    
    static RecordType receivableType = [SELECT DeveloperName,Id,Name,SobjectType FROM RecordType WHERE SobjectType = 'Invoice_Line_Item__c' AND Name = 'Receivable Line Items'];


    
    public static void generateInvoice(List<String> salesOrderIdList){
        try{
            List<Sales_Order__c> saleOrderList = [SELECT name, Bill_To__c,Magento_order_No__c, createddate, Authdotnetoldaccount__c, Payment_Status__c,Order_Status__c,Promotion__r.Name,Promotion__c, Shipping_Tax__c,
                        Total_Quantity_Ordered__c,Order_Date__c,Sales_Representative__r.name,Customer_Name__r.name,Customer_Name__r.Phone,Billing_City__c,Payment_Method__c, Customer_Name__r.Web_Site__c, TaxAmount__c,
                        Billing_State__c,Billing_Street__c,Customer_Name__c,Customer_Email__c,Ship_to__c, Shipping_City__c,Shipping_Handle__c,Mobile__c, Tax_Percentage__c, 
                        Shipping_State__c,Shipping_Street__c,Shipping_ZipCode__c,Billing_ZipCode__c,Grand_Total__c,No_Of_Products_Ordered__c, Total_Due__c, Total_Paid__c, 
                        Order_Type__c,Transaction_ID__c,Discount_AmountTotal__c, DiscountAmount__c, 
                        (SELECT Id FROM Invoice__r), 
                        (SELECT Id, UnitPrice__c,Price__c FROM SO_Line_Items__r)
                        FROM Sales_Order__c 
                        WHERE Id IN :salesOrderIdList];
            getSalesOrderData(saleOrderList);
            List<Invoice__c> invoiceList = new List<Invoice__c>();
            String InvoiceRecordTypeId = [SELECT Id FROM RecordType WHERE name='receivables' AND sobjecttype='Invoice__c'].Id;
            Set<String> paymentTypeSet = new Set<String>{'Manual Payment', 'Cardknox'}; //'Zibby by Affirm',
            Map<String, List<Transaction__c>> OrderIdToTransactionMap = populateTransactionMap(
                [SELECT Id, Name, Payment_Method__c, TransactionId__c, Amount__c, Days_opened__c, Payment_Type__c, CreatedDate, Sales_Order__c 
                FROM Transaction__c 
                WHERE Sales_Order__c IN :salesOrderIdList
                AND (Transaction_Type__c='AUTH_ONLY' OR Transaction_Type__c='authorization') 
                AND (Status__c='Authorized' OR Payment_Type__c IN :paymentTypeSet)]
            );

            Map<String, List<Transaction__c>> OrderIdToSuccededTransactionMap = populateTransactionMap(
                [SELECT id, Payment_Type__c, TransactionId__c, Amount__c, CreatedDate, Sales_Order__c
                FROM Transaction__c 
                WHERE Sales_Order__c IN :salesOrderIdList AND Status__c='Captured']
            );
            System.debug('Automate Affirm : OrderIdToTransactionMap  ' + OrderIdToTransactionMap);
            System.debug('Automate Affirm : OrderIdToSuccededTransactionMap  ' + OrderIdToSuccededTransactionMap);
            Map<Id,Transaction__c> getPaymentMethodIdMap = new Map<Id,Transaction__c>();
            Map<String, List<Payment_Method__c>> salesOrderOdToPaymentMethodsMap = obtainPaymentMethod(salesOrderIdList, OrderIdToTransactionMap, OrderIdToSuccededTransactionMap, getPaymentMethodIdMap);
            Map<String, Invoice__c> salesOrderIdToInvoiceMap = new Map<String, Invoice__c>();
            List<Task> taskToInsertList = new List<Task>();
            List<Transaction__c> transactionToUpdate = new List<Transaction__c>();
            Map<String ,List<Transaction__c>> salesOrderToFinalTransactionMap = new Map<String ,List<Transaction__c>>();
            System.debug('Automate Affirm : salesOrderOdToPaymentMethodsMap  ' + salesOrderOdToPaymentMethodsMap);
            System.debug('Automate Affirm : generate invoice 1 : saleOrderList ' + saleOrderList);
            for(Sales_Order__c currentOrder_i : saleOrderList){
                System.debug('Automate Affirm : generate invoice 2');
                if( currentOrder_i.Payment_Status__c == 'Authorized' || currentOrder_i.Payment_Status__c == 'Partial' ||  
                    (currentOrder_i.Payment_Status__c == 'Pending' && currentOrder_i.Payment_Method__c == 'Manual Payment' 
                    &&  currentOrder_i.Payment_Method__c == 'Cardknox') ){//currentOrder_i.Payment_Method__c =='Zibby by Affirm' &&
                    System.debug('Automate Affirm : generate invoice 2');
                    List<Transaction__c> transactionObjectList = OrderIdToTransactionMap.get(currentOrder_i.Id);
                    System.debug('transactionObjectList: '+transactionObjectList);
                    
                    if(transactionObjectList.size() > 0) 
                    { 
                        System.debug('Automate Affirm : generate invoice 3');
                        Transaction__c transactionObject;  
                        //Invoice__c invObj = salesOrderIdToInvoiceMap.get(currentOrder_i.Id);//new Invoice__c(); 
                        List<Transaction__c> succeededTransactionObjectList = OrderIdToSuccededTransactionMap.get(currentOrder_i.Id);

                        transactionObject = transactionObjectList.get(0);
                        List<Payment_Method__c> paymentMethodVarList = salesOrderOdToPaymentMethodsMap.get(currentOrder_i.Id);

                        System.debug('Automate Affirm : generate invoice 4: paymentMethodVarList: '+paymentMethodVarList);
                        transactionObjectList = new List<Transaction__c>();
                        for(Payment_Method__c paymentMethodVar : paymentMethodVarList)
                        {   
                            String status, error, transactionId, response, avsResponse, type;
                            switch on paymentMethodVar.recordtype.Name {
                                when ('Credit Card (Authorize.net)'), 'Credit Card' {
                                    System.debug('Automate Affirm : generate invoice : in credit Card condition: ' + itemInvoiceList);
                                    AuthorizeDotNetResponse responseObject = new AuthorizeDotNetResponse();
                                    Transaction__c t = getPaymentMethodIdMap.get(paymentMethodVar.id);
                                    AuthorizeDotNetResponse resposeObject = capture(paymentMethodVar.Id, t, string.valueof(t.Amount__c), '', currentOrder_i, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c, salesOrderToTaxAmount.get(currentOrder_i.Id), transactionObjectList);
                                    if (wasVoided){                                 
                                        transactionObjectList.add(new Transaction__c(Id = t.Id, Status__c = 'Voided'));
                                    }
                                    if(resposeObject.transactionId == null){
                                        status = 'Failed';
                                        error = resposeObject.error;
                                    }else{
                                        status = 'Captured';
                                        transactionId = resposeObject.transactionId;
                                        response = resposeObject.responseReasonText;
                                        avsResponse = responseObject.avsResponse;
                                    }
                                    transactionObjectList.add(
                                        createTransaction(captureType, currentOrder_i.Id, status, paymentMethodVar.Id, t.Amount__c, response, avsResponse, transactionId, error)
                                    );
                                }
                                when 'PayPal', 'PayPal Express Checkout' {
                                    PayPalResponse payPalResponseOBJ = new PayPalResponse();
                                    PaypalConnect PaypalConnectOBJ = new PaypalConnect(currentOrder_i.Customer_Name__r.Web_Site__c);                            
                                    payPalResponseOBJ = capturePayPal(currentOrder_i, getPaymentMethodIdMap.get(paymentMethodVar.id).TransactionId__c, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c); 
                                    if(payPalResponseOBJ.id == null){ 
                                        status = 'Failed';
                                        error = payPalResponseOBJ.error;
                                    }
                                    else {
                                        status = 'Captured';  
                                        transactionId = payPalResponseOBJ.id;
                                    }
                                    transactionObjectList.add(
                                        createTransaction('CAPTURE_ONLY', currentOrder_i.Id, status, paymentMethodVar.Id, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c, payPalResponseOBJ.response, null, transactionId, error)
                                    );

                                }
                                when 'Zibby by Affirm', 'Affirm', 'Affirm: Buy Now with 3 Easy Payments' {
                                    String orderNumber = currentOrder_i.Magento_order_No__c != null && currentOrder_i.Magento_order_No__c != '' ? currentOrder_i.Magento_order_No__c : currentOrder_i.Id;
                                    AffirmIntagrationManager.Request affirmReq = new AffirmIntagrationManager.Request(orderNumber,'','');
                                    AffirmIntagrationManager.Response affirmRes;
                                    if(paymentMethodVar.recordtype.Name == 'Zibby by Affirm' ){
                                        affirmRes = AffirmIntagrationManager.captureZibbyByAffirm(currentOrder_i.Transaction_ID__c, affirmReq, currentOrder_i.Customer_Name__r.Web_Site__c);
                                    }else{
                                        affirmRes = AffirmIntagrationManager.captureWithChargeId(currentOrder_i.Transaction_ID__c, affirmReq, currentOrder_i.Customer_Name__r.Web_Site__c);
                                    }

                                    if(affirmRes.id == null) {
                                        status = 'Failed';
                                        response = affirmRes.message;
                                    }
                                    else {
                                        status = 'Captured';  
                                        transactionId = affirmRes.id;
                                    }

                                    transactionObjectList.add(
                                        createTransaction('CAPTURE_ONLY', currentOrder_i.Id, status, paymentMethodVar.Id, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c, response, null, transactionId, null)
                                    );
                                }
                                when 'CheckoutFinance' {
                                    FinanceIntegrationManager.Response financeRes = FinanceIntegrationManager.capture(currentOrder_i.Transaction_ID__c);
                                    if(financeRes.chargeId == null) {
                                        status = 'Failed';
                                        response = financeRes.message;
                                    }
                                    else {
                                        status = 'Captured';  
                                        transactionId = financeRes.chargeId;
                                    }
                                    transactionObjectList.add(
                                        createTransaction('CAPTURE_ONLY', currentOrder_i.Id, status, paymentMethodVar.Id, getPaymentMethodIdMap.get(paymentMethodVar.id).Amount__c, response, null, transactionId, null)
                                    );
                                }
                                when 'Manual Payment', 'Cardknox' {
                                    transactionObjectList.add(new Transaction__c(Id = getPaymentMethodIdMap.get(paymentMethodVar.id).Id, Status__c = 'Captured'));
                                }
                            }
                        }
                        salesOrderToFinalTransactionMap.put(currentOrder_i.Id, transactionObjectList);
                        transactionToUpdate.addAll(transactionObjectList);
                        System.debug('Automate Affirm : generate invoice : before createInvoiceItems');
    
                    }
                }
            }
            System.debug('Automate Affirm : generate invoice : transactionToUpdate: ' + transactionToUpdate);
            System.debug('Automate Affirm : generate invoice : taskToInsertList: ' + taskToInsertList);
            List<Invoice_Line_Item__c> itemInvoiceToInsertList = new List<Invoice_Line_Item__c>();
            List<Invoice__c> invoiceToRemoveList = new List<Invoice__c> ();
            Map<String, Invoice__c> invoiceToRemoveMap = new Map<String, Invoice__c> ();
            salesOrderIdToInvoiceMap = obtainInvoiceMap(saleOrderList, InvoiceRecordTypeId);

            
            // for(Sales_Order__c current_order_i : saleOrderList){
            //     String currentInvoiceId = salesOrderIdToInvoiceMap.get(current_order_i.Id).Id;
            //     if(salesOrderToFinalTransactionMap.get(current_order_i.Id) != null){
            //         Boolean isAllFailed = true;
            //         for(Transaction__c currentTransaction_i :salesOrderToFinalTransactionMap.get(current_order_i.Id)){
            //             if(currentTransaction_i.Status__c == 'Failed'){
            //                 // invoiceToRemoveMap.put(currentInvoiceId, new Invoice__c(Id = currentInvoiceId));
            //                 // salesOrderIdToInvoiceMap.remove(current_order_i.Id);
            //                 currentTransaction_i.Invoice__c = null;
            //             }else{
            //                 isAllFailed = false;
            //             }
            //         }
            //         if(isAllFailed){
            //             invoiceToRemoveMap.put(currentInvoiceId, new Invoice__c(Id = currentInvoiceId));
            //             salesOrderIdToInvoiceMap.remove(current_order_i.Id);
            //         }
            //     } 
            // }
            
            
            
            for(Sales_Order__c currentOrder_i : saleOrderList){
                Invoice__c invObj = salesOrderIdToInvoiceMap.get(currentOrder_i.Id);
                if(salesOrderToFinalTransactionMap.get(currentOrder_i.Id) != null){
                    taskToInsertList.addAll(createTask(salesOrderToFinalTransactionMap.get(currentOrder_i.Id), currentOrder_i.Id, invObj ));//invObj
                }
                if( invObj != null && !invoiceToRemoveMap.containsKey(invObj.Id)){
                    createInvoiceItems(currentOrder_i.Id, invObj);
                }else{
                    salesOrderIdToInvoiceMap.remove(currentOrder_i.Id);
                }
            }
        
            System.debug('Automate Affirm : generate invoice : itemInvoiceList: ' + itemInvoiceList);
            for(Sales_Order__c current_order_i : saleOrderList){
                Invoice__c currentInvoice = salesOrderIdToInvoiceMap.get(current_order_i.Id);
                if(itemInvoiceList.containsKey(current_order_i.Id)){
                    itemInvoiceToInsertList.addAll(itemInvoiceList.get(current_order_i.Id));
                }else if(currentInvoice != null){
                    invoiceToRemoveMap.put(currentInvoice.Id, new Invoice__c(Id = currentInvoice.Id));
                    salesOrderIdToInvoiceMap.remove(current_order_i.Id);
                }
                
            }
            System.debug('Automate Affirm : generate invoice : itemInvoiceList: ' + itemInvoiceList);
            System.debug('Automate Affirm : generate invoice : itemInvoiceToInsertList: ' + itemInvoiceToInsertList);
            System.debug('Automate Affirm : generate invoice : invoiceToRemoveList: ' + invoiceToRemoveList);
            if(!invoiceToRemoveMap.isEmpty()){
                //delete invoiceToRemoveList;
                delete invoiceToRemoveMap.values();
            }

            if(!taskToInsertList.isEmpty()){
                insert taskToInsertList;
            }
            if(!transactionToUpdate.isEmpty()){
                upsert transactionToUpdate;
            }
            if(!itemSOList.isEmpty()){
                List<SO_Line_Items__c> itemSOToUpdateList = new List<SO_Line_Items__c>();
                for(List<SO_Line_Items__c> currentSOItemList_i :itemSOList.values()){
                    itemSOToUpdateList.addAll(currentSOItemList_i);
                }          
                update itemSOToUpdateList;
            }
            if(!itemInvoiceToInsertList.isEmpty()){
                insert itemInvoiceToInsertList;
            }

            Set<Id> invoiceItems = new Set<id>();
            List<Sales_Order__c> orderToUpdateList = new List<Sales_Order__c>();
            for(Sales_Order__c currentOrder_i : saleOrderList){
                if(salesOrderIdToInvoiceMap.containsKey(currentOrder_i.Id) && salesOrderIdToInvoiceMap.get(currentOrder_i.Id) != null && !invoiceToRemoveMap.containsKey(salesOrderIdToInvoiceMap.get(currentOrder_i.Id).Id)){
                    Integer lastTransactionIndex = salesOrderToFinalTransactionMap.get(currentOrder_i.Id).size()-1;
                    invoiceItems.addAll(updateInvoiceQuantity(salesOrderIdToInvoiceMap.get(currentOrder_i.Id), currentOrder_i, salesOrderToFinalTransactionMap.get(currentOrder_i.Id).get(lastTransactionIndex)));
                    orderToUpdateList.add(currentOrder_i);
                }
            }
            if(!invoiceItems.isEmpty()){
                UpdateSOitemInvoicedQty.addinvoicedSOItemUpdate(invoiceItems);
            }
            if(orderToUpdateList.size() > 0){
                update orderToUpdateList;
            }
            if(salesOrderIdToInvoiceMap != null && salesOrderIdToInvoiceMap.values().size() > 0){
                update salesOrderIdToInvoiceMap.values();
            }
        }catch(Exception ex){
            String errorMessage = ex.getMessage() + 'in line: '+ex.getLineNumber(); 
            System.debug('Error: ' + errorMessage);
            Log__c errorLog = new Log__c(Status__c = 'Failed', Data__c = errorMessage);
            insert errorLog;
        }
        
    }

    static Map<String, List<SO_Line_Items__c>> populateSoLineItemMap(List<SO_Line_Items__c> salesOrderLineItemList){
        Map<String, List<SO_Line_Items__c>> resultMap = new  Map<String, List<SO_Line_Items__c>>(); 
        for(SO_Line_Items__c currentOrderLineItem_i : salesOrderLineItemList){
            if(!resultMap.containsKey(currentOrderLineItem_i.Sales_Order__c)){
                resultMap.put(currentOrderLineItem_i.Sales_Order__c, new List<SO_Line_Items__c>() );
            }
            resultMap.get(currentOrderLineItem_i.Sales_Order__c).add(currentOrderLineItem_i);
        }
        return resultMap;
    } 

    static void getSalesOrderData(List<Sales_Order__c> saleOrderList){
        System.debug('Automate Affirm : in getSalesOrderData 1');
        Map<String, Decimal> salesOrderToSubTotalMap  = new Map<String, Decimal>();
        Map<String, Decimal> salesOrderToGrandTotalMap  = new Map<String, Decimal>();
        salesOrderToTaxAmount  = new Map<String, Decimal>();
        Map<String, Decimal> salesOrderTodDiscaountMap  = new Map<String, Decimal>();

        salesOrderToItemSoWrapperMap = new Map<String, List<ItemsorderWrapper>>();
        
        List<ItemsorderWrapper> SoRelatedList = new list<ItemsorderWrapper>();
        Map<id,SO_Line_Items__c> soRelatedMap = new Map<id,SO_Line_Items__c>([SELECT id,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c, OriginalPrice__c,Price__c,DiscountAmount__c, Discount_Amount__c, ProductSKU__c,Item__c,
                                                                            Product_Brand__c,Promotion_Brand__c,Products__r.Product_Image_URL__c,Quantity__c,Sales_Order__c, Sub_Total__c,TaxAmount__c,Tax_Amount__c,Tax_Percent__c,UnitPrice__c,
                                                                            Quantity_Invoiced__c, Invoiced_Sub_Total__c, Invoiced_Discount__c, Invoiced_Quantity__c, Invoiced_Tax__c, Invoiced_Total__c,
                                                                            ProductImageUrl__c, Total__c
                                                                            FROM SO_Line_Items__c WHERE Item__c != 'Cancelled' and Sales_Order__c IN :saleOrderList]);
        //Calculating Unit Price,Sub Total,Tax Amount,Discount Amount,Row Total...etc also quantity is assigned So related list
        System.debug('Automate Affirm : in getSalesOrderData 2');

            
        Map<String, List<SO_Line_Items__c>> salesOrderToLineItemsMap = populateSoLineItemMap([SELECT id,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Price__c,Sub_Total__c,
                                        DiscountAmount__c, Discount_Amount__c,Product_Url__c,ProductSKU__c, Invoiced_Sub_Total__c, Invoiced_Discount__c, Invoiced_Quantity__c, Invoiced_Tax__c, Invoiced_Total__c, TaxAmount__c,Tax_Amount__c,
                                        Tax_Percent__c,Product_Name__c,Products__r.Product_Image_URL__c,UnitPrice__c,Quantity_Invoiced__c,(SELECT id,Quantity_Invoiced__c FROM Invoice_Line_Item__r), ProductImageUrl__c,
                                        Total__c
                                        FROM SO_Line_Items__c 
                                        WHERE Item__c != 'Cancelled' and Sales_Order__c IN :saleOrderList and Bundle_Item__c = null AND Products__r.RecordType.name != 'Protection Plan' ORDER BY ProductSKU__c ASC]);

        Map<String, List<SO_Line_Items__c>> salesOrderToBundleLineItemsMap = populateSoLineItemMap([SELECT id,name,Products__c,Products__r.Image__c,Products__r.name,Manufacturer__c,OriginalPrice__c,Product_Brand__c,Promotion_Brand__c,Quantity__c,Sales_Order__c,Price__c,Sub_Total__c,DiscountAmount__c,
                                        Product_Url__c,ProductSKU__c,Invoiced_Sub_Total__c, Invoiced_Discount__c, Invoiced_Quantity__c, Invoiced_Tax__c, Invoiced_Total__c,Discount_Amount__c, TaxAmount__c,Tax_Amount__c,Tax_Percent__c,Product_Name__c,
                                        Products__r.Product_Image_URL__c,UnitPrice__c,Quantity_Invoiced__c,Row_Total__c, ProductImageUrl__c,Total__c
                                        FROM SO_Line_Items__c WHERE Sales_Order__c IN  :saleOrderList AND Products__r.RecordType.name = 'Protection Plan']);
        System.debug('Automate Affirm : in getSalesOrderData 3');
        for(Sales_Order__c currentOrder_i : saleOrderList){
            Decimal subTot = 0;
            Decimal disAmount = 0;
            Decimal taxAmount = 0; 
            Decimal grandTotal = 0;
            Boolean isChecke;

            salesOrderToItemSoWrapperMap.put(currentOrder_i.Id, new List<ItemsorderWrapper>());
            System.debug('Automate Affirm : in getSalesOrderData 4');
            for(SO_Line_Items__c soLine : salesOrderToLineItemsMap.get(currentOrder_i.Id)) {
                if(soRelatedMap.containsKey(soLine.id) && soRelatedMap.get(soLine.id).Quantity__c != soRelatedMap.get(soLine.id).Quantity_Invoiced__c) {
                    System.debug('Automate Affirm : in getSalesOrderData 5');
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
                    if (soLine.DiscountAmount__c == null){
                        soLine.DiscountAmount__c = 0;
                    }
                    if(soLine.Quantity_Invoiced__c != null || soLine.Quantity_Invoiced__c == 0) {
                        subTotal = Decimal.valueOf(UP) * (soLine.Quantity__c - soLine.Quantity_Invoiced__c);
                        taxAmt = (soLine.TaxAmount__c * (soLine.Quantity__c - soLine.Quantity_Invoiced__c)) / soLine.Quantity__c;    
                        disAmt = (soLine.DiscountAmount__c * (soLine.Quantity__c - soLine.Quantity_Invoiced__c)) / soLine.Quantity__c;
                    }
                    else {
                        subTotal = soLine.Quantity__c * Decimal.valueOf(UP);
                        taxAmt = soLine.TaxAmount__c;
                        disAmt = soLine.DiscountAmount__c;
                    }

                    Decimal rowTotal = (subTotal + taxAmt) - disAmt;
                    subTot += subTotal;
                    taxAmount += taxAmt;
                    disAmount += disAmt;

                    if(soLine.Quantity_Invoiced__c != null) {
                        salesOrderToItemSoWrapperMap.get(currentOrder_i.Id).add(new ItemsorderWrapper(soLine,String.valueOf(soLine.Quantity__c - soLine.Quantity_Invoiced__c),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal)));         
                    }
                    else {
                        salesOrderToItemSoWrapperMap.get(currentOrder_i.Id).add(new ItemsorderWrapper(soLine,String.valueOf(soLine.Quantity__c),String.valueOf(subTotal),String.valueOf(taxAmt),String.valueOf(disAmt),String.valueOf(rowTotal)));
                    }
                }
            }
            if(salesOrderToBundleLineItemsMap.containsKey(currentOrder_i.Id)){
                for(SO_Line_Items__c soLine : salesOrderToBundleLineItemsMap.get(currentOrder_i.Id)) {
                                                
                    Decimal taxAmt;
                    Decimal taxAmttemp;
                    
                    if(soRelatedMap.containsKey(soLine.id) && soRelatedMap.get(soLine.id).Quantity__c != soRelatedMap.get(soLine.id).Quantity_Invoiced__c) 
                    {
                        taxAmt = soLine.TaxAmount__c;
                        subTot += soLine.Sub_Total__c;
                        taxAmount += taxAmt;
                        if (soLine.DiscountAmount__c == null){
                            soLine.DiscountAmount__c = 0;
                        }
                        disAmount += soLine.DiscountAmount__c;
                        salesOrderToItemSoWrapperMap.get(currentOrder_i.Id).add(new ItemsorderWrapper(soLine,String.valueOf(soLine.Quantity__c),String.valueOf(soLine.Sub_Total__c),String.valueOf(taxAmt),String.valueOf(soLine.DiscountAmount__c),String.valueOf(soLine.Row_Total__c)));
                    }
                }
            }
            if (taxAmount != null && currentOrder_i.Shipping_Tax__c != null){                               
                taxAmount += currentOrder_i.Shipping_Tax__c;
            }
            
            if (currentOrder_i.DiscountAmount__c == null){
                currentOrder_i.DiscountAmount__c = 0;
            }
            grandTotal = Math.abs((subTot + currentOrder_i.Shipping_Handle__c) + currentOrder_i.TaxAmount__c - (disAmount + currentOrder_i.DiscountAmount__c));
            salesOrderToGrandTotalMap.put(currentOrder_i.Id, grandTotal);
            salesOrderToTaxAmount.put(currentOrder_i.Id, taxAmount);
        }
        System.debug('Automate Affirm : in populateSalesOrderDataMap:'+salesOrderToItemSoWrapperMap);
        populateSalesOrderDataMap(salesOrderToItemSoWrapperMap);
    }
    
    static void createInvoiceItems(String salesOrderId, Invoice__c invObj ){
        System.debug('Automate Affirm : in createInvoiceItems:');
        Boolean itemCreated = false;
        itemInvoiceList.put(salesOrderId, new List<Invoice_Line_Item__c>());
        itemSOList.put(salesOrderId, new List<SO_Line_Items__c>());
        for(SO_Line_Items__c SOItemList: selectedSOItemList.get(salesOrderId)) 
        {
            for(SO_Line_Items__c oneSOItem : getqtyinv.get(salesOrderId).keySet()) 
            {
                System.debug('Automate Affirm : in secodn loop:');
                if(getqtyinv.get(salesOrderId).containsKey(SOItemList) && SOItemList.id == oneSOItem.id) 
                {
                    System.debug('Automate Affirm : in secodn loop : invoice item creation');
                    Invoice_Line_Item__c itemInvoice = new Invoice_Line_Item__c();
                    
                    itemInvoice.RecordTypeId = receivableType.Id;
                    itemInvoice.Invoice__c = invObj.id;
                    itemInvoice.Sales_Order__c = oneSOItem.Sales_Order__c;
                    itemInvoice.Items_invoiced__c = oneSOItem.id;
                    String strQ2I = getqtyinv.get(salesOrderId).get(oneSOItem);
                    itemInvoice.Quantity_to_Invoice__c = Integer.valueof(strQ2I.trim());
                    itemInvoice.Tax_Amount_Hidden__c = Decimal.valueof(gettaxAmtinv.get(salesOrderId).get(oneSOItem));
                    itemInvoice.Sub_Total__c = Decimal.valueof(getsubTotalinv.get(salesOrderId).get(oneSOItem));
                    itemInvoice.Discount_Amount_Hidden__c = Decimal.valueof(getdisAmtinv.get(salesOrderId).get(oneSOItem));
                    
                    oneSOItem.Invoiced_Sub_Total__c = oneSOItem.Sub_Total__c;
                    oneSOItem.Invoiced_Discount__c = oneSOItem.Discount_Amount__c;
                    oneSOItem.Invoiced_Quantity__c = oneSOItem.Quantity__c;
                    oneSOItem.Invoiced_Tax__c = oneSOItem.TaxAmount__c;
                    oneSOItem.Invoiced_Total__c = oneSOItem.Total__c;
                    itemSOList.get(salesOrderId).add(oneSOItem);
                    
                    System.debug('Invoice Quantity: '+itemInvoice.Quantity_to_Invoice__c);
                    
                    itemInvoiceList.get(salesOrderId).add(itemInvoice);
                    itemCreated = true;
                }
            } 
        }
    }
    public static void populateSalesOrderDataMap(Map<String, List<ItemsorderWrapper>> soRelatedMap) {
        //Allocating memory to store filter values of soRelatedList
        selectedSOItem = new Map<String, List<ItemsorderWrapper>>(); 
        selectedSOItemList = new Map<String, List<SO_Line_Items__c>>();  
        getqtyinv = new Map<String, map<SO_Line_Items__c,String>>();
        getsubTotalinv = new Map<String, Map<SO_Line_Items__c, String>>();
        getdisAmtinv = new Map<String, Map<SO_Line_Items__c, String>>();
        gettaxAmtinv = new Map<String, Map<SO_Line_Items__c,String>>();
        getrowTinv = new Map<String, Map<SO_Line_Items__c, String>>();
        System.debug('Automate Affirm : in populateSalesOrderDataMap:');
        for(String currentOrderId_i : soRelatedMap.keySet()){
            try {
                //get the records from soRelatedList for the quantiy to Invoice greater than and not equal to zero
                for(ItemsorderWrapper oneItem: soRelatedMap.get(currentOrderId_i)) {
                    if(oneItem.qty > '0' || oneItem.qty != '0') {
                        if(!selectedSOItem.containsKey(currentOrderId_i) ){
                            selectedSOItem.put(currentOrderId_i, new List<ItemsorderWrapper>()); 
                            selectedSOItemList.put(currentOrderId_i, new List<SO_Line_Items__c>());  
                            getqtyinv.put(currentOrderId_i, new map<SO_Line_Items__c,String>());
                            getsubTotalinv.put(currentOrderId_i, new Map<SO_Line_Items__c, String>());
                            getdisAmtinv.put(currentOrderId_i, new Map<SO_Line_Items__c, String>());
                            gettaxAmtinv.put(currentOrderId_i, new Map<SO_Line_Items__c,String>());
                            getrowTinv.put(currentOrderId_i, new Map<SO_Line_Items__c, String>());
                        }
                        selectedSOItem.get(currentOrderId_i).add(oneItem);
                        selectedSOItemList.get(currentOrderId_i).add(oneItem.SoItem);
                        getqtyinv.get(currentOrderId_i).put(oneItem.SoItem,oneItem.qty);
                        getsubTotalinv.get(currentOrderId_i).put(oneItem.SoItem,oneItem.subTotal);
                        getdisAmtinv.get(currentOrderId_i).put(oneItem.SoItem,oneItem.disAmount);
                        gettaxAmtinv.get(currentOrderId_i).put(oneItem.SoItem,oneItem.taxAmount);
                        getrowTinv.get(currentOrderId_i).put(oneItem.SoItem,oneItem.rowTotal);
                    }
                }
            }
            Catch(Exception e)
            {
                System.debug('Error: '+ e.getMessage() + ' in line: ' + e.getLineNumber());
               //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,e.getMessage()+' '+e.getCause()+' '+e.getLineNumber()));  
            }
        }
    }

    static Set<id> updateInvoiceQuantity(Invoice__c invobj, Sales_Order__c SO_Obj, Transaction__c transactionObject ){
        Set<id> invoiceItems = new Set<id>();
        invobj.Notify_Customer_by_Email__c = isChecked;
        invobj.Number_of_Invoices_Sent__c = (isChecked == true) ? 1: 0;

        if((transactionObject.TransactionId__c == null || transactionObject.TransactionId__c == '') && SO_Obj.Payment_Method__c != 'Manual Payment'  && SO_Obj.Payment_Method__c != 'Cardknox' ) {//&& SO_Obj.Payment_Method__c != 'Zibby by Affirm'

            invobj.Invoice_Status__c='Capture-Failed';
            SO_Obj.Payment_Status__c='Capture-Failed';
        }
        else {
            invobj.Invoice_Status__c='Capture-Success';
            SO_Obj.Payment_Status__c='Received';
            for(Invoice_Line_Item__c invItems : itemInvoiceList.get(SO_Obj.Id)) {
                invoiceItems.add(invItems.id);
            }
        }
        return invoiceItems;
    }
    static Map<String, List<Transaction__c>> populateTransactionMap(List<Transaction__c> transactionObjectList){
        Map<String, List<Transaction__c>> resultMap = new Map<String, List<Transaction__c>>(); 
        for(Transaction__c currentTransaction_i : transactionObjectList){
            if(!resultMap.containsKey(currentTransaction_i.Sales_Order__c)){
                resultMap.put(currentTransaction_i.Sales_Order__c, new List<Transaction__c>() );
            }
            resultMap.get(currentTransaction_i.Sales_Order__c).add(currentTransaction_i);
        }
        return resultMap;
    }

    static Map<String, Invoice__c> obtainInvoiceMap(List<Sales_Order__c> salesOrderList, String InvoiceRecordTypeId){
        Map<String, Invoice__c> salesOrderIdToInvoiceMap = new Map<String, Invoice__c>();
        for(Sales_Order__c currentOrder_i : salesOrderList){        
            Invoice__c invObj = new Invoice__c();
            invObj.Sales_Order__c = currentOrder_i.id;
            invObj.Customer_Name__c = currentOrder_i.Customer_Name__c;
            invObj.Shipping__c = currentOrder_i.Shipping_Handle__c;
            invObj.Sales_Order_Discount__c = currentOrder_i.DiscountAmount__c;
            if (currentOrder_i.DiscountAmount__c != null && currentOrder_i.Tax_Percentage__c != null){
                invObj.Sales_Order_Discount_Tax__c = currentOrder_i.DiscountAmount__c/100*currentOrder_i.Tax_Percentage__c != null ? currentOrder_i.DiscountAmount__c/100*currentOrder_i.Tax_Percentage__c : 0;
            }
            else{
                invObj.Sales_Order_Discount_Tax__c = 0;
            }
            invObj.Shipping_Tax__c = currentOrder_i.Shipping_Tax__c != null ? currentOrder_i.Shipping_Tax__c : 0;
            invObj.Email__c = currentOrder_i.Customer_Email__c;
            invObj.Items_invoiced__c = getqtyinv.containsKey(currentOrder_i.Id) ? getqtyinv.get(currentOrder_i.Id).size() : 0; 
            invObj.RecordTypeId = InvoiceRecordTypeId;
            salesOrderIdToInvoiceMap.put(currentOrder_i.Id, invObj);
        }

        insert salesOrderIdToInvoiceMap.values();

        for(Invoice__c currentInvoice : [SELECT Id, Invoice_Status__c, RecordTypeId, Transaction_ID__c, Transaction_Response__c, Name, CreatedDate, Sales_Order__c, Customer_Name__c,Email__c,Items_invoiced__c,Payment_Method__c,authorization_Transaction__c
                                         FROM Invoice__c 
                                         WHERE Id in :salesOrderIdToInvoiceMap.values()]){
            salesOrderIdToInvoiceMap.put(currentInvoice.Sales_Order__c, currentInvoice);                                 
        }
        return salesOrderIdToInvoiceMap;
    }

    static List<Task> createTask(List<Transaction__c> transactionObjectList, String salesOrderId, Invoice__c invoiceObject ){
        List<Task> TaskList = new List<Task>();
        for(Transaction__c transactionObject : transactionObjectList)
        {
            transactionObject.Invoice__c = (invoiceObject != null) ? invoiceObject.id : null;
            
            Task taskVar = new Task();
            taskVar.WhatId = salesOrderId;
            if(transactionObject.TransactionId__c == null && transactionObject.Status__c == 'Failed')
            {   
                transactionObject.Invoice__c = null;
                taskVar.Subject='Order Amount('+transactionObject.Amount__c+') Capture-Failed: '+ (invoiceObject != null ? invoiceObject.Name : 'No invoice created');
                taskVar.Status='Open';
                taskVar.ownerid = UserInfo.getUserId();
                TaskList.add(taskVar);
            }
            
        }
        return TaskList;
        
    }

    static Map<String, List<Payment_Method__c>> obtainPaymentMethod(List<String> salesOrderIdList, Map<String, List<Transaction__c>> transactionObjectMap, Map<String, List<Transaction__c>> succeededTransactionObjectMap, Map<Id,Transaction__c> getPaymentMethodIdMap){
        Map<String, List<Payment_Method__c>> result = new Map<String, List<Payment_Method__c>>();
        Map<String, Set<String>> PaymentMethodIdToSaleOrderIdMap = new Map<String, Set<String>>();

        for(String currentOrderId_i : salesOrderIdList ){
            Set<String> transactioIds = new Set<String>();
            if(succeededTransactionObjectMap.containsKey(currentOrderId_i)){
                for(Transaction__c oneTransaction : succeededTransactionObjectMap.get(currentOrderId_i)){
                    if (oneTransaction.TransactionId__c != null){
                        transactioIds.add(oneTransaction.TransactionId__c);
                    }
                    if (oneTransaction.Payment_Type__c == 'Zibby by Affirm'  || oneTransaction.Payment_Type__c == 'Affirm' || oneTransaction.Payment_Type__c == 'Affirm: Buy Now with 3 Easy Payments' || oneTransaction.Payment_Type__c == 'PayPal' || oneTransaction.Payment_Type__c == 'PayPal Express Checkout'){
                        transactioIds.add(string.valueof(oneTransaction.Amount__c));
                    }
                }
            }
            if(transactionObjectMap.containsKey(currentOrderId_i)){
                for(Transaction__c oneTransaction : transactionObjectMap.get(currentOrderId_i)){
                    if (!transactioIds.contains(oneTransaction.TransactionId__c) && !transactioIds.contains(string.valueof(oneTransaction.Amount__c))){
                        getPaymentMethodIdMap.put(oneTransaction.Payment_Method__c, oneTransaction);
                        if(!PaymentMethodIdToSaleOrderIdMap.containsKey(oneTransaction.Payment_Method__c)){
                            PaymentMethodIdToSaleOrderIdMap.put(oneTransaction.Payment_Method__c, new Set<String>());
                        }
                        PaymentMethodIdToSaleOrderIdMap.get(oneTransaction.Payment_Method__c).add(currentOrderId_i);
                    }
                }
            }
        }
        
        for(Payment_Method__c currentPaymentMethod_i : [SELECT Id, Amount__c, name, Customer_Profile_ID__c, Payment_Profile_ID__c, recordtype.name
                                                        FROM Payment_Method__c WHERE Id IN :getPaymentMethodIdMap.keySet()]){
            if(PaymentMethodIdToSaleOrderIdMap.containsKey(currentPaymentMethod_i.Id)){
                for(String currentOrderId_i : PaymentMethodIdToSaleOrderIdMap.get(currentPaymentMethod_i.Id)){
                    if(!result.containsKey(currentOrderId_i)){
                        result.put(currentOrderId_i, new List<Payment_Method__c>());
                    }
                    result.get(currentOrderId_i).add(currentPaymentMethod_i);
                }
            }
        }

        return result;
    }
    private static AuthorizeDotNetResponse capture(string paymentMethodID, Transaction__c trans, string amount, string invoiceNumber, Sales_Order__c salesOrderObject, decimal grandTotal, decimal taxAmount, List<Transaction__c> currentObjectTransactionList)
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
                System.debug('trans: '+trans);
                
                AuthorizeDotNetFunctions authorizeDotNetFunctionsObject = new AuthorizeDotNetFunctions();
                system.debug('paymentMethodVar.Payment_Profile_ID__c: '+paymentMethodVar.Payment_Profile_ID__c);
                system.debug('paymentMethodVar.Customer_Profile_ID__c ' + paymentMethodVar.Customer_Profile_ID__c+' string.valueOf(grandTotal) '+string.valueOf(grandTotal)+' string.valueOf(taxAmount)  '+string.valueOf(taxAmount));
                //response object
                Transaction__c transactionObject = new Transaction__c();
                boolean insertTransaction = false;
                string orderNumber = salesOrderObject.Magento_order_No__c != null && salesOrderObject.Magento_order_No__c != '' ? salesOrderObject.Magento_order_No__c : salesOrderObject.Id;
                //if more than 7 days
                if (trans.Days_opened__c >= 7){
                    responseObject = authorizeDotNetFunctionsObject.createCustomerAuthAndCaptureTransaction(paymentMethodVar.Customer_Profile_ID__c, paymentMethodVar.Payment_Profile_ID__c, string.valueOf(grandTotal), string.valueOf(taxAmount), orderNumber, trans.createddate, salesOrderObject.Authdotnetoldaccount__c);
                    if (responseObject.transactionId != null && (responseObject.error == null || responseObject.error == '')){
                        captureType = 'AUTH_W_CAPTURE';
                        wasVoided = true;
                        authorizeDotNetFunctionsObject.voidTransaction(paymentMethodVar.Customer_Profile_ID__c, paymentMethodVar.Payment_Profile_ID__c, trans.TransactionId__c, trans.createddate, salesOrderObject.Authdotnetoldaccount__c);
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
                    currentObjectTransactionList.add(transactionObject);
                }
                System.debug('responseObject: '+responseObject);
            }
            else 
            {
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'You cannot create Invoice, please make sure that payment method is added in Salesorder.'));  
            }    
        }
        Catch(Exception e)
        {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.error,'Exception '+e.getMessage()+' '+e.getLineNumber()));  
            system.debug('Exception'+e.getMessage()+' '+e.getLineNumber() );
        }
        return responseObject;
    }

    private static payPalResponse capturePayPal(Sales_Order__c salesOrderObject, string transactionId, decimal grandTotal){  
        
        PaypalConnect PaypalConnectOBJ = new PaypalConnect(salesOrderObject.Customer_Name__r.Web_Site__c);
        payPalResponse payPalResponseOBJ = new payPalResponse();
        
        try
        {
            
            if(transactionId != null) 
            {
                payPalResponseOBJ = PaypalConnectOBJ.capturePayment(string.valueof(grandTotal), transactionId);
            }
        }
        Catch(Exception e)
        {
            system.debug('Exception'+e.getMessage()+' '+e.getLineNumber() );
        }
        return payPalResponseOBJ;
    
    } 
    //createTransaction(transactionType, salesOrderId, status, paymentMethod, amount, response, avsResponse, transactioId, error);
    static Transaction__c createTransaction (String transactionType, String salesOrderId, String status, String paymentMethod, Decimal amount, String response, String avsResponse, String transactioId, String error){
        Transaction__c transactionObject = new Transaction__c();
        transactionObject.Transaction_Type__c = transactionType;
        transactionObject.Sales_Order__c = salesOrderId;
        transactionObject.Status__c = status;
        transactionObject.Payment_Method__c = paymentMethod;
        transactionObject.Amount__c = amount;
        transactionObject.Transaction_Response__c = response;
        transactionObject.TransactionId__c = transactioId;
        transactionObject.Error__c = error;
        transactionObject.Trans_AVS_Response__c = avsResponse;
        return transactionObject;
    }

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