import 'package:alo_draft_app/util/color.dart';
import 'package:alo_draft_app/util/custom_logger.dart';
import 'package:alo_draft_app/util/filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alo_draft_app/blocs/contact/contact_bloc.dart';
import 'package:alo_draft_app/blocs/contact/contact_event.dart';
import 'package:alo_draft_app/blocs/contact/contact_state.dart';
import 'package:alo_draft_app/screens/contact_detail_screen.dart';
import 'package:alo_draft_app/models/contact_model.dart';

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
  ContactFilterData _currentFilter = const ContactFilterData();

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
        AppLogger.log('Trying alternative launch method...');

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
      AppLogger.log('Phone launch error: $e');

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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ContactFilterBottomSheet(
        currentFilter: _currentFilter,
        onFilterChanged: (filter) {
          setState(() {
            _currentFilter = filter;
          });
          _applyFilter(filter);
        },
      ),
    );
  }

  void _applyFilter(ContactFilterData filter) {
    String? sourceFilter;
    DateTime? startDate;
    DateTime? endDate;

    if (filter.activeFilterType == FilterType.source &&
        filter.selectedSource != null) {
      sourceFilter = filter.selectedSource;
    } else if (filter.activeFilterType == FilterType.time &&
        filter.selectedTimeFilter != null) {
      final now = DateTime.now();
      switch (filter.selectedTimeFilter!) {
        case TimeFilter.today:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case TimeFilter.thisWeek:
          final weekStart = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case TimeFilter.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          break;
      }
    }

    _contactBloc.add(ContactsFiltered(
      sourceFilter: sourceFilter,
      startDate: startDate,
      endDate: endDate,
    ));
  }

  void _clearFilter() {
    setState(() {
      _currentFilter = const ContactFilterData();
    });
    _contactBloc.add(ContactsLoaded());
  }

  void _navigateToDetail(Contact contact) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => ContactDetailScreen(contact: contact),
      ),
    )
        .then((_) {
      // Refresh contacts when returning from detail screen
      _contactBloc.add(ContactsLoaded());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _contactBloc,
      child: Scaffold(
        body: Column(
          children: [
            // Filter Bar
            if (_currentFilter.hasActiveFilter)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.blue[200]!),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lọc: ${_currentFilter.activeFilterText}',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearFilter,
                      child: Text(
                        'Xóa bộ lọc',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Contact List
            Expanded(
              child: BlocBuilder<ContactBloc, ContactState>(
                builder: (context, state) {
                  if (state is ContactLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (state is ContactLoaded) {
                    if (state.contacts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.contacts_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _currentFilter.hasActiveFilter
                                  ? 'Không tìm thấy liên hệ phù hợp'
                                  : 'Không có liên hệ nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
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
                          margin: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 1),
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
                                          double newValue =
                                              (slideAnimation.value +
                                                      details.delta.dx * 2)
                                                  .clamp(0.0, 120.0);
                                          animationController.value =
                                              newValue / 120.0;
                                        } else if (details.delta.dx < 0 &&
                                            slideAnimation.value > 0) {
                                          double newValue =
                                              (slideAnimation.value +
                                                      details.delta.dx * 2)
                                                  .clamp(0.0, 120.0);
                                          animationController.value =
                                              newValue / 120.0;
                                        }
                                      },
                                      onHorizontalDragEnd: (details) {
                                        if (slideAnimation.value > 60) {
                                          animationController.forward();
                                        } else {
                                          animationController.reverse();
                                        }
                                      },
                                      onTap: () {
                                        if (slideAnimation.value < 30) {
                                          _navigateToDetail(contact);
                                        }
                                      },
                                      child: Container(
                                        width: double.infinity,
                                        height: 80,
                                        color: Colors.white,
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
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
                                                _formatDate(
                                                    contact.contactDate),
                                                style: const TextStyle(
                                                  color: AppColors.dateText,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                          subtitle: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  contact.originName,
                                                  style: const TextStyle(
                                                    color: AppColors.originText,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                if (contact.isNew)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration:
                                                        const BoxDecoration(
                                                      color:
                                                          AppColors.newContact,
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
                              // Call button overlay
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
                                          await _makePhoneCall(
                                              contact.phoneNumber);
                                          animationController.reverse();
                                        },
                                        child: Container(
                                          color: Colors.transparent,
                                          child: const Center(
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${state.error}'),
                          ElevatedButton(
                            onPressed: () {
                              _contactBloc.add(ContactsLoaded());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(
                    child: Text('No contacts available'),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "contact_fab",
          onPressed: _showFilterBottomSheet,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.filter_list, color: Colors.white),
        ),
      ),
    );
  }
}
