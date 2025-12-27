import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String hint;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Icon? icon;
  final TextEditingController? controller;
  final bool? obscure;
  final TextInputType? keyboardType;
  const CustomTextField({
    super.key,
    required this.hint,
    this.icon,
    this.inputFormatters,
    this.validator,
    this.controller,
    this.obscure,
    this.keyboardType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscure;

  @override
  void initState() {
    _obscure = widget.obscure ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        inputFormatters: widget.inputFormatters,
        validator: widget.validator,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: _obscure,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixIcon: widget.icon,
          suffixIcon: widget.obscure != null && widget.obscure!
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}
