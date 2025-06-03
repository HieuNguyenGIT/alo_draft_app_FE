import 'package:alo_draft_app/util/color.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:alo_draft_app/blocs/contact/contact_bloc.dart';
import 'package:alo_draft_app/blocs/contact/contact_event.dart';
import 'package:alo_draft_app/blocs/contact/contact_state.dart';

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen>
    with TickerProviderStateMixin {
  late ContactBloc _contactBloc;
  final Map<int, AnimationController> _animationControllers = {};
  final Map<int, Animation<double>> _slideAnimations = {};

  @override
  void initState() {
    super.initState();
    _contactBloc = ContactBloc();
    _contactBloc.add(ContactsLoaded());
  }

  @override
  void dispose() {
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    _contactBloc.close();
    super.dispose();
  }

  AnimationController _getAnimationController(int contactId) {
    if (!_animationControllers.containsKey(contactId)) {
      _animationControllers[contactId] = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      );
      _slideAnimations[contactId] = Tween<double>(
        begin: 0.0,
        end: 120.0,
      ).animate(CurvedAnimation(
        parent: _animationControllers[contactId]!,
        curve: Curves.easeInOut,
      ));
    }
    return _animationControllers[contactId]!;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    AppLogger.log('Starting phone call for: $phoneNumber'); // Debug log

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      AppLogger.log('Created URI: $phoneUri'); // Debug log

      // Check if tel: scheme is supported
      bool canLaunch = await canLaunchUrl(phoneUri);
      AppLogger.log('Can launch tel URI: $canLaunch'); // Debug log

      if (canLaunch) {
        // Try with external application mode (forces opening in phone app)
        bool launched = await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );

        AppLogger.log('Launch successful: $launched'); // Debug log

        if (launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening phone app for $phoneNumber'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Try alternative approach for devices that don't support canLaunchUrl properly
        AppLogger.log('Trying alternative launch method...'); // Debug log

        await launchUrl(
          phoneUri,
          mode: LaunchMode.externalApplication,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone app should be opening...'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.log('Phone launch error: $e'); // Debug log
      AppLogger.log('Error type: ${e.runtimeType}'); // Debug log

      // Enhanced fallback with device-specific instructions
      await Clipboard.setData(ClipboardData(text: phoneNumber));

      if (mounted) {
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
                  style: const TextStyle(
                      fontSize: 11, fontStyle: FontStyle.italic),
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
                // Retry with a simpler approach
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
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _contactBloc,
      child: Scaffold(
        body: BlocBuilder<ContactBloc, ContactState>(
          builder: (context, state) {
            if (state is ContactLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (state is ContactLoaded) {
              if (state.contacts.isEmpty) {
                return const Center(
                  child: Text('No contacts found'),
                );
              }
              return ListView.builder(
                itemCount: state.contacts.length,
                itemBuilder: (context, index) {
                  final contact = state.contacts[index];
                  final animationController =
                      _getAnimationController(contact.id);
                  final slideAnimation = _slideAnimations[contact.id]!;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 0, vertical: 1),
                    height: 80,
                    child: Stack(
                      children: [
                        // Background call action - Full width
                        Container(
                          width: double.infinity,
                          height: 80,
                          color: AppColors.callBackground,
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone,
                                  color: AppColors.callIcon,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Call',
                                  style: TextStyle(
                                    color: AppColors.callIcon,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Slidable contact tile
                        AnimatedBuilder(
                          animation: slideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(slideAnimation.value, 0),
                              child: GestureDetector(
                                onHorizontalDragUpdate: (details) {
                                  if (details.delta.dx > 0 &&
                                      slideAnimation.value < 120) {
                                    // Dragging right
                                    double newValue = (slideAnimation.value +
                                            details.delta.dx * 2)
                                        .clamp(0.0, 120.0);
                                    animationController.value =
                                        newValue / 120.0;
                                  } else if (details.delta.dx < 0 &&
                                      slideAnimation.value > 0) {
                                    // Dragging left
                                    double newValue = (slideAnimation.value +
                                            details.delta.dx * 2)
                                        .clamp(0.0, 120.0);
                                    animationController.value =
                                        newValue / 120.0;
                                  }
                                },
                                onHorizontalDragEnd: (details) {
                                  if (slideAnimation.value > 60) {
                                    // If more than halfway, snap to open
                                    animationController.forward();
                                  } else {
                                    // Otherwise, snap back to closed
                                    animationController.reverse();
                                  }
                                },
                                onTap: () {
                                  if (slideAnimation.value < 30) {
                                    // Normal contact tap only when not swiped
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'Contact details for ${contact.phoneNumber}'),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 80,
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          contact.phoneNumber,
                                          style: const TextStyle(
                                            color: AppColors.phoneNumber,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(contact.contactDate),
                                          style: const TextStyle(
                                            color: AppColors.dateText,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            contact.phoneNumberOrigin,
                                            style: const TextStyle(
                                              color: AppColors.originText,
                                              fontSize: 13,
                                            ),
                                          ),
                                          // Status dot - only show if new
                                          if (contact.isNew)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppColors.newContact,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        // Call button overlay - Half screen width tap area
                        AnimatedBuilder(
                          animation: slideAnimation,
                          builder: (context, child) {
                            if (slideAnimation.value > 20) {
                              return Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: slideAnimation.value,
                                child: GestureDetector(
                                  onTap: () async {
                                    AppLogger.log(
                                        'Call button tapped for ${contact.phoneNumber}');
                                    await _makePhoneCall(contact.phoneNumber);
                                    animationController.reverse();
                                  },
                                  child: Container(
                                    color: Colors.transparent,
                                    child: const Center(
                                      // Add this
                                      child: Icon(
                                        Icons.phone,
                                        color: AppColors.callIcon,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }
            if (state is ContactFailure) {
              return Center(
                child: Text('Error: ${state.error}'),
              );
            }
            return const Center(
              child: Text('No contacts available'),
            );
          },
        ),
      ),
    );
  }
}
