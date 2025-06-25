import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lip_reading/constants/constants.dart';
import 'package:lip_reading/cubit/video_cubit/video_cubit.dart';
import 'package:lip_reading/enum/model_enum.dart';
import 'package:lip_reading/utils/app_colors.dart';

class ModelSelector extends StatefulWidget {
  const ModelSelector({super.key});

  @override
  _ModelSelectorState createState() => _ModelSelectorState();
}

class _ModelSelectorState extends State<ModelSelector> {
  @override
  Widget build(BuildContext context) {
    var cubit = context.read<VideoCubit>();
    final primaryColor = Theme.of(context).colorScheme.secondary;
    final unselectedColor = AppColors.white;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.white, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(Model.values.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Vertical divider between buttons
            return Container(
              height: 30,
              width: 1,
              color: unselectedColor.withOpacity(0.5),
            );
          } else {
            final model = Model.values[index ~/ 2];
            final isSelected = model == cubit.selectedModel;
            final text = words[index ~/ 2];

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    cubit.selectedModel = model;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isSelected ? primaryColor : unselectedColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
