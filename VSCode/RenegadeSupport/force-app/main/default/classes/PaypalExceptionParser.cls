public class PaypalExceptionParser
{
    public String name;	//CAPTURE_AMOUNT_LIMIT_EXCEEDED
    public String message;	//Capture amount specified exceeded allowable limit
    public String information_link;	//https://developer.paypal.com/webapps/developer/docs/api/#CAPTURE_AMOUNT_LIMIT_EXCEEDED
    public String debug_id;	//379e2a3ef418
    public static PaypalExceptionParser parse(String json)
    {
        return (PaypalExceptionParser) System.JSON.deserialize(json, PaypalExceptionParser.class);
    }
}