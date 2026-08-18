@isTest
private class AccountServiceTest {
    @testSetup
    static void setupTestData() {
        Account accountWithWins = new Account(Name = 'Test Account With Wins');
        Account accountWithoutWins = new Account(Name = 'Test Account Without Wins');
        insert new List<Account>{ accountWithWins, accountWithoutWins };

        insert new List<Opportunity>{
            new Opportunity(
                Name = 'Closed Won Opp 1',
                AccountId = accountWithWins.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount = 1000
            ),
            new Opportunity(
                Name = 'Closed Won Opp 2',
                AccountId = accountWithWins.Id,
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                Amount = 2000
            ),
            new Opportunity(
                Name = 'Open Opp',
                AccountId = accountWithWins.Id,
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30),
                Amount = 500
            ),
            new Opportunity(
                Name = 'Closed Lost Opp',
                AccountId = accountWithoutWins.Id,
                StageName = 'Closed Lost',
                CloseDate = Date.today(),
                Amount = 750
            )
        };
    }

    @isTest
    static void testGetTotalClosedWonOpportunityAmounts_returnsSumForAccountWithWins() {
        Map<String, Id> accountIdByName = accountIdsByName();
        Set<Id> accountIds = new Set<Id>{
            accountIdByName.get('Test Account With Wins'),
            accountIdByName.get('Test Account Without Wins')
        };

        Test.startTest();
        Map<Id, Decimal> totals = AccountService.getTotalClosedWonOpportunityAmounts(accountIds);
        Test.stopTest();

        System.assertEquals(
            3000,
            totals.get(accountIdByName.get('Test Account With Wins')),
            'Closed won amounts should be summed for the account with wins'
        );
        System.assertEquals(
            0,
            totals.get(accountIdByName.get('Test Account Without Wins')),
            'Account with no closed won opportunities should total zero'
        );
    }

    @isTest
    static void testGetTotalClosedWonOpportunityAmounts_accountWithNoOpportunities_returnsZero() {
        Account accountWithNoOpportunities = new Account(Name = 'Empty Account');
        insert accountWithNoOpportunities;

        Test.startTest();
        Map<Id, Decimal> totals = AccountService.getTotalClosedWonOpportunityAmounts(
            new Set<Id>{ accountWithNoOpportunities.Id }
        );
        Test.stopTest();

        System.assertEquals(0, totals.get(accountWithNoOpportunities.Id));
    }

    @isTest
    static void testGetTotalClosedWonOpportunityAmounts_emptyAccountIds_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Decimal> totals = AccountService.getTotalClosedWonOpportunityAmounts(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, totals.size());
    }

    @isTest
    static void testGetTotalOpenOpportunityAmounts_returnsSumForAccountWithOpenOpp() {
        Map<String, Id> accountIdByName = accountIdsByName();
        Set<Id> accountIds = new Set<Id>{
            accountIdByName.get('Test Account With Wins'),
            accountIdByName.get('Test Account Without Wins')
        };

        Test.startTest();
        Map<Id, Decimal> totals = AccountService.getTotalOpenOpportunityAmounts(accountIds);
        Test.stopTest();

        System.assertEquals(
            500,
            totals.get(accountIdByName.get('Test Account With Wins')),
            'Open amounts should be summed for the account with an open opportunity'
        );
        System.assertEquals(
            0,
            totals.get(accountIdByName.get('Test Account Without Wins')),
            'Account with only closed opportunities should total zero'
        );
    }

    @isTest
    static void testGetTotalOpenOpportunityAmounts_accountWithNoOpportunities_returnsZero() {
        Account accountWithNoOpportunities = new Account(Name = 'Empty Account For Open Test');
        insert accountWithNoOpportunities;

        Test.startTest();
        Map<Id, Decimal> totals = AccountService.getTotalOpenOpportunityAmounts(
            new Set<Id>{ accountWithNoOpportunities.Id }
        );
        Test.stopTest();

        System.assertEquals(0, totals.get(accountWithNoOpportunities.Id));
    }

    @isTest
    static void testGetTotalOpenOpportunityAmounts_emptyAccountIds_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Decimal> totals = AccountService.getTotalOpenOpportunityAmounts(new Set<Id>());
        Test.stopTest();

        System.assertEquals(0, totals.size());
    }

    private static Map<String, Id> accountIdsByName() {
        Map<String, Id> accountIdByName = new Map<String, Id>();
        for (Account acct : [SELECT Id, Name FROM Account]) {
            accountIdByName.put(acct.Name, acct.Id);
        }
        return accountIdByName;
    }
}