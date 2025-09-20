import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'scheduledetail.dart';

final supabase = Supabase.instance.client;

class WorkPeriod {
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String workerIds;

  WorkPeriod({this.startTime, this.endTime, this.workerIds = ""});

  List<String> get workerIdsList =>
      workerIds.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

class Schedule {
  final int id;
  final String name;
  final DateTime dateCreated;
  final String createdBy;
  final DateTime? startDate;
  final DateTime? endDate;
  final String description;
  final List<WorkPeriod> workPeriods;

  Schedule({
    required this.id,
    required this.name,
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
  final String _currentUser = "Admin";

  final List<Schedule> _allSchedules = [];
  List<Schedule> _filteredSchedules = [];

  int get _nextId => _allSchedules.isEmpty
      ? 1
      : _allSchedules.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterSchedules);
    _loadSchedulesFromSupabase();
  }

  void _filterSchedules() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSchedules = _allSchedules
          .where((s) =>
          s.id.toString().contains(query) ||
          s.name.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query) ||
          s.createdBy.toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _loadSchedulesFromSupabase() async {
    try {
      final response = await supabase.from('Schedule').select().order('id', ascending: true);
      if (response.isEmpty) {
        setState(() {
          _allSchedules.clear();
          _filteredSchedules.clear();
        });
        return;
      }

      List<Schedule> schedules = [];
      for (var row in response) {
        final scheduleId = row['id'] as int;

        final workPeriodRows = await supabase
            .from('Work_Periods')
            .select()
            .eq('schedule_id', scheduleId);

        final workPeriods = workPeriodRows.map<WorkPeriod>((wpRow) {
          final startParts = (wpRow['start_time'] as String).split(':');
          final endParts = (wpRow['end_time'] as String).split(':');

          return WorkPeriod(
            startTime: TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1])),
            endTime: TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1])),
            workerIds: wpRow['worker_ids'] ?? "",
          );
        }).toList();

        schedules.add(Schedule(
          id: scheduleId,
          name: row['name'] ?? '',
          dateCreated: DateTime.parse(row['date_created']),
          createdBy: row['created_by'],
          startDate: row['effective_start'] != null ? DateTime.parse(row['effective_start']) : null,
          endDate: row['effective_end'] != null ? DateTime.parse(row['effective_end']) : null,
          description: row['description'] ?? '',
          workPeriods: workPeriods,
        ));
      }

      setState(() {
        _allSchedules.clear();
        _allSchedules.addAll(schedules);
        _filteredSchedules = List.from(_allSchedules);
      });
    } catch (e) {
      debugPrint("Error loading schedules: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading schedules: $e")));
    }
  }

  Future<void> _addScheduleToSupabase(Schedule schedule) async {
    try {
      final response = await supabase.from('Schedule').insert({
        'id': schedule.id,
        'name': schedule.name,
        'date_created': schedule.dateCreated.toIso8601String(),
        'created_by': schedule.createdBy,
        'effective_start': schedule.startDate?.toIso8601String(),
        'effective_end': schedule.endDate?.toIso8601String(),
        'description': schedule.description,
      }).select();

      if (response.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add schedule")));
        return;
      }

      final scheduleId = response[0]['id'];
      for (var wp in schedule.workPeriods) {
        await supabase.from('Work_Periods').insert({
          'schedule_id': scheduleId,
          'start_time': '${wp.startTime!.hour}:${wp.startTime!.minute}',
          'end_time': '${wp.endTime!.hour}:${wp.endTime!.minute}',
          'worker_ids': wp.workerIds,
        });
      }

      setState(() {
        _allSchedules.add(schedule);
        _filterSchedules();
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Schedule added successfully!")));
    } catch (e) {
      debugPrint("Error adding schedule: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showAddScheduleDialog() {
    final pageContext = context;

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final List<WorkPeriod> workPeriods = [WorkPeriod()];
    final List<TextEditingController> workerControllers = [TextEditingController()];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Add Schedule"),
              content: SizedBox(
                width: double.maxFinite,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("ID: $_nextId"),
                        Text("Date Created: ${now.toLocal().toString().split(' ')[0]}"),
                        Text("Created By: $_currentUser"),
                        const SizedBox(height: 10),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(labelText: "Schedule Name"),
                        ),
                        const SizedBox(height: 10),
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
                                  if (picked != null) setStateDialog(() => startDate = picked);
                                },
                                child: Text(startDate == null
                                    ? "Start Date"
                                    : "${startDate!.toLocal().toString().split(' ')[0]}"),
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
                                  if (picked != null) setStateDialog(() => endDate = picked);
                                },
                                child: Text(endDate == null
                                    ? "End Date"
                                    : "${endDate!.toLocal().toString().split(' ')[0]}"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descController,
                          decoration: const InputDecoration(labelText: "Work Description"),
                        ),
                        const SizedBox(height: 20),

                        // WORK PERIODS
                        Column(
                          children: List.generate(workPeriods.length, (i) {
                            final period = workPeriods[i];
                            if (workerControllers.length <= i) workerControllers.add(TextEditingController());
                            workerControllers[i].text = period.workerIds;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: period.startTime ?? TimeOfDay.now(),
                                          );
                                          if (picked != null) setStateDialog(() => period.startTime = picked);
                                        },
                                        child: Text(period.startTime == null
                                            ? "Select Start Time"
                                            : "Start: ${period.startTime!.format(context)}"),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final picked = await showTimePicker(
                                            context: context,
                                            initialTime: period.endTime ?? TimeOfDay.now(),
                                          );
                                          if (picked != null) setStateDialog(() => period.endTime = picked);
                                        },
                                        child: Text(period.endTime == null
                                            ? "Select End Time"
                                            : "End: ${period.endTime!.format(context)}"),
                                      ),
                                    ),
                                  ],
                                ),
                                TextField(
                                  controller: workerControllers[i],
                                  decoration: const InputDecoration(
                                      labelText: "Worker IDs (comma separated)"),
                                  onChanged: (val) => period.workerIds = val,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (workPeriods.length > 1)
                                      IconButton(
                                        onPressed: () {
                                          setStateDialog(() {
                                            workPeriods.removeAt(i);
                                            workerControllers.removeAt(i);
                                          });
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                      ),
                                  ],
                                ),
                                const Divider(),
                              ],
                            );
                          }),
                        ),

                        ElevatedButton.icon(
                          onPressed: () {
                            setStateDialog(() {
                              workPeriods.add(WorkPeriod());
                              workerControllers.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add Work Period"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    // VALIDATION with SnackBars
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                          const SnackBar(content: Text("Schedule name cannot be empty")));
                      return;
                    }
                    if (startDate == null || endDate == null) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                          const SnackBar(content: Text("Effective start and end dates cannot be empty")));
                      return;
                    }
                    if (workPeriods.isEmpty) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                          const SnackBar(content: Text("Work periods cannot be empty")));
                      return;
                    }
                    for (var wp in workPeriods) {
                      if (wp.startTime == null || wp.endTime == null) {
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(content: Text("Start time and end time must be selected")));
                        return;
                      }
                      if (wp.startTime == wp.endTime) {
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(content: Text("Start time and end time cannot be the same")));
                        return;
                      }
                      if (wp.workerIds.trim().isEmpty) {
                        ScaffoldMessenger.of(pageContext).showSnackBar(
                            const SnackBar(content: Text("Worker IDs cannot be empty")));
                        return;
                      }
                    }

                    final schedule = Schedule(
                      id: _nextId,
                      name: nameController.text.trim(),
                      dateCreated: DateTime.now(),
                      createdBy: _currentUser,
                      startDate: startDate,
                      endDate: endDate,
                      description: descController.text.trim(),
                      workPeriods: workPeriods,
                    );

                    Navigator.pop(context);
                    await _addScheduleToSupabase(schedule);
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Work Scheduler Page"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Schedule List", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Work Schedule", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search schedule...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _showAddScheduleDialog,
                icon: const Icon(Icons.add),
                label: const Text("Add"),
              ),
            ),
            const SizedBox(height: 16),
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
                      title: Text(
                        "ID: ${s.id}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Name: ${s.name}\n"
                            "Created by: ${s.createdBy}\n"
                            "Date Created: ${s.dateCreated.toLocal().toString().split(' ')[0]}\n"
                            "Effective Period: "
                            "${s.startDate != null ? s.startDate!.toLocal().toString().split(' ')[0] : '-'} to "
                            "${s.endDate != null ? s.endDate!.toLocal().toString().split(' ')[0] : '-'}",
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScheduleDetailPage(schedule: s),
                        ),
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

