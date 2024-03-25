import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  _AddEventsPageState createState() => _AddEventsPageState();
}

class _AddEventsPageState extends State<AddEventPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;

  final Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Event', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: Container(
        color: Colors.grey.shade400,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration('Title'),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecoration('Description'),
              ),
              const SizedBox(height: 16.0),
              DateTimeField(
                format: DateFormat("yyyy-MM-dd HH:mm"),
                style: TextStyle(color: gold),
                decoration: _inputDecoration('Date and Time'),
                onShowPicker: (context, currentValue) async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    initialDate: currentValue ?? DateTime.now(),
                    lastDate: DateTime(2101),
                    builder: (BuildContext context, Widget? child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          primaryColor: Colors.black,
                          colorScheme: ColorScheme.dark(
                            primary: gold,
                            onPrimary: Colors.black,
                            surface: Colors.black,
                            onSurface: gold,
                          ),
                          dialogBackgroundColor: Colors.black,
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: ThemeData.dark().copyWith(
                            primaryColor: Colors.black,
                            colorScheme: ColorScheme.dark(
                              primary: gold,
                              onPrimary: Colors.black,
                              surface: Colors.black,
                              onSurface: gold,
                            ),
                            dialogBackgroundColor: Colors.black,
                          ),
                          child: child!,
                        );
                      },
                    );
                    return DateTimeField.combine(date, time);
                  } else {
                    return currentValue;
                  }
                },
                onChanged: (value) {
                  setState(() {
                    _selectedDate = value;
                  });
                },
              ),
              const SizedBox(height: 100),
              ElevatedButton(
                onPressed: () async {
                  String title = _titleController.text.trim();
                  String description = _descriptionController.text.trim();

                  if (title.isNotEmpty && description.isNotEmpty && _selectedDate != null) {
                    String documentName = '${title}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';


                    await FirebaseFirestore.instance.collection('events').doc(documentName).set({
                      'title': title,
                      'description': description,
                      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      'time': DateFormat('HH:mm').format(_selectedDate!),
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Event added successfully!'),
                        duration: Duration(seconds: 3),
                      ),
                    );

                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill in all the fields.'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Text(
                    'Save Event',
                    style: TextStyle(fontSize: 18, color: gold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black),
      filled: true,
      fillColor: Colors.black26,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: const BorderSide(color: Colors.black),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.0),
        borderSide: BorderSide(color: gold),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
