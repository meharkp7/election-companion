import 'package:flutter/material.dart';

enum ValidationType {
  required,
  email,
  phone,
  password,
  age,
  name,
  address,
  pincode,
  aadhaar,
  voterId,
}

class ValidationRule {
  final ValidationType type;
  final String? errorMessage;
  final dynamic customValidator;

  const ValidationRule({
    required this.type,
    this.errorMessage,
    this.customValidator,
  });
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ValidationResult.success() {
    return const ValidationResult(isValid: true);
  }

  factory ValidationResult.error(String message) {
    return ValidationResult(isValid: false, errorMessage: message);
  }
}

class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  ValidationResult validateField(String value, List<ValidationRule> rules) {
    for (final rule in rules) {
      final result = _validateRule(value, rule);
      if (!result.isValid) {
        return result;
      }
    }
    return ValidationResult.success();
  }

  ValidationResult _validateRule(String value, ValidationRule rule) {
    switch (rule.type) {
      case ValidationType.required:
        if (value.trim().isEmpty) {
          return ValidationResult.error(
            rule.errorMessage ?? 'This field is required',
          );
        }
        break;

      case ValidationType.email:
        if (!_isValidEmail(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid email address',
          );
        }
        break;

      case ValidationType.phone:
        if (!_isValidPhone(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid phone number',
          );
        }
        break;

      case ValidationType.password:
        if (!_isValidPassword(value)) {
          return ValidationResult.error(
            rule.errorMessage ??
                'Password must be at least 8 characters with letters and numbers',
          );
        }
        break;

      case ValidationType.age:
        if (!_isValidAge(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid age (18-120)',
          );
        }
        break;

      case ValidationType.name:
        if (!_isValidName(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid name',
          );
        }
        break;

      case ValidationType.address:
        if (!_isValidAddress(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid address',
          );
        }
        break;

      case ValidationType.pincode:
        if (!_isValidPincode(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid 6-digit pincode',
          );
        }
        break;

      case ValidationType.aadhaar:
        if (!_isValidAadhaar(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid 12-digit Aadhaar number',
          );
        }
        break;

      case ValidationType.voterId:
        if (!_isValidVoterId(value)) {
          return ValidationResult.error(
            rule.errorMessage ?? 'Please enter a valid Voter ID',
          );
        }
        break;
    }

    // Custom validator
    if (rule.customValidator != null) {
      final customResult = rule.customValidator(value);
      if (customResult is ValidationResult) {
        return customResult;
      } else if (customResult is String) {
        return ValidationResult.error(customResult);
      } else if (customResult is bool && !customResult) {
        return ValidationResult.error(
          rule.errorMessage ?? 'Validation failed',
        );
      }
    }

    return ValidationResult.success();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    // Indian phone number format
    return RegExp(r'^[6-9]\d{9}$')
        .hasMatch(phone.replaceAll(RegExp(r'[^\d]'), ''));
  }

  bool _isValidPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[a-zA-Z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }

  bool _isValidAge(String age) {
    final ageInt = int.tryParse(age);
    return ageInt != null && ageInt >= 18 && ageInt <= 120;
  }

  bool _isValidName(String name) {
    return name.trim().length >= 2 && RegExp(r'^[a-zA-Z\s]+$').hasMatch(name);
  }

  bool _isValidAddress(String address) {
    return address.trim().length >= 10;
  }

  bool _isValidPincode(String pincode) {
    return RegExp(r'^\d{6}$').hasMatch(pincode);
  }

  bool _isValidAadhaar(String aadhaar) {
    return RegExp(r'^\d{12}$')
        .hasMatch(aadhaar.replaceAll(RegExp(r'[^\d]'), ''));
  }

  bool _isValidVoterId(String voterId) {
    // Indian Voter ID format: 3 letters + 7 digits
    return RegExp(r'^[A-Z]{3}\d{7}$')
        .hasMatch(voterId.toUpperCase().replaceAll(RegExp(r'[^\w]'), ''));
  }

  // Predefined validation rules for common fields
  static List<ValidationRule> get emailRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.email),
      ];

  static List<ValidationRule> get phoneRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.phone),
      ];

  static List<ValidationRule> get passwordRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.password),
      ];

  static List<ValidationRule> get ageRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.age),
      ];

  static List<ValidationRule> get nameRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.name),
      ];

  static List<ValidationRule> get addressRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.address),
      ];

  static List<ValidationRule> get pincodeRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.pincode),
      ];

  static List<ValidationRule> get aadhaarRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.aadhaar),
      ];

  static List<ValidationRule> get voterIdRules => [
        const ValidationRule(type: ValidationType.required),
        const ValidationRule(type: ValidationType.voterId),
      ];
}

// Enhanced form field with validation
class ValidatedFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final TextEditingController controller;
  final List<ValidationRule> validationRules;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String)? onChanged;
  final String? Function(String)? onSubmit;
  final bool enabled;
  final int maxLines;
  final int? maxLength;

  const ValidatedFormField({
    super.key,
    this.label,
    this.hint,
    required this.controller,
    required this.validationRules,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onSubmit,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<ValidatedFormField> createState() => _ValidatedFormFieldState();
}

class _ValidatedFormFieldState extends State<ValidatedFormField> {
  String? _errorMessage;
  bool _hasBeenFocused = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validate);
    super.dispose();
  }

  void _validate() {
    if (!_hasBeenFocused) return;

    final result = ValidationService().validateField(
      widget.controller.text,
      widget.validationRules,
    );

    setState(() {
      _errorMessage = result.errorMessage;
    });

    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            errorText: _errorMessage,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _errorMessage != null
                    ? Colors.red
                    : Theme.of(context).primaryColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onTap: () {
            setState(() {
              _hasBeenFocused = true;
            });
          },
          onFieldSubmitted: widget.onSubmit,
        ),
      ],
    );
  }

  bool get isValid => _errorMessage == null;
  String? get errorMessage => _errorMessage;
}
