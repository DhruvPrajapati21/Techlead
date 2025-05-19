import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageServiceRequest extends StatefulWidget {
  const ManageServiceRequest({super.key});

  @override
  State<ManageServiceRequest> createState() => _ManageServiceRequestState();
}

class _ManageServiceRequestState extends State<ManageServiceRequest> {
  // Controllers to handle the text inputs
  final TextEditingController requestIdController = TextEditingController();
  final TextEditingController clientNameController = TextEditingController();
  final TextEditingController clientInfoController = TextEditingController();
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController assignedEmployeeController = TextEditingController();
  final TextEditingController commentController = TextEditingController();

  // Variables to hold the selected values
  String? selectedUrgency = 'Low';
  String? selectedStatus = 'New';
  DateTime? selectedDateTime;

  // Function to handle the date and time selection
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.teal,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal, // button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                dialHandColor: Colors.teal,
                hourMinuteTextColor: Colors.teal,
              ),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Service Request"),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade200, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Request ID
                  _buildTextField(
                    controller: requestIdController,
                    label: 'Request ID',
                    icon: Icons.confirmation_number,
                  ),
                  const SizedBox(height: 10),

                  // Client Name
                  _buildTextField(
                    controller: clientNameController,
                    label: 'Client Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 10),

                  // Client Info
                  _buildTextField(
                    controller: clientInfoController,
                    label: 'Client Info',
                    icon: Icons.info_outline,
                  ),
                  const SizedBox(height: 10),

                  // Urgency Level Dropdown
                  _buildDropdown(
                    value: selectedUrgency,
                    label: 'Urgency Level',
                    icon: Icons.priority_high,
                    items: ['Low', 'Medium', 'High'],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedUrgency = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Agenda
                  _buildTextField(
                    controller: agendaController,
                    label: 'Agenda',
                    icon: Icons.event_note,
                  ),
                  const SizedBox(height: 10),

                  // Assigned Employee
                  _buildTextField(
                    controller: assignedEmployeeController,
                    label: 'Assigned Employee',
                    icon: Icons.assignment_ind,
                  ),
                  const SizedBox(height: 10),

                  // Scheduled Date and Time
                  GestureDetector(
                    onTap: () => _selectDateTime(context),
                    child: AbsorbPointer(
                      child: _buildTextField(
                        controller: TextEditingController(
                          text: selectedDateTime == null
                              ? ''
                              : '${selectedDateTime!.toLocal()}'.split(' ')[0],
                        ),
                        label: 'Scheduled Date and Time',
                        icon: Icons.calendar_today,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Request Status Dropdown
                  _buildDropdown(
                    value: selectedStatus,
                    label: 'Request Status',
                    icon: Icons.track_changes,
                    items: ['New', 'Assigned', 'In Progress', 'Completed'],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedStatus = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Comment/Feedback
                  _buildTextField(
                    controller: commentController,
                    label: 'Comment/Feedback',
                    icon: Icons.comment,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle form submission
                        print('Request ID: ${requestIdController.text}');
                        print('Client Name: ${clientNameController.text}');
                        print('Client Info: ${clientInfoController.text}');
                        print('Urgency Level: $selectedUrgency');
                        print('Agenda: ${agendaController.text}');
                        print('Assigned Employee: ${assignedEmployeeController
                            .text}');
                        print('Scheduled Date and Time: $selectedDateTime');
                        print('Request Status: $selectedStatus');
                        print('Comment/Feedback: ${commentController.text}');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                          'Submit', style: TextStyle(fontSize: 18, color: Colors
                          .white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String label,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Row(
            children: [
              Icon(
                Icons.circle,
                color: item == "Low"
                    ? Colors.green
                    : item == "Medium"
                    ? Colors.orange
                    : Colors.red,
                size: 12,
              ),
              const SizedBox(width: 10),
              Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal.shade300, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
        filled: true,
        fillColor: Colors.teal.shade50,
      ),
      dropdownColor: Colors.teal.shade100,
      icon: Icon(
          Icons.arrow_drop_down_circle, color: Colors.teal.shade700, size: 28),
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 16,
      ),
    );
  }

}
