public with sharing class AccountService {
    public static Map<Id, Decimal> getTotalClosedWonOpportunityAmounts(Set<Id> accountIds) {
        Map<Id, Decimal> totalsByAccountId = new Map<Id, Decimal>();
        for (Id accountId : accountIds) {
            totalsByAccountId.put(accountId, 0);
        }

        for (AggregateResult result : [
            SELECT AccountId, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE AccountId IN :accountIds AND IsWon = true
            GROUP BY AccountId
        ]) {
            totalsByAccountId.put((Id) result.get('AccountId'), (Decimal) result.get('totalAmount'));
        }

        return totalsByAccountId;
    }

    public static Map<Id, Decimal> getTotalOpenOpportunityAmounts(Set<Id> accountIds) {
        Map<Id, Decimal> totalsByAccountId = new Map<Id, Decimal>();
        for (Id accountId : accountIds) {
            totalsByAccountId.put(accountId, 0);
        }

        for (AggregateResult result : [
            SELECT AccountId, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE AccountId IN :accountIds AND IsClosed = false
            GROUP BY AccountId
        ]) {
            totalsByAccountId.put((Id) result.get('AccountId'), (Decimal) result.get('totalAmount'));
        }

        return totalsByAccountId;
    }
}