import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }

}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Best Name Voting')),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('names')
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData){
          return LinearProgressIndicator();
        }else{
          final List<_NameRecord> records = snapshot.data.docs
            .map((snapshot) => _NameRecord.fromSnapshot(snapshot))
            .toList();

          return ListView(
            children: records
                .map((record) => _buildListItem(context, record))
                .toList(),
          );
          //return _buildList(context, records);
        }
      });
  }
/*
  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }
*/
  Widget _buildListItem(BuildContext context, _NameRecord record) {
    //final record = _NameRecord.fromSnapshot(data);

    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.pinkAccent),
          borderRadius: BorderRadius.circular(7.0),
        ),
        child: ListTile(
          title: Text(record.name),
          trailing: Text(record.votes.toString()),
          //onTap: () => print(record),
            onTap: () => _toggleVoted(record),
            //record..updateData({'votes': record.votes + 1})
        ),
      ),
    );
  }
}

  Future <void> _toggleVoted(_NameRecord record) async{
    try{
      //check internet connection
      final result = await InternetAddress.lookup('firestore.googleapis.com');
      if(result.isEmpty || result[0].rawAddress.isEmpty){
        throw 'Cannot access "firestore.googleapis.com" !';
      }else{
        await FirebaseFirestore.instance.runTransaction(
            (transaction) async{
                transaction.update(record.firestoreDocRef,
                    {'votes': record.votes + 1});
            }
        );
      }

    } catch (error){
       print('Error doing Firebase transaction: $error');
    }
  }

class _NameRecord {

  final String name;
  final int votes;
  final DocumentReference firestoreDocRef;

  _NameRecord.fromMap(Map<String, dynamic> map,
        {@required this.firestoreDocRef})
      : assert(map['name'] != null && map['name'] is String),
        assert(map['votes'] != null && map['votes'] is int),
        name = map['name'] as String,
        votes = map['votes'] as int;

  _NameRecord.fromSnapshot(QueryDocumentSnapshot snapshot)
      : this.fromMap(snapshot.data.call(), firestoreDocRef: snapshot.reference);

  @override
  String toString() => "Record<$name:$votes>";
}