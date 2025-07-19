public class AccountTriggerHandler {
    public static void checkOwnershipValidation(List<Account> newRecord, Map<Id,Account> oldAccMap){
        for(Account acc : newRecord){
            if(acc.Industry == 'Agriculture' && acc.Type == 'Prospect'){
                //Check if the Ownership field is changed or not if yes check if it is being set to 'Private'?
                if(oldAccMap.get(acc.Id).Ownership != acc.Ownership && acc.Ownership == 'Private'){
                  acc.addError('Account cannot be saved as Ownership is set as Private');
                }
            }
        }        
    }
    
    public static void updateWebsiteFieldOnChild(List<Account> newRecord, Map<Id,Account> oldAccMap){
        Map<Id, String> addAccToUpdateChild = new Map<Id, String>();  //Map variable to hold the key(id) and value(website) of the parent account
        //Since Website is of type string, so we are choosing String
        for(Account acc: newRecord){
            if(acc.Website != oldAccMap.get(acc.Id).Website){
                System.debug('Oldmap'+ oldAccMap.get(acc.Id));
                addAccToUpdateChild.put(acc.Id, acc.Website);  //To add value in Map .put is used instead of .add
                //Example: {001G100000T4e6iIAB=www.expressl&t.com}
            }
        }
        if(!addAccToUpdateChild.keySet().isEmpty()){
            //keySet() refers to a method that returns a Set view of all the keys contained within that HashMap
            List<Contact> childContactToUpdate = new List<Contact>();
            List<Contact> childContactRecods = [SELECT Id, FirstName, Website__c, AccountId FROM Contact WHERE AccountId IN: addAccToUpdateChild.keySet()];
            //It is necessary to query all the fields that will be used further --> Website__c and AccountId
            for(Contact con : childContactRecods){
                con.Website__c = addAccToUpdateChild.get(con.AccountId);
                childContactToUpdate.add(con);
            }
            if(!childContactToUpdate.isEmpty())
                update childContactToUpdate;
        }
    }
    
    public static void createRelatedContactsBasedOnCNCfield(List<Account> newRecords){
        List<Contact> relatedCons = new List<Contact>();
        for(Account acc: newRecords){
            if(acc.Create_N_Contacts__c != null){
                System.debug('In 1');
                for(integer i=0; i<acc.Create_N_Contacts__c; i++){
                    Contact con = new Contact();  //Since 1 contact at a time will be added so using a Contact variable
                    System.debug('Id' + acc.Id);
                    con.LastName = acc.Name + '_' + i;
                    con.AccountId = acc.Id;  //To make this contact related to the Parent Account
                    relatedCons.add(con);
                }
            }
        }
        if(!relatedCons.isEmpty())
            insert relatedCons;
    }
    
    public static void setSalesRepAsAccountOwner(List<Account> newRecords){
        List<Id> newAccountIds = new List<Id>();
        for(Account acc : newRecords){
            newAccountIds.add(acc.OwnerId);
        }
    Map<Id, User> ownerDetails = new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN : newAccountIds]);
        for(Account newAcc : newRecords){
            newAcc.Sales_Representative__c = ownerDetails.get(newAcc.OwnerId).Name;
        }
    }
    
    public static void updateNameAsRestoredOnAccountRestoration(List<Account> newRecords){
        List<Account> accToBeRestored = new List<Account>();
        List<Id> restoredAccIds = new List<Id>();
        for(Account restoredAcc : newRecords){
            //restoredAcc.Name = 'Restored_' + restoredAcc.Name; //This will throw an error as in After context same record is in read-only mode
            restoredAccIds.add(restoredAcc.Id);
        }
        //Fetch all the accounts that are being restored
        List<Account> restoredAccontsToUpdate = [SELECT Id, Name FROM Account WHERE Id IN : restoredAccIds];
        for(Account restoredAcc : restoredAccontsToUpdate){
            restoredAcc.Name = 'Restored - ' + restoredAcc.Name;
            accToBeRestored.add(restoredAcc);
        }
        if(!accToBeRestored.isEmpty())
            update accToBeRestored;
    }
    
    public static void onUpdateOfIndustryUpdateContactLeadUsingAsyncApex(List<Account> newRecords, Map<Id, Account> oldAccMap){
        List<Id> listOfUpdatedAccIds = new List<Id>();
        for(Account updatedAcc : newRecords){
            if(oldAccMap.get(updatedAcc.Id).Industry != updatedAcc.Industry && updatedAcc.Industry == 'Biotechnology'){
                listOfUpdatedAccIds.add(updatedAcc.Id);
                System.debug(listOfUpdatedAccIds);
            }
        }
        if(!listOfUpdatedAccIds.isEmpty())
            AsyncApexMethod(listOfUpdatedAccIds);
    }
    
    //@future method - Takes only list of Id and Premitive datatype as parameter. 
    //  This is part of Asynchronous Apex, means in the current transaction it will execute everything except this method. 
    //  It will be exceute later when the resources are available.
    //  We are basically delaying our transaction to future time to avoid hitting governor limit.
    //  So any thing that can be delt later on can be moved to @future method.
    
    @future
    public static void AsyncApexMethod(List<Id> accountIds){
        List<Contact> updatedContacts = new List<Contact>();
        List<Contact> relatedContacts = [SELECT Id, LeadSource FROM Contact WHERE AccountId IN : accountIds];
        for(Contact con : relatedContacts){
            con.LeadSource = 'Phone';
            updatedContacts.add(con);
        }
        if(!updatedContacts.isEmpty())
            update updatedContacts;
    }
}