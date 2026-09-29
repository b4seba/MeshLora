import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _kUserName = 'radio_mesh_user_name';
  static const String _kMessages = 'radio_mesh_messages';
  static const String _kIsPaired = 'radio_mesh_is_paired';
  static const String _kLastDeviceId = 'radio_mesh_last_device_id';

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserName, name);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserName);
  }

  Future<void> saveIsPaired(bool isPaired) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kIsPaired, isPaired);
  }

  Future<bool> getIsPaired() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsPaired) ?? false;
  }

  Future<void> saveLastDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastDeviceId, deviceId);
  }

  Future<String?> getLastDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLastDeviceId);
  }

  Future<void> saveMessages(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await prefs.setString(_kMessages, jsonEncode(jsonList));
  }

  Future<List<ChatMessage>?> getMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_kMessages);
    if (data == null || data.isEmpty) return null;
    try {
      final list = jsonDecode(data) as List<dynamic>;
      return list.map((item) => ChatMessage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
