import 'package:flutter/material.dart';
import 'widgets/add_content.dart';
import 'add_menu_screen.dart';
import 'add_food_screen.dart';

class AddScreen extends StatelessWidget {
  const AddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 100),
              AddContent(
                title: 'Adicione um menu',
                icon: Icons.menu_book,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddMenuScreen()
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              AddContent(
                title: 'Adicione uma comida',
                icon: Icons.rice_bowl,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddFoodScreen()),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
