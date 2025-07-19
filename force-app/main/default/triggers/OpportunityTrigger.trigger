trigger OpportunityTrigger on Opportunity (before update, after update, after delete) {
  
    Switch on Trigger.operationType{
        when BEFORE_UPDATE{
            //7. If the Opprotunity Stage is Modified, update Opportunity Amount, based on Probability*Expected Revenue
            OpportunityTriggerHandler.updateOpportunityAmount(Trigger.new, Trigger.oldMap);
            // Trigger.NEW: List<sObject> -> List<Opportunity> - new version of the data
            // Trigger.OLD: List<sObject> -> List<Opportunity> - older version of the data
            // Trigger.newMap: Map<Id,sobject> -> Map<Id,Opportunity> - new values in key value format
            // Trigger.oldMap: Map<Id,sobject> -> Map<Id,Opportunity> - old values in key value format
        }
        when AFTER_UPDATE{
            //5. Whenever an Opportunity is Closed Won, create a Task for the Opportunity Owner to split the revenue among the team 
            //   with high priority
         
            //It is a best practice to write your logic into a handler class
            OpportunityTriggerHandler.handleActivityAfterOppIsClosedWon(Trigger.new); //This will pass a list of new updated Opprotunity
          
            //15. As soon as Opportunity is Closed Lost, remove all Opportunity Team Members from the Opportunity
            OpportunityTriggerHandler.removeTeamMembersOnOppClosedLost(Trigger.new, Trigger.oldMap);
            
            //18. As soon as Opportunity Stage reaches Needs Analysis, add all users of role:Opportunists as a Team of this Opportunity
            OpportunityTriggerHandler.addAllUsersOfOpportunistsRoleAsTeamMember(Trigger.new, Trigger.oldMap);
            
            //25. As soon as an Opportunity is Closed Won, send out email messages to Opportunity Owner, Account Owner, Opportunity team
            //    members and all users under OpportunityMegaStar Public Group notifying about the win and the revenue.
            OpportunityTriggerHandler.notifyRespectiveMembersOnOppClosedWon(Trigger.new, Trigger.oldMap);
            
            //28. When the Opportunity Stage is set from Perception Analysis to Qualification or from Perception Analysis to Prospecting, 
            //    create a Reminder Task for the Opportunity Owner to check why the opportunity didn’t progress further. Remind them the 
            //    very next day when this happened.
            OpportunityTriggerHandler.remindOwnerOnStageUpdateAndCreateTask(Trigger.new, Trigger.oldMap);
        }
        when AFTER_DELETE{
            //13. As soon as an Opportunity is deleted, create a task for the Opportunity’s Account Owner to investigate why the record 
            //   was deleted and submit the information
            OpportunityTriggerHandler.createTaskToCheckWhyTheRecordDeleted(Trigger.old);
        }
    }
}
