import 'package:material_ui/material_ui.dart';
import 'package:forui/forui.dart' show FButton;

class AboutScreen extends StatelessWidget {
   const AboutScreen({super.key});
 
   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: Container(
         width: 1280,
         height: 720,
         alignment: Alignment.center,
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             const Text(
               'Addons Maker',
               style: TextStyle(fontSize: 48),
             ),
             const SizedBox(height: 16),
             const Text(
               'Version 1.0.0',
               style: TextStyle(fontSize: 24),
             ),
             const SizedBox(height: 16),
             const Text(
               'Developed by Your Name',
               style: TextStyle(fontSize: 24),
             ),
           ],
         ),
       ),
     );
   }
 }