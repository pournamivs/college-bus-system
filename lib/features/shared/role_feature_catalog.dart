enum AppRole { admin, driver, student, staff, parent }

class RoleFeature {
  final String title;
  final String description;
  final bool enabled;

  const RoleFeature({
    required this.title,
    required this.description,
    this.enabled = true,
  });
}

class RoleFeatureCatalog {
  static const Map<AppRole, List<RoleFeature>> byRole = {
    AppRole.driver: [
      RoleFeature(title: 'Start/Stop Trip', description: 'Start route and broadcast GPS'),
      RoleFeature(title: 'Live Broadcast', description: 'Continuous location WebSocket updates'),
      RoleFeature(title: 'Trip Status', description: 'Running / Paused / Stopped status'),
      RoleFeature(title: 'Bus Capacity', description: 'Passenger count sync with attendance'),
      RoleFeature(title: 'Maintenance', description: 'Report fuel, engine, and delay issues'),
      RoleFeature(title: 'SOS Countdown', description: '5-second emergency trigger with location'),
    ],
    AppRole.student: [
      RoleFeature(title: 'Live Tracking', description: 'Real-time bus map with moving icon'),
      RoleFeature(title: 'ETA', description: 'Dynamic ETA to next stop'),
      RoleFeature(title: 'Assigned Stop', description: 'Clearly visible assigned stop information'),
      RoleFeature(title: 'Geo-Fence Alerts', description: '500m proximity alert'),
      RoleFeature(title: 'Attendance', description: 'Manual/biometric attendance flow'),
      RoleFeature(title: 'Fees', description: 'Payment and due status'),
      RoleFeature(title: 'SOS', description: 'Emergency alert with location'),
    ],
    AppRole.staff: [
      RoleFeature(title: 'Student Tracking', description: 'Live map with staff alerts'),
      RoleFeature(title: 'Priority SOS', description: 'High-priority emergency handling'),
      RoleFeature(title: 'Attendance Override', description: 'Manual attendance correction'),
    ],
    AppRole.parent: [
      RoleFeature(title: 'Secure Linking', description: 'Request and approval based linking'),
      RoleFeature(title: 'Multi Child', description: 'Switch and track multiple students'),
      RoleFeature(title: 'Live Map', description: 'Tracking map per linked child'),
      RoleFeature(title: 'Safety Dashboard', description: 'Boarded/not-boarded live safety state'),
    ],
    AppRole.admin: [
      RoleFeature(title: 'Overview Metrics', description: 'Buses, trips, users counters'),
      RoleFeature(title: 'User Management', description: 'Add/remove students and drivers'),
      RoleFeature(title: 'Fleet Monitoring', description: 'Monitor all buses'),
      RoleFeature(title: 'Emergency Board', description: 'Acknowledge and resolve SOS alerts'),
      RoleFeature(title: 'Incident History', description: 'Historical alert audit trail'),
    ],
  };
}
