({
  checkChange: function(component, event, helper) {
    var compEvent = component.getEvent("isCheckedEvent");
    compEvent.setParams({ id: component.get("v.line").obj.Id });
    compEvent.fire();
  },

  handleAllChecked: function(component, event) {
    var checked = event.getParam("checked");
    component.set("v.checked", checked);
  }
});