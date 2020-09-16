public with sharing class EDIManager {
	
	@future(callout=true)
	public static void sendFilesRequest(){
		try{
			Heroku_setting__c setting = Heroku_setting__c.getinstance();
			string body = generateRequest();
			system.debug('body = ' + body);
			HttpRequest httpReq = new HttpRequest();
            Blob headerValue = Blob.valueOf(setting.Username__c+':'+setting.Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            system.debug('***:' + EncodingUtil.base64Encode(headerValue));
            httpReq.setHeader('Authorization', authorizationHeader);
	        httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('IsAProduction', ''+!runningInASandbox());
	        httpReq.setEndpoint(setting.URL__c);
	        httpReq.setBody(body);
	        httpReq.settimeout(80000);
	        httpReq.setMethod('POST');
	        Http h = new Http();
			try{
		        HttpResponse res = Test.isRunningTest() ? null : h.send(httpReq);
				system.debug('result = ' + res.getBody());
				list<Response> response = ((list<Response>)JSON.deserialize(res.getBody(), list<Response>.class));
			
				Log__c log = new Log__c(Process__c = 'Request EDI files', Data__c = body, Tries__c = 1, Status__c = 'Succeeded', Response__c = res.getBody());
				for (Response r : response){
					if (!r.success){
						log.Status__c = 'Failed';
						log.Error__c = r.message;
						break;
					}
				}
				insert log;
			}
			catch (exception ex){
				system.debug('ex.getmessage = ' + ex.getmessage() + ' ' + ex.getlinenumber());
				Log__c log = new Log__c(Process__c = 'Request EDI files', Data__c = body, Error__c = ex.getmessage() + ' ' + ex.getlinenumber(), Tries__c = 1, Status__c = 'Failed');
				insert log;
			}
		}
		catch (exception e){
			system.debug('e.getmessage() = ' + e.getmessage() + ' ' + e.getlinenumber());
			Log__c log = new Log__c(Process__c = 'Request EDI files', Error__c = e.getmessage() + ' ' + e.getlinenumber(), Tries__c = 1, Status__c = 'Failed');
			insert log;
		}
	}
	private static string generateRequest(){
		list<EDI_Map__mdt> ediMap = [select Username__c, URL__c, Port__c, Password__c, X855_path__c, X856_path__c, Failed_path__c, X855_file_name__c, Secured__c,
									X856_file_name__c, Failed_file_name__c, X855_handler_url__c, X856_handler_url__c, Failed_handler_url__c from EDI_Map__mdt
									where Inactive__c = false];
		Request req = new Request();
		req.manufacturers = new list<Manufacturer>();
		for (EDI_Map__mdt m : ediMap){
			Manufacturer manufacturer = new Manufacturer();
			manufacturer.username = m.Username__c;
			manufacturer.password = m.Password__c;
			manufacturer.url = m.URL__c;
			manufacturer.port = m.Port__c;
			manufacturer.secured = m.Secured__c;
			manufacturer.fileSettingList = new list<FileSetting>();
			manufacturer.fileSettingList.add(new FileSetting(m.X855_path__c, m.X855_file_name__c, m.X855_handler_url__c));
			manufacturer.fileSettingList.add(new FileSetting(m.X856_path__c, m.X856_file_name__c, m.X856_handler_url__c));
			manufacturer.fileSettingList.add(new FileSetting(m.Failed_path__c, m.Failed_file_name__c, m.Failed_handler_url__c));
			req.manufacturers.add(manufacturer);
		}
        system.debug(req.manufacturers);
		return json.serialize(req);
	}
    
    private static Boolean runningInASandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }

	public class Request{
		public list<Manufacturer> manufacturers {get; set;}
	}
	public class Manufacturer{
		public string username {get; set;}
		public string password {get; set;}
		public string url {get; set;}
		public string port {get; set;}
		public boolean secured {get; set;}
		public list<FileSetting> fileSettingList {get; set;}
	}
	public class FileSetting{
		public string path {get; set;}
		public string name {get; set;}
		public string url {get; set;}
		
		public FileSetting(string path, string name, string url){
			this.path = path;
			this.name = name;
			this.url = url;
		}
	}

	public class Response{
		public string URL {get; set;}
		public boolean success {get; set;}
		public string message {get; set;}
	}
}