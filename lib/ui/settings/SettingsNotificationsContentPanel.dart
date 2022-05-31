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

import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/settings/SettingsNotificationPreferencesContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class SettingsNotificationsContentPanel extends StatefulWidget {
  final SettingsNotificationsContent? content;

  SettingsNotificationsContentPanel({this.content});

  @override
  _SettingsNotificationsContentPanelState createState() => _SettingsNotificationsContentPanelState();
}

class _SettingsNotificationsContentPanelState extends State<SettingsNotificationsContentPanel> implements NotificationsListener {
late SettingsNotificationsContent _selectedContent;
  bool _contentValuesVisible = false;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Auth2.notifyLoginChanged]);
    // Do not allow not logged in users to view "Notifications" content
    _selectedContent =
        widget.content ?? (Auth2().isLoggedIn ? SettingsNotificationsContent.inbox : SettingsNotificationsContent.preferences);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: _panelHeaderLabel),
        body: Column(children: <Widget>[
          Expanded(
              child: SingleChildScrollView(
                  physics: (_contentValuesVisible ? NeverScrollableScrollPhysics() : null),
                  child: Container(
                      color: Styles().colors!.background,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                            padding: EdgeInsets.only(left: 16, top: 16, right: 16),
                            child: RibbonButton(
                                textColor:
                                    (_contentValuesVisible ? Styles().colors!.fillColorSecondary : Styles().colors!.fillColorPrimary),
                                backgroundColor: Styles().colors!.white,
                                borderRadius: BorderRadius.all(Radius.circular(5)),
                                border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                                rightIconAsset: (_contentValuesVisible ? 'images/icon-up.png' : 'images/icon-down.png'),
                                label: _getContentLabel(_selectedContent),
                                onTap: _changeSettingsContentValuesVisibility)),
                        _buildContent()
                      ]))))
        ]),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar());
  }


  Widget _buildContent() {
    return Stack(children: [Padding(padding: EdgeInsets.all(16), child: _contentWidget), _buildContentValuesContainer()]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(
        visible: _contentValuesVisible,
        child: Positioned.fill(child: Stack(children: <Widget>[_buildContentDismissLayer(), _buildContentValuesWidget()])));
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(
        child: BlockSemantics(
            child: GestureDetector(
                onTap: () {
                  setState(() {
                    _contentValuesVisible = false;
                  });
                },
                child: Container(color: Styles().colors!.blackTransparent06))));
  }

  Widget _buildContentValuesWidget() {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors!.fillColorSecondary, height: 2));
    for (SettingsNotificationsContent contentItem in SettingsNotificationsContent.values) {
      if ((contentItem == SettingsNotificationsContent.inbox) && !Auth2().isLoggedIn) {
        continue;
      }
      if ((_selectedContent != contentItem)) {
        contentList.add(_buildContentItem(contentItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: SingleChildScrollView(child: Column(children: contentList)));
  }

  Widget _buildContentItem(SettingsNotificationsContent contentItem) {
    return RibbonButton(
        backgroundColor: Styles().colors!.white,
        border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
        rightIconAsset: null,
        label: _getContentLabel(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentItem(SettingsNotificationsContent contentItem) {
    _selectedContent = contentItem;
    _changeSettingsContentValuesVisibility();
  }

  void _changeSettingsContentValuesVisibility() {
    _contentValuesVisible = !_contentValuesVisible;
    if (mounted) {
      setState(() {});
    }
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case SettingsNotificationsContent.inbox:
      //TODO: implement
        return Container();
      case SettingsNotificationsContent.preferences:
        return SettingsNotificationPreferencesContentWidget();
    }
  }

  // Utilities

  String _getContentLabel(SettingsNotificationsContent content) {
    switch (content) {
      case SettingsNotificationsContent.inbox:
        return Localization().getStringEx('panel.settings.notifications.content.inbox.label', 'My Notifications');
      case SettingsNotificationsContent.preferences:
        return Localization().getStringEx('panel.settings.notifications.content.preferences.label', 'My Notification Preferences');
    }
  }

  String get _panelHeaderLabel {
    switch (_selectedContent) {
      case SettingsNotificationsContent.inbox:
        return Localization().getStringEx('panel.settings.notifications.header.inbox.label', 'My Notifications');
      case SettingsNotificationsContent.preferences:
        return Localization().getStringEx('panel.settings.notifications.header.preferences.label', 'My Notification Preferences');
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      if ((_selectedContent == SettingsNotificationsContent.inbox) && !Auth2().isLoggedIn) {
        // Do not allow not logged in users to view "Notifications" content
        _selectedContent = SettingsNotificationsContent.preferences;
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

}

enum SettingsNotificationsContent { inbox, preferences }