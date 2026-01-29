# 🛠️ Complete Materials List - Intelligent Parking Management System

## 📋 Hardware Components Required

### 1. ESP32-CAM Entry Gate Components

| # | Component | Quantity | Specifications | Estimated Cost (USD) | Purpose |
|---|-----------|----------|----------------|---------------------|---------|
| 1 | ESP32-CAM Module | 1 | AI-Thinker ESP32-CAM, WiFi, Bluetooth, OV2640 Camera | $10 | QR code scanning, WiFi connectivity |
| 2 | Servo Motor (SG90) | 1 | 5V, 1.8kg torque, 180° rotation, PWM control | $3 | Automated gate control |
| 3 | I2C LCD Display | 1 | 16x2 characters, I2C interface, Address 0x27 | $5 | Real-time parking statistics display |
| 4 | IR Obstacle Sensor | 1 | Digital output, 2-30cm detection range | $1 | Car detection for gate automation |
| 5 | Power Supply | 1 | 5V, 2A minimum, USB or wall adapter | $5 | Power for ESP32-CAM and components |
| 6 | Resistors | 2 | 220Ω, 1/4W | $0.10 | LED current limiting (if using LEDs) |
| 7 | Jumper Wires | 10+ | Male-to-male, various lengths | $2 | Component connections |
| 8 | Breadboard | 1 | 400 points, full-size | $2 | Prototyping and connections |
| 9 | FTDI Programmer | 1 | USB to Serial, 5V/3.3V | $5 | Programming ESP32-CAM |
| 10 | USB Cable | 1 | Micro USB or Type-C | $2 | Power and programming |

**Subtotal Entry Gate: ~$35**

### 2. ESP32-CAM Exit Gate Components

| # | Component | Quantity | Specifications | Estimated Cost (USD) | Purpose |
|---|-----------|----------|----------------|---------------------|---------|
| 1 | ESP32-CAM Module | 1 | AI-Thinker ESP32-CAM, WiFi, Bluetooth, OV2640 Camera | $10 | QR code scanning, WiFi connectivity |
| 2 | Servo Motor (SG90) | 1 | 5V, 1.8kg torque, 180° rotation, PWM control | $3 | Automated gate control |
| 3 | IR Obstacle Sensor | 1 | Digital output, 2-30cm detection range | $1 | Car detection for gate automation |
| 4 | Power Supply | 1 | 5V, 2A minimum, USB or wall adapter | $5 | Power for ESP32-CAM and components |
| 5 | Resistors | 2 | 220Ω, 1/4W | $0.10 | LED current limiting (if using LEDs) |
| 6 | Jumper Wires | 10+ | Male-to-male, various lengths | $2 | Component connections |
| 7 | Breadboard | 1 | 400 points, full-size | $2 | Prototyping and connections |
| 8 | FTDI Programmer | 1 | USB to Serial, 5V/3.3V | $5 | Programming ESP32-CAM |
| 9 | USB Cable | 1 | Micro USB or Type-C | $2 | Power and programming |

**Subtotal Exit Gate: ~$30**

**Note**: LCD display is shared with entry gate (connected only to entry gate ESP32)

### 3. Additional Components (Optional but Recommended)

| # | Component | Quantity | Specifications | Estimated Cost (USD) | Purpose |
|---|-----------|----------|----------------|---------------------|---------|
| 1 | Enclosure Box | 2 | Weatherproof, suitable size for ESP32-CAM | $10 | Protection from weather and dust |
| 2 | Mounting Hardware | - | Screws, brackets, mounting tape | $5 | Secure mounting of components |
| 3 | LED Indicators | 4 | Red and Green LEDs, 5mm | $1 | Visual status indicators |
| 4 | Buzzer | 2 | 5V active buzzer | $2 | Audio feedback for gate operations |
| 5 | Extension Cables | - | Various lengths for power and data | $5 | Extended reach for installation |
| 6 | Power Strip | 1 | Multiple outlets, surge protection | $5 | Power distribution |
| 7 | Cable Management | - | Cable ties, clips, organizers | $2 | Neat cable organization |

**Subtotal Additional: ~$30**

### 4. Development and Testing Equipment

| # | Component | Quantity | Specifications | Estimated Cost (USD) | Purpose |
|---|-----------|----------|----------------|---------------------|---------|
| 1 | Computer/Laptop | 1 | Windows/Mac/Linux, USB ports | (Owned) | Development and programming |
| 2 | Mobile Phone | 1 | Android or iOS | (Owned) | Testing mobile application |
| 3 | Multimeter | 1 | Digital multimeter | $10 | Testing and debugging |
| 4 | Soldering Iron | 1 | Basic soldering kit | $15 | Permanent connections (optional) |
| 5 | Wire Strippers | 1 | Basic wire strippers | $5 | Wire preparation |

**Subtotal Development: ~$30 (if needed)**

---

## 💰 Total Cost Breakdown

### Hardware Costs
- **Entry Gate**: $35
- **Exit Gate**: $30
- **Additional Components**: $30
- **Development Equipment**: $30 (if needed)
- **Total Hardware**: **~$125** (with optional components)

### Software Costs
- **Flutter SDK**: Free (Open Source)
- **Node.js**: Free (Open Source)
- **Arduino IDE**: Free (Open Source)
- **Render.com**: Free (Free tier available)
- **Total Software**: **$0** (All open source and free)

### Cloud Hosting Costs
- **Render.com Free Tier**: Free (750 hours/month)
- **Optional Paid Tier**: $7/month (for 24/7 without spin-down)
- **Total Cloud**: **$0** (Free tier) or **$7/month** (Paid tier)

---

## 📦 Complete Shopping List

### Essential Components (Minimum Required)
1. ✅ 2x ESP32-CAM Module (AI-Thinker)
2. ✅ 2x Servo Motor (SG90)
3. ✅ 1x I2C LCD Display (16x2)
4. ✅ 2x IR Obstacle Sensor
5. ✅ 2x Power Supply (5V, 2A)
6. ✅ 1x FTDI Programmer
7. ✅ Jumper Wires (20+ pieces)
8. ✅ 2x Breadboard
9. ✅ Resistors (220Ω, 4 pieces)

### Recommended Additional Components
10. ✅ 2x Enclosure Box (weatherproof)
11. ✅ Mounting Hardware
12. ✅ LED Indicators (Red and Green)
13. ✅ Buzzer (for audio feedback)
14. ✅ Extension Cables
15. ✅ Power Strip
16. ✅ Cable Management

---

## 🔌 Pin Connection Summary

### Entry Gate Pin Connections
- **LCD SDA**: GPIO 15
- **LCD SCL**: GPIO 16
- **Servo Signal**: GPIO 12
- **IR Sensor**: GPIO 14
- **Camera**: Built-in (OV2640)

### Exit Gate Pin Connections
- **Servo Signal**: GPIO 12
- **IR Sensor**: GPIO 14
- **Camera**: Built-in (OV2640)

---

## ⚡ Power Requirements

### Entry Gate Power
- **ESP32-CAM**: 5V, 300mA
- **Servo Motor**: 5V, 500-900mA (peak)
- **LCD Display**: 3.3V/5V, 20mA
- **IR Sensor**: 5V, 20mA
- **Total**: 5V, 2A power supply required

### Exit Gate Power
- **ESP32-CAM**: 5V, 300mA
- **Servo Motor**: 5V, 500-900mA (peak)
- **IR Sensor**: 5V, 20mA
- **Total**: 5V, 2A power supply required

---

## 🛒 Where to Buy

### Online Retailers
- **Amazon**: Wide selection, fast shipping
- **AliExpress**: Lower prices, longer shipping
- **eBay**: Good deals, used components available
- **Adafruit**: Quality components, good documentation
- **SparkFun**: Quality components, tutorials

### Local Electronics Stores
- Check local electronics stores
- RadioShack (if available)
- Electronic component distributors

---

## 📝 Notes

### Important Considerations
1. **Power Supply**: Ensure stable 5V, 2A supply for reliable operation
2. **WiFi Range**: ESP32-CAM should be within WiFi router range
3. **Camera Positioning**: Mount camera for optimal QR code scanning
4. **Weather Protection**: Use enclosure for outdoor installation
5. **Servo Power**: Servo motor needs separate power supply for reliable operation

### Compatibility
- All components are compatible with ESP32-CAM
- Standard Arduino-compatible components
- 5V and 3.3V logic levels supported
- I2C devices use standard addresses

### Safety
- Use proper power supplies with correct voltage
- Avoid short circuits
- Use fuses for protection
- Follow electrical safety guidelines

---

## ✅ Pre-Purchase Checklist

Before purchasing components, ensure:
- [ ] You have a computer for development
- [ ] You have WiFi network for ESP32-CAM
- [ ] You have basic electronics knowledge
- [ ] You have tools for assembly (screwdriver, wire strippers)
- [ ] You have space for installation
- [ ] You understand the project requirements

---

**Total Estimated Cost**: ~$125 (with optional components)  
**Minimum Cost**: ~$65 (essential components only)  
**Software Cost**: $0 (all open source)  
**Cloud Hosting**: $0 (free tier) or $7/month (paid tier)

---

This materials list provides everything needed to build the Intelligent Parking Management System. All components are readily available and affordable, making this an accessible IoT project.

