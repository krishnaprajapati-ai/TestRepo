public with sharing class OAuthKickoff {

    @AuraEnabled
    public static String syncLeadsToOrgB(List<String> leadIds) { 
        try {
            if(leadIds == null || leadIds.isEmpty()) {
                throw new AuraHandledException('No leads selected to sync');
            }
            
            System.debug('📤 Lead IDs to sync: ' + leadIds);
            
            // Get Lead data from Org A
            List<Lead> leadsToSync = [
                SELECT Id, FirstName, LastName, Company, Email, Phone, 
                       Status, LeadSource, Title, Street, City, State, 
                       PostalCode, Country, Description
                FROM Lead 
                WHERE Id IN :leadIds
            ];
            
            
            if(leadsToSync.isEmpty()) {
                throw new AuraHandledException('No leads found with provided IDs');
            }
            
            System.debug('📋 Found ' + leadsToSync.size() + ' leads to sync');
            
            // Prepare records for Composite API
            List<Map<String, Object>> records = new List<Map<String, Object>>();
            
            for(Lead l : leadsToSync) {
                Map<String, Object> record = new Map<String, Object>();
                
                // Required attribute for Salesforce
                record.put('attributes', new Map<String, Object>{'type' => 'Lead'});
                
                // Add Lead fields (only non-null values)
                if(String.isNotBlank(l.FirstName)) record.put('FirstName', l.FirstName);
                if(String.isNotBlank(l.LastName)) record.put('LastName', l.LastName);
                if(String.isNotBlank(l.Company)) record.put('Company', l.Company);
                if(String.isNotBlank(l.Email)) record.put('Email', l.Email);
                if(String.isNotBlank(l.Phone)) record.put('Phone', l.Phone);
                if(String.isNotBlank(l.Status)) record.put('Status', l.Status);
                if(String.isNotBlank(l.LeadSource)) record.put('LeadSource', l.LeadSource);
                if(String.isNotBlank(l.Title)) record.put('Title', l.Title);
                if(String.isNotBlank(l.Street)) record.put('Street', l.Street);
                if(String.isNotBlank(l.City)) record.put('City', l.City);
                if(String.isNotBlank(l.State)) record.put('State', l.State);
                if(String.isNotBlank(l.PostalCode)) record.put('PostalCode', l.PostalCode);
                if(String.isNotBlank(l.Country)) record.put('Country', l.Country);
                if(String.isNotBlank(l.Description)) record.put('Description', l.Description);
                
                records.add(record);
            }
            
            // Create composite request body
            Map<String, Object> compositeRequest = new Map<String, Object>();
            compositeRequest.put('allOrNone', false);
            compositeRequest.put('records', records);
            
            String jsonBody = JSON.serialize(compositeRequest);
            System.debug('📤 Request Body: ' + jsonBody);
            
            // Make HTTP Request
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:Org_B_REST/services/data/v60.0/composite/sobjects/');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setBody(jsonBody);
            req.setTimeout(60000);
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            System.debug('📥 Status Code: ' + res.getStatusCode());
            System.debug('📥 Response: ' + res.getBody());
            
            // Process response
            if(res.getStatusCode() == 200) {
                List<Object> results = (List<Object>) JSON.deserializeUntyped(res.getBody());
                Integer successCount = 0;
                Integer errorCount = 0;
                
                for(Object result : results) {
                    Map<String, Object> resultMap = (Map<String, Object>) result;
                    Boolean success = (Boolean) resultMap.get('success');
                    if(success) {
                        successCount++;
                    } else {
                        errorCount++;
                        System.debug('❌ Failed record: ' + resultMap);
                    }
                }
                
                String message = successCount + ' lead(s) synced successfully';
                if(errorCount > 0) {
                    message += ', ' + errorCount + ' failed. Check debug logs for details.';
                }
                
                System.debug('✅ ' + message);
                return message;
                
            } else {
                throw new AuraHandledException('Sync failed: ' + res.getBody());
            }
            
        } catch (Exception e) {
            System.debug('❌ Error: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
}