public class ContactTriggerHandler {
    public static void contactCreatedWithoutParentAccount(List<Contact> newRecords){
        for(Contact con : newRecords){
            if(con.AccountId == null){  
                //Check if the AccountId is null or not
                con.addError('Contact cannot be saved as there is no related Account');
            }
        }
    }
    
    public static void checkNameEmailBeforeCreation(List<Contact> newCons){
        List<Contact> listOfContacts = new List<Contact>([Select Id, LastName, Email, Phone from Contact Limit 500000]);
        for(Contact con : newCons){
            for(Contact checkList : listOfContacts){
                if(con.LastName == checkList.LastName && con.Email == checkList.Email && con.Phone == checkList.Phone)
                    con.addError('Contact cannot be created as there already exists contact with same Name, Email and Phone');
            }
        }
    }
    
    public static void shareContactWithContactInnovatorsGroup(List<Contact> newRecords){
        List<ContactShare> listOfContactToShare = new List<ContactShare>();
        Id contactInovatorGrpId = [SELECT Id, Name FROM Group WHERE Name = 'Contact Innovators' LIMIT 1].Id;
        for(Contact newContact : newRecords){
            ContactShare conToShare = new ContactShare();
            //This contact sharing comes into play only when we want to give more access than the Object/Record than it already has
            //By default Contact has 
            conToShare.ContactAccessLevel = 'Edit';
            conToShare.ContactId = newContact.Id;
            conToShare.RowCause = 'Manual';
            conToShare.UserOrGroupId = contactInovatorGrpId;
            listOfContactToShare.add(conToShare);
        }
        if(!listOfContactToShare.isEmpty()){
            insert listOfContactToShare;
        }
            
    }
    
    public static void sentEmailToParentAccountOnEmailOrPhoneUpdate(List<Contact> newRecords, Map<Id, Contact> oldContactMap){
        List<Id> accountIdsToInform = new List<Id>();
        for(Contact con : newRecords){
            accountIdsToInform.add(con.AccountId);
        }
        system.debug(accountIdsToInform);
        //Fetch Prent Account's Email Id
        List<Account> receiversId = new List<Account>([SELECT Id, OwnerId, Owner.Email from Account WHERE Id IN : accountIdsToInform]);
        //Due to Field-Level Security (FLS) Restriction on Owner.Email we need to fetch the Email Id in other way
        System.debug(receiversId);
        List<String> emailAddressList = new List<String>();
        for (Account acc : receiversId) {
                emailAddressList.add(acc.Owner.Email);
        }
        
        system.debug(emailAddressList);
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        for(Contact updatedCons : newRecords){
            if(updatedCons.AccountId != null){  //Check if Contact has any active Account or not
              if(updatedCons.Email != oldContactMap.get(updatedCons.Id).Email || updatedCons.Phone != oldContactMap.get(updatedCons.Id).Phone){
                  Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.toAddresses = emailAddressList;
                    mail.Subject = 'Contact Email or Phone is Changed';
                    mail.plainTextBody = 'This is to inform that the Email or Phone of your Child Contact has been modified. Please check!';
                    messages.add(mail);
                    //Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.Email[] { mail });
                }
            }
        }
        System.debug(messages);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    }
    
    public static void fetchBillingAddFromAccAndSaveInContact(List<Contact> newrecords){
        List<Id> parentAccountIds = new List<Id>();
        for(Contact con : newRecords){
            parentAccountIds.add(con.AccountId);
        }
        Map<Id, Account> parentAccountInfo = new Map<Id, Account>([SELECT Id, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode FROM Account WHERE Id IN : parentAccountIds]);
        System.debug(parentAccountInfo);
        for(Contact newContact : newRecords){
            //newContact.MailingAddress = parentAccountInfo.get(newContact.AccountId);  //Field is not writeable: Contact.MailingAddress
            newContact.MailingStreet = parentAccountInfo.get(newContact.AccountId).BillingStreet;
            newContact.MailingCity = parentAccountInfo.get(newContact.AccountId).BillingCity;
            newContact.MailingState = parentAccountInfo.get(newContact.AccountId).BillingState;
            newContact.MailingCountry = parentAccountInfo.get(newContact.AccountId).BillingCountry;
            newContact.MailingPostalCode = parentAccountInfo.get(newContact.AccountId).BillingPostalCode;
        }
    }
    
    public static void throwErrorIfMaxContactAllowedExceds(List<Contact> newRecords){
        List<Id> parentAccountIds = new List<Id>();
        for(Contact con : newRecords){
            parentAccountIds.add(con.AccountId);
        }
        Map<Id, Account> parentAccountInfo = new Map<Id, Account>([SELECT Id, Max_Contacts_Allowed__c, (SELECT Id FROM Contacts) FROM Account WHERE Id IN : parentAccountIds]);
        for(Contact newContact : newRecords){
            if((parentAccountInfo.get(newContact.AccountId).Contacts).size() >= parentAccountInfo.get(newContact.AccountId).Max_Contacts_Allowed__c)
                newContact.addError('Contact cannot be inserted. You have exceded the Max Contact Allowed per Account');
        }
    }
    
    public static void addOrRemoveLocationsOnUpdateInChildLocation(List<Contact> newRecords, Map<Id, Contact> oldConMap){
        List<Location__c> locationsToCreate = new List<Location__c>();
        List<Location__c> deleteLocationList = new List<Location__c>();
        Map<Id, Location__c> existingLocationRecords;
        if(oldConMap != null)
          existingLocationRecords = new Map<Id, Location__c>([Select Id, ContactId__c FROM Location__c WHERE ContactId__c IN : oldConMap.keySet()]);
        for(Contact newContact : newRecords){
            if(Trigger.isInsert){
                for(Integer i=0; i<newContact.Create_N_Locations__c ; i++){
                    Location__c loc = new Location__c();
                    loc.Name = 'Location_' + i;
                    loc.ContactId__c = newContact.Id;
                     locationsToCreate.add(loc);
                }
            }
            else if(Trigger.isUpdate){
                if(oldConMap.get(newContact.Id).Create_N_Locations__c != newContact.Create_N_Locations__c){
                    if(oldConMap.get(newContact.Id).Create_N_Locations__c < newContact.Create_N_Locations__c){
                        Integer newRecordsToCreate = (Integer)(newContact.Create_N_Locations__c - oldConMap.get(newContact.Id).Create_N_Locations__c);
                        for(Integer i=0; i<newRecordsToCreate ; i++){
                            Location__c loc = new Location__c();
                            loc.Name = 'Location_' + i;
                            loc.ContactId__c = newContact.Id;
                            locationsToCreate.add(loc);
                        }
                    }
                    else if(oldConMap.get(newContact.Id).Create_N_Locations__c > newContact.Create_N_Locations__c){
                        Integer recordsToDelete = (Integer)(oldConMap.get(newContact.Id).Create_N_Locations__c - newContact.Create_N_Locations__c);
                        for(Location__c locRec : existingLocationRecords.values()){
                            system.debug(existingLocationRecords.values());
                            system.debug('Id' + locRec.ContactId__c);
                            if(locRec.ContactId__c == newContact.Id){
                                if(deleteLocationList.size() < recordsToDelete)
                                    deleteLocationList.add(locRec);
                            }
                        }
                    }
                }
            }
        }
        if(!locationsToCreate.isEmpty())
            insert locationsToCreate;
        
        if(!deleteLocationList.isEmpty())
            delete deleteLocationList;
    }
}