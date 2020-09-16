/* Call the apex class of AccountGeolocation whenever new account is created and existing accuount is updated with Shipping address,
Call the apex class of AccountBillingGeolocation whenever new account is created and existing accuount is updated with Billing address
*/
trigger GeolocationOfAccount on Account (after insert,after update) 
{
    if(GeolocationManager.isRun){
        Id rectypeIdDev = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Delivery Company').getRecordTypeId();
        Id rectypeIdManu = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Manufacturer').getRecordTypeId();
        Id rectypeIdWarh = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Warehouse').getRecordTypeId();
        Id rectypeIdCustomer = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        if(system.isBatch() || system.isFuture()) return;
        Integer mapBillingIndex = 0;
        Integer mapShippingIndex = 0;    
        Map<Integer,Map<Id, Boolean>> billingAccountIdChunkMap = new Map<Integer,Map<Id, Boolean>>();
        Map<Integer,Map<Id, Boolean>> shippingAccountIdChunkMap = new Map<Integer,Map<Id, Boolean>>();
        if(trigger.isAfter){  
            for(Account account_i : trigger.new){
                if(  (account_i.Location__Latitude__s == null && (account_i.RecordTypeId == rectypeIdDev || account_i.RecordTypeId == rectypeIdWarh)) 
                    || (trigger.isUpdate && (account_i.ShippingStreet != Trigger.oldMap.get(account_i.id).ShippingStreet || account_i.ShippingCity != Trigger.oldMap.get(account_i.id).ShippingCity || account_i.ShippingPostalCode != Trigger.oldMap.get(account_i.id).ShippingPostalCode)) ){
                        if(!shippingAccountIdChunkMap.containsKey((Integer)mapShippingIndex/100)){
                            shippingAccountIdChunkMap.put((Integer)mapShippingIndex/100,new Map<Id, Boolean>());
                        }
                        if (account_i.ShippingStreet == account_i.BillingStreet && account_i.ShippingCity == account_i.BillingCity && account_i.ShippingPostalCode == account_i.BillingPostalCode ){
                            shippingAccountIdChunkMap.get((Integer)mapShippingIndex/100).put(account_i.Id, true);
                            mapShippingIndex++;
                        }
                        else{
                            shippingAccountIdChunkMap.get((Integer)mapShippingIndex/100).put(account_i.Id, false);
                            mapShippingIndex++; 
                        } 
    
                }else if((account_i.BillingLocation__Latitude__s == null && account_i.RecordTypeId == rectypeIdManu) 
                    || (trigger.isUpdate && (account_i.BillingStreet != Trigger.oldMap.get(account_i.id).BillingStreet || account_i.BillingCity != Trigger.oldMap.get(account_i.id).BillingCity || account_i.BillingPostalCode != Trigger.oldMap.get(account_i.id).BillingPostalCode)) ){
                        if(!billingAccountIdChunkMap.containsKey((Integer)mapBillingIndex/100)){
                            billingAccountIdChunkMap.put((Integer)mapBillingIndex/100,new Map<Id, Boolean>());
                        }
                        if (account_i.ShippingStreet == account_i.BillingStreet && account_i.ShippingCity == account_i.BillingCity && account_i.ShippingPostalCode == account_i.BillingPostalCode ){
                            billingAccountIdChunkMap.get((Integer)mapBillingIndex/100).put(account_i.Id, true);
                            mapBillingIndex++;
                        }
                        else{
                            billingAccountIdChunkMap.get((Integer)mapBillingIndex/100).put(account_i.Id, false);
                            mapBillingIndex++; 
                        }
                }
            }
        }
        if(shippingAccountIdChunkMap.size() > 0){
            for(Integer index : shippingAccountIdChunkMap.keySet()){
                if(!System.isFuture() && !System.isBatch()){
                    AccountGeolocation.updateLocations(shippingAccountIdChunkMap.get(index));
                }
            }
            GeolocationManager.isRun = false;
        }
        
        if(billingAccountIdChunkMap.size() > 0){
            for(Integer index : billingAccountIdChunkMap.keySet()){
                if(!System.isFuture() && !System.isBatch()){
                    AccountBillingGeolocation.updateLocations(billingAccountIdChunkMap.get(index));
                }
            }
            GeolocationManager.isRun = false;
        }
    }
    
}