import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Color gold = const Color(0xFFD7B504);

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late BuildContext scaffoldContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: TextStyle(color: gold)),
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: gold),
      ),
      body: Builder(builder: (BuildContext context) {
        scaffoldContext = context;
        return Container(
          color: Colors.grey.shade400,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('userType', isEqualTo: 'user')
                .snapshots(),
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

              var userDocs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: userDocs.length,
                itemBuilder: (context, index) {
                  var userData = userDocs[index].data() as Map<String, dynamic>;
                  var username = userData['name'];
                  var phone = userData['phone'];
                  var wing = userData['wing'];
                  var flat = userData['flat'];
                  var profileImageURL = userData['profileImageURL'];

                  return GestureDetector(
                    onTap: () {
                      _showUserDetailsPopup(context, userData);
                    },
                    child: Card(
                      margin:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      color: Colors.black,
                      elevation: 2.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 35,
                          backgroundImage: profileImageURL != null
                              ? CachedNetworkImageProvider(profileImageURL)
                              : null,
                        ),
                        title: Text('Name: $username',
                            style: TextStyle(color: gold, fontSize: 20)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Phone: $phone',
                                style: TextStyle(color: gold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('Wing: $wing   Flat: $flat',
                                style: TextStyle(color: gold, fontSize: 15)),
                            const SizedBox(height: 4),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _showConfirmationDialog(
                                context, userDocs[index].id);
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _showConfirmationDialog(
      BuildContext context, String userId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: Text('Confirmation', style: TextStyle(color: gold)),
          content: Text('Are you sure you want to delete this user?',
              style: TextStyle(color: gold)),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                _deleteUser(context, userId);
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'userType': 'disabled'});

      SnackBar snackBar = const SnackBar(
        content: Text('User deleted successfully!'),
        duration: Duration(seconds: 3),
      );

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(snackBar);
    } catch (e) {
      SnackBar snackBar = const SnackBar(
        content: Text('Error while deleting user..!'),
        duration: Duration(seconds: 3),
      );

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(snackBar);
    }
  }

  Future<void> _showUserDetailsPopup(
      BuildContext context, Map<String, dynamic> userData) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: AlertDialog(
            backgroundColor: Colors.black87,
            title: Text('User Details', style: TextStyle(color: gold)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 25),
                  if (userData['profileImageURL'] != null)
                    CachedNetworkImage(
                      imageUrl: userData['profileImageURL'],
                      height: 200,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  const SizedBox(height: 25),
                  Text('Name: ${userData['name']}',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: gold)),
                  const SizedBox(height: 10),
                  Text('Wing: ${userData['wing']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Flat: ${userData['flat']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Email: ${userData['email']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Phone: ${userData['phone']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('DOB: ${userData['dob']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Gender: ${userData['gender']}',
                      style: TextStyle(color: gold)),
                  const SizedBox(height: 10),
                  Text('Age: ${userData['age']}',
                      style: TextStyle(color: gold)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
