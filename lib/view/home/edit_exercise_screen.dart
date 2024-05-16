import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_routines_app/model/user_exercise_model.dart';
import 'package:workout_routines_app/state/add_exercise/add_exercise_provider.dart';
import 'package:workout_routines_app/state/edit_exercise/edit_exercise_provider.dart';
import 'package:workout_routines_app/state/exercise/model/exercise_model.dart';
import 'package:workout_routines_app/state/exercise/provider/exercise_provider.dart';
import 'package:workout_routines_app/utils/utils.dart';
import 'package:workout_routines_app/view/exercise/widget/equipments_filter_bottom_sheet.dart';
import 'package:workout_routines_app/view/home/widget/search_textfield.dart';

class EditExerciseScreen extends HookConsumerWidget {
  final UserExerciseModel userExercise;
  final int index;
  const EditExerciseScreen({
    super.key,
    required this.userExercise,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseData = ref.watch(exerciseProvider).exerciseData;
    final isLoadng = ref.watch(exerciseProvider).isLoading;
    Box<UserExerciseModel> userExercises =
        Hive.box(ConstantString.userExerciseBox);

    final searchTextController = useTextEditingController();
    final isFiltered = useState(false);
    final showFilters = useState(false);
    final searchResult = useState(<ExerciseData>[]);
    final selectedId = useState(userExercise.exerciseId);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(exerciseProvider.notifier).getExerciseData();
      });

      return;
    }, []);

    'Data length -> ${exerciseData.length}'.log();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: AppColor.transparent,
        title: const Text(
          "Add exercise",
          style: TextStyle(
            color: AppColor.black,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              showFilters.value = !showFilters.value;

              if (!showFilters.value) {
                isFiltered.value = false;
              }
            },
            icon: Icon(
              showFilters.value
                  ? Icons.filter_list_off_rounded
                  : Icons.filter_list_rounded,
              color: AppColor.black,
            ),
          ),
        ],
      ),
      body: isLoadng
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColor.yellow,
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: getSizeWidth(context, 4),
                    right: getSizeWidth(context, 4),
                    top: getSizeHeight(context, 2),
                    bottom: getSizeHeight(context, 1.5),
                  ),
                  child: SearchTextfield(
                    controller: searchTextController,
                    onChange: (value) {
                      isFiltered.value = value!.isNotEmpty;

                      searchResult.value = exerciseData
                          .where((element) => element.name!
                              .toLowerCase()
                              .contains(value.toLowerCase()))
                          .toList();
                    },
                  ),
                ),

                if (showFilters.value)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: getSizeWidth(context, 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildFilterChips(
                          context,
                          onTap: () async {
                            final equipments =
                                getEquipmentsList(exerciseData: exerciseData);

                            final result =
                                await showModalBottomSheet<List<String>>(
                              context: context,
                              builder: (context) {
                                return EquipmentsFilterBottomSheet(
                                  selectedId: const [],
                                  equipmentsList: equipments,
                                );
                              },
                            );

                            if (result == null) return;
                            if (result.isEmpty) return;

                            searchResult.value = getFilteredList(
                              exerciseData: exerciseData,
                              filteredData: searchResult.value,
                              selectedId: result,
                            );

                            isFiltered.value = true;
                          },
                          title: "Equipments",
                        ),
                        buildFilterChips(
                          context,
                          onTap: () {},
                          title: "Main muscle",
                        ),
                        buildFilterChips(
                          context,
                          onTap: () {},
                          title: "Secondary muscle",
                        ),
                        buildFilterChips(
                          context,
                          onTap: () {},
                          title: "Categories",
                        ),
                      ].addHSpacing(getSizeWidth(context, 2)),
                    ),
                  ),

                //
                Expanded(
                  child: ListView.builder(
                    itemCount: isFiltered.value
                        ? searchResult.value.length
                        : exerciseData.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(
                        bottom: getSizeHeight(context, 2),
                        left: getSizeWidth(context, 4),
                        right: getSizeWidth(context, 4),
                        top: getSizeHeight(context, 1.5)),
                    itemBuilder: (context, index) {
                      final exercise = isFiltered.value
                          ? searchResult.value[index]
                          : exerciseData[index];
                      return Card(
                        color: AppColor.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0.1,
                        child: ListTile(
                          onTap: () {
                            if (selectedId.value.contains(exercise.id!)) {
                              selectedId.value = List.from(selectedId.value)
                                ..remove(exercise.id!);
                            } else {
                              selectedId.value = List.from(selectedId.value)
                                ..add(exercise.id!);
                            }
                          },
                          leading: exercise.angle0Image != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(
                                    imageUrl: exercise.angle0Image!,
                                    height: 40,
                                    width: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : null,
                          title: Text(exercise.name!),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: getSizeWidth(context, 4),
                          ),
                          trailing: Container(
                            height: 24,
                            width: 24,
                            decoration: BoxDecoration(
                              color: selectedId.value.contains(exercise.id!)
                                  ? AppColor.darkYellow
                                  : null,
                              border: selectedId.value.contains(exercise.id!)
                                  ? Border.all(color: AppColor.darkYellow)
                                  : Border.all(color: AppColor.grey2),
                              shape: BoxShape.circle,
                            ),
                            child: selectedId.value.contains(exercise.id!)
                                ? const Icon(
                                    Icons.check,
                                    color: AppColor.white,
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: selectedId.value.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                var uuid = const Uuid();
                final userExercise = UserExerciseModel(
                  id: uuid.v4(),
                  workOutName: this.userExercise.workOutName,
                  createdAt: this.userExercise.createdAt,
                  exerciseId: selectedId.value,
                );

                final addExercideModel = AddExerciseModel(
                  exerciseBox: userExercises,
                  model: userExercise,
                  context: context,
                );

                final updateModel = UpdateExerciseModel(
                  addExerciseModel: addExercideModel,
                  index: index,
                );

                ref.read(editExerciseProvider(updateModel));
              },
              backgroundColor: AppColor.black,
              icon: const Icon(
                Icons.edit_rounded,
                color: AppColor.white,
              ),
              label: const Text(
                "Edit",
                style: TextStyle(
                  color: AppColor.white,
                ),
              ),
            ),
    );
  }

  GestureDetector buildFilterChips(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              title,
            ),
            1.0.toHSB(context),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColor.black,
            )
          ],
        ),
      ),
    );
  }

  List<Equipments> getEquipmentsList({
    required List<ExerciseData> exerciseData,
  }) {
    final equipments = <Equipments>[];

    for (final exercise in exerciseData) {
      for (final equipment in exercise.equipments!) {
        if (equipments.contains(equipment)) {
          "Here".log();
          continue;
        } else {
          equipments.add(equipment);
        }
      }
    }

    return equipments;
  }

  List<ExerciseData> getFilteredList({
    required List<ExerciseData> exerciseData,
    required List<ExerciseData> filteredData,
    required List<String> selectedId,
  }) {
    List<ExerciseData> finalExerciseData = <ExerciseData>[];

    if (filteredData.isEmpty) {
      for (final exercise in exerciseData) {
        for (final equipment in exercise.equipments!) {
          if (selectedId.contains(equipment.id)) {
            finalExerciseData.add(exercise);
          }
        }
      }
    } else {
      for (final exercise in filteredData) {
        for (final equipment in exercise.equipments!) {
          if (selectedId.contains(equipment.id)) {
            finalExerciseData.add(exercise);
          }
        }
      }
    }
    return finalExerciseData;
  }
}
