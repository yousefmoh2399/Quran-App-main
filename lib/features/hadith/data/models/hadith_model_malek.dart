class HadithModelFinal {
  int? id;
  HadithModelData? data;

  HadithModelFinal({this.id, this.data});

  HadithModelFinal.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    data = json["data"] != null ? HadithModelData.fromJson(json["data"]) : null;
  }
}

class HadithModelData {
  MetaDataModel? metadata;
  List<HadithsModel> hadiths = [];

  HadithModelData({this.metadata, List<HadithsModel>? hadiths}) {
    if (hadiths != null) this.hadiths = hadiths;
  }

  HadithModelData.fromJson(Map<String, dynamic> json) {
    metadata = json["metadata"] != null
        ? MetaDataModel.fromJson(json['metadata'])
        : null;
    json['hadiths'].forEach((element) {
      hadiths.add(HadithsModel.fromJson(element));
    });
  }
}

class MetaDataModel {
  String? name;
  SectionModel? section;

  MetaDataModel({this.name, this.section});

  MetaDataModel.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    section =
        json["section"] != null ? SectionModel.fromJson(json["section"]) : null;
  }
}

class SectionModel {
  String? name;

  SectionModel({this.name});

  SectionModel.fromJson(Map<String, dynamic> json) {
    name = json["name"];
  }
}

class HadithsModel {
  int? hadithnumber, arabicnumber;
  String? text;

  HadithsModel({this.hadithnumber, this.arabicnumber, this.text});

  HadithsModel.fromJson(Map<String, dynamic> json) {
    hadithnumber = json["hadithnumber"];
    arabicnumber = json["arabicnumber"];
    text = json["text"];
  }
}
