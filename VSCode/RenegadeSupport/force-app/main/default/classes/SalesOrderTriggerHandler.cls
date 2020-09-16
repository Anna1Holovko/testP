public without sharing class SalesOrderTriggerHandler {
    static Boolean mapUpdateInTrigger = false;
	public static Boolean emailSynchronized = false;
    
    public static void afterUpdate (map<id, Sales_Order__c> soOldMap, list<Sales_Order__c> soNewList, map<id, Sales_Order__c> newSoMap){
        checkAccountRecordType(soNewList, soOldMap);
        Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
        map<id, Sales_Order__c> soToUpdate = new map<id, Sales_Order__c>();
        map<id, string> zipCodeBySO = new map<id, string>();

        Set<Id> soIdForVoidGuardianSet = new  Set<Id>();
        Set<Id> soIdForCreateGuardianSet = new  Set<Id>();
        Set<Id> soIdForCheckFraudSet = new  Set<Id>();
        Set<Id> soIdFoSiftScienceSet = new  Set<Id>();
        for (Sales_Order__c so : soNewList){
            if (so.Do_not_charge_tax__c != soOldMap.get(so.id).Do_not_charge_tax__c || so.Shipping_ZipCode__c != soOldMap.get(so.id).Shipping_ZipCode__c){
                zipCodeBySO.put(so.id, so.Shipping_ZipCode__c);
            }
        }
        if (zipCodeBySO.values().size() > 0){
            claculateTax(zipCodeBySO, newSoMap);
        }
        for (Sales_Order__c so : soNewList){
            if (so.Send_Guardian__c && so.Send_Guardian__c != soOldMap.get(so.id).Send_Guardian__c && !test.isrunningtest()){///if (((so.Order_Status__c == 'Received by Warehouse' && soOldMap.get(so.id).Order_Status__c != 'Received by Warehouse') || so.Send_Guardian__c != soOldMap.get(so.id).Send_Guardian__c) && so.Protection_Plan_included__c && (so.Guardian_Number__c == null || so.Guardian_Number__c == '')){
                Sales_Order__c salesOrderToUpdate = new Sales_Order__c(id = so.id); 
                if(System.isBatch() || System.isFuture() || System.isScheduled() || Limits.getFutureCalls() >= (Limits.getLimitFutureCalls() - 5)){
                	salesOrderToUpdate.Send_to_Guardian_in_15_minutes__c = true;
                    salesOrderToUpdate.Send_to_Guardian_time_was_checked__c = system.now();
                }
                else{
                    soIdForCreateGuardianSet.add(so.id);
                }
                salesOrderToUpdate.Send_Guardian__c = false;
                soToUpdate.put(salesOrderToUpdate.id,salesOrderToUpdate);
            } 
            if (so.Recheck_fraud__c != soOldMap.get(so.id).Recheck_fraud__c){
                soIdForCheckFraudSet.add(so.id);
            }
            if( so.X30_minute_Sift_Score__c && soOldMap.containsKey(so.id) && !soOldMap.get(so.id).X30_minute_Sift_Score__c ){
                soIdFoSiftScienceSet.add(so.Id);
            }
            if (so.Void_Guardian__c != soOldMap.get(so.id).Void_Guardian__c){
                soIdForVoidGuardianSet.add(so.id);
            }
            if (so.Send_to_a_delivery_company__c){
                sendToDeliveryCompany(so);
            }
            if (so.TaxAmount__c != null && so.TaxAmount__c != 0 && !so.TaxJar_updated_successfully__c && ((so.Order_Status__c == 'Completed' && soOldMap.get(so.id).Order_Status__c != 'Completed') || (so.Order_Status__c == 'Completed' && so.Resend_to_TaxJar__c))){
                CommitTaxJarTransaction(so.id);
            }
            if (so.Magento_Order_ID__c != null)
            {
                if (!so.IsSoModified__c && so.Order_Status__c == 'Completed'){
                    if ((so.Ready_for_integration__c || (so.Order_Status__c != soOldMap.get(so.id).Order_Status__c && setting.API_User_ID__c != null && string.valueof(so.CreatedById).contains(setting.API_User_ID__c)))){
                        Sales_Order__c salesOrderToUpdate;
                        if (soToUpdate.containskey(so.id)){
                        	salesOrderToUpdate = soToUpdate.get(so.id);
                        }
                        else{
	                        salesOrderToUpdate = new Sales_Order__c(id = so.id);
	                        soToUpdate.put(so.id, salesOrderToUpdate);
                        }
                        if(System.isBatch() || System.isFuture() || System.isScheduled()){
                            salesOrderToUpdate.Ready_for_integration__c = false;
                            salesOrderToUpdate.Resend__c = true;
                            //update salesOrderToUpdate;
                        }else{
                            createUpdateLog(so);
                            if (so.Ready_for_integration__c){
                                salesOrderToUpdate.Ready_for_integration__c = false;
                                //update salesOrderToUpdate;
                            }
                        }
                        
                        
                    }
                }
            }
        }
        if (soToUpdate.values().size() > 0){
        	update soToUpdate.values();
        }
        if (!mapUpdateInTrigger){
        	mapLocationSetAfterUpdate(soOldMap, newSoMap);
        }
        markCustomerETACallOnRelatedPOs(soNewList, soOldMap);
        if(soIdForCreateGuardianSet.size() > 0){
            createGuardianPlan(soIdForCreateGuardianSet); 
        }
        if(soIdForVoidGuardianSet.size() > 0){
            voidGuardianPlan(soIdForVoidGuardianSet);
        }
        if(soIdForCheckFraudSet.size() > 0){
            checkFraud(soIdForCheckFraudSet);
        }
        if(soIdFoSiftScienceSet.size() > 0){
            updateSoSiftScienceAfter30Min(soIdFoSiftScienceSet); 
        }
    }

    private static void synchronizeDeliveryEmail(List<Sales_Order__c> orderList, Map<Id, Sales_Order__c> oldOrderMap) {
        if (emailSynchronized) {
            return;
        }
        Set<Id> accountIdSet = new Set<Id>();
        for (Sales_Order__c order_i : orderList) {
            if(order_i.Delivery_Company__c != null && (oldOrderMap==null || oldOrderMap.get(order_i.Id).Delivery_Company__c != order_i.Delivery_Company__c)) {
                accountIdSet.add(order_i.Delivery_Company__c);
            }
        }

        if(accountIdSet.size() == 0) {
            return;
        }
        List<Sales_Order__c> orderListToUpdate = new List<Sales_Order__c>();
        
        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, Email__c FROM Account WHERE Id IN :accountIdSet]);
        for (Sales_Order__c order_i : orderList) {
            if (accountMap.containsKey(order_i.Delivery_Company__c)) {
                order_i.Delivery_company_Email__c = accountMap.get(order_i.Delivery_Company__c).Email__c;
            }
        }
    }

    static void markCustomerETACallOnRelatedPOs(List<Sales_Order__c> salesOrderList, Map<Id, Sales_Order__c> oldMap){
        Set<Id> changedSOIdSet = new Set<Id>();
        for(Sales_Order__c order_i : salesOrderList){
            if(order_i.Mark_Customer_ETA_call_on_related_POs__c != oldMap.get(order_i.Id).Mark_Customer_ETA_call_on_related_POs__c){
                changedSOIdSet.add(order_i.Id);
            }
        }
        if(changedSOIdSet.size() > 0){
            List<Purchase_Order__c> relatedPOList = [SELECT Id FROM Purchase_Order__c WHERE Sales_Order__c IN :changedSOIdSet];
            for(Purchase_Order__c po_i : relatedPOList){
                po_i.ETA_Is_Given__c = true;
            }
            if(relatedPOList.size() > 0){
                update relatedPOList;
            }
        }
    }
    
    static void checkAccountRecordType (List<Sales_Order__c> salesOrderList, Map<Id, Sales_Order__c> oldMap ){
        Set<String> accountIdList = new Set<String>();
        List<Account> accountToUpdateRecordTypeList = new List<Account>();
        for(Sales_Order__c order_i : salesOrderList){
            if(order_i.Customer_Name__c != null && (oldMap == null || order_i.Customer_Name__c != oldMap.get(order_i.Id).Customer_Name__c)){
                accountIdList.add(order_i.Customer_Name__c);
            }
        }
        if(accountIdList.isEmpty()){
            return;
        }
        List<RecordType> customerRecordType = [SELECT Id FROM RecordType WHERE sObjectType='Account' AND Name = 'Customer' ];
        if(customerRecordType.isEmpty()){
            return;
        }
        for(Account account_i : [SELECT Id FROM Account WHERE Id in :accountIdList AND RecordType.Name = 'Sales Accounts']){
            account_i.RecordTypeId = customerRecordType.get(0).Id;
            accountToUpdateRecordTypeList.add(account_i);
        }

        if(!accountToUpdateRecordTypeList.isEmpty()){
            update accountToUpdateRecordTypeList;
        }
    }

    private static void createUpdateLog(Sales_Order__c so){
        Log__c log = new Log__c();
        list<Log__c> existedlog = [select id from Log__c where Object_ID__c = :so.id and Status__c = 'Failed'];
        if (existedlog.size() > 0){
            log.id = existedlog[0].id;
        }
        log.Owner__c = 'Salesforce';
        log.Object_ID__c = so.id;
        log.Process__c = 'Order updated';
        log.Status__c = 'Sent';
        log.Data__c = '{"data": {"magentoId":"' + so.Magento_Order_ID__c + '","status":"' + so.Order_Status__c + '"}}';
        upsert log;
    }
    
    public static void beforeInsert (list<Sales_Order__c> soNewList){
        //checkForFraud(soNewList);
        Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
        set<string> zipCodes = new set<string>();
        for (Sales_Order__c so : soNewList){
            if(so.Billing_ZipCode__c != Null && so.Billing_ZipCode__c.length() > 5)
            {
                so.Billing_ZipCode__c = so.Billing_ZipCode__c.substring(0, 5); 
            }
            if(so.Shipping_ZipCode__c != Null && so.Shipping_ZipCode__c.length() > 5)
            {
                so.Shipping_ZipCode__c = so.Shipping_ZipCode__c.substring(0, 5); 
            }
            if (setting.API_User_ID__c == null || !UserInfo.getUserId().contains(setting.API_User_ID__c)){
                zipCodes.add(so.Shipping_ZipCode__c);
            }
        }
        if (zipCodes.size() > 0){
            updateTax(zipCodes, soNewList);
        }
        getDeliverycompanyHelper.salesorderDeliverycompany(soNewList, null);
        fillSuggestedTrackingCompany(soNewList, null);
    }

    public static void fillShippingStateInitials(List<Sales_Order__c> soNewList, Map<Id, Sales_Order__c> soOldMap) {
        for(Sales_Order__c so_i: soNewList) {
            if(soOldMap == null || (so_i.Shipping_State__c == null || so_i.Shipping_State__c != ((Sales_Order__c)soOldMap.get(so_i.Id)).Shipping_State__c )){
                so_i.Shipping_State_Initials__c  = Utilities.getStateinitial(so_i.Shipping_State__c);
            }
        }
    }
    
    public static void updateAccountField(List<Sales_Order__c> soList, Map<Id, Sales_Order__c> oldOrderMap) {
        Set<Id> accIdSet = new Set<Id>();
        Map<String, Opened_SO_statuses__c> openedSOstatusesMap = Opened_SO_statuses__c.getAll();
        
        for(Sales_Order__c so_i: soList) {
            Sales_Order__c oldOrder = oldOrderMap != null ? oldOrderMap.get(so_i.Id) : null;
            if((openedSOstatusesMap.containsKey(so_i.Order_Status__c) && oldOrder == null ) || 
                (oldOrder != null && oldOrder.Order_Status__c != so_i.Order_Status__c && 
                    ((openedSOstatusesMap.containsKey(oldOrder.Order_Status__c) && !openedSOstatusesMap.containsKey(so_i.Order_Status__c)) 
                    || (!openedSOstatusesMap.containsKey(oldOrder.Order_Status__c) && openedSOstatusesMap.containsKey(so_i.Order_Status__c)))) ) {
                accIdSet.add(so_i.Customer_Name__c); 
            }
        }
        if(!accIdSet.isEmpty()) {
            updateNumberOpenedSO(accIdSet, openedSOstatusesMap.keySet());
        }
    }

    public static void updateAccountFieldOnUpdateSO(List<Sales_Order__c> soList, Map<Id, Sales_Order__c> soOldMap) {
        Set<Id> accIdSet = new Set<Id>();
        Map<String, Opened_SO_statuses__c> openedSOstatusesMap = Opened_SO_statuses__c.getAll();
        
        for(Sales_Order__c so_i: soList) {
            if(so_i.Order_Status__c != soOldMap.get(so_i.Id).Order_Status__c 
               && (openedSOstatusesMap.containsKey(so_i.Order_Status__c) || openedSOstatusesMap.containsKey(soOldMap.get(so_i.Id).Order_Status__c ))) {
                   accIdSet.add(so_i.Customer_Name__c);
               }
            if(so_i.Customer_Name__c  != soOldMap.get(so_i.Id).Customer_Name__c 
               && (openedSOstatusesMap.containsKey(so_i.Order_Status__c) || openedSOstatusesMap.containsKey(soOldMap.get(so_i.Id).Order_Status__c ))) {
                   accIdSet.add(so_i.Customer_Name__c);
                   accIdSet.add(soOldMap.get(so_i.Id).Customer_Name__c);
               }
        }
        if(!accIdSet.isEmpty()) {
            updateNumberOpenedSO(accIdSet, openedSOstatusesMap.keySet());
        }
    }
    
    private static void updateNumberOpenedSO(Set<Id> accIdSet, Set<String> openedSOstatusesSet){
        AggregateResult[] groupedResults = [
            SELECT COUNT(Id)numbSO, Customer_Name__c
            FROM Sales_Order__c
            WHERE Customer_Name__c IN: accIdSet AND Customer_Name__c <> null AND Order_Status__c IN: openedSOstatusesSet
            GROUP BY Customer_Name__c
        ];
        Map<Id, Integer> accIdToNumbOpenSoMap = new Map<Id, Integer>();
        List<Account> accToUpdateList = new List<Account>();
        for (AggregateResult ar : groupedResults) {
            Id accId = (Id)ar.get('Customer_Name__c');
            Integer numbOpenSO = (Integer)ar.get('numbSO');
            accIdToNumbOpenSoMap.put(accId, numbOpenSO);
        }
        for(Id accId_i: accIdSet) {
            Integer numbOpenSO = (accIdToNumbOpenSoMap.containsKey(accId_i)) ? accIdToNumbOpenSoMap.get(accId_i) : 0;
            Account acc = new Account (Id = accId_i, 
                                       Number_of_Opened_Sales_Orders__c = numbOpenSO);
            accToUpdateList.add(acc);
        }
        if(!accToUpdateList.isEmpty()) {
            Database.update(accToUpdateList, false);
        }
    }
    
    @future(callout=true)
    public static void geocode(Map<Id, String> addressMap){
    	geocodeNotFuture(addressMap);
    }
    private static integer retried = 1;
    public static void geocodeNotFuture(Map<Id, String> addressMap){
        Map<Id, Sales_Order__c> salesOrders = new Map<Id, Sales_Order__c>(
            [
                SELECT Id, Billing_Location__Latitude__s, Billing_Location__Longitude__s, Shipping_Location__Latitude__s, Shipping_Location__Longitude__s,
                Billing_City__c, Billing_Street__c, Billing_State__c, Billing_ZipCode__c,
                Shipping_City__c, Shipping_Street__c, Shipping_State__c, Shipping_ZipCode__c,
                Delivery_Company__c, Delivery_Company__r.Name, Delivery_Company__r.Location__Latitude__s, Delivery_Company__r.Location__Longitude__s
                FROM Sales_Order__c
                WHERE Id IN : addressMap.keySet()
                FOR UPDATE
            ]);
        
        if (salesOrders.size() == 0){
            return;
        }

        for (Id id_i : addressMap.keySet()){
            try{
                List<String> addressList = addressMap.get(id_i).split('==');
                for(String currentAddress_i : addressList){
                    GResponse response = getLocation(EncodingUtil.urlEncode(currentAddress_i, 'UTF-8'));
                    if (response != null){
                        LatLng ll = response.results[0].geometry.location;
                        Sales_Order__c salesOrder_i = salesOrders.get(id_i);
                        Map<String, String> addresses = generateAddresses(salesOrder_i);
                        for (String address_i : addresses.keySet()) {
                            if (currentAddress_i == addresses.get(address_i)){
                                System.debug(salesOrder_i.Delivery_Company__c);
                                if (address_i == 'Shipping'){
                                	salesOrder_i.Location__Latitude__s = ll.lat;
                                	salesOrder_i.Location__Longitude__s = ll.lng;
                                }
                                if(address_i == 'Shipping' && String.isNotBlank(salesOrder_i.Delivery_Company__c)){
                                    salesOrder_i.Delivery_Companies_Distance__c = getNearby(string.valueof(ll.lat), string.valueof(ll.lng),string.valueof(id_i), string.valueof(salesOrder_i.Delivery_Company__c), string.valueof(salesOrder_i.Delivery_Company__r.Location__Latitude__s), string.valueof(salesOrder_i.Delivery_Company__r.Location__Longitude__s), string.valueof(salesOrder_i.Delivery_Company__r.Name));
                                }
                                salesOrder_i.put(address_i + '_Location__Latitude__s', ll.lat);
                                salesOrder_i.put(address_i + '_Location__Longitude__s', ll.lng);
                            }
                        }
                    }
                }
            }
            catch(Exception e){
                System.debug('ex: ' + e + e.getStackTraceString());
            }
        }
        try{        
	        mapUpdateInTrigger = true;
	        update salesOrders.values();
	        mapUpdateInTrigger = false;
        }
        catch (exception e){
        	if (retried >= 4) return;
        	retried ++;
        	geocodeNotFuture(addressMap);
        }
    }
    
    public static GResponse getLocation(String address){
        Google_API__c googleAPI = Google_API__c.getAll().values();
        String googleAPIUrl = googleAPI.URL__c;
        String googleAPIKey = googleAPI.Key__c;
        if (googleAPIURL == null || googleAPIKey == null){
            return null;
        }
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setTimeout(10000);
        req.setEndpoint(googleAPIUrl + address + '&key=' + googleAPIKey );
        HttpResponse res = h.send(req);
        GResponse gr = (GResponse) JSON.deserialize(res.getBody(), GResponse.class);
        System.debug(gr);
        if (gr.status == 'OK'){
            return gr;
        }

        return null;
    }
    
    public static void mapLocationSetAfterUpdate(Map<Id, Sales_Order__c> oldMap, Map<Id, Sales_Order__c> newMap){
        Map<Id, String> addressMap = new Map<Id, String>();
        for (Id salesOrder_i : newMap.keySet()){
            Map<String, String> oldAddresses = generateAddresses(oldMap.get(salesOrder_i));
            Map<String, String> newAddresses = generateAddresses(newMap.get(salesOrder_i));
            for (String address_i : newAddresses.keySet()){
                if (oldAddresses.get(address_i) != newAddresses.get(address_i) || 
                    newMap.get(salesOrder_i).UpdateAddress__c != oldMap.get(salesOrder_i).UpdateAddress__c ||
                    newMap.get(salesOrder_i).Delivery_Company__c != oldMap.get(salesOrder_i).Delivery_Company__c){
                    if(!addressMap.containsKey(salesOrder_i)){
                        addressMap.put(salesOrder_i, newAddresses.get(address_i));
                    }
                    else{
                        addressMap.put(salesOrder_i, addressMap.get(salesOrder_i) + '==' + newAddresses.get(address_i));
                    }
                }
            }
        }

        if (addressMap.size() > 0 && !test.isrunningtest()){
        	geocode(addressMap);
        }
    }
    
    public static Map<String, String> generateAddresses(Sales_Order__c salesOrder){
        String[] prefixes = new String[] { 'Billing', 'Shipping' };
        String[] fields = new String[] { '_Street__c', '_City__c', '_State__c', '_ZipCode__c'};
            
            Map<String, String> addresses = new Map<String, String>();
        for (String prefix_i : prefixes) {
            for (String field_i : fields) {
                if (salesOrder.get(prefix_i + field_i) != null){
                    if (!addresses.containsKey(prefix_i))
                        addresses.put(prefix_i, string.valueOf(salesOrder.get(prefix_i + field_i)) + ',');
                    else
                        addresses.put(prefix_i, addresses.get(prefix_i) + string.valueOf(salesOrder.get(prefix_i + field_i)) + (fields.indexOf(field_i) < fields.size() - 1 ? ',' : ''));
                }
            }
        }
        return addresses;
    }
    
    public static void mapLocationSetAfterInsert(Map<Id, Sales_Order__c> newMap){
        Map<Id, String> addressMap = new Map<Id, String>();
        for (Sales_Order__c salesOrder_i : newMap.values()){
            List<String> addresses = generateAddresses(salesOrder_i).values();
            for (String address_i : addresses){
                if(!addressMap.containsKey(salesOrder_i.Id)){
                    addressMap.put(salesOrder_i.Id, address_i);
                }
                else{
                    addressMap.put(salesOrder_i.Id, addressMap.get(salesOrder_i.Id) + '==' + address_i);
                }
            }
        }
        try {
	        if (addressMap.size() > 0){
	            geocode(addressMap);
	        }
        }
        catch (exception e){
        	system.debug (e.getmessage() + e.getlinenumber());
        }
    }
        
    public static void beforeUpdate (Map<Id, Sales_Order__c> soNewMap, map<id, Sales_Order__c> soOldMap){
        list<Sales_Order__c> soNewList = soNewMap.values();
        synchronizeDeliveryEmail(soNewList, soOldMap);
        //checkForFraud(soNewList);
        list<string> soIdsToUpdatePos = new list<string>();
        list<Sales_Order__c> soToUpdateTax = new list<Sales_Order__c>();
        set<string> zipCodes = new set<string>();
        for (Sales_Order__c so : soNewList){
            if(so.Billing_ZipCode__c != Null && so.Billing_ZipCode__c != soOldMap.get(so.id).Billing_ZipCode__c && so.Billing_ZipCode__c.length() > 5)
            {
                so.Billing_ZipCode__c = so.Billing_ZipCode__c.substring(0, 5); 
            }
            if(so.Shipping_ZipCode__c != Null && so.Shipping_ZipCode__c != soOldMap.get(so.id).Shipping_ZipCode__c && so.Shipping_ZipCode__c.length() > 5)
            {
                so.Shipping_ZipCode__c = so.Shipping_ZipCode__c.substring(0, 5); 
            }
            if(so.Do_not_charge_tax__c != soOldMap.get(so.id).Do_not_charge_tax__c || so.Shipping_ZipCode__c != soOldMap.get(so.id).Shipping_ZipCode__c)
            {
                soToUpdateTax.add(so);
                zipCodes.add(so.Shipping_ZipCode__c);
            }
            if (so.Send_ETA_notification_to_customer__c){
                so.Send_ETA_notification_to_customer__c = false;
                soIdsToUpdatePos.add(so.id);
            }
        }
        if (soIdsToUpdatePos.size() > 0){
            updatePoSendEtaToCustomer(soIdsToUpdatePos);
        }
        if (soToUpdateTax.size() > 0){
            updateTax(zipCodes, soToUpdateTax);
        }
        getDeliverycompanyHelper.salesorderDeliverycompany(soNewList, soOldMap);
        fillSuggestedTrackingCompany(soNewList, soOldMap);
        checkExcludeFromBulk(soNewMap, soOldMap);
    }
    
    public static void afterInsert (list<Sales_Order__c> soNewList, map<id, Sales_Order__c> newSoMap){
        mapLocationSetAfterInsert(newSoMap);
        checkAccountRecordType(soNewList, null);

        Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
        map<id, string> zipCodeBySO = new map<id, string>();
        map<id, Sales_Order__c> soToUpdate = new map<id, Sales_Order__c>();
        Set<Id> soIdForCheckFraudSet = new  Set<Id>();
        for (Sales_Order__c so : soNewList){
            if (so.createddate.date() == system.today()){
                soIdForCheckFraudSet.add(so.id);
            }
            if (so.Shipping_ZipCode__c != null && (setting.API_User_ID__c == null || !UserInfo.getUserId().contains(setting.API_User_ID__c))){
                
                zipCodeBySO.put(so.id, so.Shipping_ZipCode__c);
            }
        }
        if (zipCodeBySO.values().size() > 0){
            claculateTax(zipCodeBySO, newSoMap);
        }
        if (soToUpdate.values().size() > 0){
            update soToUpdate.values();
        }
        if(soIdForCheckFraudSet.size() > 0){
            checkFraud(soIdForCheckFraudSet);
        }
    }
    
    private static void updateTax(set<string> zipCodesList, list<Sales_Order__c> soNewList){
        map<string, Shipping_Zip_Codes__c> taxByZipcode = new map<string, Shipping_Zip_Codes__c>();
        list<Shipping_Zip_Codes__c> zipCodes = [select TaxJar_Sales_Tax__c, Zip_Code__c from Shipping_Zip_Codes__c where Zip_Code__c in :zipCodesList];
        for (Shipping_Zip_Codes__c szc : zipCodes){
            taxByZipcode.put(szc.Zip_Code__c, szc);
        }
        for(Sales_Order__c so : soNewList){
            if (taxByZipcode.containskey(so.Shipping_ZipCode__c) && taxByZipcode.get(so.Shipping_ZipCode__c).TaxJar_Sales_Tax__c != null && !so.Do_not_charge_tax__c){
                so.Tax_Percentage__c = taxByZipcode.get(so.Shipping_ZipCode__c).TaxJar_Sales_Tax__c;
            }
            else{
                so.Tax_Percentage__c = 0;
            }
        }
    }
    
    private static void claculateTax(map<id, string> zipCodeBySO, map<id, Sales_Order__c> newSoMap){
        map<string, Shipping_Zip_Codes__c> taxByZipcode = new map<string, Shipping_Zip_Codes__c>();
        list<Shipping_Zip_Codes__c> zipCodes = [select TaxJar_Sales_Tax__c, Zip_Code__c from Shipping_Zip_Codes__c where Zip_Code__c in :zipCodeBySO.values()];
        for (Shipping_Zip_Codes__c szc : zipCodes){
            taxByZipcode.put(szc.Zip_Code__c, szc);
        }
        list<SO_Line_Items__c> soliToUpdate = [select Tax_Percent__c, Sales_Order__r.Shipping_ZipCode__c, Sales_Order__r.Do_not_charge_tax__c, Sub_Total__c, Discount_Amount__c, Bundle_Item__c, Bundle_Item_Relative_Discount_Amount__c from SO_Line_Items__c where Sales_Order__c in :zipCodeBySO.keyset()];
        system.debug('soliToUpdate = ' + soliToUpdate);
        system.debug('taxByZipcode = ' + taxByZipcode);
        for(SO_Line_Items__c sli : soliToUpdate){
            if (taxByZipcode.containskey(newSoMap.get(sli.Sales_Order__c).Shipping_ZipCode__c) && taxByZipcode.get(newSoMap.get(sli.Sales_Order__c).Shipping_ZipCode__c).TaxJar_Sales_Tax__c != null && !newSoMap.get(sli.Sales_Order__c).Do_not_charge_tax__c){
                sli.Tax_Percent__c = taxByZipcode.get(sli.Sales_Order__r.Shipping_ZipCode__c).TaxJar_Sales_Tax__c;
                if (sli.Sub_Total__c != null){
                	if (sli.Bundle_Item__c != null && sli.Bundle_Item_Relative_Discount_Amount__c != null){
                        sli.Tax_Amount__c = (sli.Sub_Total__c - sli.Bundle_Item_Relative_Discount_Amount__c) * sli.Tax_Percent__c/100;
                	}
                    else if (sli.Discount_Amount__c != null){
                        sli.Tax_Amount__c = (sli.Sub_Total__c - sli.Discount_Amount__c) * sli.Tax_Percent__c/100;
                    }
                    else {
                        sli.Tax_Amount__c = (sli.Sub_Total__c) * sli.Tax_Percent__c/100;
                    }
                }
            }
            else{
                sli.Tax_Percent__c = 0;
                sli.Tax_Amount__c = 0;
            }
        }
        system.debug('soliToUpdate = ' + soliToUpdate);
        if (soliToUpdate.size() > 0){
            update soliToUpdate;
        }
    }
    
    private static void updatePoSendEtaToCustomer(list<string> soIdsToUpdatePos){
        list<Purchase_Order__c> pos = [select id, Manual_override_Send_ETA_to_customer__c, Required_Confirmation__c from Purchase_Order__c where Sales_Order__c in :soIdsToUpdatePos];
        if (pos.size() == 0 )return;
        for (Purchase_Order__c po : pos){
            po.Manual_override_Send_ETA_to_customer__c = true;
            po.Required_Confirmation__c = true;
        }
        update pos;
    }
    
    public static void sendToDeliveryCompany (Sales_Order__c so){
        Sales_Order__c nso = new Sales_Order__c (id = so.id, Send_to_a_delivery_company__c = false);
        update nso;
        list<Shipment__c> shipmentToUpdate = [select id, Send_to_a_delivery_company__c, Related_Sales_Order__c from Shipment__c where Related_Sales_Order__c = :so.id];
        if (shipmentToUpdate.size() > 0){
            //shipmentToUpdate[0].Send_to_a_delivery_company__c = true;
            //update shipmentToUpdate[0];
            list<string> updateshipmentToSendId = new list<string>();
            updateshipmentToSendId.add(shipmentToUpdate[0].id);
            set<id> relatedSO = new set<id>();
            relatedSO.add(so.id);
            ShipmentTriggerHandler.sendToDelivery (updateshipmentToSendId,relatedSO, so.Delivery_company_status__c, true);
        }
    }

    static void fillSuggestedTrackingCompany(List<Sales_Order__c> soNewList,  Map<Id, Sales_Order__c> newSoMap){
        Set<Id> deliveryIdSet = new Set<Id>();
        Set<Id> manufactureIdSet = new Set<Id>();
        for(Sales_Order__c so_i : soNewList){
            if(so_i.Manufacturer__c != null && so_i.Delivery_Company__c != null && (newSoMap == null || so_i.Delivery_Company__c != newSoMap.get(so_i.Id).Delivery_Company__c || so_i.Manufacturer__c != newSoMap.get(so_i.Id).Manufacturer__c)){
                deliveryIdSet.add(so_i.Delivery_Company__c);
                manufactureIdSet.add(so_i.Manufacturer__c);
            }
        }
        Map<String, String> ruleKeyToTrackingNameMap = new Map<String, String>();
        Set<String> searchStringSet = new Set<String>();
        if(manufactureIdSet.size() > 0){
            for(Trucking_Rule__c rule_i : [SELECT Id, Truking_Selection_Note__c, Selected_Delivery__c, Selected_Manufacturer__c FROM Trucking_Rule__c WHERE Selected_Delivery__c IN :deliveryIdSet AND Selected_Manufacturer__c IN :manufactureIdSet AND Truking_Selection_Note__c != null]){
                String keyMap = rule_i.Selected_Delivery__c + ' _ ' + rule_i.Selected_Manufacturer__c;
                String truckingNote = rule_i.Truking_Selection_Note__c;
                if(truckingNote.contains(',')){
                    List<String> splittedList = truckingNote.split(',');
                    truckingNote = splittedList[0].trim();
                }
                ruleKeyToTrackingNameMap.put(keyMap, truckingNote);
                searchStringSet.add(' (Name LIKE \'%' + truckingNote + '%\' ) ');
            }
            if(ruleKeyToTrackingNameMap.size() > 0){
                String query = 'SELECT Id, Name FROM Account WHERE RecordType.Name = \'Trucking Company\' AND (' + String.join(new List<String>(searchStringSet), ' OR ')+')';
                List <Account> trackingCompanyList = Database.query(query);
                Map<String, Id> accountNameToIdMap = new Map<String, Id>();
                for(Account account_i : trackingCompanyList){
                    accountNameToIdMap.put(account_i.Name, account_i.Id);
                }
                Map<String, Id> ruleKeyToTrackingCompanyIdMap = new Map<String, Id>();
                for(String keyMap_i : ruleKeyToTrackingNameMap.keySet()){
                    String truckingNote = ruleKeyToTrackingNameMap.get(keyMap_i);
                    Id trackingCompanyId = null;
                    for(String accountName_i : accountNameToIdMap.keySet()){
                        if(accountName_i.containsIgnoreCase(truckingNote)){
                            trackingCompanyId = accountNameToIdMap.get(accountName_i);
                            break;
                        }
                    }
                    if(trackingCompanyId != null){
                        ruleKeyToTrackingCompanyIdMap.put(keyMap_i, trackingCompanyId);
                    }
                }    
                for(Sales_Order__c so_i : soNewList){
                    if(so_i.Manufacturer__c != null){
                        String keyMap = so_i.Delivery_Company__c + ' _ ' + so_i.Manufacturer__c;
                        if(ruleKeyToTrackingCompanyIdMap.containsKey(keyMap)){
                            so_i.Suggested_Trucking_Company__c = ruleKeyToTrackingCompanyIdMap.get(keyMap);
                        }
                    }
                }
            }
        }
    }
    

    public static void CommitTaxJarTransaction (string soId){
        TaxJarManager.submitTaxJarTransaction(soId);
    }
    
    @future (callout=true)
    public static void voidGuardianPlan (Set<Id> soIdSet){
        List<Sales_Order__c> soList = [SELECT Guardian_s_void_link__c FROM Sales_Order__c WHERE Id IN :soIdSet];
        for(Sales_Order__c so_i : soList){
            if(String.isEmpty(so_i.Guardian_s_void_link__c)){
                so_i.Error_message_voiding_protection_pl__c = 'Void link is empty';
            }else{
                try{
                    GuardianManager.Response res = GuardianManager.VoidPlan(so_i.Guardian_s_void_link__c);
                    if(JSON.serialize(res.results[0]).contains('FAILURE')){//if (res.results[0].Info != 'FAILURE-VOID'){
                        so_i.Is_Protection_Plan_Registered__c = false;
                        so_i.Guardian_voided_time__c = system.now();
                    }
                    //In case of an error
                    else {
                        so_i.Error_message_voiding_protection_pl__c = res.results[1].Info;
                    }
                }catch (exception e){
                    so_i.Error_message_voiding_protection_pl__c = e.getMessage();
                }
            }
        }
        update soList;
    }
    
    @future (callout=true)
    public static void createGuardianPlan (Set<Id> soIdSet){

        List<Sales_Order__c> soList = [ SELECT  Id, Name, Order_Date__c, Protection_Plan_Cost__c, TaxAmount__c, Shipping_Handle__c, Grand_Total__c, 
                                                Billing_ZipCode__c, Billing_Phone__c, Bill_To__c, Billing_State__c, Shipping_ZipCode__c, Ship_To__c, 
                                                Shipping_Phone__c, Billing_Street__c, Billing_City__c, Magento_order_No__c, Shipping_City__c, Shipping_State__c, 
                                                Shipping_Street__c, Email__c, Plan_code__c, (select Item__c, Products__r.recordtype.name, Products__r.name FROM SO_Line_Items__r) 
                                        FROM Sales_Order__c WHERE Id IN :soIdSet ];
        List<SO_Line_Items__c> soLineToUpdateList = new List<SO_Line_Items__c>();                               
        for(Sales_Order__c so_i : soList){
            String body = GuardianManager.generateBody(so_i);
            GuardianManager.Response response = GuardianManager.sendRequest(so_i, body);
            system.debug('response.results[0] = ' + response.results[0]);
            system.debug('response.results[0]..Info = ' + response.results[0].Info);
            system.debug('response.results[0].Info != FAILURE-REGISTRATION = ' + response.results[0].Info == 'FAILURE-REGISTRATION');
            if (response.results[0].Info != 'FAILURE-REGISTRATION'){
                for (GuardianManager.Results res : response.results){
                    if (res.Info.contains('Plan')){
                        so_i.Guardian_Number__c = res.Info.split(':')[2].split(',')[0];
                        so_i.Is_Protection_Plan_Registered__c = true;
                        so_i.Error_messag_registering_protection_plan__c = '';
                        break;
                    }
                }
                for (GuardianManager.Links link : response.links){
                    system.debug('link = ' + link);
                    system.debug('link.Href = ' + link.Href);
                    system.debug('link void = ' + link.Href.contains('void'));
                    if (link.Href.contains('void')){
                        so_i.Guardian_s_void_link__c = link.Href.split(':')[1];
                        break;
                    }
                }
                system.debug('so.SO_Line_Items__r = ' + so_i.SO_Line_Items__r);
                for (SO_Line_Items__c li : so_i.SO_Line_Items__r){
                    system.debug('li.Products__r.name = ' + li.Products__r.name);
                    system.debug('li.Products__r.name ==' + li.Products__r.name.contains('Protection Plan'));
                    if (li.Products__r.name.contains('Protection Plan')){
                        li.Item__c = 'Registered';
                        soLineToUpdateList.add(li);
                    }
                }
            }else{
                boolean isError = false;
                for (GuardianManager.Results res : response.results){
                    if (!res.Info.contains('plan') && !res.Info.contains('FAILURE-REGISTRATION') && !res.Info.contains('Transaction total') && !res.Info.contains('Setting transaction total') && !res.Info.contains('add transaction')){
                        so_i.Error_messag_registering_protection_plan__c = res.Info;
                        isError = true;
                    }
                    else if (res.Info.contains('plan')){
                        so_i.Guardian_Number__c = res.Info.split(':')[2].split(' ')[0];
                    }
                }
                    system.debug('isError = ' + isError);
                if (isError){
                    so_i.Error_registering_protection_plan__c = system.now();
                }
                else{
                    system.debug('so.SO_Line_Items__r = ' + so_i.SO_Line_Items__r);
                    for (SO_Line_Items__c li : so_i.SO_Line_Items__r){
                        system.debug('li.Products__r.name = ' + li.Products__r.name);
                        system.debug('li.Products__r.name ==' + li.Products__r.name.contains('Protection Plan'));
                        if (li.Products__r.name.contains('Protection Plan')){
                            li.Item__c = 'Registered';
                            soLineToUpdateList.add(li);
                        }
                    }
                } 
            }
            so_i.Guardian_response__c = string.valueof(response);
            so_i.Guardian_request__c = string.valueof(body);
        }
        update soLineToUpdateList;
        update soList;
    }
    
    
    @future (callout=true)
    private static void checkFraud (Set<Id> soIdSet){
        List<Sales_Order__c> soList = [ SELECT  Id, Bill_To__c, Billing_Street__c, Billing_City__c, Billing_State__c, Billing_ZipCode__c, Billing_Country__c, Billing_Phone__c,
                                                Ship_to__c, Shipping_Street__c, Shipping_City__c, Shipping_State__c, Shipping_ZipCode__c, Shipping_Country__c, Shipping_Phone__c, 
                                                Email__c, Grand_Total__c, Payment_Type__r.Last_4_digits_of_CC__c, Payment_Type__r.recordtypeid, Placed_From_IP__c 
                                        FROM Sales_Order__c WHERE Id IN :soIdSet];
        try{
            for(Sales_Order__c so_i : soList){
                WhitePagesHandler.Request wpReq = WhitePagesHandler.generateRequest(so_i);
                WhitePagesHandler.Response wpRes = WhitePagesHandler.identityCheck(wpReq);
                system.debug('wpRes = ' + wpRes);
                so_i.White_Pages_response__c = string.valueof(wpRes);
                if (wpRes.primary_address_checks != null){
                    so_i.White_Pages_billing_address_to_name__c = wpRes.primary_address_checks.address_to_name;
                    so_i.White_Pages_billing_address_error__c = wpRes.primary_address_checks.error;
                    so_i.White_Pages_billing_address_resident_n__c = wpRes.primary_address_checks.resident_name;
                    if (wpRes.primary_address_checks.warnings != null && wpRes.primary_address_checks.warnings.size() > 0){
                        so_i.White_Pages_billing_address_warning__c = string.valueof(wpRes.primary_address_checks.warnings);
                    }
                }
                if (wpRes.secondary_address_checks != null){
                    so_i.White_Pages_shipping_address_to_name__c = wpRes.secondary_address_checks.address_to_name;
                    so_i.White_Pages_shipping_address_error__c = wpRes.secondary_address_checks.error;
                    so_i.White_Pages_shipping_address_resident_n__c = wpRes.secondary_address_checks.resident_name;
                    if (wpRes.secondary_address_checks.warnings != null && wpRes.secondary_address_checks.warnings.size() > 0){
                        so_i.White_Pages_shipping_address_warning__c = string.valueof(wpRes.secondary_address_checks.warnings);
                    }
                }
                if (wpRes.ip_address_checks != null){
                    so_i.White_Pages_IP_error__c = wpRes.ip_address_checks.error;
                    if ( wpRes.ip_address_checks.warnings != null &&  wpRes.ip_address_checks.warnings.size() > 0){
                        so_i.White_Pages_IP_warning__c = string.valueof(wpRes.ip_address_checks.warnings);
                    }
                    so_i.White_Pages_IP_distance_from_address__c = string.valueof(wpRes.ip_address_checks.distance_from_address);
                    so_i.White_Pages_IP_distance_from_phone__c = string.valueof(wpRes.ip_address_checks.distance_from_phone);
                    so_i.White_Pages_IP_is_proxy__c = string.valueof(wpRes.ip_address_checks.is_proxy);
                }
                if (wpRes.primary_phone_checks != null){
                    so_i.White_Pages_phone_error__c = wpRes.primary_phone_checks.error;
                    if ( wpRes.primary_phone_checks.warnings != null &&  wpRes.primary_phone_checks.warnings.size() > 0){
                        so_i.White_Pages_phone_warning__c = string.valueof(wpRes.primary_phone_checks.warnings);
                    }
                    so_i.White_Pages_phone_to_name__c = wpRes.primary_phone_checks.phone_to_name;
                    so_i.White_Pages_phone_to_address__c = wpRes.primary_phone_checks.phone_to_address;
                    so_i.White_Pages_phone_carrier__c = wpRes.primary_phone_checks.carrier;
                    so_i.White_Pages_phone_line_type__c = wpRes.primary_phone_checks.line_type;
                    so_i.White_Pages_phone_subscriber_name__c = wpRes.primary_phone_checks.subscriber_name;
                }
                if (wpRes.secondary_phone_checks != null){
                    so_i.White_Pages_secondary_phone_error__c = wpRes.secondary_phone_checks.error;
                    if (wpRes.secondary_phone_checks.warnings != null &&  wpRes.secondary_phone_checks.warnings.size() > 0){
                        so_i.White_Pages_secondary_phone_warning__c = string.valueof(wpRes.secondary_phone_checks.warnings);
                    }
                    so_i.White_Pages_secondary_phone_to_name__c = wpRes.secondary_phone_checks.phone_to_name;
                    so_i.White_Pages_secondary_phone_to_address__c = wpRes.secondary_phone_checks.phone_to_address;
                    so_i.White_Pages_secondary_phone_carrier__c = wpRes.secondary_phone_checks.carrier;
                    so_i.White_Pages_secondary_phone_line_type__c = wpRes.secondary_phone_checks.line_type;
                    so_i.White_Pages_secondary_phone_subscriber_n__c = wpRes.secondary_phone_checks.subscriber_name;
                }
                if (wpRes.email_address_checks != null){
                    so_i.White_Pages_email_error__c = wpRes.email_address_checks.error;
                    if (wpRes.email_address_checks.warnings != null &&  wpRes.email_address_checks.warnings.size() > 0){
                        so_i.White_Pages_email_warning__c = string.valueof(wpRes.email_address_checks.warnings);
                    }
                    so_i.White_Pages_email_to_name__c = wpRes.email_address_checks.email_to_name;
                    so_i.White_Pages_email_registered_name__c = wpRes.email_address_checks.registered_name;
                    so_i.White_Pages_email_first_seen_days__c = wpRes.email_address_checks.email_first_seen_days;
                }

                //score
                updateSoSifctScience( so_i, so_i.Email__c, 'Sift_science__c');
            }
            update soList;
        }
        catch (exception e){ 
            system.debug('e = ' + e.getmessage());
        }
    }
    
    @future (callout=true)
    static void updateSoSiftScienceAfter30Min(Set<Id> SoIdSet){
        List<Sales_Order__c> salesOrderList =  [SELECT id, Email__c FROM  Sales_Order__c WHERE id IN: SoIdSet];
        for(Sales_Order__c salesOrder_i : salesOrderList){
            updateSoSifctScience( salesOrder_i, salesOrder_i.Email__c, 'Sift_science_score_30_minutes__c');
        }
        update salesOrderList;
    }

    static void updateSoSifctScience(Sales_Order__c newSo, String soEmail, String fieldName){
        SiftScienceHandler.Response sRes = SiftScienceHandler.getScore(soEmail);
        newSo.Sift_science_response__c = string.valueof(sRes);
        if(sRes.status == 0 && sRes.scores.containskey('payment_abuse')){
            newSo.put(fieldName, string.valueof(integer.valueof(sRes.scores.get('payment_abuse').score  * 100)));
        }
    }
    /*private static void checkForFraud(List<Sales_Order__c> soNewList){
        for(Sales_Order__c sa_i : soNewList){
            if(sa_i.Bill_To__c != sa_i.Ship_to__c || sa_i.Billing_Street__c != sa_i.Shipping_Street__c || sa_i.Billing_City__c != sa_i.Shipping_City__c || sa_i.Billing_State__c != sa_i.Shipping_State__c || sa_i.Billing_ZipCode__c != sa_i.Shipping_ZipCode__c || sa_i.Billing_Phone__c != sa_i.Shipping_Phone__c || sa_i.Mobile__c != sa_i.Shipping_Mobile__c  ){
                sa_i.Check_for_Fraud__c = true; 
            }
        }
    }*/
    
    // Classes for Google API response
    public class GResponse{
        public String status;
        public GComponents[] results;
    }
    public class GComponents{
        public String formatted_address;
        public GGeometry geometry;
    }
    public class GGeometry {
        public LatLng location;
    }
    public class LatLng{
        public Double lat, lng;
    }

    public static string getNearby(String lat, String lon,string soID,String deliveryId,String lat1, String lon1,string deliverycomanyname) 
    {
        // If geolocation isn't set, use Eindhoven (or any other city)
        // Put a default location latitue and longitude here, this could be where you are located the most
        // and will only be used as a backup if the browser can not get your location details
        
        if(lat == null || lon == null || lat.equals('') || lon.equals('')) 
		{
			lat ='51.096214'; 
			lon = '3.683153'; 
        }  
        //recordtype rectypeId=[select id from recordtype where name='Delivery Company'];
        //System.debug('deliveryId: '+deliveryId);
       
        String queryString = 
            'SELECT Id, Name, Location__Longitude__s, Location__Latitude__s, ' +'ShippingStreet, Phone, ShippingCity,ShippingPostalCode ' +
            'FROM Account ' +'WHERE Is_active__c = true and Location__Latitude__s != null and Location__Longitude__s != null and  RecordType.name = \'Delivery Company\' AND DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') < 805'  
            + 'ORDER BY DISTANCE(Location__c, GEOLOCATION('+lat+','+lon+'), \'km\') '+ 'LIMIT 3';
        // Run and return the query results 
        
        system.debug('query string contains :' + querystring);
        list<Account> deliverycompanies = database.Query(queryString);
        system.debug('deliverycompanies :' + deliverycompanies);
     
        return calculateHaversineDistance(deliverycompanies,soID,decimal.valueof(lat),decimal.valueof(lon),decimal.valueof(lat1),decimal.valueof(lon1),deliverycomanyname);
        
    } 
    public static string calculateHaversineDistance(list<account> accList ,string salesorderId,Decimal lat1, Decimal lon1, Decimal lat2, Decimal lon2,string deliverycomanyname)
    {
        // convert to radians
        Double dDepartLat = lat1 * 3.14159 / 180;
        Double dDepartLong = lon1 * 3.14159 / 180; 
        map<string,Double> deliveryComapniesList=new map<string,Double>();
        
        for(account actemp: accList)
        {
            Double dArrivalLat = actemp.Location__Latitude__s * 3.14159 / 180;
            Double dArrivalLong = actemp.Location__Longitude__s * 3.14159 / 180;
            
            Double dDeltaLong = dArrivalLong - dDepartLong;
            Double dDeltaLat = dArrivalLat - dDepartLat; 
            
            // calculate angle using the haversine formula
            Double dHaversineResult = Math.Sin( dDeltaLat / 2 ) * Math.Sin( dDeltaLat / 2 ) 
                + Math.Cos( dDepartLat ) * Math.Cos( dArrivalLat )  
                * Math.Sin( dDeltaLong / 2 ) * Math.Sin( dDeltaLong / 2 );
            
            // calculate distance by multiplying arc-tangent by the planet radius in miles
            Double dDistance = 3958.76 * 2 * Math.Atan2( Math.Sqrt( dHaversineResult ), Math.Sqrt( 1 - dHaversineResult ));
            deliveryComapniesList.put(actemp.Name,Math.round(dDistance)); 
        } 
        
        Double dArrivalLat;
        Double dArrivalLong;
        Double dDeltaLong;
        Double dDeltaLat;
        Double dHaversineResult;
        Double dDistance; 
        
        if(lat2 !=null && lon2 !=null)
        {
            dArrivalLat = lat2 * 3.14159 / 180;
            dArrivalLong = lon2 * 3.14159 / 180;
            
            dDeltaLong = dArrivalLong - dDepartLong;
            dDeltaLat = dArrivalLat - dDepartLat; 
            
            // calculate angle using the haversine formula
            dHaversineResult = Math.Sin( dDeltaLat / 2 ) * Math.Sin( dDeltaLat / 2 ) 
                + Math.Cos( dDepartLat ) * Math.Cos( dArrivalLat )  
                * Math.Sin( dDeltaLong / 2 ) * Math.Sin( dDeltaLong / 2 );
            
            // calculate distance by multiplying arc-tangent by the planet radius in miles
            dDistance = 3958.76 * 2 * Math.Atan2( Math.Sqrt( dHaversineResult ), Math.Sqrt( 1 - dHaversineResult ) );
        }
        
        // Update Distance value in Sales Order and return the distance
        //Sales_Order__c so=new Sales_Order__c(); 
        //so.id=salesorderId;  
        //so.Distance_In_Miles__c= Math.round(dDistance);   
        //so.Nearest_Delivery_Company__c = acc.Name;  
        //so.Delivery_Companies_Distance__c = '';
        string ret = '';
        if(deliverycomanyname !=null && dDistance !=null)
        {
            //Suggested Delivery
            ret +=' Suggested Delivery:  ';
            ret +=deliverycomanyname+' - '+Math.round(dDistance) +' Miles  \n';
        }
        
        for(string deliverycompanyTemp: deliveryComapniesList.keyset())
        {
            ret +=deliverycompanyTemp+' - '+integer.valueof(deliveryComapniesList.get(deliverycompanyTemp)) +' Miles  \n';
        } 
        
        //so.Delivery_Companies_Distance__c+=deliverycompanyName+' - '+Math.round(dDistance);
        return ret; 
    }   

    static void checkExcludeFromBulk(Map<Id, Sales_Order__c> newOrderMap, Map<Id, Sales_Order__c> oldOrderMap){
        Set<Id> orderToUpdateSet = new Set<Id>();
        for(Sales_Order__c currentOrder_i : newOrderMap.values()){
            if(currentOrder_i.Product_Excluded_from_bulk__c == false && currentOrder_i.Product_Excluded_from_bulk__c != oldOrderMap.get(currentOrder_i.Id).Product_Excluded_from_bulk__c){
                orderToUpdateSet.add(currentOrder_i.Id);
            }
        }
        if(orderToUpdateSet.size() == 0){
            return;
        }
        Set<String> excludedOrderIdSet = new Set<String> ();
        for(SO_Line_Items__c orderItem_i : [SELECT Product_Excluded_from_bulk__c, Sales_Order__c 
                                            FROM SO_Line_Items__c 
                                            WHERE Sales_Order__c IN :orderToUpdateSet]) {
            if(!excludedOrderIdSet.contains(orderItem_i.Sales_Order__c)) {										
                newOrderMap.get(orderItem_i.Sales_Order__c).Product_Excluded_from_bulk__c = orderItem_i.Product_Excluded_from_bulk__c;
                if(orderItem_i.Product_Excluded_from_bulk__c == true) {
                    excludedOrderIdSet.add(orderItem_i.Sales_Order__c);
                }
            }
        }
    }
}