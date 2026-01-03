import 'package:flutter/material.dart';


final kInputDecoration = InputDecoration(
  hintStyle: const TextStyle(color: Colors.grey),
  filled: true,
  fillColor: const Color(0xFF282828),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: const BorderSide(color: Colors.grey),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: const BorderSide(color: Colors.grey),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(30),
    borderSide: const BorderSide(color: Color.fromARGB(255, 1, 149, 247)),
  ),
);
