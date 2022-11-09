// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SkillsSelfEvaluationResultsPanel extends StatefulWidget {

  SkillsSelfEvaluationResultsPanel();

  @override
  _SkillsSelfEvaluationResultsPanelState createState() => _SkillsSelfEvaluationResultsPanelState();
}

class _SkillsSelfEvaluationResultsPanelState extends State<SkillsSelfEvaluationResultsPanel> {
  List<SurveyResponse> _responses = [];
  Set<String> _responseSections = {"Self-Management Skills", "Innovation Skills", "Cooperation Skills", "Social Engagement Skills", "Emotional Resilience Skills"};
  SurveyResponse? _selectedComparisonResponse;

  @override
  void initState() {
    Polls().loadSurveyResponses(surveyTypes: ["bessi"], limit: 10).then((responses) {
      if (CollectionUtils.isNotEmpty(responses)) {
        _responses = responses!;
        _responses.sort(((a, b) => a.dateCreated.compareTo(b.dateCreated)));
        _responseSections.clear();
        for (SurveyResponse response in responses) {
          _responseSections.addAll(response.survey.stats?.scores.keys ?? []);
        }
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootBackHeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.results.header.title', 'Skills Self-Evaluation'),),
      body: SectionSlantHeader(
        header: _buildHeader(),
        slantColor: Styles().colors?.gradientColorPrimary,
        backgroundColor: Styles().colors?.background,
        children: _buildContent(),
        childrenPadding: const EdgeInsets.only(top: 240),
      ),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.section.title', 'Results'), style: TextStyle(fontFamily: "ProximaNovaExtraBold", fontSize: 36.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        Text(Localization().getStringEx('panel.skills_self_evaluation.results.score.scale', '(0-100)'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 16.0, color: Styles().colors?.surface), textAlign: TextAlign.center,),
        _buildScoresHeader(),
      ]),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ]
        )
      ),
    );
  }

  Widget _buildScoresHeader() {
    return Padding(padding: const EdgeInsets.only(top: 64, left: 32, right: 32, bottom: 16), child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: Styles().colors?.surface, thickness: 2),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Row(children: [
          Flexible(flex: 5, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.results.skills.title', 'SKILLS'), style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface),)),
          Flexible(flex: 3, fit: FlexFit.tight, child: Text(_responses.isNotEmpty ? DateTimeUtils.localDateTimeToString(_responses[0].dateCreated, format: 'MM/dd/yy') ?? 'NONE' : 'NONE', style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface),)),
          Flexible(flex: 2, fit: FlexFit.tight, child: DropdownButtonHideUnderline(child:
            DropdownButton<SurveyResponse?>(
              icon: Padding(padding: const EdgeInsets.only(left: 4), child: Image.asset('images/icon-down.png', color: Styles().colors?.surface)),
              isExpanded: false,
              style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface),
              // hint: (currentTerm?.name?.isNotEmpty ?? false) ? Text(currentTerm?.name ?? '', style: getTermDropDownItemStyle(selected: true)) : null,
              items: _buildResponseDateDropDownItems(),
              onChanged: _onResponseDateDropDownChanged,
              dropdownColor: Colors.transparent,
              isDense: true,
            ),
          )),
        ],)),
      ],
    ));
  }

  List<Widget> _buildContent() {
    return <Widget>[
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8),
        itemCount: _responseSections.length,
        itemBuilder: (BuildContext context, int index) {
          String section = _responseSections.elementAt(index);
          //TODO: get title string from section key
          String title = section;
          num? mostRecentScore = CollectionUtils.isNotEmpty(_responses) ? _responses[0].survey.stats?.scores[section] : null;
          num? comparisonScore = _selectedComparisonResponse?.survey.stats?.scores[section];
          return Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Card(
              child: InkWell(
                onTap: () => _showScoreDescription(section),
                child: Padding(padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16), child: Row(children: [
                  Flexible(flex: 4, fit: FlexFit.tight, child: Padding(padding: const EdgeInsets.only(right: 16.0), child: 
                    Text(title, style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 16.0, color: Styles().colors?.fillColorPrimaryVariant)))
                  ),
                  Flexible(flex: 2, fit: FlexFit.tight, child: Text(mostRecentScore?.toString() ?? "--", style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 36.0, color: Styles().colors?.fillColorSecondary))),
                  Flexible(flex: 1, fit: FlexFit.tight, child: Text(comparisonScore?.toString() ?? "--", style: TextStyle(fontFamily: "ProximaNovaBold", fontSize: 36.0, color: Styles().colors?.mediumGray))),
                  Flexible(flex: 1, fit: FlexFit.tight, child: SizedBox(height: 16.0 , child: Image.asset('images/chevron-right.png', color: Styles().colors?.fillColorSecondary))),
                ],)),
              )
            ));
      }),
      Padding(padding: const EdgeInsets.only(top: 16), child: GestureDetector(onTap: _onTapClearAllScores, child: 
        Text("Clear All Scores", style: TextStyle(
          fontFamily: "ProximaNovaBold", 
          fontSize: 16.0, 
          color: Styles().colors?.fillColorPrimaryVariant,
          decoration: TextDecoration.underline,
          decorationColor: Styles().colors?.fillColorSecondary
        )
      ),)),
    ];
  }

  List<DropdownMenuItem<SurveyResponse?>> _buildResponseDateDropDownItems() {
    //TODO: add student average option?
    List<DropdownMenuItem<SurveyResponse?>> items = <DropdownMenuItem<SurveyResponse?>>[
      DropdownMenuItem<SurveyResponse?>(
        value: null,
        child: Text('NONE', style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface,),),
      )
    ];
    if (CollectionUtils.isNotEmpty(_responses)) {
      for (SurveyResponse response in _responses) {
        String dateString = DateTimeUtils.localDateTimeToString(response.dateCreated, format: 'MM/dd/yy') ?? '';
        items.add(DropdownMenuItem<SurveyResponse?>(
          value: response,
          child: Text(dateString, style: TextStyle(fontFamily: "ProximaNovaRegular", fontSize: 12.0, color: Styles().colors?.surface,),),
        ));
      }
    }
    return items;
  }

  void _onResponseDateDropDownChanged(SurveyResponse? value) {
    setState(() {
      _selectedComparisonResponse = value;
    });
    //TODO: set scores in card widgets based on value section scores
  }

  void _showScoreDescription(String section) {
    //TODO: show panel with more info about evaluation section score
  }

  void _onTapClearAllScores() {
    //TODO: call Polls BB API to clear all responses for survey type "bessi" after confirming
  }
}

