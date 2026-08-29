library intl_phone_field;

import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/padding.dart';
import 'package:family_expense_management/style/radius.dart';

class CountryPicker extends StatefulWidget {
  final ValueChanged<Country>? onCountryChanged;
  final String languageCode;
  final String? initialCountryCode;
  final List<Country>? countries;
  final TextStyle? style;
  final bool showDropdownIcon;

  final BoxDecoration dropdownDecoration;
  final TextStyle? dropdownTextStyle;
  final String searchText;
  final IconPosition dropdownIconPosition;
  final Icon dropdownIcon;
  final bool showCountryFlag;

  final EdgeInsetsGeometry flagsButtonPadding;
  final PickerDialogStyle? pickerDialogStyle;
  final EdgeInsets flagsButtonMargin;
  final CountryCubit countryCubit;

  const CountryPicker({
    Key? key,
    this.initialCountryCode,
    this.languageCode = 'en',
    this.style,
    this.dropdownTextStyle,
    this.countries,
    this.onCountryChanged,
    this.showDropdownIcon = true,
    this.dropdownDecoration = const BoxDecoration(),
    @Deprecated('Use searchFieldInputDecoration of PickerDialogStyle instead')
    this.searchText = 'Search country',
    this.dropdownIconPosition = IconPosition.leading,
    this.dropdownIcon = const Icon(Icons.arrow_drop_down),
    this.showCountryFlag = true,
    this.flagsButtonPadding = EdgeInsets.zero,
    this.pickerDialogStyle,
    this.flagsButtonMargin = EdgeInsets.zero,
    required this.countryCubit,
  }) : super(key: key);

  @override
  _IntlCountryPickerState createState() => _IntlCountryPickerState();
}

class _IntlCountryPickerState extends State<CountryPicker> {
  late List<Country> _countryList;
  late List<Country> filteredCountries;

  @override
  void initState() {
    super.initState();
    _countryList = widget.countries ?? countries;
    filteredCountries = _countryList;
    if (widget.initialCountryCode == null) {
      widget.countryCubit.select(null);
    } else {
      widget.countryCubit.select(
        _countryList.firstWhere(
          (item) => item.code == (widget.initialCountryCode ?? 'US'),
          orElse: () => _countryList.first,
        ),
      );
    }
  }

  Future<void> _changeCountry() async {
    filteredCountries = _countryList;
    await showDialog(
      context: context,
      useRootNavigator: false,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => CountryPickerDialog(
          languageCode: widget.languageCode.toLowerCase(),
          style: widget.pickerDialogStyle,
          filteredCountries: filteredCountries,
          searchText: widget.searchText,
          countryList: _countryList,
          selectedCountry: widget.countryCubit.state ?? countries.first,
          onCountryChanged: (Country country) {
            widget.countryCubit.select(country);
            widget.onCountryChanged?.call(country);
            setState(() {});
          },
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountryCubit, Country?>(
      bloc: widget.countryCubit,
      builder: (context, state) {
        return Container(
          height: 46.h,
          width: double.maxFinite,
          padding: EdgeInsetsApp.symmetricH12,
          margin: widget.flagsButtonMargin,
          decoration: BoxDecoration(
            borderRadius: BorderRadiusApp.radius32,
            color: ColorsApp.white,
            border: Border.all(color: ColorsApp.grey200),
          ),
          child: DecoratedBox(
            decoration: widget.dropdownDecoration,
            child: InkWell(
              borderRadius:
                  widget.dropdownDecoration.borderRadius as BorderRadius?,
              onTap: _changeCountry,
              child: Padding(
                padding: widget.flagsButtonPadding,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(width: 4),
                    if (widget.showDropdownIcon &&
                        widget.dropdownIconPosition ==
                            IconPosition.leading) ...[
                      widget.dropdownIcon,
                      const SizedBox(width: 4),
                    ],
                    if (widget.showCountryFlag && state != null) ...[
                      kIsWeb
                          ? Image.asset(
                              'assets/flags/${state.code.toLowerCase()}.png',
                              package: 'intl_phone_field',
                              width: 32,
                            )
                          : Text(
                              state.flag,
                              style: const TextStyle(fontSize: 18),
                            ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        state == null ? widget.searchText : '+${state.name}',
                        style: widget.dropdownTextStyle,
                      ),
                    ),
                    if (widget.showDropdownIcon &&
                        widget.dropdownIconPosition ==
                            IconPosition.trailing) ...[
                      const SizedBox(width: 4),
                      widget.dropdownIcon,
                    ],
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CountryCubit extends Cubit<Country?> {
  CountryCubit() : super(null);

  void select(Country? value) {
    emit(value);
  }
}
