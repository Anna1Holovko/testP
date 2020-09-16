({
  toggle: function(component, isShow) {
    var spinner = component.find("mainSpinner");
    if (isShow) {
      $A.util.removeClass(spinner, "slds-hide");
    } else {
      $A.util.addClass(spinner, "slds-hide");
    }
  },
  obtainShipmentItemLines: function(component, helper) {
    helper.toggle(component, true);
    var objectId = component.get("v.recordId");
    var action = component.get("c.obtainShipmentLines");
    action.setParams({
      objectId: objectId
    });
    action.setCallback(this, function(response) {
      var helper = this;
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        if (result.success) {
          component.set("v.salesOrderId", result.result.salesOrderId);
          component.set("v.columnsData", result.result.columnsData);
          component.set("v.shipmentLineList", result.result.rowsData);
          component.set("v.pageType", result.result.type);
          component.set("v.fieldDisplayingSetting", result.result.fieldSettings);
        }
      } else {
        console.log("Failed with state: " + state);
      }
      window.setTimeout(
        $A.getCallback(function() {
          helper.toggle(component, false);
          component.set("v.loading", false);
        }),
        500
      );
    });
    $A.enqueueAction(action);
  }
});