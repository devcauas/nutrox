import 'package:flutter/material.dart';
import 'add_screen.dart';
import 'profile_screen.dart';
import 'widgets/home_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> get _screens => [
    const HomeContent(),
    const AddScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        height: 110,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                49,
                49,
                49,
              ).withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, -2),
              spreadRadius: 1,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.shifting,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Início',
              backgroundColor: Color.fromARGB(255, 7, 109, 24),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_to_photos),
              label: 'Adicionar',
              backgroundColor: Color.fromARGB(255, 62, 143, 64),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
              backgroundColor: Color.fromARGB(255, 3, 155, 109),
            ),
          ],
        ),
      ),
    );
  }
}
