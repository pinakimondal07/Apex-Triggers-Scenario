trigger LeadTrigger on Lead (before update, after insert, before delete) {
    //2. Whenever a Lead record is updated, set the Lead Status to 'Working-Contacted'
    //Switch on Trigger.operationType{
    //    when BEFORE_UPDATE{
    //        for(Lead updateLeadStatus : Trigger.new){
    //            updateLeadStatus.Status = 'Working-Contacted';
    //        }
    //    }
    //}
    
    
    //4. Whenever a Lead is updated and Industry is HealthCare, set Lead Source as Purchased List, SIC Code as 1100, Primary as Yes
    Switch on Trigger.operationType{
        when BEFORE_UPDATE{
            for(Lead leadToCheck : Trigger.new){
                //2. Whenever a Lead record is updated, set the Lead Status to 'Working-Contacted'
                leadToCheck.Status = 'Working-Contacted';  //Setting the fild as per the scenario 2
                if(leadToCheck.Industry == 'Healthcare'){
                    leadToCheck.LeadSource = 'Purchased List';
                    leadToCheck.SICCode__c = '1100';
                    leadToCheck.Primary__c = 'Yes';
                }
            }
            
            //27. Do not allow a user to modify the Lead record if the Lead is created before 8 days from today
            LeadTriggerHandler.restrictUpdateIfCreateDateIsMoreThan8(Trigger.new);
        }
        //6. As soon as a Lead record is created, create a Task for the Lead Owner to follow up with the Customer
        when AFTER_INSERT{
            LeadTriggerHandler.createtaskToFollowUpWithCustomer(Trigger.new);
        }
        //12. Do not allow Lead deletion if it is Working-Contacted
        when BEFORE_DELETE{
            LeadTriggerHandler.validationToRestrictDeleteIfWorkingContacted(Trigger.old);
        }
    }
}