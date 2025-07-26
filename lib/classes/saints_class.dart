// en construction, mais ce sera nécessaire pour avoir les détails de fêtes et les textes
// auxquels on doit accéder.

class Saints {
  /// Cette classe sert définir la structure de données pour la fiche d'un Saint
  String?
      title; // titre général de la fête ('Bienheureux Grégoire X, Pape' par exemple)
  String? description; // petite biographie proposée
  String?
      usage; // texte en plus pour donner des détails: "fête, mais solennité dans la ville" par exemple
  List?
      liturgicalCommons; // liste des communs proposés (pasteurs / religieux, ...)
}
