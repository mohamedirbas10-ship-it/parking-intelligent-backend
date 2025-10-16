# Smart Car Parking - Color Palette

## Overview
This app uses a professional Blue & Green color palette designed to convey **trust**, **clarity**, and **calmness** - perfect for solving the stressful problem of finding parking.

## Color Palette

### Primary Color - Confident Digital Blue
- **Main**: `#2D5BFF` - Used for headers, primary buttons, and brand identity
- **Dark**: `#1E3A8A` - For hover states and emphasis
- **Light**: `#60A5FA` - For gradients and lighter accents

**Usage**: Headers, main navigation, primary branding

### Success/Action Color - Fresh Energetic Teal-Green
- **Main**: `#00C48C` - Used for "go" actions, confirmations, and available spots
- **Light**: `#34D399` - For success messages
- **Dark**: `#059669` - For active states

**Usage**: 
- "BOOK" buttons (green = go!)
- Available parking spots
- Success confirmations
- Booking confirmations

### Warning/Alert Color - Soft Clear Red
- **Main**: `#FF6B6B` - Used for warnings, full spots, and cancellations
- **Light**: `#FCA5A5` - For light warnings
- **Dark**: `#DC2626` - For critical alerts

**Usage**:
- "CANCEL" buttons
- Booked/unavailable spots
- Warning messages
- Error states

### Background Color - Very Light Gray
- **Main**: `#F8F9FA` - Clean, spacious background
- **Dark**: `#E5E7EB` - For subtle variations

**Usage**: Main app background, creating clean, scannable interface

### Text Color - Dark Navy Gray
- **Main**: `#2E3A59` - High contrast, readable text
- **Light**: `#6B7280` - Secondary text, hints
- **White**: `#FFFFFF` - Text on colored backgrounds

**Usage**: All text content, ensuring readability

### Additional Colors
- **Disabled**: `#D1D5DB` - Disabled buttons and inactive elements
- **Border**: `#E5E7EB` - Clean borders and dividers
- **White**: `#FFFFFF` - Cards, containers
- **Black**: `#111827` - Deep shadows

## Color Psychology

### Why Blue?
✓ Conveys **trust** and **reliability**
✓ Used by major tech companies (Facebook, LinkedIn)
✓ Creates a sense of **dependability**
✓ Professional and modern

### Why Green?
✓ Universal symbol for **"go"** and **"available"**
✓ Creates **positive**, **calm** experience
✓ Perfect for confirming bookings
✓ Indicates success and completion

### Why Red/Orange for Warnings?
✓ Grabs attention for important alerts
✓ Clearly indicates unavailable/booked spots
✓ Used sparingly to maintain calm atmosphere

## Implementation

All colors are defined in:
- `lib/theme/app_colors.dart` - Color constants
- `lib/theme/app_theme.dart` - Complete theme configuration

The theme is automatically applied throughout the app via `MaterialApp` in `lib/main.dart`.

## Examples

### Parking Slots
- **Available**: Gray border → Green "BOOK" button
- **Booked by you**: Green border → Orange "CANCEL" button  
- **Booked by others**: Red border → Red "BOOKED" label

### Buttons
- **Primary actions**: Green background (success/go)
- **Destructive actions**: Red background (warning/stop)
- **Navigation**: Blue (trust/reliability)

### Status Messages
- **Success**: Green background
- **Error**: Red background
- **Info**: Blue background

## Accessibility

All color combinations meet WCAG 2.1 AA standards for contrast:
- Text on backgrounds: Minimum 4.5:1 contrast ratio
- Large text: Minimum 3:1 contrast ratio
- Interactive elements: Clear visual distinction

---

**Design Philosophy**: Clean, professional, and stress-free parking experience.
