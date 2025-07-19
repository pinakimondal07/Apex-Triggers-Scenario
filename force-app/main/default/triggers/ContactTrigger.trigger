trigger ContactTrigger on Contact (before insert, after insert, after update) {
    Switch on Trigger.operationType{
        when BEFORE_INSERT{
            //8. If a contact is created without a parent Account, do not allow user to create the Contact record
            ContactTriggerHandler.contactCreatedWithoutParentAccount(Trigger.new);
            
            //14. Check if a Contact record exists with the same last name, email & phone. If so, do not let new contact creation
            ContactTriggerHandler.checkNameEmailBeforeCreation(Trigger.new);
            
            //21. Whenever a Contact record is created, fetch the BillingAddress from Parent Account and save it in the MailingAddress 
            //    field of the Contact record.
            ContactTriggerHandler.fetchBillingAddFromAccAndSaveInContact(Trigger.new);
            
            //23. Check the Max Contacts Allowed field on the Account record and if the number of child contacts go beyond this number, 
            //    do not allow Contact insertion & association to this Account
            ContactTriggerHandler.throwErrorIfMaxContactAllowedExceds(Trigger.new);
        }
        when AFTER_INSERT{
            //17. As soon as a Contact is created, share the Contact record with all users who are part of the Contact Innovators Public Group
            ContactTriggerHandler.shareContactWithContactInnovatorsGroup(Trigger.new);
            
            //24.
            ContactTriggerHandler.addOrRemoveLocationsOnUpdateInChildLocation(Trigger.new, null);
            //In insert scenario we dont have trigger.old so we are passing null
        }
        when AFTER_UPDATE{
            //20. When the email or phone of a Contact with an active Parent Account is modified, send an email to the Account Owner 
            //    notifying the same
            ContactTriggerHandler.sentEmailToParentAccountOnEmailOrPhoneUpdate(Trigger.new, Trigger.oldMap);
            
            //24. Whenever the Create N Locations filed of Location is updated, accordingly add/remove the loctaions record under a contact record
            ContactTriggerHandler.addOrRemoveLocationsOnUpdateInChildLocation(Trigger.new, Trigger.oldMap);
        }
    }
}
