/*
 * @OnlyCurrentDoc
 */
const SHEET_NAME = 'Leads';
const QUEUED_TIMEOUT_MINUTES = 10; // Change this value if needed

// Cleanup the Queued status in all the sheets in a loop. Trigger is being set to run this once at midnight

function cleanupExpiredQueues() {
  const now = new Date();
  const sheets = SpreadsheetApp.getActiveSpreadsheet().getSheets();

  sheets.forEach(sheet => {
    const data = sheet.getDataRange().getValues();
    if (data.length === 0) return;

    const headers = data[0];
    const statusCol = headers.indexOf("Status");
    const queuedAtCol = headers.indexOf("Queued At");

    // Skip sheets that don't contain required columns
    if (statusCol === -1 || queuedAtCol === -1) return;

    for (let i = 1; i < data.length; i++) {
      const status = data[i][statusCol];
      const queuedAtStr = data[i][queuedAtCol];

      if (status === "Queued" && queuedAtStr) {
        const queuedAt = new Date(queuedAtStr);
        const diffMin = (now - queuedAt) / (1000 * 60);
        if (diffMin >= QUEUED_TIMEOUT_MINUTES) {
          sheet.getRange(i + 1, statusCol + 1).setValue('');
          sheet.getRange(i + 1, queuedAtCol + 1).setValue('');
        }
      }
    }
  });
}

function doGet(e) {
//  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);

  //   Moved Lines 99-131 to after e.parameter.authcheck (line 222) for Authorized users error handling check to precede the leads sheet check.  
// ✅ 1️⃣ Get state from request parameter, fallback if blank or National
//   var state = e.parameter.state;
//   var sheetName = (state && state !== '' && state !== 'National') ? state : SHEET_NAME;

//   // ✅ 2️⃣ Use this sheet name
//   const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);

//   // ✅ If the sheet does not exist, stop here and tell caller
//   if (!sheet) {
//     return ContentService.createTextOutput(
//       JSON.stringify({ status: 'error', message: 'Sheet not found', noLeads: true })
//     ).setMimeType(ContentService.MimeType.JSON);
//   }

//   // ✅ If the sheet exists but has only header row (or is empty)
//   if (sheet.getLastRow() <= 1) {
//     return ContentService.createTextOutput(
//       JSON.stringify({ status: 'error', message: 'No Leads available', noLeads: true })
//     ).setMimeType(ContentService.MimeType.JSON);
//   }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  
  const nameCol = headers.indexOf("Name");
  const phoneCol = headers.indexOf("Phone Number");
  const followUpCol = headers.indexOf("Follow up");
  const followUpDateCol = headers.indexOf("Follow up Date");
  const statusCol = headers.indexOf("Status");
  const queuedAtCol = headers.indexOf("Queued At");
  const dispositionCol = headers.indexOf("Disposition with Comments");
  const now = new Date();
  const todayStr = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd");

  // ✅ This checks if the URL has an action parameter for dispositions
  if (e.parameter.action == "getDispositions") {
    return getDispositions();
  }

  // If query param ?search=9876543210 is sent
  if (e.parameter.search) {
    const searchNumber = e.parameter.search.trim();
    for (let i = 1; i < data.length; i++) {
      let phone = data[i][phoneCol].toString().replace(/[^0-9]/g, '');
      if (phone.endsWith(searchNumber)) {
        const lead = {
          name: data[i][headers.indexOf("Name")],
          phone: data[i][phoneCol],
          rowIndex: i + 1,
        };
        // Include all previous disposition comments
        for (let j = 0; j < headers.length; j++) {
          if (headers[j].includes("Disposition with Comments")) {
            lead[headers[j]] = data[i][j];
          }
        }
        return ContentService.createTextOutput(JSON.stringify(lead)).setMimeType(ContentService.MimeType.JSON);
      }
    }
    // Not found
    return ContentService.createTextOutput(JSON.stringify({
      name: "",
      phone: "",
      rowIndex: -1
    })).setMimeType(ContentService.MimeType.JSON);
  }

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    const name = row[nameCol];
    const phone = row[phoneCol];
    const followUp = row[followUpCol]?.toString().toLowerCase();
    const followUpDateRaw = row[followUpDateCol];
    const status = row[statusCol];
    const disposition = row[dispositionCol];
    const isFollowUp = followUp === "yes";
    const isQueued = status === "Queued";
    const isDispositionEmpty = !disposition || disposition.toString().trim() === "";
    let isFollowUpDue = false;
    if (isFollowUp) {
      if (!followUpDateRaw) {
        // If no follow up date is given, treat as due
        isFollowUpDue = true;
      } else {
        const followUpDate = new Date(followUpDateRaw);
        const followUpDateStr = Utilities.formatDate(followUpDate, Session.getScriptTimeZone(), "yyyy-MM-dd");
        isFollowUpDue = followUpDateStr <= todayStr;
      }
    }
    // Determine eligibility:
    // If follow-up is "no", set isEligible to false immediately.
    // Otherwise, proceed with eligibility logic:
    // - User must not be queued
    // - AND either:
    //    a) it's a follow-up (yes) AND it's due
    //    b) OR it's not a follow-up AND the disposition is empty
    const isEligible = followUp === "no" ? false : (
      !isQueued && (
        (isFollowUp && isFollowUpDue) || (!isFollowUp && isDispositionEmpty)
      )
    );
    if (isEligible) {
      sheet.getRange(i + 1, statusCol + 1).setValue("Queued");
      sheet.getRange(i + 1, queuedAtCol + 1).setValue(now);
      // Prepare the lead object
      const lead = {
        name,
        phone,
        rowIndex: i + 1,
      };
      // Include all disposition comment columns
      for (let j = 0; j < headers.length; j++) {
        const header = headers[j];
        if (header.includes("Disposition with Comments")) {
          lead[header] = row[j];
        }
      }
      return ContentService.createTextOutput(
        JSON.stringify(lead)
      ).setMimeType(ContentService.MimeType.JSON);
    }
  }
  return ContentService.createTextOutput(
    JSON.stringify({ name: "", phone: "", rowIndex: -1 })
  ).setMimeType(ContentService.MimeType.JSON);
}

function getDispositions() {
  // ✅ Get the 'Dispositions' sheet from the active spreadsheet
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Dispositions");

  // ✅ Get the last row number in the sheet
  var lastRow = sheet.getLastRow();

  // ✅ If there are no rows beyond the header, return an alert message
  if (lastRow < 2) {
    return ContentService.createTextOutput(
      JSON.stringify({ error: "No dispositions found in column B. Please check your sheet." })
    ).setMimeType(ContentService.MimeType.JSON);
  }

  // ✅ Get column B, from row 2 to last row
  var data = sheet.getRange(2, 2, lastRow - 1).getValues();

  // ✅ Convert the 2D array to a simple flat array of strings, removing empty rows
  var dispositions = data.map(function(row) { return row[0]; })
                         .filter(function(item) { return item && item.toString().trim() !== ""; });

  // ✅ If the list is empty after filtering, return an alert message
  if (dispositions.length === 0) {
    return ContentService.createTextOutput(
      JSON.stringify({ error: "No valid dispositions found in column B." })
    ).setMimeType(ContentService.MimeType.JSON);
  }

  // ✅ Otherwise, return the dispositions list as JSON
  return ContentService.createTextOutput(JSON.stringify({ dispositions: dispositions }))
    .setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  //   const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(SHEET_NAME);

  // ✅ Grab state from request
  var state = e.parameter.state;
  var sheetName = (state && state !== '' && state !== 'National') ? state : SHEET_NAME;

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);

  const body = JSON.parse(e.postData.contents);
  const { 
    rowIndex, 
    disposition, 
    comments, 
    callerName, 
    callerPhone,
    callerState, 
    followUp, 
    followUpDate 
  } = body;
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  // Format timestamped comment
  const now = new Date();
  const timestamp = Utilities.formatDate(now, Session.getScriptTimeZone(), "yyyy-MM-dd HH:mm");
  const commentText = `${timestamp}\nDisposition: ${disposition}\nComments: ${comments}`;
  // Identify base disposition column
  const baseDispColIndex = headers.indexOf("Disposition with Comments");
  let dispColIndex = baseDispColIndex;
  // Find the next empty disposition column
  while (dispColIndex < headers.length && sheet.getRange(rowIndex, dispColIndex + 1).getValue()) {
    dispColIndex++;
  }
  // If we ran out of columns, add a new one
  if (dispColIndex >= headers.length) {
    const count = dispColIndex - baseDispColIndex + 1;
    const suffix = (n) => {
      if (n >= 11 && n <= 13) return "th";
      switch (n % 10) {
        case 1: return "st";
        case 2: return "nd";
        case 3: return "rd";
        default: return "th";
      }
    };
    const newHeader = `${count}${suffix(count)} Disposition with Comments`;
    const newHeaderCell = sheet.getRange(1, dispColIndex + 1);
    newHeaderCell.setValue(newHeader);
    newHeaderCell.setFontWeight("bold");
  }
  // Write disposition entry
  sheet.getRange(rowIndex, dispColIndex + 1).setValue(commentText);
  //----------------------------------------
  // ✅ New: Write to separate Last columns
  //----------------------------------------
  const lastTimestampCol = headers.indexOf("Last Contacted Timestamp") + 1;
  const lastCallerCol = headers.indexOf("Last Caller") + 1;
  const lastStatusCol = headers.indexOf("Last Disposition Status") + 1;
  const lastCommentsCol = headers.indexOf("Last Disposition Comments") + 1;
  if (lastTimestampCol > 0) {
    sheet.getRange(rowIndex, lastTimestampCol).setValue(timestamp);
  }
  if (lastCallerCol > 0) {
    sheet.getRange(rowIndex, lastCallerCol).setValue(`${callerName} | ${callerPhone}`);
  }
  if (lastStatusCol > 0) {
    sheet.getRange(rowIndex, lastStatusCol).setValue(disposition);
  }
  if (lastCommentsCol > 0) {
    sheet.getRange(rowIndex, lastCommentsCol).setValue(comments);
  }

  // Clear status and queued at
  const statusCol = headers.indexOf("Status") + 1;
  const queuedAtCol = headers.indexOf("Queued At") + 1;
  sheet.getRange(rowIndex, statusCol).setValue("");
  sheet.getRange(rowIndex, queuedAtCol).setValue("");
  // Handle follow-up logic
  const followUpCol = headers.indexOf("Follow up") + 1;
  const followUpDateCol = headers.indexOf("Follow up Date") + 1;
  if (followUp === "Yes") {
    sheet.getRange(rowIndex, followUpCol).setValue("Yes");
    sheet.getRange(rowIndex, followUpDateCol).setValue(followUpDate);
  } else {
    sheet.getRange(rowIndex, followUpCol).setValue("");
    sheet.getRange(rowIndex, followUpDateCol).setValue("");
  }
  //----------------------------------------
  // ✅ Add entry to "Call Log" sheet
  //----------------------------------------
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const callLogSheet = ss.getSheetByName("Call Log");
  // Get lead details from same row
  const leadNameCol = headers.indexOf("Name") + 1;
  const leadPhoneCol = headers.indexOf("Phone Number") + 1;
  const leadStateCol = headers.indexOf("Residing State") + 1;
  const leadName = sheet.getRange(rowIndex, leadNameCol).getValue();
  const leadPhone = sheet.getRange(rowIndex, leadPhoneCol).getValue();
  const leadState = sheet.getRange(rowIndex, leadStateCol).getValue();
  // ✅ Build row
  const logRow = [
    callerName,
    callerPhone,
    callerState,
    leadName,
    leadPhone,
    leadState,
    timestamp,	  // Lead Contacted Date
    disposition,
    comments,
    followUp,
    followUpDate
  ];
  // ✅ Append row to Call Log
  callLogSheet.appendRow(logRow);

  return ContentService.createTextOutput(
    JSON.stringify({ status: "success" })
  ).setMimeType(ContentService.MimeType.JSON);
}

// Authorization check
if (e.parameter.authcheck) {
  let phone = e.parameter.authcheck || '';
  phone = phone.trim();
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("Authorized Users");
  const lastRow = sheet.getLastRow();
  const range = sheet.getRange("A2:A" + lastRow);
  const dataRaw = range.getValues();
  const data = dataRaw.flat().map(x => String(x).trim());
  const foundIndex = data.findIndex(entry => entry.includes(phone));
  const isAuthorized = foundIndex !== -1;
  if (isAuthorized) {
    const foundRow = foundIndex + 2;
    const rowData = sheet.getRange(foundRow, 1, 1, 3).getValues()[0];
    const callerName = rowData[1];
    const callerState = rowData[2];

    // Find first empty login column
    const maxCols = sheet.getLastColumn();
    let col = 4;
    let found = false;
    while (col <= maxCols) {
      const header = sheet.getRange(1, col).getValue().toString().trim();
      const cellValue = sheet.getRange(foundRow, col).getValue();
      if (header.match(/^\d+(st|nd|rd|th) Login$/) && cellValue === "") {
        found = true;
        break;
      }
      col++;
    }
    if (!found) {
      col = maxCols + 1;
      const loginNumber = col - 3;
      let suffix = "th";
      if (loginNumber % 10 === 1 && loginNumber % 100 !== 11) suffix = "st";
      else if (loginNumber % 10 === 2 && loginNumber % 100 !== 12) suffix = "nd";
      else if (loginNumber % 10 === 3 && loginNumber % 100 !== 13) suffix = "rd";
      const loginHeader = loginNumber + suffix + " Login";
      const headerCell = sheet.getRange(1, col);
      headerCell.setValue(loginHeader);
      headerCell.setFontWeight("bold");
      headerCell.setHorizontalAlignment("center");
    }
    const rangeLogin = sheet.getRange(foundRow, col);
    rangeLogin.setValue(new Date());
    rangeLogin.setNumberFormat("yyyy-MM-dd HH:mm");
    rangeLogin.setHorizontalAlignment("center");
    return ContentService.createTextOutput(JSON.stringify({
      authorized: true,
      callerName: callerName,
      callerState: callerState
    })).setMimeType(ContentService.MimeType.JSON);
  }
  return ContentService.createTextOutput(JSON.stringify({ authorized: false })).setMimeType(ContentService.MimeType.JSON);
}
