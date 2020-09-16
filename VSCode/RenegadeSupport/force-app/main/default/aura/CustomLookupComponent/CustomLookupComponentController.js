({
    init : function(component, event, helper) {
        let defaultId = component.get("v.defaultId");
        if(!!defaultId){
            helper.obtainRecords(component, helper, component.get("v.sObjectName"), component.get("v.filterFieldName"), defaultId, true);
        }
    },

    searchRecords : function(component, event, helper) {
        let timer = component.get('v.timer');
        if (!!timer){
            clearTimeout(timer);
        }
        timer = window.setTimeout(
            $A.getCallback(() => {
                component.set("v.filterValue", event.target.value);
                helper.searchRecords(component, event, helper);
            }), 1000
        );
    },

    closeCombo: function(c,e,h){
        c.set('v.isComboOpen', false);
    },
    openCombo: function(c,e,h){
        c.set('v.isComboOpen', true);
    },
    handleOptionSelect: function(c,e,h){
        //c.set('v.inputValue', e.currentTarget.dataset.id);
        c.set('v.chosenId', e.currentTarget.dataset.id);
        c.set('v.inputLabel', e.currentTarget.dataset.name);
        $A.enqueueAction(c.get('c.closeCombo'));
    }
})