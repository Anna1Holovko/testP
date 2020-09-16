({
    Init : function(component, event, helper) {
        helper.obtainInvoices(component,helper);
        //helper.setTableData(component, []);
    },
    onRowSelected : function(component, event, helper){
        var selected = event.getParam('selectedRows');
        if(selected.length>0){
            alert(selected[0].Id);
            
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/"+selected[0].Id
            });
            urlEvent.fire();
            
        }
        
    }
})