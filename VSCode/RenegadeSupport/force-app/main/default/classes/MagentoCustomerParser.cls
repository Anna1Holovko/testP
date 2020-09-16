public class MagentoCustomerParser
{
	public String entity_id;	//64795
	public String website_id;	//1
	public String email;	//angana@renegadefurniture.com
	public String group_id;	//1
	public String created_at;	//2016-03-14 21:21:50
	public String updated_at;	//2016-03-14 21:21:50
	public String disable_auto_group_change;	//0
	public String created_in;	//Admin
	public String firstname;	//Angana
	public String lastname;	//Gosh
    public string authnetcim_profile_id; //1204221062
    
	public static MagentoCustomerParser parse(String json)
    {
		return (MagentoCustomerParser) System.JSON.deserialize(json, MagentoCustomerParser.class);
	}

}