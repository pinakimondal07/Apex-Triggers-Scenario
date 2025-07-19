public class TaskTriggerHandler {
    public static void increamentTaskAssociatedOnNewTaskCreation(List<Task> newRecords){
        //Todo: Need to update the logic to make it working for multiple tasks created on same Contact
        List<Contact> updatedContact = new List<Contact>();
        Map<Id, Integer> conCountMap = new Map<Id, Integer>();
        List<Contact> allContacts = new List<Contact>([SELECT Id, Name, Number_Of_Task_Associated__c FROM Contact]);
        for(Task tsk : newRecords){
            for(Contact assignedContact : allContacts){
                if(conCountMap.containsKey(tsk.WhoId)){
                    Integer countVar = conCountMap.get(tsk.WhoId) + 1;
                    conCountMap.put(tsk.WhoId, countVar);
                }
                else{
                    conCountMap.put(tsk.WhoId, 1);
                }
                if(tsk.WhoId == assignedContact.Id){
                    if(assignedContact.Number_Of_Task_Associated__c != null){
                        assignedContact.Number_Of_Task_Associated__c = assignedContact.Number_Of_Task_Associated__c + conCountMap.get(assignedContact.Id);
                    }
                    else{
                        assignedContact.Number_Of_Task_Associated__c = conCountMap.get(assignedContact.Id);
                    }
                    updatedContact.add(assignedContact);
                }
            }
            if(!updatedContact.isEmpty())
                update updatedContact;
        }
    }
    
    public static void allowUpdateIfModifYTaskPermissionIsChecked(List<Task> newRecords){
        List<Id> contactIdList = new List<Id>();
        for(Task newTask : newRecords){
            if(String.valueOf(newTask.WhoId).startsWith('003'))  //This is done to distinguish between Lead and Contact. Contact records start with 003
              contactIdList.add(newTask.WhoId);
        }
        Map<Id, Contact> relatedContactIds = new Map<Id, Contact>([SELECT AccountId  FROM Contact WHERE Id IN : contactIdList]);
        Map<Id, Account> parentAccount =new Map<Id, Account>([SELECT Id, Modify_Task_Permission__c FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Id IN : contactIdList)]);
        for(Task childTask : newRecords){
            if(parentAccount.get(relatedcontactIds.get(childTask.WhoId).AccountId).Modify_Task_Permission__c == false)
                childTask.addError('Task cannnot be updated as you do not have the modify permission from the Parent Account');
        }
    }
}