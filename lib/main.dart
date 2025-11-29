// IP DIALER version COPY from AOL-DIALER
// - Full updated Dart code with:
// - Follow up Yes/No radio buttons
// - Follow up DatePicker (only future dates)
// - Posting follow-up data on submit
// - Display logic improvements for mobile usability


// NOTE: SMSCountry login-based OTP verification
import 'dart:async';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'secrets.dart';

  
  String icallerName = '';
  String icallerState = '';
  String icallerPhone = '';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => IdleTimerProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lead Caller App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(), // ✅ your login screen as the start
    );
  }
}


// class CallLeadsApp extends StatelessWidget {
//   @override
  // Widget build(BuildContext context) {
    // return MaterialApp(
      // title: 'Lead Caller',
      // theme: ThemeData(primarySwatch: Colors.blue),
      // home: LeadCallerScreen(),
    // );
  // }
// }

class LeadCallerScreen extends StatefulWidget {

 final String callerName;
 final String callerPhone;
 final String callerState;
 final VoidCallback onLogout; // ✅ THIS MUST EXIST

LeadCallerScreen({
  required this.callerName,
  required this.callerPhone,
  required this.callerState,
  required this.onLogout,
});

  @override
  _LeadCallerScreenState createState() => _LeadCallerScreenState();
}

class SearchLeadScreen extends StatefulWidget {
	final Function(Map<String, dynamic>) onLeadSelected;
	final VoidCallback onFetchNextLead;

	SearchLeadScreen({required this.onLeadSelected, required this.onFetchNextLead});

  @override
  _SearchLeadScreenState createState() => _SearchLeadScreenState();
}

class DispositionSuccessScreen extends StatelessWidget {
	final VoidCallback onFetchNextLead;
	final Function(Map<String, dynamic>) onLeadSelected; // ✅ add this

	DispositionSuccessScreen({
	  required this.onFetchNextLead,
	  required this.onLeadSelected,
	});

  @override
  Widget build(BuildContext context) {
  print("BUILDING LeadCallerScreen");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
      idleManager.resetTimer(() {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Success"),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    icallerName.isNotEmpty ? icallerName[0].toUpperCase() : "?",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                PopupMenuButton<String>(
					onSelected: (value) {
					  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
						if (value == 'home') {
						  idleManager.resetTimer(() {
							Navigator.of(context).pushAndRemoveUntil(
							  MaterialPageRoute(builder: (_) => LoginScreen()),
							  (route) => false,
							);
						  });

						  Navigator.of(context).pushAndRemoveUntil(
							MaterialPageRoute(
							  builder: (_) => InstructionScreen(
								callerName: icallerName,
								callerPhone: icallerPhone,
								callerState: icallerState,
							  ),
							),
							(route) => false,
						  );
						}
						else if (value == 'logout') {
							idleManager.cancelTimer();
							  DispositionCache().dispositionOptions.clear();
							Navigator.pushAndRemoveUntil(
							  context,
							  MaterialPageRoute(builder: (_) => LoginScreen()),
							  (route) => false,
							);
						  }
					},

                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'home', child: Text('Home')),
                    PopupMenuItem(value: 'logout', child: Text('Sign Out')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
			children: [
			  Icon(Icons.check_circle, color: Colors.green, size: 80),
			  SizedBox(height: 20),
			  Text(
				"Disposition submitted successfully!",
				style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
				textAlign: TextAlign.center,
			  ),
			  SizedBox(height: 30),
			  Text(
				"Ready to call next lead?",
				style: TextStyle(fontSize: 20),
				textAlign: TextAlign.center,
			  ),
			  SizedBox(height: 20),
			  ElevatedButton(
				onPressed: () {
				  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
				  idleManager.resetTimer(() {
					Navigator.of(context).pushAndRemoveUntil(
					  MaterialPageRoute(builder: (_) => LoginScreen()),
					  (route) => false,
					);
				  });				
				  Navigator.pop(context); // Close success screen
				  onFetchNextLead();      // Trigger next lead from queue
				},
				child: Text(
				  "Fetch Next Lead",
				  style: TextStyle(
					fontSize: 16,
					color: Colors.white,
					fontWeight: FontWeight.bold,
				  ),
				),
				style: ElevatedButton.styleFrom(
				  backgroundColor: Colors.green,
				  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
				),
			  ),
			  SizedBox(height: 32),
			  ElevatedButton.icon(
				icon: Icon(Icons.search, color: Colors.white),
				label: Text(
				  "Search a Lead",
				  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
				),
				onPressed: () {
				  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
				  idleManager.resetTimer(() {
					Navigator.of(context).pushAndRemoveUntil(
					  MaterialPageRoute(builder: (_) => LoginScreen()),
					  (route) => false,
					);
				  });				
				  Navigator.push(
					context,
					MaterialPageRoute(
					  builder: (context) => SearchLeadScreen(
						onLeadSelected: (leadData) {
						  idleManager.resetTimer(() {
							Navigator.of(context).pushAndRemoveUntil(
							  MaterialPageRoute(builder: (_) => LoginScreen()),
							  (route) => false,
							);
						  });						
						  // ✅ This correctly updates your lead with searched data
						  onLeadSelected(leadData);
						  Navigator.pop(context); // Close Search screen
						  // Navigator.pop(context); // Close Success screen
						},
						onFetchNextLead: () {
						  idleManager.resetTimer(() {
							Navigator.of(context).pushAndRemoveUntil(
							  MaterialPageRoute(builder: (_) => LoginScreen()),
							  (route) => false,
							);
						  });						
						  Navigator.pop(context); // Or you can omit this if not needed
						  // Navigator.pop(context);
						  onFetchNextLead();
						},
					  ),
					),
				  );
				},
				style: ElevatedButton.styleFrom(
				  backgroundColor: Colors.orange,
				  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
				),
			  ),
			],

        ),
      ),
    );
  }
}





class _SearchLeadScreenState extends State<SearchLeadScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String? errorMessage;
  bool isSearching = false;

  Future<void> searchLead() async {
  
  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
  idleManager.resetTimer(() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }); 
 
	final rawInput = _phoneController.text.trim();

	// Remove all non-digit characters: +, -, (), spaces, etc.
	String cleaned = rawInput.replaceAll(RegExp(r'[^0-9]'), '');

	// If 12-digit number starting with 91 → keep last 10 digits
	if (cleaned.length == 12 && cleaned.startsWith('91')) {
	  cleaned = cleaned.substring(2);
	}

	// If 11-digit number starting with 0 → remove the leading 0
	else if (cleaned.length == 11 && cleaned.startsWith('0')) {
	  cleaned = cleaned.substring(1);
	}

	// Final validation: must be exactly 10 digits
	if (cleaned.length != 10) {
	  setState(() => errorMessage = "Enter a valid 10-digit mobile number.");
	  return;
	}

    setState(() {
      isSearching = true;
      errorMessage = null;
    });

    // final apiUrl = 'https://script.google.com/macros/s/AKfycbzzvEt0ChdL_pohOxjqS9R_MSgdiTFEWwh5QbarngqGZAHe5BKwSymSaftXsb16_5Wz/exec?search=$cleaned';
	final apiUrl = 'https://script.google.com/macros/s/AKfycbwKnLIHPiqwbhsISuk7kYcb6x99Q10bYWNiLqt82skSA3iblANoRTBMS7woSI2hU_nf/exec?search=$cleaned&state=$icallerState';

    final response = await http.get(Uri.parse(apiUrl));

    setState(() => isSearching = false);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
		
		// Sheet not found or empty sheet with no leads
		if (data['noLeads'] == true) {
		  ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('No Leads Available')),
		  );
		  return;
		}	  
      
	  if (data['name'] != "") {
        widget.onLeadSelected(data);
        Navigator.pop(context);
      } else {
        setState(() => errorMessage = "Lead not found. Please verify and try again.");
      }
    } else {
      setState(() => errorMessage = "Error connecting to server. Please try again.");
    }
  }
  
  void fetchNextLead() {

  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
  idleManager.resetTimer(() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  });  
  
  widget.onFetchNextLead(); // Delegate to main screen
  Navigator.pop(context);   // Close this screen
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Search Lead")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.number,
              maxLength: 15,
              decoration: InputDecoration(labelText: "Enter Mobile Number (10 digits)", border: OutlineInputBorder()),
            ),
            SizedBox(height: 10),
            if (errorMessage != null)
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
            // SizedBox(height: 10),
			ElevatedButton(
			  onPressed: searchLead,
			  child: isSearching
				  ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
				  : Text(
					  "Search",
					  style: TextStyle(
						fontSize: 18,               // 👈 bigger text
						fontWeight: FontWeight.bold, // 👈 bold
						color: Colors.white,         // 👈 white text
					  ),
					),
			  style: ElevatedButton.styleFrom(
				backgroundColor: Colors.orange,
				foregroundColor: Colors.white,         // fallback for icon/text color
				padding: EdgeInsets.symmetric(         // 👈 bigger touch area
				  horizontal: 32,
				  vertical: 16,
				),
				textStyle: TextStyle(
				  fontWeight: FontWeight.bold,         // extra safety: bold in style too
				),
			  ),
			),
			
			SizedBox(height: 32),
			Text(
			  "If you are unable to find the lead, you can Fetch new Lead here",
			  textAlign: TextAlign.center,
			  style: TextStyle(fontSize: 16, color: Colors.black87),
			),
			SizedBox(height: 10),
			Center(
			  child: ElevatedButton(
				onPressed: fetchNextLead,
				style: ElevatedButton.styleFrom(
				  backgroundColor: Colors.green,
				  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
				),
				child: Text(
				  "Fetch Next Lead",
				  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
				),
			  ),
			),
					
          ],
        ),
      ),
    );
  }
}

class DispositionCache {
  static final DispositionCache _instance = DispositionCache._internal();
  factory DispositionCache() => _instance;
  DispositionCache._internal();

  List<String> dispositionOptions = [];
}

class _LeadCallerScreenState extends State<LeadCallerScreen> {
  final String apiUrl = 'https://script.google.com/macros/s/AKfycbw-nNqsPVzFYIFQUj0g9PyIqy3PIDySon-akYGe9thmHSY1BLgLoQ6wtwpX7qQgCmfO/exec';
  Map<String, dynamic>? currentLead;
  String? selectedDisposition;
  TextEditingController commentController = TextEditingController();
  bool isLoading = false;
  bool showFetchMessage = false; // <-- Spinner message while loading screen
  String? persistentMessage;

  bool followUp = false;
  DateTime? followUpDate;
  bool showCalendar = true;
  bool showPreviousComments = true;

 // final List<String> dispositionOptions = [
  //  "Invalid Number",
  //  "No Answer - Not Reachable",
  //  "Answered - Busy Call back in X Days",
  //  "Answered - Resend the Nomination Link",
  //  "Answered - Interested & Willing to Complete Profile",
 //   "Answered - Not Interested to Continue as SY/PR",
 //   "Answered - Not available for a specific period",
 //   "Answered - Interested but relocated",
 //   "Answered - Others"
 // ];
 
	 // ✅ Replace your hardcoded dispositionOptions with an empty list
//	List<String> dispositionOptions = [];
	List<String> get dispositionOptions => DispositionCache().dispositionOptions;

  bool get isCommentRequired => selectedDisposition == "Answered - Others";

  String getMergedPreviousDispositions(Map<String, dynamic> lead) {
    final dispositionKeys = lead.keys.where((k) => k.contains('Disposition with Comments')).toList();
    final List<Map<String, dynamic>> dispositionEntries = [];

    for (var key in dispositionKeys) {
      final val = lead[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        final lines = val.toString().split('\n');
        if (lines.isNotEmpty) {
          final timestampStr = lines[0].trim();
          DateTime? dt;
          try {
            dt = DateTime.parse(timestampStr);
          } catch (_) {
            dt = null;
          }
          dispositionEntries.add({
            'timestamp': dt ?? DateTime(1970),
            'text': val.toString(),
          });
        }
      }
    }

    if (dispositionEntries.isEmpty) return "Past Disposition info not available";

    dispositionEntries.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    return dispositionEntries.map((e) => e['text'] as String).join('\n\n');
  }

  void fetchNextLead({bool fromDisposition = false}) async {
  
  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
  idleManager.resetTimer(() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  });
  
    if (isLoading) return; 
	
    setState(() {
      isLoading = true;
      showFetchMessage = fromDisposition; // Show message only if called from disposition

	  showPreviousComments = true;
      persistentMessage = null;
      followUp = false;
      followUpDate = null;
	  showCalendar = true; // ✅ Always reset to calendar mode for fresh state
    });

    // final response = await http.get(Uri.parse(apiUrl));
	final response = await http.get(Uri.parse('$apiUrl?state=${widget.callerState}'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
	  
		if (data['noLeads'] == true) {
		  // ✅ If sheet not found OR no leads, show message
		setState(() {
		  currentLead = null;               // ✅ No lead
		  selectedDisposition = null;       // ✅ Clear disposition
		  commentController.clear();        // ✅ Clear comment box
		  isLoading = false;                // ✅ Spinner off
		  showFetchMessage = false;         // ✅ Flag cleared
		});

		  ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('No Leads Available')),
		  );

		  return; // ✅ Stop here — no more processing
		}	  
	  
      if (data['message'] == null && data['name'] != "") {
        setState(() {
          currentLead = data;
          selectedDisposition = null;
          commentController.clear();
          isLoading = false;
	      showFetchMessage = false; // Reset after fetch is done

        });
      } else {
        setState(() {
          currentLead = null;
          persistentMessage = data['message'] ?? 'No more leads';
          isLoading = false;
	      showFetchMessage = false; // Reset after fetch is done

        });
      }
    } else {
      setState(() {
        persistentMessage = "Failed to fetch lead.";
        isLoading = false;
	    showFetchMessage = false; // Reset after fetch is done

      });
    }
  }

  void submitDisposition() async {

  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
  idleManager.resetTimer(() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  });  
  
    if (selectedDisposition == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Select a disposition.")));
      return;
    }
    if (isCommentRequired && commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Comment required for this disposition.")));
      return;
    }
    if (followUp && followUpDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Select a follow-up date.")));
      return;
    }

    setState(() {
	  isLoading = true;
	  showFetchMessage = true; // show message only during fetch after disposition
	});

    final response = await http.post(
      // Uri.parse(apiUrl),
	  Uri.parse('$apiUrl?state=${widget.callerState}'),
      body: json.encode({
        'rowIndex': currentLead!['rowIndex'],
        'disposition': selectedDisposition,
		// 'comments': commentController.text.trim(),
		// 'comments': '${commentController.text.trim()} | $callerName | $callerPhone',
		// 'comments': '${commentController.text.trim()} | ${widget.callerName} | ${widget.callerPhone}',
		// 'comments': '${commentController.text.trim()}\nCaller: ${widget.callerName} | ${widget.callerPhone}',
		  'comments': commentController.text.trim(),
		  'callerName': widget.callerName,
		  'callerPhone': widget.callerPhone,		
		  'callerState': widget.callerState,

        'followUp': followUp ? 'Yes' : 'No',
        'followUpDate': followUp ? DateFormat('yyyy-MM-dd').format(followUpDate!) : '',
      }),
    );

  if (response.statusCode == 200) {
    setState(() {
      isLoading = false; // clear immediately!
    });
    fetchNextLead(fromDisposition: true);
	} else {
	  setState(() {
		isLoading = false;
		showFetchMessage = false;
	  });
	  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to submit disposition.")));
	}
  }
  
    void makeCall() async {
    final Uri url = Uri.parse("tel:${currentLead!['phone']}");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unable to launch dialer.")));
    }
  }
  
  void saveDisposition() async {

  final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
  idleManager.resetTimer(() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  });
  
  if (selectedDisposition == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Select a disposition.")));
    return;
  }
  if (isCommentRequired && commentController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Comment required for this disposition.")));
    return;
  }
  if (followUp && followUpDate == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Select a follow-up date.")));
    return;
  }

  setState(() => isLoading = true);

  final response = await http.post(
    // Uri.parse(apiUrl),
	Uri.parse('$apiUrl?state=${widget.callerState}'),
    body: json.encode({
      'rowIndex': currentLead!['rowIndex'],
      'disposition': selectedDisposition,
//	  'comments': commentController.text.trim(),
//	  'comments': '${commentController.text.trim()} | $callerName | $callerPhone',
//	  'comments': '${commentController.text.trim()} | ${widget.callerName} | ${widget.callerPhone}',

	  'comments': commentController.text.trim(),
	  'callerName': widget.callerName,
	  'callerPhone': widget.callerPhone,
	  'callerState': widget.callerState,

      'followUp': followUp ? 'Yes' : 'No',
      'followUpDate': followUp ? DateFormat('yyyy-MM-dd').format(followUpDate!) : '',
    }),
  );

  setState(() => isLoading = false);

  if (response.statusCode == 200) {
	Navigator.push(
	  context,
	  MaterialPageRoute(
		builder: (context) => DispositionSuccessScreen(
		  onFetchNextLead: fetchNextLead,
		  onLeadSelected: (leadData) {
			setState(() {
			  currentLead = leadData;
			  selectedDisposition = null;
			  commentController.clear();
			  showPreviousComments = true;
			  followUp = false;
			  followUpDate = null;
			  isLoading = false; // ✅ fixes the blank screen
			});
		  },
		),
	  ),
	);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to save disposition.")));
  }
}

	Future<void> fetchDispositions() async {
	  // ✅ Make the GET request to your Apps Script with the action parameter
	  final response = await http.get(Uri.parse('$apiUrl?action=getDispositions'));

	  if (response.statusCode == 200) {
		final data = json.decode(response.body);

		// ✅ Check if the server sent an error message instead of dispositions
		if (data.containsKey('error')) {
		  // ✅ Show an alert dialog to inform the user
		  if (mounted) {
			showDialog(
			  context: context,
			  builder: (context) => AlertDialog(
				title: Text('No Dispositions Found'),
				content: Text(data['error']),
				actions: [
				  TextButton(
					onPressed: () => Navigator.of(context).pop(),
					child: Text('OK'),
				  ),
				],
			  ),
			);
		  }
		} else {
		  // ✅ If valid, update the list normally
		  setState(() {
			DispositionCache().dispositionOptions = List<String>.from(data['dispositions']);
		  });
		}
	  } else {
		// ✅ Handle request failure
		print('Failed to load dispositions');
	  }
	}

	@override
	void initState() {
	  super.initState();
	
	  // ✅ Proper: show spinner while fetching
//	  setState(() {
//		isLoading = true;
//	  });
		
	  if (dispositionOptions.isEmpty) {
		// ✅ Fetch dispositions first, then leads
		fetchDispositions();
		}
		fetchNextLead();

	  WidgetsBinding.instance.addPostFrameCallback((_) {
		final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
		idleManager.resetTimer(() {
		  Navigator.of(context).pushAndRemoveUntil(
			MaterialPageRoute(builder: (_) => LoginScreen()),
			(route) => false,
		  );
		});
	  });
	}

//  @override
//  void initState() {
//    super.initState();
//    fetchNextLead();
	
//	  WidgetsBinding.instance.addPostFrameCallback((_) {
//		final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
//		idleManager.resetTimer(() {
//		  Navigator.of(context).pushAndRemoveUntil(
//			MaterialPageRoute(builder: (_) => LoginScreen()),
//			(route) => false,
//		  );
//		});
//	  });	
//  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lead Caller", style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : "U",
                  style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                ),
              ),
              onSelected: (value) {
                final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
                if (value == 'logout') {
                  Provider.of<IdleTimerProvider>(context, listen: false).cancelTimer();
                    DispositionCache().dispositionOptions.clear();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                }
                if (value == 'home') {
                  idleManager.resetTimer(() {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                      (route) => false,
                    );
                  });

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => InstructionScreen(
                        callerName: widget.callerName,
                        callerPhone: widget.callerPhone,
                        callerState: widget.callerState,
                      ),
                    ),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'home',
                  child: Row(children: [Icon(Icons.home, color: Colors.grey), SizedBox(width: 8), Text('Home')]),
                ),
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(children: [Icon(Icons.logout, color: Colors.grey), SizedBox(width: 8), Text('Sign Out')]),
                ),
              ],
            ),
          ),
        ],
      ),

      body: Container(
        decoration: BoxDecoration(color: Colors.grey[50]),
        child: _buildBody(),
      ),
    );
  }


// NOTE: SMSCountry login-based OTP verification

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.deepOrange),
            if (showFetchMessage) ...[
              SizedBox(height: 16),
              Text(
                "Submitting & Fetching Next Lead...",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    if (currentLead == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
              SizedBox(height: 24),
              Text(
                "All Caught Up!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(height: 8),
              Text(
                "No more leads available right now.\nPlease try again later.",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: fetchNextLead,
                icon: Icon(Icons.refresh),
                label: Text("Check Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Lead Details Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade50,
                        child: Icon(Icons.person, color: Colors.blue),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentLead!['name'] ?? "Unknown",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Lead",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Phone Number", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(
                            currentLead!['phone'] ?? "",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.phone, size: 20),
                        label: Text("CALL"),
                        onPressed: makeCall,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Disposition Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Disposition", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDisposition,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    hint: Text("Select Outcome"),
                    isExpanded: true,
                    menuMaxHeight: 300,
                    items: dispositionOptions.map((d) {
                      return DropdownMenuItem<String>(
                        value: d,
                        child: Text(d, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedDisposition = val),
                  ),

                  SizedBox(height: 16),
                  Text("Comments", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Enter call notes...",
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  Divider(),
                  SizedBox(height: 8),

                  // Follow Up Section
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
                      SizedBox(width: 8),
                      Text("Follow up required?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      Spacer(),
                      Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: followUp,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) => setState(() => followUp = val!),
                          ),
                          Text("No"),
                          SizedBox(width: 12),
                          Radio<bool>(
                            value: true,
                            groupValue: followUp,
                            activeColor: Colors.deepOrange,
                            onChanged: (val) => setState(() => followUp = val!),
                          ),
                          Text("Yes"),
                        ],
                      ),
                    ],
                  ),
                  
                  if (followUp)
                    Container(
                      margin: EdgeInsets.only(top: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Select Date:", style: TextStyle(fontSize: 12, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          showCalendar
                            ? Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(primary: Colors.deepOrange),
                                ),
                                child: CalendarDatePicker(
                                  initialDate: followUpDate ?? DateTime.now().add(Duration(days: 1)),
                                  firstDate: DateTime.now().add(Duration(days: 1)),
                                  lastDate: DateTime.now().add(Duration(days: 365)),
                                  onDateChanged: (picked) {
                                    setState(() {
                                      followUpDate = picked;
                                      showCalendar = false;
                                    });
                                  },
                                ),
                              )
                            : ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.event_available, color: Colors.deepOrange),
                                title: Text(
                                  DateFormat('EEEE, d MMMM y').format(followUpDate!),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                trailing: TextButton(
                                  child: Text("Change", style: TextStyle(color: Colors.deepOrange)),
                                  onPressed: () => setState(() => showCalendar = true),
                                ),
                              ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Previous Comments Accordion
          Card(
            elevation: 0,
            color: Colors.grey.shade200,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text("Previous History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              leading: Icon(Icons.history, color: Colors.grey[700]),
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  color: Colors.white,
                  child: Text(
                    getMergedPreviousDispositions(currentLead!),
                    style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: saveDisposition,
                  icon: Icon(Icons.save_outlined),
                  label: Text("SAVE"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue[700],
                    side: BorderSide(color: Colors.blue.shade200),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: submitDisposition,
                  icon: Icon(Icons.check_circle_outline),
                  label: Text("SAVE & NEXT"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: () {
                final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
                idleManager.resetTimer(() {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                });              
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchLeadScreen(
                      onLeadSelected: (leadData) {
                        setState(() {
                          currentLead = leadData;
                          selectedDisposition = null;
                          commentController.clear();
                          showPreviousComments = true;
                          followUp = false;
                          followUpDate = null;
                          showCalendar = true;
                        });
                      },
                      onFetchNextLead: () {
                        fetchNextLead();
                      },
                    ),
                  ),
                );
              },
              icon: Icon(Icons.search, color: Colors.grey[700]),
              label: Text("Search for a specific lead", style: TextStyle(color: Colors.grey[700])),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }
}

// NOTE: SMSCountry login-based OTP verification

class IdleTimerProvider with ChangeNotifier {
  Timer? _timer;

  void resetTimer(VoidCallback onTimeout) {
    _timer?.cancel();
    _timer = Timer(Duration(minutes: 30), onTimeout);
  }

  void cancelTimer() {
    _timer?.cancel();
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  String sentOtp = "";
  
  bool canResend = false;
  int secondsRemaining = 30;
  Timer? countdownTimer;
    
  bool isLoading = false;

  void sendOtp() async {
    final phone = phoneController.text.trim();
    final generatedOtp = generateOtp();
	
	if (phoneController.text.trim().length != 10) {
	  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter valid 10-digit mobile number.")));
	  return;
	}
	
    final uri = Uri.parse('https://api.smscountry.com/SMSCwebservice_bulk.aspx');
    final params = {
      'User': Secrets.smsCountryUser,
      'passwd': Secrets.smsCountryPass,
      'mobilenumber': '91$phone',
      'message': 'OTP for mobile verification is: $generatedOtp. Thank you. JGD.',
      'sid': Secrets.smsCountrySid,
      'mtype': 'N',
      'DR': 'Y'
    };
	
    try {
      final response = await http.post(uri, body: params);
      if (response.statusCode == 200) {
        setState(() {
          sentOtp = generatedOtp;
          otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to +91$phone")));
		startResendCountdown();

      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to send OTP")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

	String generateOtp() {
	  final random = Random.secure(); // More secure than Random()
	  return (random.nextInt(900000) + 100000).toString(); // 6-digit: 100000–999999
	}


  void verifyOtp() async {
  
      setState(() { isLoading = true; });

		final enteredOtp = otpController.text.trim();
		final callerPhone = phoneController.text.trim(); // 10-digit mobile typed from input

		if (enteredOtp != sentOtp) {
		  setState(() { isLoading = false; });
		  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
		  return;
		}

		final validationUrl = 'https://script.google.com/macros/s/AKfycbw-nNqsPVzFYIFQUj0g9PyIqy3PIDySon-akYGe9thmHSY1BLgLoQ6wtwpX7qQgCmfO/exec?authcheck=$callerPhone';
		final response = await http.get(Uri.parse(validationUrl));
		final data = json.decode(response.body);

		if (data['authorized'] == true) {
		  setState(() {
			icallerName = data['callerName'];
			icallerState = data['callerState'];
			icallerPhone = callerPhone;  // Save the phone number globally too!
		  });

		  Navigator.pushReplacement(
			context,
			MaterialPageRoute(
			  builder: (_) => InstructionScreen(
				callerName: icallerName,
				callerPhone: icallerPhone,
				callerState: icallerState,
			  ),
			),
		  );

		} else {    
		  setState(() { isLoading = false; });

		  if (mounted) {
			showDialog(
			  context: context,
			  builder: (context) => AlertDialog(
				title: Text('Unauthorized'),
				content: Text('Unauthorized Number. Contact Admin'),
				actions: [
				  TextButton(
					onPressed: () {
					  Navigator.of(context).pop(); 
					  Navigator.of(context).pushAndRemoveUntil(
						MaterialPageRoute(builder: (_) => LoginScreen()), 
						(route) => false,
					  );
					},
					child: Text('OK'),
				  ),
				],
			  ),
			);
		  }
		}
  }
  
	void startResendCountdown() {
	  if (!mounted) return; 
	  setState(() {
		canResend = false;
		secondsRemaining = 30;
	  });
	  countdownTimer?.cancel();
	  countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
		if (!mounted) { 
		  timer.cancel();
		  return;
		}
		if (secondsRemaining > 0) {
		  setState(() {
			secondsRemaining--;
		  });
		} else {
		  timer.cancel();
		  setState(() {
			canResend = true;
		  });
		}
	  });
	}

	@override
	void dispose() {
	  countdownTimer?.cancel(); 
	  nameController.dispose();
	  phoneController.dispose();
	  otpController.dispose();
	  super.dispose();
	}


  @override
  Widget build(BuildContext context) {
  
      if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }
	
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Header Area
                  Icon(Icons.phone_in_talk, size: 80, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Lead Connect",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Sign in to start calling",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 40),

                  // Login Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            otpSent ? "Verification" : "Welcome Back",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 30),

                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_android, color: Colors.orange),
                              prefixText: '+91 ',
                              prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                              labelText: "Mobile Number",
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.orange, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            enabled: !otpSent, // Disable phone input after OTP sent
                          ),

                          if (otpSent) ...[
                            SizedBox(height: 20),
                            TextField(
                              controller: otpController,
                              keyboardType: TextInputType.number,
                              autofillHints: [AutofillHints.oneTimeCode],
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.orange),
                                labelText: "Enter OTP",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.orange, width: 2),
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              ),
                            ),
                          ],
                          
                          SizedBox(height: 30),
                          
                          ElevatedButton(
                            onPressed: otpSent ? verifyOtp : sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              elevation: 2,
                            ),
                            child: Text(
                              otpSent ? "VERIFY OTP" : "SEND OTP",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),

                          if (otpSent) ...[
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Didn't receive code? ", style: TextStyle(color: Colors.grey[600])),
                                canResend 
                                  ? TextButton(
                                      onPressed: sendOtp,
                                      child: Text("Resend", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                                    )
                                  : Text(
                                      "Resend in ${secondsRemaining}s",
                                      style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                                    ),
                              ],
                            ),
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    otpSent = false;
                                    otpController.clear();
                                  });
                                },
                                child: Text("Change Number", style: TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 40),
                  Text(
                    "Powered by Art of Living",
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InstructionScreen extends StatefulWidget {
  final String callerName;
  final String callerPhone;
  final String callerState;

const InstructionScreen({required this.callerName, required this.callerPhone, required this.callerState});

  @override
  _InstructionScreenState createState() => _InstructionScreenState();
}

class _InstructionScreenState extends State<InstructionScreen> {
  
  @override
  void initState() {
    super.initState();
    final idleManager = Provider.of<IdleTimerProvider>(context, listen: false);
    idleManager.resetTimer(() {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => LoginScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lead Caller App", style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  widget.callerName.isNotEmpty ? widget.callerName[0].toUpperCase() : "U",
                  style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
                ),
              ),
              onSelected: (value) {
                if (value == 'logout') {
                  Provider.of<IdleTimerProvider>(context, listen: false).cancelTimer();
                    DispositionCache().dispositionOptions.clear();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                    (route) => false,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(value: 'logout', child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('Sign Out'),
                  ],
                )),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50], // Light background
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${widget.callerName} Ji! 🙏",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "You are now one step closer to making a difference in an individual's life.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.4),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              Text("Quick Guide", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87)),
              SizedBox(height: 16),

              // Instructions Grid
              GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildInstructionCard("Fetch Lead", "Get a new lead", Icons.cloud_download, Colors.blue),
                  _buildInstructionCard("Save", "Save disposition", Icons.save, Colors.blue),
                  _buildInstructionCard("Save & Next", "Save & fetch next", Icons.next_plan, Colors.green),
                  _buildInstructionCard("Search Lead", "Find by phone", Icons.search, Colors.orange),
                ],
              ),

              SizedBox(height: 32),
              
              // Call to Action
              Center(
                child: Column(
                  children: [
                    Text(
                      "Ready to start calling?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LeadCallerScreen(
                                callerName: widget.callerName,
                                callerPhone: widget.callerPhone,
                                callerState: widget.callerState,
                                onLogout: () {
                                  Provider.of<IdleTimerProvider>(context, listen: false).cancelTimer();
                                   DispositionCache().dispositionOptions.clear();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(builder: (_) => LoginScreen()),
                                    (route) => false,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        icon: Icon(Icons.play_arrow_rounded, size: 28),
                        label: Text("START CALLING", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      )
    );
  }
  
  Widget _buildInstructionCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4)),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

}

