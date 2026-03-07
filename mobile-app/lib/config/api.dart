class ApiConfig {
  // emulator
  //static const String baseUrl = "http://10.0.2.2:5000";

  // For physical device:
  // cmd -> ipconfig -> IPv4 Address (Wi-Fi adapter)
  // static const String baseUrl = "http://IPv4 Address:5000";
   static const String baseUrl = "http://192.168.8.159:5000";
  // static const String baseUrl = "http://10.155.119.121:5000";
   static const String fastApiBaseUrl = "http://10.20.130.135:8000"; // inference server
}
