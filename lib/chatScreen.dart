import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'messageScreen.dart';
import 'marketplace.dart';
import 'userProfile.dart';
import 'homeScreen.dart';
import 'orderScreen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  Future<DocumentSnapshot?> _getUserData(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) return userDoc;

    final sellerDoc =
        await FirebaseFirestore.instance
            .collection('sellers')
            .doc(userId)
            .get();

    if (sellerDoc.exists) return sellerDoc;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            color: Color(0xFF292B41),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Chat",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                color: Color(0xFF292B41),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Contact List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('chats')
                        .where('users', arrayContains: currentUserId)
                        .snapshots(), // 🔄 removed .orderBy
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No contacts found.",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF292B41),
                        ),
                      ),
                    );
                  }

                  final chats = snapshot.data!.docs;

                  // Sort by lastMessageTime (if exists), descending
                  chats.sort((a, b) {
                    final aTime =
                        (a['lastMessageTime'] as Timestamp?)?.toDate() ??
                        DateTime(1970);
                    final bTime =
                        (b['lastMessageTime'] as Timestamp?)?.toDate() ??
                        DateTime(1970);
                    return bTime.compareTo(aTime);
                  });

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      final data = chat.data() as Map<String, dynamic>;

                      final List<dynamic> users = data['users'] ?? [];

                      final otherUserId = users.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      if (otherUserId == '') return const SizedBox.shrink();

                      return FutureBuilder<DocumentSnapshot?>(
                        future: _getUserData(otherUserId),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return const SizedBox.shrink();
                          }

                          final userData =
                              userSnapshot.data!.data()
                                  as Map<String, dynamic>?;

                          if (userData == null) return const SizedBox.shrink();

                          final name =
                              userData.containsKey('first_name')
                                  ? "${userData['first_name']} ${userData['last_name']}"
                                  : userData['companyName'] ?? "Unknown";

                          final profileImage = userData['profileImage'] ?? '';

                          return _chatTile(
                            context,
                            chatId: chat.id,
                            name: name,
                            profileImage: profileImage,
                            lastMessage: data['lastMessage'] ?? '',
                            timestamp: data['lastMessageTime'],
                            otherUserId: otherUserId,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF292B41),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Marketplace()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderManagementPage(),
              ),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserProfile()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Market'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _chatTile(
    BuildContext context, {
    required String chatId,
    required String name,
    required String profileImage,
    required String lastMessage,
    required Timestamp? timestamp,
    required String otherUserId,
  }) {
    final DateTime? time = timestamp != null ? timestamp.toDate() : null;

    String formattedTime = '';
    if (time != null) {
      final now = DateTime.now();
      if (now.difference(time).inDays == 0) {
        formattedTime =
            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      } else {
        formattedTime = "${time.day}/${time.month}/${time.year}";
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFC5E4E6),
        borderRadius: BorderRadius.circular(90),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF292B41),
          backgroundImage:
              profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
          child:
              profileImage.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF292B41),
          ),
        ),
        subtitle: Text(
          lastMessage.isNotEmpty ? lastMessage : "(No messages yet)",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF292B41),
          ),
        ),
        trailing: Text(
          formattedTime,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      Messagescreen(chatId: chatId, otherUserId: otherUserId),
            ),
          );
        },
      ),
    );
  }
}
