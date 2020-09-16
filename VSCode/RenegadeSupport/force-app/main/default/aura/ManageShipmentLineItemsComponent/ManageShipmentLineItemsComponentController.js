({
  init: function(component, event, helper) {
    helper.obtainShipmentItemLines(component, helper);
  },
  update: function(component, event, helper) {
    helper.toggle(component, true);
    var isClassic = component.get("v.isClassic");
    var checkedList = component.get("v.checkedList");
    var shipmentLineList = component.get("v.shipmentLineList");
    var shipmentIdList = [];
    var shipmentLine;
    shipmentLineList.forEach(function(item) {
      if (checkedList.includes(item.obj.Id)) {
        if (!shipmentLine) {
          shipmentLine = item.obj;
        }
        shipmentIdList.push(item.obj.Shipment__c);
      }
    });
    $A.createComponents(
      [
        [
          "c:ManageShipmentLineItemsEditComponent",
          {
            pageType: component.get("v.pageType"),
            salesOrderId: component.get("v.salesOrderId"),
            fieldDisplayingSetting: component.get("v.fieldDisplayingSetting"),
            shipmentIdList: shipmentIdList,
            shipmentLineIdList: checkedList,
            shipmentLine: shipmentLine,
            isClassic: isClassic,
            visualforceURL: component.get("v.visualforceURL")
          }
        ]
      ],
      function(components, status) {
        if (status === "SUCCESS") {
          var modalBody = components[0];
          helper.toggle(component, false);
          if (isClassic) {
            var modalBlock = component.find("modalBlock");
            modalBlock.set("v.body", modalBody);
          } else {
            component.find("overlayLib").showCustomModal({
              body: modalBody,
              showCloseButton: true,
              cssClass: "",
              closeCallback: function() {
                component.set("v.checkedList", []);
                component.set("v.checkAll", false);
                helper.obtainShipmentItemLines(component, helper);
              }
            });
          }
        }
      }
    );
  },

  split: function(component, event, helper) {
    helper.toggle(component, true);
    var isClassic = component.get("v.isClassic");
    var checkedList = component.get("v.checkedList");
    var shipmentLineList = component.get("v.shipmentLineList");
    var selectedLine = shipmentLineList.filter(
      line => line.obj.Id == checkedList[0]
    );
    $A.createComponents(
      [
        [
          "c:ManageShipmentLineItemsSplitComponent",
          {
            selectedLine: selectedLine[0].obj,
            isClassic: isClassic
          }
        ]
      ],
      function(components, status) {
        if (status === "SUCCESS") {
          var modalBody = components[0];
          helper.toggle(component, false);
          if (isClassic) {
            var modalBlock = component.find("modalBlock");
            modalBlock.set("v.body", modalBody);
          } else {
            component.find("overlayLib").showCustomModal({
              body: modalBody,
              showCloseButton: true,
              cssClass: "",
              closeCallback: function() {
                component.set("v.checkedList", []);
                component.set("v.checkAll", false);
                helper.obtainShipmentItemLines(component, helper);
              }
            });
          }
        }
      }
    );
  },

  goToNewReplacementPO: function(component, event, helper) {
    if (component.get("v.isClassic")) {
      window.open(
        "/apex/ReplacePurchaseOrderPage?id=" +
          component.get("v.salesOrderId") +
          "&solids=" +
          component.get("v.checkedList").join("%2C")
      );
    } else {
      var navService = component.find("navService");
      event.preventDefault();
      navService.navigate({
        type: "standard__webPage",
        attributes: {
          url:
            "/apex/ReplacePurchaseOrderPage?solids=" +
            component.get("v.checkedList").join(",") +
            "&id=" +
            component.get("v.salesOrderId")
        }
      });
    }
  },

  goToNewPartPO: function(component, event, helper) {
    if (component.get("v.isClassic")) {
      window.open(
        "/apex/ReplacePartPage?solids=" +
          component.get("v.checkedList").join("%2C") +
          "&id=" +
          component.get("v.salesOrderId")
      );
    } else {
      var navService = component.find("navService");
      event.preventDefault();
      navService.navigate({
        type: "standard__webPage",
        attributes: {
          url:
            "/apex/ReplacePartPage?solids=" +
            component.get("v.checkedList").join(",") +
            "&id=" +
            component.get("v.salesOrderId")
        }
      });
    }
  },
  checkedListChange: function(component, event, helper) {
    var checkedList = component.get("v.checkedList");
    var lineList = component.get("v.shipmentLineList");
    var selecetedLine = lineList.filter(line => line.obj.Id == checkedList[0]);
    if (
      component.get("v.pageType") != "Case" &&
      checkedList.length == 1 &&
      selecetedLine[0].obj.Shipment_Product_Quantity__c != 1
    ) {
      component.set("v.isSplitable", true);
    } else {
      component.set("v.isSplitable", false);
    }
  },
  handleCloseEvent: function(component, event, helper) {
    component.set("v.checkedList", []);
    component.set("v.checkAll", false);
    helper.obtainShipmentItemLines(component, helper);
  }
});