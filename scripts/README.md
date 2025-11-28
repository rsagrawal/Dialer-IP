# Google Apps Scripts

This directory contains the Google Apps Script code for both production and development environments.

## Structure

```
scripts/
├── production/
│   └── Code.gs          # Production script (IP Dialer)
└── development/
    └── Code.gs          # Development script (Copy of IP Dialer)
```

## Production Script

- **Google Sheet**: IP Dialer (Original)
- **Script ID**: `AKfycbwKnLIHPiqwbhsISuk7kYcb6x99Q10bYWNiLqt82skSA3iblANoRTBMS7woSI2hU_nf`
- **Deployment URL**: https://script.google.com/macros/s/AKfycbwKnLIHPiqwbhsISuk7kYcb6x99Q10bYWNiLqt82skSA3iblANoRTBMS7woSI2hU_nf/exec

## Development Script

- **Google Sheet**: Development Sheet
- **Script ID**: `AKfycbw-nNqsPVzFYIFQUj0g9PyIqy3PIDySon-akYGe9thmHSY1BLgLoQ6wtwpX7qQgCmfO`
- **Deployment URL**: https://script.google.com/macros/s/AKfycbw-nNqsPVzFYIFQUj0g9PyIqy3PIDySon-akYGe9thmHSY1BLgLoQ6wtwpX7qQgCmfO/exec
- **Google Sheet URL**: https://docs.google.com/spreadsheets/d/1gQ4IQXSGlszJgu78PZWZRsKZic4N7Eq8fOlIBhOrkbg/edit

## How to Deploy Changes

After making changes to the scripts in this repository:

1. **Copy the updated code** from the appropriate file (`production/Code.gs` or `development/Code.gs`)
2. **Open the Google Apps Script editor**:
   - Go to your Google Sheet
   - Click **Extensions** → **Apps Script**
3. **Paste the updated code** into the editor
4. **Save** the script (Ctrl+S or Cmd+S)
5. **Deploy** the script:
   - Click **Deploy** → **Manage deployments**
   - Click the **Edit** icon (pencil) on the existing deployment
   - Update the **Version** to "New version"
   - Click **Deploy**

## Features

Both scripts include:
- ✅ User authorization checking
- ✅ Lead fetching with state-based filtering
- ✅ Disposition management
- ✅ Follow-up date tracking
- ✅ Call logging
- ✅ Queue management with timeout
- ✅ Search functionality

## Version Control

This repository tracks all changes to the Google Apps Scripts, allowing you to:
- View history of changes
- Rollback to previous versions if needed
- Compare differences between production and development
- Document why changes were made
