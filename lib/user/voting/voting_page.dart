import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VotingPage extends StatefulWidget {
  const VotingPage({super.key});

  @override
  _VotingPageState createState() => _VotingPageState();
}

class _VotingPageState extends State<VotingPage> {
  late Color gold;

  @override
  void initState() {
    super.initState();
    gold = const Color(0xFFD7B504);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Voting', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: _buildVotingList(),
    );
  }

  Widget _buildVotingList() {
    return Container(
      color: Colors.grey.shade400,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('votes').snapshots(),
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
                        'Vote for :- $title',
                        style: TextStyle(color: gold),
                      ),
                      Container(
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
                        Column(
                          children: [
                            InkWell(
                              onTap: () {
                                _voteForOption(votingId, options[i], i);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: _buildOptionWithProgressBar(
                                    options[i], voteCounts[i], totalVotes),
                              ),
                            ),
                            const SizedBox(height: 10.0),
                          ],
                        ),
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

  Widget _buildOptionWithProgressBar(
      String option, int voteCount, int totalVotes) {
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

  void _voteForOption(
      String votingId, String option, int selectedOptionIndex) async {
    try {
      // Get the current user's email
      String? email = FirebaseAuth.instance.currentUser?.email;
      if (email == null) {
        // Handle the case where the user is not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get the voting document
      var votingDoc = await FirebaseFirestore.instance
          .collection('votes')
          .doc(votingId)
          .get();
      if (!votingDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voting not found.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Check if the voting is closed
      var status = votingDoc.data()?['status'];
      if (status != 'open') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voting is closed.'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Get the previous vote from user_votes collection
      var userVoteRef = FirebaseFirestore.instance
          .collection('votes')
          .doc(votingId)
          .collection('user_votes')
          .doc(email);
      var userVoteDoc = await userVoteRef.get();
      String? previousOption;
      if (userVoteDoc.exists) {
        previousOption = userVoteDoc.data()?['option'];
      }

      // Update the vote count for the selected option
      DocumentSnapshot voteDoc = await FirebaseFirestore.instance
          .collection('votes')
          .doc(votingId)
          .get();
      List<int> voteCounts = List.from(voteDoc['voteCounts']);

      if (previousOption != null) {
        // Decrement the count for the previous option
        int previousOptionIndex = voteDoc['options'].indexOf(previousOption);
        if (previousOptionIndex != -1) {
          voteCounts[previousOptionIndex]--;
        }
      }
      // Increment the count for the selected option
      voteCounts[selectedOptionIndex]++;

      await FirebaseFirestore.instance
          .collection('votes')
          .doc(votingId)
          .update({
        'voteCounts': voteCounts,
      });

      // Record the user's vote to prevent multiple votes
      await userVoteRef.set({
        'option': option,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote submitted successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting vote: $e'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
