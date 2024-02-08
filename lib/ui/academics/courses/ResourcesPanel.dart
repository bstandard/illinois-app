import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/academics/courses/ModuleHeaderWidget.dart';
import 'package:illinois/ui/academics/courses/PDFPanel.dart';
import 'package:illinois/ui/academics/courses/VideoPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/content.dart' as con;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';


class ResourcesPanel extends StatefulWidget {
  final List<Content> contentItems;
  final ReferenceType? initialReferenceType;
  final Color? color;
  final int unitNumber;
  final String unitName;

  final Widget? moduleIcon;
  final String moduleName;

  const ResourcesPanel({required this.contentItems, this.initialReferenceType, required this.color, required this.unitNumber, required this.unitName, this.moduleIcon, required this.moduleName});

  @override
  State<ResourcesPanel> createState() => _ResourcesPanelState();
}

class _ResourcesPanelState extends State<ResourcesPanel> {
  Color? _color;
  late List<Content> _contentItems;
  Set<ReferenceType> _referenceTypes = {};
  Set<String> _loadingReferenceKeys = {};
  Map<String, File?> _fileCache = {};
  ReferenceType? _selectedResourceType;

  @override
  void initState() {
    _color = widget.color;
    _contentItems = widget.contentItems;
    _selectedResourceType = widget.initialReferenceType;
    for (Content item in _contentItems) {
      if (item.reference?.type != null) {
        _referenceTypes.add(item.reference!.type!);
      }
    }
    super.initState();

    //TODO: load and cache all content files on init?
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.essential_skills_coach.resources.header.title', 'Unit Resources'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: Column(children: [
        ModuleHeaderWidget(icon: widget.moduleIcon, moduleName: widget.moduleName, backgroundColor: _color,),
        _buildResourcesHeaderWidget(),
        _buildResourceTypeDropdown(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
            child: _buildResources()
          ),
        ),
      ],),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildResources(){
    List<Content> filteredContentItems = _filterContentItems();
    return ListView.builder(
        shrinkWrap: true,
        // physics: NeverScrollableScrollPhysics(),
        itemCount: filteredContentItems.length,
        itemBuilder: (BuildContext context, int index) {
          Content contentItem = filteredContentItems[index];
          Reference? reference = contentItem.reference;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Material(
              color: Styles().colors.surface,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              clipBehavior: Clip.hardEdge,
              elevation: 1.0,
              child: InkWell(
                onTap: (){
                  if (reference?.type == ReferenceType.video) {
                    if (_fileCache[reference?.referenceKey] != null) {
                      _openVideo(context, reference?.name, _fileCache[reference?.referenceKey]!);
                    } else {
                      _setLoadingReferenceKey(reference?.referenceKey, true);
                      _loadContentForKey(reference?.referenceKey, onResult: (value) {
                        _openVideo(context, reference?.name, value);
                      });
                    }
                  } else if (reference?.type == ReferenceType.uri) {
                    Uri uri = Uri.parse(reference?.referenceKey ?? "");
                    _launchUrl(uri);
                  } else if (reference?.type != ReferenceType.text) {
                    _setLoadingReferenceKey(reference?.referenceKey, true);
                    if (_fileCache[reference?.referenceKey] != null) {
                      _openPdf(context, reference?.name, _fileCache[reference?.referenceKey]!.path);
                    } else {
                      _loadContentForKey(reference?.referenceKey, onResult: (value) {
                        _openPdf(context, reference?.name, value.path);
                      });
                    }
                  }
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  leading: Styles().images.getImage("${reference?.stringFromType()}-icon"),
                  title: Text(contentItem.name ?? "", style: Styles().textStyles.getTextStyle("widget.message.large.fat"),),
                  subtitle: Text(contentItem.details ?? ""),
                  trailing: reference?.type != ReferenceType.text ? _loadingReferenceKeys.contains(reference?.referenceKey) ? CircularProgressIndicator() : Icon(
                    Icons.chevron_right_rounded,
                    size: 25.0,
                  ) : null,
                ),
              ),
            ),
          );
        }
    );
  }

  Widget _buildResourceTypeDropdown(){
    return Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0),
      child: Container(
        padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
        decoration: BoxDecoration(
          color: Styles().colors.surface,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
        ),
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton(
            value: _selectedResourceType,
            alignment: AlignmentDirectional.centerStart,
            iconDisabledColor: Styles().colors.fillColorSecondary,
            iconEnabledColor: Styles().colors.fillColorSecondary,
            focusColor: Styles().colors.surface,
            dropdownColor: Styles().colors.surface,
            isExpanded: true,
            underline: Divider(color: Styles().colors.fillColorSecondary, height: 1.0, indent: 16.0, endIndent: 16.0),
            borderRadius: BorderRadius.all(Radius.circular(4.0)),
            items: _buildDropdownItems(),
            onChanged: (ReferenceType? selected) {
              setState(() {
                _selectedResourceType = selected;
              });
            }
          ),
        )
      )
    );
  }

  Widget _buildResourcesHeaderWidget(){
    return Container(
      color: Styles().colors.fillColorPrimary,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Unit ${widget.unitNumber}', style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                  Text(widget.unitName, style: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"))
                ],
              ),
            ),
            Flexible(
              flex: 1,
              child: Container(
                  decoration: BoxDecoration(
                    color: Styles().colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Styles().images.getImage('closed-book', size: 40.0),
                  )
              ),
            )
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<ReferenceType>> _buildDropdownItems() {
    List<DropdownMenuItem<ReferenceType>> dropDownItems = [
      DropdownMenuItem(value: null, child: Text(Localization().getStringEx('panel.essential_skills_coach.resources.select.all.label', "View All Resources"), style: Styles().textStyles.getTextStyle("widget.detail.large")))
    ];

    for (ReferenceType type in _referenceTypes) {
      String itemText = '';
      switch (type) {
        case ReferenceType.pdf:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.pdf.label', 'View All PDFs');
          break;
        case ReferenceType.video:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.video.label', 'View All Videos');
          break;
        case ReferenceType.uri:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.uri.label', 'View All External Links');
          break;
        case ReferenceType.text:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.text.label', 'View All Terms');
          break;
        case ReferenceType.powerpoint:
          itemText = Localization().getStringEx('panel.essential_skills_coach.resources.select.powerpoint.label', 'View All Powerpoints');
          break;
        default:
          continue;
      }

      dropDownItems.add(DropdownMenuItem(value: type, child: Text(
        itemText,
        style: Styles().textStyles.getTextStyle("widget.detail.large")
      )));
    }
    return dropDownItems;
  }

  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  List<Content> _filterContentItems() {
    if (_selectedResourceType != null) {
      List<Content> filteredContentItems =  _contentItems.where((i) => i.reference?.type == _selectedResourceType).toList();
      return filteredContentItems;
    }
    return _contentItems;
  }

  void _loadContentForKey(String? key, {Function(File)? onResult}) {
    if (StringUtils.isNotEmpty(key) && !_loadingReferenceKeys.contains(key)) {
      _setLoadingReferenceKey(key, true);
      con.Content().getFileContentItem(key!, Config().essentialSkillsCoachKey ?? "").then((value) => {
        setState(() {
          _loadingReferenceKeys.remove(key);
          if (value != null) {
            _fileCache[key] = value;
            onResult?.call(value);
          }
        })
      });
    }
  }

  void _openPdf(BuildContext context, String? resourceName, String? path) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PDFPanel(resourceName: resourceName, path: path,),
    ),);
  }

  void _openVideo(BuildContext context, String? resourceName, File file) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => VideoPanel(resourceName: resourceName, file: file,),
    ),);
  }

  void _setLoadingReferenceKey(String? key, bool value) {
    if (key != null) {
      setStateIfMounted(() {
        if (value) {
          _loadingReferenceKeys.add(key);
        } else {
          _loadingReferenceKeys.remove(key);
        }
      });
    }
  }
}
