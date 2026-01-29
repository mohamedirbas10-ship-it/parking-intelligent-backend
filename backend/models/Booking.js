const mongoose = require("mongoose");

const bookingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: [true, "User ID is required"],
    },
    slotId: {
      type: String,
      required: [true, "Slot ID is required"],
    },
    duration: {
      type: Number,
      required: [true, "Duration is required"],
      min: [1, "Duration must be at least 1 hour"],
      max: [24, "Duration cannot exceed 24 hours"],
    },
    reservedAt: {
      type: Date,
      required: [true, "Reservation start time is required"],
      default: Date.now,
    },
    expiresAt: {
      type: Date,
      required: [true, "Expiry time is required"],
    },
    status: {
      type: String,
      enum: ["active", "occupied", "completed", "expired", "cancelled"],
      default: "active",
    },
    qrCode: {
      type: String,
      required: [true, "QR code is required"],
      unique: true,
      index: true,
    },
    enteredAt: {
      type: Date,
      default: null,
    },
    exitedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

// Index for faster queries
bookingSchema.index({ userId: 1, status: 1 });
bookingSchema.index({ slotId: 1, status: 1 });
bookingSchema.index({ reservedAt: 1, expiresAt: 1 });

// Check if booking is currently active (within time window)
bookingSchema.methods.isCurrentlyActive = function () {
  const now = new Date();
  return (
    this.status === "active" && now >= this.reservedAt && now <= this.expiresAt
  );
};

// Check if booking is future (hasn't started yet)
bookingSchema.methods.isFuture = function () {
  const now = new Date();
  return this.status === "active" && now < this.reservedAt;
};

// Check if booking has expired
bookingSchema.methods.isExpired = function () {
  const now = new Date();
  return now > this.expiresAt && this.status === "active";
};

// Static method to check slot availability for a time range
bookingSchema.statics.isSlotAvailable = async function (
  slotId,
  startTime,
  endTime,
  excludeBookingId = null,
) {
  const query = {
    slotId: slotId,
    status: { $in: ["active", "occupied"] },
  };

  // Exclude specific booking (useful for updates)
  if (excludeBookingId) {
    query._id = { $ne: excludeBookingId };
  }

  const conflictingBookings = await this.find(query);

  for (const booking of conflictingBookings) {
    const bookingStart = new Date(booking.reservedAt).getTime();
    const bookingEnd = new Date(booking.expiresAt).getTime();
    const newStart = new Date(startTime).getTime();
    const newEnd = new Date(endTime).getTime();

    // Check for time overlap
    if (newStart < bookingEnd && newEnd > bookingStart) {
      return false; // Slot is not available
    }
  }

  return true; // Slot is available
};

// Static method to get current booking for a slot
bookingSchema.statics.getCurrentBookingForSlot = async function (slotId) {
  const now = new Date();

  const booking = await this.findOne({
    slotId: slotId,
    status: { $in: ["active", "occupied"] },
    reservedAt: { $lte: now },
    expiresAt: { $gte: now },
  });

  return booking;
};

// Static method to get next booking for a slot
bookingSchema.statics.getNextBookingForSlot = async function (slotId) {
  const now = new Date();

  const booking = await this.findOne({
    slotId: slotId,
    status: "active",
    reservedAt: { $gt: now },
  }).sort({ reservedAt: 1 }); // Get earliest future booking

  return booking;
};

// Middleware to automatically expire old bookings
bookingSchema.pre("save", function (next) {
  const now = new Date();

  // Auto-expire if past expiry time
  if (this.status === "active" && now > this.expiresAt) {
    this.status = "expired";
  }

  next();
});

const Booking = mongoose.model("Booking", bookingSchema);

module.exports = Booking;
