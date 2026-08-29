import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:family_expense_management/data/constant/enums.dart';
import 'package:family_expense_management/style/colors.dart';
import 'package:family_expense_management/style/spaces.dart';
import 'package:family_expense_management/style/text_style.dart';

/// Two-option chip selector for [AccountRole].
///
/// The Arabic labels are display-only; the value handed back to the caller is
/// the enum, never the localized string.
class AccountTypeSelector extends StatelessWidget {
  final AccountRole value;
  final ValueChanged<AccountRole> onChanged;

  const AccountTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("auth.account_type".tr(), style: TextStyleApp.authFieldLabel),
        Spaces.height8,
        Row(
          children: [
            Expanded(
              child: _RoleChip(
                key: const Key('auth_role_parent'),
                label: "auth.parent".tr(),
                icon: Icons.supervisor_account_outlined,
                selected: value == AccountRole.parent,
                onTap: () => onChanged(AccountRole.parent),
              ),
            ),
            Spaces.width12,
            Expanded(
              child: _RoleChip(
                key: const Key('auth_role_member'),
                label: "auth.family_member".tr(),
                icon: Icons.person_add_alt_1_outlined,
                selected: value == AccountRole.member,
                onTap: () => onChanged(AccountRole.member),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? ColorsApp.primaryGreen : ColorsApp.white,
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          height: 46.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected ? ColorsApp.primaryGreen : ColorsApp.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18.r,
                color: selected ? ColorsApp.white : ColorsApp.navy,
              ),
              Spaces.width6,
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selected
                      ? TextStyleApp.authChipSelected
                      : TextStyleApp.authChipUnselected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
