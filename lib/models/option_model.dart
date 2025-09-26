class OptionModel {
  final String value;
  final String text;

  OptionModel({required this.value, required this.text});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      value: json['value'] ?? '',
      text: json['text'] ?? '',
    );
  }
}