import 'models/text_translation.dart';

class TranslateResponse {
  List<TextTranslation> translations;

  TranslateResponse({
    required this.translations,
  });

  factory TranslateResponse.fromJson(Map<String, dynamic> json) {
    List<TextTranslation> translations = List.empty(growable: true);

    if (json['translations'] != null) {
      Iterable l = json['translations'] as List;
      translations = l.map((item) => TextTranslation.fromJson(item)).toList();
    }

    return TranslateResponse(
      translations: translations,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'translations': translations?.map((e) => e.toJson())?.toList(),
    }..removeWhere((key, value) => value == null);
  }
}
