import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament_model.dart';

class CreateTournamentScreen extends StatefulWidget {
  @override
  _CreateTournamentScreenState createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _submitTournament() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      final newTournament = TournamentModel(
        id: '', // Firestore will generate ID
        name: _nameController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _selectedDate!,
        matchIds: [],
      );

      final docRef = FirebaseFirestore.instance.collection('tournaments').doc();
      await docRef.set(newTournament.toJson()..['id'] = docRef.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tournament created successfully')),
      );
      Navigator.pop(context);
    }
  }

  void _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Tournament')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Tournament Name'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(labelText: 'Location'),
                validator: (value) =>
                value == null || value.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(_selectedDate == null
                      ? 'Pick Start Date'
                      : 'Start Date: ${_selectedDate!.toLocal()}'.split(' ')[0]),
                  Spacer(),
                  ElevatedButton(
                    onPressed: _pickDate,
                    child: Text('Select Date'),
                  ),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitTournament,
                child: Text('Create Tournament'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
