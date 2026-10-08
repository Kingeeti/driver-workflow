import 'package:flutter/material.dart';

void main() => runApp(const HaulFlowApp());

enum Role { driver, admin }

class Driver {
  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });
  final String id, name, email, phone, password;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.driverId,
    required this.title,
    required this.body,
    this.shipmentId,
    this.invitation = false,
    this.handoffRequest = false,
    this.read = false,
  });
  final String id, driverId, title, body;
  final String? shipmentId;
  final bool invitation;
  final bool handoffRequest;
  bool read;
}

class Shipment {
  Shipment({required this.id, required this.route, required this.driverIds});
  final String id, route;
  final List<String> driverIds;
  final Set<String> acceptedDrivers = {};
  final List<String> activity = [
    'Shipment invitation created by the administrator.',
  ];
  int activeShift = 0;
  bool handoffRequested = false;
  bool delivered = false;
  bool get isActive => acceptedDrivers.length == 2;
}

class HaulFlowApp extends StatefulWidget {
  const HaulFlowApp({super.key});
  @override
  State<HaulFlowApp> createState() => _HaulFlowAppState();
}

class _HaulFlowAppState extends State<HaulFlowApp> {
  static const _adminEmail = 'demoAdmin@gmail.com';
  static const _adminPassword = 'DemoAdmin123';
  final List<Driver> _drivers = [];
  final List<AppNotification> _notifications = [];
  final List<Shipment> _shipments = [];
  Role? _role;
  Driver? _signedInDriver;
  int _nextId = 1;

  String _id(String prefix) => '$prefix-${_nextId++}';

  void _register(String name, String email, String phone, String password) {
    final normalized = email.trim().toLowerCase();
    if (normalized == _adminEmail.toLowerCase() ||
        _drivers.any((driver) => driver.email == normalized)) {
      throw const FormatException(
        'An account already uses this email address.',
      );
    }
    setState(
      () => _drivers.add(
        Driver(
          id: _id('driver'),
          name: name.trim(),
          email: normalized,
          phone: phone.trim(),
          password: password,
        ),
      ),
    );
  }

  void _driverLogin(String email, String password) {
    final match = _drivers
        .where(
          (driver) =>
              driver.email == email.trim().toLowerCase() &&
              driver.password == password,
        )
        .firstOrNull;
    if (match == null)
      throw const FormatException(
        'Email or password is incorrect. Register as a driver first.',
      );
    setState(() {
      _role = Role.driver;
      _signedInDriver = match;
    });
  }

  void _adminLogin(String email, String password) {
    if (email.trim().toLowerCase() != _adminEmail.toLowerCase() ||
        password != _adminPassword) {
      throw const FormatException(
        'Administrator email or password is incorrect.',
      );
    }
    setState(() {
      _role = Role.admin;
      _signedInDriver = null;
    });
  }

  void _createShipment(String firstId, String secondId) {
    final shipment = Shipment(
      id: 'SHP-${2000 + _shipments.length + 1}',
      route: 'Karachi → Lahore',
      driverIds: [firstId, secondId],
    );
    setState(() {
      _shipments.add(shipment);
      for (final id in shipment.driverIds) {
        _notifications.insert(
          0,
          AppNotification(
            id: _id('notice'),
            driverId: id,
            shipmentId: shipment.id,
            invitation: true,
            title: 'New shipment invitation',
            body:
                '${shipment.id}: ${shipment.route}. Review and accept to join the two-driver crew.',
          ),
        );
      }
    });
  }

  void _acceptInvitation(Driver driver, Shipment shipment) {
    setState(() {
      shipment.acceptedDrivers.add(driver.id);
      shipment.activity.insert(
        0,
        '${driver.name} accepted the shipment invitation.',
      );
      for (final id in shipment.driverIds) {
        _notifications.insert(
          0,
          AppNotification(
            id: _id('notice'),
            driverId: id,
            shipmentId: shipment.id,
            title: 'Crew response',
            body:
                '${driver.name} accepted ${shipment.id}. ${shipment.isActive ? 'Both drivers are confirmed; the trip is active.' : 'Awaiting co-driver confirmation.'}',
          ),
        );
      }
      final invite = _notifications
          .where(
            (item) =>
                item.driverId == driver.id &&
                item.shipmentId == shipment.id &&
                item.invitation,
          )
          .firstOrNull;
      if (invite != null) invite.read = true;
    });
  }

  void _addTripUpdate(Shipment shipment, String message) {
    setState(() {
      shipment.activity.insert(0, message);
      for (final id in shipment.driverIds) {
        _notifications.insert(
          0,
          AppNotification(
            id: _id('notice'),
            driverId: id,
            shipmentId: shipment.id,
            title: 'Shipment update · ${shipment.id}',
            body: message,
          ),
        );
      }
    });
  }

  void _requestHandoff(Driver driver, Shipment shipment) {
    setState(() {
      shipment.handoffRequested = true;
      final message = '${driver.name} requested the scheduled driver handoff.';
      shipment.activity.insert(0, message);
      for (final id in shipment.driverIds) {
        _notifications.insert(
          0,
          AppNotification(
            id: _id('notice'),
            driverId: id,
            shipmentId: shipment.id,
            handoffRequest: id != driver.id,
            title: id == driver.id
                ? 'Handoff requested'
                : 'Handoff ready for you',
            body: id == driver.id
                ? 'Your co-driver has been asked to take over ${shipment.id}.'
                : '$message Accept the handoff when you are ready to drive.',
          ),
        );
      }
    });
  }

  void _acceptHandoff(Driver driver, Shipment shipment) {
    setState(() {
      shipment.handoffRequested = false;
      shipment.activeShift = (shipment.activeShift + 1) % 6;
      for (final notice in _notifications.where(
        (item) =>
            item.driverId == driver.id &&
            item.shipmentId == shipment.id &&
            item.handoffRequest,
      )) {
        notice.read = true;
      }
    });
    _addTripUpdate(
      shipment,
      '${driver.name} accepted the handoff and is now driving.',
    );
  }

  void _logout() => setState(() {
    _role = null;
    _signedInDriver = null;
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'HaulFlow',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176B87)),
      scaffoldBackgroundColor: const Color(0xfff6f8fa),
      useMaterial3: true,
    ),
    home: _role == Role.admin
        ? AdminHome(
            drivers: _drivers,
            shipments: _shipments,
            onCreateShipment: _createShipment,
            onLogout: _logout,
          )
        : _role == Role.driver
        ? DriverHome(
            driver: _signedInDriver!,
            shipments: _shipments,
            notifications: _notifications,
            onAccept: _acceptInvitation,
            onStop: (shipment) => _addTripUpdate(
              shipment,
              '${_signedInDriver!.name} marked the scheduled fuel and safety stop reached.',
            ),
            onRequestHandoff: _requestHandoff,
            onAcceptHandoff: _acceptHandoff,
            onLogout: _logout,
          )
        : AuthHome(
            onRegister: _register,
            onDriverLogin: _driverLogin,
            onAdminLogin: _adminLogin,
          ),
  );
}

class AuthHome extends StatelessWidget {
  const AuthHome({
    super.key,
    required this.onRegister,
    required this.onDriverLogin,
    required this.onAdminLogin,
  });
  final void Function(String, String, String, String) onRegister;
  final void Function(String, String) onDriverLogin, onAdminLogin;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xff176B87),
                    size: 48,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'HaulFlow',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const Text('Two-driver shipment workflow'),
                  const SizedBox(height: 28),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Driver sign in'),
                      Tab(text: 'Driver onboarding'),
                      Tab(text: 'Admin login'),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: TabBarView(
                      children: [
                        LoginForm(
                          button: 'Sign in as driver',
                          onLogin: onDriverLogin,
                        ),
                        RegisterForm(onRegister: onRegister),
                        LoginForm(
                          button: 'Sign in as administrator',
                          onLogin: onAdminLogin,
                          admin: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    required this.button,
    required this.onLogin,
    this.admin = false,
  });
  final String button;
  final void Function(String, String) onLogin;
  final bool admin;
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final email = TextEditingController(), password = TextEditingController();
  String? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    try {
      widget.onLogin(email.text, password.text);
    } on FormatException catch (e) {
      setState(() => error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      Text(
        widget.admin
            ? 'Only the authorised administrator can use this sign-in. There is no administrator registration.'
            : 'Use the email and password you created during driver onboarding.',
      ),
      const SizedBox(height: 18),
      TextField(
        controller: email,
        decoration: const InputDecoration(
          labelText: 'Email',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: password,
        obscureText: true,
        onSubmitted: (_) => submit(),
        decoration: const InputDecoration(
          labelText: 'Password',
          border: OutlineInputBorder(),
        ),
      ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      const SizedBox(height: 16),
      FilledButton(onPressed: submit, child: Text(widget.button)),
    ],
  );
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.onRegister});
  final void Function(String, String, String, String) onRegister;
  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final form = GlobalKey<FormState>(),
      name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      password = TextEditingController();
  String? message;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    try {
      widget.onRegister(name.text, email.text, phone.text, password.text);
      setState(
        () => message = 'Account created. Switch to Driver sign in to log in.',
      );
      form.currentState!.reset();
    } on FormatException catch (e) {
      setState(() => message = e.message);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const Text(
        'Create your driver account. Your administrator can then invite you to a shipment.',
      ),
      const SizedBox(height: 16),
      Form(
        key: form,
        child: Column(
          children: [
            field(name, 'Full name'),
            const SizedBox(height: 12),
            field(email, 'Email', email: true),
            const SizedBox(height: 12),
            field(phone, 'Phone number'),
            const SizedBox(height: 12),
            TextFormField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Create password',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.length < 6
                  ? 'Use at least 6 characters.'
                  : null,
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  message!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: submit,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create driver account'),
            ),
          ],
        ),
      ),
    ],
  );
  TextFormField field(
    TextEditingController controller,
    String label, {
    bool email = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: email ? TextInputType.emailAddress : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) =>
        value == null || value.trim().isEmpty || (email && !value.contains('@'))
        ? 'Enter a valid $label.'
        : null,
  );
}

class AdminHome extends StatefulWidget {
  const AdminHome({
    super.key,
    required this.drivers,
    required this.shipments,
    required this.onCreateShipment,
    required this.onLogout,
  });
  final List<Driver> drivers;
  final List<Shipment> shipments;
  final void Function(String, String) onCreateShipment;
  final VoidCallback onLogout;
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  String? first, second;
  String? error;
  void create() {
    if (first == null || second == null || first == second) {
      setState(() => error = 'Select two different onboarded drivers.');
      return;
    }
    widget.onCreateShipment(first!, second!);
    setState(() {
      first = null;
      second = null;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) => Shell(
    title: 'Administrator dashboard',
    onLogout: widget.onLogout,
    child: ListView(
      children: [
        Text(
          'Create a two-driver invitation',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          widget.drivers.isEmpty
              ? 'No drivers have registered yet. Ask drivers to complete onboarding first.'
              : 'Select two registered drivers. Each will receive an invitation in their Notifications tab.',
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          value: first,
          decoration: const InputDecoration(
            labelText: 'First driver',
            border: OutlineInputBorder(),
          ),
          items: widget.drivers
              .map(
                (driver) => DropdownMenuItem(
                  value: driver.id,
                  child: Text(driver.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => first = value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: second,
          decoration: const InputDecoration(
            labelText: 'Second driver',
            border: OutlineInputBorder(),
          ),
          items: widget.drivers
              .map(
                (driver) => DropdownMenuItem(
                  value: driver.id,
                  child: Text(driver.name),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => second = value),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: widget.drivers.length < 2 ? null : create,
          icon: const Icon(Icons.send),
          label: const Text('Send shipment invitations'),
        ),
        const SizedBox(height: 28),
        Text(
          'Registered drivers (${widget.drivers.length})',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ...widget.drivers.map(
          (driver) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(driver.name),
            subtitle: Text('${driver.email} · ${driver.phone}'),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Created shipments',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        ...widget.shipments.map(
          (shipment) => ListTile(
            leading: const Icon(Icons.local_shipping_outlined),
            title: Text('${shipment.id} · ${shipment.route}'),
            subtitle: Text(
              '${shipment.acceptedDrivers.length}/2 drivers accepted${shipment.isActive ? ' · Active' : ''}',
            ),
          ),
        ),
      ],
    ),
  );
}

class DriverHome extends StatelessWidget {
  const DriverHome({
    super.key,
    required this.driver,
    required this.shipments,
    required this.notifications,
    required this.onAccept,
    required this.onStop,
    required this.onRequestHandoff,
    required this.onAcceptHandoff,
    required this.onLogout,
  });
  final Driver driver;
  final List<Shipment> shipments;
  final List<AppNotification> notifications;
  final void Function(Driver, Shipment) onAccept,
      onRequestHandoff,
      onAcceptHandoff;
  final void Function(Shipment) onStop;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) {
    final mine = notifications
        .where((item) => item.driverId == driver.id)
        .toList();
    final delivery = shipments
        .where(
          (item) =>
              item.driverIds.contains(driver.id) &&
              item.acceptedDrivers.contains(driver.id),
        )
        .toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('HaulFlow'),
          actions: [
            Center(child: Text(driver.name)),
            IconButton(
              onPressed: onLogout,
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                text:
                    'Notifications (${mine.where((item) => !item.read).length})',
              ),
              const Tab(text: 'My shipments'),
              const Tab(text: 'Profile'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: mine.isEmpty
                  ? [
                      const EmptyState(
                        'No notifications yet',
                        'Shipment invitations and trip updates will appear here.',
                      ),
                    ]
                  : mine.map((notice) {
                      final shipment = notice.shipmentId == null
                          ? null
                          : shipments
                                .where((item) => item.id == notice.shipmentId)
                                .firstOrNull;
                      final canAccept =
                          notice.invitation &&
                          shipment != null &&
                          !shipment.acceptedDrivers.contains(driver.id);
                      final activeDriverId = shipment == null
                          ? null
                          : shipment.driverIds[shipment.activeShift.isEven
                                ? 0
                                : 1];
                      final canAcceptHandoff =
                          notice.handoffRequest &&
                          shipment != null &&
                          shipment.handoffRequested &&
                          activeDriverId != driver.id;
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            notice.invitation
                                ? Icons.assignment_ind_outlined
                                : Icons.notifications_outlined,
                          ),
                          title: Text(notice.title),
                          subtitle: Text(notice.body),
                          trailing: canAccept
                              ? FilledButton(
                                  onPressed: () => onAccept(driver, shipment),
                                  child: const Text('Accept'),
                                )
                              : canAcceptHandoff
                              ? FilledButton.icon(
                                  onPressed: () =>
                                      onAcceptHandoff(driver, shipment),
                                  icon: const Icon(Icons.directions_car),
                                  label: const Text('Accept handoff'),
                                )
                              : (notice.read
                                    ? null
                                    : const Icon(
                                        Icons.circle,
                                        color: Colors.blue,
                                        size: 12,
                                      )),
                        ),
                      );
                    }).toList(),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: delivery.isEmpty
                  ? [
                      const EmptyState(
                        'No accepted shipments',
                        'Accept a shipment invitation before its driver workflow is available.',
                      ),
                    ]
                  : delivery
                        .map(
                          (shipment) => ShipmentCard(
                            driver: driver,
                            shipment: shipment,
                            onStop: onStop,
                            onRequestHandoff: onRequestHandoff,
                            onAcceptHandoff: onAcceptHandoff,
                          ),
                        )
                        .toList(),
            ),
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(driver.name),
                  subtitle: Text('${driver.email}\n${driver.phone}'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your driver account is active. Shipments are assigned by the administrator through invitations.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ShipmentCard extends StatelessWidget {
  const ShipmentCard({
    super.key,
    required this.driver,
    required this.shipment,
    required this.onStop,
    required this.onRequestHandoff,
    required this.onAcceptHandoff,
  });
  final Driver driver;
  final Shipment shipment;
  final void Function(Shipment) onStop;
  final void Function(Driver, Shipment) onRequestHandoff, onAcceptHandoff;
  @override
  Widget build(BuildContext context) {
    final activeDriver =
        shipment.driverIds[shipment.activeShift.isEven ? 0 : 1];
    final isDriving = activeDriver == driver.id;
    final coDriver = shipment.driverIds.firstWhere((id) => id != driver.id);
    final canAccept =
        shipment.handoffRequested && !isDriving && driver.id == coDriver;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${shipment.id} · ${shipment.route}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              shipment.isActive
                  ? (isDriving
                        ? 'You are driving · Shift ${shipment.activeShift + 1} of 6'
                        : 'Resting · Your co-driver is driving')
                  : 'Awaiting your co-driver to accept.',
            ),
            const SizedBox(height: 14),
            if (shipment.isActive)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isDriving && !shipment.handoffRequested)
                    FilledButton.icon(
                      onPressed: () => onRequestHandoff(driver, shipment),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Request handoff'),
                    ),
                  if (canAccept)
                    FilledButton.icon(
                      onPressed: () => onAcceptHandoff(driver, shipment),
                      icon: const Icon(Icons.verified),
                      label: const Text('Accept handoff'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => onStop(shipment),
                    icon: const Icon(Icons.local_gas_station_outlined),
                    label: const Text('Mark scheduled stop'),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            const Text(
              'Activity',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...shipment.activity
                .take(4)
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Text('• $item'),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({
    super.key,
    required this.title,
    required this.child,
    required this.onLogout,
  });
  final String title;
  final Widget child;
  final VoidCallback onLogout;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          onPressed: onLogout,
          tooltip: 'Log out',
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(padding: const EdgeInsets.all(20), child: child),
        ),
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.title, this.body, {super.key});
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 56),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 46, color: Colors.grey),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(body, textAlign: TextAlign.center),
      ],
    ),
  );
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
