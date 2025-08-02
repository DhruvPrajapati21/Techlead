import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class TaskReport {
  final String employeeName, taskTitle, location, serviceStatus, serviceDepartment;
  final DateTime date;
  final String actionsTaken; // Admin ID/email

  TaskReport({
    required this.employeeName,
    required this.taskTitle,
    required this.location,
    required this.serviceStatus,
    required this.serviceDepartment,
    required this.date,
    required this.actionsTaken,
  });

  factory TaskReport.fromMap(Map<String, dynamic> data) {
    final ts = data['timestamp'] as Timestamp;
    return TaskReport(
      employeeName: data['employeeName'] ?? '',
      taskTitle: data['taskTitle'] ?? '',
      location: data['location'] ?? '',
      serviceStatus: data['service_status'] ?? '',
      serviceDepartment: data['Service_department'] ?? '',
      date: ts.toDate(),
      actionsTaken: data['actionsTaken'] ?? 'N/A',
    );
  }
}

// Syncfusion calendar appointments data source
class TaskDataSource extends CalendarDataSource {
  TaskDataSource(List<Appointment> source) {
    appointments = source;
  }
}
