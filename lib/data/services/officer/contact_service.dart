import 'package:url_launcher/url_launcher.dart';

/// Contacto con el ciudadano desde el detalle del sereno.
/// Solo se usa con incidentes aceptados: en pendientes la información del
/// ciudadano no se expone.
class ContactService {
  const ContactService();

  /// Abre el marcador telefónico con el número del ciudadano.
  Future<bool> call(String phone) async {
    final target = telUri(phone);
    if (target == null) return false;
    try {
      return await launchUrl(target);
    } catch (_) {
      return false;
    }
  }

  /// Abre WhatsApp con un mensaje inicial hacia el ciudadano.
  Future<bool> whatsapp(String phone, {String? message}) async {
    final target = whatsappUri(phone, message: message);
    if (target == null) return false;
    try {
      return await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}

/// Construye el [Uri] `tel:` o `null` si no hay dígitos marcables.
Uri? telUri(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (cleaned.replaceAll('+', '').isEmpty) return null;
  return Uri(scheme: 'tel', path: cleaned);
}

/// Construye el enlace `wa.me` o `null` si no hay dígitos.
/// Los móviles peruanos de 9 dígitos usan el prefijo 51 que exige `wa.me`.
Uri? whatsappUri(String phone, {String? message}) {
  final digits = sanitizePhoneForWhatsApp(phone);
  if (digits.isEmpty) return null;
  final query = message != null && message.isNotEmpty
      ? <String, String>{'text': message}
      : null;
  return Uri.https('wa.me', '/$digits', query);
}

/// Deja solo dígitos y antepone el 51 a móviles de 9 dígitos.
String sanitizePhoneForWhatsApp(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 9) return '51$digits';
  return digits;
}
