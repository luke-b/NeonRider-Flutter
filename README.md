# ✨ NeonRide ✨ - Futuristic Ride-Hailing UI Prototype

<p align="center">
  <!-- IMPORTANT: Replace this with an actual GIF or screenshot of the app in action! -->
  <img src="PLACEHOLDER_FOR_APP_DEMO.gif" alt="NeonRide App Demo" width="300"/>
</p>

## Concept

NeonRide is a **Flutter-based UI/UX prototype** simulating a futuristic ride-hailing service (like Uber or Lyft). Step into a cyberpunk-lite world and experience a sleek, **neon-infused interface** for booking rides, tracking simulated driver assignments, and managing your journey.

This project focuses purely on the **front-end experience**, demonstrating UI transitions, state management for the booking flow, and a distinct visual aesthetic.

## 🚀 Key Features

*   **Futuristic Neon Aesthetic:** A visually striking dark theme complemented by vibrant, glowing UI elements using a palette of purple (primary), pink (secondary), and cyan (accent).
*   **Simulated Ride Booking Flow:** Experience the core user journey:
    *   Entering a destination (simulated).
    *   Choosing from various ride options (NeonX, XL, Black, Bike).
    *   Confirming the ride request.
    *   A "searching for driver" state.
    *   Viewing assigned (simulated) driver details.
*   **Dynamic Bottom Sheet:** The primary interaction hub dynamically adapts its content based on the app's current state (`Idle` -> `Searching` -> `Driver Assigned`) using smooth `AnimatedSwitcher` transitions.
*   **Clear Ride Options Display:** Each ride option card presents key information like vehicle type, passenger capacity, simulated pricing, and estimated arrival times. Visual cues indicate the selected option.
*   **Driver Assignment Simulation:** When a driver is "found" (after a simulated delay), view dummy driver details including name, car model, license plate, rating, and updated ETA.
*   **Engaging Micro-animations:** Subtle effects like pulsing location markers and floating destination markers add dynamism to the UI.
*   **Modern UI Elements:** Utilizes gradients for backgrounds and buttons, `BackdropFilter` for blur/frosted glass effects, and custom fonts (`Inter`, `Poppins`) via `google_fonts`.

## 🌊 Core Flow Simulation

The prototype manages its state internally to simulate the ride booking process:

1.  **`AppState.idle`:** The user can input a destination (basic text field), browse available `RideOption` cards in the bottom sheet, select one, and view estimated price/ETA. The "Confirm" button is active.
2.  **`AppState.searching`:** Triggered after confirming. The bottom sheet shows a loading indicator. A simulated delay (`Future.delayed`) mimics backend communication. A "Cancel Search" option becomes available.
3.  **`AppState.driverAssigned`:** After the delay, the app transitions to this state. Dummy `Driver` data is generated. The bottom sheet updates to show driver details, updated ETA, and placeholder contact buttons. A "Cancel Trip" option is available.

## 🛠️ Tech Stack & Dependencies

*   **Framework:** Flutter (Developed with `3.7.3`)
*   **Language:** Dart (Developed with `2.19.2`)
*   **Key Packages:**
    *   `google_fonts: ^4.0.4` (For Inter & Poppins fonts)
    *   `font_awesome_flutter: ^10.4.0` (For icons)
*   **State Management:** Basic `setState` within a `StatefulWidget` (suitable for prototype complexity).
*   **UI:** `MaterialApp`, `Scaffold`, `Stack`, `DraggableScrollableSheet`, `AnimatedSwitcher`, `BackdropFilter`, `Container`, `Row`, `Column`, custom `BoxShadow` for glows, `LinearGradient`, `RadialGradient`.

## ⚙️ How to Run

1.  **Prerequisites:**
    *   Ensure you have the Flutter SDK installed (version `3.7.3` is recommended for guaranteed compatibility with the dependencies used).
    *   Ensure you have the corresponding Dart SDK (version `2.19.2` is recommended).
    *   An emulator/simulator running or a physical device connected.

2.  **Clone the Repository:**
    ```bash
    git clone https://github.com/luke-b/NeonRider-Flutter.git
    ```

3.  **Navigate to Project Directory:**
    ```bash
    cd NeonRider-Flutter
    ```

4.  **Fetch Dependencies:**
    ```bash
    flutter pub get
    ```

5.  **Run the App:**
    ```bash
    flutter run
    ```

## ⚠️ Project Status: Prototype

**Important:** This is strictly a **UI/UX prototype** and **not** a fully functional application.

*   ❌ **No Real Backend:** It does not connect to any server for real ride requests, driver matching, or user accounts.
*   ❌ **No Real Maps:** It does not integrate with any map SDKs (like Google Maps or Mapbox). The map view is a static visual simulation.
*   ❌ **No Real Payments:** No payment gateways are implemented.
*   ❌ **No Real Location Tracking:** Location markers are static or have simple pre-defined animations.
*   ✅ **Simulated Data:** Driver details, ETAs (after initial selection), and search times are simulated locally using delays and random data generation.

The primary goal is to showcase the visual design and the core user interaction flow of the NeonRide concept.

## 🔮 Potential Future Ideas (If Realized)

*   Integrate with a real map SDK for displaying maps, routes, and real-time locations.
*   Develop a backend service (e.g., using Firebase, Node.js, Python) for user authentication, ride management, driver matching, and pricing logic.
*   Implement real-time communication (e.g., WebSockets, Firebase Realtime Database/Firestore) for driver location updates.
*   Integrate a payment gateway (e.g., Stripe, Braintree).
*   Develop user profile and ride history features.

---

Feel free to explore the code and see how the UI and state transitions are implemented!
