class WordImage {
  String? url;

  WordImage({
    this.url,
  });

  factory WordImage.fromJson(Map<String, dynamic> json) {

    return WordImage(
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
    }..removeWhere((key, value) => value == null);
  }
}
