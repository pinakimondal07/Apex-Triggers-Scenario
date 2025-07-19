//Whenever a new account is created, create a dummy contact under the account and the dummy contact will have the name 
//"Dummy Contact <account name>"

trigger DummyContact on Account (after insert) {
    List<Contact> listOfConacts = new List<Contact>();
    switch on Trigger.operationType {
        when AFTER_INSERT {
            for(Account acc : Trigger.new){
                //Create new contact for each account
                Contact DummyContact = new Contact();
                DummyContact.FirstName = 'Dummy';
                DummyContact.LastName = acc.Name;
                listOfConacts.add(DummyContact);
            }
            insert listOfConacts;
        }
    
    }
}