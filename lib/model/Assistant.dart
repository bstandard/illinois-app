import 'package:rokwire_plugin/utils/utils.dart';

Map<String, String> deeplinks = {
  'home': 'Home',
  'browse': 'Browse',
  'map': 'Map',
  'map.events': 'Events',
  'map.dining': 'Residence Hall Dining',
  'map.buildings': 'Campus Buildings',
  'map.student_courses': 'My Courses',
  'map.appointments': 'MyMcKinley In-Person Appointments',
  'map.mtd_stops': 'Bus Stops',
  'map.mtd_destinations': 'My Destinations',
  'map.mental_health': 'Find a Therapist',
  'map.state_farm_wayfinding': 'State Farm Wayfinding',
  'academics': 'Academics',
  'academics.gies_checklist': 'iDegrees New Student Checklist',
  'academics.uiuc_checklist': 'New Student Checklist',
  'academics.events': 'Academic Events',
  'academics.canvas_courses': 'My Gies Canvas Courses',
  'academics.medicine_courses': 'My College of Medicine Compliance',
  'academics.student_courses': 'My Courses',
  'academics.skills_self_evaluation': 'Skills Self-Evaluation',
  'academics.todo_list': 'To-Do List',
  'academics.due_date_catalog': 'Due Date Catalog',
  'academics.my_illini': 'myIllini',
  'academics.appointments': 'Appointments',
  'wellness': 'Wellness',
  'wellness.daily_tips': 'Today\'s Wellness Tip',
  'wellness.rings': 'Daily Wellness Rings',
  'wellness.todo': 'To-Do List',
  'wellness.appointments': 'MyMcKinley Appointments',
  'wellness.health_screener': 'Illinois Health Screener',
  'wellness.podcast': 'Healthy Illini Podcast',
  'wellness.resources': 'Wellness Resources',
  'wellness.struggling': 'I\'m Struggling',
  'wellness.mental_health': 'Mental Health Resources',
  'inbox': 'Inbox Panel',
  'appointment': 'Appointment',
  'profile.my': 'My Profile',
  'profile.who_are_you': 'Who Are You?',
  'profile.privacy': 'My App Privacy Settings',
  'settings.sections': 'Sign In/Sign Out',
  'settings.interests': 'My Interests',
  'settings.food_filters': 'My Food Filters',
  'settings.sports': 'My Sports Teams',
  'settings.favorites': 'Customize Favorites',
  'settings.assessments': 'My Assessments',
  'settings.calendar': 'My Calendar Settings',
  'settings.appointments': 'MyMcKinley Appointments',
  'event_detail': 'Event Detail',
  'game_detail': 'Athletics Game Detail',
  'athletics_game_started': 'Athletics Game Detail',
  'athletics_news_detail': 'Athletics News Detail',
  'group': 'Group Detail',
  'canvas_app_deeplink': 'Canvas Student',
  'wellness_todo_entry': 'Wellness To-Do item',
  'poll': 'Poll Detail',
};

class Message {
  final String content;
  final bool user;
  final bool example;
  final Link? link;
  final List<String> sources;
  MessageFeedback? feedback;
  String? feedbackExplanation;

  Message({required this.content, required this.user, this.example = false,
    this.link, this.sources = const [], this.feedback, this.feedbackExplanation});

  factory Message.fromAnswerJson(Map<String, dynamic> json) {
    List<String>? sources = JsonUtils.stringListValue(json['sources']);
    if (sources == null) {
      String? source = JsonUtils.stringValue(json['sources']);
      if (source != null) {
        sources = source.split(',');
        sources = sources.map((e) => e.trim()).toList();
      }
    }
    String? deeplink = JsonUtils.stringValue(json['deeplink'])?.trim();
    return Message(
      content: JsonUtils.stringValue(json['answer'])?.trim() ?? '',
      user: JsonUtils.boolValue(json['user']) ?? false,
      example: JsonUtils.boolValue(json['example']) ?? false,
      link: deeplink != null ?
        Link(name: deeplinks[deeplink] ?? deeplink.split('.|_').join(' '),
          link: 'edu.illinois.rokwire.firebase.messaging.$deeplink') : null, //TODO: handle link base better
      sources: sources ?? [],
      feedback: null,
      feedbackExplanation: null,
    );
  }
}

class Link {
  final String name;
  final String link;
  final String? iconKey;

  Link({required this.name, required this.link, this.iconKey});
}

enum MessageFeedback { good, bad }