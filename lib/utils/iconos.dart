// Emoji de cada categoría
String emojiCategoria(String categoria) {
  switch (categoria) {
    case 'Comida':
      return '🍜';
    case 'Transporte':
      return '🚌';
    case 'Fiesta':
      return '🎉';
    case 'Casa':
      return '🏠';
    case 'Salud':
      return '💊';
    case 'Viajes':
      return '✈️';
    case 'Ropa':
      return '👚';
    default:
      return '✨';
  }
}