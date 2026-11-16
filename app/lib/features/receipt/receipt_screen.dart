import 'dart:ui' as ui;

import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../services/receipt_pdf.dart';
import '../../services/whatsapp.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'receipt_card.dart';
import 'receipt_data.dart';

/// معاينة الإشعار/السند بعد التسجيل، مع المشاركة عبر نافذة الجوال (واتساب، رسائل، بريد…)
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, required this.customerId, required this.txId});
  final String customerId;
  final String txId;
  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  final _captureKey = GlobalKey();
  bool _busy = false;

  ReceiptData? _data() {
    final s = ref.read(sessionProvider).session!;
    final c = ref.read(customerProvider(widget.customerId)).valueOrNull;
    final txs = ref.read(customerTxsProvider(widget.customerId)).valueOrNull;
    if (c == null || txs == null) return null;
    final tx = txs.where((t) => t.id == widget.txId).firstOrNull;
    if (tx == null) return null;
    final orig = tx.voidedId == null ? null : txs.where((t) => t.id == tx.voidedId).firstOrNull;
    return ReceiptData.build(
      session: s,
      customer: c,
      tx: tx,
      balances: Ledger.balances(txs),
      f: ref.read(moneyFormatProvider),
      originalRef: orig?.invoiceNo,
    );
  }

  String _fileName(ReceiptData d) => '${d.title}-${d.reference}'.replaceAll(RegExp(r'[\\/:*?"<>| ]'), '-');

  /// زر المشاركة: PDF عبر نافذة المشاركة في الجوال
  Future<void> _sharePdf(ReceiptData d, Rect? origin) => _run(() async {
        final bytes = await ReceiptPdf.build(d);
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'application/pdf', name: '${_fileName(d)}.pdf')],
          subject: '${d.title} — ${d.storeName}',
          sharePositionOrigin: origin,
        );
      });

  /// مشاركة كصورة: أوضح في واتساب ويفتحها أي جوال بدون برنامج PDF
  Future<void> _shareImage(ReceiptData d, Rect? origin) => _run(() async {
        final boundary = _captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 3);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Share.shareXFiles(
          [XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png', name: '${_fileName(d)}.png')],
          text: d.asText(),
          sharePositionOrigin: origin,
        );
      });

  Future<void> _print(ReceiptData d, {bool thermal = false}) => _run(() async {
        final bytes = await ReceiptPdf.build(d, thermal: thermal);
        await Printing.layoutPdf(onLayout: (_) async => bytes, name: _fileName(d));
      });

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Rect? _origin(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  @override
  Widget build(BuildContext context) {
    // نعيد البناء عند وصول البيانات أو تغيّر حالة المزامنة
    ref.watch(customerProvider(widget.customerId));
    ref.watch(customerTxsProvider(widget.customerId));
    final d = _data();
    final customerPhone = d?.customerPhone;

    return Scaffold(
      appBar: AjilHeader(
        close: true,
        title: d?.title ?? 'الإشعار',
        subtitle: d?.pending == true ? 'بانتظار المزامنة' : null,
        actions: [
          if (d != null)
            Builder(
              builder: (ctx) => SquareIconButton(
                icon: Icons.share_rounded,
                tooltip: 'مشاركة',
                color: AjilColors.primary,
                onPressed: _busy ? null : () => _sharePdf(d, _origin(ctx)),
              ),
            ),
        ],
      ),
      body: d == null
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Column(children: [
                    if (d.pending)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                          Icon(Icons.schedule_rounded, size: 16, color: AjilColors.pendingText),
                          SizedBox(width: 6),
                          Text('بانتظار المزامنة — يمكنك المشاركة الآن', style: TextStyle(color: AjilColors.pendingText, fontSize: 13)),
                        ]),
                      ),
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AjilColors.border),
                      ),
                      child: RepaintBoundary(key: _captureKey, child: ReceiptCard(d)),
                    ),
                  ]),
                ),
              ),
              Container(
                decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AjilColors.headerBorder))),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: SafeArea(
                  top: false,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Expanded(
                        child: Builder(
                          builder: (ctx) => FilledButton.icon(
                            onPressed: _busy ? null : () => _sharePdf(d, _origin(ctx)),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('مشاركة PDF'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Builder(
                          builder: (ctx) => OutlinedButton.icon(
                            onPressed: _busy ? null : () => _shareImage(d, _origin(ctx)),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('مشاركة صورة'),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      if (customerPhone != null)
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () => Whatsapp.send(customerPhone, d.asText()),
                            icon: const Icon(Icons.chat_outlined, color: AjilColors.paid),
                            label: const Text('واتساب للزبون مباشرة'),
                          ),
                        ),
                      Expanded(
                        child: PopupMenuButton<bool>(
                          onSelected: (thermal) => _print(d, thermal: thermal),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: false, child: Text('طباعة A5')),
                            PopupMenuItem(value: true, child: Text('طابعة حرارية 58mm')),
                          ],
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.print_outlined, color: AjilColors.textSoft),
                              SizedBox(width: 6),
                              Text('طباعة'),
                            ]),
                          ),
                        ),
                      ),
                    ]),
                    TextButton(onPressed: () => context.pop(), child: const Text('تم')),
                  ]),
                ),
              ),
            ]),
    );
  }
}
