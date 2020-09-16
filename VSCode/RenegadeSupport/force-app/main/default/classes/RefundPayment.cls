public class RefundPayment{
	public cls_amount amount;
	class cls_amount {
		public String currency1;	//USD
		public String total;	//110.54
	}
	public static RefundPayment parse(String json){
		return (RefundPayment) System.JSON.deserialize(json, RefundPayment.class);
	}
    public static String generateJSONContent(string refundAmount,string currencyType) 
    {       
      
        RefundPayment.cls_amount amountObject=new RefundPayment.cls_amount();
        amountObject.currency1=currencyType;
        amountObject.total=refundAmount;
        RefundPayment payment=new RefundPayment();
        payment.amount=amountObject;
        String request = json.serialize(payment);
        system.debug('****serialized:' + request);
        request= request.replace('"currency1":', '"currency":');
        system.debug('****replaced:' + request);
        return request;
    }
    

	
}