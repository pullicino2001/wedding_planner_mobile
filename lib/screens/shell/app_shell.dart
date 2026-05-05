import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  static const _routes = [
    '/home/overview',
    '/home/budget',
    '/home/guests',
    '/home/vendors',
    '/home/timeline',
  ];

  static const _items = [
    _NavItem(icon: Icons.home_outlined, label: 'Home'),
    _NavItem(icon: Icons.euro_outlined, label: 'Budget'),
    _NavItem(icon: Icons.people_outline, label: 'Guests'),
    _NavItem(icon: Icons.store_outlined, label: 'Vendors'),
    _NavItem(icon: Icons.checklist_outlined, label: 'Timeline'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _PillNavBar(
        selectedIndex: selectedIndex,
        items: _items,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _PillNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final ValueChanged<int> onTap;

  const _PillNavBar({
    required this.selectedIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.line),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14281C14),
                blurRadius: 24,
                offset: Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == selectedIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: isActive ? AppColors.primaryGrad : null,
                      boxShadow: isActive
                          ? const [
                              BoxShadow(
                                color: Color(0x80006064),
                                blurRadius: 12,
                                spreadRadius: -4,
                                offset: Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: isActive ? Colors.white : AppColors.inkMute,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : AppColors.inkMute,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
