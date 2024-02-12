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
          Uri.parse("https://3897-103-89-235-250.ngrok-free.app/upload"));

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // resizeToAvoidBottomInset: true,
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              // crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 3),
                                        width: 170,
                                        child: TextFormField(
                                          initialValue: name[index],
                                          onChanged: (text) =>
                                              {name[index] = _controller.text},
                                          // controller: _controller,
                                          style: const TextStyle(
                                            color: Color(0xFF9174DB),
                                            fontSize: 18,
                                          ),
                                        )
                                        // Text(
                                        //   name[index] + " :",
                                        //   style: const TextStyle(
                                        //     fontSize: 18,
                                        //     color: Color(0xFF9174DB),
                                        //   ),
                                        // ),
                                        ),
                                    Text(
                                      numbers[index],
                                      style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              const Color(0xFFF0ECE5)),
                                      shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                        ),
                                      ),
                                    ),
                                    onPressed: (() => savecontact(index)),
                                    child: const Text("Save"),
                                  ),
                                ),
                              ],
                            ),
                          );
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

  void getContactPermission() async {
    if (await Permission.contacts.isGranted) {
    } else {
      await Permission.contacts.request();
    }
  }

  savecontact(int index) async {
    Contact contact = Contact();
    print("--${_controller.text}");
    contact.givenName = name[index];
    contact.phones = [Item(label: "mobile", value: numbers[index])];
    ContactsService.addContact(contact);
  }
}
