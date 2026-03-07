// Consolidated Sinhala translations for Weekly Price Forecast screen
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
  static const String rain = 'වැසි';
  static const String noRain = 'වැසි නොමැත';
  static const String breezy = 'මධ්‍යම සුළඟ';
  static const String calm = 'සුළඟ නොමැති';
  static const String highMoisture = 'උසස් ආර්ද්‍රතාව';

  // Weather description translations
  static const Map<String, String> _weatherDescriptions = {
    'scattered clouds': 'විහිදුණු වලාකුළු',
    'few clouds': 'අඩු වලාකුළු',
    'broken clouds': 'බිඳුණු වලාකුළු',
    'overcast clouds': 'අඳුරු වලාකුළු',
    'clear sky': 'පැහැදිලි ආකාශය',
    'light rain': 'සුළු වැසි',
    'moderate rain': 'මධ්‍යම වැසි',
    'heavy intensity rain': 'තද වැසි',
    'mist': 'මිදුම',
  };

  static const String isRequired = 'අවශ්‍යයි';
  static const String weatherDataLoaded = 'කාලගුණ දත්ත ලබාගෙන ඇත';

  static String translateWeatherDescription(String? desc) {
    if (desc == null) return '';
    final key = desc.trim().toLowerCase();
    return _weatherDescriptions[key] ?? desc;
  }
}
