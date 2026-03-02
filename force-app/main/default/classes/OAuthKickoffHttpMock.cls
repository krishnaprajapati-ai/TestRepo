@isTest
public class OAuthKickoffHttpMock implements HttpCalloutMock {

    private Integer statusCode;
    private String responseBody;

    public OAuthKickoffHttpMock(Integer statusCode, String responseBody) {
        this.statusCode = statusCode;
        this.responseBody = responseBody;
    }

    public HTTPResponse respond(HTTPRequest req) { 
        HttpResponse res = new HttpResponse();
        res.setStatusCode(this.statusCode);
        res.setHeader('Content-Type', 'application/json');
        res.setBody(this.responseBody);
        return res;
    }
}