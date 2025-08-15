// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/team_model.dart';
//
// class CreateTeamScreen extends StatefulWidget {
//   @override
//   _CreateTeamScreenState createState() => _CreateTeamScreenState();
// }
//
// class _CreateTeamScreenState extends State<CreateTeamScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final List<TextEditingController> _playerControllers = List.generate(11, (_) => TextEditingController());
//
//   Future<void> _submitTeam() async {
//     if (_formKey.currentState!.validate()) {
//       final players = _playerControllers.map((e) => e.text.trim()).where((name) => name.isNotEmpty).toList();
//
//       final newTeam = TeamModel(
//         id: '',
//         name: _nameController.text.trim(),
//         playerNames: players,
//       );
//
//       final docRef = FirebaseFirestore.instance.collection('teams').doc();
//       await docRef.set(newTeam.toJson()..['id'] = docRef.id);
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Team created successfully')),
//       );
//       Navigator.pop(context);
//     }
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _playerControllers.forEach((controller) => controller.dispose());
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Create Team')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(labelText: 'Team Name'),
//                 validator: (value) => value == null || value.isEmpty ? 'Required' : null,
//               ),
//               SizedBox(height: 16),
//               Text('Players:', style: TextStyle(fontWeight: FontWeight.bold)),
//               ...List.generate(11, (index) {
//                 return TextFormField(
//                   controller: _playerControllers[index],
//                   decoration: InputDecoration(labelText: 'Player ${index + 1}'),
//                 );
//               }),
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _submitTeam,
//                 child: Text('Create Team'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
