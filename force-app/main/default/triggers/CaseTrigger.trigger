
trigger CaseTrigger on Case (before insert, before update) {
    Switch on Trigger.operationType{
        when BEFORE_INSERT{
            //3. Whenever a Case is created and and Case Origin is Phone, Set the Priority as High, else set Priority as Low
            for(Case caseToCheck : Trigger.new){
                if(caseToCheck.Origin == 'Phone'){
                        caseToCheck.Priority = 'High';
                }
                else{
                    caseToCheck.Priority = 'Low';
                }
            }
            //--------------------------------------------------------------------------------------------------------------
        }
        when BEFORE_UPDATE{
            //16. Allow Case Deletion only by System Admin users
            CaseTriggerHandler.allowCaseDeletionByAdminOnly(Trigger.old);
        }
    }
}