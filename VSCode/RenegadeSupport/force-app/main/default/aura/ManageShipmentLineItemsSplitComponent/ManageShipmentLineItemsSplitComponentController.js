({
  init: function(component, event, helper) {
    component.set(
      "v.firstGroup",
      component.get("v.selectedLine").Shipment_Product_Quantity__c - 1
    );
  },
  saveSplit: function(component, event, helper) {
    var firstGroup = Number(component.get("v.firstGroup"));
    var secondGroup = Number(component.get("v.secondGroup"));
    var selectedLine = component.get("v.selectedLine");
    if (firstGroup + secondGroup == selectedLine.Shipment_Product_Quantity__c) {
      helper.toggle(component, true);
      helper.splitLines(component, selectedLine, firstGroup, secondGroup);
    } else {
      helper.showToast(
        component,
        "error",
        "Sum of both fields must be equal Quantity of Shipment Line Item"
      );
    }
  },

  cancel: function(component, event, helper) {
    if (component.get("v.isClassic")) {
      var compEvent = component.getEvent("closeEvent");
      compEvent.fire();
      component.destroy();
    } else {
      component.find("overlayLib").notifyClose();
    }
  },
  changeInputs: function(component, event, helper) {
    var selectedLine = component.get("v.selectedLine");
    var newValue = Number(event.getSource().get("v.value"));
    if (newValue >= selectedLine.Shipment_Product_Quantity__c) {
      newValue = selectedLine.Shipment_Product_Quantity__c - 1;
    } else if (newValue <= 0) {
      newValue = 1;
    }
    if (event.getSource().get("v.label") == "Group 1") {
      component.set(
        "v.secondGroup",
        selectedLine.Shipment_Product_Quantity__c - newValue
      );
      component.set("v.firstGroup", newValue);
    } else {
      component.set(
        "v.firstGroup",
        selectedLine.Shipment_Product_Quantity__c - newValue
      );
      component.set("v.secondGroup", newValue);
    }
  }
});