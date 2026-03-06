// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:widgetbook/widgetbook.dart' as _widgetbook;
import 'package:widgetbook_textf/use_cases/basic_formatting_use_case.dart'
    as _widgetbook_textf_use_cases_basic_formatting_use_case;
import 'package:widgetbook_textf/use_cases/link_formatting_use_case.dart'
    as _widgetbook_textf_use_cases_link_formatting_use_case;
import 'package:widgetbook_textf/use_cases/nested_formatting_use_case.dart'
    as _widgetbook_textf_use_cases_nested_formatting_use_case;
import 'package:widgetbook_textf/use_cases/overflow_use_case.dart'
    as _widgetbook_textf_use_cases_overflow_use_case;
import 'package:widgetbook_textf/use_cases/rtl_use_case.dart'
    as _widgetbook_textf_use_cases_rtl_use_case;
import 'package:widgetbook_textf/use_cases/style_inheritance_use_case.dart'
    as _widgetbook_textf_use_cases_style_inheritance_use_case;
import 'package:widgetbook_textf/use_cases/text_properties_use_case.dart'
    as _widgetbook_textf_use_cases_text_properties_use_case;
import 'package:widgetbook_textf/use_cases/textf_options_use_case.dart'
    as _widgetbook_textf_use_cases_textf_options_use_case;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'Textf',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Basic Formatting',
            builder: _widgetbook_textf_use_cases_basic_formatting_use_case
                .basicFormattingUseCase,
            designLink: 'https://www.example.com',
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Link Formatting',
            builder: _widgetbook_textf_use_cases_link_formatting_use_case
                .linkFormattingUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Nested Formatting',
            builder: _widgetbook_textf_use_cases_nested_formatting_use_case
                .nestedFormattingUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Overflow Handling',
            builder:
                _widgetbook_textf_use_cases_overflow_use_case.overflowUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'RTL Support',
            builder: _widgetbook_textf_use_cases_rtl_use_case.rtlUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Inheritance',
            builder: _widgetbook_textf_use_cases_style_inheritance_use_case
                .styleInheritanceUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Text Properties',
            builder: _widgetbook_textf_use_cases_text_properties_use_case
                .textPropertiesUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'TextfOptions Customization',
            builder: _widgetbook_textf_use_cases_textf_options_use_case
                .textfOptionsUseCase,
          ),
        ],
      ),
    ],
  ),
];
