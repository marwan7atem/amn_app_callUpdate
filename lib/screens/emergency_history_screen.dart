import 'package:flutter/material.dart';
import '../models/emergency_event.dart';
import '../services/emergency_history_service.dart';

class EmergencyHistoryScreen extends StatelessWidget {
  const EmergencyHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Emergency History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Container(
        color: const Color(0xFF101010),
        child: StreamBuilder<List<EmergencyEvent>>(
          stream: EmergencyHistoryService.eventsStream(),
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildMonthSectionTitle('Emergency Calendar'),
                const SizedBox(height: 12),
                const _CalendarCard(
                  highlightedDays: [9, 12, 15],
                  monthLabel: 'Recent Incidents',
                ),
                const SizedBox(height: 16),
                const Text(
                  '* Highlighted dates indicate incidents.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (events.isEmpty)
                  const Text(
                    'No emergency events recorded yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  )
                else
                  ...events.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _IncidentCard.fromEvent(e),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final List<int> highlightedDays;
  final String monthLabel;

  const _CalendarCard({
    required this.highlightedDays,
    required this.monthLabel,
  });

  @override
  Widget build(BuildContext context) {
    final daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: daysOfWeek
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildWeekRow([1, 2, 3, 4, 5, 6, 7]),
              const SizedBox(height: 8),
              _buildWeekRow([8, 9, 10, 11, 12, 13, 14]),
              const SizedBox(height: 8),
              _buildWeekRow([15, 16, 17, 18, 19, 20, 21]),
              const SizedBox(height: 8),
              _buildWeekRow([22, 23, 24, 25, 26, 27, 28]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(List<int> days) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map(
            (day) {
              final isHighlighted = highlightedDays.contains(day);
              return Expanded(
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color:
                          isHighlighted ? Colors.redAccent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$day',
                        style: TextStyle(
                          color:
                              isHighlighted ? Colors.white : Colors.grey[300],
                          fontSize: 13,
                          fontWeight: isHighlighted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          )
          .toList(),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String dateTime;
  final String location;
  final String statusLabel;
  final Color statusColor;

  const _IncidentCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.statusLabel,
    required this.statusColor,
  });

  factory _IncidentCard.fromEvent(EmergencyEvent event) {
    IconData icon;
    Color iconColor;
    String locationText = event.location != null && event.location!.isNotEmpty
        ? 'Location: ${event.location}'
        : 'Location: Not specified';

    switch (event.type) {
      case 'sos':
        icon = Icons.warning_amber_rounded;
        iconColor = Colors.amber;
        break;
      case 'hospital_call':
        icon = Icons.local_hospital;
        iconColor = Colors.redAccent;
        break;
      case 'contact_call':
        icon = Icons.call;
        iconColor = Colors.redAccent;
        break;
      default:
        icon = Icons.emergency;
        iconColor = Colors.redAccent;
    }

    final dateTimeText =
        'Date: ${event.timestamp.toLocal().toString().substring(0, 16)}';

    return _IncidentCard(
      icon: icon,
      iconColor: iconColor,
      title: event.title,
      dateTime: dateTimeText,
      location: locationText,
      statusLabel: event.status,
      statusColor:
          event.status.toLowerCase() == 'cancelled' ? Colors.redAccent : Colors.green,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dateTime,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            location,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    // In a real app, navigate to details.
                  },
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
