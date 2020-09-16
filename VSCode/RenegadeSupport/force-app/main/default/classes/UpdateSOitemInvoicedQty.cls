/*
*   Author : Vishnu Bijjula | Kairos Tech
*   Class  : UpdateSOitemInvoicedQty
*   Purpose: This class is used to update the quantity of Invoiced and Refunded on Sales Order Line Items Field Values.
*/
global with sharing class UpdateSOitemInvoicedQty {
    
    global static void addinvoicedSOItemUpdate(Set<Id> invoiceItemList) {
        Map<String, SO_Line_Items__c> soItemToUpdateMap = new Map<String, SO_Line_Items__c>();
        map<id,SO_Line_Items__c> soitemmap = new map<id,SO_Line_Items__c>();
        Set<Id> soiIds = new Set<Id>();
        
        try {
            Id SalesOrderId;
            
            Id payablesRT = Schema.SObjectType.invoice__c.getRecordTypeInfosByName().get('Payables').getRecordTypeId();
            Id receivablesRT = Schema.SObjectType.invoice__c.getRecordTypeInfosByName().get('Receivables').getRecordTypeId();
            Map<id, Invoice__c> InvoiceMap = new Map<id, Invoice__c>();
            List<Id> invoiceIdList = new List<Id>();

            for(Invoice_Line_Item__c  inv : [Select id,Items_invoiced__c,Invoice__r.Sales_Order__c from Invoice_Line_Item__c where id In:invoiceItemList])
            {
                soiIds.add(inv.Items_invoiced__c);
                SalesOrderId = inv.Invoice__r.Sales_Order__c;
                invoiceIdList.add(inv.Invoice__c);
            }
            
            InvoiceMap = new Map<id, Invoice__c>([SELECT Id, Reason_for_Refund__c FROM Invoice__c WHERE id in :invoiceIdList]);
            list<SO_Line_Items__c> bundleSOItems = new List<SO_Line_Items__c>();   
            for(SO_Line_Items__c SOItem : [SELECT id,Products__c,Quantity_Invoiced__c,Quantity_Refunded__c,Quantity__c,Bundle_Item__c,Products__r.RecordType.Name, DiscountAmount__c
                                           FROM SO_Line_Items__c where Sales_Order__c=:SalesOrderId AND (Products__r.RecordType.Name='Bundled' AND Bundle_Item__c != Null)]) 
            {
                bundleSOItems.add(SOItem);
            }                                                                       
            System.debug('bundleSOItems: '+bundleSOItems);
            System.debug('bundleSOItems Size:: '+bundleSOItems.size());
            
            for(SO_Line_Items__c  so: [SELECT id, Quantity_Invoiced__c, Quantity__c, Quantity_Refunded__c, DiscountAmount__c FROM SO_Line_Items__c where id IN :soiIds])
            {
                soitemmap.put(so.id,so);
            }
            
            for(Invoice_Line_Item__c  inv : [SELECT Id,Invoice__c,Items_invoiced__c,Quantity_Invoiced__c,Quantity_Ordered__c,Items_invoiced__r.Products__c,
                                             Quantity_to_Invoice__c,Quantity_To_Refund__c,Items_invoiced__r.Products__r.RecordType.Name,Items_invoiced__r.Bundle_Item__c,
                                             Invoice__r.RecordtypeId,Invoice__r.Recordtype.Name FROM Invoice_Line_Item__c where id In :invoiceItemList])
            {
                SO_Line_Items__c soi = new SO_Line_Items__c();
                
                System.debug('Insert Recordtype: '+inv.Invoice__r.Recordtype.Name);
                if(inv.Invoice__r.RecordtypeId == receivablesRT) {
                    if(inv.Items_invoiced__r.Products__r.RecordType.Name == 'Bundled') {
                        soi = soitemmap.get(inv.Items_invoiced__c);
                        decimal quan = soi.Quantity__c;
                        soi.Quantity_Invoiced__c = inv.Quantity_to_Invoice__c;
                        if(InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='Cancellation'){
                            
                            // soi.DiscountAmount__c -= inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / (soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c) );
                            // quan -= inv.Quantity_To_Refund__c;
                            // if(quan<1){
                            //     soi.Item__c='Cancelled';
                            // }
                            // else {
                            // 	soi.Quantity__c = quan;
                            // }
                            soi = populateItemData(soi, inv, quan);
                        }

                        soItemToUpdateMap.put(soi.id, soi);
                        SO_Line_Items__c parentItem = soi;
                        if(bundleSOItems.size() > 0 || bundleSOItems != null) {
                            for(SO_Line_Items__c updateInvoiced : bundleSOItems) {
                                if(updateInvoiced.Products__c == inv.Items_invoiced__r.Products__c && updateInvoiced.Bundle_Item__c != null) {
                                    soi = updateInvoiced;
                                    soi.Quantity_Invoiced__c = updateInvoiced.Quantity__c * inv.Quantity_to_Invoice__c;
                                    if(InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='Cancellation'){
                                        Decimal discToSubstruct =  inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / (soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c) );
                                        soi.DiscountAmount__c -= discToSubstruct;
                                        parentItem.DiscountAmount__c -= discToSubstruct;  
                                    }
                                    
                                    soItemToUpdateMap.put(soi.id, soi);
                                }else if(updateInvoiced.id==inv.Items_invoiced__c && InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='Compensation'){
                                    updateInvoiced.Quantity_Refunded__c+= inv.Quantity_To_Refund__c;
                                }
                            }
                        }
                    }
                    else {
                        soi = soitemmap.get(inv.Items_invoiced__c);
                        decimal quan = soi.Quantity__c;
                        
                        if(InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='Cancellation'){
                            // quan -= inv.Quantity_To_Refund__c;
                            // soi.DiscountAmount__c -= inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / (soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c) );
                            // if(quan<1){
                            //     soi.Item__c='Cancelled';
                            // }
                            // else {
                            // 	soi.Quantity__c = quan;
                            // }
                            soi = populateItemData(soi, inv, quan);
                        }
                        soi.Quantity_Invoiced__c = inv.Quantity_to_Invoice__c;
                        soItemToUpdateMap.put(soi.id, soi); 
                    }
                }
                else if(inv.Invoice__r.RecordtypeId == payablesRT) {
                    if(inv.Items_invoiced__r.Products__r.RecordType.Name == 'Bundled' && inv.Items_invoiced__r.Bundle_Item__c != null) {
                        if(bundleSOItems.size() > 0 || bundleSOItems != null) {
                            SO_Line_Items__c parentItem = soitemmap.get(inv.Items_invoiced__c);
                            for(SO_Line_Items__c updateRefunded : bundleSOItems) {
                                if((updateRefunded.Products__c == inv.Items_invoiced__r.Products__c && updateRefunded.Bundle_Item__c == inv.Items_invoiced__r.Bundle_Item__c) && updateRefunded.Bundle_Item__c != null) {
                                    soi = updateRefunded;
                        			decimal quan = soi.Quantity__c;
                                    
                                    if(InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='Cancellation'){
                                        quan -= inv.Quantity_To_Refund__c;
                                        Decimal discToSubstruct = calculateDiscountToSubstract(soi, inv);//0;
                                        // Decimal differenceBetweenInvoicedAndRefunded = soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c;
                                        // if(differenceBetweenInvoicedAndRefunded != 0 && soi.DiscountAmount__c != 0){
                                        //     discToSubstruct = inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / differenceBetweenInvoicedAndRefunded);
                                        // }                       
                                        //soi.DiscountAmount__c -= inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / (soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c) );
                                        soi.DiscountAmount__c -= discToSubstruct;
                                        parentItem.DiscountAmount__c -= discToSubstruct; 
                                        if(quan < 1) {
                                            soi.Item__c='Cancelled';
                                        }
			                            else {
			                            	soi.Quantity__c = quan;
                                        }
                                        //soi = populateItemData(soi, inv, quan);
                                    }
                                    soi.Quantity_Refunded__c += inv.Quantity_To_Refund__c;
                                    soItemToUpdateMap.put(soi.id, soi);
                                }
                            }
                        }
                    }
                    else {
                        soi = soitemmap.get(inv.Items_invoiced__c);
                        decimal quan = soi.Quantity__c;
                       
                        if(InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='Cancellation' || InvoiceMap.get(inv.Invoice__c).Reason_for_Refund__c=='GPP Cancellation'){
                            // quan -= inv.Quantity_To_Refund__c;
                            // soi.DiscountAmount__c -= inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / (soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c) );
                            // if(quan<1){
                            //     soi.Item__c='Cancelled';
                            // }
                            // else {
                            // 	soi.Quantity__c = quan;
                            // }
                            soi = populateItemData(soi, inv, quan);
                        }
                        soi.Quantity_Refunded__c += inv.Quantity_To_Refund__c;
                        soItemToUpdateMap.put(soi.id, soi);
                    }
                }
            }
            if(!soItemToUpdateMap.isEmpty()) {
                update soItemToUpdateMap.values();//setValidOrderItemQuantity();
            }
        }
        catch(Exception e)
        {
            System.debug(e.getMessage()+' '+e.getCause()+' '+e.getLineNumber());
            EmailManager.send('An error has occurred.<br/>Error text: ' + e.getMessage() + '<br/>Stack trace: ' + e.getStackTraceString() +' \n on one of SO_line_item ' + JSON.serialize(invoiceItemList), 'Responsible Emails');
        }
    }
    
    static SO_Line_Items__c populateItemData(SO_Line_Items__c soi, Invoice_Line_Item__c inv, Decimal quantity ){
        quantity -= inv.Quantity_To_Refund__c;	
        //Decimal differenceBetweenInvoicedAndRefunded = soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c;
        soi.DiscountAmount__c -= calculateDiscountToSubstract(soi, inv); //differenceBetweenInvoicedAndRefunded != 0 ? inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / differenceBetweenInvoicedAndRefunded) : 0;
        if(quantity < 1) {	
            soi.Item__c = 'Cancelled';	
        }	
        else {	
            soi.Quantity__c = quantity;	
        }	
        return soi;
    }

    static Decimal calculateDiscountToSubstract(SO_Line_Items__c soi, Invoice_Line_Item__c inv){
        Decimal differenceBetweenInvoicedAndRefunded = soi.Quantity_Invoiced__c - soi.Quantity_Refunded__c;
        return differenceBetweenInvoicedAndRefunded != 0 ? inv.Quantity_To_Refund__c * (soi.DiscountAmount__c / differenceBetweenInvoicedAndRefunded) : 0;                
    }

    global static void removeinvoicedSOItemUpdate(list<Invoice_Line_Item__c> invoiceItemList) {
        map<id,SO_Line_Items__c> soitemmap = new map<id,SO_Line_Items__c>();
        set<Id> soiIds = new set<Id>();
        list<SO_Line_Items__c> SO_Item = new list<SO_Line_Items__c>();
        
        try {
            Id payablesRT = Schema.SObjectType.invoice__c.getRecordTypeInfosByName().get('Payables').getRecordTypeId();
            Id receivablesRT = Schema.SObjectType.invoice__c.getRecordTypeInfosByName().get('Receivables').getRecordTypeId();
            
            Id SalesOrderId;
            
            for(Invoice_Line_Item__c  inv : [Select id,Items_invoiced__c,Invoice__r.Sales_Order__c from Invoice_Line_Item__c where id In:invoiceItemList])
            {
                soiIds.add(inv.Items_invoiced__c);
                SalesOrderId = inv.Invoice__r.Sales_Order__c;
            }
            
            list<SO_Line_Items__c> bundleSOItems = new List<SO_Line_Items__c>();   
            for(SO_Line_Items__c SOItem : [Select id,Products__c,Quantity_Invoiced__c,Quantity_Refunded__c,Quantity__c,Bundle_Item__c,Products__r.RecordType.Name
                                           from SO_Line_Items__c where Sales_Order__c=:SalesOrderId AND (Products__r.RecordType.Name='Bundled' AND Bundle_Item__c != Null)]) 
            {
                bundleSOItems.add(SOItem);
            }                                                                       
            System.debug('bundleSOItems: '+bundleSOItems);
            System.debug('bundleSOItems Size:: '+bundleSOItems.size());                                                                       
            
            for(SO_Line_Items__c  so: [select id,Quantity_Invoiced__c,Quantity_Refunded__c from SO_Line_Items__c where id IN :soiIds ])
            {
                soitemmap.put(so.id,so);
            }
            
            for(Invoice_Line_Item__c  inv : [SELECT Id,Invoice__c,Items_invoiced__c,Quantity_Invoiced__c,Quantity_Ordered__c,Items_invoiced__r.Products__c,
                                             Quantity_to_Invoice__c,Quantity_To_Refund__c,Items_invoiced__r.Products__r.RecordType.Name,Items_invoiced__r.Bundle_Item__c,
                                             Invoice__r.RecordtypeId,Invoice__r.Recordtype.Name FROM Invoice_Line_Item__c where id In :invoiceItemList])
            {
                SO_Line_Items__c soi = new SO_Line_Items__c();
                
                System.debug('Delete Recordtype: '+inv.Invoice__r.RecordtypeId);
                soi=soitemmap.get(inv.Items_invoiced__c);
                if(inv.Invoice__r.RecordtypeId == receivablesRT) {
                    soi.Quantity_Invoiced__c -= inv.Quantity_to_Invoice__c;
                    
                    if(bundleSOItems.size() > 0 || bundleSOItems != null) {
                        for(SO_Line_Items__c updateInvoiced : bundleSOItems) {
                            if(updateInvoiced.Products__c == inv.Items_invoiced__r.Products__c && updateInvoiced.Bundle_Item__c != null) {
                                soi = updateInvoiced;
                                soi.Quantity_Invoiced__c -= updateInvoiced.Quantity__c * inv.Quantity_to_Invoice__c;
                                
                                SO_Item.add(soi);
                            }
                        }
                    }
                }
                else if(inv.Invoice__r.RecordtypeId == payablesRT) {
                    soi.Quantity_Refunded__c -= inv.Quantity_To_Refund__c;
                    
                    SO_Item.add(soi);
                    if(bundleSOItems.size() > 0 || bundleSOItems != null) {
                        for(SO_Line_Items__c updateRefunded : bundleSOItems) {
                            if((updateRefunded.Products__c == inv.Items_invoiced__r.Products__c && updateRefunded.Bundle_Item__c == inv.Items_invoiced__r.Bundle_Item__c) && updateRefunded.Bundle_Item__c != null) {
                                soi = updateRefunded;
                                soi.Quantity_Refunded__c -= inv.Quantity_To_Refund__c;
                                
                                SO_Item.add(soi);
                            }
                        }
                    }
                }
            }
            System.debug('SO_Item: '+SO_Item);
            if(!SO_Item.isEmpty()) {
                update SO_Item;
            }
        }
        Catch(Exception e)
        {
            System.debug(e.getMessage()+' '+e.getCause()+' '+e.getLineNumber());  
        }
    } 
}