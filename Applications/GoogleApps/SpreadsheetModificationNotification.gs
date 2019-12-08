function NotifyManager(e)
{
  // these columns contain the email addresses of the managers who must approve this request
  var requiredExecutiveIndex = 15;
  var requiredManagerIndex = 16;

  // when using e.values[X] where X is the index, it starts at zero
  var sheet = SpreadsheetApp.getActiveSpreadsheet(); // get the entire sheet
  var managerEmailAddress = e.values[requiredManagerIndex];
  var message = "A purchase request for " + e.values[3] + " has been submitted by " + e.values[2] + ".  In order to approve this request, " + e.values[requiredManagerIndex] + " should REPLY to this email and type 'Approved' into the email body.  Upon manager approval, the request will be forwarded to the selected executive for final approval.\r\n"
  message += "\r\nManager Approval:  " + e.values[requiredManagerIndex];
  message += "\r\nExecutive Approval:  " + e.values[requiredExecutiveIndex];
  //message += "\r\nReview Purchase Requests:  " + sheet.getUrl();
  var subject = "Soverance Purchase Authorization Approval Request";

  if (managerEmailAddress != "")
  {
    var name = "Soverance Accounting"
    var cclist = e.values[requiredExecutiveIndex]
    MailApp.sendEmail(managerEmailAddress, subject, message, {cc: cclist, name: name});
  }
}

function NotifyOnApproval(e)
{
  // make sure the edited cell is in approvalColumnIndex, which is the "Approved" column of this sheet
  var approvalColumnIndex = 18;
  // these columns contain the email addresses of the managers who must approve this request
  var requiredExecutiveIndex = 15;
  var requiredManagerIndex = 16;

  if (e.range.getColumn() == approvalColumnIndex)
  {
    // Set a comment on the edited cell to indicate when it was last changed and by who.
    var cell = e.range;
    cell.setNote('Last modified: ' + new Date() + ' by: ' + Session.getActiveUser());

    var value = e.value;  // store the value of the edited cell
    var sheet = e.source.getActiveSheet();  // get the entire sheet
    var range = sheet.getRange(e.range.getRow(), 1, 1, approvalColumnIndex)  // get the entire range row of the specified sheet
    var data = range.getValues();
    var name = "Soverance Accounting"
    var cclist = e.values[requiredExecutiveIndex] + "," + e.values[requiredManagerIndex];  // create a CC list of managers for the email

    // if the value of the edited cell contains a single "y" character
    if (value.indexOf("y") >= 0)
    {
      for (i in data)
      {
        // when using data[X] where X is the index, it starts at one
        var row = data[i];
        var emailAddress = row[1];  // Second column, the auto-recorded email address of the user who submitted the form
        var message = "Your purchase request for " + row[3] + " has been approved by " + Session.getActiveUser() + ".  You may now proceed with the transaction.\r\n\r\nPlease forward all receipts to info@soverance.com."
        var subject = "Soverance Purchase Authorization Request - APPROVED";

        if (emailAddress != "")
        {
          MailApp.sendEmail(emailAddress, subject, message, {cc: cclist, name: name});
        }
      }
    }

    // if the value of the edited cell contains a single "n" character
    if (value.indexOf("n") >= 0)
    {
      for (i in data)
      {
      // when using data[X] where X is the index, it starts at one
        var row = data[i];
        var emailAddress = row[1];  // Second column, the auto-recorded email address of the user who submitted the form
        var message = "Your purchase request for " + row[3] + " has been denied by " + Session.getActiveUser() + ".  This purchase is not approved."
        var subject = "Soverance Purchase Authorization Request - DENIED";

        if (emailAddress != "")
        {
          MailApp.sendEmail(emailAddress, subject, message, {cc: cclist, name: name});
        }
      }
    }
  }
}

