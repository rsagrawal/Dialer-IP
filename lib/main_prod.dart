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
  final String apiUrl = 'https://script.google.com/macros/s/AKfycbwKnLIHPiqwbhsISuk7kYcb6x99Q10bYWNiLqt82skSA3iblANoRTBMS7woSI2hU_nf/exec';
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
		  title: Text("Lead Caller"),
		  backgroundColor: Colors.cyan,
		  actions: [
			PopupMenuButton<String>(
			  icon: CircleAvatar(
				child: Text(widget.callerName[0].toUpperCase()), // First letter as icon
				backgroundColor: Colors.grey,
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
				  child: Text('Home'),
				),
				PopupMenuItem<String>(
				  value: 'logout',
				  child: Text('Sign Out'),
				),
			  ],
			)
		  ],
		),

		body: isLoading
			? Center(
				child: Column(
				  mainAxisSize: MainAxisSize.min,
				  children: [
					CircularProgressIndicator(), // full default size
					if (showFetchMessage) ...[
					  SizedBox(height: 10),
					  Text(
						"Disposition Submitted and Fetching Next Lead",
						style: TextStyle(fontSize: 16),
						textAlign: TextAlign.center,
					  ),
					],
				  ],
				),
			  )

          : (currentLead == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "No more leads. Please try again in sometime",
                        style: TextStyle(fontSize: 18, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: fetchNextLead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Name: ${currentLead!['name']}", style: TextStyle(fontSize: 18)),
						Row(
						  children: [
							Text(
							  "Phone: ${currentLead!['phone']}",
							  style: TextStyle(fontSize: 18),
							),
							SizedBox(width: 8), // Add spacing between text and button
							ElevatedButton.icon(
							  icon: Icon(Icons.phone, color: Colors.white),
							  label: Text(
								"Call",
								style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
							  ),
							  onPressed: makeCall,
							  style: ElevatedButton.styleFrom(
								backgroundColor: Colors.blue),
							),
						  ],
						),


						
                        SizedBox(height: 10),
						
						DropdownButtonFormField<String>(
						  value: selectedDisposition,
						  decoration: InputDecoration(
							labelText: "Disposition",
							border: OutlineInputBorder(
							  borderRadius: BorderRadius.circular(8),
							),
							contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
						  ),
						  isExpanded: true, // ensures dropdown takes full width
						  menuMaxHeight: 250, // limit dropdown height on mobile
						  items: dispositionOptions.map((d) {
							return DropdownMenuItem<String>(
							  value: d,
							  child: Text(
								d,
								overflow: TextOverflow.ellipsis,
								style: TextStyle(fontSize: 14), // smaller text for compact feel
							  ),
							);
						  }).toList(),
						  onChanged: (val) => setState(() => selectedDisposition = val),
						),

                        SizedBox(height: 10),
                        TextField(
                          controller: commentController,
                          maxLines: 2,
                          decoration: InputDecoration(labelText: "Comments", border: OutlineInputBorder()),
                        ),
						
						SizedBox(height: 10),
						Container(
						  margin: EdgeInsets.only(bottom: 0), // ✅ Reduces bottom space
						  child: Row(
						  crossAxisAlignment: CrossAxisAlignment.center,
						  children: [
							Text("Follow up required?", style: TextStyle(fontWeight: FontWeight.bold, fontSize:15)),
							SizedBox(width: 10),
							Radio(
							  value: false,
							  groupValue: followUp,
							  onChanged: (val) => setState(() => followUp = val!),
							//  onChanged: (val) {
							//	setState(() {
							//	  followUp = val!;
							//	  if (!followUp) followUpDate = null; // ❗ Reset date if "No" is selected
							//	});
							//  },							  
							  visualDensity: VisualDensity.compact,
							),
							Text("No"),
							SizedBox(width: 10),
							Radio(
							  value: true,
							  groupValue: followUp,
							  onChanged: (val) => setState(() => followUp = val!),
						//	  onChanged: (val) {
						//		setState(() {
						//		  followUp = val!;
						//		  // ✅ Ensure a valid future date is set immediately
						//		  if (followUp && followUpDate == null) {
						//			followUpDate = DateTime.now().add(Duration(days: 1));
						//		  }
						//		});
						//	  },							  
							  visualDensity: VisualDensity.compact,
							),
							Text("Yes"),
						    ],
						  ),
						),
						
						if (followUp)
						  Row(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
							  Text(
								"Follow up Date:",
								style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
							  ),
							  SizedBox(width: 8),
							  showCalendar
								  ? Container(
									  width: 280,
									  decoration: BoxDecoration(
										border: Border.all(color: Colors.grey.shade400),
										borderRadius: BorderRadius.circular(8),
									  ),
									  padding: EdgeInsets.all(4),
									  child: Theme(
										data: Theme.of(context).copyWith(
										  textTheme: Theme.of(context).textTheme.copyWith(
											bodySmall: TextStyle(fontSize: 12),
											bodyMedium: TextStyle(fontSize: 12),
										  ),
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
									  ),
									)
									: GestureDetector(
										onTap: () {
										  setState(() {
											showCalendar = true; // Show the calendar again to change date
										  });
										},
										child: Text(
										  DateFormat('yyyy-MM-dd').format(followUpDate!),
										  style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
										),
									)

							],
						  ),


						SizedBox(height: 16),
							GestureDetector(
							  onTap: () {
								setState(() {
							      showPreviousComments = !showPreviousComments; 
								});
							  },
							  child: Row(
								mainAxisAlignment: MainAxisAlignment.spaceBetween,
								children: [
								  Text(
									"Previous Disposition Comments:",
									style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
								  ),
								  Icon(
									showPreviousComments
										? Icons.keyboard_arrow_up
										: Icons.keyboard_arrow_down,
									color: Colors.grey[700],
								  ),
								],
							  ),
							),
							if (showPreviousComments)
							  Container(
								margin: EdgeInsets.only(top: 8),
								padding: EdgeInsets.all(12),
								decoration: BoxDecoration(
								  border: Border.all(color: Colors.grey),
								  borderRadius: BorderRadius.circular(6),
								  color: Colors.grey.shade100,
								),
								constraints: BoxConstraints(minHeight: 50, maxHeight: 200),
								child: SingleChildScrollView(
								  child: Text(
									getMergedPreviousDispositions(currentLead!),
									style: TextStyle(fontSize: 14, color: Colors.black87),
								  ),
								),
							  ),

                        SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            //ElevatedButton.icon(
                            //  icon: Icon(Icons.phone, color: Colors.white),
                            //  label: Text("Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            //  onPressed: makeCall,
                            //  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            //),
							// FloatingActionButton(
							//  onPressed: makeCall,
							//  backgroundColor: Colors.green,
							//  child: Icon(Icons.phone, color: Colors.white),
							//  tooltip: 'Call',
							// ),
							
							InkWell(
							  onTap: makeCall,
							  child: CircleAvatar(
								backgroundColor: Colors.cyanAccent,
								radius: 25,
								child: Icon(Icons.phone, color: Colors.white),
							  ),
							),
							
							ElevatedButton.icon(
                              icon: Icon(Icons.save, color: Colors.white),
                              label: Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: saveDisposition,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                            ),
                            ElevatedButton.icon(
                              icon: Icon(Icons.send, color: Colors.white),
                              label: Text("Save & Next", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              onPressed: submitDisposition,
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                          ],
                        ),
						
                        SizedBox(height: 32),
						Center(
						  child: ElevatedButton.icon(
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
									  setState(() {
										currentLead = leadData;
										selectedDisposition = null;
										commentController.clear();
										showPreviousComments = true;
										followUp = false;
										followUpDate = null;
										showCalendar = true; // ✅ Always reset to calendar mode for fresh state

									  });
									},
									onFetchNextLead: () {
									  fetchNextLead(); // ✅ calls the main screen's function
									},
								  ),
								),
							  );
							},
							style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
						  ),
						),
						
                      ],
                    ),
                  ),
                )),
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
	
	// if (nameController.text.trim().isEmpty) {
	//   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Name is required.")));
	//   return;
	// }
	
	if (phoneController.text.trim().length != 10) {
	  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Enter valid 10-digit mobile number.")));
    try {
      final response = await http.post(uri, body: params);
      if (response.statusCode == 200) {
        setState(() {
          sentOtp = generatedOtp;
          otpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to +91$phone")));
		// ScaffoldMess0enger.of(context).showSnackBar(SnackBar(content: Text("OTP sent to +91$phone. OTP: $sentOtp")));
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
  
      setState(() { isLoading = true; }); // ✅ NEW

		final enteredOtp = otpController.text.trim();
		final callerPhone = phoneController.text.trim(); // 10-digit mobile typed from input

		if (enteredOtp != sentOtp) {
		  setState(() { isLoading = false; });
		  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid OTP")));
		  return;
		}

		final validationUrl = 'https://script.google.com/macros/s/AKfycbwKnLIHPiqwbhsISuk7kYcb6x99Q10bYWNiLqt82skSA3iblANoRTBMS7woSI2hU_nf/exec?authcheck=$callerPhone';
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
//		} else {
//		  setState(() { isLoading = false; });
//		  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Unauthorized user")));
//		}

		} else {    // ✅ Show Alert dialog instead of snackbar message used above in commented code
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
					  Navigator.of(context).pop(); // ✅ Close the dialog
					  Navigator.of(context).pushAndRemoveUntil(
						MaterialPageRoute(builder: (_) => LoginScreen()), // ✅ Use your LoginScreen here
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
	  if (!mounted) return; // ✅ Check if widget is still mounted
	  setState(() {
		canResend = false;
		secondsRemaining = 30;
	  });
	  countdownTimer?.cancel();
	  countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
		if (!mounted) { // ✅ Check before setState
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
	  countdownTimer?.cancel(); // ✅ Cancel timer on dispose
	  nameController.dispose();
	  phoneController.dispose();
	  otpController.dispose();
	  super.dispose();
	}


  @override
  Widget build(BuildContext context) {
  
      if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
	
    return Scaffold(
      appBar: AppBar(title: Text("Lead Connect : Sign in"), backgroundColor: Colors.cyan,),
		body: Center(
		  child: SingleChildScrollView(
			child: Padding(
			  padding: EdgeInsets.all(16),
			  child: Column(
				crossAxisAlignment: CrossAxisAlignment.center,
				children: [
					// ✅ Replace the Row with just one TextField with prefixText.
					// ✅ Comment out the Name field if you don’t need it.

					/*
					TextField(
					  controller: nameController,
					  decoration: InputDecoration(
						labelText: "Name",
						border: OutlineInputBorder(),
						contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
					  ),
					),
					SizedBox(height: 12),
					*/

					TextField(
					  controller: phoneController,
					  keyboardType: TextInputType.number,
					  maxLength: 10,
					  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
					  decoration: InputDecoration(
						prefixText: '+91 ',
						prefixStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
						labelText: "Enter Mobile Number (10 digits)",
						border: OutlineInputBorder(),
						contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
					  ),
					),

					if (otpSent)
						TextField(
						  controller: otpController,
						  keyboardType: TextInputType.number,
						  autofillHints: [AutofillHints.oneTimeCode],
						  decoration: InputDecoration(
							labelText: "Enter OTP",
							border: OutlineInputBorder(),
							contentPadding: EdgeInsets.symmetric(vertical: 20, horizontal: 12),
						  ),
						),
					  
				
					SizedBox(height: 20),
					ElevatedButton(
					  onPressed: otpSent ? verifyOtp : sendOtp,
					  style: ElevatedButton.styleFrom(
						backgroundColor: Colors.blue, // Button background color
						foregroundColor: Colors.white, // Text color
						shape: RoundedRectangleBorder(
						  borderRadius: BorderRadius.zero, // Square edges
						),
						padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Optional: larger touch area
					  ),
					  child: Text(
						otpSent ? "Verify OTP" : "Send OTP",
						style: TextStyle(fontSize: 16),
					  ),
					),
				
				if (otpSent)
				  Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
					  SizedBox(height: 12),
					  TextButton(
						onPressed: canResend ? sendOtp : null,
						style: TextButton.styleFrom(
						  foregroundColor: canResend ? Colors.blue : Colors.grey,
						),
						child: Text("Resend OTP"),
					  ),
					  if (!canResend)
						Padding(
						  padding: EdgeInsets.only(left: 12),
						  child: Text("Resend in $secondsRemaining s"),
						),
					],
				  ),
			  ],
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
		  title: Text("Lead Caller App"),
		  backgroundColor: Colors.cyan,
		  actions: [
			Row(
			  children: [
				// Text(callerName, style: TextStyle(fontSize: 16, color: Colors.white)),
				SizedBox(width: 8),
				PopupMenuButton<String>(
				  icon: CircleAvatar(
					child: Text(widget.callerName[0].toUpperCase()),
				  ),
				  onSelected: (value) {
					if (value == 'logout') {
					  // idleManager.cancelTimer();
					  Provider.of<IdleTimerProvider>(context, listen: false).cancelTimer();
					    DispositionCache().dispositionOptions.clear();
					  Navigator.of(context).pushAndRemoveUntil(
						MaterialPageRoute(builder: (_) => LoginScreen()),
						(route) => false,
					  );
					}
				  },
				  itemBuilder: (context) => [
					PopupMenuItem(value: 'logout', child: Text('Sign Out')),
				  ],
				),
			  ],
			)
		  ],
		),
		body: Padding(
		  padding: EdgeInsets.all(16),
		  child: SingleChildScrollView(
			child: Column(
			  crossAxisAlignment: CrossAxisAlignment.start,
			  children: [
				RichText(
				  text: TextSpan(
					children: [
					  TextSpan(
						text: "Dear ",
						style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
					  ),
					  TextSpan(
						text: "${widget.callerName} Ji",
						style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
					  ),
					  TextSpan(
						text: "\n\n Welcome to the Lead Connect App",
						style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
					  ),
					],
				  ),
				),
				SizedBox(height: 8),
				Text(
				  "You are now one step closer to making a difference in an individual's life.",
				  style: TextStyle(fontSize: 16),
				),
				SizedBox(height: 24),
				Text("Important Instructions:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
				SizedBox(height: 8),
				Table(
				  border: TableBorder.all(color: Colors.grey),
				  columnWidths: {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
				  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
				  children: [
					TableRow(children: [
					  InstructionCell("Fetch Lead", Colors.blue),
					  Padding(
						padding: EdgeInsets.all(8),
						child: Text("Fetches a new lead from the database."),
					  ),
					]),
					TableRow(children: [
					  InstructionCell("Save", Colors.blue),
					  Padding(
						padding: EdgeInsets.all(8),
						child: Text("Saves the current disposition and comments."),
					  ),
					]),
					TableRow(children: [
					  InstructionCell("Save & Next", Colors.green),
					  Padding(
						padding: EdgeInsets.all(8),
						child: Text("Saves and fetches the next lead immediately."),
					  ),
					]),
					TableRow(children: [
					  InstructionCell("Search Lead", Colors.orange),
					  Padding(
						padding: EdgeInsets.all(8),
						child: Text("Search a specific lead by mobile number."),
					  ),
					]),
				  ],
				),
				SizedBox(height: 32),
				Row(
				  crossAxisAlignment: CrossAxisAlignment.center,
				  children: [
					Text(
					  "Ready to call?",
					  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
					),
					SizedBox(width: 16),
					ElevatedButton.icon(
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
					  icon: Icon(Icons.play_arrow),
					  label: Text("Fetch Lead"),
					  style: ElevatedButton.styleFrom(
						backgroundColor: Colors.blue,
						foregroundColor: Colors.white,
						textStyle: TextStyle(fontWeight: FontWeight.bold),
					  ),
					),
				  ],
				),
			  ],
			),
		  ),
		)
	);
  }
  
	// New helper widget for the colored label
	Widget InstructionCell(String label, Color color) {
	  return Container(
		padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
		color: color,
		child: Text(
		  label,
		  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
		),
	  );
	}

}

