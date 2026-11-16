import 'package:decimal/decimal.dart';
import 'ledger.dart';
import 'models.dart';
import 'tx_kind.dart';

/// سطر في كشف الحساب التحليلي
class StatementLine {
  final LedgerTx tx;
  final Decimal signed;
  final Decimal runningBalance;
  final bool isVoided; // أُلغيت لاحقاً
  const StatementLine(this.tx, this.signed, this.runningBalance, this.isVoided);
}

class CurrencyStatement {
  final String currency;
  final Decimal openingBalance; // الرصيد قبل بداية الفترة
  final Decimal debit;
  final Decimal credit;
  final List<StatementLine> lines; // الأحدث أولاً
  const CurrencyStatement(this.currency, this.openingBalance, this.debit, this.credit, this.lines);
  Decimal get closingBalance => openingBalance + debit - credit;
}

/// كشف حساب زبون: إجمالي لكل عملة + تحليلي بالحركات ورصيد تراكمي لكل عملة
class Statement {
  final Customer customer;
  final Map<String, CurrencyStatement> byCurrency;
  final DateTime? from;
  final DateTime? to;
  const Statement(this.customer, this.byCurrency, this.from, this.to);

  static Statement build(Customer customer, Iterable<LedgerTx> all,
      {DateTime? from, DateTime? to, String? onlyCurrency}) {
    final txs = all.where((t) => t.sync != SyncState.failed).toList()
      ..sort((a, b) {
        final c = a.createdAt.compareTo(b.createdAt);
        return c != 0 ? c : (a.serverSeq ?? 0x1FFFFFFFFFFFFF).compareTo(b.serverSeq ?? 0x1FFFFFFFFFFFFF);
      });
    final byId = {for (final t in txs) t.id: t};
    final voided = Ledger.voidedIds(txs);

    final opening = <String, Decimal>{};
    final debit = <String, Decimal>{};
    final credit = <String, Decimal>{};
    final running = <String, Decimal>{};
    final lines = <String, List<StatementLine>>{};

    for (final t in txs) {
      final cur = t.kind == TxKind.voided ? (byId[t.voidedId]?.currency ?? t.currency) : t.currency;
      if (onlyCurrency != null && cur != onlyCurrency) continue;
      final s = Ledger.signedAmount(t, byId);
      final r = (running[cur] ?? Decimal.zero) + s;
      running[cur] = r;
      final before = from != null && t.createdAt.isBefore(from);
      final after = to != null && t.createdAt.isAfter(to);
      if (before) {
        opening[cur] = (opening[cur] ?? Decimal.zero) + s;
        continue;
      }
      if (after) continue;
      if (s > Decimal.zero) debit[cur] = (debit[cur] ?? Decimal.zero) + s;
      if (s < Decimal.zero) credit[cur] = (credit[cur] ?? Decimal.zero) - s;
      (lines[cur] ??= []).add(StatementLine(t, s, r, voided.contains(t.id)));
    }

    final currencies = {...opening.keys, ...lines.keys};
    return Statement(
      customer,
      {
        for (final c in currencies)
          c: CurrencyStatement(c, opening[c] ?? Decimal.zero, debit[c] ?? Decimal.zero, credit[c] ?? Decimal.zero,
              (lines[c] ?? []).reversed.toList()),
      },
      from,
      to,
    );
  }
}
