import 'package:flutter/material.dart';

class S {
  static const double s0 = 0;
  static const double s1 = 1;
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s10 = 10;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;
  static const double s48 = 48;
  static const double s56 = 56;
  static const double s50 = 50;
  static const double s64 = 64;
  static const double s72 = 72;
  static const double s80 = 80;
  static const double s90 = 90;
  static const double s100 = 100;
  static const double s120 = 120;
  static const double s150 = 150;
  static const double s160 = 160;
  static const double s170 = 170;
  static const double s180 = 180;
  static const double s190 = 190;
  static const double s200 = 200;

// You can follow the pattern for every single number if needed:
// static const double s121 = 121; ... up to 150
}

const blankHorizontalsSpace1 = SizedBox(width: S.s1);
const blankHorizontalsSpace2 = SizedBox(width: S.s2);
const blankHorizontalsSpace4 = SizedBox(width: S.s4);
const blankHorizontalsSpace8 = SizedBox(width: S.s8);
const blankHorizontalsSpace10 = SizedBox(width: S.s10);
const blankHorizontalsSpace12 = SizedBox(width: S.s12);
const blankHorizontalsSpace16 = SizedBox(width: S.s16);
const blankHorizontalsSpace20 = SizedBox(width: S.s20);
const blankHorizontalsSpace24 = SizedBox(width: S.s24);
const blankHorizontalsSpace28 = SizedBox(width: S.s28);
const blankHorizontalsSpace32 = SizedBox(width: S.s32);
const blankHorizontalsSpace40 = SizedBox(width: S.s40);
const blankHorizontalsSpace48 = SizedBox(width: S.s48);
const blankHorizontalsSpace56 = SizedBox(width: S.s56);
const blankHorizontalsSpace64 = SizedBox(width: S.s64);
const blankHorizontalsSpace72 = SizedBox(width: S.s72);
const blankHorizontalsSpace80 = SizedBox(width: S.s80);
const blankHorizontalsSpace100 = SizedBox(width: S.s100);
const blankHorizontalsSpace120 = SizedBox(width: S.s120);
const blankHorizontalsSpace150 = SizedBox(width: S.s150);

const blankVerticalSpace1 = SizedBox(height: S.s1);
const blankVerticalSpace2 = SizedBox(height: S.s2);
const blankVerticalSpace4 = SizedBox(height: S.s4);
const blankVerticalSpace8 = SizedBox(height: S.s8);
const blankVerticalSpace10 = SizedBox(height: S.s10);
const blankVerticalSpace12 = SizedBox(height: S.s12);
const blankVerticalSpace16 = SizedBox(height: S.s16);
const blankVerticalSpace20 = SizedBox(height: S.s20);
const blankVerticalSpace24 = SizedBox(height: S.s24);
const blankVerticalSpace28 = SizedBox(height: S.s28);
const blankVerticalSpace32 = SizedBox(height: S.s32);
const blankVerticalSpace40 = SizedBox(height: S.s40);
const blankVerticalSpace48 = SizedBox(height: S.s48);
const blankVerticalSpace56 = SizedBox(height: S.s56);
const blankVerticalSpace64 = SizedBox(height: S.s64);
const blankVerticalSpace72 = SizedBox(height: S.s72);
const blankVerticalSpace80 = SizedBox(height: S.s80);
const blankVerticalSpace100 = SizedBox(height: S.s100);
const blankVerticalSpace120 = SizedBox(height: S.s120);
const blankVerticalSpace150 = SizedBox(height: S.s150);

class P {
  // --- Uniform Padding (All Sides) ---
  static const all0 = EdgeInsets.all(S.s0);
  static const all2 = EdgeInsets.all(S.s2);
  static const all4 = EdgeInsets.all(S.s4);
  static const all8 = EdgeInsets.all(S.s8);
  static const all10 = EdgeInsets.all(S.s10);
  static const all12 = EdgeInsets.all(S.s12);
  static const all16 = EdgeInsets.all(S.s16);
  static const all20 = EdgeInsets.all(S.s20);
  static const all24 = EdgeInsets.all(S.s24);
  static const all32 = EdgeInsets.all(S.s32);
  static const all48 = EdgeInsets.all(S.s48);
  static const all100 = EdgeInsets.all(S.s100);
  static const all150 = EdgeInsets.all(S.s150);

  // --- Horizontal Padding (Left & Right) ---
  static const h4 = EdgeInsets.symmetric(horizontal: S.s4);
  static const h8 = EdgeInsets.symmetric(horizontal: S.s8);
  static const h16 = EdgeInsets.symmetric(horizontal: S.s16);
  static const h24 = EdgeInsets.symmetric(horizontal: S.s24);
  static const h32 = EdgeInsets.symmetric(horizontal: S.s32);

  // --- Vertical Padding (Top & Bottom) ---
  static const v4 = EdgeInsets.symmetric(vertical: S.s4);
  static const v8 = EdgeInsets.symmetric(vertical: S.s8);
  static const v16 = EdgeInsets.symmetric(vertical: S.s16);
  static const v24 = EdgeInsets.symmetric(vertical: S.s24);
  static const v32 = EdgeInsets.symmetric(vertical: S.s32);

  // --- Custom Combinations (Common in Material 3) ---
  // Large horizontal, small vertical (common for buttons/chips)
  static const h16v8 = EdgeInsets.symmetric(horizontal: S.s16, vertical: S.s8);
  static const h24v12 = EdgeInsets.symmetric(horizontal: S.s24, vertical: S.s12);
}