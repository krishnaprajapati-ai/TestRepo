@isTest
private class OAuthKickoffTest {

    @TestSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>(); 

        leads.add(new Lead(
            FirstName   = 'John',
            LastName    = 'Doe',
            Company     = 'Acme Corp',
            Email       = 'john.doe@acme.com',
            Phone       = '1234567890',
            Status      = 'Open - Not Contacted',
            LeadSource  = 'Web',
            Title       = 'Manager',
            Street      = '123 Main St',
            City        = 'Austin',
            State       = 'TX',
            PostalCode  = '73301',
            Country     = 'US',
            Description = 'Test lead 1'
        ));

        leads.add(new Lead(
            FirstName  = 'Jane',
            LastName   = 'Smith',
            Company    = 'Globex Inc',
            Status     = 'Working - Contacted',
            LeadSource = 'Phone Inquiry'
        ));

        insert leads;
    }

    // Successful sync — 200 with all records succeeding
    @isTest
    static void testSyncLeads_Success() {
        List<Lead> leads = [SELECT Id FROM Lead];
        List<String> leadIds = new List<String>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        // Mock: all records succeed
        String mockResponse = '[' +
            '{"id":"00Qxx0000001234","success":true,"errors":[]},' +
            '{"id":"00Qxx0000005678","success":true,"errors":[]}' +
        ']';

        Test.setMock(HttpCalloutMock.class, new OAuthKickoffHttpMock(200, mockResponse));

        Test.startTest();
        String result = OAuthKickoff.syncLeadsToOrgB(leadIds);
        Test.stopTest();

        Assert.isTrue(result.contains('2 lead(s) synced successfully'), 'Should report 2 successful syncs');
    }

    // Partial success — some records fail
    @isTest
    static void testSyncLeads_PartialFailure() {
        List<Lead> leads = [SELECT Id FROM Lead];
        List<String> leadIds = new List<String>();
        for (Lead l : leads) {
            leadIds.add(l.Id);
        }

        String mockResponse = '[' +
            '{"id":"00Qxx0000001234","success":true,"errors":[]},' +
            '{"id":null,"success":false,"errors":[{"message":"Duplicate","statusCode":"DUPLICATE_VALUE"}]}' +
        ']';

        Test.setMock(HttpCalloutMock.class, new OAuthKickoffHttpMock(200, mockResponse));

        Test.startTest();
        String result = OAuthKickoff.syncLeadsToOrgB(leadIds);
        Test.stopTest();

        Assert.isTrue(result.contains('1 lead(s) synced successfully'), 'Should report 1 success');
        Assert.isTrue(result.contains('1 failed'), 'Should report 1 failure');
    }

    // HTTP error — non-200 status code
    @isTest
    static void testSyncLeads_HttpError() {
        List<Lead> leads = [SELECT Id FROM Lead LIMIT 1];
        List<String> leadIds = new List<String>{ leads[0].Id };

        String mockResponse = '{"errorCode":"SERVER_ERROR","message":"Internal error"}';

        Test.setMock(HttpCalloutMock.class, new OAuthKickoffHttpMock(500, mockResponse));

        Test.startTest();
        try {
            OAuthKickoff.syncLeadsToOrgB(leadIds);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Script-thrown exception'), 'Should throw error on non-200');
        }
        Test.stopTest();
    }

    // Null lead IDs
    @isTest
    static void testSyncLeads_NullIds() {
        Test.startTest();
        try {
            OAuthKickoff.syncLeadsToOrgB(null);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    // Empty lead IDs list
    @isTest
    static void testSyncLeads_EmptyIds() {
        Test.startTest();
        try {
            OAuthKickoff.syncLeadsToOrgB(new List<String>());
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }

    // Non-existent lead IDs
    @isTest
    static void testSyncLeads_InvalidIds() {
        List<String> fakeIds = new List<String>{ '00Q000000000000AAA' };

        Test.startTest();
        try {
            OAuthKickoff.syncLeadsToOrgB(fakeIds);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage());
        }
        Test.stopTest();
    }
}