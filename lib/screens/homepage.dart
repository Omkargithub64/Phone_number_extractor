// ignore_for_file: avoid_print

import 'dart:convert';
// import 'dart:html';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getContactPermission();
  }

  bool showloader = false;
  String number = "";
  List name = [];
  List numbers = [];
  File? image;

  Future pickImage() async {
    setState(() {
      showloader = true;
    });
    try {
      final image = await ImagePicker()
          .pickImage(source: ImageSource.camera, imageQuality: 9);
      if (image == null) return;
      // final imageTemp = File(image.path);
      final imageTemp = File(image.path);

      final request = http.MultipartRequest("POST",
          Uri.parse("https://60fb-103-89-235-250.ngrok-free.app/upload"));

      final headers = {"Content-type": "multipart/form-data"};
      request.files.add(http.MultipartFile(
          'image', imageTemp.readAsBytes().asStream(), imageTemp.lengthSync(),
          filename: imageTemp.path.split("/").last));
      request.headers.addAll(headers);
      final response = await request.send();

      http.Response res = await http.Response.fromStream(response);
      final resJson = jsonDecode(res.body);
      // number = resJson['number'];
      name = resJson['name'];
      numbers = resJson['numbers'];

      if (response.statusCode == 200) {
        print(res.body);
        print(numbers);
      } else {
        print("image not send");
      }
      setState(() {
        showloader = false;
      });

      setState(() => this.image = imageTemp);
    } on PlatformException catch (e) {
      print('Failed to pick image: $e');
    }
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();

  bool _isEditing = false;
  late int _editingIndex;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        floatingActionButton: SizedBox(
          width: 80,
          height: 80,
          child: RawMaterialButton(
            elevation: 50,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            fillColor: const Color(0xFF31304D),
            onPressed: pickImage,
            child: const Icon(
              Icons.camera,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        backgroundColor: const Color.fromARGB(255, 13, 15, 29),
        body: ModalProgressHUD(
          inAsyncCall: showloader,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // mainAxisSize: MainAxisSize.min,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 334,
                  width: 318,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 50, 0, 0),
                    decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 9, 0, 31),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            width: 9,
                            color: const Color.fromARGB(255, 30, 30, 50))),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: image != null
                          ? Image.file(image!)
                          // ? Text(image!.path)
                          : const Center(
                              child: Text(
                              "Select Image",
                              style: TextStyle(
                                color: Color.fromARGB(86, 145, 110, 232),
                              ),
                            )),
                    ),
                  ),
                ),
                Container(
                  // height: 300,
                  margin: const EdgeInsets.all(35),
                  // clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 30, 30, 50),
                      borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 300, minHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: numbers.length,
                        padding: const EdgeInsets.all(10),
                        itemBuilder: (BuildContext context, int index) {
                          if (_isEditing && _editingIndex == index) {
                            return ListTile(
                              title: TextField(
                                controller: _nameController,
                                decoration:
                                    const InputDecoration(hintText: 'Name'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(149, 255, 255, 255)),
                              ),
                              subtitle: TextField(
                                controller: _phoneNumberController,
                                decoration: const InputDecoration(
                                    hintText: 'Phone Number'),
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 255, 255, 255)),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () {
                                  _saveChanges(index);
                                },
                              ),
                            );
                          } else {
                            return ListTile(
                              title: Text(
                                name[index],
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(143, 255, 255, 255)),
                              ),
                              subtitle: Text(
                                numbers[index],
                                style: const TextStyle(
                                    fontSize: 20,
                                    color: Color.fromARGB(255, 255, 255, 255)),
                              ),
                              trailing: SizedBox(
                                width: 70,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          _startEditing(index);
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                        icon: const Icon(Icons.save),
                                        onPressed: () {
                                          savecontact(index);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startEditing(int index) {
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _nameController.text = name[index];
      _phoneNumberController.text = numbers[index];
    });
  }

  void _saveChanges(int index) {
    final newName = _nameController.text;
    final newPhoneNumber = _phoneNumberController.text;

    if (newName.isNotEmpty && newPhoneNumber.isNotEmpty) {
      setState(() {
        numbers[index] = newPhoneNumber;
        name[index] = newName;

        _isEditing = false;
      });
      print(name[index]);
    }
  }

  void getContactPermission() async {
    if (await Permission.contacts.isGranted) {
    } else {
      await Permission.contacts.request();
    }
  }

  savecontact(int index) async {
    Contact contact = Contact();
    contact.givenName = name[index];
    contact.phones = [Item(label: "mobile", value: numbers[index])];
    ContactsService.addContact(contact);
  }
}
