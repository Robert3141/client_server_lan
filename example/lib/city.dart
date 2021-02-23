import 'dart:convert';

class City {
  String name;
  String province;
  String country;
  City({
    this.name,
    this.province,
    this.country,
  });

  City copyWith({
    String name,
    String province,
    String country,
  }) {
    return City(
      name: name ?? this.name,
      province: province ?? this.province,
      country: country ?? this.country,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'province': province,
      'country': country,
    };
  }

  factory City.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return City(
      name: map['name'],
      province: map['province'],
      country: map['country'],
    );
  }

  String toJson() => json.encode(toMap());

  factory City.fromJson(String source) => City.fromMap(json.decode(source));

  @override
  String toString() =>
      'City(name: $name, province: $province, country: $country)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is City &&
        o.name == name &&
        o.province == province &&
        o.country == country;
  }

  @override
  int get hashCode => name.hashCode ^ province.hashCode ^ country.hashCode;
}
