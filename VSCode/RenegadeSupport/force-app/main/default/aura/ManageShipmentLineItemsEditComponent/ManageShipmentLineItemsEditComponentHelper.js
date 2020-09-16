({
  obtainMetaData: function (component, helper) {
    var pageType = component.get("v.pageType");
    var action = component.get("c.obtainMetadata");
    action.setParams({
      type: pageType
    });
    action.setCallback(this, function (response) {
      var helper = this;
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        var parsed = JSON.parse(result);
        if (parsed.success) {
          component.set(
            "v.shipmentItemStatusPicklist",
            parsed.result.Shipment_Item_Status__c
          );
          component.set(
            "v.shipmentItemStatusPicklist",
            parsed.result.Shipment_Item_Status__c
          );
          component.set(
            "v.statusOfTechNeededPicklist",
            parsed.result.Status_Of_Tech_Needed__c
          );
          component.set(
            "v.furnitureConditionPicklist",
            parsed.result.Furniture_Condition__c
          );
          if (parsed.result.dependencyMap) {
            if (parsed.result.dependencyMap.Damage_Action__c) {
              component.set(
                "v.damageActionsMap",
                parsed.result.dependencyMap.Damage_Action__c
              );
              if (
                parsed.result.Shipment_Item_Status__c &&
                parsed.result.Shipment_Item_Status__c.length > 0
              ) {
                component.set(
                  "v.damageActionPicklist",
                  helper.setupPicklist(
                    parsed.result.Shipment_Item_Status__c[0].value,
                    parsed.result.dependencyMap.Damage_Action__c
                  )
                );
              }
            }

            if (parsed.result.dependencyMap.Location_Of_Furniture__c) {
              component.set(
                "v.locationOfFurnitureMap",
                parsed.result.dependencyMap.Location_Of_Furniture__c
              );
            }

            if (parsed.result.dependencyMap.Tech_Scheduled_By__c) {
              component.set(
                "v.techScheduledByMap",
                parsed.result.dependencyMap.Tech_Scheduled_By__c
              );
            }

            if (parsed.result.dependencyMap.No_Fit_Status__c) {
              component.set(
                "v.noFitStatusMap",
                parsed.result.dependencyMap.No_Fit_Status__c
              );
            }

            if (parsed.result.dependencyMap.Sent_Tech_Report__c) {
              component.set(
                "v.sentTechReportMap",
                parsed.result.dependencyMap.Sent_Tech_Report__c
              );
            }
          }
          window.setTimeout(
            $A.getCallback(function () {
              component.set("v.objectToEdit", component.get("v.shipmentLine"));
              helper.onItemStatusChange(component, event, helper);
              helper.toggle(component, false);
            }),
            100
          );
        }
      } else {
        console.log("Failed with state: " + state);
      }
    });
    $A.enqueueAction(action);
  },
  onItemStatusChange: function (component, event, helper) {
    var objectToEdit = component.get("v.objectToEdit");

    //DAMAGE ACTION
    var damageActionsMap = component.get("v.damageActionsMap");
    var damageActionPicklist = helper.setupPicklist(
      objectToEdit.Shipment_Item_Status__c,
      damageActionsMap
    );
    component.set("v.damageActionPicklist", damageActionPicklist);
    if (
      damageActionPicklist.length > 0 &&
      objectToEdit.Damage_Action__c == null
    ) {
      objectToEdit.Damage_Action__c = damageActionPicklist[0].value;
      component.set("v.objectToEdit", objectToEdit);
    }
    //Drop Off Date Actual - condtion to show
    helper.setShowDropOffDateActual(component, objectToEdit);

    helper.setAllConditons(component, objectToEdit);

    window.setTimeout(
      $A.getCallback(function () {
        helper.onDamageChange(component, event, helper);
      }),
      100
    );
  },
  onDamageChange: function (component, event, helper) {
    var objectToEdit = component.get("v.objectToEdit");
    var damageActionPicklist = component.get("v.damageActionPicklist");
    var damageAction = null;
    if (damageActionPicklist.length > 0) {
      damageAction = objectToEdit.Damage_Action__c;
    }

    //Location Of Furniture
    var locationOfFurnitureMap = component.get("v.locationOfFurnitureMap");
    var locationOfFurniturePicklist = helper.setupPicklist(
      damageAction,
      locationOfFurnitureMap
    );
    component.set("v.locationOfFurniturePicklist", locationOfFurniturePicklist);
    //Tech Scheduled By
    var techScheduledByMap = component.get("v.techScheduledByMap");
    var techScheduledByPicklist = helper.setupPicklist(
      damageAction,
      techScheduledByMap
    );
    component.set("v.techScheduledByPicklist", techScheduledByPicklist);
    //No Fit Status
    var noFitStatusMap = component.get("v.noFitStatusMap");
    var noFitStatusPicklist = helper.setupPicklist(
      damageAction,
      noFitStatusMap
    );
    component.set("v.noFitStatusPicklist", noFitStatusPicklist);
    //Sent Tech Report
    var sentTechReportMap = component.get("v.sentTechReportMap");
    var sentTechReportPicklist = helper.setupPicklist(
      damageAction,
      sentTechReportMap
    );
    component.set("v.sentTechReportPicklist", sentTechReportPicklist);

    helper.setAllConditons(component, objectToEdit);

    component.set("v.objectToEdit", objectToEdit);
  },
  setupPicklist: function (parentValue, valueMap) {
    var picklist = [];
    if (valueMap[parentValue]) {
      picklist = valueMap[parentValue];
    }
    return picklist;
  },

  setShowConsignmentCenter: function (component, objectToEdit) {
    var statusList = [];
    statusList.push("At Consignment");
    var isShowConsignmentCenter = statusList.includes(
      objectToEdit.Shipment_Item_Status__c
    );
    // if (statusList.includes(objectToEdit.Shipment_Item_Status__c)) {
    //   isShowRepairAmount = true;
    // }
    component.set("v.isShowConsignmentCenter", isShowConsignmentCenter);
  },

  setShowDropOffDateActual: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Drop_Off_Date_Actual__c["statusValue"];
    var isShowDropOffDateActual = false;
    if (statusList.includes(objectToEdit.Shipment_Item_Status__c)) {
      // && isAllDrop_Off_Null == true
      isShowDropOffDateActual = true;
    }
    component.set("v.isShowDropOffDateActual", isShowDropOffDateActual);
  },

  setShowRepairAmount: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting").Repair_Amount__c[
      "statusValue"
    ];
    var damageList = component.get("v.fieldDisplayingSetting").Repair_Amount__c[
      "damageValue"
    ];
    var isShowRepairAmount = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowRepairAmount = true;
    }
    component.set("v.isShowRepairAmount", isShowRepairAmount);
  },
  setShowRepairDateExpected: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Repair_Date_Expected__c["statusValue"];

    var damageList = component.get("v.fieldDisplayingSetting")
      .Repair_Date_Expected__c["damageValue"];

    var isShowRepairDateExpected = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowRepairDateExpected = true;
    }
    component.set("v.isShowRepairDateExpected", isShowRepairDateExpected);
  },
  setShowReplacementDropOffDates: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Replacement_Drop_off_Date_Actual__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Replacement_Drop_off_Date_Actual__c["damageValue"];

    var isShowReplacementDropOffDates = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowReplacementDropOffDates = true;
    }
    component.set(
      "v.isShowReplacementDropOffDates",
      isShowReplacementDropOffDates
    );
  },
  setShowRepairDateActual: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Repair_Date_Actual__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Repair_Date_Actual__c["damageValue"];

    var isShowRepairDateActual = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowRepairDateActual = true;
    }
    component.set("v.isShowRepairDateActual", isShowRepairDateActual);
  },
  setShowStatusOfTechNeeded: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Status_Of_Tech_Needed__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Status_Of_Tech_Needed__c["damageValue"];

    var isShowStatusOfTechNeeded = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      // && userType == 'Standard'
      isShowStatusOfTechNeeded = true;
    }
    component.set("v.isShowStatusOfTechNeeded", isShowStatusOfTechNeeded);
  },
  setShowPartsInformation: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Parts_Information__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Parts_Information__c["damageValue"];

    var isShowPartsInformation = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowPartsInformation = true;
    }
    component.set("v.isShowPartsInformation", isShowPartsInformation);
  },
  setShowPArtArrivalDates: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Parts_Arrival_Expected__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Parts_Arrival_Expected__c["damageValue"];

    var isShowPArtArrivalDates = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowPArtArrivalDates = true;
    }
    component.set("v.isShowPArtArrivalDates", isShowPArtArrivalDates);
  },
  setShowPartsAreShipping: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Parts_Are_Shipping__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Parts_Are_Shipping__c["damageValue"];

    var isShowPartsAreShipping = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      isShowPartsAreShipping = true;
    }
    component.set("v.isShowPartsAreShipping", isShowPartsAreShipping);
  },
  setShowTechNeededCreateDate: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Tech_Needed_Create_Date__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Tech_Needed_Create_Date__c["damageValue"];

    var isShowTechNeededCreateDate = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      //&& userType == 'Standard'
      isShowTechNeededCreateDate = true;
    }
    component.set("v.isShowTechNeededCreateDate", isShowTechNeededCreateDate);
  },
  setShowTechRequestSubmittedDate: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Tech_Request_Submitted_Date__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Tech_Request_Submitted_Date__c["damageValue"];

    var isShowTechRequestSubmittedDate = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      //&& userType == 'Standard'
      isShowTechRequestSubmittedDate = true;
    }
    component.set(
      "v.isShowTechRequestSubmittedDate",
      isShowTechRequestSubmittedDate
    );
  },
  setShowTechAppointmentConfirmed: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Tech_Appointment_Confirmed__c["statusValue"];
    var damageList = component.get("v.fieldDisplayingSetting")
      .Tech_Appointment_Confirmed__c["damageValue"];

    var isShowTechAppointmentConfirmed = false;
    if (
      statusList.includes(objectToEdit.Shipment_Item_Status__c) &&
      damageList.includes(objectToEdit.Damage_Action__c)
    ) {
      //&& userType == 'Standard'
      isShowTechAppointmentConfirmed = true;
    }
    component.set(
      "v.isShowTechAppointmentConfirmed",
      isShowTechAppointmentConfirmed
    );
  },
  setShowFiles: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting").Uploading_files[
      "statusValue"
    ];

    var isShowFiles = false;
    if (statusList.includes(objectToEdit.Shipment_Item_Status__c)) {
      isShowFiles = true;
    } else {
      component.set("v.files", []);
    }
    component.set("v.isShowFiles", isShowFiles);
  },
  setFurnitureCondition: function (component, objectToEdit) {
    var statusList = component.get("v.fieldDisplayingSetting")
      .Furniture_Condition__c["statusValue"];
    var isShowFurnitureCondition = false;
    if (statusList.includes(objectToEdit.Shipment_Item_Status__c)) {
      //&& userType == 'Standard'
      isShowFurnitureCondition = true;
    }
    component.set("v.isShowFurnitureCondition", isShowFurnitureCondition);
  },
  setAllConditons: function (component, objectToEdit) {
    var helper = this;

    //At Consignment - condtion to show
    helper.setShowConsignmentCenter(component, objectToEdit);

    //Repair Amount - condtion to show
    helper.setShowRepairAmount(component, objectToEdit);

    //Repair Date Expected - condtion to show
    helper.setShowRepairDateExpected(component, objectToEdit);

    //Replacement Drop Off Date Actual and Expected - condtion to show
    helper.setShowReplacementDropOffDates(component, objectToEdit);

    //Replacement DropOff Dates - condtion to show
    helper.setShowRepairDateActual(component, objectToEdit);

    //Status Of Tech Needed - condtion to show
    helper.setShowStatusOfTechNeeded(component, objectToEdit);

    //Parts Information - condtion to show
    helper.setShowPartsInformation(component, objectToEdit);

    //Parts Arrival Date Expected and Actual -  condtion to show
    helper.setShowPArtArrivalDates(component, objectToEdit);

    //Parts Are Shipping - condtion to show
    helper.setShowPartsAreShipping(component, objectToEdit);

    //Tech Needed Create Date - condtion to show
    helper.setShowTechNeededCreateDate(component, objectToEdit);

    //Tech Reques Submitted Date - condtion to show
    helper.setShowTechRequestSubmittedDate(component, objectToEdit);

    //Tech Appointment Confirmed - condtion to show
    helper.setShowTechAppointmentConfirmed(component, objectToEdit);

    // Furnuture condition - condition to show
    helper.setFurnitureCondition(component, objectToEdit);
    //files condition
    helper.setShowFiles(component, objectToEdit);
  },
  deleteFilesAction: function (component, files) {
    var action = component.get("c.deleteAttachemnts");
    action.setParams({
      documentIdList: files
    });
    action.setCallback(this, function (response) {
      var helper = this;
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
      }
    });
    $A.enqueueAction(action);
  },
  connectFilesToShipment: function (component, files, shipmentIds) {
    var action = component.get("c.connectAttachemnts");
    action.setParams({
      documentIdList: files,
      shipmentIdList: shipmentIds
    });
    action.setCallback(this, function (response) {
      var helper = this;
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();
        if (result.success) {
          helper.showToast(component, "info", "Success!!!");
          helper.close(component);
        } else {
          helper.showToast(component, "error", result.message);
        }
      }
    });
    $A.enqueueAction(action);
  },
  updateLines: function (component, shipmentIds, updateObject) {
    debugger;
    var action = component.get("c.updateShipmentLines");
    action.setParams({
      shipmentLineIdList: shipmentIds,
      updatedLine: JSON.stringify(updateObject)
    });
    action.setCallback(this, function (response) {
      var helper = this;
      var state = response.getState();
      if (state === "SUCCESS") {
        var result = response.getReturnValue();

        if (result.success) {
          var files = component.get("v.files");
          if (component.get("v.isClassic")) {
            if (!!files && !!files[0] && files[0].length > 0) {
              window.postMessage(
                {
                  files: component.get("v.files")[0],
                  lineIdList: component.get("v.shipmentLineIdList"),
                  shipmentIdList: component.get("v.shipmentIdList"),
                  salesOrderId: component.get("v.salesOrderId")
                },
                component.get("v.visualforceURL")
              );
            } else {
              helper.close(component);
            }
          } else {
            if (!!files && files.length > 0) {
              var fileIds = [];
              files.forEach(function (item_i) {
                fileIds.push(item_i.documentId);
              });
              var shipmentIdList = component.get("v.shipmentIdList");
              helper.connectFilesToShipment(component, fileIds, shipmentIdList);
            }
            helper.showToast(component, "info", "Success!!!");
            helper.close(component);
          }
        }
        //else if(result.message.includes("FIELD_CUSTOM_VALIDATION_EXCEPTION") || result.message.includes("FIELD_FILTER_VALIDATION_EXCEPTION")){
        // }
        else {
          helper.showFieldError(
            component,
            helper,
            result.result,
            result.message
          );
          // helper.showToast(component, "error", result.message);
          // helper.toggle(component, false);
        }
      }
    });
    $A.enqueueAction(action);
  },

  showFieldError: function (component, helper, fieldList, message) {
    //error-notes
    debugger;
    if (!!fieldList) {
      fieldList.forEach((fieldName) => {
        if (fieldName === "Consignment_Center__c") {
          component.set("v.isShowErrorConsignmentCenter", true);
          component.set(
            "v.errorMessage",
            "Account record type must be 'Consignment Center'"
          );
          //component.set("v.errorMessageConsigmentCenter", message);
          //component.set("v.errorMessage", message);
          //{!v.errorMessage}
        } else {
          component.set("v.errorMessage", message);
          let findedElem = component.find(fieldName);
          $A.util.addClass(findedElem, "error-notes");
        }
      });
    }

    component.set("v.showError", true);
    //helper.showToast(component, "error", message);
    helper.toggle(component, false);
  },

  showToast: function (component, type, message) {
    if (!!component.get("v.isClassic")) {
      if (component.get("v.isClassic")) {
        alert(message);
      } else {
        component.find("notifLib").showNotice({
          variant: type,
          message: message
        });
      }
    }
  },

  toggle: function (component, isShow) {
    var spinner = component.find("mainSpinner");
    if (isShow) {
      $A.util.removeClass(spinner, "slds-hide");
    } else {
      $A.util.addClass(spinner, "slds-hide");
    }
  },

  close: function (component) {
    if (!!component.get("v.isClassic")) {
      if (component.get("v.isClassic")) {
        var compEvent = component.getEvent("closeEvent");
        compEvent.fire();
        component.destroy();
      } else {
        component.find("overlayLib").notifyClose();
      }
    }
  }
});