  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';
  import 'schedule.dart' as sch;
  import 'scheduledetail.dart';

  final supabase = Supabase.instance.client;

  class WorkPeriodWorker {
    final int workPeriodId;
    final int workerId;

    WorkPeriodWorker({
      required this.workPeriodId,
      required this.workerId,
    });

    factory WorkPeriodWorker.fromMap(Map<String, dynamic> map) { //fromMap used to get data from database
      return WorkPeriodWorker(
        workPeriodId: map['work_period_id'] as int, //ensure is int
        workerId: map['worker_id'] as int,
      );
    }

    Map<String, dynamic> toMap() { //convert back to map (for saving)
      return {
        'work_period_id': workPeriodId,
        'worker_id': workerId,
      };
    }
  }

  class WorkSchedulerPage extends StatefulWidget {
    final String staffId;

    const WorkSchedulerPage({super.key, required this.staffId});

    @override
    State<WorkSchedulerPage> createState() => _WorkSchedulerPageState();
  }

  class _WorkSchedulerPageState extends State<WorkSchedulerPage> {
    final TextEditingController _searchController = TextEditingController();
    String get _currentStaffId => widget.staffId;

    final List<sch.Schedule> _allSchedules = [];
    List<sch.Schedule> _filteredSchedules = [];

    int get _nextId =>
        _allSchedules.isEmpty
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
            s.createdBy.toLowerCase().contains(query))
            .toList();
      });
    }

    Future<void> _loadSchedulesFromSupabase() async {
      try {
        final response = await supabase
            .from('Schedule')
            .select()
            .order('id', ascending: true);

        if (response.isEmpty) {
          setState(() {
            _allSchedules.clear();
            _filteredSchedules.clear();
          });
          return;
        }

        // Fetch all workers once
        final allWorkersResponse = await supabase.from('Worker').select();
        final allWorkers = (allWorkersResponse as List).map<sch.Worker>((w) {
          return sch.Worker(
            id: w['id'] as int,
            name: w['name'] as String,
            totalWorkHours: (w['total_work_hours'] as num?)?.toDouble() ?? 0,
          );
        }).toList();

        List<sch.Schedule> schedules = [];

        for (var row in response) {
          final scheduleId = row['id'] as int;

          // Fetch work periods for this schedule
          final workPeriodRows = await supabase
              .from('Work_Periods')
              .select()
              .eq('schedule_id', scheduleId);

          List<sch.WorkPeriod> workPeriods = [];

          for (var wpRow in workPeriodRows) {
            final wpId = wpRow['id'] as int;

            // Parse start/end times
            final startParts = (wpRow['start_time'] as String).split(':');
            final endParts = (wpRow['end_time'] as String).split(':');

            // Fetch related worker IDs
            final wpWorkers = await supabase
                .from('Work_Periods_Worker')
                .select('worker_id')
                .eq('work_period_id', wpId);

            final workerIds = wpWorkers.map<int>((w) => w['worker_id'] as int).toList();

            // Filter allWorkers locally
            final workers = allWorkers.where((w) => workerIds.contains(w.id)).toList();

            workPeriods.add(
              sch.WorkPeriod(
                id: wpRow['id'] as int,
                startTime: TimeOfDay(
                  hour: int.parse(startParts[0]),
                  minute: int.parse(startParts[1]),
                ),
                endTime: TimeOfDay(
                  hour: int.parse(endParts[0]),
                  minute: int.parse(endParts[1]),
                ),
                workerIds: workerIds,
                workers: workers,
              ),
            );

            debugPrint('WorkPeriod $wpId workers: ${workers.map((w) => w.id).toList()}');
          }

          schedules.add(
            sch.Schedule(
              id: scheduleId,
              name: row['name'] ?? '',
              dateCreated: DateTime.parse(row['date_created']),
              createdBy: row['created_by'] ?? 'Unknown',
              startDate: row['effective_start'] != null
                  ? DateTime.parse(row['effective_start'])
                  : null,
              endDate: row['effective_end'] != null
                  ? DateTime.parse(row['effective_end'])
                  : null,
              description: row['description'] ?? '',
              workPeriods: workPeriods,
            ),
          );
        }

        setState(() {
          _allSchedules
            ..clear()
            ..addAll(schedules);
          _filteredSchedules = List.from(_allSchedules);
        });
      } catch (e) {
        debugPrint("Error loading schedules: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading schedules: $e")),
          );
        }
      }
    }

    Future<void> _addScheduleToSupabase(sch.Schedule schedule) async {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add schedule")),
          );
          return;
        }

        final scheduleId = response[0]['id'];

        for (var wp in schedule.workPeriods) {
          // Insert work period
          final wpResponse = await supabase.from('Work_Periods').insert({
            'schedule_id': scheduleId,
            'start_time': '${wp.startTime!.hour}:${wp.startTime!.minute}:00',
            'end_time': '${wp.endTime!.hour}:${wp.endTime!.minute}:00',
          }).select();

          final workPeriodId = wpResponse[0]['id'];
          // Assign the generated ID to the local object
          wp.id = workPeriodId;

          // Calculate duration
          final start = Duration(
              hours: wp.startTime!.hour, minutes: wp.startTime!.minute);
          var end = Duration(
              hours: wp.endTime!.hour, minutes: wp.endTime!.minute);
          if (end < start) {
            end += const Duration(days: 1); // overnight shift
          }
          final duration = end - start;
          final hours = duration.inMinutes / 60.0;

          // Insert worker relationships + update worker hours
          for (var workerId in wp.workerIds) {
            // Insert relation
            await supabase.from('Work_Periods_Worker').insert({
              'work_period_id': workPeriodId,
              'worker_id': workerId,
            });

            // Fetch current total
            final workerResponse = await supabase
                .from('Worker')
                .select('total_work_hours')
                .eq('id', workerId)
                .maybeSingle();

            double currentHours = 0.0;
            if (workerResponse != null &&
                workerResponse['total_work_hours'] != null) {
              currentHours =
                  (workerResponse['total_work_hours'] as num).toDouble();
            }

            // Update worker total
            await supabase.from('Worker').update({
              'total_work_hours': currentHours + hours,
            }).eq('id', workerId);
          }
        }

        // Reload schedules from Supabase so everything (including worker hours) is up-to-date
        await _loadSchedulesFromSupabase();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Schedule added successfully!")),
        );

      } catch (e) {
        debugPrint("Error adding schedule: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    void _showAddScheduleDialog() async{
      // Fetch workers first
      final workersResponse = await supabase.from('Worker').select();

      List<sch.Worker> workerList = [];
      workerList = (workersResponse as List).map((w) => sch.Worker(
        id: w['id'] as int,
        name: w['name'] as String,
        totalWorkHours: (w['total_work_hours'] as num?)?.toDouble() ?? 0,
      )).toList();

      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate;
      final nameController = TextEditingController();
      final descController = TextEditingController();
      final List<sch.WorkPeriod> workPeriods = [sch.WorkPeriod()];
      final List<TextEditingController> workerControllers = [
        TextEditingController()
      ];
      String? errorMessage;

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
                          // Inline error banner
                          if (errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              color: Colors.red,
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          const SizedBox(height: 8),

                          Text("ID: $_nextId"),
                          Text("Date Created: ${now.toLocal().toString().split(
                              ' ')[0]}"),
                          Text("Created By: $_currentStaffId"),
                          const SizedBox(height: 10),

                          TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                                labelText: "Schedule Name"),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final initial = startDate ?? now;
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initial,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setStateDialog(() => startDate = picked);

                                      // Automatically adjust endDate if it is before startDate
                                      if (endDate != null && endDate!.isBefore(picked)) {
                                        setStateDialog(() => endDate = picked);
                                      }

                                      // Clear any previous error
                                      setStateDialog(() => errorMessage = null);
                                    }
                                  },
                                  child: Text(
                                    startDate == null
                                        ? "Start Date"
                                        : startDate!.toLocal().toString().split(' ')[0],
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

  // END DATE PICKER
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (startDate == null) {
                                      setStateDialog(() => errorMessage = "Please select start date first");
                                      return;
                                    }

                                    final first = startDate!;
                                    final initial = endDate ?? first; // make sure initial >= first
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initial,
                                      firstDate: first,
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setStateDialog(() {
                                        endDate = picked;
                                        errorMessage = null; // clear previous error
                                      });
                                    }
                                  },
                                  child: Text(
                                    endDate == null
                                        ? "End Date"
                                        : endDate!.toLocal().toString().split(' ')[0],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          TextField(
                            controller: descController,
                            decoration: const InputDecoration(
                                labelText: "Work Description"),
                          ),
                          const SizedBox(height: 20),

                          // WORK PERIODS
                          Column(
                            children: List.generate(workPeriods.length, (i) {
                              final period = workPeriods[i];
                              if (workerControllers.length <= i) {
                                workerControllers.add(TextEditingController());
                              }

                              // always sync the workerIds -> input text
                              workerControllers[i].text =
                                  period.workerIds.join(", ");

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
                                              initialTime: period.startTime ??
                                                  TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              setStateDialog(() =>
                                              period.startTime = picked);
                                            }
                                          },
                                          child: Text(period.startTime == null
                                              ? "Select Start Time"
                                              : "Start: ${period.startTime!
                                              .format(context)}"),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final picked = await showTimePicker(
                                              context: context,
                                              initialTime: period.endTime ??
                                                  TimeOfDay.now(),
                                            );
                                            if (picked != null) {
                                              setStateDialog(() =>
                                              period.endTime = picked);
                                            }
                                          },
                                          child: Text(period.endTime == null
                                              ? "Select End Time"
                                              : "End: ${period.endTime!.format(
                                              context)}"),
                                        ),
                                      ),
                                    ],
                                  ),

                                  ElevatedButton(
                                    onPressed: () async {
                                      final selected = await showDialog<List<int>>(
                                        context: context,
                                        builder: (context) {
                                          List<int> tempSelected = List.from(period.workerIds);

                                          return StatefulBuilder(
                                            builder: (context, setStateInner) {
                                              return AlertDialog(
                                                title: const Text('Select Workers'),
                                                content: SizedBox(
                                                  width: double.maxFinite,
                                                  child: ListView(
                                                    children: workerList.map((w) {
                                                      return CheckboxListTile(
                                                        title: Text("${w.id} - ${w.name}"),
                                                        value: tempSelected.contains(w.id),
                                                        onChanged: (checked) {
                                                          setStateInner(() {
                                                            if (checked == true) {
                                                              tempSelected.add(w.id);
                                                            } else {
                                                              tempSelected.remove(w.id);
                                                            }
                                                          });
                                                        },
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, tempSelected),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );

                                      if (selected != null) {
                                        setStateDialog(() {
                                          period.workerIds = selected;
                                        });
                                      }
                                    },
                                    child: Text(period.workerIds.isEmpty
                                        ? 'Select Workers'
                                        : 'Selected: ${period.workerIds.join(', ')}'),
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
                                          icon: const Icon(
                                              Icons.delete, color: Colors.red),
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
                                workPeriods.add(sch.WorkPeriod());
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
                      // VALIDATION
                      if (nameController.text
                          .trim()
                          .isEmpty) {
                        setStateDialog(() =>
                        errorMessage = "Schedule name cannot be empty");
                        return;
                      }
                      if (startDate == null || endDate == null) {
                        setStateDialog(() =>
                        errorMessage =
                        "Effective start and end dates cannot be empty");
                        return;
                      }
                      if (workPeriods.isEmpty) {
                        setStateDialog(() =>
                        errorMessage = "Work periods cannot be empty");
                        return;
                      }
                      for (var wp in workPeriods) {
                        if (wp.startTime == null || wp.endTime == null) {
                          setStateDialog(() =>
                          errorMessage =
                          "Start time and end time must be selected");
                          return;
                        }
                        if (wp.startTime == wp.endTime) {
                          setStateDialog(() =>
                          errorMessage =
                          "Start time and end time cannot be the same");
                          return;
                        }
                        if (wp.workerIds.isEmpty) {
                          setStateDialog(() =>
                          errorMessage = "Worker IDs cannot be empty");
                          return;
                        }
                      }

  // Overlap validation
                      for (int i = 0; i < workPeriods.length; i++) {
                        final wp1 = workPeriods[i];

                        // Convert start/end to Duration in minutes
                        Duration start1 = Duration(hours: wp1.startTime!.hour, minutes: wp1.startTime!.minute);
                        Duration end1 = Duration(hours: wp1.endTime!.hour, minutes: wp1.endTime!.minute);
                        if (end1 <= start1) end1 += const Duration(days: 1); // handle overnight

                        for (int j = i + 1; j < workPeriods.length; j++) {
                          final wp2 = workPeriods[j];
                          Duration start2 = Duration(hours: wp2.startTime!.hour, minutes: wp2.startTime!.minute);
                          Duration end2 = Duration(hours: wp2.endTime!.hour, minutes: wp2.endTime!.minute);
                          if (end2 <= start2) end2 += const Duration(days: 1); // handle overnight

                          bool overlap = start1 < end2 && end1 > start2;

                          if (overlap) {
                            setStateDialog(() =>
                            errorMessage = "Work periods cannot overlap (period ${i + 1} conflicts with period ${j + 1})");
                            return;
                          }
                        }
                      }

                      // Clear error
                      setStateDialog(() => errorMessage = null);

                      final schedule = sch.Schedule(
                        id: _nextId,
                        name: nameController.text.trim(),
                        dateCreated: DateTime.now(),
                        createdBy: _currentStaffId,
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
      return DefaultTabController(
        length: 2, // two tabs
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Work Scheduler Page"),
            centerTitle: true,
            bottom: const TabBar(
              tabs: [
                Tab(text: "Schedules", icon: Icon(Icons.schedule)),
                Tab(text: "Workers", icon: Icon(Icons.people)),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              // --- TAB 1: SCHEDULES ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Schedule List",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text("Work Schedule",
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Name: ${s.name}\n"
                                    "Created by: ${s.createdBy}\n"
                                    "Date Created: ${s.dateCreated
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0]}\n"
                                    "Effective Period: "
                                    "${s.startDate != null
                                    ? s.startDate!.toLocal().toString().split(
                                    ' ')[0]
                                    : '-'} to "
                                    "${s.endDate != null ? s.endDate!
                                    .toLocal()
                                    .toString()
                                    .split(' ')[0] : '-'}",
                              ),
                              onTap: () async {
                                final deleted = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleDetailPage(schedule: s),
                                  ),
                                );

                                // Re-fetch all schedules if a schedule was deleted
                                if (deleted == true) {
                                  await _loadSchedulesFromSupabase();
                                }
                              },

                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // --- TAB 2: WORKERS ---
              FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase.from('Worker').select(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("Error: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red)));
                  }
                  final workers = snapshot.data ?? [];
                  // Sort descending by total_work_hours
                  workers.sort((a, b) {
                    double hoursA = (a['total_work_hours'] as num?)?.toDouble() ?? 0;
                    double hoursB = (b['total_work_hours'] as num?)?.toDouble() ?? 0;
                    return hoursB.compareTo(hoursA); // descending
                  });
                  if (workers.isEmpty) {
                    return const Center(child: Text("No workers found"));
                  }
                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final w = workers[index];
                      double totalHours = (w['total_work_hours'] as num?)?.toDouble() ?? 0;

                      // Convert decimal hours to hours + minutes
                      final hours = totalHours.floor();
                      final minutes = ((totalHours - hours) * 60).round();

                      // Check if over 8 hours
                      final isOver = totalHours > 8;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOver ? Colors.red[200] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOver ? Colors.red.shade400 : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${w['name'] ?? 'Unnamed'} (ID: ${w['id']})",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("${hours}h ${minutes}m",
                                style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

            ],
          ),
        ),
      );
    }


  }