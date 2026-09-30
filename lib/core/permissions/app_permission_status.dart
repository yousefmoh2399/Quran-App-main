enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  notApplicable;

  bool get isGranted => this == AppPermissionStatus.granted;
  bool get isDenied => this == AppPermissionStatus.denied;
  bool get isPermanentlyDenied => this == AppPermissionStatus.permanentlyDenied;
  bool get isRestricted => this == AppPermissionStatus.restricted;
  bool get isNotApplicable => this == AppPermissionStatus.notApplicable;
}
