({
  checkAll: function(component, event, helper) {
    var checkedLinesList = component.get("v.checkedList");
    var lines = component.get("v.lines");
    var checkedAll = component.get("v.checkAll");
    if (checkedAll) {
      lines.forEach(function(line) {
        if (!checkedLinesList.includes(line.obj.Id)) {
          checkedLinesList.push(line.obj.Id);
        }
      });
    } else {
      checkedLinesList = [];
    }
    component.set("v.checkedList", checkedLinesList);
    var appEvent = $A.get("e.c:CustomDataTable_IsALLChecked_Event");
    appEvent.setParams({ checked: component.get("v.checkAll") });
    appEvent.fire();
  },

  handleIsCheckedEvent: function(component, event, helper) {
    var lines = component.get("v.lines");
    var checkedLineId = event.getParam("id");
    var checkedLinesList = component.get("v.checkedList");
    if (checkedLinesList.includes(checkedLineId)) {
      checkedLinesList.splice(checkedLinesList.indexOf(checkedLineId), 1);
    } else {
      checkedLinesList.push(checkedLineId);
    }
    component.set("v.checkedList", checkedLinesList);
    if (checkedLinesList.length == lines.length) {
      component.set("v.checkAll", true);
    } else {
      component.set("v.checkAll", false);
    }
  }
});