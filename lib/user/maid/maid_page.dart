import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MaidPage extends StatefulWidget {
  const MaidPage({super.key});

  @override
  _MaidPageState createState() => _MaidPageState();
}

class _MaidPageState extends State<MaidPage> with SingleTickerProviderStateMixin {
  final Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maid Page', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: _buildViewAllMaid(),
    );
  }

  Widget _buildViewAllMaid() {
    return Container(
      color: Colors.grey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('maids').snapshots(),
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

            var maidDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: maidDocs.length,
              itemBuilder: (context, index) {
                var maidData = maidDocs[index].data() as Map<String, dynamic>;
                var profileImageURL = maidData['profileImageURL'];
                var name = maidData['name'];
                var contactNumber = maidData['contactNumber'];
                var dob = maidData['dob'];
                var age = maidData['age'];
                var gender = maidData['gender'];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: profileImageURL != null ? NetworkImage(profileImageURL) : null,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Name: $name', style: TextStyle(color: gold,fontWeight: FontWeight.bold)),
                            Text('Phone : $contactNumber', style: TextStyle(color: gold)),
                            Text('Date of Birth: $dob', style: TextStyle(color: gold)),
                            Text('Age: $age', style: TextStyle(color: gold)),
                            Text('Gender: $gender', style: TextStyle(color: gold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
