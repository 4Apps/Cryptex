class HeaderEntry {
  final int id;
  final String name;
  final String value;

  HeaderEntry(this.id, {this.name = "", this.value = ""});

  HeaderEntry.fromMap(Map<String, dynamic> data)
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
