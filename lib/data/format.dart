/// Formats a whole-peso amount, for example 1250 becomes "₱1,250".
String formatPeso(int value) {
  final bool negative = value < 0;
  final String digits = value.abs().toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '${negative ? '−' : ''}₱$buffer';
}

/// "1 item", "3 items".
String pluralItems(int count) => '$count ${count == 1 ? 'item' : 'items'}';
