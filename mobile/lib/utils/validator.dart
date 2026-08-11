class Validator {
  static isNumeric(String str) {
    RegExp regex = RegExp(r'^[0-9\s]+$');
    return regex.hasMatch(str);
  }

  static isEmail(String str) {
    RegExp regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(str);
  }

  static bool isAcceptedPassword(String str) {
    return str.length >= 8;
  }
}
