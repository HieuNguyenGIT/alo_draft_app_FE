import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:alo_draft_app/util/constants.dart';
import 'package:alo_draft_app/services/api_service.dart';
import 'package:alo_draft_app/models/contact_model.dart';
import 'package:alo_draft_app/util/custom_logger.dart';

class ContactService {
  // Get all contacts
  Future<List<Contact>> getContacts() async {
    try {
      final token = await ApiService.getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/contacts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((contact) => Contact.fromJson(contact)).toList();
      } else {
        throw Exception('Failed to load contacts from server');
      }
    } catch (e) {
      AppLogger.log('API call failed, using mock data: $e');
      // Fallback to mock data
      return getMockContacts();
    }
  }

  // Hide contact
  Future<void> hideContact(int contactId) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/contacts/$contactId/hide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to hide contact');
      }
    } catch (e) {
      AppLogger.log('Hide contact API failed: $e');
      // In mock mode, we'll just log and continue
      AppLogger.log('Mock: Contact $contactId hidden locally');
    }
  }

  // Update contact status
  Future<void> updateContactStatus(int contactId, int newStatus) async {
    try {
      final token = await ApiService.getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/contacts/$contactId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'contact_status': newStatus,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update contact status');
      }
    } catch (e) {
      AppLogger.log('Update contact status API failed: $e');
      // In mock mode, we'll just log and continue
      AppLogger.log(
          'Mock: Contact $contactId status updated to $newStatus locally');
    }
  }

  // Mock data method
  List<Contact> getMockContacts() {
    return [
      Contact(
        id: 1,
        phoneNumber: '0988 365 247',
        origin: '0', // Nhận diện số
        contactDate: DateTime.now().subtract(const Duration(hours: 2)),
        isNew: true,
        accessUrl: 'https://nguyenhung2802.github.io/Web-the-band/',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '14.162.167.144',
      ),
      Contact(
        id: 2,
        phoneNumber: '+84 987 654 321',
        origin: '4', // Popup báo giá
        contactDate: DateTime.now().subtract(const Duration(days: 1)),
        isNew: false,
        accessUrl: 'https://example.com/pricing',
        contactStatus: 1,
        contactHideStatus: 0,
        contactIp: '10.0.0.123',
      ),
      Contact(
        id: 3,
        phoneNumber: '+84 123 456 789',
        origin: '21', // Google
        contactDate: DateTime.now().subtract(const Duration(hours: 5)),
        isNew: true,
        accessUrl: 'https://google.com/ads/landing',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '172.16.254.1',
      ),
      Contact(
        id: 4,
        phoneNumber: '+84 555 666 777',
        origin: '20', // Leadform
        contactDate: DateTime.now().subtract(const Duration(days: 3)),
        isNew: false,
        accessUrl: 'https://leadform.example.com',
        contactStatus: 2,
        contactHideStatus: 0,
        contactIp: '203.0.113.42',
      ),
      Contact(
        id: 5,
        phoneNumber: '+84 999 888 777',
        origin: '1', // Popup nút gọi
        contactDate: DateTime.now().subtract(const Duration(minutes: 30)),
        isNew: true,
        accessUrl: 'https://example.com/call-popup',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '198.51.100.78',
      ),
      Contact(
        id: 6,
        phoneNumber: '+84 444 333 222',
        origin: '10', // Báo giá sản phẩm
        contactDate: DateTime.now().subtract(const Duration(hours: 12)),
        isNew: false,
        accessUrl: 'https://example.com/product-quote',
        contactStatus: 1,
        contactHideStatus: 0,
        contactIp: '233.252.0.156',
      ),
      Contact(
        id: 7,
        phoneNumber: '+84 111 222 333',
        origin: '2', // Popup voucher
        contactDate: DateTime.now().subtract(const Duration(hours: 8)),
        isNew: true,
        accessUrl: 'https://example.com/voucher',
        contactStatus: 0,
        contactHideStatus: 0,
        contactIp: '192.168.1.100',
      ),
      Contact(
        id: 8,
        phoneNumber: '+84 777 888 999',
        origin: '3', // Popup lái thử
        contactDate: DateTime.now().subtract(const Duration(days: 2)),
        isNew: false,
        accessUrl: 'https://example.com/test-drive',
        contactStatus: 1,
        contactHideStatus: 0,
        contactIp: '10.10.10.10',
      ),
    ];
  }
}
