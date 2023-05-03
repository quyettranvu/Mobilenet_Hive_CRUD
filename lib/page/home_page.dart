import 'package:face_recognition_flutter/utils/local_db.dart';
import 'package:flutter/material.dart';

import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController controller = TextEditingController();
  bool isUpdateMode = false;
  int? taskID;
  int selectedTaskIndex = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text("Hi ${LocalDB.getUser().name}'s Gym Task Management👋",
      style: const TextStyle(fontSize: 15),),
      actions: [
        buildLogoutButton(context),
      ],
    ),
    body: Column(
      children: [
        const SizedBox(height: 20),
        Stack(
          children: [
            const SizedBox(height: 40),
            TextField(
              onSubmitted: (value) {
                if(isUpdateMode && taskID!= null){
                  LocalDB.updateGymTask(value, taskID!);
                }else{
                  LocalDB.addGymTask(value);
                }
                isUpdateMode = false;
                controller.clear();
                setState((){});
              },
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Add your gym task',
                labelStyle: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: Colors.blueAccent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: LocalDB.readGymTasks().length,
            itemBuilder: (BuildContext context, int index) {
              Map tasks = LocalDB.readGymTasks();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.transparent,
                elevation: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.blueAccent, Colors.purpleAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    title: Text(tasks.values.elementAt(index)),
                    //control the leading widget(check icon on left side)
                    leading: isUpdateMode && index == selectedTaskIndex
                        ? GestureDetector(
                        onTap: (){
                          isUpdateMode = false;
                          setState(() {});
                        },
                        child:const Icon(Icons.check, color: Colors.green)
                    ) : null,
                    //tapping on title and start updating
                    onTap: (){
                      controller.text = tasks.values.elementAt(index);
                      isUpdateMode = true;
                      taskID = tasks.keys.elementAt(index);
                      selectedTaskIndex = index;
                      setState(() {});
                    },
                    //specify a widget that appears on the right side of the tile(for actions with tile)
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        LocalDB.deleteGymTask(tasks.keys.elementAt(index));
                        setState((){});
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );

  Widget buildLogoutButton(BuildContext context) => SizedBox(
    width: 60, // set a fixed width for the button
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(40),
      ),
      onPressed: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      ),
      icon: const Icon(Icons.logout),
      label: const SizedBox.shrink(), // hide the label
    ),
  );
}
