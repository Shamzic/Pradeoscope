import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class MyImagePicker extends StatefulWidget {
  @override
  _MyImagePickerState createState() => new _MyImagePickerState();
}

class _MyImagePickerState extends State<MyImagePicker> {
  File _image;
  String _path;
  
  Future getImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    
    setState(() {
      _image = image;
      print('PATH : ');
      print(_image.path);
      uploadFile();
    });
  }
  
  Future<Null> uploadFile() async {
    print('FILE UPLOADING');
    final ByteData bytes = await rootBundle.load(_image.path);
    final Directory tempDir = Directory.systemTemp;
    final String fileName = "${Random().nextInt(10000)}.jpg";
    final File file = File('${tempDir.path}/$fileName');
    file.writeAsBytes(bytes.buffer.asUint8List(), mode: FileMode.write);
    final StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
    final StorageUploadTask task = ref.putFile(file);
    final Uri downloadUrl = (await task.future).downloadUrl;
    _path = downloadUrl.toString();
    print(_path);
    print('File Uploaded !');
    postImage();
  }
  
  
  Future<Null> downloadFile(String httpPath) async {
    final RegExp regExp = RegExp('([^?/]*\.(jpg))');
    final String fileName = regExp.stringMatch(httpPath);
    final Directory tempDir = Directory.systemTemp;
    final File file = File('${tempDir.path}/$fileName');
    
    final StorageReference ref = FirebaseStorage.instance.ref().child(fileName);
    final StorageFileDownloadTask downloadTask = ref.writeToFile(file);
    
    final int byteNumber = (await downloadTask.future).totalByteCount;
    print(byteNumber);
    //setState(() => _cachedFile = file);
  }
  
  void postImage() {
    Firestore.instance.runTransaction((transaction) async {
      FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
      CollectionReference reference = Firestore.instance.collection('flutter_data');
      await reference.add({
        "title": null,
        "editing": true,
        "like": 0,
        "userID": currentUser.uid,
        "userName": currentUser.displayName,
        "userlikers": [],
        "type": "image",
        "url": _path
      });
    });
  }
  
  
  @override
  Widget build(BuildContext context) {
    return new FloatingActionButton(
      onPressed: getImage,
      tooltip: 'Pick Image',
      child: new Icon(Icons.add_a_photo),
    );
  }
}


class FluxPage extends StatelessWidget {
  
  
  @override
  Widget build(BuildContext context) {
    print("Hello");
    return Scaffold(
      appBar: AppBar(
        title: Text('Pradeoscope Firestore'),
        centerTitle: true,
        actions: <Widget>[
          MyImagePicker(),
        ],
      ),
      
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: <Widget>[
                TextFormField(
                  maxLength: 21,
                  onSaved: (String item) {
                    item = "";
                  },
                  decoration: InputDecoration(labelText: 'Write your post'),
                  onFieldSubmitted: (String item) {
                    Firestore.instance.runTransaction((transaction) async {
                      FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
                      CollectionReference reference = Firestore.instance.collection('flutter_data');
                      await reference.add({
                        "title": item,
                        "editing": true,
                        "like": 0,
                        "userID": currentUser.uid,
                        "userName": currentUser.displayName,
                        "userlikers": [],
                        "type": "text",
                        "url": null
                      });
                    });
                  }),
              ],
            ),
          ),
          StreamBuilder(
            stream: Firestore.instance.collection('flutter_data').snapshots(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) return CircularProgressIndicator();
              return FirestoreListView(documents: snapshot.data.documents);
            },
          ),
        ],
      ),
      
      // Avatar Google at the bottom of the page
      floatingActionButton: StreamBuilder(
        stream: FirebaseAuth.instance.currentUser().asStream(),
        builder: (BuildContext context, AsyncSnapshot<FirebaseUser> snapshot) {
          return FloatingActionButton(
            elevation: 10.0,
            onPressed: () {},
            child: CircleAvatar(
              backgroundImage: NetworkImage(snapshot.data.photoUrl),
              radius: 30.0,
            ),
          );
        }),
      
      // Pour ameliorer l'esthetique en bas de l'app
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      bottomNavigationBar: BottomAppBar(
        child: Container(
          height: 80.0,
        ),
      ),
    );
  }
}

class MyWidget2 extends StatefulWidget {
  List<DocumentSnapshot> documents;
  var index;
  BuildContext context;
  
  MyWidget2(List<DocumentSnapshot> documents, var index, BuildContext context) {
    this.documents = documents;
    this.index = index;
    this.context = context;
  }
  
  @override
  _MyWidgetState2 createState() => _MyWidgetState2();
}

class _MyWidgetState2 extends State<MyWidget2> {
  bool _liked = true;
  
  void setLiked(bool b) {
    this._liked = b;
  }
  
  bool getLiked() {
    return this._liked;
  }
  
  @override
  Widget build(BuildContext context) => Container(
    child: IconButton(
      icon: Icon(
        Icons.favorite_border,
        color: getLiked() ? Colors.black26 : Colors.red,
      ),
      splashColor: Colors.red.withOpacity(0.8),
      onPressed: () {
        setLiked(false);
        Firestore.instance.runTransaction((Transaction transaction) async {
          FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
          DocumentSnapshot snapshot =
          await transaction.get(widget.documents[widget.index].reference);
          String valueDoc = snapshot.documentID.toString();
          print(valueDoc);
          
          var arrayList = [];
          arrayList = widget.documents[widget.index].data['userlikers'];
          print(arrayList);
          List l = [];
          int pos = -1;
          for (int i = 0; i < arrayList.length; i++) {
            if (arrayList[i] == currentUser.uid.toString()) {
              setLiked(true);
              pos = i;
            }
            l.add(arrayList[i]);
          }
          if (!getLiked()) {
            print('New like from the current user!');
            await transaction.update(snapshot.reference, {'like': snapshot['like'] + 1});
            l.add(currentUser.uid.toString());
          }
          if (getLiked()) {
            print('This user has already liked this post !');
            await transaction.update(snapshot.reference, {'like': snapshot['like'] - 1});
            l.removeAt(pos);
          }
          print(arrayList);
          await transaction.update(snapshot.reference, {'userlikers': l});
          print(getLiked());
          print(currentUser.displayName);
        });
      },
    ),
  );
}

Widget streamBuilder() {
  return new StreamBuilder(
    stream: Firestore.instance.collection('flutter_data').snapshots(),
    builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (!snapshot.hasData) return CircularProgressIndicator();
      Firestore.instance.runTransaction((Transaction transaction) async {
        //FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
        return FirestoreListView(documents: snapshot.data.documents);
      });
    },
  );
}

class FirestoreListView extends StatelessWidget {
  // liste des documents de la firebase
  final List<DocumentSnapshot> documents;
  bool _liked = false;
  String stringName1 = "";
  String stringName2 = "";
  
  void setLiked(bool b) {
    this._liked = b;
  }
  
  bool getLiked() {
    return this._liked;
  }
  
  FirestoreListView({this.documents}); // constructeur
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: documents.length,
        shrinkWrap: false,
        itemExtent: 110.0,
        itemBuilder: (BuildContext context, int index) {
          String title = documents[index].data['title'].toString();
          int like = documents[index].data['like'];
          String temp = documents[index].data['userName'];
          stringName1 = "$temp has written :";
          stringName2 = "$temp has send an image :";
          return ListTile(
            
            title: Container(
              height: 150.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: Colors.black26),
              ),
              padding: EdgeInsets.all(5.0),
              margin: EdgeInsets.all(8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (documents[index].data['type'] == 'image') ?
                          stringName2 : stringName1,
                          style: TextStyle(
                            fontSize: 11.0,
                            color: Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        (documents[index].data['type'] == 'image')
                          ? Container(
                          height: 60.0,
                          child: Image.network(documents[index].data['url']),
                        )
                          : !documents[index].data['editing']
                          ? Text(title)
                          : Expanded(
                          child: TextFormField(
                            initialValue: title,
                            maxLength: 21,
                            onFieldSubmitted: (String item) {
                              Firestore.instance.runTransaction((transaction) async {
                                DocumentSnapshot snapshot =
                                await transaction.get(documents[index].reference);
                                await transaction.update(snapshot.reference, {'title': item});
                                await transaction
                                  .update(snapshot.reference, {"editing": !snapshot['editing']});
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Text("$like"),
                  MyWidget2(documents, index, context), // Heart icon
                  IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      Firestore.instance.runTransaction((Transaction transaction) async {
                        DocumentSnapshot snapshot = await transaction.get(documents[index].reference);
                        FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
                        if (snapshot.data['userID'] == currentUser.uid) {
                          print('suppression par user ok');
                          await transaction.delete(snapshot.reference);
                        } else {
                          print('snapshot.data\[\'userID\'\]');
                          print(snapshot.data['userID']);
                        }
                      });
                    },
                    color: Colors.black26,
                  )
                ],
              ),
            ),
            onTap: () => Firestore.instance.runTransaction((Transaction transaction) async {
              DocumentSnapshot snapshot = await transaction.get(documents[index].reference);
              await transaction.update(snapshot.reference, {"editing": !snapshot["editing"]});
            }),
          );
        },
      ));
  }
}
