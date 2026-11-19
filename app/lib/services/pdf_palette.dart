import 'package:flutter/material.dart' show Color;
import 'package:pdf/pdf.dart';

import '../core/theme.dart';

/// ألوان ملفات PDF مأخوذة من مظهر المستخدم الحالي — لا ألوان ثابتة في الخدمات
class PdfPalette {
  PdfPalette.of(AjilTheme t)
      : primary = _c(t.primary),
        primaryDark = _c(t.primaryDark),
        primaryLight = _c(t.primaryLight),
        onPrimary = _c(t.onPrimary),
        debt = _c(t.debt),
        debtBg = _c(t.debtBg),
        paid = _c(t.paid),
        paidBg = _c(t.paidBg),
        muted = _c(t.textMuted),
        border = _c(t.border),
        divider = _c(t.divider),
        paperBorder = _c(t.paperBorder),
        paperMuted = _c(t.paperMuted);

  final PdfColor primary, primaryDark, primaryLight, onPrimary;
  final PdfColor debt, debtBg, paid, paidBg;
  final PdfColor muted, border, divider, paperBorder, paperMuted;

  static PdfColor _c(Color c) => PdfColor.fromInt(c.value);
}
