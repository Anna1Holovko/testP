({
  init: function (component, event, helper) {
    debugger;
    if (component.get("v.isClassic")) {
      var eventMethod = window.addEventListener
        ? "addEventListener"
        : "attachEvent";
      var eventer = window[eventMethod];
      var messageEvent = eventMethod == "attachEvent" ? "onmessage" : "message";
      eventer(
        messageEvent,
        function (wrapper) {
          if (wrapper.data.status == "success") {
            helper.close(component);
          } else if (wrapper.data.status == "fail") {
            helper.showToast(component, "error", "Something went wrong");
          }
        },
        false
      );
    }
    helper.obtainMetaData(component, helper);
  },
  onItemStatusChange: function (component, event, helper) {
    helper.onItemStatusChange(component, event, helper);
  },

  onDamageChange: function (component, event, helper) {
    helper.onDamageChange(component, event, helper);
  },

  handleUploadFinished: function (component, event, helper) {
    var uploadedFiles = event.getParam("files");
    var files = component.get("v.files");
    if (!files) {
      files = [];
    }
    files = files.concat(uploadedFiles);
    component.set("v.files", files);
  },
  onDeleteFile: function (component, event, helper) {
    if (component.get("v.isClassic")) {
      var fileName = event.getSource().get("v.name");
      var files = component.get("v.files");
      files[0] = Object.values(files[0]).filter(function (item) {
        return item.name != fileName;
      });
      component.set("v.files", files);
    } else {
      var documentId = event.getSource().get("v.name");
      var files = component.get("v.files");
      files = files.filter(function (item) {
        return item.documentId != documentId;
      });
      component.set("v.files", files);
      helper.deleteFilesAction(component, [documentId]);
    }
  },
  showFile: function (component, event, helper) {
    var documentId = event.target.getAttribute("name");
    $A.get("e.lightning:openFiles").fire({
      recordIds: [documentId]
    });
  },
  update: function (component, event, helper) {
    helper.toggle(component, true);
    var shipmentLineIds = component.get("v.shipmentLineIdList");

    var objectToEdit = component.get("v.objectToEdit");
    var updateObject = {};

    //Consignment_Center__c
    updateObject.Consignment_Center__c = objectToEdit.Consignment_Center__c;
    //Shipment_Item_Status__c
    updateObject.Shipment_Item_Status__c = objectToEdit.Shipment_Item_Status__c;

    //Damage_Action__c
    var damageActionPicklist = component.get("v.damageActionPicklist");
    if (!!damageActionPicklist && damageActionPicklist.length > 0) {
      updateObject.Damage_Action__c = objectToEdit.Damage_Action__c;
    } else {
      updateObject.Damage_Action__c = null;
    }

    //Location_Of_Furniture__c
    var locationOfFurniturePicklist = component.get(
      "v.locationOfFurniturePicklist"
    );
    if (
      !!locationOfFurniturePicklist &&
      locationOfFurniturePicklist.length > 0
    ) {
      updateObject.Location_Of_Furniture__c =
        objectToEdit.Location_Of_Furniture__c;
    } else {
      updateObject.Location_Of_Furniture__c = null;
    }

    //Tech_Scheduled_By__c
    var techScheduledByPicklist = component.get("v.techScheduledByPicklist");
    if (!!techScheduledByPicklist && techScheduledByPicklist.length > 0) {
      updateObject.Tech_Scheduled_By__c = objectToEdit.Tech_Scheduled_By__c;
    } else {
      updateObject.Tech_Scheduled_By__c = null;
    }

    //No_Fit_Status__c
    var noFitStatusPicklist = component.get("v.noFitStatusPicklist");
    if (!!noFitStatusPicklist && noFitStatusPicklist.length > 0) {
      updateObject.No_Fit_Status__c = objectToEdit.No_Fit_Status__c;
    } else {
      updateObject.No_Fit_Status__c = null;
    }

    //Sent_Tech_Report__c
    var sentTechReportPicklist = component.get("v.sentTechReportPicklist");
    if (!!sentTechReportPicklist && sentTechReportPicklist.length > 0) {
      updateObject.Sent_Tech_Report__c = objectToEdit.Sent_Tech_Report__c;
    } else {
      updateObject.Sent_Tech_Report__c = null;
    }

    //Scheduled_Delivery_Date__c
    //if(objectToEdit.Shipment_Item_Status__c == 'Scheduled Delivery'){
    updateObject.Scheduled_Delivery_Date__c =
      objectToEdit.Scheduled_Delivery_Date__c;
    //}
    //else{
    //  updateObject.Scheduled_Delivery_Date__c = null;
    //}

    //Delivery_Date_Actual__c
    //if(objectToEdit.Shipment_Item_Status__c == 'Delivered No Issues'){
    updateObject.Delivery_Date_Actual__c = objectToEdit.Delivery_Date_Actual__c;
    //}
    //else{
    //  updateObject.Delivery_Date_Actual__c = null;
    //}

    //Drop_Off_Date_Actual__c
    //var isShowDropOffDateActual = component.get("v.isShowDropOffDateActual");
    //if(isShowDropOffDateActual){
    updateObject.Drop_Off_Date_Actual__c = objectToEdit.Drop_Off_Date_Actual__c;
    //}
    //else{
    //  updateObject.Drop_Off_Date_Actual__c = null;
    //}

    //Repair_Amount__c
    //var isShowRepairAmount = component.get("v.isShowRepairAmount");
    //if(isShowRepairAmount){
    updateObject.Repair_Amount__c = objectToEdit.Repair_Amount__c;
    //}
    //else{
    //  updateObject.Repair_Amount__c = null;
    //}

    //Repair_Date_Expected__c
    //var isShowRepairDateExpected = component.get("v.isShowRepairDateExpected");
    //if(isShowRepairDateExpected){
    updateObject.Repair_Date_Expected__c = objectToEdit.Repair_Date_Expected__c;
    //}
    //else{
    //  updateObject.Repair_Date_Expected__c = null;
    //}

    //Replacement_Drop_off_Date_Actual__c
    //Replacement_Drop_off_Date_Expected__c
    //var isShowReplacementDropOffDates = component.get("v.isShowReplacementDropOffDates");
    //if(isShowReplacementDropOffDates){
    updateObject.Replacement_Drop_off_Date_Actual__c =
      objectToEdit.Replacement_Drop_off_Date_Actual__c;
    updateObject.Replacement_Drop_off_Date_Expected__c =
      objectToEdit.Replacement_Drop_off_Date_Expected__c;
    //}
    //else{
    //  updateObject.Replacement_Drop_off_Date_Actual__c = null;
    //  updateObject.Replacement_Drop_off_Date_Expected__c = null;
    //}

    //Repair_Date_Actual__c
    //var isShowRepairDateActual = component.get("v.isShowRepairDateActual");
    //if(isShowRepairDateActual){
    updateObject.Repair_Date_Actual__c = objectToEdit.Repair_Date_Actual__c;
    //}
    //else{
    //  updateObject.Repair_Date_Actual__c = null;
    //}

    //Status_Of_Tech_Needed__c
    //var isShowStatusOfTechNeeded = component.get("v.isShowStatusOfTechNeeded");
    //var statusOfTechNeededPicklist = component.get("v.statusOfTechNeededPicklist");
    //if(isShowStatusOfTechNeeded && !!statusOfTechNeededPicklist && statusOfTechNeededPicklist.length > 0){
    updateObject.Status_Of_Tech_Needed__c =
      objectToEdit.Status_Of_Tech_Needed__c;
    //}
    //else{
    //  updateObject.Status_Of_Tech_Needed__c = null;
    //}

    //Parts_Information__c
    //var isShowPartsInformation = component.get("v.isShowPartsInformation");
    //if(isShowPartsInformation){
    updateObject.Parts_Information__c = objectToEdit.Parts_Information__c;
    //}
    //else{
    //  updateObject.Parts_Information__c = null;
    //}

    //Parts_Arrival_Expected__c
    //Parts_Arrival_Date_Actual__c
    //var isShowPArtArrivalDates = component.get("v.isShowPArtArrivalDates");
    //if(isShowPArtArrivalDates){
    updateObject.Parts_Arrival_Expected__c =
      objectToEdit.Parts_Arrival_Expected__c;
    updateObject.Parts_Arrival_Date_Actual__c =
      objectToEdit.Parts_Arrival_Date_Actual__c;
    //}
    //else{
    //  updateObject.Parts_Arrival_Expected__c = null;
    //  updateObject.Parts_Arrival_Date_Actual__c = null;
    //}

    //Parts_Are_Shipping__c
    //var isShowPartsAreShipping = component.get("v.isShowPartsAreShipping");
    //if(isShowPartsAreShipping){
    updateObject.Parts_Are_Shipping__c = objectToEdit.Parts_Are_Shipping__c;
    //}
    //else{
    //  updateObject.Parts_Are_Shipping__c = null;
    //}

    //Tech_Needed_Create_Date__c
    //var isShowTechNeededCreateDate = component.get("v.isShowTechNeededCreateDate");
    //if(isShowTechNeededCreateDate){
    updateObject.Tech_Needed_Create_Date__c =
      objectToEdit.Tech_Needed_Create_Date__c;
    //}
    //else{
    //  updateObject.Tech_Needed_Create_Date__c = null;
    //}

    //Tech_Request_Submitted_Date__c
    //var isShowTechRequestSubmittedDate = component.get("v.isShowTechRequestSubmittedDate");
    //if(isShowTechRequestSubmittedDate){
    updateObject.Tech_Request_Submitted_Date__c =
      objectToEdit.Tech_Request_Submitted_Date__c;
    //}
    //else{
    //  updateObject.Tech_Request_Submitted_Date__c = null;
    //}

    //Tech_Appointment_Confirmed__c
    //var isShowTechAppointmentConfirmed = component.get("v.isShowTechAppointmentConfirmed");
    //if(isShowTechAppointmentConfirmed){
    updateObject.Tech_Appointment_Confirmed__c =
      objectToEdit.Tech_Appointment_Confirmed__c;
    //}
    //else{
    //  updateObject.Tech_Appointment_Confirmed__c = null;
    //}

    //Furniture_Condition__c
    //var furnitureConditionPicklist = component.get("v.furnitureConditionPicklist");
    //if(objectToEdit.Shipment_Item_Status__c == 'Hold As Stock' && !!furnitureConditionPicklist && furnitureConditionPicklist.length > 0){
    updateObject.Furniture_Condition__c = objectToEdit.Furniture_Condition__c;
    //}
    //else{
    //  updateObject.Furniture_Condition__c = null;
    //}

    helper.updateLines(component, shipmentLineIds, updateObject);
  },

  cancel: function (component, event, helper) {
    if (!component.get("v.isClassic")) {
      var files = component.get("v.files");
      var fileIdList = [];
      files.forEach(function (item) {
        fileIdList.push(item.documentId);
      });
      helper.deleteFilesAction(component, fileIdList);
    }
    helper.close(component);
  },

  sendFiles: function (component, event, handler) {
    var fileList = event.target.files;
    component.set("v.files", fileList);
  },

  clearFiles: function (component, event, handler) {
    event.target.value = null;
  },

  changeNumber: function (component, event, handler) {
    var objectToEdit = component.get("v.objectToEdit");
    if (objectToEdit.Repair_Amount__c > 100000000) {
      objectToEdit.Repair_Amount__c = 100000000;
    } else if (objectToEdit.Repair_Amount__c < 0) {
      objectToEdit.Repair_Amount__c = 0;
    }
    component.set("v.objectToEdit", objectToEdit);
  }
});