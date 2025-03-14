import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; //for conection firebase
import 'package:cloud_firestore/cloud_firestore.dart'; //for conection firestore

void main() async {
  // for start firebase
  WidgetsFlutterBinding.ensureInitialized(); // start before use firebase
  await Firebase.initializeApp(); // for start firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // close debugbanner
      home: RestaurantListScreen(), // call class RestaurantListScreen
    );
  }
}

class RestaurantListScreen extends StatelessWidget {
  final CollectionReference restaurants = FirebaseFirestore.instance
      .collection('Restaurants'); //reference collection in firestore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurants")),
      body: StreamBuilder<QuerySnapshot>(
        // StreamBuilder use realtime data in firestore
        stream: restaurants.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator()); //use for waitting data
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Data"));
          }

          var restaurantList = snapshot.data!.docs; //pull data into variable

          return ListView.builder(
            itemCount: restaurantList.length,
            itemBuilder: (context, index) {
              var restaurant = restaurantList[index];
              String docId = restaurant.id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.restaurant, color: Colors.orange),
                  title: Text(restaurant['name'],
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  subtitle: Text("ประเภท: ${restaurant['type']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RestaurantFormScreen(
                                  isEditing: true, docId: docId),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmationDialog(context, docId);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const RestaurantFormScreen(isEditing: false),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
    
  }
  
  void _showDeleteConfirmationDialog(BuildContext context, String docId) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text("Confirm?"),
        content: const Text("Are you sure to delete?"),
        actions: [
          TextButton(
            child: const Text("cancel"),
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
          ),
          TextButton(
            child: const Text("delete", style: TextStyle(color: Colors.red)),
            onPressed: () {
              FirebaseFirestore.instance.collection('Restaurants').doc(docId).delete().then((_) {
                Navigator.of(dialogContext).pop();
              });
            },
          ),
        ],
      );
    },
  );
}

}

class RestaurantFormScreen extends StatefulWidget {
  final bool isEditing;
  final String? docId;

  const RestaurantFormScreen({super.key, required this.isEditing, this.docId});

  @override
  _RestaurantFormScreenState createState() => _RestaurantFormScreenState();
}

class _RestaurantFormScreenState extends State<RestaurantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final CollectionReference restaurants =
      FirebaseFirestore.instance.collection('Restaurants');

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.docId != null) {
      _loadRestaurantData();
    }
  }

  void _loadRestaurantData() async {
    var doc = await restaurants.doc(widget.docId).get();
    if (doc.exists) {
      setState(() {
        _nameController.text = doc['name'];
        _typeController.text = doc['type'];
        _locationController.text = doc['location'];
      });
    }
  }

  void _saveRestaurant() {
    if (_formKey.currentState!.validate()) {
      if (widget.isEditing && widget.docId != null) {
        restaurants.doc(widget.docId).update({
          'name': _nameController.text,
          'type': _typeController.text,
          'location': _locationController.text,
        }).then((_) {
          Navigator.pop(context);
        });
      } else {
        restaurants.add({
          'name': _nameController.text,
          'type': _typeController.text,
          'location': _locationController.text,
        }).then((_) {
          Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isEditing ? "แก้ไขร้านอาหาร" : "เพิ่มร้านอาหาร")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "ชื่อร้านอาหาร"),
                validator: (value) =>
                    value!.isEmpty ? "กรุณากรอกชื่อร้าน" : null,
              ),
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(labelText: "ประเภทอาหาร"),
                validator: (value) =>
                    value!.isEmpty ? "กรุณากรอกประเภทอาหาร" : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "ที่ตั้งร้าน"),
                validator: (value) =>
                    value!.isEmpty ? "กรุณากรอกที่ตั้งร้าน" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveRestaurant,
                child: Text(
                    widget.isEditing ? "บันทึกการแก้ไข" : "เพิ่มร้านอาหาร"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
