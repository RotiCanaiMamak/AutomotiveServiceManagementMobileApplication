
import 'package:flutter/material.dart';

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

class WorkPeriod {
  int? id;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  List<int> workerIds;
  List<Worker> workers;

  WorkPeriod({
    this.id,
    this.startTime,
    this.endTime,
    this.workerIds = const [],
    this.workers = const [],
  });
}
class Worker {
  final int id;
  final String name;
  final double totalWorkHours;

  Worker({
    required this.id,
    required this.name,
    this.totalWorkHours = 0,
  });
}
