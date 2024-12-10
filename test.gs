function sendEmails() {
  // Get the active spreadsheet and relevant sheets
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Emails_to_send');
  var sentSheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('EmailStatus');
  var trackingSheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Onboarding_Tracker12');
  
  var data = sheet.getDataRange().getValues(); // Get all data from the DataSheet
  var trackingData = trackingSheet.getRange('A5:A100').getValues(); // Get IDs from TrackingSheet A5:A100
  var trackingRange = trackingSheet.getRange('BV5:CC100').getValues(); // Get BV:CC from TrackingSheet
  
  var logEntries = [];
  
  // Loop through each row (starting from row 4 to skip header)
  for (var i = 4; i < data.length; i++) {
    var id = data[i][0]; // Column A: ID
    var legalName = data[i][1]; // Column B: Legal Name
    var emailAddress = data[i][2]; // Column C: Email Address
    var subject = data[i][24]; // Column Y: Subject (Index 24 is column Y)
    var body = data[i][25]; // Column Z: Body (Index 25 is column Z)
    var htmlBody = data[i][27]; // Column AB: HTML Body (Index 27 is column A8)
    var attach = data[i][26]; // Column AA: Attachments (Index 26 is column AA) - file URL or file ID

    var attachments = [];

    // Check if there's an attachment (assumed to be a file URL or file ID in Column AA)
    if (attach && attach.trim()) {
      try {
        // If the attachment is a URL ( URL pointing to a Google Drive file)
        var file = DriveApp.getFileById(extractFileIdFromUrl(attach));
        attachments.push(file);
      } catch (e) {
        Logger.log('Error retrieving file from URL or ID: ' + attach);
      }
    }

    // Check if the ID matches TrackingSheet ID
    var idMatch = false;
    for (var j = 0; j < trackingData.length; j++) {
      if (trackingData[j][0] === id) {
        idMatch = true;
        break;
      }
    }
    
    if (!idMatch) {
      // If no match found, send an email notification about the mismatch
      sendEmailNotification(id);
      continue; // Skip processing this entry
    }



    //Need to update code here to match from Emails_to_send sheet template name to   
    // Need to change this to match off \
    // create index of trackingSheet and if Emails_to_send ID equals trackingSheet index ID then check if trackingSheet index name matches 
    // Check if the AD value matches BV:CC in the TrackingSheet
    var adValue = data[i][29]; // Assuming AD is column 30 (index 29)
    var matchedColumn = -1;

    for (var k = 0; k < trackingRange.length; k++) {
      for (var l = 0; l < trackingRange[k].length; l++) {
        if (trackingRange[k][l] === adValue && trackingSheet.getRange(k + 5, l + 70).getValue() === '') {
          matchedColumn = l + 70; // Get the column in BV:CC range
          break;
        }
      }
      if (matchedColumn !== -1) break; // If a match is found, break out of both loops
    }

    if (matchedColumn !== -1) {
      // If a match is found and the corresponding cell is blank, add "X"
      trackingSheet.getRange(k + 5, matchedColumn).setValue('X');
    }

    // Proceed with email sending if the email address is valid
    if (emailAddress.trim()) {
      var emailStatus = 'Pass'; // Default to 'Pass'
      var errorMessage = '';

      try {
        // Send the email using sendAndTrackEmail function
        sendAndTrackEmail({
          to: emailAddress,
          subject: subject,
          body: body,
          htmlBody: htmlBody,
          attachments: attachments 
        });

        // Log success
        Logger.log('Sent email to ' + legalName + ' (' + emailAddress + ')');
      } catch (e) {
        // If there's an error (email fails to send), catch and log it
        emailStatus = 'Fail';
        errorMessage = e.message; // Capture error message
        Logger.log('Failed to send email to ' + legalName + ' (' + emailAddress + ') - ' + errorMessage);
      }

      // Add log entry for this email
      logEntries.push([
        new Date(), // Timestamp of email sent
        id,         // ID
        legalName,  // Legal Name
        emailAddress, // Email Address
        subject,    // Subject
        body,       // Body
        htmlBody,   // HTML Body
        attachments, // Attachments
        emailStatus, // 'Pass' or 'Fail'
        errorMessage // Error message if failure
      ]);
    }

    // Optional: Add a delay if you're sending many emails to avoid hitting the quota limit
    // Utilities.sleep(1000); // Pause for 1 second between emails (uncomment if needed)
  }

  // After the loop, append all log entries to the SentEmail sheet at once
  if (logEntries.length > 0) {
    sentSheet.getRange(sentSheet.getLastRow() + 1, 1, logEntries.length, logEntries[0].length).setValues(logEntries);
  }
}

function sendAndTrackEmail(emailOptions) {
  // Extract email details from the provided object
  var to = emailOptions.to;
  var subject = emailOptions.subject;
  var body = emailOptions.body;
  var htmlBody = emailOptions.htmlBody;
  var attachments = emailOptions.attachments || []; // Default to empty array if no attachments

  // Send the email with optional attachments
  MailApp.sendEmail({
    to: to,
    subject: subject,
    body: body,
    htmlBody: htmlBody,
    attachments: attachments // Attachments are passed here
  });

  // Log the sending activity (this could be extended to track email status)
  Logger.log('Email sent to: ' + to + ' with subject: ' + subject);
}

// Utility function to extract file ID from a Google Drive URL
function extractFileIdFromUrl(url) {
  var regex = /(?:drive|docs)\.google\.com\/.*\/d\/([^\/?]+)/;
  var match = url.match(regex);
  if (match && match[1]) {
    return match[1];
  } else {
    throw new Error('Invalid Google Drive URL');
  }
}

// Utility function to send notification email when IDs do not match
// function sendEmailNotification(id) {
//   var emailAddress = 'admin@example.com'; // Replace with your admin email address
//   var subject = 'ID Mismatch Notification';
//   var body = 'The ID ' + id + ' from DataSheet does not match any ID in TrackingSheet A5:A100.';
//   MailApp.sendEmail({
//     to: emailAddress,
//     subject: subject,
//     body: body
//   });
// }
