import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  final Map<DateTime, List<CalendarEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    // TODO: Load actual events from database
    final now = DateTime.now();
    _events[DateTime(now.year, now.month, now.day)] = [
      CalendarEvent('Load Pickup', 'LOAD-001', EventType.pickup, '09:00 AM'),
      CalendarEvent('Load Delivery', 'LOAD-002', EventType.delivery, '02:00 PM'),
    ];
    _events[DateTime(now.year, now.month, now.day + 1)] = [
      CalendarEvent('Driver Meeting', 'John Smith', EventType.meeting, '10:00 AM'),
    ];
    _events[DateTime(now.year, now.month, now.day + 3)] = [
      CalendarEvent('Load Pickup', 'LOAD-005', EventType.pickup, '11:00 AM'),
    ];
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new event
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Calendar
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.surfaceGradient,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              eventLoader: _getEventsForDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppTheme.purplePrimary.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.purplePrimary,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.info,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonDecoration: BoxDecoration(
                  color: AppTheme.purplePrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: const TextStyle(color: Colors.white),
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
            ),
          ),

          // Events list for selected day
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Select a day to see events'))
                : _buildEventsList(_getEventsForDay(_selectedDay!)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Add event dialog
        },
        backgroundColor: AppTheme.purplePrimary,
        label: const Text('Add Event'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: AppTheme.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No events for this day',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getEventColor(event.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getEventIcon(event.type),
                color: _getEventColor(event.type),
              ),
            ),
            title: Text(event.title),
            subtitle: Text('${event.reference} • ${event.time}'),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getEventIcon(EventType type) {
    switch (type) {
      case EventType.pickup:
        return Icons.upload;
      case EventType.delivery:
        return Icons.download;
      case EventType.meeting:
        return Icons.people;
      case EventType.maintenance:
        return Icons.build;
      case EventType.other:
        return Icons.event;
    }
  }

  Color _getEventColor(EventType type) {
    switch (type) {
      case EventType.pickup:
        return AppTheme.info;
      case EventType.delivery:
        return AppTheme.success;
      case EventType.meeting:
        return AppTheme.warning;
      case EventType.maintenance:
        return AppTheme.error;
      case EventType.other:
        return AppTheme.purplePrimary;
    }
  }
}

enum EventType {
  pickup,
  delivery,
  meeting,
  maintenance,
  other,
}

class CalendarEvent {
  final String title;
  final String reference;
  final EventType type;
  final String time;

  CalendarEvent(this.title, this.reference, this.type, this.time);
}
