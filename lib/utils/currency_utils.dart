String currencySymbol(String code) {
  switch (code) {
    case 'USD':
      return '\$';
    case 'SAR':
      return 'ر.س';
    case 'EUR':
    default:
      return '€';
  }
}
