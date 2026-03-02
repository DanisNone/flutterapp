import 'package:flutter/material.dart';
import 'package:flutterapp/constants/app_colors.dart';

class ConnectionStatus extends StatelessWidget {
  final bool isConnected;
  
  const ConnectionStatus({
    super.key,
    required this.isConnected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? AppColors.online : AppColors.offline,
            boxShadow: [
              BoxShadow(
                color: (isConnected ? AppColors.online : AppColors.offline).withOpacity(0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isConnected ? 'Подключено' : 'Отключено',
          style: TextStyle(
            color: isConnected ? AppColors.online : AppColors.offline,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
