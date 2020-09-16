@isTest
global class DispatchHttpCalloutMock implements HttpCalloutMock {
 global HTTPResponse respond(HTTPRequest req) {
        
        System.assertEquals('https://null//api/v1/exports/orders.xml', req.getEndpoint());
        System.assertEquals('POST', req.getMethod());
        
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"foo":"bar"}');
        res.setStatusCode(200);
        return res;
    }

}