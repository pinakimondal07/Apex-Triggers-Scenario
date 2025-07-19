public class CaseTriggerHandler {
    public static void allowCaseDeletionByAdminOnly(List<Case> caseToDelete){
        //userInfo class is useful to get the Current user's details
        Id currentUserProfileId = UserInfo.getProfileId();  //To get current logged-in user's profile Id
        //Ideally there should be only one System Admin Profile, hence querying the its Id
        Id systemAdminProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        //Above method of query will work if the SOQL returns only single row
        for(Case checkCase : caseToDelete){
            if(currentUserProfileId != systemAdminProfileId)
                System.debug('In If');
                checkCase.addError('The Case can only be deleted by System Admin');
        }
    }
}