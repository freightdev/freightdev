import 'package:flutter/material.dart';
import '../../../../core/theme/colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/loadboard_model.dart';

class CalendarDispatchScreen extends StatefulWidget {
  const CalendarDispatchScreen({super.key});

  @override
  State<CalendarDispatchScreen> createState() => _CalendarDispatchScreenState();
}

class _CalendarDispatchScreenState extends State<CalendarDispatchScreen> {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.roadBlack,
      appBar: AppBar(
        backgroundColor: AppColors.asphaltGray,
        title: const Text(
          'Schedule',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        actions: [
          AppButton(
            label: 'Today',
            variant: AppButtonVariant.secondary,
            size: AppButtonSize.small,
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedMonth = DateTime.now();
              });
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          _CalendarWidget(
            selectedDate: _selectedDate,
            focusedMonth: _focusedMonth,
            onDateSelected: (date) {
              setState(() => _selectedDate = date);
            },
            onMonthChanged: (month) {
              setState(() => _focusedMonth = month);
            },
          ),
          // Schedule for selected day
          Expanded(
            child: _DaySchedule(
              date: _selectedDate,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new event
        },
        backgroundColor: AppColors.sunrisePurple,
        child: const Icon(Icons.add, color: AppColors.white),
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedMonth;
  final Function(DateTime) onDateSelected;
  final Function(DateTime) onMonthChanged;

  const _CalendarWidget({
    required this.selectedDate,
    required this.focusedMonth,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday % 7;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.white),
                onPressed: () {
                  onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month - 1));
                },
              ),
              Text(
                _getMonthYearLabel(focusedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.white),
                onPressed: () {
                  onMonthChanged(DateTime(focusedMonth.year, focusedMonth.month + 1));
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return SizedBox(
                width: 40,
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGray,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Calendar grid
          ...List.generate(6, (weekIndex) {
            final weekDays = List.generate(7, (dayIndex) {
              final dayNumber = weekIndex * 7 + dayIndex - firstWeekday + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox(width: 40, height: 40);
              }

              final date = DateTime(focusedMonth.year, focusedMonth.month, dayNumber);
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isToday = date.year == DateTime.now().year &&
                  date.month == DateTime.now().month &&
                  date.day == DateTime.now().day;

              return _DayCell(
                day: dayNumber,
                isSelected: isSelected,
                isToday: isToday,
                hasEvent: dayNumber % 3 == 0, // Mock: some days have events
                onTap: () => onDateSelected(date),
              );
            });

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: weekDays,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getMonthYearLabel(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final bool hasEvent;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.hasEvent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.gradientSunrise : null,
            color: isToday && !isSelected
                ? AppColors.sunrisePurple.withOpacity(0.2)
                : null,
            borderRadius: BorderRadius.circular(20),
            border: isToday && !isSelected
                ? Border.all(color: AppColors.sunrisePurple, width: 2)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.white,
                ),
              ),
              if (hasEvent && !isSelected)
                Positioned(
                  bottom: 4,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.yellowLine,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DaySchedule extends StatelessWidget {
  final DateTime date;

  const _DaySchedule({required this.date});

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(date);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: AppColors.gradientNight,
        border: Border.all(color: AppColors.borderGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _formatDateHeader(date),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
              ),
            ),
          ),
          if (events.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_busy,
                      size: 64,
                      color: AppColors.textGray,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No events scheduled',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  return _EventCard(event: events[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}';
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime date) {
    // Mock events
    if (date.day % 3 != 0) return [];

    return [
      {
        'time': '08:00 AM',
        'title': 'Pickup - LD-2024-001',
        'location': 'Chicago, IL',
        'type': 'pickup',
        'driver': 'John Smith',
      },
      {
        'time': '02:00 PM',
        'title': 'Delivery - LD-2024-002',
        'location': 'Dallas, TX',
        'type': 'delivery',
        'driver': 'Jane Doe',
      },
    ];
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event['type'] == 'pickup' ? AppColors.forestGreen : AppColors.truckRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event['time'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  event['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event['location'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 14,
                      color: AppColors.highwayBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      event['driver'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            event['type'] == 'pickup' ? Icons.upload : Icons.download,
            color: color,
            size: 24,
          ),
        ],
      ),
    );
  }
}
