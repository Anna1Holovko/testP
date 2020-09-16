({
	doInit : function(component, event, helper) {
        component.set('v.columnsForCustomTable', [
            {Name: 'Product name', fieldName: 'Name', type: 'text'},
            {Name: 'SKU', fieldName: 'SKU__c', type: 'text'},
            {Name: 'Manufacturer Inventory', fieldName: 'Manufacturer_Inventory__c', type: 'number'}
        ]);
        
        helper.obtainProducts(component, helper);
    },

    sort : function(component, event, helper){
        let timeout = 500;
        
        let timer = component.get("v.timer");
        clearTimeout(timer);
        timer = setTimeout(
            
            $A.getCallback(
                function(){
                    debugger;
                    component.set("v.isLoaded", false);
                    helper.sortProducts(component);
                }
            )
        ,timeout);
        component.set("v.timer", timer);
    }
})