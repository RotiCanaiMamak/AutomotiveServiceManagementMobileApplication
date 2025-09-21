import 'package:flutter/material.dart';
import 'schedule.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ScheduleDetailPage extends StatefulWidget {
  final Schedule schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  @override
  _ScheduleDetailPageState createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late Schedule schedule;

  @override
  void initState() {
    super.initState();
    schedule = widget.schedule;
  }

  String _formatTime(TimeOfDay? t) {
    if (t == null){
      return "--:--";
    }
    final h = t.hour.toString().padLeft(2, "0");
    final m = t.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }

  Map<String, Duration> _calculateHoursPerWorker() {
    final Map<String, Duration> workerHours = {};
    for (var wp in schedule.workPeriods) {
      if (wp.startTime == null || wp.endTime == null){
        continue;
      }

      final start = Duration(hours: wp.startTime!.hour, minutes: wp.startTime!.minute);
      var end = Duration(hours: wp.endTime!.hour, minutes: wp.endTime!.minute);
      if (end < start){ //if overnight shift
        end += const Duration(days: 1);
      }

      final duration = end - start;
      for (var id in wp.workerIds) {
        workerHours[id.toString()] =
            (workerHours[id.toString()] ?? Duration.zero) + duration;
      }
    }
    return workerHours;
  }

  Future<void> _deleteSchedule() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this schedule?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true){
      return;
    }

    try {
      //delete work periods and associative entity
      for (var wp in schedule.workPeriods) {
        if (wp.id != null) {
          await supabase.from('Work_Periods_Worker').delete().eq('work_period_id', wp.id!);
          await supabase.from('Work_Periods').delete().eq('id', wp.id!);

          //update worker total hours
          final start = Duration(hours: wp.startTime!.hour, minutes: wp.startTime!.minute);
          var end = Duration(hours: wp.endTime!.hour, minutes: wp.endTime!.minute);
          if (end < start){
            end += const Duration(days: 1);
          }
          final durationHours = end.inMinutes / 60;

          for (var workerId in wp.workerIds) {
            final worker = await supabase.from('Worker').select('total_work_hours').eq('id', workerId).maybeSingle();
            if (worker != null) {
              double currentHours = (worker['total_work_hours'] as num?)?.toDouble() ?? 0;
              await supabase.from('Worker').update({
                'total_work_hours': (currentHours - durationHours).clamp(0, double.infinity)
              }).eq('id', workerId);
            }
          }
        }
      }

      //delete the schedule
      await supabase.from('Schedule').delete().eq('id', schedule.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Schedule deleted successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting schedule: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Schedule ID: ${schedule.id}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //created at and created by
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date Created:",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        schedule.dateCreated.toLocal().toString().split(' ')[0],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Created By:",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(schedule.createdBy, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              //schdule name and description
              Center(
                child: Text(
                  schedule.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  (schedule.description.trim().isNotEmpty)
                      ? schedule.description
                      : "No description",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              //effective period
              const Text(
                "Effective Period",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "${schedule.startDate?.toLocal().toString().split(' ')[0] ?? '-'} to "
                    "${schedule.endDate?.toLocal().toString().split(' ')[0] ?? '-'}",
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 8),

              //tabs
              const TabBar(
                labelColor: Colors.blue,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.blue,
                tabs: [
                  Tab(text: "Overall Schedule"),
                  Tab(text: "Total Hours"),
                ],
              ),
              const SizedBox(height: 8),

              Expanded(
                child: TabBarView(
                  children: [
                    //overall work periods
                    ListView.builder(
                      itemCount: schedule.workPeriods.length,
                      itemBuilder: (context, index) {
                        final wp = schedule.workPeriods[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_formatTime(wp.startTime),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(_formatTime(wp.endTime),
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GridView.count(
                                      crossAxisCount: 2,
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      childAspectRatio: 4,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 16,
                                      children: wp.workerIds.map((id) => Text("ID: $id")).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    //worker total hours in the current schedule
                    Builder(
                      builder: (context) {
                        final workerHours = _calculateHoursPerWorker();

                        //sort descending by duration
                        final sortedEntries = workerHours.entries.toList()
                          ..sort((a, b) => b.value.compareTo(a.value));

                        return ListView(
                          children: sortedEntries.map((entry) {
                            final hours = entry.value.inHours;
                            final minutes = entry.value.inMinutes.remainder(60);
                            final isOver = entry.value.inHours > 8;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
                                  Text(entry.key,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("${hours}h ${minutes}m",
                                      style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              //delete button
              Center(
                child: ElevatedButton.icon(
                  onPressed: _deleteSchedule,
                  icon: const Icon(Icons.delete),
                  label: const Text("Delete Schedule"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
