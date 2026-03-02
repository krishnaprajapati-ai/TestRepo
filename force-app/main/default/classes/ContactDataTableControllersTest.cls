@isTest
private class ContactDataTableControllersTest {

    @TestSetup
    static void setupTestData() {
        List<Lead> leads = new List<Lead>(); 

        leads.add(new Lead(
            FirstName = 'John',
            LastName  = 'Doe',
            Company   = 'Acme Corp',
            Status    = 'Open - Not Contacted',
            Phone     = '1234567890',
            LeadSource = 'Web'
        ));

        leads.add(new Lead(
            FirstName = 'Jane',
            LastName  = 'Smith',
            Company   = 'Globex Inc',
            Status    = 'Working - Contacted',
            Phone     = '0987654321',
            LeadSource = 'Phone Inquiry'
        ));

        leads.add(new Lead(
            FirstName = 'Bob',
            LastName  = 'Johnson',
            Company   = 'Initech',
            Status    = 'Open - Not Contacted',
            Phone     = '5551234567',
            LeadSource = 'Web'
        ));

        insert leads;
    }

    // Case 1: Both searchName and leadSourceName provided
    @isTest
    static void testGetAccounts_BothFilters() {
        List<Lead> results = ContactDataTableControllers.getAccounts('John', 'Web');

        Assert.areEqual(2, results.size(), 'Should return 2 leads matching name and source');
        Assert.areEqual('Web', results[0].LeadSource);
        Assert.isTrue(results[0].Name.contains('John'));
    }

    // Case 2: Only searchName provided
    @isTest
    static void testGetAccounts_SearchNameOnly() {
        List<Lead> results = ContactDataTableControllers.getAccounts('Jo', null);

        // Should match John Doe and Bob Johnson
        Assert.areEqual(2, results.size(), 'Should return leads matching partial name "Jo"');
    }

    // Case 3: Only leadSourceName provided
    @isTest
    static void testGetAccounts_LeadSourceOnly() {
        List<Lead> results = ContactDataTableControllers.getAccounts(null, 'Web');

        Assert.areEqual(2, results.size(), 'Should return all Web leads');
        for (Lead l : results) {
            Assert.areEqual('Web', l.LeadSource);
        }
    }

    // Case 4: No filters — return all leads
    @isTest
    static void testGetAccounts_NoFilters() {
        List<Lead> results = ContactDataTableControllers.getAccounts(null, null);

        Assert.areEqual(3, results.size(), 'Should return all test leads');
    }

    // Edge case: Empty strings instead of null
    @isTest
    static void testGetAccounts_EmptyStrings() {
        List<Lead> results = ContactDataTableControllers.getAccounts('', '');

        Assert.areEqual(3, results.size(), 'Empty strings should behave like no filters');
    }

    // Edge case: Both filters with no matching results
    @isTest
    static void testGetAccounts_NoMatch() {
        List<Lead> results = ContactDataTableControllers.getAccounts('ZZZ', 'Web');

        Assert.areEqual(0, results.size(), 'Should return no leads for non-matching name');
    }
}