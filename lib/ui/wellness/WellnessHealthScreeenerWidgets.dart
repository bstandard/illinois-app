/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/survey.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessHealthScreenerHomeWidget extends StatefulWidget {
  WellnessHealthScreenerHomeWidget();

  @override
  State<WellnessHealthScreenerHomeWidget> createState() => _WellnessHealthScreenerHomeWidgetState();
}

class _WellnessHealthScreenerHomeWidgetState extends State<WellnessHealthScreenerHomeWidget> implements NotificationsListener {
  bool _loading = false;

  List<String> _timeframes = ["Today", "This Week", "This Month", "All Time"];
  List<String> _surveyTypes = ["All", "Symptoms", "Illness Screener"];

  String? _selectedTimeframe = "This Week";
  String? _selectedSurveyType = "All";

  List<SurveyResponse> _responses = [];

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, []);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? _buildLoadingContent() : _buildContent();
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // SurveyWidget(survey: Config().symptomSurveyID, onChangeSurveyResponse: (_) {
        //   setState(() {});
        // }),
        HomeSlantWidget(
          title: Localization().getStringEx('panel.wellness.sections.health_screener.label.screener.title', 'Symptom Screener'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          childPadding: HomeSlantWidget.defaultChildPadding,
          child: Column(children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      Localization().getStringEx('panel.wellness.sections.health_screener.label.symptom_screener.title',
                        'Feeling sick? Use the Symptom Screener to help you find the right resources'),
                      style: Styles().textStyles?.getTextStyle('widget.title.large.fat'),
                    ),
                    SizedBox(height: 16),
                    RoundedButton(
                      label: Localization().getStringEx('panel.wellness.sections.health_screener.button.take_screener.title', 'Take the Symptom Screener'),
                      textStyle: Styles().textStyles?.getTextStyle('widget.detail.regular.fat'),
                      onTap: _onTapTakeSymptomScreener),
                  ],
                ),
              ),
            )
          ]),
        ),
        HomeSlantWidget(
          title: Localization().getStringEx('panel.wellness.sections.health_screener.label.history.title', 'History'),
          titleIcon: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),
          childPadding: HomeSlantWidget.defaultChildPadding,
          child: Column(children: [
            _buildFiltersWidget(),
            _buildResponesesSection(),
          ]),
        )
      ]);
  }

  Widget _buildFiltersWidget() {
    return Card(
      color: Styles().colors?.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(Localization().getStringEx("panel.wellness.sections.health_screener.dropdown.filter.timeframe.title", "Time:"), style: Styles().textStyles?.getTextStyle('widget.title.regular'),),
                Container(width: 8.0),
                Expanded(
                  child: DropdownButton(value: _selectedTimeframe, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                      items: _getDropDownItems(_timeframes), isExpanded: true, onChanged: (String? selected) {
                    setState(() {
                      _selectedTimeframe = selected;
                      _refreshHistory();
                    });
                  }),
                ),
              ],
            ),
            Row(
              children: [
                Text(Localization().getStringEx("panel.wellness.sections.health_screener.dropdown.filter.event_type.title", "Type:"), style: Styles().textStyles?.getTextStyle('widget.title.regular'),),
                Container(width: 8.0),
                Expanded(
                  child: DropdownButton(value: _selectedSurveyType, style: Styles().textStyles?.getTextStyle('widget.detail.regular'),
                      items: _getDropDownItems(_surveyTypes), isExpanded: true, onChanged: (String? selected) {
                    setState(() {
                      _selectedSurveyType = selected;
                      _refreshHistory();
                    });
                  }),
                ),
              ],
            ),
            // Row(
            //   children: [
            //     Text(Localization().getStringEx("panel.activity.dropdown.filter.illness.title", "Illness:"), style: Styles().textStyles.headline4,),
            //     Container(width: 8.0),
            //     Expanded(
            //       child: DropdownButton(value: _selectedPlan, isExpanded: true, style: Styles().textStyles.body, items: AppWidgets.getDropDownItems(Health().activePlans, nullOption: "All"), onChanged: (TreatmentPlan? selected) {
            //         setState(() {
            //           _selectedPlan = selected;
            //           _refreshEvents();
            //         });
            //       }),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponesesSection() {
    List<Widget> content = [];
    for(SurveyResponse response in _responses) {
      Widget widget = _buildSurveyResponseCard(context, response, showTimeOnly: _selectedTimeframe == "Today");
      content.add(widget);
      content.add(Container(height: 16.0));
    }
    return Column(children: content);
  }

  Widget _buildSurveyResponseCard(BuildContext context, SurveyResponse response, {bool showTimeOnly = false}) {
    List<Widget> widgets = [];

    String? date;
    if (showTimeOnly) {
      date = DateTimeUtils.getDisplayTime(dateTimeUtc: response.dateCreated);
    } else {
      date = DateTimeUtils.getDisplayDateTime(response.dateCreated);
    }

    widgets.addAll([
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(response.survey.title.toUpperCase(), style: Styles().textStyles?.getTextStyle('widget.title.small.fat')),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(date ?? '', style: Styles().textStyles?.getTextStyle('widget.title.small')),
              Container(width: 8.0),
              Image.asset('images/chevron-right.png')
              // UIIcon(IconAssets.chevronRight, size: 14.0, color: Styles().colors.headlineText),
            ],
          ),
        ],
      ),
      Container(height: 8),
    ]);

    dynamic result = response.survey.resultData;
    if (result is Map<String, dynamic>) {
      if (result['type'] == 'survey_data.result') {
        SurveyDataResponse dataResult = SurveyDataResponse.fromJson('result', result);
        widgets.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(Localization().getStringEx("panel.wellness.sections.health_screener.label.result.title", "Results:"), style: Styles().textStyles?.getTextStyle('widget.title.regular.fat')),
            SurveyWidgets.buildSurveyDataResult(context, dataResult) ?? Container(),
          ],
        ));
      }
    }

    return Material(
      borderRadius: BorderRadius.circular(30),
      color: Styles().colors?.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        // onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => EventSummaryPanel(event: event, plan: plan))),
        child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            )
        ),
      ),
    );
  }

  void _onTapTakeSymptomScreener() {
    // Navigator.push(context, CupertinoPageRoute(builder: (context) => SurveyPanel(survey: Config().symptomSurveyID, onChangeSurveyResponse: (_) {
    //   setState(() {});
    // })));
  }

  void _refreshHistory() {
    _setLoading(true);

    DateTime now = DateTime.now();
    DateTime? startDate;
    switch(_selectedTimeframe) {
      case "Today":
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case "This Week":
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        break;
      case "This Month":
        startDate = DateTime(now.year, now.month);
        break;
      case "All Time":
        startDate = null;
        break;
      default:
        startDate = DateTime(now.year, now.month, now.day);
    }

    List<String> types = [];
    if (_selectedSurveyType == "All") {
      types.addAll(_surveyTypes.skip(1));
    } else if (_selectedSurveyType != null) {
      types.add(_selectedSurveyType!);
    }
    for (int i = 0; i < types.length; i++) {
      types[i] = types[i].toLowerCase().replaceAll(' ', '_');
    }

    //TODO: Handle pagination
    Polls().loadSurveyResponses(typeIDs: types, startDate: startDate, limit: 100).then((responses) {
      setState(() {
        _responses = responses ?? [];
      });
      _setLoading(false);
    });
  }

  List<DropdownMenuItem<T>> _getDropDownItems<T>(List<T> options, {String? nullOption}) {
    List<DropdownMenuItem<T>> dropDownItems = <DropdownMenuItem<T>>[];
    if (nullOption != null) {
      dropDownItems.add(DropdownMenuItem(value: null, child: Text(nullOption, style: Styles().textStyles?.getTextStyle('widget.detail.regular'))));
    }
    for (T option in options) {
      dropDownItems.add(DropdownMenuItem(value: option, child: Text(option.toString(), style: Styles().textStyles?.getTextStyle('widget.detail.regular'))));
    }
    return dropDownItems;
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          CircularProgressIndicator(),
          Container(height: MediaQuery.of(context).size.height / 5 * 3)
        ]));
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }

  // Notifications Listener

  @override
  void onNotification(String name, param) {

  }
}
