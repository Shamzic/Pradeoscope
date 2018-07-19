import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FluxPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print("Hello");
    return Scaffold(
      appBar: AppBar(
        title: Text('Pradeoscope Firestore'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            // log out
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).pushNamed('main-page');
              FirebaseAuth.instance.signOut();
            },
          ),
          /*IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              // Ajoute un document avec un champ title vide
              Firestore.instance.runTransaction((Transaction transaction) async {
                CollectionReference reference = Firestore.instance.collection('flutter_data');
                await reference.add({"title": "", "editing": false, "like": 0, "user": ""});
              });
            },
          )*/
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
                          "userlikers": []
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

/*class MyWidget extends StatefulWidget {
  final color;
  const MyWidget({this.color});
  
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  Color myColorVar = Colors.red;
  @override
  Widget build(BuildContext context) => Container(
    child: IconButton(
      icon: Icon(Icons.update),
      onPressed: () {
        setState(() {
          if(myColorVar==Colors.red)
           myColorVar = Colors.blue;
          else
            myColorVar = Colors.red;
        });
      },
      color: myColorVar,
      ),
  );
}*/

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
        FirebaseUser currentUser = await FirebaseAuth.instance.currentUser();
        return FirestoreListView(documents: snapshot.data.documents);
      });
    },
  );
}

class FirestoreListView extends StatelessWidget {
  // liste des documents de la firebase
  final List<DocumentSnapshot> documents;
  bool _liked = false;
  String stringName = "Toto";

  /*        FirebaseUser currentUser;
        Firestore.instance.runTransaction((Transaction transaction) async {
          currentUser = await FirebaseAuth.instance.currentUser();
        });
        String stringName = currentUser.displayName+"has written :";*/

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
      itemExtent: 70.0,
      itemBuilder: (BuildContext context, int index) {
        String title = documents[index].data['title'].toString();
        int like = documents[index].data['like'];
        String temp = documents[index].data['userName'];
        stringName = "$temp has written :";
        return ListTile(
          title: Container(
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
                        stringName,
                        style: TextStyle(
                          fontSize: 11.0,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      !documents[index].data['editing']
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
                      if (snapshot.data['user'] == currentUser.uid) {
                        print('suppression par user ok');
                        await transaction.delete(snapshot.reference);
                      } else {
                        print('snapshot.data\[\'user\'\]');
                        print(snapshot.data['user']);
                        print('FirebaseAuth.instance.currentUser().hashCode.toString()');
                        print(FirebaseAuth.instance.currentUser().hashCode.toString());
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
