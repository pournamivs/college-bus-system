import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _currentIndex = 0; // 0 for Map, 1 for List
  GoogleMapController? _mapController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = "";

  Widget _buildMapTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('locations').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        Set<Marker> markers = {};
        for (var doc in snapshot.data!.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          if (data['is_active'] == true && data['latitude'] != null) {
            markers.add(
              Marker(
                markerId: MarkerId(doc.id),
                position: LatLng(data['latitude'], data['longitude']),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  data['status'] == 'moving' ? BitmapDescriptor.hueGreen : 
                  (data['status'] == 'slow' ? BitmapDescriptor.hueYellow : BitmapDescriptor.hueRed)
                ),
                infoWindow: InfoWindow(
                  title: 'Bus: ${doc.id}',
                  snippet: 'Status: ${data['status']} | Speed: ${data['speed']} km/h',
                ),
              ),
            );
          }
        }

        return GoogleMap(
          initialCameraPosition: const CameraPosition(
             // Set default admin starting view, dynamically center bounds in real prod
            target: LatLng(26.1158, 91.7086), 
            zoom: 12,
          ),
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
        );
      },
    );
  }

  Widget _buildListTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Search Bus ID or Status...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('locations').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No buses tracking currently."));
              }

              var docs = snapshot.data!.docs.where((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                String busId = doc.id.toLowerCase();
                String status = (data['status'] ?? '').toString().toLowerCase();
                return busId.contains(_searchQuery) || status.contains(_searchQuery);
              }).toList();

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  bool isActive = data['is_active'] ?? false;
                  String status = data['status'] ?? 'stopped';
                  
                  Color statusColor = Colors.red;
                  if (status == 'moving') statusColor = Colors.green;
                  if (status == 'slow') statusColor = Colors.orange;
                  if (!isActive) statusColor = Colors.grey;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.directions_bus, color: statusColor),
                      ),
                      title: Text('Bus: ${docs[index].id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        isActive 
                            ? 'Speed: ${data['speed']} km/h • $status' 
                            : 'Currently Inactive',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_square, color: Colors.blueAccent),
                        onPressed: () {
                          // TODO: Open modal to edit bus driver/student assignments.
                          _showEditBusModal(docs[index].id);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showEditBusModal(String busId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manage $busId', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Assign Students'),
                onTap: () {
                    // Update user docs where role='student' and set bus_id
                    Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.badge),
                title: const Text('Change Driver'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: _currentIndex == 0 ? _buildMapTab() : _buildListTab(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Admin adds new bus empty state wrapper
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'Fleet Status',
          ),
        ],
      ),
    );
  }
}
