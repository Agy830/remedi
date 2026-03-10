
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:remedi/database/db_helper.dart';
import 'package:intl/intl.dart';

/// Displays the medication history on a calendar.
/// 
/// Key features:
/// - Uses `TableCalendar` to show a monthly view.
/// - Fetches logs from `DBHelper` to mark days with events.
/// - Shows detailed list of 'TAKEN' vs 'MISSED' doses below the calendar.
/// - Adapts to Dark Mode automatically.
class PatientCalendarScreen extends StatefulWidget {
  const PatientCalendarScreen({super.key});

  @override
  State<PatientCalendarScreen> createState() => _PatientCalendarScreenState();
}

class _PatientCalendarScreenState extends State<PatientCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Map of Date -> List of Log Statuses/IDs
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  /// Loads all medication logs from SQLite and groups them by date.
  /// 
  /// This is used by the `TableCalendar`'s event loader to add dots/markers to days.
  Future<void> _loadEvents() async {
    final logs = await DBHelper().getAllLogs();
    
    final Map<DateTime, List<dynamic>> newEvents = {};
    
    for (var log in logs) {
      final dateString = log['taken_at'] as String;
      final date = DateTime.parse(dateString);
      // Normalize to day (strip time)
      final day = DateTime(date.year, date.month, date.day);
      
      if (newEvents[day] == null) newEvents[day] = [];
      newEvents[day]!.add(log);
    }

    if (mounted) {
      setState(() {
        _events = newEvents;
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    // TableCalendar uses normalized dates, but we double check
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black12 : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Medication History'),
        backgroundColor: isDark ? Colors.black : Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadEvents();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(isDark),
                const SizedBox(height: 8.0),
                Expanded(child: _buildEventList(isDark)),
              ],
            ),
    );
  }

  Widget _buildCalendar(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 10, 16),
        lastDay: DateTime.utc(2030, 3, 14),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        eventLoader: _getEventsForDay,
        
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: Colors.red),
          defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
          weekNumberTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
          markersMaxCount: 1,
          markerDecoration: const BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 17,
            fontWeight: FontWeight.w500
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black54),
          rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black54),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          weekendStyle: const TextStyle(color: Colors.red),
        ),
        
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildEventList(bool isDark) {
    final events = _getEventsForDay(_selectedDay!);
    
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: isDark ? Colors.white24 : Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No logs for this day',
              style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final log = events[index];
        final time = DateTime.parse(log['taken_at']);
        final status = log['status'];
        final medId = log['medication_id'];

        Color statusColor = Colors.grey;
        IconData statusIcon = Icons.help;
        
        if (status == 'TAKEN') {
          statusColor = Colors.green;
          statusIcon = Icons.check;
        } else if (status == 'MISSED') {
          statusColor = Colors.red;
          statusIcon = Icons.close;
        } else if (status == 'SKIPPED') {
          statusColor = Colors.orange;
          statusIcon = Icons.skip_next;
        }

        return Card(
          elevation: 2,
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(
                statusIcon,
                color: Colors.white,
              ),
            ),
            title: FutureBuilder<Map<String, dynamic>?>(
              future: DBHelper().getMedication(medId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return Text(
                    snapshot.data!['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  );
                }
                return Text('Medication #$medId', style: TextStyle(color: isDark ? Colors.white : Colors.black87));
              },
            ),
            subtitle: Text(
              DateFormat('h:mm a').format(time),
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            trailing: Chip(
              label: Text(
                status,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor: statusColor,
              padding: EdgeInsets.zero,
            ),
          ),
        );
      },
    );
  }
}
