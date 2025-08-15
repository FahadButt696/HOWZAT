import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/match_model.dart';
import '../../routes/app_routes.dart';
import '../history/history_screen.dart';
import '../match/player_select_screen.dart'; // Keep this import for the Start Match navigation

// Import the new screens
import '../settings/settings_screen.dart';
import '../teams/teams_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController hostTeamController = TextEditingController(text: 'Team A');
  final TextEditingController visitorTeamController = TextEditingController(text: 'Team B');
  final TextEditingController _oversController = TextEditingController();

  String tossWonBy = 'Host team';
  String optedTo = 'Bat';
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  int _currentIndex = 0; // Tracks the current selected tab index
  late PageController _pageController; // Controls the PageView for smooth transitions

  @override
  void initState() {
    super.initState();
    // Initialize PageController with the current index
    _pageController = PageController(initialPage: _currentIndex);

    hostTeamController.addListener(() {
      setState(() {
        // Update tossWonBy if it matches the old team name or is empty
        if (tossWonBy == '' || tossWonBy == 'Host team') {
          tossWonBy = hostTeamController.text;
        }
      });
    });
    visitorTeamController.addListener(() {
      setState(() {
        // Update tossWonBy if it matches the old team name or is empty
        if (tossWonBy == '' || tossWonBy == 'Visitor team') {
          tossWonBy = visitorTeamController.text;
        }
      });
    });
  }

  @override
  void dispose() {
    hostTeamController.dispose();
    visitorTeamController.dispose();
    _oversController.dispose();
    _pageController.dispose(); // Dispose of the PageController
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        // Use PageView as the body for smooth transitions
        child: PageView(
          controller: _pageController,
          // Update the current index when the page changes (e.g., swiping)
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            // --- New Match Screen Content ---
            _buildNewMatchScreenContent(),

            // --- Teams Screen ---
            const TeamsScreen(), // Your new Teams Screen

            // --- History Screen ---
            const HistoryScreen(), // Your new History Screen

            // --- Settings Screen ---
            const SettingsScreen(), // Your new Settings Screen
          ],
        ),
      ),

      /// Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B6623), Color(0xFF1E3C72)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex, // Use the state variable
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.white60,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.sports_cricket), label: "New match"),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Teams"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
          ],
          onTap: (index) {
            // Animate PageView to the selected index with a smooth transition
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn, // Smooth animation curve
            );
          },
        ),
      ),
    );
  }

  // Extracted original Home Screen content into a new method
  Widget _buildNewMatchScreenContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "HOWZAT!",
                style: GoogleFonts.balooBhai2(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              /// VS Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.black12, Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _teamInputBox("Select team1", hostTeamController, 'assets/icons/team.png'),
                        Image.asset("assets/icons/Vss.png", height: 100, width: 100),
                        _teamInputBox("Select team2", visitorTeamController, 'assets/icons/team.png'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _selectDate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                            DateFormat('dd MMMMyyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _selectTime,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlueAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text(
                            selectedTime.format(context),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// Toss Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Toss won by?", style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              _gradientBox(
                child: Row(
                  children: [
                    _radioTile(hostTeamController.text, tossWonBy, (val) => setState(() => tossWonBy = val!)),
                    const SizedBox(width: 10),
                    _radioTile(visitorTeamController.text, tossWonBy, (val) => setState(() => tossWonBy = val!)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Opted To Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text("Opted to?", style: GoogleFonts.balooBhai2(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 8),
              _gradientBox(
                child: Row(
                  children: [
                    _radioTile("Bat", optedTo, (val) => setState(() => optedTo = val!)),
                    const SizedBox(width: 10),
                    _radioTile("Bowl", optedTo, (val) => setState(() => optedTo = val!)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// Overs Input
              _gradientBox(
                child: TextField(
                  controller: _oversController,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Overs",
                    labelStyle: GoogleFonts.balooBhai2(color: Colors.white70),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Start Match Button
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF64DD17)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    final teamA = hostTeamController.text.trim();
                    final teamB = visitorTeamController.text.trim();
                    final overs = int.tryParse(_oversController.text.trim());

                    if (teamA.isEmpty || teamB.isEmpty || overs == null || overs <= 0 || tossWonBy.isEmpty || optedTo.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all the required fields')),
                      );
                      return;
                    }

                    final Map<String, dynamic> matchData = {
                      'teamA': teamA,
                      'teamB': teamB,
                      'overs': overs,
                      'date': selectedDate.toIso8601String(),
                      'time': selectedTime.format(context),
                      'tossWonBy': tossWonBy,
                      'optedTo': optedTo,
                    };

                    Navigator.pushNamed(
                      context,
                      AppRoutes.playerSelect,
                      arguments: matchData,
                    );

                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Start match",
                    style: GoogleFonts.balooBhai2(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Team Input Field with Static Avatar
  Widget _teamInputBox(String label, TextEditingController controller, String imagePath) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 10),
        CircleAvatar(
          backgroundColor: Colors.white,
          radius: 30,
          backgroundImage: AssetImage(imagePath),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 80,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Enter name",
              hintStyle: const TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _radioTile(String label, String groupValue, ValueChanged<String> onChanged) {
    return Expanded(
      child: Row(
        children: [
          Radio<String>(
            value: label,
            groupValue: groupValue,
            onChanged: (val) => onChanged(val!),
            activeColor: Colors.lightGreenAccent.shade700,
          ),
          Flexible(child: Text(label, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _gradientBox({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.black12, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
