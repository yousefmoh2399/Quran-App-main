// ignore_for_file: file_names

class TafaseerModel {
  int? id;
  List<DataModel> data = [];

  TafaseerModel({this.id, List<DataModel>? data}) {
    if (data != null) this.data = data;
  }

  TafaseerModel.fromJson(Map<String, dynamic> json) {
    id = json["id"];
    json["data"].forEach((element) {
      data.add(DataModel.fromJson(element));
    });
  }
}

class DataModel {
  int? id, sura, aya;
  String? text;

  DataModel({this.id, this.sura, this.aya, this.text});

  DataModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    sura = json['sura'];
    aya = json['aya'];
    text = json['text'];
  }
}
