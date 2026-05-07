import 'package:flutter/material.dart';
import '../../models/team_member.dart';

class RoleTemplate {
  final String title;
  final String category;
  final IconData icon;
  final List<TeamDuty> defaultDuties;
  final String linkedVendorCategory;
  final bool pullsDietary;
  final bool allowMultiple;

  const RoleTemplate({
    required this.title,
    required this.category,
    required this.icon,
    this.defaultDuties = const [],
    this.linkedVendorCategory = '',
    this.pullsDietary = false,
    this.allowMultiple = false,
  });
}

const List<RoleTemplate> kRoleTemplates = [
  // ── Bridal Party ──────────────────────────────────────────────────────────

  RoleTemplate(
    title: 'Bride',
    category: 'Bridal Party',
    icon: Icons.favorite_outline,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Arrive at church with escort, wait for cue'),
      TeamDuty(phase: 'Church', description: 'Walk down aisle on music cue'),
      TeamDuty(phase: 'Venue', description: 'Lead first dance with groom'),
      TeamDuty(phase: 'General', description: 'Enjoy the day!'),
    ],
  ),

  RoleTemplate(
    title: 'Groom',
    category: 'Bridal Party',
    icon: Icons.diamond_outlined,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Arrive at church 30 min early with best man'),
      TeamDuty(phase: 'Church', description: 'Wait at altar, greet guests as they arrive'),
      TeamDuty(phase: 'Venue', description: 'Lead first dance with bride'),
      TeamDuty(phase: 'Venue', description: 'Deliver speech / thank guests'),
    ],
  ),

  RoleTemplate(
    title: 'Best Man',
    category: 'Bridal Party',
    icon: Icons.workspace_premium_outlined,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Hold the rings, present at altar'),
      TeamDuty(phase: 'Church', description: 'Sign register as witness'),
      TeamDuty(phase: 'Church', description: 'Coordinate groomsmen arrival and positions'),
      TeamDuty(phase: 'Venue', description: 'Deliver speech before dessert'),
      TeamDuty(phase: 'Venue', description: 'Ensure groom\'s car is decorated'),
      TeamDuty(phase: 'General', description: 'Keep groom calm and on schedule'),
    ],
  ),

  RoleTemplate(
    title: 'Maid of Honour',
    category: 'Bridal Party',
    icon: Icons.star_outline,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Coordinate bridesmaids — timing and positions'),
      TeamDuty(phase: 'Church', description: 'Hold bride\'s bouquet during ceremony'),
      TeamDuty(phase: 'Church', description: 'Sign register as witness'),
      TeamDuty(phase: 'Venue', description: 'Bustle bride\'s dress before dancing'),
      TeamDuty(phase: 'Venue', description: 'Deliver speech / toast the couple'),
      TeamDuty(phase: 'General', description: 'Keep bride calm and on schedule'),
    ],
  ),

  RoleTemplate(
    title: 'Bridesmaid',
    category: 'Bridal Party',
    icon: Icons.people_outline,
    allowMultiple: true,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Walk in procession ahead of bride'),
      TeamDuty(phase: 'Church', description: 'Stand at altar during ceremony'),
      TeamDuty(phase: 'Venue', description: 'Mingle with guests during drinks reception'),
      TeamDuty(phase: 'General', description: 'Support bride and maid of honour throughout the day'),
    ],
  ),

  RoleTemplate(
    title: 'Groomsman',
    category: 'Bridal Party',
    icon: Icons.group_outlined,
    allowMultiple: true,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Arrive early to seat guests — bride\'s family left, groom\'s right'),
      TeamDuty(phase: 'Church', description: 'Walk bridesmaid down aisle during recessional'),
      TeamDuty(phase: 'Venue', description: 'Help direct guests to venue and car park'),
      TeamDuty(phase: 'General', description: 'Support best man and groom throughout the day'),
    ],
  ),

  RoleTemplate(
    title: 'Flower Girl',
    category: 'Bridal Party',
    icon: Icons.local_florist_outlined,
    allowMultiple: true,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Walk ahead of bride, scatter petals or carry flowers'),
    ],
  ),

  RoleTemplate(
    title: 'Page Boy / Ring Bearer',
    category: 'Bridal Party',
    icon: Icons.child_care_outlined,
    allowMultiple: true,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Carry ring cushion or walk with flower girl in procession'),
    ],
  ),

  // ── Ceremony ─────────────────────────────────────────────────────────────

  RoleTemplate(
    title: 'Officiant / Celebrant',
    category: 'Ceremony',
    icon: Icons.menu_book_outlined,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Lead the ceremony and vows'),
      TeamDuty(phase: 'Church', description: 'Guide signing of register'),
    ],
  ),

  RoleTemplate(
    title: 'Reader',
    category: 'Ceremony',
    icon: Icons.import_contacts_outlined,
    allowMultiple: true,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Deliver reading during ceremony — confirm order of service in advance'),
    ],
  ),

  // ── Coordination ─────────────────────────────────────────────────────────

  RoleTemplate(
    title: 'MC / Toastmaster',
    category: 'Coordination',
    icon: Icons.campaign_outlined,
    defaultDuties: [
      TeamDuty(phase: 'Venue', description: 'Welcome guests to the reception'),
      TeamDuty(phase: 'Venue', description: 'Call guests in to dinner'),
      TeamDuty(phase: 'Venue', description: 'Introduce each speaker in order'),
      TeamDuty(phase: 'Venue', description: 'Cue first dance and open the floor'),
      TeamDuty(phase: 'Venue', description: 'Keep evening programme moving — liaise with band/DJ'),
    ],
  ),

  RoleTemplate(
    title: 'Food Coordinator',
    category: 'Coordination',
    icon: Icons.restaurant_outlined,
    linkedVendorCategory: 'Caterer',
    pullsDietary: true,
    defaultDuties: [
      TeamDuty(phase: 'Venue', description: 'Meet caterer on arrival, confirm dietary requirements'),
      TeamDuty(phase: 'Venue', description: 'Ensure dietary guests receive correct meals'),
      TeamDuty(phase: 'Venue', description: 'Liaise between caterer and MC for meal timing'),
      TeamDuty(phase: 'General', description: 'Have dietary breakdown list on hand throughout day'),
    ],
  ),

  RoleTemplate(
    title: 'Music Coordinator',
    category: 'Coordination',
    icon: Icons.music_note_outlined,
    linkedVendorCategory: 'Band / DJ',
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Brief church musician on order of service and music cues'),
      TeamDuty(phase: 'Venue', description: 'Meet band/DJ on arrival, confirm setlist and timing'),
      TeamDuty(phase: 'Venue', description: 'Cue first dance song with band/DJ'),
      TeamDuty(phase: 'Venue', description: 'Manage any song requests from couple'),
    ],
  ),

  RoleTemplate(
    title: 'Transport Coordinator',
    category: 'Coordination',
    icon: Icons.directions_car_outlined,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Ensure bridal cars arrive on time and are ready'),
      TeamDuty(phase: 'Church', description: 'Coordinate buses/coaches for guests'),
      TeamDuty(phase: 'Venue', description: 'Direct guests to car park and shuttle bus'),
      TeamDuty(phase: 'General', description: 'Have all driver contact numbers on hand'),
    ],
  ),

  RoleTemplate(
    title: 'Photographer Liaison',
    category: 'Coordination',
    icon: Icons.camera_alt_outlined,
    linkedVendorCategory: 'Photographer',
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Point out key family members to photographer'),
      TeamDuty(phase: 'Church', description: 'Organise group photo line-up after ceremony'),
      TeamDuty(phase: 'Venue', description: 'Ensure group photo list is completed before dinner'),
      TeamDuty(phase: 'General', description: 'Carry and hand over group photo list to photographer'),
    ],
  ),

  RoleTemplate(
    title: 'Gift Coordinator',
    category: 'Coordination',
    icon: Icons.card_giftcard_outlined,
    defaultDuties: [
      TeamDuty(phase: 'Venue', description: 'Set up gift table at venue entrance'),
      TeamDuty(phase: 'Venue', description: 'Collect and securely store cards and gifts during the evening'),
      TeamDuty(phase: 'Venue', description: 'Transfer gifts to couple\'s car / safe location at end of night'),
    ],
  ),

  // ── Family ───────────────────────────────────────────────────────────────

  RoleTemplate(
    title: 'Father of the Bride',
    category: 'Family',
    icon: Icons.person_outline,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Escort bride down the aisle'),
      TeamDuty(phase: 'Venue', description: 'Deliver father-of-the-bride speech'),
    ],
  ),

  RoleTemplate(
    title: 'Mother of the Bride',
    category: 'Family',
    icon: Icons.person_outline,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Arrive at church before bride, seated in front row'),
      TeamDuty(phase: 'Venue', description: 'Support bride throughout the day'),
    ],
  ),

  RoleTemplate(
    title: 'Father of the Groom',
    category: 'Family',
    icon: Icons.person_outline,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Arrive at church with mother of the groom, seated in front row'),
      TeamDuty(phase: 'Venue', description: 'Deliver speech / toast at reception'),
    ],
  ),

  RoleTemplate(
    title: 'Mother of the Groom',
    category: 'Family',
    icon: Icons.person_outline,
    defaultDuties: [
      TeamDuty(phase: 'Church', description: 'Arrive at church with family, seated in front row'),
      TeamDuty(phase: 'Venue', description: 'Support groom throughout the day'),
    ],
  ),
];

/// All unique category names in display order
const List<String> kRoleCategories = [
  'Bridal Party',
  'Ceremony',
  'Coordination',
  'Family',
];
