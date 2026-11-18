import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme.dart';
import '../../services/statement_links.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// رابط كشف الحساب العام للزبون: نسخ، مشاركة، تجديد (يُبطل القديم).
/// الإنشاء والتجديد يحتاجان اتصالاً؛ الرابط المحفوظ يُنسخ ويُشارك بدون نت.
Future<void> showStatementLinkSheet(BuildContext context, Customer customer) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => StatementLinkSheet(customer: customer),
    );

class StatementLinkSheet extends ConsumerStatefulWidget {
  const StatementLinkSheet({super.key, required this.customer});
  final Customer customer;
  @override
  ConsumerState<StatementLinkSheet> createState() => _StatementLinkSheetState();
}

class _StatementLinkSheetState extends ConsumerState<StatementLinkSheet> {
  String? _token;
  bool _loading = true;
  AjilError? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool regenerate = false}) async {
    final s = ref.read(sessionProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    final cached = regenerate ? null : await StatementLinks.cachedToken(s, widget.customer.id);
    if (cached != null) {
      if (mounted) setState(() => (_token = cached, _loading = false));
      // تحديث صامت: لو جدّد جوال آخر الرابط نأخذ الجديد
      if (s.online) {
        try {
          final fresh = await StatementLinks.fetch(s, widget.customer.id);
          if (mounted) setState(() => _token = fresh);
        } catch (_) {}
      }
      return;
    }
    try {
      final t = await StatementLinks.fetch(s, widget.customer.id, regenerate: regenerate);
      if (mounted) setState(() => (_token = t, _loading = false));
      if (regenerate && mounted) showOk(context, 'تم تجديد الرابط — الرابط القديم لم يعد يعمل');
    } catch (e) {
      if (mounted) setState(() => (_error = AjilError.parse(e), _loading = false));
    }
  }

  Future<void> _regenerate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تجديد رابط الكشف؟'),
        content: const Text('سيتوقف الرابط القديم عن العمل فوراً، ويحتاج الزبون الرابط الجديد.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تجديد')),
        ],
      ),
    );
    if (ok == true) await _load(regenerate: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final w = s.session!;
    final canRegenerate = w.isOwner || s.settings?['employees_can_send_notices'] == true;
    final url = _token == null ? null : StatementLinks.url(_token!);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('رابط كشف الحساب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('صفحة للقراءة فقط يرى فيها ${widget.customer.name} رصيده وآخر حركاته ووعوده، بدون رقم جواله أو ملاحظاتك.',
              style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
          const SizedBox(height: 14),
          if (!StatementLinks.configured)
            const InfoStrip(
              icon: Icons.info_outline,
              bg: AjilColors.pendingBg,
              fg: AjilColors.pendingText,
              text: 'عنوان صفحة الكشف غير مضبوط في هذا الإصدار (STATEMENT_BASE_URL)',
            )
          else if (_loading)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else if (url == null)
            InfoStrip(
              icon: _error?.code == 'offline' ? Icons.wifi_off_rounded : Icons.error_outline,
              bg: AjilColors.pendingBg,
              fg: AjilColors.pendingText,
              text: _error?.code == 'offline'
                  ? 'لا يوجد اتصال — إنشاء رابط الكشف يحتاج إنترنت. حاول عند عودة الاتصال.'
                  : (_error?.message ?? 'تعذّر جلب الرابط'),
              action: ('إعادة', () => _load()),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: AjilColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AjilColors.divider),
              ),
              child: SelectableText(url,
                  textDirection: TextDirection.ltr, maxLines: 2, style: const TextStyle(fontSize: 13, color: AjilColors.text)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Share.share(url, subject: 'كشف حساب ${widget.customer.name}'),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('مشاركة'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) showOk(context, 'نُسخ الرابط');
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ'),
                ),
              ),
            ]),
            if (canRegenerate) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: s.online ? _regenerate : () => showError(context, 'offline: تجديد الرابط يحتاج اتصالاً بالإنترنت'),
                icon: const Icon(Icons.autorenew_rounded, color: AjilColors.debt),
                label: const Text('تجديد الرابط (يُبطل القديم)', style: TextStyle(color: AjilColors.debt)),
              ),
            ],
          ],
        ]),
      ),
    );
  }
}
