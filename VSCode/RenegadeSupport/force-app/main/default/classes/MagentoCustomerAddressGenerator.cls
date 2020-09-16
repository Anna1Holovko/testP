public class MagentoCustomerAddressGenerator 
{
    public string firstname;
    public string lastname;
    public list<string> street;
    public String city;	
    public String region;	
    public String postcode;
    public String country_id;	
    public string telephone;
    public Integer is_default_billing;
    public Integer is_default_shipping;
    public MagentoCustomerAddressGenerator(string fname,string lname,string streetvar,string cityVar,string state,string zipcode,string addressType,string phone)
    {
        firstname=fname;
        lastname=lname;
        street=new list<string>();
        street.add(streetvar);
        city=cityVar;
        region=state;
        postcode=zipcode;
        country_id='US';
        telephone=phone;
        if(addressType=='Billing')
        {
            is_default_billing=1;
            is_default_shipping=0;
            
        }
        else if(addressType=='Shipping')
        {
            is_default_shipping=1;
            is_default_billing=0;
        }
        
    }
}