// import 'dart:ui';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import '../utils/app_theme.dart';
//
// class PremiumAccessScreen extends StatefulWidget {
//   const PremiumAccessScreen({super.key});
//
//   @override
//   State<PremiumAccessScreen> createState() => _PremiumAccessScreenState();
// }
//
// class _PremiumAccessScreenState extends State<PremiumAccessScreen> {
//   int _selectedPlanIndex = 1; // Default to yearly
//
//   final List<Map<String, dynamic>> _plans = [
//     {
//       'title': 'Monthly Plan',
//       'price': '\$9.99',
//       'period': '/month',
//       'popular': false,
//     },
//     {
//       'title': 'Yearly Plan',
//       'price': '\$49.99',
//       'period': '/year',
//       'popular': true,
//       'save': 'Save 50%',
//     },
//     {
//       'title': 'Lifetime',
//       'price': '\$99.99',
//       'period': 'one-time',
//       'popular': false,
//     },
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppTheme.getBackgroundColor(context),
//       appBar: AppBar(
//         backgroundColor: AppTheme.getBackgroundColor(context),
//         elevation: 0,
//         leading: IconButton(
//           onPressed: () => Navigator.of(context).pop(),
//           icon: Icon(
//             Icons.arrow_back,
//             color: AppTheme.getTextPrimaryColor(context),
//           ),
//         ),
//         title: Text(
//           'Go Premium',
//           style: GoogleFonts.poppins(
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//             color: AppTheme.getTextPrimaryColor(context),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   Text(
//                     'Unlock Premium Features',
//                     style: GoogleFonts.poppins(
//                       fontSize: 24,
//                       fontWeight: FontWeight.bold,
//                       color: AppTheme.getTextPrimaryColor(context),
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Choose a plan that works best for you',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: AppTheme.getTextSecondaryColor(context),
//                     ),
//                   ),
//
//                   const SizedBox(height: 32),
//
//                   // Plans List
//                   ..._plans.asMap().entries.map((entry) {
//                     final index = entry.key;
//                     final plan = entry.value;
//                     return Padding(
//                       padding: const EdgeInsets.only(bottom: 12),
//                       child: _buildPlanCard(context, plan, index),
//                     );
//                   }).toList(),
//
//                   const SizedBox(height: 32),
//
//                   // Features
//                   Text(
//                     'What\'s Included',
//                     style: GoogleFonts.poppins(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: AppTheme.getTextPrimaryColor(context),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//
//                   _buildFeature('Unlimited bandwidth'),
//                   _buildFeature('Access to all servers'),
//                   _buildFeature('No ads'),
//                   _buildFeature('Priority support'),
//                   _buildFeature('Advanced security'),
//                 ],
//               ),
//             ),
//           ),
//
//           // Continue Button
//           Container(
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: AppTheme.getBackgroundColor(context),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               child: SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Handle continue
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppTheme.getPrimaryColor(context),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: Text(
//                     'Continue',
//                     style: GoogleFonts.poppins(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan, int index) {
//     final isSelected = _selectedPlanIndex == index;
//     final isPopular = plan['popular'] == true;
//
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: () {
//           setState(() {
//             _selectedPlanIndex = index;
//           });
//         },
//         borderRadius: BorderRadius.circular(16),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: AppTheme.getCardColor(context),
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(
//               color: isSelected
//                   ? AppTheme.getPrimaryColor(context)
//                   : (AppTheme.isDarkMode(context) ? AppTheme.borderDark : AppTheme.borderLight),
//               width: isSelected ? 2 : 1,
//             ),
//           ),
//           child: Row(
//             children: [
//               // Radio
//               Container(
//                 width: 24,
//                 height: 24,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: isSelected
//                         ? AppTheme.getPrimaryColor(context)
//                         : AppTheme.getTextSecondaryColor(context),
//                     width: 2,
//                   ),
//                 ),
//                 child: isSelected
//                     ? Center(
//                   child: Container(
//                     width: 12,
//                     height: 12,
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: AppTheme.getPrimaryColor(context),
//                     ),
//                   ),
//                 )
//                     : null,
//               ),
//               const SizedBox(width: 16),
//
//               // Plan Details
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           plan['title'],
//                           style: GoogleFonts.poppins(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: AppTheme.getTextPrimaryColor(context),
//                           ),
//                         ),
//                         if (isPopular) ...[
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: AppTheme.success,
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               'POPULAR',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Text(
//                           plan['price'],
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: AppTheme.getTextSecondaryColor(context),
//                           ),
//                         ),
//                         Text(
//                           ' ${plan['period']}',
//                           style: GoogleFonts.poppins(
//                             fontSize: 12,
//                             color: AppTheme.getTextSecondaryColor(context),
//                           ),
//                         ),
//                         if (plan['save'] != null) ...[
//                           const SizedBox(width: 8),
//                           Text(
//                             plan['save'],
//                             style: GoogleFonts.poppins(
//                               fontSize: 12,
//                               fontWeight: FontWeight.w600,
//                               color: AppTheme.success,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFeature(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           Icon(
//             Icons.check_circle,
//             color: AppTheme.success,
//             size: 20,
//           ),
//           const SizedBox(width: 12),
//           Text(
//             text,
//             style: GoogleFonts.poppins(
//               fontSize: 14,
//               color: AppTheme.getTextPrimaryColor(context),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }