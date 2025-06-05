import 'package:alo_draft_app/util/color.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alo_draft_app/models/contact_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/contact/contact_bloc.dart';
import 'package:alo_draft_app/blocs/contact/contact_event.dart';

class ContactDetailScreen extends StatelessWidget {
  final Contact contact;

  const ContactDetailScreen({super.key, required this.contact});

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    AppLogger.log('Starting phone call for: $phoneNumber');

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      AppLogger.log('Created URI: $phoneUri');

      bool canLaunch = await canLaunchUrl(phoneUri);
      AppLogger.log('Can launch tel URI: $canLaunch');

      if (canLaunch) {
        bool launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );

        AppLogger.log('Launch successful: $launched');

        if (launched) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening phone app for $phoneNumber'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        AppLogger.log('Trying alternative launch method...');

        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone app should be opening...'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Phone launch error: $e');

      await Clipboard.setData(ClipboardData(text: phoneNumber));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone app launch failed'),
              Text('$phoneNumber copied to clipboard'),
              const SizedBox(height: 4),
              Text(
                'Error: ${e.toString()}',
                style:
                    const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          duration: const Duration(seconds: 5),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'RETRY',
            textColor: Colors.white,
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              try {
                await launchUrl(Uri.parse('tel:$phoneNumber'));
              } catch (e) {
                AppLogger.log('Retry failed: $e');
              }
            },
          ),
        ),
      );
    }
  }

  Future<void> _hideContact(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Ẩn thông tin'),
          content: const Text(
              'Bạn có chắc chắn muốn ẩn thông tin liên hệ này không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Hide the contact
                context.read<ContactBloc>().add(ContactHidden(contact.id));
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Go back to contact list

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã ẩn thông tin liên hệ'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Ẩn', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả Danh sách'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => _hideContact(context),
            child: const Text(
              'Ẩn thông tin',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phone Number - Large Orange Text
            Text(
              contact.phoneNumber,
              style: const TextStyle(
                color: AppColors.phoneNumber,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Contact Details
            _buildDetailRow('Ngày truy cập', _formatDate(contact.contactDate)),
            _buildDetailRow('Nguồn', contact.originName),
            _buildDetailRow('Địa chỉ IP', contact.contactIp),
            _buildDetailRow('URL truy cập', contact.accessUrl),

            // Status Section
            const SizedBox(height: 16),
            const Text(
              'Trạng thái',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),

            // Status dropdown (for future use)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: contact.contactStatus,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Chưa liên hệ')),
                    DropdownMenuItem(value: 1, child: Text('Đã liên hệ')),
                    DropdownMenuItem(value: 2, child: Text('Đã mua hàng')),
                  ],
                  onChanged: (int? newValue) {
                    if (newValue != null) {
                      // TODO: Update contact status via BLoC
                      context
                          .read<ContactBloc>()
                          .add(ContactStatusUpdated(contact.id, newValue));
                    }
                  },
                ),
              ),
            ),

            const Spacer(),

            // Call Customer Button
            Container(
              width: double.infinity,
              height: 50,
              margin: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                onPressed: () => _makePhoneCall(context, contact.phoneNumber),
                icon: const Icon(Icons.phone, color: Colors.white),
                label: const Text(
                  'Gọi khách hàng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.phoneNumber,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
