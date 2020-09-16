public class createPayment {
    /*
    public String intent; //sale
    public cls_payer payer;
    public cls_transactions[] transactions;
    class cls_payer {
        public String payment_method; //credit_card
        public cls_funding_instruments[] funding_instruments;
    }
    class cls_funding_instruments {
        public cls_credit_card credit_card;
    }
    class cls_credit_card {
        public String number1; //4417119669820331
        public String type; //visa
        public Integer expire_month; //11
        public Integer expire_year; //2018
        public String cvv2; //874
        public String first_name; //Betsy
        public String last_name; //Buyer
        public cls_billing_address billing_address;
    }
    class cls_billing_address {
        public String line1; //111 First Street
        public String city; //Saratoga
        public String state; //CA
        public String postal_code; //95070
        public String country_code; //US
    }
    class cls_transactions {
        public cls_amount amount;
        public String description; //This is the payment transaction description.
    }
    class cls_amount {
        public String total; //7.47
        public String currency1; //USD
        public cls_details details;
    }
    class cls_details {
        public String subtotal; //7.41
        public String tax; //0.03
        public String shipping; //0.03
    }
    public static createPayment parse(String json) 
    {
        return (createPayment) System.JSON.deserialize(json, createPayment.class);
    }
    public static String generateJSONContent(string line,string city,string state,string postal_code,string number1,
                                             string type, integer expire_month,integer expire_year,string cvv,string fname,
                                             string lname,string subtotal,string tax,string total) 
    {
        // Create an object to write to the JSON string.
        
        cls_billing_address cba = new cls_billing_address();
        cba.line1 =line; // '111 First Street';
        cba.city =city; // 'Saratoga';
        cba.state =state; // 'CA';
        cba.postal_code =postal_code; // '95070';
        cba.country_code = 'US';//
        
        cls_credit_card ccc = new cls_credit_card();
        
        ccc.number1 = number1; //'4293405113454010';
        ccc.type = type; //'visa';
        ccc.expire_month =expire_month; // 10;
        ccc.expire_year =expire_year; //2019;
        ccc.cvv2 = cvv; //'123';
        ccc.first_name =fname; // 'Betsy';
        ccc.last_name =lname; // 'Buyer';
        ccc.billing_address = cba;
        
        cls_funding_instruments cfi = new cls_funding_instruments();
        cfi.credit_card = ccc;
        
        List < cls_funding_instruments > flList = new List < cls_funding_instruments > ();
        flList.add(cfi);
        
        cls_payer cp = new cls_payer();
        cp.payment_method = 'credit_card';
        cp.funding_instruments = flList;
        
        cls_details cd = new cls_details();
        cd.subtotal = subtotal; //'7.41';
        cd.tax = tax; //'0.03';
        cd.shipping = '0.00';
        
        cls_amount ca = new cls_amount();
        ca.total =total;// '7.47';
        ca.currency1 = 'USD';
        ca.details = cd;
        
        cls_transactions clsTrans = new cls_transactions();
        clsTrans.amount = ca;
        clsTrans.description = 'This is the payment transaction description.';
        
        List < cls_transactions > transactList = new List < cls_transactions > ();
        transactList.add(clsTrans);
        
        
        
        createPayment x = new createPayment();
        x.intent = 'authorize';
        x.transactions = transactList;
        x.payer = cp;
        
        
        String s = json.serialize(x);
        system.debug('****serialized:' + s);
        s = s.replace('"currency1":', '"currency":');
        s = s.replace('"number1":', '"number":');
        system.debug('****replaced:' + s);
        return s;
    }
    */
}