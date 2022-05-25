class Settings {
  final int id;
  final String name;
  final String value;

  Settings(this.id, {this.name = "", this.value = ""});

  Settings.fromMap(Map<String, dynamic> data)
      : id = data['id'],
        name = data['name'],
        value = data['value'];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'value': value,
      };

  @override
  String toString() {
    return "${this.name}: ${this.value}";
  }
}
