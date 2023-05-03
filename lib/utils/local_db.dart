import "package:hive_flutter/hive_flutter.dart";
import "../models/user.dart";

//Using Hive for storing datas
class HiveBoxes {
  static const userDetails = "user_details";
  static const gymTasks = "gym_tasks";

  //INITIALIZE BOX
  static Box userDetailsBox()=>Hive.box(userDetails);
  static Box gymTasksBox()=>Hive.box(gymTasks);

  //create Boxes
  static initialize() async{
    await Hive.openBox(userDetails);
    await Hive.openBox(gymTasks);
  }

  //CLEAR DATAS IN BOX
  static clearAllBox() async{
    await HiveBoxes.userDetailsBox().clear();
  }
}


//methods working with our db
class LocalDB{
  //GET DATA FROM USER
  static User getUser() => User.fromJson(HiveBoxes.userDetailsBox().toMap());

  //return a map object with key-value pairs
  static String getUserName() =>
      HiveBoxes.userDetailsBox().toMap()[User.nameKey];

  static String getUserArray() =>
      HiveBoxes.userDetailsBox().toMap()[User.arrayKey];

  //SET DATA TO BOX
  //takes a User object, converts it to a Map(toJson), and then inserts all the key-value pairs of the resulting Map into the userDetailsBox(putAll).
  static setUserDetails(User user) =>
      HiveBoxes.userDetailsBox().putAll(user.toJson());

  //CRUD Operations for working with tasks
  static addGymTask(String task) {
    HiveBoxes.gymTasksBox().add(task);
  }

  static Map readGymTasks() {
    return HiveBoxes.gymTasksBox().toMap();
  }

  static updateGymTask(String updatedGymTask,int taskID) {
    HiveBoxes.gymTasksBox().put(taskID, updatedGymTask);
  }

  static deleteGymTask(int taskID) {
    HiveBoxes.gymTasksBox().delete(taskID);
  }
}
