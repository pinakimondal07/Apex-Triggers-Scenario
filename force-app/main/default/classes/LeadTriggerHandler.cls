public class LeadTriggerHandler {
    public static void createtaskToFollowUpWithCustomer(List<Lead> leads){
        List<Task> followupTask = new List<Task>();
        for(Lead leadsTask : leads){
            Task taskRecord = new Task();
            taskRecord.WhoId = leadsTask.Id;  //If the related record is Contact or Lead use 'WhoId' else use 'WhatId' for relation
            taskRecord.OwnerId = leadsTask.OwnerId;
            taskRecord.Description = 'Follow-up with the Customer';
            taskRecord.Subject = 'Follow-up';
            taskRecord.Priority = 'High';
            followupTask.add(taskRecord);
        }
        if(!followupTask.isEmpty())
        insert followupTask;
    }
    
    public static void validationToRestrictDeleteIfWorkingContacted(List<Lead> newRecords){
        for(Lead leads : newRecords){
            if(leads.Status == 'Working-Contacted')
                leads.addError('This Lead cannot be deleted as its status is Working-Contacted');
        }
    }
    
    public static void restrictUpdateIfCreateDateIsMoreThan8(List<Lead> newRecords){
        for(Lead leadToUpdate : newRecords){
            if(leadToUpdate.CreatedDate.addDays(8) < System.today())
                leadToUpdate.addError('This Lead cannot be modified as it was created more than 8 days ago');
        }
    }
}