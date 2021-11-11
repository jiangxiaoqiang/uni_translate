library translation_engine_reddwarf;

import 'dart:convert';
import 'dart:ffi';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:uni_translate_client/uni_translate_client.dart';
import 'package:wheel/wheel.dart';

const String kEngineTypeReddwarf = 'reddwarf';

const String _kEngineOptionKeyAppKey = 'appKey';
const String _kEngineOptionKeyAppSecret = 'appSecret';

String _md5(String data) {
  return md5.convert(utf8.encode(data)).toString();
}

String _sha256(String data) {
  return sha256.convert(utf8.encode(data)).toString();
}

class ReddwarfTranslationEngine extends TranslationEngine {
  static List<String> optionKeys = [
    _kEngineOptionKeyAppKey,
    _kEngineOptionKeyAppSecret,
  ];

  ReddwarfTranslationEngine(TranslationEngineConfig config) : super(config);

  String get type => kEngineTypeReddwarf;
  List<String> get supportedScopes => [kScopeLookUp];

  String get _optionAppKey => option[_kEngineOptionKeyAppKey];
  String get _optionAppSecret => option[_kEngineOptionKeyAppSecret];

  @override
  Future<DetectLanguageResponse> detectLanguage(DetectLanguageRequest request) {
    // TODO: implement detectLanguage
    throw UnimplementedError();
  }

  bool isNullable<T>() => null is T;

  @override
  Future<LookUpResponse> lookUp(LookUpRequest request) async {
    LookUpResponse lookUpResponse = LookUpResponse();
    Map<String,String> req = {
      'word': request.word,
      'from': request.sourceLanguage,
      'to': request.targetLanguage
    };
    var response = await RestClient.postHttp("/dict/word/translate/v1", req);
    if(!RestClient.respSuccess(response) || response.data["result"] == null || response.data["result"].toString().isEmpty){
        return lookUpResponse;
    }
    var data = response.data["result"];
    var query = data['query'];
    var translation = data['translations'];
    var basic = data['basic'];
    var returnPhrase = data['returnPhrase'];
    var tSpeakUrl = data['tSpeakUrl'];
    var wordSentence = data["sentences"];
    var definitions = data["definitions"];

    if (wordSentence != null) {
      List sentences = wordSentence as List;
      if(sentences.length > 0) {
        List<WordSentence> sens = new List.empty(growable: true);
        sentences.forEach((element) {
          List ts = element["translations"];
          List<String> weightData = ts.map((entry) => entry.toString())
              .toList();
          var ws = WordSentence(
            text: element['text'],
            translations: weightData,
          );
          sens.add(ws);
        });
        lookUpResponse.sentences = sens;
      }
    }

    if (definitions != null) {
      List definitionList = definitions as List;
      if(definitionList.length > 0) {
        List<WordDefinition> sens = new List.empty(growable: true);
        definitionList.forEach((element) {
          List ts = element["values"];
          List<String> weightData = ts.map((entry) => entry.toString())
              .toList();
          var ws = WordDefinition(
            type: element['type'],
            name: element["name"],
            values: weightData
          );
          sens.add(ws);
        });
        lookUpResponse.definitions = sens;
      }
    }

    if (translation != null) {
      lookUpResponse.translations =
          (translation as List).map((e) => TextTranslation(text: e["text"])).toList();
      if (lookUpResponse.translations.length == 1) {
        lookUpResponse.translations[0].audioUrl = tSpeakUrl;
      }
    }

    if (returnPhrase != null) {
      lookUpResponse.word = returnPhrase[0];
    }

    if (basic != null) {
      var examType = basic['exam_type'];
      var explains = basic['explains'];
      var wfs = basic['wfs'];

      if (examType != null) {
        lookUpResponse.tags = (examType as List).map((e) {
          return WordTag(name: e);
        }).toList();
      }
      if (explains != null) {
        lookUpResponse.definitions = (explains as List).map((e) {
          String def = e.toString();
          int dotIndex = def.indexOf('. ');
          String name = dotIndex >= 0 ? def.substring(0, dotIndex + 1) : null;
          String value = dotIndex >= 0 ? def.substring(dotIndex + 2) : def;
          List<String> values = value.split('；');

          return WordDefinition(
            name: name,
            values: values,
          );
        }).toList();
      }

      lookUpResponse.pronunciations = [
        WordPronunciation(
            type: 'uk',
            phoneticSymbol: basic['uk-phonetic'],
            audioUrl: basic['uk-speech']),
        WordPronunciation(
            type: 'us',
            phoneticSymbol: basic['us-phonetic'],
            audioUrl: basic['us-speech']),
      ]
          .where((e) =>
              (e.phoneticSymbol ?? '').isNotEmpty ||
              (e.audioUrl ?? '').isNotEmpty)
          .toList();

      if (wfs != null) {
        lookUpResponse.tenses = (wfs as List).map((e) {
          var wf = e['wf'];
          String name = wf['name'];
          String value = wf['value'];

          List<String> values = [value];
          if (value.indexOf('或') >= 0) {
            values = value.split('或');
          }

          return WordTense(
            name: name,
            values: values,
          );
        }).toList();
      }
    }

    if ((lookUpResponse.definitions ?? []).isNotEmpty ||
        (lookUpResponse.pronunciations ?? []).isNotEmpty) {
      Uri uri2 = Uri.https(
        'picdict.youdao.com',
        '/search',
        {
          'q': request.word,
          'le': request.sourceLanguage,
        },
      );

      try {
        var response2 = await http.get(uri2);
        Map<String, dynamic> data2 = json.decode(response2.body);

        if (data2['data']['pic'] != null) {
          lookUpResponse.images = (data2['data']['pic'] as List)
              .map((e) => WordImage(url: e['url']))
              .toList();
        }
      } catch (error) {
        // skip
      }
    }

    return lookUpResponse;
  }

  @override
  Future<TranslateResponse> translate(TranslateRequest request) {
    throw UnimplementedError();
  }
}
