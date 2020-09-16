@isTest
global class FidelitoneMock implements WebServiceMock {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
   	System.debug(requestName);

	FidelitoneComOrders.ArrayOfOrderStatus afos = new FidelitoneComOrders.ArrayOfOrderStatus();
   	FidelitoneComOrders.GetOrderStatusUpdatesResponse_element ff = new FidelitoneComOrders.GetOrderStatusUpdatesResponse_element();
   	ff.GetOrderStatusUpdatesResult = afos;

   	FidelitoneComOrders.ArrayOfString arrstr = new FidelitoneComOrders.ArrayOfString();
   	FidelitoneComOrders.PlaceOrderResponse_element pore = new FidelitoneComOrders.PlaceOrderResponse_element();
   	pore.PlaceOrderResult = arrstr;

   	FidelitoneComOrders.AcknowledgeOrderStatusUpdateResponse_element alods = new FidelitoneComOrders.AcknowledgeOrderStatusUpdateResponse_element();
   	alods.AcknowledgeOrderStatusUpdateResult = 'TEST';

   		if(requestName.equals('GetOrderStatusUpdates')) {
   			System.debug(ff.GetOrderStatusUpdatesResult);
       		response.put('response_x', ff); 
   		}else if(requestName.equals('PlaceOrder')) {
   			response.put('response_x', pore); 
   		}else if (requestName.equals('AcknowledgeOrderStatusUpdate')) {
   			response.put('response_x', alods); 
   		}
   }
}