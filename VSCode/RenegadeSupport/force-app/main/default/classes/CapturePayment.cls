public class CapturePayment
{
	public cls_amount amount;
	public boolean is_final_capture;
	
    class cls_amount 
    {
		public String currency1;	//USD
		public String total;	//600.05
	}
	
    public static CapturePayment parse(String json)
    {
		return (CapturePayment) System.JSON.deserialize(json, CapturePayment.class);
	}
    
    public static String generateJSONContent(string total) 
    {       
       CapturePayment.cls_amount cls=new CapturePayment.cls_amount();
        cls.currency1='USD';
        cls.total=total; //'7.47'
        CapturePayment x =new CapturePayment();
        x.amount=cls;
        x.is_final_capture=true;
        String s = json.serialize(x);
        system.debug('****serialized:' + s);
        s = s.replace('"currency1":', '"currency":');
        s = s.replace('"number1":', '"number":');
        system.debug('****replaced:' + s);
        return s;
    }
    
}