trigger AccountTrigger on Account (before insert, before update, after update, after insert, after undelete) {
    Switch on Trigger.operationType{
        when BEFORE_UPDATE{
            //9. If an Account with Industry Agriculture and Type Prospect is updated and if the user is trying to set the Ownership  
            //   field to Private, do not allow the user to set this ownership
            AccountTriggerHandler.checkOwnershipValidation(Trigger.new, Trigger.oldMap);
        }
        when AFTER_UPDATE{
            //10. Everytime an Account website is updated, update the website field on all child contacts for the Account
            AccountTriggerHandler.updateWebsiteFieldOnChild(Trigger.new, Trigger.oldMap);
            
            //30. When an account is updated and Industry is changed to Biotechnology, find all related contacts and update Lead Source 
            //    to Phone. Use async apex to achieve this.
            AccountTriggerHandler.onUpdateOfIndustryUpdateContactLeadUsingAsyncApex(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT{
            //11. Create Contact records based on Create N Contacts field on the Account record
            AccountTriggerHandler.createRelatedContactsBasedOnCNCfield(Trigger.new);
        }
        when BEFORE_INSERT{
            //26. Set the Account Owner's Name as the Sales Rep field value when an Account is created
            AccountTriggerHandler.setSalesRepAsAccountOwner(Trigger.new);
        }
        when AFTER_UNDELETE{
            //29. As soon as an account record is restored from bin, update its name and prefix it with "Restored" keyword
            AccountTriggerHandler.updateNameAsRestoredOnAccountRestoration(Trigger.new);
        }
    }
}
