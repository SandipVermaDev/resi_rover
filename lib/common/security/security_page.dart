import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  _SecurityPageState createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> with SingleTickerProviderStateMixin {

  final Color gold = const Color(0xFFD7B504);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Security Page', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: _buildViewAllSecurity(),
    );
  }

  Widget _buildViewAllSecurity() {
    return Container(
      color: Colors.grey.shade400,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('userType', isEqualTo: 'security')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD7B504)),
                  strokeWidth: 3.0,
                ),
              );
            }

            var securityDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: securityDocs.length,
              itemBuilder: (context, index) {
                var securityData = securityDocs[index].data() as Map<String, dynamic>;
                var profileImageURL = securityData['profileImageURL'];
                var name = securityData['name'];
                var email = securityData['email'];
                var contactNumber = securityData['phone'];

                return GestureDetector(
                  onTap: () {
                    _showSecurityDetailsDialog(context, securityData);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profileImageURL != null ? CachedNetworkImageProvider(profileImageURL) : null,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Name :$name', style: TextStyle(color: gold,fontWeight: FontWeight.bold)),
                              Text('Email: $email', style: TextStyle(color: gold)),
                              Text('Ph No: $contactNumber', style: TextStyle(color: gold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showSecurityDetailsDialog(BuildContext context, Map<String, dynamic> securityData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Security Details', style: TextStyle(color: gold)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (securityData['profileImageURL'] != null)
                  CachedNetworkImage(
                    imageUrl: securityData['profileImageURL'],
                    height: 200,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                const SizedBox(height: 10),
                Text('Name: ${securityData['name']}', style: TextStyle(color: gold)),
                Text('Email: ${securityData['email']}', style: TextStyle(color: gold)),
                Text('Phone: ${securityData['phone']}', style: TextStyle(color: gold)),
                Text('Date of Birth: ${securityData['dob']}', style: TextStyle(color: gold)),
                Text('Age: ${securityData['age']}', style: TextStyle(color: gold)),
                Text('Gender: ${securityData['gender']}', style: TextStyle(color: gold)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
