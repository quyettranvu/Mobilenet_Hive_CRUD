class User {
  static const String nameKey = "user_name";
  static const String arrayKey = "user_array";

  String? name;
  List? array;

  User({this.name, this.array});

  //Methods for defining Custom Objects
  //type of keys should be dynamic when parsing JSON data
  factory User.fromJson(Map<dynamic, dynamic> json) =>
      User(
        name: json[nameKey],
        array: json[arrayKey],
      );

  Map<String, dynamic> toJson() {
    return {
      nameKey: name,
      arrayKey: array,
    };
  }
}