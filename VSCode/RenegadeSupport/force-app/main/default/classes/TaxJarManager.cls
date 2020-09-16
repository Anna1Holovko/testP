public without sharing class TaxJarManager {
    
    public static void submitTaxJarTransaction(string soId){
        if(System.isBatch()){
            submitTransaction(soId);
        }else{
            submitTransactionFuture(soId);
        }
    }
    @future (callout=true)
    public static void submitTransactionFuture(string soId){
        submitTransaction(soId);
    }
    
    public static void submitTransaction(string soId){
        string body = '';
        TaxJar_Setting__c setting = TaxJar_Setting__c.getInstance();
        try{
            HttpRequest httpReq = new HttpRequest();
            httpReq.setHeader('Content-Type', 'application/json');
            httpReq.setHeader('Authorization', 'Bearer ' + setting.Token__c);
            string endPoint = setting.URL__c;
            httpReq.setEndpoint(endPoint);
            httpReq.setMethod('POST');
            system.debug('endPoint = ' + endPoint);
            body = generateBody(soId);
            httpReq.setBody(body);
            Http h = new Http();
            HttpResponse res = h.send(httpReq);
            System.debug('res.getBody() = ' + res.getBody());
            TaxJarManager.Response response = (TaxJarManager.Response ) JSON.deserialize(res.getBody(), TaxJarManager.Response.class);
            Sales_Order__c so = new Sales_Order__c(id = soId);
            so.TaxJar_request__c = body;
            so.TaxJar_response__c = res.getBody();
            so.Resend_to_TaxJar__c = false;
            if (response.detail == null || response.detail == ''){
                so.TaxJar_updated_successfully__c = true;
                so.TaxJar_error__c = '';
            }
            else {
                so.TaxJar_error__c = response.detail;
            }
            update so;
            //return response;
        }catch (Exception e){
            system.debug('e.getmessage() = ' + e.getmessage());
            Sales_Order__c so = new Sales_Order__c(id = soId);
            so.TaxJar_request__c = body;
            so.Resend_to_TaxJar__c = false;
            so.TaxJar_error__c = e.getmessage() + ' - ' + e.getlinenumber();
            update so;
            //return response;
        }
    }
    public static string generateBody(string soId){
        Sales_Order__c so = [SELECT Magento_order_No__c, Shipping_Street__c, Shipping_State__c, Shipping_City__c, Shipping_ZipCode__c, Sub_Total__c, Shipping_Handle__c,
                             TaxAmount__c, Discount_AmountTotal__c, 
                             (SELECT Quantity__c, ProductSKU__c, Product_Name__c, Price__c, TaxAmount__c 
                              FROM SO_Line_Items__r
                              WHERE Products__r.RecordType.name != 'Bundled' or Bundle_Item__c != null)
                             FROM Sales_Order__c
                             WHERE Id = :soId];
        Request req = new Request();
        Decimal amount = 0;
        if (so.Sub_Total__c != null) {
            amount += so.Sub_Total__c;
        }
        if (so.Shipping_Handle__c != null) {
            amount += so.Shipping_Handle__c;
        }
        req.transaction_id = so.Magento_order_No__c;
        req.transaction_date = string.valueof(system.today());
        req.to_country = 'US';
        req.to_zip = so.Shipping_ZipCode__c;
        req.to_state = Utilities.getStateinitial(so.Shipping_State__c);
        req.to_city = so.Shipping_City__c;
        req.to_street = so.Shipping_Street__c;
        req.amount = amount;
        req.shipping = so.Shipping_Handle__c;
        req.sales_tax = so.TaxAmount__c;
        req.discount = so.Discount_AmountTotal__c;
        list<LineItemReq> lis = new list<LineItemReq>();
        for (SO_Line_Items__c sli : so.SO_Line_Items__r){
            LineItemReq li = new LineItemReq();
            li.quantity = integer.valueof(sli.Quantity__c);
            li.product_identifier = sli.ProductSKU__c;
            li.description = sli.Product_Name__c;
            li.unit_price = sli.Price__c;
            li.sales_tax = sli.TaxAmount__c;
            lis.add(li);
        }
        req.line_items = lis;
        string reqStr = Json.serialize(req);
        system.debug('reqStr = ' + reqStr);
        return reqStr;
    }
    
    public class Response{
        public Order order { get; set; }
        public string error  { get; set; }
        public string detail  { get; set; }
        public string status  { get; set; }
    }
    
    public class Request{
        public string transaction_id  { get; set; }
        public string transaction_date  { get; set; }
        public string to_country  { get; set; }
        public string to_zip  { get; set; }
        public string to_state  { get; set; }
        public string to_city  { get; set; }
        public string to_street  { get; set; }
        public decimal amount  { get; set; }
        public decimal shipping  { get; set; }
        public decimal sales_tax  { get; set; }
        public decimal discount  { get; set; }
        public list<LineItemReq> line_items  { get; set; }
    }
    
    public class Order{
        public string transaction_id  { get; set; }
        public integer user_id { get; set; }
        public string transaction_date  { get; set; }
        public string transaction_reference_id  { get; set; }
        public string customer_id { get; set; }
        public string from_country  { get; set; }
        public string from_zip  { get; set; }
        public string from_state  { get; set; }
        public string from_city  { get; set; }
        public string from_street  { get; set; }
        public string to_country  { get; set; }
        public string to_zip  { get; set; }
        public string to_state  { get; set; }
        public string to_city  { get; set; }
        public string to_street  { get; set; }
        public decimal amount  { get; set; }
        public decimal shipping  { get; set; }
        public decimal sales_tax  { get; set; }
        public list<LineItem> line_items  { get; set; }
        
        
        public string discount  { get; set; }
    }
    
    public class LineItem{
        public integer id { get; set; }
        public decimal quantity { get; set; }
        public string product_identifier  { get; set; }
        public string product_tax_code  { get; set; }
        public string description  { get; set; }
        public decimal unit_price  { get; set; }
        public decimal discount  { get; set; }
        public decimal sales_tax  { get; set; }
    }
    
    public class LineItemReq{
        public integer quantity { get; set; }
        public string product_identifier  { get; set; }
        public string description  { get; set; }
        public decimal unit_price  { get; set; }
        public decimal sales_tax  { get; set; }
    }
}