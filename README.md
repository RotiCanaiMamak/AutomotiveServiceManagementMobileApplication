# Automotive Service Management Mobile Application

A mobile workshop management application developed with Flutter for the **Mobile Application Development** assignment.

GPT Car Workshop Service Hub helps workshop staff manage customers, vehicles, service records, work schedules, spare part inventory, and invoices from one application. It uses Supabase as its cloud backend for database and image storage.

## Features

- Staff login with credential validation
- Dashboard with monthly revenue chart
- Low stock alerts and lowest stock item indicator
- Recent customer communication and vehicle service activity
- Customer management
  - View customer details
  - Add customer records with profile images
  - Delete customer records
  - Record communication history
  - View vehicles belonging to each customer
- Vehicle management
  - Add vehicles with uploaded images
  - Link vehicles to customers
  - View vehicle information
  - Delete vehicle records
  - Add and view service history
- Work scheduling
  - Create and manage work schedules
  - Add multiple work periods
  - Assign workers to each period
  - Track worker working hours
  - View schedule details and delete schedules
- Inventory control
  - View spare part information
  - Review stock quantity, descriptions, and usage history
  - Submit stock addon requests
- Invoice management
  - Search invoices by invoice number or customer
  - View invoice items, quantities, prices, and total amount
  - Approve unpaid invoices
  - Generate paid invoices as text files

## Built With

- Flutter
- Dart
- Supabase
- Shared Preferences
- `fl_chart`
- `image_picker`
- `intl`

## Requirements

- Flutter SDK compatible with Dart `^3.9.2`
- Android Studio or Visual Studio Code with Flutter and Dart extensions
- Android emulator or physical Android device
- A Supabase project with the required database tables and storage buckets

## Database Tables

The application uses the following Supabase tables:

- `Staff`
- `Customer`
- `Vehicle`
- `Service_History`
- `Communication_History`
- `Worker`
- `Schedule`
- `Work_Periods`
- `Work_Periods_Worker`
- `inventory`
- `Invoice`
- `Invoice_Inventory`

## How to Run

1. Clone or download this repository.
2. Open the project folder in Android Studio or Visual Studio Code.
3. Install the required packages:

   ```bash
   flutter pub get
   ```

4. Start an emulator or connect an Android device.
5. Run the application.

## Login Credentials

| Staff ID | Password |
| --- | --- |
| `A101` | `123` |
| `A102` | `321` |
| `A103` | `abc` |

## Navigation

The application provides a bottom navigation bar with the following pages:

| Page | Purpose |
| --- | --- |
| Home | Displays revenue, low stock alerts, recent communications, and service activity |
| Vehicles | Manages workshop vehicle records and service histories |
| Jobs | Creates schedules, work periods, and worker assignments |
| Customer | Manages customer records and communication histories |
| Inventory | Displays spare part stock, details, and recent usage |
| Invoices | Displays, approves, and generates invoices |

## Technical Highlights

- Uses Supabase for cloud-based data storage and image uploads.
- Uses Shared Preferences to retain the logged in staff member's name locally.
- Uses image selection from the device gallery for customer and vehicle images.
- Uses a bar chart to visualise monthly paid invoice revenue.
- Calculates invoice totals from inventory item quantities and unit prices.
- Generates approved invoices as text files in the application documents directory.
- Uses relational data to connect customers, vehicles, services, schedules, workers, invoices, and inventory.

## Notes

- The application requires an active internet connection to access Supabase data.
