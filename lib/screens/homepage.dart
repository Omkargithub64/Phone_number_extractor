// ignore_for_file: avoid_print

import 'dart:convert';
// import 'dart:html';
import 'dart:io';
// import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
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

  Future pickImage(bool isgall) async {
    setState(() {
      showloader = true;
    });
    try {
      final source = isgall ? ImageSource.gallery : ImageSource.camera;
      final image =
          await ImagePicker().pickImage(source: source, imageQuality: 20);
      if (image == null) {
        setState(() {
          showloader = false;
        });
        return;
      }
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        // aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        compressQuality: 20,
        compressFormat: ImageCompressFormat.jpg,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Select Area',
            toolbarColor: const Color(0xFF31304D),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
            showCropGrid: false,
            cropFrameColor: Colors.deepPurple,
            hideBottomControls: true,
          ),
          IOSUiSettings(
            title: 'Select Area',
          ),
          WebUiSettings(
            context: context,
          ),
        ],
      );

      if (croppedFile == null) {
        setState(() {
          showloader = false;
        });
        return null;
      }

      // final imageTemp = File(image.path);
      final imageTemp = File(croppedFile.path);

      final request = http.MultipartRequest("POST",
          Uri.parse("https://ad7f-157-45-209-228.ngrok-free.app/upload"));

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
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          height: 150,
          color: const Color(0xFF161A30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: IconButton(
                  icon: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF31304D),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    width: 100,
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        "assets/icons/scan.png",
                        color: Colors.white,
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ),
                  onPressed: () => {
                    pickImage(false),
                  },
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 80,
                child: IconButton(
                  icon: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF31304D),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    width: 100,
                    height: 100,
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Image.asset(
                        "assets/icons/gallery.png",
                        color: Colors.white,
                        width: 30,
                        height: 30,
                      ),
                    ),
                  ),
                  onPressed: () => {
                    pickImage(true),
                  },
                ),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF31304D),
          title: const Text("Phone Numbers"),
          // forceMaterialTransparency: true,
          foregroundColor: Colors.white,
        ),
        resizeToAvoidBottomInset: true,
        // floatingActionButton:
        floatingActionButtonLocation:
            FloatingActionButtonLocation.miniCenterFloat,
        backgroundColor: const Color(0xFF161A30),
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
                        color: const Color.fromARGB(255, 0, 0, 0),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            width: 9, color: const Color(0xFF31304D))),
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
                      color: const Color(0xFF31304D),
                      borderRadius: BorderRadius.circular(24)),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 300, minHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: numbers.length,
                        // padding: const EdgeInsets.all(10),
                        itemBuilder: (BuildContext context, int index) {
                          if (_isEditing && _editingIndex == index) {
                            return ListTile(
                              titleAlignment: ListTileTitleAlignment.top,
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
                                icon: Container(
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6.0),
                                    child: Image.asset(
                                      'assets/icons/check.png',
                                      color: const Color(0xFF31304D),
                                      width: 15,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  _saveChanges(index);
                                },
                              ),
                            );
                          } else {
                            return ListTile(
                              // titleAlignment: ListTileTitleAlignment.center,
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
                                width: 90,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: IconButton(
                                        icon: Container(
                                          decoration: const BoxDecoration(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10)),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(3.0),
                                            child: Image.asset(
                                              'assets/icons/edit.png',
                                              color: const Color(0xFF31304D),
                                              width: 40,
                                            ),
                                          ),
                                        ),
                                        onPressed: () {
                                          _startEditing(index);
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: IconButton(
                                          icon: Container(
                                            decoration: const BoxDecoration(
                                              color: Color.fromARGB(
                                                  255, 255, 255, 255),
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10)),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(6.0),
                                              child: Image.asset(
                                                'assets/icons/add.png',
                                                color: const Color(0xFF31304D),
                                                width: 40,
                                              ),
                                            ),
                                          ),
                                          onPressed: () {
                                            savecontact(index);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text("Contact Saved"),
                                            ));
                                          }),
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
