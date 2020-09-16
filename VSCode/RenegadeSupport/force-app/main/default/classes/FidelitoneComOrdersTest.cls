@isTest
private class FidelitoneComOrdersTest {
	
	@isTest static void test_method_one() {
		FidelitoneComOrders.ShipmentStatus ss = new FidelitoneComOrders.ShipmentStatus();
		ss.EventID = 5;
		ss.EventDate = 'teset';
		ss.StatusCode = 'teset';
		ss.StatusDescription = 'teset';
		ss.DispatchStatus = 'teset';
		ss.DeliveryCode = 'teset';
		ss.DeliveryDate = 'teset';
		ss.DeliveryTime = 'teset';
		ss.TimeCode = 'teset';

		FidelitoneComOrders.OrderStatus os = new FidelitoneComOrders.OrderStatus();
		os.OrderId = 5;
		os.OrderNbr = 'etst';
		os.CarrierCode = 'etst';
		os.OriginalOrderNbr = 'etst';

		FidelitoneComOrders.DetailLine dl = new FidelitoneComOrders.DetailLine();
		dl.ItemCode = 'test';
		dl.CustomerItemNumber = 'test';
		dl.OrderQty = 1;
		dl.UnitOfMeasure = 'test';
		dl.Weight = 2.3;
		dl.LotNumber = 'test';
		dl.RetailValue = 222;
		dl.Volume = 2.2;
		dl.UoM = 'test';
		dl.CustomerField1 = 'test';
		dl.CustomerField2 = 'test';
		dl.CustomerField3 = 'test';
		dl.StopType = 'test';

		Test.setMock(WebServiceMock.class, new FidelitoneMock());
		Test.startTest();

		FidelitoneComOrders.AcknowledgeOrderStatusUpdateResponse_element alods = new FidelitoneComOrders.AcknowledgeOrderStatusUpdateResponse_element();
		FidelitoneComOrders.GetOrderStatusUpdates_element geos = new FidelitoneComOrders.GetOrderStatusUpdates_element();
		FidelitoneComOrders.ArrayOfDetailLine adl = new FidelitoneComOrders.ArrayOfDetailLine();
		FidelitoneComOrders.AcknowledgeOrder alo = new FidelitoneComOrders.AcknowledgeOrder();
		FidelitoneComOrders.PlaceOrder_element poe = new FidelitoneComOrders.PlaceOrder_element();
		FidelitoneComOrders.PlaceOrderResponse_element pore = new FidelitoneComOrders.PlaceOrderResponse_element();
		FidelitoneComOrders.ArrayOfShipmentStatus aoss = new FidelitoneComOrders.ArrayOfShipmentStatus();
		FidelitoneComOrders.PODImage pod = new FidelitoneComOrders.PODImage();
		FidelitoneComOrders.ArrayOfUpdateOrder aofud = new FidelitoneComOrders.ArrayOfUpdateOrder();
		FidelitoneComOrders.ArrayOfUpdateEvent aofu = new FidelitoneComOrders.ArrayOfUpdateEvent();
		FidelitoneComOrders.ArrayOfDetailComment aodc = new FidelitoneComOrders.ArrayOfDetailComment();
		FidelitoneComOrders.DetailComment dc = new FidelitoneComOrders.DetailComment();
		FidelitoneComOrders.GetOrderStatusUpdatesResponse_element gosu = new FidelitoneComOrders.GetOrderStatusUpdatesResponse_element();
		FidelitoneComOrders.ArrayOfPODImage aofd = new FidelitoneComOrders.ArrayOfPODImage();
		FidelitoneComOrders.ArrayOfOrderStatus afos = new FidelitoneComOrders.ArrayOfOrderStatus();
		FidelitoneComOrders.ArrayOfOrder arroo = new FidelitoneComOrders.ArrayOfOrder();
		FidelitoneComOrders.OrderStatusRequest ors = new FidelitoneComOrders.OrderStatusRequest();
		ors.OrderID = 'test';
		ors.Client = 'test';
		ors.StartDate = 'test';
		ors.EndDate = 'test';
		ors.IgnoreAcknowledgement = 'test';
		FidelitoneComOrders.UpdateOrder uo = new FidelitoneComOrders.UpdateOrder();
		FidelitoneComOrders.AcknowledgeOrderStatusUpdate_element aos = new FidelitoneComOrders.AcknowledgeOrderStatusUpdate_element();
		FidelitoneComOrders.UpdateEvent ue = new FidelitoneComOrders.UpdateEvent();
		FidelitoneComOrders.OrdersService oss = new FidelitoneComOrders.OrdersService();

		oss.GetOrderStatusUpdates(ors);
		oss.PlaceOrder(arroo);
		oss.AcknowledgeOrderStatusUpdate(alo);

		Test.stopTest();

	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}