({
    obtainInvoices : function(component, helper) {
        var salesOrderID = component.get("v.recordId");
        //alert(salesOrderID);
        /*var action = component.get("c.obtainsPayablesInvoice");
        action.setParams({
            "salesOrderID":salesOrderID
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var result =  response.getReturnValue();
                helper.setTableData(component, result.result, helper);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);*/

        var action = component.get("c.obtainsPayablesInvoiceList");
        action.setParams({
            "salesOrderID":salesOrderID
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                debugger;
                var result = response.getReturnValue();
                if(result.success){
                    component.set("v.columnsData", result.result.columnsData);
                    component.set("v.rowsData", result.result.rowsData);
                }
                
                //helper.setTableData(component, result.result, helper);
            }
            else {
                console.log("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);    


    },
    
    setTableData : function(component, tableData, helper){
        var invoceData = tableData.rowsData;
        var columnData = tableData.columnsData;
        var urlColums = {};
        var atributs = {};
        
        Object.keys(columnData).forEach(function(element) {
            if(columnData[element][1]==='url'){
                urlColums[element] = 1;//atributs['lable'] = element;
            }
            
        });
        //alert(Object.keys(urlColums) +"|"+Object.values(urlColums) );
        /* component.set("v.columns", [{ label: 'Invoice Number', fieldName: 'Name', type: 'text', typeAttributes: { label:'Go'}},
                                    { label: 'Total Line Items invoiced', fieldName: 'Items_invoiced__c', type: 'number'},
                                    { label: 'Customer Name', fieldName: 'Customer_Name__r.Name', type: 'text' },
                                    { label: 'Sub Total', fieldName: 'Sub_Total__c', type: 'currency' },
                                    { label: 'Tax Amount', fieldName: 'TaxAmount__c', type: 'currency' },
                                    { label: 'Discount Amount	', fieldName: 'DiscountAmount__c', type: 'currency' },
                                    { label: 'Grand Total', fieldName: 'Grand_Total__c', type: 'currency' }                                     
                                   ]);
        // id, Name, RecordType.Name, Items_invoiced__c, Customer_Name__c, Sub_Total__c, TaxAmount__c, DiscountAmount__c, Grand_Total__c 
        
        */
        //populate rows data
        if(invoceData.length>0){
            var tableData=[];
            invoceData.forEach(function(element) {
                
                var currentRecordData={};
                currentRecordData['labelnameRecordType.Name'] = 'test';
                var columnsList = Object.keys(element);
                
                //alert(columnsList);
                for(var i = 0; i<columnsList.length; i++){
                    var key = columnsList[i];
                    var value = element[key];
                    if( key==='Name'){// ||
                        
                        atributs[key] = [value];   
                        currentRecordData['urlLabel'+key] = value;
                        currentRecordData[key] = "/"+element['Id'];
                        continue;
                    }
                    if(typeof(element[key]) === 'object' ){           
                        var dat = helper.parceobj(element[key], key, '',helper);
                        //alert('dat '+dat);
                        dat.forEach(function(row){
                            //alert('row '+row[0][1] +' | '+ row[0][0]+' | '+ row[0][2]);
                            currentRecordData[row[0][1]] = '/'+row[0][2];
                            currentRecordData['urlLabel'+row[0][1]] = row[0][0];
                        });
                        continue;
                    }
                    
                    currentRecordData[key] = value;
                }
                tableData.push(currentRecordData);
            });
            //alert('tableData '+ Object.values(tableData[0]));
            component.set("v.data", tableData);
            
            
            //populate columnt data
            var colums =[]; 
            //alert(Object.keys(columnData));
            //colums.push({ label: 'Invoice Number', fieldName: 'Name', type: 'url', typeAttributes: { label: 'Name'} });//atributs['Name']
            Object.keys(columnData).forEach(function(element) {
                //if(element!=='Name'){
                var currentColumn = {};
                currentColumn['fieldName'] = element;
                currentColumn['label'] = columnData[element][0];
                currentColumn['type'] = columnData[element][1];
                if(element==='Name'){
                    //currentColumn['fieldName'] = currentRecordData['urlValue'+element];
                    currentColumn['type'] = 'url';
                    currentColumn['typeAttributes'] = {label: { fieldName: 'urlLabel'+element }};
                }
                
                if(currentColumn['type']==='url'){
                    currentColumn['typeAttributes'] = {label: { fieldName: 'urlLabel'+element }};
                }
                //  alert('currentColumn' + Object.keys(columnData[element][2]));
                colums.push(currentColumn);
                //}
            });
            
            component.set("v.columns", colums);
        }
        
        
        
        
        
        
        
    },
    
    parceobj : function(obj, filedName, recId,helper){
        var result = [];
        var subRes = [];
        //alert('obj|'+filedName);
        if(typeof(obj)!=='object'){
            subRes.push(obj);
            subRes.push(filedName);
            subRes.push(recId);
            
            result.push(subRes);
            //alert('result|'+result);
            return result;
        }
        var keys = Object.keys(obj);
        for(var i=0 ; i<keys.length; i++){
            var key = keys[i];
            //alert('key|'+key);
            if(key!=='Id'){
                result.push(helper.parceobj(obj[key], filedName+'.'+key, obj['Id'], helper)); 	
            }    
            
        }
        
        return result;
    }
    
    
})