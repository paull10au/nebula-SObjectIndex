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
private class SObjectGetterTest {

    static TestObjectGenerator tog = new TestObjectGenerator();

    @IsTest
    public static void basic() {
        Account togAccount = tog.getAccount();
        Contact togContact = tog.getContact();

        SObject queriedContact = [SELECT Id, LastName, Account.Name, FirstName FROM Contact WHERE Id = :togContact.Id];

        System.assertEquals(togAccount.Name, String.valueOf(SObjectGetter.get(queriedContact, 'Account.Name')));
        System.assertEquals(togContact.LastName, SObjectGetter.get(queriedContact, 'LastName'));
        System.assertEquals(null, SObjectGetter.get(queriedContact, 'FirstName'));
        System.assertEquals(null, String.valueOf(SObjectGetter.get(queriedContact, 'FirstName')));
    }

    @IsTest
    public static void relationIsNullPartWay() {
        Contact togContact = tog.getContact();
        togContact.AccountId = null;
        update togContact;

        SObject queriedContact = [SELECT Id, LastName, Account.Name, FirstName FROM Contact WHERE Id = :togContact.Id];

        System.assertEquals(null, String.valueOf(SObjectGetter.get(queriedContact, 'Account.Name')));
    }
}