//Account that has a related Contact should not be deleted. Error should be thrown.

trigger RelatedContactShuldNotBeDeleted on Account (before delete) {
    List<Account> accountsWithContacts = new List<Account>();
    switch on Trigger.operationType{
        when BEFORE_DELETE{
            for(Account ac: Trigger.old){   
            }
        }
    } 
}