class WeeklyPriceForecastSi {
  // Titles
  static const String screenTitle = 'මිල අනාවැකි';

  // Descriptions / notes
  static const String description =
      'ඉදිරි සතියේ අනාවැකි මිල ලබා ගැනීමට, අවශ්‍ය විස්තර තෝරන්න.';
  static const String predictingFor = 'මිල අනාවැකි සදහා';
  static const String getPredictionsNote =
      'මෙම සතිය සඳහා මිල අනාවැකීන් ලබා ගන්න';

  // Dropdown labels
  static const String district = 'දිස්ත්‍රික්කය';

  static const String pepperType = 'ගම්මිරිස් වර්ගය';

  static const String grade = 'ශ්‍රේණිය';

  static const String selectPrefix = 'තෝරන්න';

  // Buttons / actions
  static const String predictPrice = 'මිල අනාවැකි බලන්න';
  static const String fetchDetails = 'විස්තර ලබා ගන්න';
  static const String loading = 'රැඳී සිටින්න';

  // Sections
  static const String weekDetails = 'සතියේ විස්තර';
  static const String weatherConditions = 'කාලගුණ තත්ත්ව';

  // Weather labels / descriptions
  static const String rainfall = 'වර්ෂාපතනය';
  static const String temperature = 'උෂ්ණත්වය';
  static const String humidity = 'ආර්ද්‍රතාවය';
  static const String windSpeed = 'සුළං වේගය';

  static const String isRequired = 'අවශ්‍යයි';
  static const String weatherDataLoaded =
      'ඉදිරි සතිය සඳහා කාලගුණ දත්ත ලබාගෙන ඇත';

  static const List<String> sinhalaMonths = [
    'ජනවාරි',
    'පෙබරවාරි',
    'මාර්තු',
    'අප්‍රේල්',
    'මැයි',
    'ජූනි',
    'ජූලි',
    'අගෝස්තු',
    'සැප්තැම්බර්',
    'ඔක්තෝබර්',
    'නොවැම්බර්',
    'දෙසැම්බර්',
  ];

  static String translateWeatherDescription(String? desc) {
    if (desc == null) return '';
    final key = desc.trim().toLowerCase();
    return key;
  }
}
