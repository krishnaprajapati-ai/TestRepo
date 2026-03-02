public with sharing class ContactDataTableControllers {
    
    @AuraEnabled(cacheable=true) 
    public static List<Lead> getAccounts(String searchName, String leadSourceName) {
        
        // Case 1: searchName AND leadSource provided
        if (!String.isBlank(searchName) && !String.isBlank(leadSourceName)) { 
            List<Lead> leadList = new List<Lead>();
            leadList = [SELECT Id, Name, Status, Phone, LeadSource
                        FROM Lead
                        WHERE Name LIKE :('%' + searchName + '%')
                        AND LeadSource = :leadSourceName
                       ];
            system.debug('the lead list with both name and source --->'+leadList);
            
            return [
                SELECT Id, Name, Status, Phone, LeadSource
                FROM Lead
                WHERE Name LIKE :('%' + searchName + '%')
                AND LeadSource = :leadSourceName
            ];
        }
        
        // Case 2: only searchName provided
        if (!String.isBlank(searchName)) {
            List<Lead> leadList = new List<Lead>();
            leadList = [              SELECT Id, Name, Status, Phone, LeadSource
                        FROM Lead
                        WHERE Name LIKE :('%' + searchName + '%')
                       ];
            system.debug('the lead list with name --->'+leadList);
            return [
                SELECT Id, Name, Status, Phone, LeadSource
                FROM Lead
                WHERE Name LIKE :('%' + searchName + '%')
            ];
        }
        
        // Case 3: only leadSource provided
        if (!String.isBlank(leadSourceName)) {
            List<Lead> leadList = new List<Lead>();
            leadList = [SELECT Id, Name, Status, Phone, LeadSource
                FROM Lead
                WHERE LeadSource = :leadSourceName
                       ];
            system.debug('the lead list with SOURCE --->'+leadList);            
            return [
                SELECT Id, Name, Status, Phone, LeadSource
                FROM Lead
                WHERE LeadSource = :leadSourceName
            ];
        }
        
        // Case 4: no filters → return all leads
        List<Lead> leadList = new List<Lead>();
        leadlist = [Select Id , Name , Status , Phone ,LeadSource  From Lead Limit 50];
        system.debug('the lead list with no condition is ------>'+leadList);
        return [
            SELECT Id, Name, Status, Phone, LeadSource
            FROM Lead 
        ];
    }
}