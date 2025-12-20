class Todo{
  String title;
  String description;
  bool isDone;
  String details;

  //Constructor Call for the Todo Class
  Todo(
   {
   required this.title,
   required this.description,
   this.isDone=false,
   required this.details
   });
  //Method to convert Json to Todo Object
  Map<String,dynamic>toJson(){
    return {
      'title':title,
      'description':description,
      'isDone':isDone,
      'details':details
    };
  }
  //Method to update existing Todo Object
  Todo copyWith({
    String?title,
    String?description,
    bool?isDone,
  }){
    return Todo(
      title: title??this.title,
      description: description??this.description,
      isDone:isDone??this.isDone,
      details:details
    );
  }

  // Factory method to create a Todo object from a JSON map
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      description: json['description'],
      isDone: json['isDone'],
      details: json['details'],
    );
  }


}