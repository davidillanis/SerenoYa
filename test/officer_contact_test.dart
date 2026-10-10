import 'package:flutter_test/flutter_test.dart';
import 'package:sereno_ya/data/services/officer/contact_service.dart';

void main() {
  test('telUri conserva dígitos y anula teléfonos vacíos', () {
    expect(telUri('987 654 321')?.toString(), 'tel:987654321');
    expect(telUri('+51 987 654 321')?.toString(), 'tel:+51987654321');
    expect(telUri(''), isNull);
    expect(telUri('sin-número'), isNull);
  });

  test('whatsappUri antepone el 51 a móviles de 9 dígitos', () {
    expect(whatsappUri('987654321')?.toString(), 'https://wa.me/51987654321');
    expect(whatsappUri('51987654321')?.toString(), 'https://wa.me/51987654321');
  });

  test('whatsappUri adjunta el mensaje inicial y anula vacíos', () {
    final uri = whatsappUri('987654321', message: 'Hola serenazgo');
    expect(uri?.queryParameters['text'], 'Hola serenazgo');
    expect(whatsappUri(''), isNull);
  });

  test('sanitizePhoneForWhatsApp deja solo dígitos', () {
    expect(sanitizePhoneForWhatsApp('+51 987-654-321'), '51987654321');
    expect(sanitizePhoneForWhatsApp('987654321'), '51987654321');
  });
}
