({
    searchRecords : function(component, event, helper) {
        helper.obtainRecords(component, helper, component.get("v.sObjectName"), component.get("v.filterFieldName"), component.get("v.filterValue"), false);
    },

    obtainRecords: function(component, helper, sObjectName, filterField, searchValue, isDefaultSearch){
        debugger;
        let timer = component.get('v.timer');
        // if (!!timer){
        //     clearTimeout(timer);
        // }
        var action = component.get("c.obtainRecords");
        
        action.setParams({ 
            sObjectName : sObjectName,
            filterField : filterField,
            searchValue : searchValue,
            isDefaultSearch : isDefaultSearch
        });

        action.setCallback(this, response => {
            debugger;
            if(response.getState()=="SUCCESS"){
                let result = response.getReturnValue();
                if(isDefaultSearch){
                    helper.setDefaultValue(component, result[0].Id, result[0].Name);
                }
                result.push({id: null, Name: 'None'});
                component.set("v.sObjectList", result);
            }

        });
        $A.enqueueAction(action);
    },

    setDefaultValue : function(component, defaultId, defaultName ){
        component.set('v.chosenId', defaultId);
        component.set('v.inputLabel', defaultName); 
    }
    
})