import 'package:flutter/material.dart';

const kPrimaryColor = Color.fromRGBO(152, 29, 202, 1);
const kSecondaryColor = Color.fromRGBO(153, 117, 153, 1);
const kScaffoldBackgroundColor = Color.fromRGBO(230, 230, 250, 1);
const kThirdColor = Color.fromRGBO(192, 192, 192, 1);
var kDarkColor1 = Colors.grey[850];

const kSendButtonTextStyle = TextStyle(
  color: kPrimaryColor,
  fontWeight: FontWeight.bold,
  fontSize: 18.0,
);

const kMessageTextFieldDecoration = InputDecoration(
  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  hintText: 'Mesaj Gönder ...',
  border: InputBorder.none,
);

const kMessageContainerDecoration = BoxDecoration(
  border: Border(
    top: BorderSide(color: kPrimaryColor, width: 2.0),
  ),
);

const kTextFieldDecoration = InputDecoration(
  hintText: 'Enter your value.',
  contentPadding:
  EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide:
    BorderSide(color: kPrimaryColor, width: 1.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide:
    BorderSide(color: kPrimaryColor, width: 2.0),
    borderRadius: BorderRadius.all(Radius.circular(32.0)),
  ),
);

/// App Bar
const kAppBarTextStyle = TextStyle(
  color: kScaffoldBackgroundColor,
  fontWeight: FontWeight.bold,
  fontSize: 24.0,
);

/// Bottom Navigation Bar
const kBottomNavigationBarThemeData = BottomNavigationBarThemeData(
  backgroundColor: Colors.black,
  selectedItemColor: kScaffoldBackgroundColor,
  unselectedItemColor: kThirdColor,
  elevation: 0,
  type: BottomNavigationBarType.fixed,
);
