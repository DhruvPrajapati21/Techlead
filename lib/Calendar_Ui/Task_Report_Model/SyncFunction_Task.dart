import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'Report_Of_Task_Calendar.dart';

class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Appointment> source) {
    appointments = source;
  }
}

class TaskCalendarPage extends StatefulWidget {
  const TaskCalendarPage({Key? key}) : super(key: key);

  @override
  State<TaskCalendarPage> createState() => _TaskCalendarPageState();
}

class _TaskCalendarPageState extends State<TaskCalendarPage>
    with TickerProviderStateMixin {
  late Future<TaskDataSource> _futureAppointments;
  CalendarView _calendarView = CalendarView.week;
  Map<DateTime, List<TaskReport>> _dailyReports = {};
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Appointment? _selectedAppointment;
  bool _showCard = false;
  Appointment? _visibleAppointment;
  List<OverlayEntry> _activeBubbles = [];
  final GlobalKey _calendarKey = GlobalKey(); // key for SfCalendar wrapper
  final Map<Appointment, GlobalKey> _appointmentKeys = {}; // each appointment
  final Map<Appointment, LayerLink> _appointmentLinks = {};

  @override
  void initState() {
    super.initState();
    _futureAppointments = _fetchAndPrepareAppointments();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // from bottom
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _showAppointmentCard(Appointment appointment) {
    setState(() {
      _visibleAppointment = appointment;
      _showCard = true;
    });

    Future.delayed(const Duration(seconds: 4), () {
      setState(() => _showCard = false);
    });
  }

  void _handleAppointmentChange(Appointment? newAppointment) {
    if (newAppointment != _selectedAppointment) {
      setState(() {
        _selectedAppointment = newAppointment;
        _showCard = newAppointment != null;
        if (_showCard) {
          _slideController.forward();
        } else {
          _slideController.reverse();
        }
      });
    }
  }


  void _removeAllAppointmentBubbles() {
    for (final bubble in _activeBubbles) {
      bubble.remove();
    }
    _activeBubbles.clear();
  }

  Future<TaskDataSource> _fetchAndPrepareAppointments() async {
    final assignSnap =
        await FirebaseFirestore.instance.collection('TaskAssign').get();
    final reportSnap =
        await FirebaseFirestore.instance.collection('DailyTaskReport').get();

    // Map assignments for easy lookup (replace mapping keys accordingly)
    Map<String, dynamic> assigns = {
      for (var d in assignSnap.docs) d.id: d.data()
    };

    List<Appointment> appts = [];

    for (var doc in reportSnap.docs) {
      final data = doc.data();
      final report = TaskReport.fromMap(data);
      // Link this report to assignment — adjust if key name differs.
      final assigned = assigns[report.date.millisecondsSinceEpoch.toString()];
      final actionsTaken = assigned?['actionsTaken'] ?? report.actionsTaken;

      final start = report.date;
      final end = report.date.add(Duration(hours: 1));

      appts.add(Appointment(
        startTime: start,
        endTime: end,
        subject: '${report.taskTitle} -  EmployeeName: ${report.employeeName}',
        notes:
            'Location: ${report.location}\n'
            'Dept: ${report.serviceDepartment}\n'
            'Status: ${report.serviceStatus}\n'
            'Action Taken: $actionsTaken\n',
        color: report.serviceStatus.toLowerCase() == 'completed'
            ? Colors.green
            : report.serviceStatus.toLowerCase() == 'in progress'
                ? Colors.orange
                : Colors.redAccent,
      ));
    }

    return TaskDataSource(appts);
  }

  final List<Color> taskColors = [
    Color(0xFFFF6B6B), // Coral Red
    Color(0xFF00BFFF), // Deep Sky Blue
    Color(0xFF7CFC00), // Lawn Green
    Color(0xFFFFD700), // Gold
    Color(0xFFFF1493), // Deep Pink
    Color(0xFF00FA9A), // Medium Spring Green
    Color(0xFF1E90FF), // Dodger Blue
    Color(0xFFFF8C00), // Dark Orange (still shiny)
    Color(0xFFDA70D6), // Orchid
    Color(0xFF40E0D0), // Turquoise
  ];


  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF000F89), // Royal Blue
            Color(0xFF0F52BA), // Cobalt Blue
            Color(0xFF002147), // Dark Blue
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _fetchAndPrepareAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final dataSource = snapshot.data as TaskDataSource;

          return Column(
            children: [
              // Calendar View Selector (your unchanged container)
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF000F89),
                      Color(0xFF0F52BA),
                      Color(0xFF002147)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<CalendarView>(
                    value: _calendarView,
                    dropdownColor: const Color(0xFF0F52BA),
                    iconEnabledColor: Colors.cyanAccent,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    items: const [
                      DropdownMenuItem(
                          value: CalendarView.day, child: Text('Day')),
                      DropdownMenuItem(
                          value: CalendarView.week, child: Text('Week')),
                      DropdownMenuItem(
                          value: CalendarView.workWeek,
                          child: Text('Work Week')),
                      DropdownMenuItem(
                          value: CalendarView.month, child: Text('Month')),
                      DropdownMenuItem(
                          value: CalendarView.schedule,
                          child: Text('Schedule')),
                      DropdownMenuItem(
                          value: CalendarView.timelineDay,
                          child: Text('Timeline Day')),
                      DropdownMenuItem(
                          value: CalendarView.timelineWeek,
                          child: Text('Timeline Week')),
                      DropdownMenuItem(
                          value: CalendarView.timelineMonth,
                          child: Text('Timeline Month')),
                    ],
                    onChanged: (view) {
                      if (view != null) {
                        setState(() {
                          _calendarView = view;
                        });
                      }
                    },
                  ),
                ),
              ),

              // Calendar UI Expanded
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.8, // Or adjust as needed
                    child: Container(
                      key: _calendarKey,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF000F89),
                            Color(0xFF0F52BA),
                            Color(0xFF002147),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SfCalendar(
                        view: _calendarView,
                        dataSource: dataSource,
                        onViewChanged: (ViewChangedDetails details) {
                          _removeAllAppointmentBubbles();

                          final visibleDates = details.visibleDates;

                          final visibleAppointments = dataSource.appointments!
                              .cast<Appointment>()
                              .where((appt) => visibleDates.any((date) =>
                                  appt.startTime.year == date.year &&
                                  appt.startTime.month == date.month &&
                                  appt.startTime.day == date.day))
                              .toList();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            // Group appointments by datetime to detect overlaps
                            Map<String, List<Appointment>> groupedByTime = {};

                            for (var appt in visibleAppointments) {
                              final key = '${appt.startTime}-${appt.endTime}';
                              groupedByTime
                                  .putIfAbsent(key, () => [])
                                  .add(appt);
                            }

                            for (var entry in groupedByTime.entries) {
                              final apptsAtSameTime = entry.value;

                              for (int i = 0;
                                  i < apptsAtSameTime.length;
                                  i++) {
                                final appt = apptsAtSameTime[i];
                                final layerLink = _appointmentLinks[appt];

                                if (layerLink != null) {
                                  final overlay = OverlayEntry(
                                    builder: (context) =>
                                        CompositedTransformFollower(
                                      link: layerLink,
                                      offset: Offset(
                                        60 + (i * 30), // ⬅️ Horizontal spread
                                        -30 +
                                            (i *
                                                10), // ⬅️ Vertical staggering for collision avoidance
                                      ),
                                      showWhenUnlinked: false,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: _SpeechBubble(
                                          employeeName: appt.subject,
                                          onClose:
                                              _removeAllAppointmentBubbles,
                                        ),
                                      ),
                                    ),
                                  );

                                  _activeBubbles.add(overlay);
                                  Overlay.of(context, rootOverlay: true)
                                      .insert(overlay);
                                }
                              }
                            }

                            Future.delayed(const Duration(seconds: 15),
                                _removeAllAppointmentBubbles);
                          });
                        },
                        backgroundColor: Colors.transparent,
                        showDatePickerButton: true,
                        headerHeight: 70,
                        headerStyle: const CalendarHeaderStyle(
                          backgroundColor: Colors.transparent,
                          textAlign: TextAlign.center,
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        monthViewSettings: const MonthViewSettings(
                          monthCellStyle: MonthCellStyle(
                            backgroundColor: Color(0xFF0F52BA),
                            textStyle: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            leadingDatesTextStyle:
                                TextStyle(color: Colors.white70),
                            trailingDatesTextStyle:
                                TextStyle(color: Colors.white70),
                            todayBackgroundColor: Color(0xFF0F52BA),
                          ),
                          appointmentDisplayMode:
                              MonthAppointmentDisplayMode.appointment,
                          showAgenda: true,
                        ),
                        viewHeaderStyle: const ViewHeaderStyle(
                          backgroundColor: Colors.transparent,
                          dayTextStyle: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                          dateTextStyle: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        todayHighlightColor: Colors.deepOrangeAccent,
                        selectionDecoration: BoxDecoration(
                          color: Colors.deepOrangeAccent.withOpacity(0.3),
                          border: Border.all(
                              color: Colors.deepOrangeAccent, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        timeSlotViewSettings: const TimeSlotViewSettings(
                          startHour: 8,
                          endHour: 18,
                          timeIntervalHeight:
                              100, // ⬅️ increased for vertical space
                          timeInterval: Duration(hours: 1),
                          timeTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          dayFormat: 'EEE',
                          dateFormat: 'd',
                        ),
                        appointmentBuilder: (context, details) {
                          final appt = details.appointments.first;
                          final key = GlobalKey();
                          _appointmentKeys[appt] = key;
                          final layerLink = LayerLink();
                          _appointmentLinks[appt] = layerLink;

                          return CompositedTransformTarget(
                            link: layerLink,
                            child: Container(
                              key: key,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: getAppointmentColor(appt),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Text(
                                  appt.subject,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },


                        onTap: (CalendarTapDetails details) {
                          // 🔴 Immediately remove all overlays/bubbles before anything else
                          _removeAllAppointmentBubbles();

                          final appt = details.appointments?.first;
                          if (appt == null) return;

                          final formattedDate = DateFormat('dd MMMM yyyy').format(appt.startTime);
                          final formattedTime =
                              '${DateFormat('hh:mm a').format(appt.startTime)} - ${DateFormat('hh:mm a').format(appt.endTime)}';

                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade50, Colors.white],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.deepOrangeAccent.withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.event_note,
                                              color: Colors.deepOrangeAccent),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            'Task Details',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF002B5B),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    _infoRow("Title", appt.subject),
                                    if (appt.notes?.isNotEmpty == true) ...[
                                      const SizedBox(height: 12),
                                      _infoRow("Description", appt.notes!),
                                    ],
                                    const SizedBox(height: 12),
                                    _infoRow("Date", formattedDate),
                                    const SizedBox(height: 12),
                                    _infoRow("Time", formattedTime),
                                    const SizedBox(height: 30),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF000F89),
                                              Color(0xFF0F52BA),
                                              Color(0xFF002147),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: () => Navigator.pop(context),
                                          icon: const Icon(Icons.close, size: 18),
                                          label: const Text("Close"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },

                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Color getAppointmentColor(Appointment appointment) {
    switch (appointment.subject) {
      case 'Meeting':
        return Colors.green.shade700;
      case 'Workout':
        return Colors.orange.shade700;
      case 'Deadline':
        return Colors.red.shade700;
      default:
        return taskColors[appointment.subject.hashCode % taskColors.length];
    }
  }
}

class _SpeechBubble extends StatelessWidget {
  final String employeeName;
  final VoidCallback onClose;

  const _SpeechBubble({
    required this.employeeName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main bubble with Glassmorphism feel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.9),
                Colors.blue.shade50.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: const Offset(3, 4),
              ),
            ],
            border: Border.all(
              color: Colors.blueAccent.withOpacity(0.3),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person, size: 16, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  employeeName,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Arrow pointer
        Positioned(
          left: -8,
          top: 14,
          child: CustomPaint(
            painter: _BubbleArrowPainter(),
          ),
        ),
      ],
    );
  }
}

class _BubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 10); // Tip start
    path.lineTo(10, 5); // Top corner
    path.lineTo(10, 15); // Bottom corner
    path.close();

    canvas.drawShadow(path, Colors.black26, 3, true); // Subtle shadow
    canvas.drawPath(path, paint); // Fill shape
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
