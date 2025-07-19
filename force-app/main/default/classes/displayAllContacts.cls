public with sharing class displayAllContacts {
    @AuraEnabled(cacheable=true)

    public static List<Contact> getAllRecords() {

        List<Contact> contactList = [SELECT Id, AccountId, Name, Phone, Email, Title FROM Contact LIMIT 10];
        return contactList;

    }
}