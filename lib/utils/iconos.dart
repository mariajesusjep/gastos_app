import 'package:flutter/material.dart';

IconData iconoCategoria(String categoria) {
  switch (categoria) {
    case 'Comida':
      return Icons.restaurant;
    case 'Transporte':
      return Icons.directions_bus;
    case 'Fiesta':
      return Icons.celebration;
    case 'Casa':
      return Icons.home;
    case 'Salud':
      return Icons.local_hospital;
    case 'Viajes':
      return Icons.flight;
    case 'Ropa':
      return Icons.checkroom;
    default:
      return Icons.receipt_long;
  }
}