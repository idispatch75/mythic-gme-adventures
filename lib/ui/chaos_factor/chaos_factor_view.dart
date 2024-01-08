import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/header.dart';
import 'chaos_factor.dart';

class ChaosFactorView extends GetView<ChaosFactorService> {
  final bool dense;

  const ChaosFactorView({this.dense = false, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        children: [
          const Header('Chaos Factor'),
          SizedBox(
            height: dense ? 45 : 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: controller.decrement,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Obx(
                    () => Center(
                      child: Text(
                        controller.chaosFactor.toString(),
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.increment,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
