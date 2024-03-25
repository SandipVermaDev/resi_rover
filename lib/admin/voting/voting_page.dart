import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:resi_rover/admin/voting/add_vote.dart';
import 'package:resi_rover/admin/voting/edit_vote.dart';

class VotingPage extends StatefulWidget {
  const VotingPage({super.key});

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voting', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: _buildVotingList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddVoteDialog(context);
        },
        backgroundColor: gold,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildVotingList() {
    return Container(
      color: Colors.grey.shade400,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('votes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          var voteDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: voteDocs.length,
            itemBuilder: (context, index) {
              var voteData = voteDocs[index].data() as Map<String, dynamic>;
              var title = voteData['title'];
              var options = voteData['options'] as List<dynamic>;
              var voteCountsData = voteData['voteCounts'];
              var status = voteData['status'] ?? 'open';
              var votingId = voteDocs[index].id;
              List<int> voteCounts;

              if (voteCountsData is List<dynamic>) {
                voteCounts = voteCountsData.cast<int>();
              } else {
                voteCounts = List.filled(options.length, 0);
              }

              int totalVotes = voteCounts.reduce((sum, count) => sum + count);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(left: 20,right: 20,top: 20),
                color: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vote for :- ' + title,
                        style: TextStyle(color: gold),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              if (status == 'open') {
                                _showCloseVotingDialog(context, title, votingId);
                              } else if (status == 'closed') {
                                _showOpenVotingDialog(context, title, votingId);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: status == 'open' ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          PopupMenuButton(
                            color: gold,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditVoteDialog(context, votingId, title, options);
                              } else if (value == 'delete') {
                                _showDeleteVoteDialog(context, votingId, title);
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return ['edit', 'delete'].map((String choice) {
                                return PopupMenuItem<String>(
                                  value: choice,
                                  child: Text(choice),
                                );
                              }).toList();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '\nOptions:',
                        style: TextStyle(color: Colors.grey),
                      ),
                      for (int i = 0; i < options.length; i++)
                        _buildOptionWithProgressBar(options[i], voteCounts[i], totalVotes),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOptionWithProgressBar(String option, int voteCount, int totalVotes) {
    double progress = totalVotes > 0 ? voteCount / totalVotes : 0.0;

    return Column(
      children: [
        Text(
          ' $option ( $voteCount votes)',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 8.0),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey,
          valueColor: AlwaysStoppedAnimation<Color>(gold),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  void _showAddVoteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddVoteDialog();
      },
    );
  }

  void _showCloseVotingDialog(BuildContext context, String votingTitle, String votingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gold,
          title: const Text('Close Voting', style: TextStyle(color: Colors.black)),
          content: Text('Do you want to close the voting for "$votingTitle"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                _closeVoting(votingId);
                Navigator.pop(context);
              },
              child: const Text('Close', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _showOpenVotingDialog(BuildContext context, String votingTitle, String votingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gold,
          title: const Text('Open Voting', style: TextStyle(color: Colors.black)),
          content: Text('Do you want to open the voting for "$votingTitle"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                _openVoting(votingId);
                Navigator.pop(context);
              },
              child: const Text('Open', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _closeVoting(String votingId) async {
    try {
      // Update the 'status' field to 'closed'
      await FirebaseFirestore.instance
          .collection('votes')
          .doc(votingId)
          .update({'status': 'closed'});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voting closed successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error closing voting: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openVoting(String votingId) async {
    try {
      // Update the 'status' field to 'open'
      await FirebaseFirestore.instance
          .collection('votes')
          .doc(votingId)
          .update({'status': 'open','createdAt': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voting opened successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening voting: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEditVoteDialog(BuildContext context, String votingId, String title, List<dynamic> options) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Use the EditVoteDialog class from edit_vote.dart
        return EditVoteDialog(votingId: votingId, title: title, options: options);
      },
    );
  }

  void _showDeleteVoteDialog(BuildContext context, String votingId, String votingTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: gold,
          title: const Text('Delete Voting', style: TextStyle(color: Colors.black)),
          content: Text('Do you want to delete the voting for "$votingTitle"?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                _deleteVoting(votingId);
                Navigator.pop(context);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _deleteVoting(String votingId) async {
    try {
      await FirebaseFirestore.instance.collection('votes').doc(votingId).delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voting deleted successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting voting: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

}