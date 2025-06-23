import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

Widget buildTextField({
  required TextEditingController controller,
  required String labelText,
  String? hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool readOnly = false, // <-- Added
  FormFieldValidator<String>? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade900, Colors.blue.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    padding: EdgeInsets.symmetric(horizontal: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly, // <-- Applied here
      style: TextStyle(
        fontSize: 16,
        color: Colors.cyan.shade100,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.cyan.shade300,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        contentPadding: EdgeInsets.all(10),
      ),
      validator: validator,
    ),
  );
}


Widget buildLeaveField({
  required TextEditingController controller,
  required String labelText,
  String? hintText,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool readOnly = false,
  VoidCallback? onTap,
  FormFieldValidator<String>? validator,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade900, Colors.blue.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      style: TextStyle(
        fontSize: 16,
        color: Colors.cyan.shade100,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.cyan.shade300,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(icon, color: Colors.white),
        ),
        filled: true,
        fillColor: Colors.transparent,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(10),
      ),
      validator: validator,
    ),
  );
}

Widget buildDropdownField({
  required String labelText,
  required IconData icon,
  required String? value,
  required List<Map<String, dynamic>> items,
  required ValueChanged<String?> onChanged,
  FormFieldValidator<String>? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade900, Colors.blue.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: DropdownButtonFormField<String>(
      value: value,
      iconEnabledColor: Colors.white,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.white),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.all(10),
        labelStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      dropdownColor: Colors.blue.shade800,
      isExpanded: true, // Important for long text support
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item['text'],
          child: Row(
            children: [
              Icon(item['icon'], color: Colors.cyan.shade100),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item['text'],
                  style: TextStyle(color: Colors.cyan.shade100),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    ),
  );
}


Widget buildMultiSelectDropdownField({
  required String labelText,
  required IconData icon,
  required List<String> items,
  required List<String> selectedItems,
  required ValueChanged<List<String>> onChanged,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade900, Colors.blue.shade700],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.shade900.withOpacity(0.2),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: DropdownSearch<String>.multiSelection(
      items: items,
      selectedItems: selectedItems,
      onChanged: onChanged,
      popupProps: PopupPropsMultiSelection.menu(
        showSearchBox: true,
        showSelectedItems: false, // Hides the trailing checkbox
        itemBuilder: (context, item, isSelected) {
          return GestureDetector(
            onTap: () {
              List<String> newSelected = List.from(selectedItems);
              if (isSelected) {
                newSelected.remove(item);
              } else {
                newSelected.add(item);
              }
              onChanged(newSelected);
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [

                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            hintText: "Search employees...",
            hintStyle: TextStyle(color: Colors.white70),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: Icon(Icons.search, color: Colors.white),
          ),
          style: TextStyle(color: Colors.white),
        ),
        menuProps: MenuProps(
          backgroundColor: Colors.blue.shade800,
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: Colors.white),
          prefixIcon: Icon(icon, color: Colors.white),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(10),
        ),
        baseStyle: TextStyle(color: Colors.white),
      ),
      dropdownButtonProps: DropdownButtonProps(
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
      ),
    ),
  );
}

Widget buildCustomCheckboxTile({
  required String title,
  required bool value,
  required ValueChanged<bool?> onChanged,
  required IconData icon,
  required Color color,
}) {
  return Card(
    elevation: 6,
    shadowColor: Colors.cyan.shade300.withOpacity(0.3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.1),
            Colors.blue.shade700.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.shade800,
              ),
              padding: EdgeInsets.all(6),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue.shade900,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    ),
  );
}


Widget buildSection(String title, List<Widget> children) {
  return Card(
    elevation: 12,
    shadowColor: Colors.blue.shade900,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.label, color: Colors.blue.shade900),
              const SizedBox(width: 8),
              Expanded(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: [Colors.blue.shade900, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Widget buildDatePickerField(
    BuildContext context, {
      required String label,
      DateTime? date,
      required VoidCallback onTap,
      FormFieldValidator<String>? validator,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          style: TextStyle(
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            hintText: date == null ? "Pick a Date" : DateFormat('dd MMMM yyyy').format(date),
            hintStyle: TextStyle(
              color: Colors.cyan.shade300,
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            prefixIcon: Icon(Icons.calendar_today, color: Colors.white), // Add calendar icon as prefix
          ),
          controller: TextEditingController(
            text: date == null ? '' : DateFormat('dd MMMM yyyy').format(date),
          ),
          validator: validator,  // Apply validator here
        ),
      ),
    ),
  );
}

Widget buildTimePickerField(
    BuildContext context, {
      required String label,
      TimeOfDay? time,
      required VoidCallback onTap,
      FormFieldValidator<String>? validator,
    }) {
  return GestureDetector(
    onTap: onTap,
    child: AbsorbPointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade900.withOpacity(0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: TextFormField(
          style: TextStyle(
            color: Colors.white, // Set input text color to white
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: Colors.white, // Label text color
              fontWeight: FontWeight.bold,
            ),
            hintText: time == null
                ? "Pick a Time"
                : MaterialLocalizations.of(context).formatTimeOfDay(
              time,
              alwaysUse24HourFormat: true, // Format time with AM/PM
            ),
            hintStyle: TextStyle(
              color: Colors.cyan.shade300, // Hint text color
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            contentPadding: EdgeInsets.all(16),
            prefixIcon: Icon(
              Icons.access_time, // Calendar (time) icon
              color: Colors.white, // Set the color of the icon
            ),
          ),
          controller: TextEditingController(
            text: time == null
                ? ''
                : MaterialLocalizations.of(context).formatTimeOfDay(
              time,
              alwaysUse24HourFormat: false, // Format time with AM/PM
            ),
          ),
          validator: validator, // Apply validator here
        ),
      ),
    ),
  );
}

Widget buildCheckboxField({
  required String label,
  required bool value,
  required ValueChanged<bool?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            onChanged(!value); // Toggle checkbox value when tapped
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: value ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: value ? Colors.blue.shade800 : Colors.grey.shade400,
                width: 2,
              ),
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: Colors.blue.shade400.withOpacity(0.6),
                    spreadRadius: 2,
                    blurRadius: 6,
                  )
              ],
            ),
            child: value
                ? Icon(
              Icons.check,
              color: Colors.white,
              size: 24,
            )
                : Icon(
              Icons.check_box_outline_blank,
              color: Colors.grey.shade600,
              size: 24,
            ),
          ),
        ),
        SizedBox(width: 16),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    ),
  );
}

// Validator for client's full name
FormFieldValidator<String> clientNameValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the client\'s name';
  }
  return null;
};
FormFieldValidator<String> typeOfPropertyValidator = (value){
  if(value==null|| value.isEmpty){
    return'Please select the Property Type';
  }
};
FormFieldValidator<String> additionalDetails = (value){
  if(value==null|| value.isEmpty){
    return'Fill out the necessary details which is required';
  }
};
FormFieldValidator<String> currentHomeAutomation = (value){
  if(value==null|| value.isEmpty){
    return'Select the type of which type of automation you want';
  }
};

// Validator for client's phone number
FormFieldValidator<String> phoneNumberValidator = (value) {
  // Check if the value is empty
  if (value == null || value.isEmpty) {
    return 'Please enter the phone number';
  }
  // Check if the value contains only digits and has exactly 10 digits
  else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
    return 'Please enter a valid 10-digit phone number';
  }
  return null;
};

// Validator for appointment date
FormFieldValidator<DateTime> appointmentDateValidator = (value) {
  if (value == null) {
    return 'Please select an appointment date';
  }
  return null;
};

// Validator for appointment time
FormFieldValidator<TimeOfDay> appointmentTimeValidator = (value) {
  if (value == null) {
    return 'Please select an appointment time';
  }
  return null;
};

// Validator for meeting purpose
FormFieldValidator<String> meetingPurposeValidator = (value) {
  if (value == null) {
    return 'Please select a meeting purpose';
  }
  return null;
};

// Validator for meeting location
FormFieldValidator<String> meetingLocationValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the meeting location';
  }
  return null;
};

// Validator for assigned staff/CEO
FormFieldValidator<String> assignedStaffValidator = (value) {
  if (value == null) {
    return 'Please select assigned staff';
  }
  return null;
};

// Validator for task priority
FormFieldValidator<String> taskPriorityValidator = (value) {
  if (value == null) {
    return 'Please select task priority';
  }
  return null;
};
// Validator for Task Due Date
FormFieldValidator<String> taskDueDateValidator = (value) {
  if (value == null || value.isEmpty) {
    return 'Please select a task due date';
  }
  return null;
};


// Validator for Task Status
FormFieldValidator<String> taskStatusValidator = (value) {
  if (value == null) {
    return 'Please select a task status';
  }
  return null;
};


// Validator for Client Meeting Status
FormFieldValidator<String> clientMeetingStatusValidator = (value) {
  if (value == null) {
    return 'Please select the client meeting status';
  }
  return null;
};

////////////////////////////////////////////////////////////////////////////////////
//Sales page validators/////

class FieldValidators {
  // Full Name Validator
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {

      return 'Full Name is required';
    }
    return null;
  }

  // Contact Number Validator
  static String? validateContactNumber(String? value) {
    if (value == null || value.isEmpty) {

      return 'Please enter the phone number';
    }
    // Check if the value contains only digits and has exactly 10 digits
    else if (!RegExp(r'^\d{10}$').hasMatch(value)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {

      return 'Email is required';
    }
    // Simple regex to check for a valid email format
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // Preferred Contact Method Validator
  static String? validatePreferredContactMethod(String? value) {
    if (value == null) {

      return 'Preferred contact method is required';
    }
    return null;
  }

  // Lead Source Validator
  static String? validateLeadSource(String? value) {
    if (value == null) {

      return 'Lead Source is required';
    }
    return null;
  }

  // Lead Type Validator
  static String? validateLeadType(String? value) {
    if (value == null) {

      return 'Lead Type is required';
    }
    return null;
  }

  // Property Size Validator
  static String? validatePropertySize(String? value) {
    if (value == null || value.isEmpty) {

      return 'Property size is required';
    }
    return null;
  }

  // Budget Range Validator
  static String? validateBudgetRange(String? value) {
    if (value == null) {

      return 'Budget range is required';
    }
    return null;
  }
}

//Task report page validators
String? validateEmployeeName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter your name';
  }
  return null;
}

String? validateTaskTitle(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the task title';
  }
  return null;
}

String? validateTaskDescription(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the task description';
  }
  return null;
}

String? validateHoursWorked(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter the hours worked';
  }
  if (int.tryParse(value) == null) {
    return 'Please enter a valid number';
  }
  return null;
}

String? validateActionsTaken(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter actions taken';
  }
  return null;
}

String? validateNextSteps(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter next steps';
  }
  return null;
}

String? validateLocation(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a location';
  }
  return null;
}