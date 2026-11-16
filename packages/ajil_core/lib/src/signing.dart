import 'dart:convert';
import 'package:crypto/crypto.dart';

/// النص الموقَّع لطلب sync-push — يجب أن يطابق canonicalString في
/// supabase/functions/_shared/signature.ts حرفاً بحرف
String canonicalString({
  required String method,
  required String path,
  required String deviceId,
  required String timestamp,
  required String nonce,
  required String body,
}) {
  final bodyHash = sha256.convert(utf8.encode(body)).toString();
  return [method.toUpperCase(), path, deviceId, timestamp, nonce, bodyHash].join('\n');
}
