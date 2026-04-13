# CUHK Second-Hand Marketplace (Group 21)

A centralized, multi-tenant SaaS marketplace tailored specifically for the CUHK community. This platform connects students across different colleges to facilitate secure and efficient second-hand trading.

## Team Members

| Student Name | Student ID | GitHub Username |
|---|---:|---|
| **Ben** | 1155214136 | [@Ben-34](https://github.com/Ben-34) |
| **Abdulrahman Mohammed** | 1155264624 | [@JotaroLivesAlone](https://github.com/JotaroLivesAlone) |
| **Abous Housameddine** | 1155256354 | [@housss77](https://github.com/housss77) |
| **Jmoud Aya** | 1155256382 | [@Aya-Jmd](https://github.com/Aya-Jmd) |
| **Bingyan Wang** | 1155191406 | [@VincentWang0719](https://github.com/VincentWang0719) |

## Project Links

- **Deployed Application:** [CUHK Marketplace on Heroku](https://cuhk-marketplace-group-21-217132cb7477.herokuapp.com/)
- **Repository:** [CUHK-Marketplace GitHub Repository](https://github.com/Aya-Jmd/CUHK-Marketplace)
- **Demo Video:** TODO

---

## Project Overview

### Market Pain Point
Second-hand trading at CUHK is currently fragmented across disorganized social channels such as Facebook and WeChat, lacking structured data for effective filtering. Informal comment threads create confusion regarding real-time item availability, while the lack of location visibility causes logistical friction when arranging pickups between distant hostels.

### Solution
We propose a centralized, **multi-tenant SaaS marketplace**. Following the SaaS architecture, the system treats different Colleges (for example Shaw, New Asia, and Wu Yee Sun) as distinct communities (tenants).

- **Core workflow:** Students can list items either globally or restricted to their specific college community. The system manages the full lifecycle of an item (**Available → Reserved → Sold**) to prevent conflicts and improve transaction clarity.
- **SaaS angle:** Each college acting as a tenant can have custom listing rules and isolated views, ensuring relevant local trading while maintaining a university-wide search capability.

---

## Implemented Features

### Core Features

1. **Item Listing and Management**  
   Users can create, edit, delete, and browse marketplace listings with item metadata, images, and listing status.
2. **Search, Filtering, and Sorting**  
   Users can search for items and refine results by relevant filters and sorting controls.
3. **Item Status Management**  
   Listings follow a transaction lifecycle such as **Available → Reserved → Sold** to reduce confusion and prevent duplicate claims.
4. **User Authentication and Role-Based Access**  
   The application supports authenticated access and differentiated privileges for normal users, college administrators, and system administrators.
5. **Multi-tenant College Community Logic**  
   Listings and moderation behavior are designed around CUHK colleges as separate communities within the same SaaS platform.

### Advanced Features

1. **Real-Time Chat**  
   In-app buyer-seller conversations are implemented inside the platform, with live-feeling message updates using Turbo Streams so users can negotiate without switching to external apps.
2. **Intelligent Search**  
   Fuzzy search is implemented with `pg_search`, together with filtering and sorting options to improve item discoverability even when queries are partial or slightly inaccurate.
3. **Location Integration**  
   Location-aware features are implemented through `leaflet-rails`, `geocoder`, and internal location APIs so users can work with meetup and listing locations more easily.
4. **Price Analytics**  
   Category-based analytics and historical price views are implemented to help users estimate fair market value.
5. **In-App Notification System**  
   Notification pages, unread/read state handling, and mark-as-read workflows are implemented to keep buyers and sellers updated on marketplace activity.

### Additional Features

1. **Admin Governance and Moderation**  
   The website is managed by users with higher privileges: college administrators who can manage items and users from their assigned college, and system administrators who can manage items and users across all colleges.
2. **Report and Item Management**  
   Users can report items to college and system administrators when necessary, so administrators can review items and delete them if needed.
3. **Secure Transactions**  
   Accepted offers use a meetup PIN workflow for secure completion, adding guardrails to the final handoff stage of the transaction lifecycle.
4. **Favorite Items List**  
   Users can mark items as favorites and manage the list in their profile so they can easily return to them later.
5. **Currency Conversion Mechanism**  
   The website can display prices in the user's preferred currency, supporting students from different international backgrounds.

---

## Implemented Feature Ownership

| Implemented Feature | Primary Developer(s) | Secondary Developer(s) | Notes |
|---|---|---|---|
| Real-Time Chat | Housameddine | Aya | In-app conversations with Turbo-powered live updates and Action Cable support. |
| Intelligent Search | Ben | Housameddine | `pg_search`, keyword search, filters, and sorting. |
| Location Integration | Abdulrahman | Ben | `leaflet-rails`, `geocoder`, and location API endpoints. |
| Price Analytics | Aya | Housameddine | Category price dashboard and historical views. |
| User Interface (UI) | Vincent, Housameddine, Aya | Abdulrahman, Ben | Visual design of the website. |
| In-App Notification System | Vincent | Aya | Notification center with read/unread workflows and Action Cable integration. |
| Item Listing and Management | Housameddine, Aya, Ben | Abdulrahman | Core marketplace workflow for creating, editing, deleting, and viewing listings. |
| Item Status Management | Housameddine, Aya | Abdulrahman | Supports the listing lifecycle from Available to Reserved to Sold. |
| User Authentication and Role-Based Access | Housameddine | Aya | Authentication and authorization for users, college administrators, and system administrators. |
| Multi-tenant College Community Logic | Aya | Housameddine | SaaS structure based on CUHK colleges as separate communities/tenants. |
| Admin Governance and Moderation | Housameddine | Aya | Administrators can manage users and listings based on role scope. |
| Report and Item Management | Aya | Housameddine | Report workflows allow moderation and item review by administrators. |
| Secure Transactions | Housameddine, Aya | Vincent, Ben | Meetup PIN flow secures the final handoff step for accepted offers. |
| Favorite Items List | Housameddine | x | Users can save and revisit favorite listings from their profile. |
| Currency Conversion Mechanism | Aya | x | Prices can be displayed in the user's selected currency. |



---

## Tech Stack

- **Framework:** Ruby on Rails 8
- **Database:** PostgreSQL
- **Deployment:** Heroku
- **Testing:**
  - RSpec (unit testing)
  - Cucumber (BDD / user-story testing)

---

## Setup Guide

### Prerequisites

Before running the project locally, make sure you have the following installed:

- Ruby
- Bundler
- PostgreSQL
- Git

You must also have access to at least one local PostgreSQL role (username and password).

### Clone the Repository

```bash
git clone https://github.com/Aya-Jmd/CUHK-Marketplace.git
cd CUHK-Marketplace
```

### Install Dependencies

```bash
bundle install
```

### Configure the Database

Open `config/database.yml` and update the `development` and, if needed, `test` database credentials with your local PostgreSQL username and password.

Then run:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### Start the Application

```bash
bin/rails server
```

Then visit:

```text
http://localhost:3000
```

---

## Run Tests

Run the automated test suites with the following commands:

### RSpec

```bash
bundle exec rspec
```

### Cucumber

```bash
bundle exec cucumber
```

To run both one after another:

```bash
bundle exec rspec
bundle exec cucumber
```

---

## SimpleCov Report

Generate the coverage report by running the test suites:

```bash
bundle exec rspec
bundle exec cucumber
```

After the suite finishes, open:

```bash
coverage/index.html
```

This report is generated with `SimpleCov` and can be screenshotted for submission evidence. The configured report merges `RSpec` and `Cucumber` into the same SimpleCov output and includes all application files.

Latest local run:

- **Line coverage:** `82.52%`
- **Branch coverage:** `63.96%`

If Windows keeps old coverage assets locked, close any open `coverage/index.html` tab before rerunning the suite so SimpleCov can refresh the single report cleanly.

![SimpleCov report screenshot](REPLACE_WITH_YOUR_SCREENSHOT_PATH)

---

## Seeded Administrator Account

The project contains a hardcoded system administrator in the database seeds for development and testing.

- **Administrator email:** `admin@example.com`
- **Administrator password:** `Admin12345`
