/// Master list of Karnataka police stations.
///
/// Used for the police station dropdown in user/prisoner forms.
/// Districts can be extended as deployment expands beyond Bangalore City.
class StationMaster {
  StationMaster._();

  static const List<String> bangaloreCity = [
    'Adugodi Police Station',
    'Airport Police Station',
    'Annaswamy Mudaliar Police Station',
    'Ashoknagar Police Station',
    'Banaswadi Police Station',
    'Basavangudi Police Station',
    'Bellandur Police Station',
    'Benniganahalli Police Station',
    'Bommanahalli Police Station',
    'Brookefield Police Station',
    'BTM Layout Police Station',
    'Byrathi Police Station',
    'Chikkabanavara Police Station',
    'Cox Town Police Station',
    'Cubbon Park Police Station',
    'CV Raman Nagar Police Station',
    'Electronic City Police Station',
    'Gangenahalli Police Station',
    'HAL Airport Police Station',
    'Halasuru Police Station',
    'Hebbal Police Station',
    'Hennur Police Station',
    'High Grounds Police Station',
    'Hoodi Police Station',
    'HSR Layout Police Station',
    'Hulimavu Police Station',
    'Indiranagar Police Station',
    'JP Nagar Police Station',
    'Jigani Police Station',
    'Kadugondanahalli Police Station',
    'Kagadaspura Police Station',
    'Kamakshipalya Police Station',
    'Kodigehalli Police Station',
    'Konanakunte Police Station',
    'Koramangala Police Station',
    'KR Puram Police Station',
    'Kumaraswamy Layout Police Station',
    'Lingarajapuram Police Station',
    'Madanayakanahalli Police Station',
    'Mahalakshmipuram Police Station',
    'Marathahalli Police Station',
    'Mathikere Police Station',
    'Muneshwara Nagar Police Station',
    'Nandini Layout Police Station',
    'Nagarabhavi Police Station',
    'New Town Police Station',
    'Panduranga Nagar Police Station',
    'Rajajinagar Police Station',
    'Rajarajeshwari Nagar Police Station',
    'Ramamurthy Nagar Police Station',
    'Sadashivanagar Police Station',
    'Sampangiramanagar Police Station',
    'Sanjay Nagar Police Station',
    'Shivajinagar Police Station',
    'Srirampura Police Station',
    'Subramanyapura Police Station',
    'Ulsoor Police Station',
    'Upparpet Police Station',
    'Varthur Police Station',
    'Vijayanagar Police Station',
    'Whitefield Police Station',
    'Wilson Garden Police Station',
    'Yelahanka New Town Police Station',
    'Yelahanka Police Station',
    'Yeshwanthpur Police Station',
  ];

  static const List<String> bangaloreRural = [
    'Anekal Police Station',
    'Attibele Police Station',
    'Bagalur Police Station',
    'Channapatna Police Station',
    'Devanahalli Police Station',
    'Doddaballapur Police Station',
    'Hosakote Police Station',
    'Kengeri Police Station',
    'Magadi Police Station',
    'Nelamangala Police Station',
    'Ramanagara Police Station',
  ];

  static const List<String> mysuru = [
    'Jayalakshmipuram Police Station',
    'Krishnamurthypuram Police Station',
    'Lashkar Police Station',
    'Nazarbad Police Station',
    'Saraswathipuram Police Station',
    'V V Mohalla Police Station',
  ];

  /// Combined list of all stations across districts.
  /// Sorted alphabetically for easy lookup in dropdowns.
  static final List<String> allStations = [
    ...bangaloreCity,
    ...bangaloreRural,
    ...mysuru,
  ]..sort();
}
