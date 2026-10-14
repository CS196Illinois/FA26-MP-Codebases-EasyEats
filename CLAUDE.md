# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

EasyEats recommends UIUC dining-hall food based on a user's nutrition goals and tracks what they eat. It has three parts:

- **Flutter app** (`Frontend/flutter_easyeats/`) that talks to the backend over HTTP
- **Node/Express API** (`Backend/server.js`) backed by a SQLite menu DB and JSON files
- **Python** meal planner (called by the API) and a Selenium menu scraper

This is a course MP codebase: students fork it, fix or improve something, and open a PR. Bugs and rough edges are expected. See `README.md` (student guide) and `Docs/RUN.md` (technical notes).

## Repository Structure

```
Backend/
  server.js               Express API, port 3000
  auth.js                 JSON-file user store, PBKDF2 password hashing, profiles, favorites
  meal-planning/meal_planner.py   meal plan generator, spawned by /api/meal-plan
  scrapers/nutrition_scraper.py   Selenium scraper for eatsmart.housing.illinois.edu -> .xlsx
  scrapers/load_to_db.py          .xlsx -> data/nutrition_data.db
  scrapers/requirements.txt       Python deps for scraper and planner
  data/                   runtime data (see below)
Frontend/flutter_easyeats/lib/   pages/, services/, models/
Docs/                     RUN.md, API_HANDBOOK.md, PLAN.md
WebScraping/, Research/   earlier experiments, not used by the app
*.xlsx, *.csv, mydatabase.db (repo root)   raw scrape exports / legacy, not used by the app
.github/                  PR template and PR checklist workflow
```

## Running

Requires Node 20+, Python 3.12 (`.python-version`), Flutter 3.35+ (Dart `^3.9.2`). No API keys.

**Backend** (terminal 1, from repo root):
```bash
python3.12 -m venv .venv && source .venv/bin/activate   # first time: create venv
pip install -r Backend/scrapers/requirements.txt
cd Backend
npm ci
node server.js          # or: npm run dev (node --watch); PORT=3001 to change port
curl localhost:3000/health
```
Keep the venv active: `server.js` spawns `python3` for `/api/meal-plan`, which needs pandas/numpy.

**Frontend** (terminal 2):
```bash
cd Frontend/flutter_easyeats
flutter pub get
flutter run -d chrome   # or -d macos / windows / linux / an emulator
flutter analyze
flutter test            # test/widget_test.dart is still the default counter template, not a real test
```

The API base URL `http://localhost:3000` is hard-coded in `services/auth_service.dart`, `services/nutrition_service.dart`, `pages/change_password_page.dart` and `pages/dining1_ike.dart`. Use `http://10.0.2.2:3000` on an Android emulator.

Running the app modifies `Backend/data/users.json` and `Backend/data/meal_tracking.json` (and sometimes `pubspec.lock`); don't commit those unless intended.

## Backend

### API routes (`Backend/server.js`)

| Route | Purpose |
|---|---|
| `GET /health` | Health check |
| `POST /api/auth/register`, `POST /api/auth/login` | Email/password auth (via `auth.js`), returns user id + profile |
| `GET/PUT /api/user/:userId/profile` | Read/update profile (goal, age, sex, calories, dietary_restrictions, notifications_enabled) |
| `POST /api/user/:userId/change-password` | Change password |
| `POST /api/user/:userId/favorites`, `DELETE /api/user/:userId/favorites/:index` | Manage favorites |
| `GET /api/dining-halls` | Distinct dining halls in the menu DB |
| `GET /api/dining-halls/:hall/foods?meal_type=&date=` | Foods for a hall (`LIKE` match on hall name) |
| `GET /api/recommendations/:userId?dining_hall=&meal_type=` | Top 20 foods ranked in SQL by protein ratio, fat ratio, fiber |
| `GET /api/meal-plan?calories=&dining_hall=&meal_type=&goal=` | Spawns `meal_planner.py --json` and returns its output |
| `POST/GET /api/user/:userId/meals` | Log a meal / meal history |
| `GET /api/user/:userId/today-totals` | Today's nutrition totals |
| `DELETE /api/user/:userId/meals/:mealId` | Delete a logged meal |

There is no session/token auth: routes trust the `userId` in the path.

### Data files (`Backend/data/`)

| File | Contents |
|---|---|
| `nutrition_data.db` | SQLite, table `nutrition_data` (dining_hall, service, date, meal_type, category, name, serving_size, calories, macros/micros). Loaded from a Dec 2025 scrape: 5 halls, ~2.2k rows, dates stored as text like `Friday, December 5, 2025`. Not every hall has every meal. |
| `users.json` | `{ "users": [...] }` accounts with hashed passwords, profiles, favorites |
| `meal_tracking.json` | `{ "meals": [...] }` logged meals with per-food nutrition |
| `archives/*.xlsx` | Older raw scrape |

### Python

- **`meal-planning/meal_planner.py`**: `MealPlanner` loads `nutrition_data` into pandas and builds a meal for a calorie target and goal (`balanced`, `weight_loss`, `bulking`, `keto`, defined as protein/fat/carb splits in `GOALS`). CLI: `--calories --hall --meal --goal --db --json`. Defaults to `../data/nutrition_data.db`; infers meal type from the current time if `--meal` is omitted. With `--json` stdout must be a single JSON object, since `server.js` parses it.
- **`scrapers/nutrition_scraper.py`**: `NutritionScraperComplete` drives headless Chrome over every hall/service/date/meal, clicks each item for nutrition, and exports `complete_dining_data_YYYYMMDD_HHMMSS.xlsx`. Set `TESTING_MODE = True` (5 items per meal) and lower `DAYS_TO_SCRAPE` in `__main__` for quick runs. Needs Google Chrome.
- **`scrapers/load_to_db.py <file.xlsx>`**: run from `Backend/scrapers/`; replaces the contents of `../data/nutrition_data.db`.

## Frontend (`Frontend/flutter_easyeats/lib/`)

Dependencies: `http`, `shared_preferences`. State lives in widgets plus the backend; there is no state-management library.

**Entry:** `main.dart` shows a `SplashScreen` that calls `UserService.loadSavedSession()` and routes to `MainPage` (logged in) or `AuthScreen`. `main_test_questionnaire.dart` is a standalone entry for testing the questionnaire.

**Flow:** `AuthScreen` → `SignUpScreen` / `SignInScreen` → `QuestionnaireScreen` (goal, age, sex, calories; saved via `AuthService.updateProfile`) → `MainPage`.

**pages/**
- `home_page.dart` — `MainPage`: dashboard with today's totals and bottom nav
- `dining_halls.dart` — a second `MainPage` class (hall list); the two files import each other with prefixes (`as home`, `as dining_halls`)
- `dining_hall_detail_page.dart` — foods, recommendations and meal logging for one hall
- `settings_page.dart` → `profile_page`, `dietary_restrictions_page`, `notifications_page`, `favorites_page`, `change_password_page`, `about_page`, `help_support_page`, `privacy_policy_page`
- `dining1_ike.dart` — old standalone demo calling `/api/meal-plan`; not imported anywhere

**services/** (all static methods)
- `auth_service.dart` — register, login, get/update profile
- `nutrition_service.dart` — dining halls, foods, recommendations, log/list/delete meals, today totals
- `user_service.dart` — current user in memory, backed by `storage_service.dart`
- `storage_service.dart` — `shared_preferences` session, valid for 7 days

**models/**
- `food_item.dart` — `FoodItem`
- `meal_entry.dart` — `MealEntry`, `NutritionTotals`

New screens go in `lib/pages/` (`*_screen.dart` for onboarding/auth, `*_page.dart` otherwise). Navigation uses plain `Navigator.push` / `pushReplacement`.

## Git

- Main branch: `main`. Work on a feature branch and open a PR; the PR template and `.github/workflows/pr-checklist.yml` require name, NetID, what/why/testing and a checklist.
