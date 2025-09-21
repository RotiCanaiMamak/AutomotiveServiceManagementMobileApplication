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

    int get _nextId => //getter
        _allSchedules.isEmpty //if schedule is empty
            ? 1                   //return 1
            : _allSchedules.map((s) => s.id) //create a new list based on schedule ID
            .reduce((a, b) => a > b ? a : b) + 1; //.reduce: combine it into single value
                                                      //then compare one by one
                                                      //then return the largest value + 1

    @override
    void initState() {
      super.initState();
      _searchController.addListener(_filterSchedules); //addListener: run the function each time text changes
      _loadSchedulesFromSupabase();
    }

    void _filterSchedules() {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredSchedules = _allSchedules
            .where((s) =>
        s.id.toString().contains(query) || //check by schedule id
            s.name.toLowerCase().contains(query) || //check by schedule name
            s.createdBy.toLowerCase().contains(query)) //check by created by
            .toList(); //converts back to list (so .where can work)
      });
    }

    Future<void> _loadSchedulesFromSupabase() async {
      try {
        final response = await supabase //connects to supabase
            .from('Schedule')
            .select()
            .order('id', ascending: true); //sort in ascending order

        if (response.isEmpty) {
          setState(() {
            _allSchedules.clear(); //clear all list (jz in case there are remaining schedules in the screen)
            _filteredSchedules.clear(); //same thing here
          });
          return;
        }

        final allWorkersResponse = await supabase.from('Worker').select(); //get all workers at once
        final allWorkers = (allWorkersResponse as List).map<sch.Worker>((w) { //<sch.Worker>: to specify the elements are object of schedule class
          return sch.Worker( //converts into sch.Worker object
            id: w['id'] as int,
            name: w['name'] as String,
            totalWorkHours: (w['total_work_hours'] as num?)?.toDouble() ?? 0, //num?: can be int, can be double, can be null
                                                                              //?.toDouble: convert to double only if not null
                                                                              //if value is null, then return 0
          );
        }).toList();

        List<sch.Schedule> schedules = [];

        for (var row in response) {
          final scheduleId = row['id'] as int;

          //get work periods for this specific schedule in the loop
          final workPeriodRows = await supabase
              .from('Work_Periods')
              .select()
              .eq('schedule_id', scheduleId);

          List<sch.WorkPeriod> workPeriods = [];

          for (var wpRow in workPeriodRows) {
            final wpId = wpRow['id'] as int;

            //parse start & end time
            final startParts = (wpRow['start_time'] as String).split(':');
            final endParts = (wpRow['end_time'] as String).split(':');

            //get worker IDs in the work period
            final wpWorkers = await supabase
                .from('Work_Periods_Worker')
                .select('worker_id')
                .eq('work_period_id', wpId); //get only this specific work period

            final workerIds = wpWorkers.map<int>((w) => w['worker_id'] as int).toList(); //store as int

            //filter allWorkers list to get the full worker objects (id, name, total hours)
            final workers = allWorkers.where((w) => workerIds.contains(w.id)).toList();

            //add into list
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
          }

          //add into list
          schedules.add(
            sch.Schedule(
              id: scheduleId,
              name: row['name'] ?? '',
              dateCreated: DateTime.parse(row['date_created']),
              createdBy: row['created_by'] ?? 'Unknown',
              startDate: row['effective_start'] != null
                  ? DateTime.parse(row['effective_start']) //if true
                  : null,                                  //if false
              endDate: row['effective_end'] != null
                  ? DateTime.parse(row['effective_end'])
                  : null,
              description: row['description'] ?? '',
              workPeriods: workPeriods,
            ),
          );
        }

        setState(() {
          _allSchedules //..: call multiple methods on the same object
            ..clear()   //clear all existing schedules
            ..addAll(schedules); //add all the newly fetched schedules
          _filteredSchedules = List.from(_allSchedules); //creates a copy of _allSchedules so they are separate objects
        });
      } catch (e) {
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
          'date_created': schedule.dateCreated.toIso8601String(), //converts into a String format that supabase can store
          'created_by': schedule.createdBy,
          'effective_start': schedule.startDate?.toIso8601String(),
          'effective_end': schedule.endDate?.toIso8601String(),
          'description': schedule.description,
        }).select(); //return the inserted row (to get schedule ID)

        if (response.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add schedule")),
          );
          return;
        }

        final scheduleId = response[0]['id']; //save the new generated ID (for work periods)

        for (var wp in schedule.workPeriods) {
          final wpResponse = await supabase.from('Work_Periods').insert({
            'schedule_id': scheduleId,
            'start_time': '${wp.startTime!.hour}:${wp.startTime!.minute}:00', //!: guarantee the value isnt null
            'end_time': '${wp.endTime!.hour}:${wp.endTime!.minute}:00',
          }).select();

          final workPeriodId = wpResponse[0]['id'];
          wp.id = workPeriodId; //save into workPeriod object

          //calculate total hours
          final start = Duration(
              hours: wp.startTime!.hour, minutes: wp.startTime!.minute);
          var end = Duration(
              hours: wp.endTime!.hour, minutes: wp.endTime!.minute);
          if (end < start) { //if overnight shift
            end += const Duration(days: 1);
          }
          final duration = end - start;
          final hours = duration.inMinutes / 60;

          //insert into associative entity & update worker hours
          for (var workerId in wp.workerIds) {
            //associative entity for worker and workPeriods
            await supabase.from('Work_Periods_Worker').insert({
              'work_period_id': workPeriodId,
              'worker_id': workerId,
            });

            //get current total hours
            final workerResponse = await supabase
                .from('Worker')
                .select('total_work_hours')
                .eq('id', workerId)
                .maybeSingle(); //null if worker not found

            double currentHours = 0;
            if (workerResponse != null && workerResponse['total_work_hours'] != null) {
              currentHours = (workerResponse['total_work_hours'] as num).toDouble();
            }

            //add into total hours
            await supabase.from('Worker')
                .update({'total_work_hours': currentHours + hours})
                .eq('id', workerId);
          }
        }

        //reload schedules from Supabase so everything is refreshed
        await _loadSchedulesFromSupabase();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Schedule added successfully!")),
        );

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }

    void _showAddScheduleDialog() async{
      //get workers
      final workersResponse = await supabase.from('Worker').select();

      List<sch.Worker> workerList = [];
      workerList = (workersResponse as List).map((w) => sch.Worker(
        id: w['id'] as int,
        name: w['name'] as String,
        totalWorkHours: (w['total_work_hours'] as num?)?.toDouble() ?? 0,
      )).toList();

      final now = DateTime.now(); //for created at
      DateTime? startDate;
      DateTime? endDate;
      final nameController = TextEditingController();
      final descController = TextEditingController();
      final List<sch.WorkPeriod> workPeriods = [sch.WorkPeriod()]; //starts with 1 work period when adding
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
                          //show inline error message
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

                          const Text(
                            "Effective Period",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              //start date picker
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

                                      //adjust endDate if it is before startDate
                                      if (endDate != null && endDate!.isBefore(picked)) {
                                        setStateDialog(() => endDate = picked);
                                      }

                                      //clear any previous error message
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

                              //end date picker
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (startDate == null) {
                                      setStateDialog(() => errorMessage = "Please select start date first");
                                      return;
                                    }

                                    final first = startDate!;
                                    final initial = endDate ?? first; //make sure initial >= first
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: initial,
                                      firstDate: first, //limit the end date to not be before start date
                                      lastDate: DateTime(2100),
                                    );

                                    if (picked != null) {
                                      setStateDialog(() {
                                        endDate = picked;
                                        errorMessage = null;
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

                          const Text(
                            "Work Periods",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          //work periods picker
                          Column(
                            children: List.generate(workPeriods.length, (i) { //create a widget for each work period
                              final period = workPeriods[i];

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
                                      if (workPeriods.length > 1) //only shjow remove button when > 1 work periods
                                        IconButton(
                                          onPressed: () {
                                            setStateDialog(() {
                                              workPeriods.removeAt(i);
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
                      //validation
                      if (nameController.text.trim().isEmpty) {
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

                      //work periods overlap validation
                      for (int i = 0; i < workPeriods.length; i++) {
                        final wp1 = workPeriods[i];

                        //convert start and end times to Duration in minutes
                        Duration start1 = Duration(hours: wp1.startTime!.hour, minutes: wp1.startTime!.minute);
                        Duration end1 = Duration(hours: wp1.endTime!.hour, minutes: wp1.endTime!.minute);
                        if (end1 <= start1){ //check overnight shift
                          end1 += const Duration(days: 1);
                        }

                        for (int j = i + 1; j < workPeriods.length; j++) {
                          final wp2 = workPeriods[j];
                          Duration start2 = Duration(hours: wp2.startTime!.hour, minutes: wp2.startTime!.minute);
                          Duration end2 = Duration(hours: wp2.endTime!.hour, minutes: wp2.endTime!.minute);
                          if (end2 <= start2){
                            end2 += const Duration(days: 1);
                          }

                          bool overlap = start1 < end2 && end1 > start2;

                          if (overlap) {
                            setStateDialog(() =>
                            errorMessage = "Work periods cannot overlap (period ${i + 1} conflicts with period ${j + 1})");
                            return;
                          }
                        }
                      }

                      //clear error message for next
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
              //tab1: Schedules
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
                              subtitle: RichText(
                                text: TextSpan(
                                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                                  children: [
                                    TextSpan(text: "Name: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: "${s.name}\n", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    TextSpan(text: "Created by: ${s.createdBy}\n"),
                                    TextSpan(text: "Date Created: ${s.dateCreated.toLocal().toString().split(' ')[0]}\n"),
                                    TextSpan(text: "Effective Period: ${s.startDate != null ? s.startDate!.toLocal().toString().split(' ')[0] : '-'} to ${s.endDate != null ? s.endDate!.toLocal().toString().split(' ')[0] : '-'}"),
                                  ],
                                ),
                              ),

                              onTap: () async {
                                final deleted = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScheduleDetailPage(schedule: s),
                                  ),
                                );

                                //refetch all the schedules if a schedule was deleted
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

              //tab2: workers
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
                  //sort descending by total work hours
                  workers.sort((a, b) {
                    double hoursA = (a['total_work_hours'] as num?)?.toDouble() ?? 0;
                    double hoursB = (b['total_work_hours'] as num?)?.toDouble() ?? 0;
                    return hoursB.compareTo(hoursA); //sort by descending
                  });
                  if (workers.isEmpty) {
                    return const Center(child: Text("No workers found"));
                  }
                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final w = workers[index];
                      double totalHours = (w['total_work_hours'] as num?)?.toDouble() ?? 0;

                      //convert decimal hours to hours + minutes (from supabase because saved as decimals)
                      final hours = totalHours.floor();
                      final minutes = ((totalHours - hours) * 60).round();

                      //check if total hours > 8 hours
                      final isOver = totalHours > 8;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOver ? Colors.red[200] : Colors.blue[50], //red if over 8 hours
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isOver ? Colors.red.shade400 : Colors.blue.shade200,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("ID: ${w['id']} (${w['name'] ?? 'Unnamed'})",
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