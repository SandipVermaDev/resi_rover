import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditEventDialog extends StatefulWidget {
  final String eventId;

  const EditEventDialog({super.key, required this.eventId});

  @override
  _EditEventDialogState createState() => _EditEventDialogState();
}

class _EditEventDialogState extends State<EditEventDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _datetimeController = TextEditingController();
  DateTime? _selectedDate;

  final Color gold = const Color(0xFFD7B504);

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  void _fetchEventDetails() async {
    try {
      var eventSnapshot = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventSnapshot.exists) {
        var eventData = eventSnapshot.data() as Map<String, dynamic>;
        var title = eventData['title'];
        var description = eventData['description'];
        var eventDate = eventData['date'];
        var eventTime = eventData['time'];

        _titleController.text = title ?? '';
        _descriptionController.text = description ?? '';

        if (eventDate != null && eventTime != null) {
          _selectedDate = DateTime.parse('$eventDate $eventTime');
          _datetimeController.text =
              DateFormat("yyyy-MM-dd HH:mm").format(_selectedDate!);
        }
      }
    } catch (e) {
      print('Error fetching event details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black54,
      title: Text('Edit Event', style: TextStyle(color: gold)),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: gold),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: gold, fontSize: 20),
              ),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: TextStyle(color: gold),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: gold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: _datetimeController,
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
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

                if (pickedDate != null) {
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
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
                    initialTime:
                        TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
                  );

                  if (pickedTime != null) {
                    pickedDate = DateTime(pickedDate.year, pickedDate.month,
                        pickedDate.day, pickedTime.hour, pickedTime.minute);

                    setState(() {
                      _selectedDate = pickedDate;
                      _datetimeController.text =
                          DateFormat("yyyy-MM-dd HH:mm").format(_selectedDate!);
                    });
                  }
                }
              },
              style: TextStyle(color: gold),
              decoration: InputDecoration(
                labelText: 'Event Date and Time',
                labelStyle: TextStyle(color: gold, fontSize: 20),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context); // Close the dialog
          },
          child: Text('Cancel', style: TextStyle(color: gold)),
        ),
        TextButton(
          onPressed: () {
            // Implement logic to save changes for events
            _saveChanges();
            Navigator.pop(context); // Close the dialog after saving changes
          },
          child: Text('Save', style: TextStyle(color: gold)),
        ),
      ],
    );
  }

  // Function to save changes to the event
  void _saveChanges() async {
    if (!mounted) {
      return;
    }
    try {
      if (_titleController.text.isNotEmpty &&
          _descriptionController.text.isNotEmpty &&
          _selectedDate != null) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.eventId)
            .update({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
          'time': DateFormat('HH:mm').format(_selectedDate!),
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event updated successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in all the fields.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating event: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
