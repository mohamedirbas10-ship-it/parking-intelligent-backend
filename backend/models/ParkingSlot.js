const mongoose = require("mongoose");

const parkingSlotSchema = new mongoose.Schema(
  {
    id: {
      type: String,
      required: [true, "Slot ID is required"],
      unique: true,
      uppercase: true,
      trim: true,
      index: true,
    },
    floor: {
      type: Number,
      default: 1,
      min: 1,
    },
    status: {
      type: String,
      enum: ["available", "occupied", "booked", "maintenance"],
      default: "available",
    },
    currentBookingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Booking",
      default: null,
    },
    bookedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  },
);

// Index for faster queries
parkingSlotSchema.index({ status: 1 });
parkingSlotSchema.index({ floor: 1 });

// Method to check if slot is currently available
parkingSlotSchema.methods.isAvailable = function () {
  return this.status === "available" && this.isActive;
};

// Method to update slot status
parkingSlotSchema.methods.updateStatus = function (
  newStatus,
  bookingId = null,
  userId = null,
) {
  this.status = newStatus;
  this.currentBookingId = bookingId;
  this.bookedBy = userId;
  return this.save();
};

// Method to free the slot
parkingSlotSchema.methods.free = function () {
  this.status = "available";
  this.currentBookingId = null;
  this.bookedBy = null;
  return this.save();
};

// Static method to initialize default slots
parkingSlotSchema.statics.initializeSlots = async function () {
  const existingSlots = await this.countDocuments();

  if (existingSlots === 0) {
    const slots = [];
    for (let i = 1; i <= 6; i++) {
      slots.push({
        id: `A${i}`,
        floor: 1,
        status: "available",
      });
    }

    await this.insertMany(slots);
    console.log("✅ Initialized 6 parking slots (A1-A6)");
  }
};

const ParkingSlot = mongoose.model("ParkingSlot", parkingSlotSchema);

module.exports = ParkingSlot;
