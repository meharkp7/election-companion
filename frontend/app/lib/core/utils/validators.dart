abstract class AppValidators {
  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null || age < 18) return 'Must be 18 or older';
    return null;
  }

  static String? validateState(String? value) {
    if (value == null || value.isEmpty) return 'State is required';
    return null;
  }

  static bool isEligibleToVote(int age) {
    return age >= 18;
  }
}
