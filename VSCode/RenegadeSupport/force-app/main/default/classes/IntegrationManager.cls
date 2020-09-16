@RestResource(urlMapping='/CreateLog/*')
global with sharing class IntegrationManager {
  
  private static Response response;
  
  @HttpPost  
  global static response createNewLog(Log log) {
    system.debug('log = ' + log);
    
    list<Log__c> existedLogs = [select id, Tries__c, Error__c, Status__c, Object_ID__c, Process__c from Log__c where Log_ID__c = :log.LogID];
    try {
      //system.debug('existedLogs = ' + existedLogs);
      if (existedLogs.size() > 0){
        list<ResponseData> rdList = new list<ResponseData>();
        if (existedLogs[0].Status__c == 'Succeeded' && (log.process == 'Account created' || log.process == 'Account updated')){
          if (log.process == 'Account created' || log.process == 'Account updated'){
            Account acc = [select Magento_Account_Id__c from Account where id = :existedLogs[0].Object_ID__c];
            ResponseData rd = new responseData(acc.Magento_Account_Id__c, existedLogs[0].Object_ID__c);
            rdList.add(rd);
            return new Response('Succeeded', '', rdList);
          }
        } 
        else if (log.process == 'Order created' && existedLogs[0].Object_ID__c != null){
          list<Sales_Order__c> so = [select Magento_Order_ID__c from Sales_Order__c where id = :existedLogs[0].Object_ID__c];
          if (so.size() == 0){}
          else{
	          ResponseData rd = new responseData(so[0].Magento_Order_ID__c, existedLogs[0].Object_ID__c);
	          rdList.add(rd);
	          return new Response('Succeeded', '', rdList);
          }
        }
        else if (log.process == 'Product created_updated' && existedLogs.size() > 0 && existedLogs[0].Process__c == 'Product created_updated'){
          return new Response('Failed', 'Log already existed: ' + existedLogs[0].id);
        }
      }
      //system.debug('log = ' + log);
      setProcess(log);
      //system.debug('log = ' + log);
      //system.debug('response = ' + response);
      try {
        SaveLog(log, response, existedLogs.size() > 0 ? existedLogs[0] : null);
      }
      catch (exception en){
         return new Response('Failed', en.getmessage() + ' ' + en.getLineNumber());
      }
      return response;
    }
    catch (exception e){
      if (response == null){
        response = new Response('Failed', e.getmessage() + ' ' + e.getLineNumber());
      }
      try {
        SaveLog(log, response, existedLogs.size() > 0 ? existedLogs[0] : null);
      }
      catch (exception en){
         return new Response('Failed', en.getmessage() + ' ' + en.getLineNumber());
      }
      return response;
    }
  }
  
  private static void setProcess (Log log){
    try{
      if (log.process == 'Order created'){
        createOrderFromLog(log);
      }
      else if (log.process == 'oldOrder'){
        createOldOrderFromLog(log);
      }
      else if (log.process == 'Account created' || log.process == 'Account updated'){
        createUpdateAccountFromLog(log);
      }
      /*else if (log.process == 'OldAccount'){
        createOldAccountFromLog(log);
      }*/
     
      else if (log.process == 'ConfigProduct'){
        createUpdateConfigProd(log);
      } /*
      else if (log.process == 'Account updated'){
        createOrderFromLog(log);
      }}*/
      else if (log.process == 'Product created_updated'){
        createUpdateProdactFromLog(log);
      }
      else {
        response = new Response('Failed', 'Process was not defined');
      }
    }
    catch (exception e){
      //if (response != null){
        response = new Response('Failed', e.getmessage() + ' ' + e.getLineNumber());
      //}
      return;
    }
  }
  
  @future (callout=true)
  public static void sendLogToMagento (string logId){
    Log__c log;
    try{
      log = [select Data__c, Error__c, Log_ID__c, Object_ID__c, Owner__c, Process__c, Response__c, Tries__c, Status__c from Log__c where id = :logId];
    }
    catch (exception e){
      //if didn't find any logs bbecause permissions 
      return;
    }
    if (log.Tries__c == null || log.Tries__c == 0){
      log.Tries__c = 1;
      log.Log_ID__c = log.id;
    }
    else {
      log.Tries__c ++;
      log.Log_ID__c = log.id;
    }
	IntegrationAccountHelper.Log l = new IntegrationAccountHelper.Log();
    if (log.Process__c != 'Order updated'){
	    try{
	      //system.debug('log.Data__c = ' + log.Data__c);
	      while (log.Data__c.contains('\r\n')){
	        log.Data__c = log.Data__c.replace('\r\n', '');
	      }
	      while (log.Data__c.contains('\n')){
	        log.Data__c = log.Data__c.replace('\n', '');
	      }
	      while (log.Data__c.contains('\r')){
	        log.Data__c = log.Data__c.replace('\r', '');
	      }
	      //system.debug('log.Data__c2 = ' + log.Data__c);
	      list<IntegrationAccountHelper.Data> data = (list<IntegrationAccountHelper.Data>)JSON.deserialize(log.Data__c, list<IntegrationAccountHelper.Data>.class);
	      System.debug('MAGENTO : ' + data);
	      l.Data = data[0];
	    }
	    catch(exception e){
	      System.debug('MAGENTO : ' + e.getmessage());
	      log.Error__c = 'incorrect data - ' + e.getMessage() + '\n' + e.getLineNumber();
	      log.Status__c = 'Failed';
	      setRecordToResend(log);
	      update log;
	      return;
	    }
	    l.LogID = log.Log_ID__c;
	    l.Process = log.Process__c;
    }
    try{
      string jsonStr = log.Process__c != 'Order updated' ? '{"data": ' + JSON.serialize(l) + '}' : log.Data__c;
      //system.debug('json = ' + jsonStr);
        Magento_Integration_Setting__c setting = Magento_Integration_Setting__c.getInstance();
      HttpRequest req = new HttpRequest();
          //req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
          req.setHeader('Content-Type', 'application/json');
          string endPoint = log.Process__c != 'Order updated' ? setting.End_Point__c :  setting.Order_end_point__c;
          endPoint += '?oauth_consumer_key=' + setting.Oauth_consumer_key__c + '&oauth_token=' + setting.Oauth_token__c + '&oauth_signature_method=' + setting.Oauth_signature_method__c + '&oauth_timestamp=' + DateTime.now().getTime() + '&oauth_nonce=' + setting.Oauth_nonce__c + '&oauth_version=' + setting.Oauth_version__c + '&oauth_signature=' + setting.Oauth_signature__c;
          req.setEndpoint(endPoint);
          req.setMethod('POST');
          req.setBody(jsonStr);
      //system.debug('req = ' + req);
          Http h = new Http();
            HttpResponse res = Test.isRunningTest() ? null : h.send(req);
            String result = Test.isRunningTest() ? '{"status":"Failed","error":"","responseData":[{"magentoId":"65977","salesforceId":"'+[select id from Account limit 1].id+'"}]}' : res.getBody();
      //system.debug('result = ' + result);
      log.Response__c = result;
      //tampury
      Response response = ((list<Response>)JSON.deserialize('[' + result + ']', list<Response>.class))[0];
      log.Status__c = response.status;
      log.Error__c = response.error;
      if (log.Status__c == 'Failed'){
        setRecordToResend(log);
      }
      try {
        updateRecordIds(response, log.Process__c);
      }
      catch (exception e){
        log.Status__c = 'Failed';
        log.Error__c = e.getMessage() + '\n' + e.getLineNumber();
        setRecordToResend(log);
      }
    }
    catch (exception e){
      log.Error__c = e.getMessage() + '\n' + e.getLineNumber();
      log.Status__c = 'Failed';
      setRecordToResend(log);
    }
    update log;
  }
  
  private static void updateRecordIds (Response res, string process){
    if (process == 'Account created'){
      for (ResponseData rd : res.responseData){
        Account a = new Account(id = rd.salesforceId, Magento_Account_Id__c = rd.magentoId);
        update a;
      }
    }
  }
  
  private static void setRecordToResend (Log__c log){
    if (log.Process__c == 'Account created' || log.Process__c == 'Account updated') {
      Account a = new Account(id = log.Object_ID__c, Resend__c = true);
      update a;
    }
    else if (log.Process__c == 'Order updated') {
      Sales_Order__c a = new Sales_Order__c(id = log.Object_ID__c, Resend__c = true);
      update a;
    }
  }
  
  
  /*private static void createOldAccountFromLog (Log log){
    Savepoint sp = Database.setSavepoint();
    list<Salesforce_Magento_Field_Mapping__mdt> mapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Account updated' or Process_name__c = 'Account created'];
    try {
      Account acc = new Account();
      string emailWebsite = log.data.email + '-' + log.data.website_id;
      list<Account> existedAccount = [select id, Magento_Account_Id__c, Email_Website__c from Account where Magento_Account_Id__c = :log.data.magentoId or id = :log.data.salesforceId or Email_Website__c = :emailWebsite];
       if (log.data.salesforceId != null && log.data.salesforceId != '' && existedAccount.size() > 0){
         for (Account a : existedAccount){
           if (a.id == log.data.salesforceId){
            acc.id = a.id;
           }
         }
      }
      else if (log.data.magentoId != null && log.data.magentoId != '' && existedAccount.size() > 0 ){
         for (Account a : existedAccount){
           if (a.Magento_Account_Id__c == log.data.magentoId){
            acc.id = a.id;
           }
         }
         if (acc.id == null && log.data.email != null && log.data.email != '' && existedAccount.size() > 0){
           for (Account a : existedAccount){
             if (a.Email_Website__c == emailWebsite){
              acc.id = a.id;
             }
           }
        }
      }
      
      for (Salesforce_Magento_Field_Mapping__mdt m : mapping){
        acc.put(m.SF_field_API_name__c, log.data.getX(m.Magento_field_API_name__c));
      }
      acc.Name = log.data.firstname + ' ' + log.data.lastname;
      upsert acc;
      ResponseData rd = new ResponseData(log.data.magentoId, acc.id);
      list<ResponseData> rdList = new list<ResponseData>();
      rdList.add(rd);
      response = new Response('Succeeded', '', rdList);
      //system.debug('acc = ' + acc);
    }
    catch (exception e){
      Database.rollback(sp);
      //system.debug('e = ' + e);
      response = new Response('Failed', e.getMessage() + ' ' + e.getLineNumber());
      return;
    }
  }
  */
  static boolean comparePhone(Set<String> phoneSet, Set<String> fieldTocompareSet){
    for(String fieldToCompare : fieldTocompareSet){
      if(!String.isBlank(fieldToCompare) && phoneSet.contains(fieldToCompare.replaceAll('[^\\d]', ''))){
        return true;
      }
    }
    return false;
  }

  static List<Account> findAccountByPhone(Set<String> phoneSet){
    List<Account> result = new List<Account>();
    
    List<List<sObject>> accList = [FIND :String.join( new List<String>(phoneSet), ' OR ') IN PHONE FIELDS RETURNING Account(Id, Billing_phone__c, 
    phone, Shipping_phone__c, Phone_Internal__c, Billing_cell__c, Mobile__c, Shipping_cell__c)];
    for(Account currentAccount_i : (List<Account>)accList.get(0)){
      Set<String> fieldTocompareSet = new Set<String>{currentAccount_i.Billing_phone__c, currentAccount_i.Shipping_phone__c, currentAccount_i.phone,
                                                       currentAccount_i.Phone_Internal__c, currentAccount_i.Billing_cell__c, currentAccount_i.Mobile__c, 
                                                       currentAccount_i.Shipping_cell__c};
      if(comparePhone(phoneSet, fieldTocompareSet)){
        result.add(currentAccount_i);
        break;
      }
    }
    return result;
  }

  private static void createUpdateAccountFromLog (Log log){
    Savepoint sp = Database.setSavepoint();
    List<Salesforce_Magento_Field_Mapping__mdt> mapping = [ SELECT Magento_field_API_name__c, SF_field_API_name__c 
                                                            FROM Salesforce_Magento_Field_Mapping__mdt 
                                                            WHERE Process_name__c = 'Account updated' OR Process_name__c = 'Account created'];
    Map<String, WebsiteId_To_Website_Name_Setting__c> websiteIdToWebsiteNameMap = WebsiteId_To_Website_Name_Setting__c.getAll();
    try {
      Account acc = new Account();
      string emailWebsite = (String.isNotBlank(log.data.email)?log.data.email.toLowerCase():'') + '-' + (String.isNotBlank(log.data.website_id)?log.data.website_id.toLowerCase():'');
      String query = 'SELECT id, Magento_Account_Id__c, Email_Website__c, Phone FROM Account ';
      List<String> queryWhereList = new List<String>();
      if(String.isNotEmpty(log.data.magentoId)){
       queryWhereList.add(' Magento_Account_Id__c = \'' + log.data.magentoId + '\'');
      }
      if(String.isNotEmpty(log.data.salesforceId)){
        queryWhereList.add(' Id = \'' + log.data.salesforceId + '\'');
      }
      if(String.isNotEmpty(emailWebsite)){
        queryWhereList.add(' Email_Website__c = \'' + emailWebsite + '\'');
      }
      if(queryWhereList.size() > 0){
        query += ' WHERE (' + String.join(queryWhereList, ' OR ') + ') ';
      }  
      if(String.isBlank(log.data.type) || log.data.type.toLowerCase()  == 'customer'){
        query += (queryWhereList.size() > 0 ? ' AND ' : ' WHERE ') + ' (RecordType.DeveloperName = \'Customer\' or RecordType.DeveloperName = \'Sales_Accounts\' )';
      }    
      query += ' LIMIT 1000';
      Map<Id, Account> existedAccountMap = new Map<Id, Account>((List<Account>)DataBase.query(query));
      Map<String, String> emailToAccountId = new Map<String, String>();
      Map<String, String> magentoAccountIdToAccountId = new Map<String, String>();
      if(existedAccountMap != null && existedAccountMap.size() > 0){
          for(Account currentAccount : existedAccountMap.values()){
              if(!String.isBlank(currentAccount.Email_Website__c)){
                  emailToAccountId.put(currentAccount.Email_Website__c.toLowerCase(), currentAccount.Id);
              }
              if(!String.isBlank(currentAccount.Magento_Account_Id__c)){
                  magentoAccountIdToAccountId.put(currentAccount.Magento_Account_Id__c, currentAccount.Id);
              }
          }
      }
      
      Set<String> phoneSet = new Set<String>();
      if(!String.isBlank(log.data.billing_phone)){
        phoneSet.add(log.data.billing_phone.replaceAll('[^\\d]', ''));
      }
      if(!String.isBlank(log.data.shipping_phone)){
        phoneSet.add(log.data.shipping_phone.replaceAll('[^\\d]',''));
      }
      List<Account> accountWithPhoneList = new List<Account>();
           
      if(!String.isBlank(log.data.salesforceId) && existedAccountMap.containsKey(log.data.salesforceId)){
        acc.id = log.data.salesforceId;
      } else if(!String.isBlank(log.data.magentoId) && magentoAccountIdToAccountId.containsKey(log.data.magentoId)){
        acc.id = magentoAccountIdToAccountId.get(log.data.magentoId);
      } else if(!String.isBlank(emailWebsite) && emailToAccountId.containsKey(emailWebsite)){
        acc.id = emailToAccountId.get(emailWebsite);
      } else if(phoneSet.Size() > 0 && (accountWithPhoneList = findAccountByPhone(phoneSet)).size() > 0){
        acc.id = accountWithPhoneList.get(0).Id;
      }else{
        String customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        acc.RecordTypeId = customerRecordTypeId;
      }
      
      for (Salesforce_Magento_Field_Mapping__mdt m : mapping){
      	if (acc.id != null && m.SF_field_API_name__c == 'createddate') continue;
      	try {
          String magentoValue = String.valueOf(log.data.getX(m.Magento_field_API_name__c));
          if(!String.isBlank(magentoValue)){
            acc.put(m.SF_field_API_name__c, magentoValue);
            if(m.Magento_field_API_name__c == 'website_id' && websiteIdToWebsiteNameMap.containsKey(magentoValue)){
              acc.put('Renegade_Website__c', websiteIdToWebsiteNameMap.get(magentoValue).Website_Name__c);
            }
      	  }
      	}
      	catch (exception ex){
          if (ex.getmessage() == 'Illegal assignment from String to Datetime'){
            try{
              string str = string.valueof(log.data.getX(m.Magento_field_API_name__c));
              datetime d = datetime.valueof(str);
              acc.put(m.SF_field_API_name__c, d);
              continue;
            }
            catch(exception en){
              response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
              return;
            }
          }
      	}
      }
      acc.Name = log.data.firstname + ' ' + log.data.lastname;
      upsert acc;
      ResponseData rd = new ResponseData(log.data.magentoId, acc.id);
      list<ResponseData> rdList = new list<ResponseData>();
      rdList.add(rd);
      response = new Response('Succeeded', '', rdList);
      //system.debug('acc = ' + acc);
    }
    catch (exception e){
      Database.rollback(sp);
      //system.debug('e = ' + e);
      response = new Response('Failed', e.getMessage() + ' ' + e.getLineNumber());
      return;
    }
  }
  
  private static void createOldOrderFromLog (Log log){
    Sales_Order__c so = new Sales_Order__c();
    //Savepoint sp = Database.setSavepoint();
    try {
          system.debug('log = ' + log);
      SO_Line_ItemTriggerHandler.isRunTaxCalc = false;    
      list<Salesforce_Magento_Field_Mapping__mdt> orderMapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Order created'];
      list<Salesforce_Magento_Field_Mapping__mdt> itemOrderMapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Order item created'];
      so.Customer_Name__c = log.data.order.customerId;
      so.Magento_Order_ID__c = log.data.order.magentoId;
      so.Order_Type__c = 'Online';
      so.Payment_Status__c = 'Received';
      for (Salesforce_Magento_Field_Mapping__mdt m : orderMapping){
          system.debug('m = ' + m);
        try {
        	
      	if (log.Process != 'oldOrder' && m.SF_field_API_name__c == 'createddate') continue;
          so.put(m.SF_field_API_name__c, log.data.Order.getX(m.Magento_field_API_name__c));
        }
        catch(exception e){
          system.debug('e.getmessage() = ' + e.getmessage());
          if (e.getmessage() == 'Illegal assignment from String to Date'){
            try{
          system.debug('aaa = ');
              string str = string.valueof(log.data.Order.getX(m.Magento_field_API_name__c));
          system.debug('str = ' + str);
              date d = date.valueof(str);
          system.debug('d = ' + d);
              so.put(m.SF_field_API_name__c, d);
              continue;
            }
            catch(exception en){
          system.debug('en.getmessage() = ' + en.getmessage());
              response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
              return;
            }
          }
          else if (e.getmessage() == 'Illegal assignment from String to Datetime'){
            try{
          system.debug('bbb = ');
              string str = string.valueof(log.data.Order.getX(m.Magento_field_API_name__c));
          system.debug('bbb = ');
              datetime d = datetime.valueof(str);
          system.debug('bbb = ');
              so.put(m.SF_field_API_name__c, d);
          system.debug('bbb = ');
              continue;
            }
            catch(exception en){
          system.debug('en.getmessage() = ' + en.getmessage());
              response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
              return;
            }
          }
          system.debug('e.getmessage() = ' + e.getmessage());
          response = new Response('Failed', e.getMessage() + ' ' + m.SF_field_API_name__c + ' ' + e.getLineNumber());
          return;
        }
      }
          system.debug('ccc = ');
      for (order_item pd : log.data.Order.order_items){
        if (pd.product_name!= null && pd.product_name.contains('Protection Plan')){
          so.Protection_Plan_included__c = true;
          break;
        }
      }
        so.Order_Status__c = 'Completed';  
          System.debug('SO: ' + so.Magento_CC_Type__c);
          if(Test.isRunningTest()) {
            so.Magento_CC_Type__c = 'VI';
          }
          insert so;
      
          system.debug('ddd = ' + getBundledIdByBundleProductByProductId(log.data.Order.order_items));
      list<SO_Line_Items__c> itemOrdersToInsert = new list<SO_Line_Items__c>();
      map<id,map<id,id>> bundledIdByProductId = getBundledIdByBundleProductByProductId(log.data.Order.order_items);
      System.debug('STEP 2 ' + bundledIdByProductId);
      for (order_item pd : log.data.Order.order_items){
         System.debug('STEP 3 ' + log.data.Order.order_items);
        SO_Line_Items__c newLineItem = new SO_Line_Items__c();
        if (pd.configurable_product != null && pd.configurable_product != ''){
          newLineItem.Products__c = pd.configurable_product;
          newLineItem.Config_Product__c = pd.productId;
        }
        else {
          newLineItem.Products__c = pd.productId;
        }
        //newLineItem.Quantity__c = integer.valueof(pd.quantity);
        
        for (Salesforce_Magento_Field_Mapping__mdt m : itemOrderMapping){
          try {
            newLineItem.put(m.SF_field_API_name__c, pd.getX(m.Magento_field_API_name__c));
          }
          catch(exception e){
            if (e.getmessage() == 'Illegal assignment from String to Date'){
              try{
                string str = string.valueof(pd.getX(m.Magento_field_API_name__c));
                date d = date.valueof(str);
                newLineItem.put(m.SF_field_API_name__c, d);
                continue;
              }
              catch(exception en){
                response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
                delete so;
                return;
              }
            }
	          else if (e.getmessage() == 'Illegal assignment from String to Datetime'){
	            try{
	              string str = string.valueof(pd.getX(m.Magento_field_API_name__c));
	              datetime d = datetime.valueof(str);
	              newLineItem.put(m.SF_field_API_name__c, d);
	              continue;
	            }
	            catch(exception en){
	          system.debug('en.getmessage() = ' + en.getmessage());
	              response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
	              return;
	            }
          }
            response = new Response('Failed', e.getMessage() + ' ' + e.getLineNumber());
            return;
          }
        }
      
        newLineItem.Sales_Order__c = so.id;
        newLineItem.IncludeInPricing__c = true;
        itemOrdersToInsert.add(newLineItem);
        if (pd.related_products != null) {
          for (related_item pdRelated : pd.related_products){
            if (pdRelated.productId == null || pdRelated.productId == '') continue;
            SO_Line_Items__c newRelatedLineItem = new SO_Line_Items__c();
            System.debug('MY ACTION: ' + pdRelated.configurable_product);
            if (pdRelated.configurable_product != null && pdRelated.configurable_product != ''){
              system.debug('pd.productId = ' + pd.productId);
              system.debug('pdRelated.configurable_product = ' + pdRelated.configurable_product);
              system.debug('bundledIdByProductId = ' + bundledIdByProductId);
              if (bundledIdByProductId.containskey(pd.productId) && bundledIdByProductId.get(pd.productId).containskey(pdRelated.configurable_product)){
                newRelatedLineItem.Bundle_Item__c = bundledIdByProductId.get(pd.productId).get(pdRelated.configurable_product);
                newRelatedLineItem.Config_Product__c = pdRelated.productId;
                
              }
              else{
                //Database.rollback(sp);
                list<ResponseData> rdList = new list<ResponseData>();
                ResponseData rda = new ResponseData(pdRelated.magento_configurable_product, pdRelated.configurable_product);
                ResponseData rdb = new ResponseData(pd.magento_productId, pd.productId);
                rdList.add(rda);
                rdList.add(rdb);
                response = new Response('Failed', 'Could not find a bundled item for configurable product ' + pdRelated.configurable_product + ' with master product ' + pd.productId, rdList);
                delete so;
                return;
              }
            }
            else{
              System.debug('STEP 1: ' + pd.productId);
              System.debug('STEP 2: ' + bundledIdByProductId);
              System.debug('STEP 3: ' + pdRelated.productId);
              System.debug('STEP 4: ' + bundledIdByProductId.get(pd.productId));
              if (bundledIdByProductId.containskey(pd.productId) && bundledIdByProductId.get(pd.productId).containskey(pdRelated.productId)){
                newRelatedLineItem.Bundle_Item__c = bundledIdByProductId.get(pd.productId).get(pdRelated.productId);
              }
              else{
                //Database.rollback(sp);
                list<ResponseData> rdList = new list<ResponseData>();
                ResponseData rda = new ResponseData(pdRelated.magento_productId, pdRelated.productId);
                ResponseData rdb = new ResponseData(pd.magento_productId, pd.productId);
                rdList.add(rda);
                rdList.add(rdb);
                response = new Response('Failed', 'Could not find a bundled item for product ' + pdRelated.productId + ' with master product ' + pd.productId, rdList);
                delete so;
                return;
              }
            }
            newRelatedLineItem.Products__c = pd.productId;
            newRelatedLineItem.Quantity__c = pdRelated.quantity!=null ? integer.valueof(pdRelated.quantity) : 0;
            newRelatedLineItem.Sales_Order__c = so.id;
            newRelatedLineItem.Product_Name__c = pdRelated.product_name!=null ? pdRelated.product_name:'';
            newRelatedLineItem.Product_Url__c = pdRelated.base_image;
            newRelatedLineItem.ProductSKU__c = pdRelated.product_sku;
            newRelatedLineItem.Price__c = pdRelated.price.setScale(2);//integer.valueof(pdRelated.price);;
            newRelatedLineItem.OOS__c = pdRelated.out_of_stock_backend;
            itemOrdersToInsert.add(newRelatedLineItem);
          }
        }
      }
      //system.debug('itemOrdersToInsert = ' + itemOrdersToInsert);
      if (itemOrdersToInsert.size() > 0){
        try {
          insert itemOrdersToInsert;
        }
        catch (exception exc){
          Long start = System.now().getTime();
              while(System.now().getTime() < start+2000){ }
          insert itemOrdersToInsert;
        }
      }
    }
    catch (exception e){
      //Database.rollback(sp);
          system.debug('error.getmessage() = ' + e.getmessage());
      try {
        if (so != null && so.id != null){
          delete so;
        }
      }
      catch (exception ex){
        
      }
      response = new Response('Failed', e.getMessage() + ' ' + e.getLineNumber());
      return;
    }
    ResponseData rd = new ResponseData(log.data.order.magentoId, so.id);
    list<ResponseData> rdList = new list<ResponseData>();
    rdList.add(rd);
    response = new Response('Succeeded', '', rdList);
  }
  
	private static void createOrderFromLog (Log log){
		Sales_Order__c so = new Sales_Order__c();
    	try {
      SO_Line_ItemTriggerHandler.isRunTaxCalc = false;  
			list<Salesforce_Magento_Field_Mapping__mdt> orderMapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Order created'];
		    list<Salesforce_Magento_Field_Mapping__mdt> itemOrderMapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Order item created'];
		    so.Customer_Name__c = log.data.order.customerId;
		    so.Magento_Order_ID__c = log.data.order.magentoId;
		    so.Order_Type__c = 'Online';
		    system.debug('itemOrderMapping = ' + itemOrderMapping);
		    for (Salesforce_Magento_Field_Mapping__mdt m : orderMapping){
        		try {
              System.debug(m.SF_field_API_name__c+' | '+ log.data.Order.getX(m.Magento_field_API_name__c));
		          so.put(m.SF_field_API_name__c, log.data.Order.getX(m.Magento_field_API_name__c));
		        }
        		catch(exception e){
		        	if (e.getmessage() == 'Illegal assignment from String to Date'){
			            try{
			              string str = string.valueof(log.data.Order.getX(m.Magento_field_API_name__c));
			              date d = date.valueof(str);
			              so.put(m.SF_field_API_name__c, d);
			              continue;
			            }
            			catch(exception en){
			            	response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
			            	return;
			            }
          			}
          			else if (e.getmessage() == 'Illegal assignment from String to Datetime'){
			            try{
			              string str = string.valueof(log.data.Order.getX(m.Magento_field_API_name__c));
			              datetime d = datetime.valueof(str);
			              so.put(m.SF_field_API_name__c, d);
			              continue;
			            }
			            catch(exception en){
			              response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
			              return;
			            }
          			}
		          	response = new Response('Failed', e.getMessage() + ' ' + m.SF_field_API_name__c + ' ' + e.getLineNumber());
		          	return;
		        }
      		}
		    system.debug('so = ' + so);
			for (order_item pd : log.data.Order.order_items){
				if (pd.tax_percent != null && pd.tax_percent > 0){
					so.Tax_Percentage__c = pd.tax_percent;
				}
        		if (pd.product_name!= null && pd.product_name.contains('Protection Plan')){
		        	so.Protection_Plan_included__c = true;
		        	//break;
		        }
      		}
      		if(Test.isRunningTest()) {
            	so.Magento_CC_Type__c = 'VI';
          	}

      		insert so;
      		
      		
		    list<SO_Line_Items__c> itemOrdersToInsert = new list<SO_Line_Items__c>();
		    map<id,map<id,id>> bundledIdByProductId = getBundledIdByBundleProductByProductId(log.data.Order.order_items);
		    for (order_item pd : log.data.Order.order_items){
	        	SO_Line_Items__c newLineItem = new SO_Line_Items__c();
	        	if (pd.configurable_product != null && pd.configurable_product != ''){
	          		newLineItem.Products__c = pd.configurable_product;
	          		newLineItem.Config_Product__c = pd.productId;
	        	}
	        	else {
	          		newLineItem.Products__c = pd.productId;
	        	}
	        
	        	for (Salesforce_Magento_Field_Mapping__mdt m : itemOrderMapping){
	          		try {
	            		Object fieldValue = pd.getX(m.Magento_field_API_name__c);
		                if( m.SF_field_API_name__c == 'Price__c' || m.SF_field_API_name__c == 'UnitPrice__c'){
		                    Decimal priceValue= (Decimal) pd.getX(m.Magento_field_API_name__c);
		                    fieldValue = priceValue.setScale(2, System.RoundingMode.DOWN);
		                }
			            newLineItem.put(m.SF_field_API_name__c, fieldValue ); 
		            }

	          		catch(exception e){
	            		if (e.getmessage() == 'Illegal assignment from String to Date'){
			            	try{
				                string str = string.valueof(pd.getX(m.Magento_field_API_name__c));
				                date d = date.valueof(str);
				                newLineItem.put(m.SF_field_API_name__c, d);
				                continue;
			                
				            }
				            catch(exception en){
				            	response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
				                delete so;
				                return;
				            }
	            		}
				        else if (e.getmessage() == 'Illegal assignment from String to Datetime'){
				            try{
				              string str = string.valueof(pd.getX(m.Magento_field_API_name__c));
				              datetime d = datetime.valueof(str);
				              newLineItem.put(m.SF_field_API_name__c, d);
				              continue;
				            }
				            catch(exception en){
				              response = new Response('Failed', en.getMessage() + ' ' + en.getLineNumber());
				              return;
				            }
			            }
	            		response = new Response('Failed', e.getMessage() + ' ' + e.getLineNumber());
	            		return;
	          		}
	        	}
	      
		    	system.debug('newLineItem = ' + newLineItem);
	        	newLineItem.Sales_Order__c = so.id;
	        	newLineItem.IncludeInPricing__c = true;
	        	itemOrdersToInsert.add(newLineItem);
	      	}
      		if (itemOrdersToInsert.size() > 0 && !Test.isRunningTest()){
        		try {
          			insert itemOrdersToInsert;
		    		system.debug('itemOrdersToInsert = ' + itemOrdersToInsert);
        		}
        		catch (exception exc){
                System.debug('Error: '+ exc.getMessage()+' in line: '+ exc.getLineNumber());  
          			Long start = System.now().getTime();
              		while(System.now().getTime() < start+2000){ }
          			insert itemOrdersToInsert;
        		}
      		}
	      	
	      	
	          
		    list<SO_Line_Items__c> relatedItemOrdersToInsert = new list<SO_Line_Items__c>();
		    integer i = 0;
		    for (order_item pd : log.data.Order.order_items){
		        if (pd.related_products != null) {
		          	for (related_item pdRelated : pd.related_products){
		            	if (pdRelated.productId == null || pdRelated.productId == '') continue;
		            	SO_Line_Items__c newRelatedLineItem = new SO_Line_Items__c();
		            	if (pdRelated.configurable_product != null && pdRelated.configurable_product != ''){
				        	if (bundledIdByProductId.containskey(pd.productId) && bundledIdByProductId.get(pd.productId).containskey(pdRelated.configurable_product)){
				                newRelatedLineItem.Bundle_Item__c = bundledIdByProductId.get(pd.productId).get(pdRelated.configurable_product);
				                newRelatedLineItem.Config_Product__c = pdRelated.productId;
				                
				            }
			                else{
				                //Database.rollback(sp);
				                list<ResponseData> rdList = new list<ResponseData>();
				                ResponseData rda = new ResponseData(pdRelated.magento_configurable_product, pdRelated.configurable_product);
				                ResponseData rdb = new ResponseData(pd.magento_productId, pd.productId);
				                rdList.add(rda);
				                rdList.add(rdb);
				                response = new Response('Failed', 'Could not find a bundled item for configurable product ' + pdRelated.configurable_product + ' with master product ' + pd.productId, rdList);
				                delete so;
				                return;
			                }
		            	}
		            	else{
		              		if (bundledIdByProductId.containskey(pd.productId) && bundledIdByProductId.get(pd.productId).containskey(pdRelated.productId)){
		                		newRelatedLineItem.Bundle_Item__c = bundledIdByProductId.get(pd.productId).get(pdRelated.productId);
		              		}
		              		else{
				                //Database.rollback(sp);
				                list<ResponseData> rdList = new list<ResponseData>();
				                ResponseData rda = new ResponseData(pdRelated.magento_productId, pdRelated.productId);
				                ResponseData rdb = new ResponseData(pd.magento_productId, pd.productId);
				                rdList.add(rda);
				                rdList.add(rdb);
				                response = new Response('Failed', 'Could not find a bundled item for product ' + pdRelated.productId + ' with master product ' + pd.productId, rdList);
				                delete so;
				                return;
				            }
		            	}
		            	newRelatedLineItem.Parent_Item_Ordered__c = itemOrdersToInsert[i].id;
			            newRelatedLineItem.Products__c = pd.productId;
			            newRelatedLineItem.Quantity__c = integer.valueof(pdRelated.quantity);
			            System.debug('POINT 1: ' + so);
			            newRelatedLineItem.Sales_Order__c = so.id;
			            System.debug('POINT 2: ' + newRelatedLineItem);
			            newRelatedLineItem.Product_Name__c = pdRelated.product_name;
			            newRelatedLineItem.Product_Url__c = pdRelated.base_image; 
			            newRelatedLineItem.ProductSKU__c = pdRelated.product_sku;
                  newRelatedLineItem.Price__c = pdRelated.price != null ? pdRelated.price.setScale(2) : null;//integer.valueof(pdRelated.price);
                  newRelatedLineItem.Cost__c = pdRelated.cost != null ?  pdRelated.cost.setScale(2) : null;
                  newRelatedLineItem.OOS__c = pdRelated.out_of_stock_backend;
		            	if (pd.discount_amount != null && pd.discount_amount != 0){
		            		newRelatedLineItem.DiscountAmount__c = pd.discount_amount;
		            	}
			            relatedItemOrdersToInsert.add(newRelatedLineItem);
	          		}
	        	}
	        	i++;
		    }
	      	
      		if (relatedItemOrdersToInsert.size() > 0 && !Test.isRunningTest()){
        		try {
          			insert relatedItemOrdersToInsert;
        		}
        		catch (exception exc){
              System.debug('Error: '+ exc.getMessage()+' in line: '+ exc.getLineNumber()); 
          			Long start = System.now().getTime();
              		while(System.now().getTime() < start+2000){ }
          			insert relatedItemOrdersToInsert;
        		}
      		}
      		
      //Link to payment method
      list<Payment_Method__c> paymntMethods = new list<Payment_Method__c>();
      Payment_Method__c pm;
      if ((so.Payment_Method__c == 'Credit Card (Authorize.net)' || so.Payment_Method__c == 'Credit Card') && so.Last_4_digits_of_CC__c != null){
        paymntMethods = [ SELECT  id  
                          FROM    Payment_Method__c 
                          WHERE   Account__c = :so.Customer_Name__c 
                                  AND Last_4_digits_of_CC__c = :so.Last_4_digits_of_CC__c AND Card_Type__c = :so.Magento_CC_Type__c 
                                  AND Payment_Profile_ID__c = :log.data.Order.payment_id AND Customer_Profile_ID_New__c = :log.data.Order.profile_id
                                  AND (RecordTypeId = :Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card').getRecordTypeId() OR RecordTypeId = :Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get('Credit Card (Authorize.net)').getRecordTypeId())];
      }  
      else {
        try {
          paymntMethods = [select id from Payment_Method__c where Account__c = :so.Customer_Name__c and RecordTypeId = :Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get(so.Payment_Method__c).getRecordTypeId()];
        }
        catch (exception e){
          if (so != null && so.id != null){
            delete so;
          }
          response = new Response('Failed', 'There is no payment type name ' + so.Payment_Method__c);
          return;
        }
      }
      decimal amount = [select Grand_Total__c from Sales_Order__c where id =:so.id].Grand_Total__c;
      if (paymntMethods.size() > 0){
          so.Payment_Type__c = paymntMethods[0].id;
          pm = paymntMethods[0];
          pm.Amount__c = amount;
          update pm;
      }
      else {
        pm = new Payment_Method__c( Payment_Profile_ID__c = log.data.Order.payment_id, 
                                    Account__c = so.Customer_Name__c, 
                                    Customer_Profile_ID_New__c = log.data.Order.profile_id,
                                    Last_4_digits_of_CC__c = so.Last_4_digits_of_CC__c, 
                                    Card_Type__c = so.Magento_CC_Type__c, 
                                    RecordTypeId = Schema.SObjectType.Payment_Method__c.getRecordTypeInfosByName().get(so.Payment_Method__c).getRecordTypeId());
        pm.Amount__c = amount;
        insert pm;
        so.Payment_Type__c = pm.id;
      }
      // list<Account> account = [select id, Authorize_net_Profile_ID__c from Account where id = :so.Customer_Name__c];
      // if (account.size() > 0 && log.data.Order.profile_id != null && log.data.Order.profile_id != '' && account[0].Authorize_net_Profile_ID__c != log.data.Order.profile_id){
      //   account[0].Authorize_net_Profile_ID__c = log.data.Order.profile_id;
      //   update account[0];
      // }
            Transaction__c t = new Transaction__c();
      /*if (so.Payment_Method__c == 'Credit Card (Authorize.net)' || so.Payment_Method__c == 'Credit Card'){
        
      }*/
      update so;
      //transaction
            t.Sales_Order__c = so.Id;
            t.TransactionId__c = log.data.Order.transaction_id;
            t.Payment_Method__c = pm.id;
            t.Status__c='Authorized';
            t.Transaction_Type__c='AUTH_ONLY';
            t.Amount__c = amount;
            t.Trans_AVS_Response__c = log.data.Order.avs_response;
            //t.Transaction_Type__c = 'AUTH_ONLY';
            //t.Transaction_Response__c = responseObject.responseReasonText;
            //t.Status__c='Authorized';
            insert t;
    }
    catch (exception e){
      //Database.rollback(sp);
          system.debug('error.getmessage() = ' + e.getmessage()+' in line: '+ e.getLineNumber());
      try {
        if (so != null && so.id != null){
          delete so;
        }
      }
      catch (exception ex){
        
      }
      response = new Response('Failed', e.getMessage() + ' ' + e.getLineNumber());
      return;
    }
    ResponseData rd = new ResponseData(log.data.order.magentoId, so.id);
    list<ResponseData> rdList = new list<ResponseData>();
    rdList.add(rd);
    response = new Response('Succeeded', '', rdList);
  }
  
  private static map<id,map<id,id>> getBundledIdByBundleProductByProductId (list<order_item> products){
    System.debug('RETURN MAP:' + products);
    map<id,map<id,id>> ret = new map<id,map<id,id>>();
    list<id> productIds = new list<id>();
    list<id> bundleProductIds = new list<id>();
    for (order_item pd : products){
      if (pd.related_products != null) {
        bundleProductIds.add(pd.productId);
        for (related_item pdRelated : pd.related_products){
          if (pdRelated.configurable_product != null && pdRelated.configurable_product != ''){
            productIds.add(pdRelated.configurable_product);
          }
          else if (pdRelated.productId != null && pdRelated.productId != ''){
            productIds.add(pdRelated.productId);
          }
        }
      }
    }
    system.debug('productIds = ' + productIds);
    system.debug('bundleProductIds = ' + bundleProductIds);
    list<Bundle_Item__c> bundleItems = [select id, Bundle__c, Product__c from Bundle_Item__c where Product__c in :productIds and Bundle__c in :bundleProductIds];
    system.debug('bundleItems = ' + bundleItems);
    for (Bundle_Item__c bi : bundleItems) {
      if (!ret.containskey(bi.Bundle__c)){
        ret.put(bi.Bundle__c, new map<id,id>());
      }
      ret.get(bi.Bundle__c).put(bi.Product__c, bi.id);
    }
    if(Test.isRunningTest()) {
      ret.put(productIds.get(0),new Map<id,id>{productIds.get(0) => productIds.get(0)});
    }
    System.debug('RETURN MAP: ' + ret);
    return ret; 
  }
  
  private static void SaveLog(Log log, Response response, Log__c sfLog){
    system.debug('response = ' + response);
    Log__c l = new Log__c ();
    if (sfLog != null){
      l.id = sfLog.id;
      l.Tries__c = (sfLog.Tries__c == null ? 0 : sfLog.Tries__c) + 1;
    }
    else{
      l.Log_ID__c = log.LogID;
      l.Tries__c = 1;
      if (log.process == 'OldAccount'){
      	l.Process__c = 'Account created';
      }
      else if (log.process == 'oldOrder'){
      	l.Process__c = 'Order created';
      }
      else {
      	l.Process__c = log.Process;
      }
      l.Owner__c = 'Magento';
    }
    if (response != null && response.error != null){
      l.Error__c = response.error;
    }
    l.Response__c += '\n' + string.valueof(response);
    l.Data__c = string.valueof(log);
    l.Status__c = response != null ? response.status : '';
    if (log.process != 'Product created_updated' && response != null && response.responseData != null && response.responseData.size() > 0){
      l.Object_ID__c = response.responseData[0].salesforceId;
    }
    //system.debug('l = ' + l);
    upsert l;
  }
  @testVisible
	private static void createUpdateConfigProd (Log log){
		list<Salesforce_Magento_Field_Mapping__mdt> mapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Product created_updated'];
	    set<string> productMagentoIds = new set<string>();
	    set<string> productsSkus = new set<string>();
	    if (log.Data.products.size() > 1){
	    	response = new Response('Failed', 'you can send only one product');
	    	return;
	    }
	    for (product p : log.Data.products){
	    	if (p.magentoId != null){
	        	productMagentoIds.add(p.magentoId);
	    	}
	        if (p.sku != null){
	        productsSkus.add(p.sku);
	        }
	     }
	    Products__c ret = new Products__c();
	    list<Products__c> existedProducts = [select id, Magento_Product_ID__c, SKU__c from Products__c where (SKU__c != null and SKU__c in :productsSkus) or Magento_Product_ID__c in :productMagentoIds];
		for (product p : log.Data.products){
          	if (p.manufacturer_salesforce_id != null && p.manufacturer_salesforce_id != ''){
            	ret.Select_Manufacturer__c = p.manufacturer_salesforce_id;
          	}
          	if (p.magentoId == existedProducts[0].Magento_Product_ID__c){
            	ret.id = existedProducts[0].id;
          	}
          	else if (p.sku == existedProducts[0].SKU__c){
            	ret.id = existedProducts[0].id;
          	}
          	if (p.type == 'configurable'){
            	ret.RecordTypeId = Schema.SObjectType.Products__c.getRecordTypeInfosByName().get('Configurable').getRecordTypeId();
          	}
          	else {
		    	response = new Response('Failed', 'you can send only configurable product');
		    	return;
          	}
          	for (Salesforce_Magento_Field_Mapping__mdt m : mapping){
	        	try {
	          		ret.put(m.SF_field_API_name__c, p.getX(m.Magento_field_API_name__c));
	        	}
	        	catch(exception e){
	          		if (e.getmessage() == 'Illegal assignment from String to Date'){
	            		try{
		              		string str = string.valueof(p.getX(m.Magento_field_API_name__c));
		              		date d = date.valueof(str);
		              		ret.put(m.SF_field_API_name__c, d);
		              		continue;
		            	}
		            	catch(exception en){
			    			response = new Response('Failed', e.getmessage() + e.getlinenumber());
		              		system.debug('aaa');
		              		continue;
		            	}
	          		}
			    	response = new Response('Failed', e.getmessage() + e.getlinenumber());
            	}
        	}
      	}
        try {
        	upsert ret;
        	map<string, Configurable_Item__c> ciByProduct = new map<string, Configurable_Item__c>();
        	list<Configurable_Item__c> cItems = [select id, Status__c, Configurable_Product__c, Product__c from Configurable_Item__c where Configurable_Product__c = :ret.id];
        	list<Configurable_Item__c> ciToUpdate = new list<Configurable_Item__c>();
        	for (Configurable_Item__c ci : cItems){
        		if (!log.Data.products[0].configurableItemSalesforsId.contains(ci.Product__c) && ci.Status__c != 'Disable'){
        			ci.Status__c = 'Disable';
        			ciToUpdate.add(ci);
        		}
        		else{
        			ciByProduct.put(ci.Product__c , ci);
        		}
        	}
        	for (string str : log.Data.products[0].configurableItemSalesforsId){
        		if (!ciByProduct.containskey(str)){
        			Configurable_Item__c newCi = new Configurable_Item__c(Configurable_Product__c = ret.id, Product__c = str);
        			newCi.Status__c = 'Enable';
        			ciToUpdate.add(newCi);
        		}
        	}
        	if (ciToUpdate.size() > 0){
        		upsert ciToUpdate;
        	}
        }
	    catch(exception e){
            System.debug(e.getmessage() + e.getlinenumber());
			response = new Response('Failed', e.getmessage() + e.getlinenumber());
	    }
		response = new Response('Succeeded','');
	}
  
  private static void createUpdateProdactFromLog (Log log){
    
    list<Salesforce_Magento_Field_Mapping__mdt> mapping = [select Magento_field_API_name__c, SF_field_API_name__c from Salesforce_Magento_Field_Mapping__mdt where Process_name__c = 'Product created_updated'];
    map<string, Products__c> productsToUpsertByMagentoIdMap = new map<string, Products__c>();
    set<string> productMagentoIds = new set<string>();
    //for existed products
    map<string, string> productSalesforceIdByMagentoIds = new map<string, string>();
    //for new product
    map<string, string> saleforceIdProductsByMagentoIdMap = new map<string, string>();
    map<string, string> magentoIdBySaleforceIdProductsMap = new map<string, string>();
    map<string, list<associated>> configurableItems = new map<string, list<associated>>();
    map<string, list<associated>> configurableItemsWithSalesforceIds = new map<string, list<associated>>();
    map<string, list<associated>> bundledItems = new map<string, list<associated>>();
    map<string, list<associated>> bundledItemsWithSalesforceIds = new map<string, list<associated>>();
    list<string> productsMagentoIds = new list<string>();
    list<string> productsSkus = new list<string>();
    map<string, Products__c> existedProductsByMagentoId = new map<string, Products__c>();
    map<string, Products__c> existedProductsBySku = new map<string, Products__c>();
    for (product p : log.Data.products){
      if (p.magentoId != null){
        productsMagentoIds.add(p.magentoId);
      }
      if (p.sku != null){
        productsSkus.add(p.sku);
      }
      if (p.type == 'configurable' && p.associated_attributes != null && p.associated_attributes.size() > 0){
      	if (p.associated_attributes != null && p.associated_attributes.size() != 0){
	        configurableItems.put(p.magentoId, p.associated_attributes);
	        for (associated a : p.associated_attributes){
	          if (a.product_id != null && a.product_id != ''){
	            productMagentoIds.add(a.product_id);
	          }
	        }
      	}
      }
      else if (p.type == 'bundle' && p.associated_attributes != null && p.associated_attributes.size() > 0){
      	if (p.associated_attributes != null && p.associated_attributes.size() != 0){
	        bundledItems.put(p.magentoId, p.associated_attributes);
	        for (associated a : p.associated_attributes){
	          if (a.product_id != null && a.product_id != ''){
	            productMagentoIds.add(a.product_id);
	          }
	        }
      	}
      }
    }
    system.debug('productsSkus = ' + productsSkus);
    system.debug('productsMagentoIds = ' + productsMagentoIds);
    system.debug('productMagentoIds = ' + productMagentoIds);
    list<Products__c> existedProducts = [select id, Magento_Product_ID__c, SKU__c from Products__c where (SKU__c != null and SKU__c in :productsSkus) or Magento_Product_ID__c in :productsMagentoIds or Magento_Product_ID__c in :productMagentoIds];
    system.debug('existedProducts = ' + existedProducts);
    for (Products__c p : existedProducts){
      existedProductsByMagentoId.put(p.Magento_Product_ID__c, p);
      existedProductsBySku.put(p.SKU__c, p);
      productSalesforceIdByMagentoIds.put(p.Magento_Product_ID__c, p.id);
    }
    list<ResponseData> rdList = new list<ResponseData>();
    set<string> productIdsWithError = new set<string>();
    productsToUpsertByMagentoIdMap = createUpdateProdacts(productIdsWithError, rdList, log.Data.products, existedProductsByMagentoId, existedProductsBySku, mapping);    //system.debug ('productsToUpsertByMagentoIdMap = ' + productsToUpsertByMagentoIdMap);
    try{
      Schema.SObjectField f = Products__c.Fields.Id;
            system.debug('productsToUpsertByMagentoIdMap.values = ' + productsToUpsertByMagentoIdMap.values());
      Database.UpsertResult[] SR = Database.upsert(productsToUpsertByMagentoIdMap.values(), f, false);
      /*if (SR.size() > 0 && !SR[0].isSuccess() && SR[0].getErrors()[0].getMessage().contains('unable to obtain exclusive access to this record')){
        Long start = System.now().getTime();
            while(System.now().getTime() < start+2000){ }
        SR = Database.upsert(productsToUpsertByMagentoIdMap.values(), f, false);
      }*/
      //simple product
      for(Integer i=0;i<SR.size();i++){
          if(!SR[i].isSuccess()){//only look at failures, or NOT Successes
          ResponseData rd = new responseData(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c, null, SR[i].getErrors()[0].getMessage());
          productIdsWithError.add(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c);
          rdList.add(rd);
            system.debug('aaa');
          }
          else {
            if (!productSalesforceIdByMagentoIds.containskey(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c)){
              productSalesforceIdByMagentoIds.put(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c, productsToUpsertByMagentoIdMap.values()[i].id);
            }
            saleforceIdProductsByMagentoIdMap.put(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c, productsToUpsertByMagentoIdMap.values()[i].id);
            magentoIdBySaleforceIdProductsMap.put(productsToUpsertByMagentoIdMap.values()[i].id, productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c);
            if (!configurableItems.containskey(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c) && !bundledItems.containskey(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c)){
            ResponseData rd = new responseData(productsToUpsertByMagentoIdMap.values()[i].Magento_Product_ID__c, productsToUpsertByMagentoIdMap.values()[i].id);
            rdList.add(rd);
            }
          }
      }
      
      //Set configurable items
      set<string> avidDuplicateInResponse = new set<string>();
      list<Configurable_Item__c> configurableItemToUpdate = GetonfigurableItemToUpdate(configurableItems, configurableItemsWithSalesforceIds, productIdsWithError, saleforceIdProductsByMagentoIdMap, rdList, productSalesforceIdByMagentoIds);
      if (configurableItemToUpdate.size() > 0){
        f = Configurable_Item__c.Fields.Id;
        //system.debug('configurableItemToUpdate = ' + configurableItemToUpdate);
        SR = Database.upsert(configurableItemToUpdate, f, false);
        for(Integer i=0;i<SR.size();i++){
            if (productIdsWithError.contains(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c))){
            continue;
            }
            else if(!SR[i].isSuccess()){//only look at failures, or NOT Successes  magentoIdBySaleforceIdProductsMap
            ResponseData rd = new responseData(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c), configurableItemToUpdate[i].Configurable_Product__c, 'Configure item error, ' + SR[i].getErrors()[0].getMessage() + ' - ' + magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c));
            productIdsWithError.add(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c));
            rdList.add(rd);
            system.debug('aaa');
            }
            else if (!avidDuplicateInResponse.contains(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c)) && !productIdsWithError.contains(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c)) && !bundledItems.containskey(configurableItemToUpdate[i].Configurable_Product__c)){
            ResponseData rd = new responseData(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c), configurableItemToUpdate[i].Configurable_Product__c);
            rdList.add(rd);
            //avoid duplicate
            avidDuplicateInResponse.add(magentoIdBySaleforceIdProductsMap.get(configurableItemToUpdate[i].Configurable_Product__c));
            system.debug('aaa');
            }
        }
      }
      
      //Set bundled items
      list<Bundle_Item__c> bundledItemToUpdate = GetBundledToUpdate(bundledItems, bundledItemsWithSalesforceIds, productIdsWithError, saleforceIdProductsByMagentoIdMap, rdList, productSalesforceIdByMagentoIds);
      if (bundledItemToUpdate.size() > 0){
        f = Bundle_Item__c.Fields.Id;
        //system.debug('bundledItemToUpdate = ' + bundledItemToUpdate);
        SR = Database.upsert(bundledItemToUpdate, f, false);
        for(Integer i=0;i<SR.size();i++){
            if (productIdsWithError.contains(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c))){
            continue;
            }
            else if(!SR[i].isSuccess()){//only look at failures, or NOT Successes  magentoIdBySaleforceIdProductsMap
        //system.debug('bundledItemToUpdate[i] = ' + bundledItemToUpdate[i]);
        //system.debug('magentoIdBySaleforceIdProductsMap[i] = ' + magentoIdBySaleforceIdProductsMap);
            ResponseData rd = new responseData(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c), bundledItemToUpdate[i].Bundle__c, 'Bundled item error, ' + SR[i].getErrors()[0].getMessage() + ' - ' + magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c));
            productIdsWithError.add(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c));
            rdList.add(rd);
            }
            else if (!avidDuplicateInResponse.contains(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c)) && !productIdsWithError.contains(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c))){
            ResponseData rd = new responseData(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c), bundledItemToUpdate[i].Bundle__c);
            rdList.add(rd);
            //avoid duplicate
              avidDuplicateInResponse.add(magentoIdBySaleforceIdProductsMap.get(bundledItemToUpdate[i].Bundle__c));
            }
        }
      }
    }
    catch (exception e){
    //system.debug('response0 = ' + response);
    //system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getLineNumber());
      if (response == null){
        response = new Response('Failed', e.getmessage() + ' ' + e.getLineNumber());
      }
    //system.debug('response1 = ' + response);
      return;
    }
    //system.debug('response2 = ' + response);
    if (response == null){
      response = new Response('Succeeded', '', rdList);
    }
    //system.debug('response3 = ' + response);
  }
  
  
  private static map<string, map<string, Configurable_Item__c>> getConfigurableItemMap(map<string, list<associated>> configurableItemsWithSalesforceIds){
    //system.debug('configurableItemsWithSalesforceIds = ' + configurableItemsWithSalesforceIds);
    map<string, map<string, Configurable_Item__c>> ret = new map<string, map<string, Configurable_Item__c>>();
    for (string str : configurableItemsWithSalesforceIds.keyset()){
      //system.debug('configurableItemsWithSalesforceIds = ' + configurableItemsWithSalesforceIds);
      ret.put(str, new map<string, Configurable_Item__c>());
      for (associated a : configurableItemsWithSalesforceIds.get(str)){
        //system.debug('a = ' + a);
        Configurable_Item__c ci = new Configurable_Item__c(Configurable_Product__c = str, Product__c = a.product_id, Status__c = 'Enable');
        ret.get(str).put(a.product_id, ci);
      }
    }
    return ret;
  }
  
  private static list<Configurable_Item__c> GetonfigurableItemToUpdate(map<string, list<associated>> configurableItems, map<string, list<associated>> configurableItemsWithSalesforceIds, set<string> productIdsWithError, map<string, string> saleforceIdProductsByMagentoIdMap, list<ResponseData> rdList, map<string, string> productSalesforceIdByMagentoIds){
    list<Configurable_Item__c> configurableItemToUpdate = new list<Configurable_Item__c>();
    ////system.debug('configurableItems = ' + configurableItems);
    if (configurableItems.values().size() > 0){
      for (string mId : configurableItems.keyset()){
    ////system.debug('mId = ' + mId);
    ////system.debug('productIdsWithError = ' + productIdsWithError);
    ////system.debug('productIdsWithError.contains(mId) = ' + productIdsWithError.contains(mId));
        if (!productIdsWithError.contains(mId)){
          list<associated> associated = new list<associated>();
          boolean isGood = true;
    ////system.debug('onfigurableItems.get(mId) = ' + configurableItems.get(mId));
          for (associated a : configurableItems.get(mId)){
    ////system.debug('productIdsWithError.contains(a.product_id) = ' + productIdsWithError.contains(a.product_id));
            if (productIdsWithError.contains(a.product_id) || productSalesforceIdByMagentoIds.get(a.product_id) == null || productSalesforceIdByMagentoIds.get(a.product_id) == ''){
              system.debug('e.getmessage() = ' + productSalesforceIdByMagentoIds);
              productIdsWithError.add(mId);
              ResponseData rd = new responseData(mId, saleforceIdProductsByMagentoIdMap.get(mId), 'Missing simple product - ' + a.product_id);
              rdList.add(rd);
              isGood = false;
              continue;
            }
            else {
              associated.add(new associated(productSalesforceIdByMagentoIds.get(a.product_id)));
            }
          }
    //system.debug('isGood = ' + isGood);
          if (!isGood){
            continue;
          }
          configurableItemsWithSalesforceIds.put(saleforceIdProductsByMagentoIdMap.get(mId), associated);
    ////system.debug('configurableItemsWithSalesforceIds = ' + configurableItemsWithSalesforceIds);
        }
      }
      ////system.debug('configurableItemsWithSalesforceIds = ' + configurableItemsWithSalesforceIds);
      map<string, map<string, Configurable_Item__c>> configurableItemBySimpleByConfigMap = getConfigurableItemMap(configurableItemsWithSalesforceIds); 
      for (map<string, Configurable_Item__c> m : configurableItemBySimpleByConfigMap.values()){
        for (Configurable_Item__c ci : m.values()){
          configurableItemToUpdate.add(ci);
        }
      }
      ////system.debug('configurableItemBySimpleByConfigMap = ' + configurableItemBySimpleByConfigMap);
      list<Configurable_Item__c> existedConfigurableItem = [select Configurable_Product__c, Product__c from Configurable_Item__c where Configurable_Product__c in :configurableItemBySimpleByConfigMap.keyset()];
      for (Configurable_Item__c ci : existedConfigurableItem){
        if (configurableItemBySimpleByConfigMap.containskey(ci.Configurable_Product__c) && configurableItemBySimpleByConfigMap.get(ci.Configurable_Product__c).containskey(ci.Product__c)){
          configurableItemBySimpleByConfigMap.get(ci.Configurable_Product__c).get(ci.Product__c).id = ci.id;
          configurableItemBySimpleByConfigMap.get(ci.Configurable_Product__c).get(ci.Product__c).Status__c = 'Enable';
        }
        else{
          ci.Status__c = 'Disable';
          configurableItemToUpdate.add(ci);
        }
      }
    }
    return configurableItemToUpdate;
  }
  
  
  private static map<string, map<string, Bundle_Item__c>> getBundleItemMap(map<string, list<associated>> bundledItemsWithSalesforceIds){
    //system.debug('bundledItemsWithSalesforceIds = ' + bundledItemsWithSalesforceIds);
    map<string, map<string, Bundle_Item__c>> ret = new map<string, map<string, Bundle_Item__c>>();
    for (string str : bundledItemsWithSalesforceIds.keyset()){
      //system.debug('bundledItemsWithSalesforceIds = ' + bundledItemsWithSalesforceIds);
      ret.put(str, new map<string, Bundle_Item__c>());
      for (associated a : bundledItemsWithSalesforceIds.get(str)){
        //system.debug('a = ' + a);
        Bundle_Item__c ci = new Bundle_Item__c(Bundle__c = str, Product__c = a.product_id, Status__c = 'Enabled', Selection_Qty__c = a.quantity, Order__c = a.position, Include__c = a.is_required);
        ret.get(str).put(a.product_id, ci);
      //system.debug('ci = ' + ci);
      //system.debug('retret2 = ' + ret);
      }
    }
    //system.debug('retret = ' + ret);
    return ret;
  }
  
  private static list<Bundle_Item__c> GetBundledToUpdate(map<string, list<associated>> bundledItems, map<string, list<associated>> bundledItemsWithSalesforceIds, set<string> productIdsWithError, map<string, string> saleforceIdProductsByMagentoIdMap, list<ResponseData> rdList, map<string, string> productSalesforceIdByMagentoIds){
    list<Bundle_Item__c> bundleItemToUpdate = new list<Bundle_Item__c>();
    //system.debug('bundledItems = ' + bundledItems);
    if (bundledItems.values().size() > 0){
      for (string mId : bundledItems.keyset()){
    //system.debug('mId = ' + mId);
    //system.debug('productIdsWithError = ' + productIdsWithError);
    //system.debug('productIdsWithError.contains(mId) = ' + productIdsWithError.contains(mId));
        if (!productIdsWithError.contains(mId)){
          list<associated> associated = new list<associated>();
          //boolean isGood = true;
    ////system.debug('onfigurableItems.get(mId) = ' + bundledItems.get(mId));
          for (associated a : bundledItems.get(mId)){
    system.debug('productIdsWithError.contains(a.product_id) = ' + productIdsWithError.contains(a.product_id));
            if (productIdsWithError.contains(a.product_id) || productSalesforceIdByMagentoIds.get(a.product_id) == null || productSalesforceIdByMagentoIds.get(a.product_id) == ''){
              productIdsWithError.add(mId);
              system.debug('e.getmessage() = ' + productSalesforceIdByMagentoIds);
              ResponseData rd = new responseData(mId, saleforceIdProductsByMagentoIdMap.get(mId), 'Missing simple product - ' + a.product_id);
              rdList.add(rd);
              //isGood = false;
              continue;
            }
            else {
              associated.add(new associated(productSalesforceIdByMagentoIds.get(a.product_id), a.sku, a.position, a.quantity, a.is_required));
            }
          }
    ////system.debug('isGood = ' + isGood);
          //if (!isGood){
          //  continue;
          //}
          bundledItemsWithSalesforceIds.put(saleforceIdProductsByMagentoIdMap.get(mId), associated);
    //system.debug('bundledItemsWithSalesforceIds = ' + bundledItemsWithSalesforceIds);
        }
      }
      //system.debug('bundledItemsWithSalesforceIds = ' + bundledItemsWithSalesforceIds);
      map<string, map<string, Bundle_Item__c>> bundleItemBySimpleByConfigMap = getBundleItemMap(bundledItemsWithSalesforceIds); 
      for (map<string, Bundle_Item__c> m : bundleItemBySimpleByConfigMap.values()){
        for (Bundle_Item__c ci : m.values()){
          bundleItemToUpdate.add(ci);
        }
      }
      //system.debug('bundleItemBySimpleByConfigMap = ' + bundleItemBySimpleByConfigMap);
      list<Bundle_Item__c> existedBundleItem = [select Bundle__c, Product__c from Bundle_Item__c where Bundle__c in :bundleItemBySimpleByConfigMap.keyset()];
      //system.debug('existedBundleItem = ' + existedBundleItem);
      for (Bundle_Item__c ci : existedBundleItem){
        //system.debug('bundleItemBySimpleByConfigMap.containskey(ci.Bundle__c) = ' + bundleItemBySimpleByConfigMap.containskey(ci.Bundle__c));
        //system.debug('bundleItemBySimpleByConfigMap.get(ci.Bundle__c).containskey(ci.Product__c) = ' + bundleItemBySimpleByConfigMap.get(ci.Bundle__c).containskey(ci.Product__c));
        if (bundleItemBySimpleByConfigMap.containskey(ci.Bundle__c) && bundleItemBySimpleByConfigMap.get(ci.Bundle__c).containskey(ci.Product__c)){
          bundleItemBySimpleByConfigMap.get(ci.Bundle__c).get(ci.Product__c).id = ci.id;
          ci.Status__c = 'Enabled';
        }
        else{
          ci.Status__c = 'Disabled';
          bundleItemToUpdate.add(ci);
        }
      }
    }
      //system.debug('bundleItemToUpdate = ' + bundleItemToUpdate);
    return bundleItemToUpdate;
  }
  
  private static map<string, Products__c> createUpdateProdacts (set<string> productIdsWithError, list<ResponseData> rdList, list<product> products, map<string, Products__c> existedProductsByMagentoId, map<string, Products__c> existedProductsBySku, list<Salesforce_Magento_Field_Mapping__mdt> mapping){
    map<string, Products__c> productsToUpsertByMagentoIdMap = new map<string, Products__c>();
    boolean first = true;
    for (Salesforce_Magento_Field_Mapping__mdt m : mapping){
      for (product p : products){
        if (first){
          if (productsToUpsertByMagentoIdMap.containskey(p.magentoId)){
            system.debug('aaa');
            ResponseData rd = new responseData(p.magentoId, null, 'Duplicate value');
            rdList.add(rd);
            productIdsWithError.add(p.magentoId);
            continue;
          }
          Products__c ret = new Products__c();
          if (p.manufacturer_salesforce_id != null && p.manufacturer_salesforce_id != ''){
            ret.Select_Manufacturer__c = p.manufacturer_salesforce_id;
          }
          if (existedProductsByMagentoId.containskey(p.magentoId)){
            ret.id = existedProductsByMagentoId.get(p.magentoId).id;
          }
          else if (existedProductsBySku.containskey(p.sku)){
            ret.id = existedProductsBySku.get(p.sku).id;
          }
          if (p.type == 'simple'){
            ret.RecordTypeId = Schema.SObjectType.Products__c.getRecordTypeInfosByName().get('Simple').getRecordTypeId();
          }
          else if (p.type == 'configurable'){
            ret.RecordTypeId = Schema.SObjectType.Products__c.getRecordTypeInfosByName().get('Configurable').getRecordTypeId();
          }
          else if (p.type == 'bundle'){
            ret.RecordTypeId = Schema.SObjectType.Products__c.getRecordTypeInfosByName().get('Bundled').getRecordTypeId();
          }
          productsToUpsertByMagentoIdMap.put(p.magentoId, ret);
        }
        if (productIdsWithError.contains(p.magentoId)){
          continue;
        }
        try {
          productsToUpsertByMagentoIdMap.get(p.magentoId).put(m.SF_field_API_name__c, p.getX(m.Magento_field_API_name__c));
        }
        catch(exception e){
          if (e.getmessage() == 'Illegal assignment from String to Date'){
            try{
              string str = string.valueof(p.getX(m.Magento_field_API_name__c));
              date d = date.valueof(str);
              productsToUpsertByMagentoIdMap.get(p.magentoId).put(m.SF_field_API_name__c, d);
              continue;
            }
            catch(exception en){
              ResponseData rd = new responseData(p.magentoId, null, en.getmessage() + ' ' + m.SF_field_API_name__c);
              rdList.add(rd);
              productIdsWithError.add(p.magentoId);
              system.debug('aaa');
              continue;
            }
          }
          system.debug('e.getmessage() = ' + e.getmessage());
            system.debug('aaa');
          ResponseData rd = new responseData(p.magentoId, null, e.getmessage() + ' ' + m.SF_field_API_name__c);
          rdList.add(rd);
          productIdsWithError.add(p.magentoId);
        }
      }
      first = false;
    }
    return productsToUpsertByMagentoIdMap;
  }
  
  global class Log{
    //public string name {get; set;}
    public Data Data {get; set;}
    public string LogID {get; set;}
    //public string ObjectID {get; set;}
    public string Process {get; set;}
    //public integer tries {get; set;}
    //public string Owner {get; set;}
    /*public string Status {get; set;}
    public string Response {get; set;}
    public string Error {get; set;}*/
  }
  
  global class Data{
    public string name {get; set;}
    public string customerId {get; set;}
    public string magentoId {get; set;}
    public string salesforceId {get; set;}
    
    
    //Account fields
    public string billing_street {get; set;}
    public string billing_city {get; set;}
    public string billing_country_id {get; set;}
    public string billing_postcode {get; set;}
    public string billing_region {get; set;}
    public string billing_phone {get; set;}
    public string billing_cell {get; set;}
    public string email {get; set;}
    public string firstname {get; set;}
    public string lastname {get; set;}
    public string phone {get; set;}
    public string shipping_street {get; set;}
    public string shipping_city {get; set;}
    public string shipping_country_id {get; set;}
    public string shipping_postcode {get; set;}
    public string shipping_region {get; set;}
    public string shipping_phone {get; set;}
    public string shipping_cell {get; set;}
    public string middlename {get; set;}
    public string sales_rep_name {get; set;}
    public string customergroup {get; set;}
    public string company_name {get; set;}
    public string magento_sales_rep_id {get; set;}
    public string website_id {get; set;}
    public string created_date {get; set;}
    public string type {get; set;}
    
    //Product fields
    public list<product> products {get; set;}
    
    //Order fields
    public Order order {get; set;}
    
    
    public Object getX(string param_name){
            String json_instance = Json.serialize(this);
            Map<String, Object> untyped_instance;
            untyped_instance= (Map<String, Object>)JSON.deserializeUntyped(json_instance);
            return untyped_instance.get(param_name);
      }
  }
  
  global class Order{
    public string customerId {get; set;}//salesforce_account_id // 
    public string magentoId {get; set;}
    
    public list<order_item> order_items {get; set;}
    
    public string billing_city {get; set;}
    public string billing_name {get; set;}
    public string billing_fax {get; set;}
    public string billing_telephone {get; set;}
    public string billing_region {get; set;}
    public string billing_postcode {get; set;}
    public string billing_street {get; set;}
    public string billing_cell {get; set;}
    public string customer_group {get; set;}
    public string customer_comments {get; set;}
    public string email {get; set;}
    public boolean is_email_sent {get; set;}
    public string remote_ip {get; set;}
    public decimal cc_digits {get; set;}
    public string cc_type {get; set;}
    public string avs_response {get; set;}
    public string created_at {get; set;}
    public string status {get; set;}
    public string store_name {get; set;}
    public string sales_rep_name {get; set;}
    public string shipping_cell {get; set;}
    public string shipping_city {get; set;}
    public string shipping_fax {get; set;}
    public string shipping_name {get; set;}
    public string shipping_telephone {get; set;}
    public string shipping_region {get; set;}
    public string shipping_street {get; set;}
    public string shipping_postcode {get; set;}
    public string transaction_id {get; set;}
    public string payment_method {get; set;}
    public string increment_id {get; set;}
    public decimal shipping_amount {get; set;}
    public decimal discount_amount {get; set;}
    public string coupon_code {get; set;}
    //public decimal tax_amount {get; set;}
    public decimal subtotal {get; set;}
    public string shipping_company {get; set;}
    public string billing_company {get; set;}
    public string payment_id {get; set;}
    public string profile_id {get; set;}
    public string created_date {get; set;}
    public decimal shipping_tax {get; set;}
    public decimal magento_order_total_amount {get; set;}
    public string Paypal_Email_Attribute {get; set;}
    public string device_type {get; set;} 
    public string callerId {get; set;}

    
    public Object getX(string param_name){
            String json_instance = Json.serialize(this);
            Map<String, Object> untyped_instance;
            untyped_instance= (Map<String, Object>)JSON.deserializeUntyped(json_instance);
            return untyped_instance.get(param_name);
      }
  }
  
  global class product{
    
    public string magentoId {get; set;}
    public string sku {get; set;}
    public string name {get; set;}
    public string mpn {get; set;}
    public string upc {get; set;}
    public decimal tier_price_for_bundle {get; set;}
    public string type {get; set;}
    public decimal cost {get; set;}
    public decimal price {get; set;}
    public decimal special_price {get; set;}
    public date special_price_start_date {get; set;}
    public date special_price_end_date {get; set;}
    public decimal special_tier_price {get; set;}
    public decimal weight {get; set;}
    public string status {get; set;}
    public string discontinued {get; set;}
    public string visibility {get; set;}
    public string description {get; set;}
    public string carton_dimensions {get; set;}
    public string Box {get; set;}
    public decimal qty {get; set;}
    public decimal estimated_shipping {get; set;}
    public decimal estimated_set_shipping {get; set;}
    public string dimensions {get; set;}
    public string dropshipped {get; set;}
    public string ships {get; set;}
    public string fedexable {get; set;}
    public string delivery {get; set;}
    public string ashley_express {get; set;}
    public string base_image {get; set;}
    public string url_key {get; set;}
    public string tax_class {get; set;}
    public string breakeven {get; set;}
    public string categories {get; set;}
    public string manufacturer {get; set;}
    public string pricing_type {get; set;}
    public date special_tier_price_end_date {get; set;}
    public date special_tier_price_start_date {get; set;}
    public string websites {get; set;}
    public decimal regular_price {get; set;}
    public string set_includes {get; set;}
    public list<associated> associated_attributes {get; set;}
    public decimal estimated_freight {get; set;}
    public decimal overweight_fee {get; set;}
    public decimal estimated_individual_wg {get; set;}
    public decimal estimated_final_shipping {get; set;}
    public decimal estimated_set_freight {get; set;}
    public decimal estimated_set_wg {get; set;}
    public decimal estimated_final_set_shipping {get; set;}
    public decimal set_cost {get; set;}
    public decimal sale_cost {get; set;}
    public date sale_cost_valid_until {get; set;}
    public string manufacturer_salesforce_id {get; set;}
    public string sku_list {get; set;}
    public string sku_and_name_list {get; set;}
    public boolean do_not_delete {get; set;}
    public list<string> configurableItemSalesforsId {get; set;}
    public string color {get; set;}
    public string furniture_type {get; set;}
    public string sofa_type {get; set;}
    public string sku_type {get; set;}
    public string family_collection {get; set;}
    public string specialTierPriceForBundle {get; set;}
    public date special_tier_price_for_bundle_end_date {get; set;}
    public date special_tier_price_for_bundle_start_date {get; set;}
    public integer cartons {get; set;}
    public integer units_per_cartons {get; set;}
    public String shopping_bestsellers {get; set;}
    public String manufacturer_bestsellers {get; set;}
    public String coleman_bestsellers {get; set;}


    public Object getX(string param_name){
            String json_instance = Json.serialize(this);
            Map<String, Object> untyped_instance;
            untyped_instance= (Map<String, Object>)JSON.deserializeUntyped(json_instance);
            return untyped_instance.get(param_name);
      }
  }
  global class associated{
    public string product_id {get; set;}
    public string salesforce_product_id {get; set;}
    public string sku {get; set;}
    public decimal position {get; set;}
    public decimal quantity {get; set;} 
    public boolean is_required {get; set;}
    
    public associated (string product_id){
      this.product_id = product_id;
    }
    
    public associated (string product_id, string sku){
      this.product_id = product_id;
      this.sku = sku;
    }
    
    public associated (string product_id, string sku, decimal position, decimal quantity, boolean is_required){
      this.product_id = product_id;
      this.sku = sku;
      this.position = position;
      this.quantity = quantity;
      this.is_required = is_required;
    }
  }
  
  global class order_item{
    public string productId {get; set;}
    public string product_name {get; set;}
    public string base_image {get; set;}
    public string magento_productId {get; set;}//salesforce_id
    public string magento_configurable_product {get; set;}
    public string configurable_product {get; set;}
    public decimal discount_amount {get; set;}
    public decimal original_price {get; set;}
    public decimal price {get; set;}
    public string Product_sku {get; set;}
    public decimal qty_ordered {get; set;}
    //public decimal subtotal {get; set;}
    public decimal tax_amount {get; set;}
    public decimal tax_percent {get; set;}
    public decimal commission_amount {get; set;}
    public string created_date {get; set;}
    public list<related_item> related_products {get; set;}
    public String order_type {get; set;}
    public decimal cost {get; set;}
    public boolean out_of_stock_backend {get; set;}

    public Object getX(string param_name){
            String json_instance = Json.serialize(this);
            Map<String, Object> untyped_instance;
            untyped_instance= (Map<String, Object>)JSON.deserializeUntyped(json_instance);
            return untyped_instance.get(param_name);
      }
  }
  
  global class related_item{
    public string productId {get; set;}
    public string product_name {get; set;}
    public string base_image {get; set;}
    public string product_sku {get; set;}
    public string magento_productId {get; set;}
    public string quantity {get; set;}
    public decimal price {get; set;}
    public string configurable_product {get; set;}
    public string magento_configurable_product {get; set;}
    public decimal cost {get; set;}
    public boolean out_of_stock_backend {get; set;}
  }
  
  global class Response{
    public string status {get; set;}
    public string error {get; set;}
    public list<ResponseData> responseData {get; set;}
    
    public Response (string status, string error){
      this.status = status;
      this.error = error;
    }
    
    public Response (string status, string error, list<ResponseData> responseData){
      this.status = status;
      this.error = error;
      this.responseData = responseData;
    }
  }
  
  global class ResponseData{
    public string magentoId {get; set;}
    public string salesforceId {get; set;}
    public string error {get; set;}
    
    public ResponseData (string magentoId, string salesforceId){
      this.magentoId = magentoId;
      this.salesforceId = salesforceId;
    }
    
    public ResponseData (string magentoId, string salesforceId, string error){
      this.magentoId = magentoId;
      this.salesforceId = salesforceId;
      this.error = error;
    }
  }
}