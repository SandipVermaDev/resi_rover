import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditVoteDialog extends StatefulWidget {
  final String votingId;
  final String title;
  final List<dynamic> options;

  List<int> _initializeVoteCounts(List<dynamic> options) {
    return List.filled(options.length, 0);
  }

  EditVoteDialog({
    required this.votingId,
    required this.title,
    required this.options,
  });

  @override
  State<EditVoteDialog> createState() => _EditVoteDialogState();
}

class _EditVoteDialogState extends State<EditVoteDialog> {
  TextEditingController _titleController = TextEditingController();

  Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    _titleController.text = widget.title;

    return AlertDialog(
      backgroundColor: gold,
      title: const Text('Edit Vote', style: TextStyle(color: Colors.black)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              //initialValue: widget.title,
              decoration: const InputDecoration(
                labelText: 'Voting Title',
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16.0),
            Column(
              children: [
                for (int i = 0; i < widget.options.length; i++)
                  _buildVotingOptionField(i + 1, widget.options[i]),
              ],
            ),
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.topRight,
              child: FloatingActionButton(
                onPressed: () {
                  setState(() {
                    widget.options.add('');
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
      actions: [
        Align(
          alignment: Alignment.bottomCenter,
          child: ElevatedButton(
            onPressed: () {
              if (_areOptionsValid(widget.options)) {
                _editVoteDetails(widget.votingId, widget.options);
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
            child: Text('Save Changes', style: TextStyle(color: gold)),
          ),
        ),
      ],
    );
  }

  bool _areOptionsValid(List<dynamic> options) {
    var nonEmptyOptions = options.where((option) => option.isNotEmpty);
    return options.length >= 2 && nonEmptyOptions.length == options.length;
  }

  Widget _buildVotingOptionField(int optionNumber, String option) {
    TextEditingController controller = TextEditingController(text: option);

    return TextFormField(
      controller: controller,
      onChanged: (value) {
        widget.options[optionNumber - 1] = value;
      },
      decoration: InputDecoration(
        labelText: 'Option $optionNumber',
        labelStyle: const TextStyle(color: Colors.black),
      ),
    );
  }

  void _editVoteDetails(String votingId, List<dynamic> options) async {
    try {
      if (!mounted) return;

      String updatedTitle = _titleController.text;
      print(
          "Updating vote details: votingId=$votingId, title=$updatedTitle, options=$options");

      if (updatedTitle.isNotEmpty) {
        Map<String, dynamic> voteData = {
          'title': updatedTitle,
          'options': options,
          'voteCounts': widget._initializeVoteCounts(options),
          'createdAt': FieldValue.serverTimestamp(),
        };

        await FirebaseFirestore.instance
            .collection('votes')
            .doc(votingId)
            .update(voteData);

        // Delete the user_votes collection associated with the edited vote
        await FirebaseFirestore.instance
            .collection('votes')
            .doc(votingId)
            .collection('user_votes')
            .get()
            .then((snapshot) {
          for (DocumentSnapshot doc in snapshot.docs) {
            doc.reference.delete();
          }
        });

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vote details updated successfully!'),
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
        print("Error updating vote details: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating vote details: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
