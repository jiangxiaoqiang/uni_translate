import 'translate_request.dart';

class LookUpRequest extends TranslateRequest {
  final String? word;

  LookUpRequest({
    String? sourceLanguage,
    String? targetLanguage,
    this.word,
  }) : super(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );

  factory LookUpRequest.fromJson(Map<String, dynamic> json) {
    return LookUpRequest(
      sourceLanguage: json['sourceLanguage'],
      targetLanguage: json['targetLanguage'],
      word: json['word'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sourceLanguage': sourceLanguage,
      'targetLanguage': targetLanguage,
      'word': word,
    };
  }
}
