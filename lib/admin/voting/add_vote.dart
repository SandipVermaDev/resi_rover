import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddVoteDialog extends StatefulWidget {
  const AddVoteDialog({super.key});

  @override
  _AddVoteDialogState createState() => _AddVoteDialogState();
}

class _AddVoteDialogState extends State<AddVoteDialog> {
  final Color gold = const Color(0xFFD7B504);
  List<TextEditingController> optionControllers = [TextEditingController()];
  TextEditingController titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey.shade400,
      title: const Text('Add Vote', style: TextStyle(color: Colors.black)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400.0,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: titleController,
                decoration: _inputDecoration('Title'),
              ),
              const SizedBox(height: 16.0),
              Column(
                children: [
                  for (int i = 0; i < optionControllers.length; i++)
                    _buildVotingOptionField(i + 1, optionControllers[i]),
                ],
              ),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      optionControllers.add(TextEditingController());
                    });
                  },
                  mini: true,
                  backgroundColor: Colors.black,
                  child: Icon(Icons.add, color: gold),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
      actions: [
        Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () {
              if (_areOptionsValid()) {
                _saveVoteDetails();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please enter at least two and non-empty options.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: Text('Add Vote', style: TextStyle(color: gold)),
          ),
        ),
      ],
    );
  }

  bool _areOptionsValid() {
    var nonEmptyOptions = optionControllers
        .where((controller) => controller.text.trim().isNotEmpty);

    return optionControllers.length >= 2 && nonEmptyOptions.length == optionControllers.length;
  }


  Widget _buildVotingOptionField(
      int optionNumber, TextEditingController controller) {
    return Column(
      children: [
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          decoration: _inputDecoration('Option $optionNumber'),
        ),
      ],
    );
  }

  void _saveVoteDetails() async {
    try {
      if (!mounted) return;

      if (titleController.text.isNotEmpty) {
        String docId =
            '${titleController.text.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}';

        Map<String, dynamic> voteData = {
          'title': titleController.text,
          'options':
          optionControllers.map((controller) => controller.text).toList(),
          'voteCounts': _initializeVoteCounts(
              optionControllers.map((controller) => controller.text).toList()),
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('votes')
            .doc(docId)
            .set(voteData);

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote added successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a title for the vote.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding vote: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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

  List<int> _initializeVoteCounts(List<String> options) {
    List<int> voteCounts = List.filled(options.length, 0);
    return voteCounts;
  }
}