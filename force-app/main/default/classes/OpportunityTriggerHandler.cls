public class OpportunityTriggerHandler {

    public static void handleActivityAfterOppIsClosedWon(List<Opportunity> newRecords){
        List<Task> taskListToInsert = new List<Task>();
        for(Opportunity opp : newRecords){
            if(opp.StageName == 'Closed Won'){
                //Create a related record
                Task taskRecord = new Task();
                taskRecord.WhatId = opp.Id;  //It will asign this task to the Opportunity
                taskRecord.Priority='High';
                taskRecord.OwnerId = opp.OwnerId;
                taskRecord.Description = 'Please split the revenue among the Team members';
                taskRecord.Subject = 'Split Revenue';
                
                //Adding the values to updated to the task list 
                taskListToInsert.add(taskRecord);               
            }
        }
        
        if(!taskListToInsert.isEmpty())
            insert taskListToInsert;
    }
    
    public static void updateOpportunityAmount(List<Opportunity> opp, Map<Id,Opportunity> oldOppMap){
        for(Opportunity oppNew : opp){
            if(oppNew.StageName != oldOppMap.get(oppNew.Id).StageName){
                //oldOppMap.get(oppNew.Id).StageName) --> from the oldMap get the unique Id of the Opportunity and then get its StageName 
                oppNew.Amount = oppNew.Probability*oppNew.ExpectedRevenue;
            }
        }
    }
    
    public static void createTaskToCheckWhyTheRecordDeleted(List<Opportunity> deletedOppRecords){
        Set<Id> accountIds = new Set<Id>();  //To store the unique Account Ids of the deleted Opportunity
        for(Opportunity opp : deletedOppRecords){
            if(opp.AccountId != null)
                accountIds.add(opp.AccountId);
        }
        Map<Id, Account> oppToAccId = new Map<Id, Account>([Select Id, OwnerId from Account where Id IN :accountIds]);
        List<Task> taskList = new List<Task>();
        for(Opportunity opp : deletedOppRecords){
            if(opp.AccountId != null){
                Task investigationTask = new Task();
                //investigationTask.WhatId = opp.Id;  //once deleted there will be no Opportunitty Id
                investigationTask.Priority = 'High';
                investigationTask.Subject = 'Investigation for deleted Opportunity';
                investigationTask.Description = 'Please investigate why the Opportunity : '+ opp.Name +' was deleted ?';
                investigationTask.Status = 'Not Started';
                //investigationTask.OwnerId = opp.Account.OwnerId  //This is not working so we need to query the Opportunity's Account OwnerId
                investigationTask.OwnerId = oppToAccId.get(opp.AccountId).OwnerId;
                taskList.add(investigationTask);
            }
        }
        if(!taskList.isEmpty())
            insert taskList;
    }
    
    public static void removeTeamMembersOnOppClosedLost(List<Opportunity> newRecords, Map<Id, Opportunity> oldOppMap){
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : newRecords){
            oppIds.add(opp.Id);
        }
        List<OpportunityTeamMember> memberList = new List<OpportunityTeamMember>([Select Id, OpportunityId from OpportunityTeamMember where OpportunityId IN : oppIds]);
        List<OpportunityTeamMember> membersToBeDeleted = new List<OpportunityTeamMember>();
        for(Opportunity opp : newRecords){
            if(opp.StageName == 'Closed Lost'){
                for(OpportunityTeamMember teamMemberList : memberList){
                    if(opp.Id == teamMemberList.OpportunityId)
                        membersToBeDeleted.add(teamMemberList);
                }
            }
        }
        if(!membersToBeDeleted.isEmpty())
            delete membersToBeDeleted;
    }
    
    public static void addAllUsersOfOpportunistsRoleAsTeamMember(List<Opportunity> newRecords, Map<Id, Opportunity> oldMap){
        List<OpportunityTeamMember> listOfMembersToAdd = new List<OpportunityTeamMember>();
        List<User> opportunistRoleUsers = [SELECT Id, UserRole.Name FROM User WHERE UserRole.Name = 'Opportunists' AND isActive = True];
        //We can fetch Role filed values directly from the User object using the '.' operator like UserRole.Id, UserRole.Name, UserRole.ParentRoleId 
        for(Opportunity opp : newRecords){
            if(opp.StageName == 'Needs Analysis' && opp.StageName != oldMap.get(opp.Id).StageName){
                for(user opportunistRoleUser : opportunistRoleUsers){
                    OpportunityTeamMember membersToBeAdded = new OpportunityTeamMember();
                    membersToBeAdded.OpportunityId = opp.Id;
                    membersToBeAdded.OpportunityAccessLevel = 'Edit';
                    membersToBeAdded.UserId = opportunistRoleUser.Id;
                    listOfMembersToAdd.add(membersToBeAdded);
                }            
            }
        }
        if(!listOfMembersToAdd.isEmpty())
            insert listOfMembersToAdd;
    }
    
    public static void remindOwnerOnStageUpdateAndCreateTask(List<Opportunity> newRecords, Map<Id, Opportunity> oldOppMap){
        List<Task> tasksToCreate = new List<Task>();
        for(Opportunity opp : newRecords){
            if(opp.StageName != oldOppMap.get(opp.Id).StageName){
                if((oldOppMap.get(opp.Id).StageName == 'Perception Analysis' && opp.StageName == 'Qualification') || 
                   (oldOppMap.get(opp.Id).StageName == 'Perception Analysis' && opp.StageName == 'Prospecting')){
                       Task reminderTask = new Task();
                       reminderTask.WhatId = opp.Id;
                       reminderTask.Description = 'Check why the opportunity was not able to progress further?';
                       reminderTask.Subject = 'Reminder Task';
                       reminderTask.Priority = 'High';
                       reminderTask.IsReminderSet = true;
                       reminderTask.ReminderDateTime = System.today() + 1;
                       tasksToCreate.add(reminderTask);
                   }
            }
        }
        if(!tasksToCreate.isEmpty())
            insert tasksToCreate;
    }
    
    public static void notifyRespectiveMembersOnOppClosedWon(List<Opportunity> newRecords, Map<Id, Opportunity> oldOppMap){
        Set<Id> listOfUsersToNotify = new Set<Id>();
        List<Id> oppIds = new List<Id>();
        List<Id> relatedAccountIdList = new List<Id>();
        for(Opportunity opp : newRecords){
            oppIds.add(opp.Id);
            relatedAccountIdList.add(opp.AccountId);
        }
        
        Map<Id, Account> relatedAccounts = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id IN : relatedAccountIdList]);
        List<OpportunityTeamMember> oppTeamMembers =new List<OpportunityTeamMember>([SELECT UserId, OpportunityId FROM OpportunityTeamMember WHERE OpportunityId IN : oppIds]);
        System.debug(oppTeamMembers);
        for(Opportunity updatedOpp : newRecords){
            if((updatedOpp.StageName == 'Closed Won') && (oldOppMap.get(updatedOpp.Id).StageName != updatedOpp.StageName)){
                listOfUsersToNotify.add(updatedOpp.OwnerId);
                listOfUsersToNotify.add(relatedAccounts.get(updatedOpp.AccountId).OwnerId);
                for(OpportunityTeamMember otm : oppTeamMembers){
                    if(otm.OpportunityId == updatedOpp.Id)
                        listOfUsersToNotify.add(otm.UserId);
                }   
            }
        }
        if(!listOfUsersToNotify.isEmpty())
            sendEmailToRespectiveUsers(listOfUsersToNotify);
    }
    
    public static void sendEmailToRespectiveUsers(Set<Id> userIds){
        List<String> emailIds = new List<String>();
        List<User> userRecords = [SELECT Email FROM User WHERE Id IN : userIds];
        for(User userRec : userRecords){
            emailIds.add(userRec.Email);
        }
        System.debug(emailIds);
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    message.toAddresses = emailIds;
    message.optOutPolicy = 'FILTER';
    message.subject = 'Take a look at the opportunity';
      message.plainTextBody = 'This is urgent';
    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>{message}; 
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
}