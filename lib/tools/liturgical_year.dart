String liturgicalYear(int year) {
  //renvoie l'année liturgique pour une année donnée
  // C pour les années multiples de 3, puis A et B
  switch (year % 3) {
    case 0:
      return 'C';
    case 1:
      return 'A';
  }
  return 'B';
}
