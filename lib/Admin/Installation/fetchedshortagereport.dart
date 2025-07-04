import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_file/open_file.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:techlead/Widgeets/custom_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_bar_provider.dart';

class FetchedProductPage extends ConsumerStatefulWidget {
  @override
  ConsumerState<FetchedProductPage> createState() => _FetchedProductPageState();
}

class _FetchedProductPageState extends ConsumerState<FetchedProductPage> {
  late Future<Map<String, dynamic>> _fetchDataFuture;
  bool isSharing = false;

  void _deleteReport(Map<String, dynamic> report) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Deleted report: ${report['id']}"),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            print("Undo delete: ${report['id']}");
          },
        ),
      ),
    );
  }

  void _shareReport(Map<String, dynamic> report) async {
    try {
      setState(() {
        isSharing = true;
      });

      String productName = report['product_name'];
      String description = report['description'];
      String siteLocation = report['site_location'];

      String shareText = "Product Name: $productName\n"
          "Description: $description\n"
          "Site Location: $siteLocation\n"
          "Shared via Flutter App";

      await Share.share(shareText);

      if (isSharing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Shared successfully")),
        );
      }
    } catch (e) {
      print("Error sharing report: $e");
    } finally {
      setState(() {
        isSharing = false;
      });
    }
  }

  Widget _buildDismissibleReport(Map<String, dynamic> report) {
    return Dismissible(
      key: Key(report['id'].toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _deleteReport(report);
        } else if (direction == DismissDirection.endToStart) {
          _shareReport(report);
        }
      },
      child: ListTile(
        title: Text(report['product_name']),
        subtitle: Text(report['description']),
        trailing: Icon(Icons.delete),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchDataFuture = _fetchShortageReports();
    WidgetsBinding.instance.addPostFrameCallback((_) {

      ref.read(customTitleWidgetProvider.notifier).state = Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.integration_instructions_sharp, color: Colors.white),
          SizedBox(width: 8),
          Text(
            "Installation Shortage Report",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: "Times New Roman",
                fontSize: 16),
          ),
        ],
      );
    });
  }

  Future<Map<String, dynamic>> _fetchShortageReports() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('product_shortage_reports')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> reports = querySnapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        }).toList();

        return {'reports': reports};
      } else {
        return {'reports': []};
      }
    } catch (e) {
      print('Error fetching reports: $e');
      return {'reports': []};
    }
  }

  Widget _buildFilePreview(
      BuildContext context, Map<String, dynamic> fileData) {
    String fileName = fileData['file_name'];
    String fileType = fileData['file_type'];
    String fileUrl = fileData['file_url'];
    String fileStatus = fileData['status'] ?? 'pending';

    IconData statusIcon;
    Color iconColor;

    return GestureDetector(
      onTap: () => _openFile(fileUrl, context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handling images correctly
          if (fileType == 'jpg' || fileType == 'jpeg' || fileType == 'png')
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    fileUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade700, Colors.blue.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.insert_drive_file,
                    size: 40,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 5),
          Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.cyanAccent),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(String fileUrl, BuildContext context) async {
    final file = await firebase_storage.FirebaseStorage.instance
        .refFromURL(fileUrl)
        .getDownloadURL();
    OpenFile.open(file);
  }

  Future<pdfx.PdfDocument> _loadPdf(String fileUrl) async {
    final data = await firebase_storage.FirebaseStorage.instance
        .refFromURL(fileUrl)
        .getData();
    return pdfx.PdfDocument.openData(data!);
  }

  Future<Excel> _loadExcel(String fileUrl) async {
    final bytes = await firebase_storage.FirebaseStorage.instance
        .refFromURL(fileUrl)
        .getData();
    return Excel.decodeBytes(bytes!);
  }

  Widget _buildReportFields(Map<String, dynamic> report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldRow("Product Name:", report['product_name']),
        _buildFieldRow("Required Quantity:", report['required_quantity']),
        _buildFieldRow("Available Quantity:", report['available_quantity']),
        _buildFieldRow("Site Location:", report['site_location']),
        _buildFieldRow("Description:", report['description']),
        _buildFieldRow("Contact Info:", report['contact_info']),
        _buildFieldRow("Address:", report['address']),
        _buildFieldRow("Assigned Technician:", report['assigned_technician']),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFieldRow(String fieldName, dynamic fieldValue) {
    final isLocation = fieldName.trim().toLowerCase() == 'site location:';
    final locationValue = fieldValue?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fieldName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: isLocation
                    ? GestureDetector(
                  onTap: () async {
                    final encodedLocation = Uri.encodeComponent(locationValue);
                    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
                    if (await canLaunch(googleMapsUrl)) {
                      await launch(googleMapsUrl);
                    } else {
                      debugPrint("Could not launch Maps");
                    }
                  },
                  child: Text(
                    locationValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      fontSize: 16,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
                    : Text(
                  locationValue,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyanAccent,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (isLocation && locationValue.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4.0, left: 8.0),
              child: Text(
                'Note: Tap to open location in Maps',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _fetchDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              var reports = snapshot.data!['reports'] as List<dynamic>;

              if (reports.isEmpty) {
                return Center(
                    child: Text('No reports found',
                        style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  var report = reports[index];
                  var files = report['files'] as List<dynamic>;

                  return Dismissible(
                    key: Key(report['id']),
                    background: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade900],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.delete,
                          color: Colors.white, size: 30),
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade900
                          ],
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                      ),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: const Icon(Icons.share,
                          color: Colors.white, size: 30),
                    ),
                    onDismissed: (direction) {
                      if (direction == DismissDirection.startToEnd) {
                        _deleteReport(report);
                      } else if (direction == DismissDirection.endToStart) {
                        _shareReport(report);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade700,
                                Colors.blue.shade900
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                _buildReportFields(report),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    childAspectRatio: 1,
                                  ),
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: files.length,
                                  itemBuilder: (context, fileIndex) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade600,
                                            Colors.blue.shade800
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: _buildFilePreview(
                                          context, files[fileIndex]),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            } else {
              return Center(
                  child: Text(
                'No data available!',
                style: TextStyle(
                    color: Colors.black,
                    fontFamily: "Times New Roman",
                    fontWeight: FontWeight.bold),
              ));
            }
          },
        ),
      ),
    );
  }
}
