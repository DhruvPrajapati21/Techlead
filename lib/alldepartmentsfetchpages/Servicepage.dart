import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ServicePageList extends StatefulWidget {
  const ServicePageList({super.key});

  @override
  State<ServicePageList> createState() => _ServicePageListState();
}

class _ServicePageListState extends State<ServicePageList> {
  // Categorized services for Residential and Commercial
  final Map<String, Map<String, IconData>> categorizedProducts = {
    'Residential': {
      'Smart Lights': FontAwesomeIcons.lightbulb,
      'Smart Thermostat': FontAwesomeIcons.thermometerHalf,
      'Security Cameras': FontAwesomeIcons.video,
      'Smart Plugs': FontAwesomeIcons.plug,
      'Smart Door Locks': FontAwesomeIcons.lock,
      'Smart Smoke Detectors': FontAwesomeIcons.cloud,
      'Smart Speakers': FontAwesomeIcons.volumeUp,
      'Smart Blinds': FontAwesomeIcons.windowMaximize,
      'Smart Doorbells': FontAwesomeIcons.bell,
      'Motion Sensors': FontAwesomeIcons.walking,
      'Smart Cameras': FontAwesomeIcons.camera,
      'Smart Switches': FontAwesomeIcons.toggleOn,
      'Smart Air Purifiers': FontAwesomeIcons.wind,
      'Smart Fans': FontAwesomeIcons.fan,
      'Smart Heaters': FontAwesomeIcons.fire,
      'Smart Humidifiers': FontAwesomeIcons.cloudRain,
      'Smart Refrigerators': FontAwesomeIcons.iceCream,
      'Smart Washing Machines': FontAwesomeIcons.soap,
      'Smart Dishwashers': FontAwesomeIcons.handsWash,
      'Smart Coffee Makers': FontAwesomeIcons.mugHot,
      'Smart Projectors': FontAwesomeIcons.projectDiagram,
      'Smart Remotes': FontAwesomeIcons.contao,
      'Smart Hubs': FontAwesomeIcons.networkWired,
      'Smart Batteries': FontAwesomeIcons.batteryFull,
      'Smart Chargers': FontAwesomeIcons.chargingStation,
      'Smart Curtains': FontAwesomeIcons.windowRestore,
      'Robotic Vacuums': FontAwesomeIcons.robot,
      'Smart Window Openers': FontAwesomeIcons.windowMaximize,
      'Smart Home Automation Hubs': FontAwesomeIcons.home,
      'Smart Light Panels': FontAwesomeIcons.lightbulb,
      'LED Strips': FontAwesomeIcons.ribbon,
      'Smart Home Assistants': FontAwesomeIcons.headset,
      'Voice Assistants': FontAwesomeIcons.microphone,
      'Automated Home Theater Systems': FontAwesomeIcons.tv,
      'Automated Shades': FontAwesomeIcons.accusoft,
      'Automatic Watering Systems': FontAwesomeIcons.water,
      'Smart Smoke Alarms': FontAwesomeIcons.bell,
      'Smart Leak Detectors': FontAwesomeIcons.water,
      'Smart Water Heaters': FontAwesomeIcons.fire,
      'Smart Air Conditioners': FontAwesomeIcons.snowflake,
      'Smart Vacuum Cleaners': FontAwesomeIcons.robot,
      'Smart Bed Frames': FontAwesomeIcons.bed,
      'Home Automation Controller Systems': FontAwesomeIcons.server,
    },
    'Commercial': {
      'Home Security Systems': FontAwesomeIcons.shieldAlt,
      'Streaming Devices': FontAwesomeIcons.stream,
      'Solar Energy Systems': FontAwesomeIcons.solarPanel,
      'Smart Meters': FontAwesomeIcons.tachometerAlt,
      'Smart Security Systems': FontAwesomeIcons.shieldVirus,
      'Smart Light Panels': FontAwesomeIcons.lightbulb,
      'Smart Doorbells': FontAwesomeIcons.bell,
      'Smart Curtains': FontAwesomeIcons.windowRestore,
      'Smart Window Openers': FontAwesomeIcons.windowMaximize,
      'Robotic Vacuums': FontAwesomeIcons.robot,
      'Smart Fans': FontAwesomeIcons.fan,
      'Smart Air Purifiers': FontAwesomeIcons.wind,
      'Smart Ovens': FontAwesomeIcons.breadSlice,
      'Smart Washing Machines': FontAwesomeIcons.soap,
      'Smart Dishwashers': FontAwesomeIcons.handsWash,
      'Smart Speakers': FontAwesomeIcons.volumeUp,
      'Smart Thermostat': FontAwesomeIcons.thermometerHalf,
      'Smart Hubs': FontAwesomeIcons.networkWired,
      'Smart Cameras': FontAwesomeIcons.camera,
      'Smart Refrigerators': FontAwesomeIcons.iceCream,
      'Smart Light Panels': FontAwesomeIcons.lightbulb,
      'LED Strips': FontAwesomeIcons.ribbon,
      'Smart Projectors': FontAwesomeIcons.projectDiagram,
      'Automated Home Theater Systems': FontAwesomeIcons.tv,
      'Voice Assistants': FontAwesomeIcons.microphone,
    }
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text('Smart Products for Residential & Commercial',style: TextStyle(fontWeight: FontWeight.bold,color: Colors.white,fontFamily: "Times New Roman")),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: categorizedProducts.entries.map((categoryEntry) {
              String category = categoryEntry.key;
              Map<String, IconData> products = categoryEntry.value;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: products.entries.map((productEntry) {
                        String product = productEntry.key;
                        IconData icon = productEntry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.all(16),
                              leading: Icon(
                                icon,
                                size: 40,
                                color: Colors.blueAccent,
                              ),
                              title: Text(
                                product,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                // Handle the tap action, maybe navigate to product details page
                                print('Tapped on $product');
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
