/**
 * @author aidan@nebulaconsulting.co.uk
 * @date 09/11/2018
 *
 * MIT License
 *
 * Copyright (c) 2018 Aidan Harding, Nebula Consulting
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

@IsTest
private class SObjectIndexTest {

    private static TestObjectGenerator tog = new TestObjectGenerator();
    private final static String DOE = 'Doe';
    private final static String ACCOUNT_ID = Contact.AccountId.getDescribe().getName();
    private final static String LAST_NAME = Contact.LastName.getDescribe().getName();
    private static Account togAccount = tog.getAccount();

    @IsTest
    static void emptyIndex() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ ACCOUNT_ID, LAST_NAME });

        System.assertEquals(null, theIndex.get(new Contact()));
        System.assert(theIndex.isEmpty());
    }

    @IsTest
    static void setCaseInsensitiveWithData() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ ACCOUNT_ID, LAST_NAME }).put(new Contact());

        try {
            theIndex.setIsCaseInsensitive(true);
        } catch (IllegalStateException e) {
            System.assertEquals(Label.SObjectIndex_Case_Insensitive_Error, e.getMessage());
            return;
        }
        System.assert(false, 'Should have thrown IllegalStateException');
    }

    @IsTest
    static void nullValueOnIndexField() {
        SObjectIndex theIndex = new SObjectIndex(Account.ParentId.getDescribe().getName()).put(togAccount);
        Account indexAccount = (Account)theIndex.get((Id)null);

        System.assertEquals(togAccount.Id, indexAccount.Id);
    }

    @IsTest
    static void singleHit() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ ACCOUNT_ID, LAST_NAME });

        Contact togContact = new Contact(AccountId = togAccount.Id, LastName = DOE);
        theIndex.put(togContact);

        System.assertEquals(1, theIndex.getAll(new Contact(AccountId = togAccount.Id, LastName = DOE)).size());
        System.assert(!theIndex.isEmpty());

        Set<String> accountIdKeySet = theIndex.keySet(ACCOUNT_ID);
        System.assertEquals(1, accountIdKeySet.size());
        System.assert(accountIdKeySet.contains(togAccount.Id));

        Set<String> lastNameKeySet = theIndex.keySet(LAST_NAME);
        System.assertEquals(1, lastNameKeySet.size());
        System.assert(lastNameKeySet.contains(DOE));

        List<Contact> values = (List<Contact>)theIndex.values();
        System.assertEquals(1, values.size());
        System.assertEquals(togContact, values[0]);
    }

    @IsTest
    static void caseInsensitive() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME})
                .setIsCaseInsensitive(true);

        Contact togContact = new Contact(AccountId = togAccount.Id, LastName = DOE);
        theIndex.put(togContact);

        System.assertEquals(1, theIndex.getAll(new Contact(AccountId = togAccount.Id, LastName = DOE.toLowerCase())).size());
        System.assert(!theIndex.isEmpty());
    }

    @IsTest
    static void caseInsensitiveMap() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME})
                .setIsCaseInsensitive(true);

        Contact togContact = new Contact(AccountId = togAccount.Id, LastName = DOE);
        theIndex.put(togContact);

        System.assertEquals(1, theIndex.getAll(new Map<String, String> {
                ACCOUNT_ID  => togAccount.Id,
                LAST_NAME => DOE.toLowerCase()}).size());
        System.assert(!theIndex.isEmpty());
    }

    @IsTest
    static void caseInsensitiveReverse() {
        SObjectIndex theIndex = new SObjectIndex(LAST_NAME)
                .setIsCaseInsensitive(true);

        Contact togContact = new Contact(AccountId = togAccount.Id, LastName = DOE.toLowerCase());
        theIndex.put(togContact);

        System.assertEquals(1, theIndex.getAll(DOE).size());
        System.assert(!theIndex.isEmpty());
    }

    private static SObjectIndex getTwoHitsIndex() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME});

        theIndex.putAll(new List<Contact> { new Contact(AccountId = togAccount.Id, FirstName = 'John', LastName = DOE),
                new Contact(AccountId = togAccount.Id, FirstName = 'Jane', LastName = DOE),
                new Contact(AccountId = togAccount.Id, FirstName = 'Fred', LastName = 'Deer')
        });
        return theIndex;
    }

    @IsTest
    static void twoHits() {
        SObjectIndex theIndex = getTwoHitsIndex();

        System.assertEquals(2, theIndex.getAll(new Contact(AccountId = togAccount.Id, LastName = DOE)).size());
        System.assert(!theIndex.isEmpty());
        Set<String> accountKeySet = theIndex.keySet(ACCOUNT_ID);
        System.assertEquals(1, accountKeySet.size());
        System.assert(accountKeySet.contains(togAccount.Id));
        Set<String> nameKeySet = theIndex.keySet('LastName');
        System.assertEquals(2, nameKeySet.size());
        System.assert(nameKeySet.contains(DOE));
        System.assert(nameKeySet.contains('Deer'));
    }

    @IsTest
    static void nearHit() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME});

        theIndex.put(new Contact(AccountId = togAccount.Id, FirstName = 'John', LastName = DOE));
        theIndex.put(new Contact(AccountId = togAccount.Id, FirstName = 'Jane', LastName = DOE + 2));

        System.assertEquals(1, theIndex.getAll(new Contact(AccountId = togAccount.Id, LastName = DOE)).size());
    }

    @IsTest
    static void simpleIndex() {
        List<Contact> data = new List<Contact> {
                new Contact(AccountId = togAccount.Id, FirstName = 'John', LastName = DOE),
                new Contact(AccountId = togAccount.Id, FirstName = 'Jane', LastName = DOE + 2)
        };

        SObjectIndex theIndex = new SObjectIndex(ACCOUNT_ID).putAll(data);

        System.assertEquals(2, theIndex.getAll(togAccount.Id).size());

        Set<String> ks2 = theIndex.keySet();
        System.assertEquals(1, ks2.size());
        System.assert(ks2.contains(togAccount.Id));

        theIndex.get(togAccount.Id);
        System.assertEquals(null, theIndex.get('null'));
        System.assert(theIndex.getAll('null').isEmpty());
    }

    @IsTest
    static void crossObjectField() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{'Account.Name', LAST_NAME});

        Contact togContact = new Contact(AccountId = togAccount.Id,  LastName = DOE);
        insert togContact;
        togContact = [SELECT Id, Account.Name, LastName FROM Contact WHERE Id = :togContact.Id];
        theIndex.put(togContact);

        System.assertEquals(1, theIndex.getAll(new Contact(Account = new Account(Name = togAccount.Name), LastName = DOE)).size());
        System.assert(!theIndex.isEmpty());

        List<Contact> values = (List<Contact>)theIndex.values();
        System.assertEquals(1, values.size());
        System.assertEquals(togContact, values[0]);
    }

    @IsTest
    static void exactHitMap() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME});

        theIndex.put(new Contact(AccountId = togAccount.Id, LastName = DOE));

        System.assertEquals(1, theIndex.getAll(new Map<String, Object>{ACCOUNT_ID => togAccount.Id, LAST_NAME => DOE}).size());
        System.assert(!theIndex.isEmpty());
    }

    @IsTest
    static void twoHitsMap() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME}).putAll(
                new List<Contact> { new Contact(AccountId = null, FirstName = 'John', LastName = 'Doe'),
                        new Contact(AccountId = togAccount.Id, FirstName = 'Jane', LastName = 'Doe'),
                        new Contact(AccountId = togAccount.Id, FirstName = 'Fred', LastName = 'Deer')
                });

        List<Contact> fetchedContacts = theIndex.getAll(new Map<String, Object>{LAST_NAME => DOE});
        System.assertEquals(2, fetchedContacts.size());
        System.assert(fetchedContacts[0].AccountId == null);
        System.assert(fetchedContacts[1].AccountId == togAccount.Id);
        System.assert(fetchedContacts[0].FirstName == 'John');
        System.assert(fetchedContacts[1].FirstName == 'Jane');
        System.assertEquals(DOE, fetchedContacts[0].LastName);
        System.assertEquals(DOE, fetchedContacts[1].LastName);
    }

    @IsTest
    static void twoHitsSubIndex() {
        SObjectIndex theIndex =  new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME}).putAll(
                new List<Contact> { new Contact(AccountId = null, FirstName = 'John', LastName = 'Doe'),
                        new Contact(AccountId = togAccount.Id, FirstName = 'Jane', LastName = 'Doe'),
                        new Contact(AccountId = togAccount.Id, FirstName = 'Fred', LastName = 'Deer')
                });

        SObjectIndex subIndex = theIndex.getSubIndex(togAccount.Id);
        List<Contact> fetchedContacts = subIndex.getAll(new Map<String, Object>{LAST_NAME => DOE});
        System.assertEquals(1, fetchedContacts.size());
        System.assert(fetchedContacts[0].AccountId == togAccount.Id);
        System.assert(fetchedContacts[0].FirstName == 'Jane');
        System.assertEquals(DOE, fetchedContacts[0].LastName);
    }

    @IsTest
    static void remove() {
        SObjectIndex theIndex = getTwoHitsIndex();

        theIndex.remove(new Contact(AccountId = togAccount.Id, FirstName = 'John', LastName = DOE));
        System.assertEquals(0, theIndex.getAll(new Contact(AccountId = togAccount.Id, LastName = DOE)).size());
        Set<String> keySetName = theIndex.keySet(LAST_NAME);
        System.assertEquals(2, keySetName.size());
        System.assert(keySetName.contains('Deer'));
        System.assert(keySetName.contains(DOE));

        System.assert(theIndex.remove(new Contact()).isEmpty());
    }

    @IsTest
    static void removeMap() {
        SObjectIndex theIndex = new SObjectIndex(new List<String>{ACCOUNT_ID, LAST_NAME, Contact.FirstName.getDescribe().getName()});

        theIndex.putAll(new List<Contact> { new Contact(AccountId = togAccount.Id, FirstName = 'John', LastName = DOE),
                new Contact(AccountId = togAccount.Id, FirstName = 'Jane', LastName = DOE),
                new Contact(AccountId = togAccount.Id, FirstName = 'Fred', LastName = 'Deer')
        });
        theIndex.remove(new Map<String, Object> { 'FirstName' => 'John'});
        System.assertEquals(1, theIndex.getAll(new Map<String, Object>{ACCOUNT_ID => togAccount.Id, LAST_NAME => DOE}).size());
        Set<String> keySetName = theIndex.keySet(LAST_NAME);
        System.assertEquals(2, keySetName.size());
        System.assert(keySetName.contains(DOE));
        System.assert(keySetName.contains('Deer'));
    }
}