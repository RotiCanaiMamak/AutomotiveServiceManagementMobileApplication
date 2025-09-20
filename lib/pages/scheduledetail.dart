import 'package:flutter/material.dart';
import 'workscheduler.dart';

class ScheduleDetailPage extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  // Helper to calculate total hours
  Map<String, Duration> _calculateHoursPerWorker() {
    final Map<String, Duration> workerHours = {};

    for (var wp in schedule.workPeriods) {
      if (wp.startTime == null || wp.endTime == null) {
        continue; // skip invalid work periods
      }

      final start = Duration(hours: wp.startTime!.hour, minutes: wp.startTime!.minute);
      var end = Duration(hours: wp.endTime!.hour, minutes: wp.endTime!.minute);

      // Handle overnight shifts
      if (end < start) {
        end += const Duration(days: 1);
      }

      final duration = end - start;

      final workers = wp.workerIds
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);

      for (var worker in workers) {
        workerHours[worker] = (workerHours[worker] ?? Duration.zero) + duration;
      }
    }

    return workerHours;
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // two tabs
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            "Schedule ID: ${schedule.id}",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Created At (left) + Created By (right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Date Created:",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        schedule.createdBy,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Schedule Name (centered)
              Center(
                child: Text(
                  schedule.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),

              // Description
              Center(
                child: Text(
                  (schedule.description != null &&
                      schedule.description.trim().isNotEmpty)
                      ? schedule.description
                      : "No description",
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Effective Period
              const Text(
                "Effective Period",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                "${schedule.startDate != null ? schedule.startDate!.toLocal().toString().split(' ')[0] : '-'}"
                    " to "
                    "${schedule.endDate != null ? schedule.endDate!.toLocal().toString().split(' ')[0] : '-'}",
              ),

              const SizedBox(height: 16),
              const Divider(thickness: 1),
              const SizedBox(height: 8),

              // Toggle Tabs
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

              // Tab Views
              Expanded(
                child: TabBarView(
                  children: [
                    // Overall Schedule (Work Periods)
                    ListView.builder(
                      itemCount: schedule.workPeriods.length,
                      itemBuilder: (context, index) {
                        final wp = schedule.workPeriods[index];
                        final workers = wp.workerIds
                            .split(',')
                            .map((e) => e.trim())
                            .where((e) => e.isNotEmpty)
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Time (no box)
                              SizedBox(
                                width: 100,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wp.startTime != null
                                          ? wp.startTime!.format(context)
                                          : "-",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      wp.endTime != null
                                          ? wp.endTime!.format(context)
                                          : "-",
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Workers (2 per row)
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
                                      children: workers.map((w) => Text(w)).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Total Hours (per worker breakdown)
                    Builder(
                      builder: (context) {
                        final workerHours = _calculateHoursPerWorker();
                        return ListView(
                          children: workerHours.entries.map((entry) {
                            final hours = entry.value.inHours;
                            final minutes = entry.value.inMinutes.remainder(60);

                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key, // worker name
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    "${hours}h ${minutes}m", // total hours
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
