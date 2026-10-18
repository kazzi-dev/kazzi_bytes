import 'package:flutter/material.dart';

import 'models.dart';

// ---------------------------------------------------------------------------
// Menu data
//
// This is sample data. Edit the dishes, prices and categories here and the
// whole app updates. Prices are whole pesos.
//
// TODO(backend): Once the API is live, MenuRepository.fetchMenu() should
// return this from the server and these constants can become test fixtures.
// ---------------------------------------------------------------------------

const List<String> kCategories = <String>[
  'Burgers',
  'Rice Meals',
  'Sides',
  'Drinks',
  'Desserts',
];

/// Icons shown on the category chips.
const Map<String, IconData> kCategoryIcons = <String, IconData>{
  'All': Icons.grid_view_rounded,
  'Burgers': Icons.lunch_dining_rounded,
  'Rice Meals': Icons.rice_bowl_rounded,
  'Sides': Icons.fastfood_rounded,
  'Drinks': Icons.local_drink_rounded,
  'Desserts': Icons.icecream_rounded,
};

// Dish photos from Unsplash (free to use under the Unsplash License,
// https://unsplash.com/license). Served from Unsplash's CDN, which sends
// CORS headers, so they also load in the web build.
// TODO(backend): Serve your own photos from your CDN and return the URL
// with each dish from the menu API.
const String _photo = 'https://images.unsplash.com/photo-';
const String _photoParams = '?auto=format&fit=crop&w=800&q=75';

const List<AddOn> _burgerAddOns = <AddOn>[
  AddOn(id: 'cheese', name: 'Extra cheese', price: 35),
  AddOn(id: 'bacon', name: 'Crispy bacon', price: 45),
  AddOn(id: 'egg', name: 'Fried egg', price: 25),
];

const List<AddOn> _riceAddOns = <AddOn>[
  AddOn(id: 'rice', name: 'Extra rice', price: 30),
  AddOn(id: 'egg', name: 'Fried egg', price: 25),
  AddOn(id: 'atchara', name: 'Atchara pickles', price: 15),
];

const List<AddOn> _sideAddOns = <AddOn>[
  AddOn(id: 'cheese-dip', name: 'Cheese dip', price: 25),
  AddOn(id: 'garlic-mayo', name: 'Garlic mayo', price: 20),
];

const List<AddOn> _drinkAddOns = <AddOn>[
  AddOn(id: 'large', name: 'Make it large', price: 20),
  AddOn(id: 'less-sugar', name: 'Less sugar', price: 0),
];

const List<AddOn> _dessertAddOns = <AddOn>[
  AddOn(id: 'scoop', name: 'Extra scoop', price: 40),
  AddOn(id: 'drizzle', name: 'Chocolate drizzle', price: 15),
];

const List<Dish> kMenu = <Dish>[
  Dish(
    id: 'burger-classic',
    imageUrl: '${_photo}1568901346375-23c9450c58cd$_photoParams',
    name: 'Classic Byte Burger',
    description:
        'Beef patty, lettuce, tomato and house sauce on a toasted bun.',
    price: 189,
    category: 'Burgers',
    icon: Icons.lunch_dining_rounded,
    rating: 4.8,
    ratingCount: 1240,
    prepMinutes: 12,
    calories: 620,
    isPopular: true,
    addOns: _burgerAddOns,
  ),
  Dish(
    id: 'burger-double',
    imageUrl: '${_photo}1607013251379-e6eecfffe234$_photoParams',
    name: 'Double Cheese Burger',
    description: 'Two beef patties with melted cheese and pickles.',
    price: 249,
    category: 'Burgers',
    icon: Icons.lunch_dining_rounded,
    rating: 4.9,
    ratingCount: 860,
    prepMinutes: 14,
    calories: 890,
    isPopular: true,
    addOns: _burgerAddOns,
  ),
  Dish(
    id: 'burger-spicy',
    imageUrl: '${_photo}1703219342329-fce8488cf443$_photoParams',
    name: 'Spicy Chicken Burger',
    description: 'Crispy chicken fillet with spicy mayo and slaw.',
    price: 219,
    category: 'Burgers',
    icon: Icons.lunch_dining_rounded,
    rating: 4.6,
    ratingCount: 410,
    prepMinutes: 13,
    calories: 710,
    isNew: true,
    addOns: _burgerAddOns,
  ),
  Dish(
    id: 'rice-teriyaki',
    imageUrl: '${_photo}1679279726946-a158b8bcaa23$_photoParams',
    name: 'Chicken Teriyaki Bowl',
    description: 'Grilled chicken glazed in teriyaki over steamed rice.',
    price: 229,
    category: 'Rice Meals',
    icon: Icons.rice_bowl_rounded,
    rating: 4.7,
    ratingCount: 530,
    prepMinutes: 15,
    calories: 680,
    isPopular: true,
    addOns: _riceAddOns,
  ),
  Dish(
    id: 'rice-tapa',
    imageUrl: '${_photo}1789239122826-db7c3fe94e4f$_photoParams',
    name: 'Beef Tapa Meal',
    description: 'Savory beef tapa with garlic rice and a fried egg.',
    price: 239,
    category: 'Rice Meals',
    icon: Icons.rice_bowl_rounded,
    rating: 4.8,
    ratingCount: 720,
    prepMinutes: 15,
    calories: 740,
    addOns: _riceAddOns,
  ),
  Dish(
    id: 'rice-garlic',
    imageUrl: '${_photo}1609570324378-ec0c4c9b6ba8$_photoParams',
    name: 'Garlic Rice & Egg',
    description: 'Fragrant garlic fried rice topped with a sunny-side egg.',
    price: 149,
    category: 'Rice Meals',
    icon: Icons.egg_alt_rounded,
    rating: 4.5,
    ratingCount: 260,
    prepMinutes: 8,
    calories: 520,
    addOns: _riceAddOns,
  ),
  Dish(
    id: 'side-fries',
    imageUrl: '${_photo}1518013431117-eb1465fa5752$_photoParams',
    name: 'Crispy Fries',
    description: 'Golden, salted fries served hot.',
    price: 99,
    category: 'Sides',
    icon: Icons.fastfood_rounded,
    rating: 4.7,
    ratingCount: 1530,
    prepMinutes: 6,
    calories: 360,
    isPopular: true,
    addOns: _sideAddOns,
  ),
  Dish(
    id: 'side-rings',
    imageUrl: '${_photo}1625938146369-adc83368bda7$_photoParams',
    name: 'Onion Rings',
    description: 'Thick-cut onion rings with a crunchy coating.',
    price: 119,
    category: 'Sides',
    icon: Icons.fastfood_rounded,
    rating: 4.4,
    ratingCount: 190,
    prepMinutes: 7,
    calories: 410,
    addOns: _sideAddOns,
  ),
  Dish(
    id: 'side-nuggets',
    imageUrl: '${_photo}1768204039907-77a974159ef0$_photoParams',
    name: 'Chicken Nuggets',
    description: 'Six juicy nuggets with your choice of dip.',
    price: 139,
    category: 'Sides',
    icon: Icons.set_meal_rounded,
    rating: 4.6,
    ratingCount: 480,
    prepMinutes: 8,
    calories: 430,
    addOns: _sideAddOns,
  ),
  Dish(
    id: 'drink-coffee',
    imageUrl: '${_photo}1517701550927-30cf4ba1dba5$_photoParams',
    name: 'Iced Coffee',
    description: 'Cold brew over ice, lightly sweetened.',
    price: 109,
    category: 'Drinks',
    icon: Icons.local_cafe_rounded,
    rating: 4.7,
    ratingCount: 650,
    prepMinutes: 3,
    calories: 140,
    addOns: _drinkAddOns,
  ),
  Dish(
    id: 'drink-tea',
    imageUrl: '${_photo}1556679343-c7306c1976bc$_photoParams',
    name: 'Lemon Iced Tea',
    description: 'Fresh brewed tea with a squeeze of lemon.',
    price: 79,
    category: 'Drinks',
    icon: Icons.local_drink_rounded,
    rating: 4.5,
    ratingCount: 340,
    prepMinutes: 2,
    calories: 110,
    addOns: _drinkAddOns,
  ),
  Dish(
    id: 'drink-mango',
    imageUrl: '${_photo}1546173159-315724a31696$_photoParams',
    name: 'Mango Shake',
    description: 'Ripe mango blended with ice and milk.',
    price: 129,
    category: 'Drinks',
    icon: Icons.local_drink_rounded,
    rating: 4.9,
    ratingCount: 910,
    prepMinutes: 4,
    calories: 260,
    isNew: true,
    addOns: _drinkAddOns,
  ),
  Dish(
    id: 'dessert-brownie',
    imageUrl: '${_photo}1636743715220-d8f8dd900b87$_photoParams',
    name: 'Chocolate Brownie',
    description: 'Fudgy brownie with a crisp top.',
    price: 99,
    category: 'Desserts',
    icon: Icons.cake_rounded,
    rating: 4.6,
    ratingCount: 300,
    prepMinutes: 3,
    calories: 380,
    addOns: _dessertAddOns,
  ),
  Dish(
    id: 'dessert-icecream',
    imageUrl: '${_photo}1516559828984-fb3b99548b21$_photoParams',
    name: 'Ube Ice Cream',
    description: 'Two scoops of creamy purple yam ice cream.',
    price: 89,
    category: 'Desserts',
    icon: Icons.icecream_rounded,
    rating: 4.9,
    ratingCount: 1100,
    prepMinutes: 2,
    calories: 290,
    isPopular: true,
    addOns: _dessertAddOns,
  ),
];

const List<Promo> kPromos = <Promo>[
  Promo(
    id: 'welcome',
    eyebrow: 'Welcome offer',
    title: '10% off your first order',
    subtitle: 'Use code KAZZI10 at checkout.',
    icon: Icons.local_offer_rounded,
    colors: <Color>[Color(0xFF1A5FFF), Color(0xFF4C2BD9)],
  ),
  Promo(
    id: 'burger-week',
    eyebrow: 'Burger week',
    title: 'Stacked, saucy, and back',
    subtitle: 'Try the Double Cheese while it’s hot.',
    icon: Icons.lunch_dining_rounded,
    colors: <Color>[Color(0xFFC2410C), Color(0xFF7C2D12)],
    category: 'Burgers',
  ),
  Promo(
    id: 'cool-down',
    eyebrow: 'Cool down',
    title: 'Shakes & iced drinks',
    subtitle: 'Mango Shake is new on the menu.',
    icon: Icons.local_drink_rounded,
    colors: <Color>[Color(0xFF0F766E), Color(0xFF134E4A)],
    category: 'Drinks',
  ),
];
