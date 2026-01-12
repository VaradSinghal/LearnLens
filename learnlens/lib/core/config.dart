import 'dart:io';

class AppConfig {
  // For physical Android device: use your computer's local IP address
  // For Android Emulator: use 10.0.2.2
  // For iOS Simulator: use localhost
  // 
  // Your detected IP addresses:
  // - 192.168.137.1 (likely mobile hotspot/virtual adapter)
  // - 192.168.1.6 (likely main network adapter - USE THIS ONE if both devices on same WiFi)
  // 
  // IMPORTANT: Set this to your computer's IP address on the same network as your phone
  // If your phone and computer are on the same WiFi, use: 192.168.1.6
  // If using mobile hotspot, use: 192.168.137.1
  static const String _physicalDeviceIp = '192.168.1.6'; // Change to match your network!
  
  // Set to true if testing on physical device, false for emulator
  static const bool _usePhysicalDevice = true;
  
  static String get baseUrl {
    if (Platform.isAndroid) {
      if (_usePhysicalDevice && _physicalDeviceIp.isNotEmpty) {
        // Physical Android device - use computer's IP address
        return 'http://$_physicalDeviceIp:8000/api/v1';
      } else {
        // Android emulator - use 10.0.2.2
        return 'http://10.0.2.2:8000/api/v1';
      }
    } else if (Platform.isIOS) {
      if (_usePhysicalDevice && _physicalDeviceIp.isNotEmpty) {
        // Physical iOS device - use computer's IP address
        return 'http://$_physicalDeviceIp:8000/api/v1';
      } else {
        // iOS simulator - use localhost
        return 'http://localhost:8000/api/v1';
      }
    } else {
      // For other platforms, default to localhost
      return 'http://localhost:8000/api/v1';
    }
  }
}

