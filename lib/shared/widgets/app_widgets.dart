import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppButton extends StatelessWidget {
  final String label; final VoidCallback? onPressed;
  final bool isLoading, outlined, danger, small;
  final Color? color; final IconData? icon; final double? width;
  const AppButton({super.key, required this.label, this.onPressed,
    this.isLoading=false, this.outlined=false, this.danger=false,
    this.small=false, this.color, this.icon, this.width});
  @override Widget build(BuildContext context) {
    final bg = danger ? AppColors.error : color ?? AppColors.primary;
    final h  = small ? 40.0 : 52.0;
    final content = isLoading
      ? SizedBox(width:18, height:18, child:CircularProgressIndicator(strokeWidth:2, color:outlined?bg:Colors.white))
      : Row(mainAxisSize:MainAxisSize.min, children:[
          if(icon!=null)...[Icon(icon, size:small?16:18, color:outlined?bg:Colors.white), const SizedBox(width:8)],
          Text(label, style:AppText.btnText(color:outlined?bg:Colors.white).copyWith(fontSize:small?13:15)),
        ]);
    if (outlined) return SizedBox(width:width, child:OutlinedButton(
      onPressed:isLoading?null:onPressed,
      style:OutlinedButton.styleFrom(foregroundColor:bg, side:BorderSide(color:bg, width:1.5),
        minimumSize:Size(width??double.infinity, h), elevation:0,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(AppRadius.lg))),
      child:content));
    return SizedBox(width:width, child:ElevatedButton(
      onPressed:isLoading?null:onPressed,
      style:ElevatedButton.styleFrom(backgroundColor:bg, foregroundColor:Colors.white,
        minimumSize:Size(width??double.infinity, h), elevation:0,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(AppRadius.lg))),
      child:content));
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label, hint; final IconData? prefixIcon; final Widget? suffixIcon;
  final bool obscureText, readOnly; final TextInputType? keyboardType;
  final String? Function(String?)? validator; final int maxLines;
  final void Function(String)? onChanged, onFieldSubmitted;
  final VoidCallback? onTap; final TextInputAction? textInputAction;
  final FocusNode? focusNode; final bool autofocus;
  const AppTextField({super.key, this.controller, this.label, this.hint,
    this.prefixIcon, this.suffixIcon, this.obscureText=false, this.readOnly=false,
    this.keyboardType, this.validator, this.maxLines=1,
    this.onChanged, this.onTap, this.textInputAction, this.focusNode,
    this.onFieldSubmitted, this.autofocus=false});
  @override Widget build(BuildContext context) => TextFormField(
    controller:controller, obscureText:obscureText, keyboardType:keyboardType,
    validator:validator, maxLines:maxLines, readOnly:readOnly, autofocus:autofocus,
    onChanged:onChanged, onTap:onTap, textInputAction:textInputAction,
    focusNode:focusNode, onFieldSubmitted:onFieldSubmitted,
    style:AppText.bodyMd(),
    decoration:InputDecoration(labelText:label, hintText:hint,
      prefixIcon:prefixIcon!=null?Icon(prefixIcon, size:20, color:AppColors.textHint):null,
      suffixIcon:suffixIcon));
}

class AdminEmptyState extends StatelessWidget {
  final String title; final String? message; final IconData icon;
  final String? actionLabel; final VoidCallback? onAction;
  const AdminEmptyState({super.key, required this.title, this.message, required this.icon, this.actionLabel, this.onAction});
  @override Widget build(BuildContext ctx) => AppUI.emptyState(title:title, message:message, icon:icon, btnLabel:actionLabel, onBtn:onAction);
}

class AdminPagination extends StatelessWidget {
  final int page, total, limit; final VoidCallback onPrev, onNext;
  const AdminPagination({super.key, required this.page, required this.total, required this.limit, required this.onPrev, required this.onNext});
  @override Widget build(BuildContext context) {
    final pages = (total / limit).ceil();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: AppColors.surface, border: Border(top: BorderSide(color: AppColors.border))),
      child: Row(children: [
        Text('$total results', style: AppText.caption()), const Spacer(),
        IconButton(icon: const Icon(Icons.chevron_left, size: 20), onPressed: page > 1 ? onPrev : null, color: AppColors.primary, disabledColor: AppColors.border),
        Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.full)),
          child: Text('$page / $pages', style: AppText.label(color: Colors.white))),
        IconButton(icon: const Icon(Icons.chevron_right, size: 20), onPressed: page < pages ? onNext : null, color: AppColors.primary, disabledColor: AppColors.border),
      ]));
  }
}

class OrderStatusStepper extends StatelessWidget {
  final String currentStatus;
  const OrderStatusStepper({super.key, required this.currentStatus});
  static const _steps = [
    ('confirmed','Confirmed',Icons.check_circle_outline),
    ('picking','Picking',Icons.inventory_outlined),
    ('packed','Packed',Icons.inventory_2_outlined),
    ('dispatched','Dispatched',Icons.local_shipping_outlined),
    ('out_for_delivery','On Way',Icons.delivery_dining_outlined),
    ('delivered','Delivered',Icons.check_circle),
  ];
  @override Widget build(BuildContext context) {
    if (currentStatus == 'cancelled') return Center(child: AppUI.badge('Cancelled', AppColors.error, icon: Icons.cancel_outlined));
    final ci = _steps.indexWhere((s) => s.$1 == currentStatus);
    return Row(children: _steps.asMap().entries.map((e) {
      final i = e.key; final s = e.value; final done = i <= ci; final act = i == ci;
      return Expanded(child: Row(children: [
        Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 28, height: 28,
            decoration: BoxDecoration(color: done ? AppColors.success : AppColors.surfaceWarm, shape: BoxShape.circle,
              border: Border.all(color: act ? AppColors.success : AppColors.border, width: act ? 2 : 1)),
            child: Icon(s.$3, size: 14, color: done ? Colors.white : AppColors.textHint)),
          const SizedBox(height: 4),
          Text(s.$2, style: AppText.caption(color: done ? AppColors.success : AppColors.textHint), textAlign: TextAlign.center),
        ]),
        if (i < _steps.length - 1)
          Expanded(child: Container(height: 2, color: i < ci ? AppColors.success : AppColors.border)),
      ]));
    }).toList());
  }
}
