# UI/UX Upgrades

## Confirmed UI/UX Work

The current app includes a polished FlutterFlow-style mobile UI with custom theme tokens, Poppins typography, onboarding images, empty states, a bottom navigation layout, and a Rudo floating assistant action.

## Design Refresh

Confirmed:

- Centralized FlutterFlow theme in `lib/flutter_flow/flutter_flow_theme.dart`.
- Poppins font family loaded from `assets/fonts/`.
- Primary color family defined in the theme.
- Light mode is the only runtime theme; dark/system controls and persistence were removed.
- Transparent `assets/dawa_intro.gif` startup flow through `DawaSplashScreen` on brand blue.

## Authentication UI

Confirmed:

- Register screen with image assets and password confirmation.
- Login screen with responsive layout patterns.
- Forgot password screen.
- Profile completion screen after signup.
- Password visibility toggles.
- Snackbars for feedback.

## Dashboard/Homepage Updates

Confirmed:

- Home screen functions as the main dashboard.
- Upcoming appointment section.
- Pregnancy week/what-to-expect section.
- Schedule appointment button.
- Floating Rudo assistant action.
- Animated page-load UI elements through `flutter_animate`.
- Empty/loading states through shimmer and no-data components.

## Navigation Improvements

Confirmed:

- Bottom navigation includes:
  - Home
  - Appointments
  - Period Tracker
- GoRouter is used for deeper routes like profile, edit profile, week page, appointment details, and encounter details.

## Form Improvements

Confirmed:

- Registration validates matching passwords.
- Profile completion checks required fields and date selection.
- Booking checks date, clinic, clinician, and time before creating an appointment.
- Booking checks doctor and mother slot availability.
- Edit Profile uses existing record values as form defaults.

## Visual Assets

Confirmed assets include:

- Dawa logos and launcher icons.
- Login/register illustrations.
- Pregnancy illustrations.
- Menstrual calendar illustration.
- No-data illustration.
- Doctor avatar/images.
- Background image.
- Splash/video asset.

## Responsive/Mobile Work

Confirmed:

- Some screens use screen width/height checks and layout constraints.
- The login/register/profile flows include responsive sizing and scroll behavior.
- `MyAppScrollBehavior` enables touch and mouse dragging.

Automated widget coverage now exercises key phone, tablet and desktop widths. Landscape, accessibility and real-device screenshot QA remain manual release checks.

## Rudo-Style UI

Confirmed:

- Rudo appears as a floating assistant from the Home screen.
- Rudo chat has suggestions, message list, voice mode states, loading/connection handling, and a disclaimer.

Not confirmed:

- A shared Rudo visual design system or component library.

## Known Visual Issues / Review Items

- No committed screenshots exist for visual regression review.
- Some generated comments and typos remain in code, including old FlutterFlow wording and `Potentital`.
- The app should be screenshot-tested on small phones, common Android screen sizes, iOS, and web.
- The Poppins/theme usage is consistent, but some screens are generated and should be visually reviewed after any design refresh.
