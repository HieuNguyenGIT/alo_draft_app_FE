import 'package:flutter/material.dart';
import 'package:alo_draft_app/models/contact_model.dart';

enum FilterType { source, time }

enum TimeFilter { today, thisWeek, thisMonth }

class ContactFilterData {
  final FilterType? activeFilterType;
  final String? selectedSource;
  final TimeFilter? selectedTimeFilter;

  const ContactFilterData({
    this.activeFilterType,
    this.selectedSource,
    this.selectedTimeFilter,
  });

  ContactFilterData copyWith({
    FilterType? activeFilterType,
    String? selectedSource,
    TimeFilter? selectedTimeFilter,
  }) {
    return ContactFilterData(
      activeFilterType: activeFilterType ?? this.activeFilterType,
      selectedSource: selectedSource ?? this.selectedSource,
      selectedTimeFilter: selectedTimeFilter ?? this.selectedTimeFilter,
    );
  }

  bool get hasActiveFilter => activeFilterType != null;

  String get activeFilterText {
    if (activeFilterType == FilterType.source && selectedSource != null) {
      return Contact.originMapping[selectedSource!] ?? selectedSource!;
    } else if (activeFilterType == FilterType.time &&
        selectedTimeFilter != null) {
      switch (selectedTimeFilter!) {
        case TimeFilter.today:
          return 'Hôm nay';
        case TimeFilter.thisWeek:
          return 'Tuần này';
        case TimeFilter.thisMonth:
          return 'Tháng này';
      }
    }
    return '';
  }
}

class ContactFilterBottomSheet extends StatefulWidget {
  final ContactFilterData currentFilter;
  final Function(ContactFilterData) onFilterChanged;

  const ContactFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<ContactFilterBottomSheet> createState() =>
      _ContactFilterBottomSheetState();
}

class _ContactFilterBottomSheetState extends State<ContactFilterBottomSheet> {
  late ContactFilterData _tempFilter;

  @override
  void initState() {
    super.initState();
    _tempFilter = widget.currentFilter;
  }

  void _updateSourceFilter(String? source) {
    setState(() {
      if (source == null) {
        _tempFilter = const ContactFilterData();
      } else {
        _tempFilter = ContactFilterData(
          activeFilterType: FilterType.source,
          selectedSource: source,
        );
      }
    });
  }

  void _updateTimeFilter(TimeFilter? timeFilter) {
    setState(() {
      if (timeFilter == null) {
        _tempFilter = const ContactFilterData();
      } else {
        _tempFilter = ContactFilterData(
          activeFilterType: FilterType.time,
          selectedTimeFilter: timeFilter,
        );
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _tempFilter = const ContactFilterData();
    });
  }

  void _applyFilters() {
    widget.onFilterChanged(_tempFilter);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lọc danh sách',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Source Filter Section
                  const Text(
                    'Nguồn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Source Dropdown
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tempFilter.activeFilterType == FilterType.source
                            ? _tempFilter.selectedSource
                            : null,
                        hint: const Text('Nguồn...'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Tất cả nguồn'),
                          ),
                          ...Contact.originMapping.entries.map(
                            (entry) => DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            ),
                          ),
                        ],
                        onChanged: _updateSourceFilter,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Time Filter Section
                  const Text(
                    'Thời gian',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time Filter Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimeFilterChip('Hôm nay', TimeFilter.today),
                      _buildTimeFilterChip('Tuần này', TimeFilter.thisWeek),
                      _buildTimeFilterChip('Tháng này', TimeFilter.thisMonth),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Xem danh sách',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilterChip(String label, TimeFilter timeFilter) {
    final isSelected = _tempFilter.activeFilterType == FilterType.time &&
        _tempFilter.selectedTimeFilter == timeFilter;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateTimeFilter(timeFilter);
        } else {
          _updateTimeFilter(null);
        }
      },
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue,
      backgroundColor: Colors.grey[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black87,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
