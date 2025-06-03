import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flutter/services.dart';

class TextFieldInpute extends StatefulWidget {
  final TextEditingController textEditingController;
  final bool ispass;
  final String hintText;
  final IconData icon;
  final List<TextInputFormatter>? inputFormatters;

  const TextFieldInpute({
    super.key,
    required this.textEditingController,
    this.ispass = false,
    required this.hintText,
    required this.icon,
    this.inputFormatters,
  });

  @override
  State<TextFieldInpute> createState() => _TextFieldInputeState();
}

class _TextFieldInputeState extends State<TextFieldInpute> {
  bool obscureText = true;

  @override
  void initState() {
    super.initState();
    obscureText = widget.ispass;
  }

  @override
  Widget build(BuildContext context) {
    TextInputType keyboardType = TextInputType.text;

    if (widget.inputFormatters != null) {
      if (widget.inputFormatters!.any((f) => f is TelefoneInputFormatter)) {
        keyboardType = TextInputType.phone;
      } else if (widget.inputFormatters!.any((f) => f is DataInputFormatter)) {
        keyboardType = TextInputType.datetime;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        obscureText: widget.ispass ? obscureText : false,
        controller: widget.textEditingController,
        inputFormatters: widget.inputFormatters,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.black45, fontSize: 18),
          prefixIcon: Icon(widget.icon, color: Colors.black45),
          suffixIcon:
              widget.ispass
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black45,
                    ),
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                  )
                  : null,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
          border: InputBorder.none,
          filled: true,
          fillColor: const Color(0xFFedf0f8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(30),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(width: 2, color: Colors.blue),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
