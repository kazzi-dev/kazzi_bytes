<p align="center">
  <img src="assets/branding/splash_light.png" width="360" alt="kazzi. bytes">
</p>

<p align="center">
  <b>A polished food ordering app built with Flutter.</b><br>
  Browse, customize, check out, and track your order live, all in a few taps.
</p>

<p align="center">
  <a href="https://kazzi-dev.github.io/kazzi_bytes/"><b>▶ Try the live demo</b></a>
  &nbsp;·&nbsp;
  <img src="https://img.shields.io/badge/Flutter-Material%203-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20Web-1B1B1F" alt="Platforms">
  <img src="https://img.shields.io/badge/tests-passing-2ea44f" alt="Tests">
</p>

> Tip: open the demo on your phone, or use your browser's mobile view, for the intended experience.

## Highlights

| | |
|---|---|
| **Motion that feels native** | Shared-axis page transitions, Hero images into the dish sheet, a fly-to-cart animation, rolling price counters, and confetti when you place an order |
| **Real ordering flow** | Menu → add-ons → cart (swipe to delete, undo, promo codes) → checkout → live order tracking |
| **Account features** | Saved addresses, saved cards with live card preview and Luhn validation, notification preferences, and favorites |
| **Built for everyone** | Light and dark themes, reduced-motion support, large-text support, and screen-reader labels |
| **Clean architecture** | Design tokens, a repository pattern with swappable mock backends, and unit and widget tests |

## Features

- Menu with search, category filters, a promo carousel, and a dish detail sheet with add-ons
- Cart with swipe-to-delete and undo, promo codes, and a price breakdown
- Checkout: dine-in or take-out, cash, GCash, or a saved card
- Order tracking with live status updates and in-app notifications
- Sign in, sign up, and guest mode
- Saved addresses, payment methods (stores only the last 4 digits), notification settings, and favorites
- Light and dark themes, reduced-motion support, and large-text support

## Tech

- Flutter (Material 3), with state managed by `ChangeNotifier` (no state-management packages)
- Repository pattern: mock repositories simulate a backend and can be swapped for real APIs
- `shared_preferences` for local persistence; `google_fonts` for typography
- Custom motion: shared-axis transitions, Hero animations, a confetti burst on order success, and a rolling price counter

## Project structure

```
lib/
  theme/        Design tokens, colors, theme, motion helpers
  data/         Models, menu data, repositories, local storage
  controllers/  App state (cart, menu, auth, orders, account)
  widgets/      Reusable UI components
  pages/        Screens
test/           Unit and widget tests
tool/           Script that generates the app icon and splash images
```

## Getting started

```bash
flutter pub get
flutter run
```

Run the tests:

```bash
flutter test
```

Demo notes: any email and password signs you in, and `error@kazzi.dev` shows a failed sign-in. The promo code `KAZZI10` takes 10% off your order. For a card, use the test number `4242 4242 4242 4242`.

## Roadmap

- Connect a real backend (auth, menu, orders, push notifications)
- Delivery with address selection and map tracking
- Rewards program and one-tap reorder

Food photos from [Unsplash](https://unsplash.com).
