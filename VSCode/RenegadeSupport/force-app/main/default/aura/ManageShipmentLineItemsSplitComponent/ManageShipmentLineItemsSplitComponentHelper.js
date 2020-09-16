({
  splitLines: function(component, selectedLine, firstGroup, secondGroup) {
    var action = component.get("c.splitShipmentLines");
    action.setParams({
      selectedLineId: selectedLine.Id,
      firstGroup: firstGroup,
      secondGroup: secondGroup
    });
    action.setCallback(this, function(response) {
      var helper = this;
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();

        if (result.success) {
          if (component.get("v.isClassic")) {
            var compEvent = component.getEvent("closeEvent");
            compEvent.fire();
            component.destroy();
          } else {
            helper.showToast(component, "info", "Success!");
            component.find("overlayLib").notifyClose();
          }
        } else {
          helper.toggle(component, false);
          helper.showToast(component, "error", result.message);
        }
      }
    });
    $A.enqueueAction(action);
  },
  showToast: function(component, type, message) {
    if (component.get("v.isClassic")) {
      alert(message);
    } else {
      component.find("notifLib").showNotice({
        variant: type,
        message: message
      });
    }
  },
  toggle: function(component, isShow) {
    var spinner = component.find("mainSpinner");
    if (isShow) {
      $A.util.removeClass(spinner, "slds-hide");
    } else {
      $A.util.addClass(spinner, "slds-hide");
    }
  }
});