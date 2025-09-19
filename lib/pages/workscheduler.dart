import 'package:flutter/material.dart';

class WorkPeriod {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> workerIds;

  WorkPeriod({
    required this.startTime,
    required this.endTime,
    required this.workerIds,
  });
}

class Schedule {
  final int id;
  final DateTime dateCreated;
  final String createdBy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final List<WorkPeriod> workPeriods;

  Schedule({
    required this.id,
    required this.dateCreated,
    required this.createdBy,
    this.startDate,
    this.endDate,
    this.description = "",
    this.workPeriods = const [],
  });
}

class WorkSchedulerPage extends StatefulWidget {
  const WorkSchedulerPage({super.key});

  @override
  State<WorkSchedulerPage> createState() => _WorkSchedulerPageState();
}

class _WorkSchedulerPageState extends State<WorkSchedulerPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  List<TextEditingController> workerControllers = [];

  final String _currentUser = "Admin"; //auto-filled creator (change ltr)

  final List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];

  int get _nextId {
    if (_allSchedules.isEmpty) return 1;
    return _allSchedules.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  @override
  void initState() {
    super.initState();
    _filteredSchedules = List.from(_allSchedules);
    _searchController.addListener(_filterSchedules);
  }

  void _filterSchedules() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSchedules = _allSchedules
          .where((s) =>
      s.description.toLowerCase().contains(query) ||
          s.createdBy.toLowerCase().contains(query))
          .toList();
    });
  }

  void _addSchedule(Schedule newSchedule) {
    setState(() {
      _allSchedules.add(newSchedule);
      _filterSchedules();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Work Scheduler Page"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Schedule List",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Work Schedule",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search schedule...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child:ElevatedButton.icon(
                onPressed: () {
                  //clear worker fields
                  _descController.clear();
                  for (var c in workerControllers) {
                    c.dispose();
                  }
                  workerControllers.clear();

                  DateTime now = DateTime.now();

                  DateTime? startDate;
                  DateTime? endDate;
                  List<WorkPeriod> tempPeriods = [];

                  showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setDialogState) {
                          return AlertDialog(
                            title: const Text("Add Schedule"),
                            content: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Text("ID: $_nextId"),
                                  Text("Date Created: ${now.toLocal().toString().split(' ')[0]}"),
                                  Text("Created By: $_currentUser"),
                                  const SizedBox(height: 10),

                                  //effective period
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Effective Period",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: now,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setDialogState(() =>
                                              startDate = picked);
                                            }
                                          },
                                          child: Text(startDate == null
                                              ? "Start Date"
                                              : "${startDate!.toLocal()}"
                                              .split(" ")[0]),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final picked = await showDatePicker(
                                              context: context,
                                              initialDate: now,
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );
                                            if (picked != null) {
                                              setDialogState(() =>
                                              endDate = picked);
                                            }
                                          },
                                          child: Text(endDate == null
                                              ? "End Date"
                                              : "${endDate!.toLocal()}"
                                              .split(" ")[0]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  //description
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Description",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  TextField(
                                    controller: _descController,
                                    decoration: const InputDecoration(
                                      labelText: "Work Description",
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  //schedule input
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Work Periods",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  Column(
                                    children: [
                                      for (int i = 0;
                                      i < tempPeriods.length + 1;
                                      i++)
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      final picked =
                                                      await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                        TimeOfDay.now(),
                                                      );
                                                      if (picked != null) {
                                                        setDialogState(() {
                                                          if (i >=
                                                              tempPeriods
                                                                  .length) {
                                                            tempPeriods.add(
                                                              WorkPeriod(
                                                                startTime:
                                                                picked,
                                                                endTime:
                                                                picked,
                                                                workerIds: [],
                                                              ),
                                                            );
                                                            workerControllers
                                                                .add(TextEditingController());
                                                          } else {
                                                            tempPeriods[i] =
                                                                WorkPeriod(
                                                                  startTime: picked,
                                                                  endTime:
                                                                  tempPeriods[i]
                                                                      .endTime,
                                                                  workerIds:
                                                                  tempPeriods[i]
                                                                      .workerIds,
                                                                );
                                                          }
                                                        });
                                                      }
                                                    },
                                                    child: Text(
                                                      i < tempPeriods.length
                                                          ? "Start: ${tempPeriods[i].startTime.format(context)}"
                                                          : "Pick Start",
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      if (i <
                                                          tempPeriods
                                                              .length) {
                                                        final picked =
                                                        await showTimePicker(
                                                          context: context,
                                                          initialTime:
                                                          TimeOfDay.now(),
                                                        );
                                                        if (picked != null) {
                                                          setDialogState(() {
                                                            tempPeriods[i] =
                                                                WorkPeriod(
                                                                  startTime:
                                                                  tempPeriods[i]
                                                                      .startTime,
                                                                  endTime: picked,
                                                                  workerIds:
                                                                  tempPeriods[i]
                                                                      .workerIds,
                                                                );
                                                          });
                                                        }
                                                      }
                                                    },
                                                    child: Text(
                                                      i < tempPeriods.length
                                                          ? "End: ${tempPeriods[i].endTime.format(context)}"
                                                          : "Pick End",
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Worker IDs below
                                            if (i < tempPeriods.length)
                                              TextField(
                                                controller:
                                                workerControllers[i],
                                                decoration:
                                                const InputDecoration(
                                                  labelText:
                                                  "Worker IDs (comma separated)",
                                                ),
                                                onChanged: (value) {
                                                  tempPeriods[i] = WorkPeriod(
                                                    startTime:
                                                    tempPeriods[i]
                                                        .startTime,
                                                    endTime: tempPeriods[i]
                                                        .endTime,
                                                    workerIds: value
                                                        .split(",")
                                                        .map((e) => e.trim())
                                                        .toList(),
                                                  );
                                                },
                                              ),

                                            const Divider(),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _descController.clear();
                                },
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  final schedule = Schedule(
                                    id: _nextId,
                                    dateCreated: now,
                                    createdBy: _currentUser,
                                    startDate: startDate,
                                    endDate: endDate,
                                    description: _descController.text,
                                    workPeriods: tempPeriods,
                                  );
                                  _addSchedule(schedule);

                                  // cleanup
                                  for (var c in workerControllers) {
                                    c.dispose();
                                  }
                                  workerControllers.clear();
                                  _descController.clear();

                                  Navigator.pop(context);
                                  _descController.clear();
                                },
                                child: const Text("Save"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ),
            const SizedBox(height: 16),

            // Schedule list
            Expanded(
              child: _filteredSchedules.isEmpty
                  ? const Center(child: Text("No schedules found"))
                  : ListView.builder(
                itemCount: _filteredSchedules.length,
                itemBuilder: (context, index) {
                  final s = _filteredSchedules[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text("ID: ${s.id} - ${s.description}"),
                      subtitle: Text(
                        "Created by: ${s.createdBy}\n"
                            "Date Created: ${s.dateCreated.toLocal().toString().split(' ')[0]}\n"
                            "Effective Period: "
                            "${s.startDate != null ? s.startDate!.toLocal().toString().split(' ')[0] : '-'}"
                            " to "
                            "${s.endDate != null ? s.endDate!.toLocal().toString().split(' ')[0] : '-'}",
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
