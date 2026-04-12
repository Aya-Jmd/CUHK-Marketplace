# CUHK Second-Hand Marketplace (Group 21)

A centralized, multi-tenant SaaS marketplace tailored specifically for the CUHK community. This platform connects students across different colleges to facilitate secure and efficient second-hand trading.

## Team Members

| Student Name | Student ID | GitHub Username |

* | **Ben**                  | 1155214136 | [@Ben-34](https://github.com/Ben-34) |
* | **Abdulrahman Mohammed** | 1155264624 | [@JotaroLivesAlone](https://github.com/JotaroLivesAlone) | 
* | **Abous Houssameddine**  | 1155256354 | [@housss77](https://github.com/housss77) |
* | **Jmoud Aya**            | 1155256382 | [@Aya-Jmd](https://github.com/Aya-Jmd) |
* | **Bingyan Wang**         | 1155191406 | [@VincentWang0719](https://github.com/VincentWang0719) |

##  Project Links
* **Deployed Application:** [https://cuhk-marketplace-group-21-217132cb7477.herokuapp.com/]
* **Repository:** [https://github.com/Aya-Jmd/CUHK-Marketplace]
* **Demo Video:** [TODO]

---

## Project Overview

### Market Pain Point
Second-hand trading at CUHK is currently fragmented across disorganized social channels (Facebook, WeChat), lacking structured data for effective filtering. Informal comment threads create confusion regarding real-time item availability (Available vs. Sold), while the lack of location visibility causes logistical friction when arranging pickups between distant hostels.

### Solution
We propose a centralized, **multi-tenant SaaS marketplace**. Following the SaaS architecture, the system treats different Colleges (e.g., Shaw, New Asia, Wu Yee Sun) as distinct "Communities" (Tenants).

* **Core Workflow:** Students can list items either globally or restricted to their specific College community. The system manages the full lifecycle of an item (Available → Reserved → Sold) to prevent double-booking.
* **SaaS Angle:** Each College acting as a tenant can have custom listing rules (e.g., expiry times) and isolated views, ensuring relevant local trading while maintaining a university-wide search capability.


---


## Advanced Features

1.  **Real-Time Chat**
    * In-app buyer-seller conversations are implemented inside the platform, with live-feeling message updates using Turbo Streams so users can negotiate without switching to external apps.
2.  **Intelligent Search**
    * Fuzzy search is implemented with `pg_search`, together with filtering and sorting options to improve item discoverability even when queries are partial or slightly inaccurate.
3.  **Location Integration**
    * Location-aware features are implemented through `leaflet-rails`, `geocoder`, and internal location APIs so users can work with meetup and listing locations more easily.
4.  **Price Analytics**
    * Category-based analytics and historical price views are implemented to help users estimate fair market value.
5.  **In-App Notification System**
    * Notification pages, unread/read state handling, and mark-as-read workflows are implemented to keep buyers and sellers updated on marketplace activity.


## Additional Features
1.  **Admin Governance and Moderation**
    * The website is managed by users with higher privileges : College administrators who can manage items and users from their assigned college, and System administrators who can manage items and users from every college.
2.  **Report and item management**
    * Users can report items to College and System administrators when necessary, so administrators can review items and delete them if need be.
3. **Secure Transactions**
    * Accepted offers use a meetup PIN workflow for secure completion, adding guardrails to the final handoff stage of the transaction lifecycle.
4.   **List of favorite items**
     * Users can mark items as their favorite and manage the list in their profile, so they can easily come back to them.
5.  **Currency conversion mechanism**
    * Integrated mechanism to display prices in the user's preferred currency across the website, to support students with international background/familiarity.

### Advanced feature ownership


| Advanced Feature | Primary Developer | Secondary Developer | Notes |
|---|---|---|---|
| Real-Time Chat | Houssameddine | Aya | In-app conversations with Turbo-powered live updates, Action Cable |
| Intelligent Search | Ben | Houssameddine | `pg_search`, keyword search, filters, and sorting |
| Location Integration | Abdulrahman | Ben | `leaflet-rails`, `geocoder`, and location API endpoints |
| Price Analytics | Aya | Houssameddine | Category price dashboard and historical views |
| In-App Notification System | Vincent | Aya | Notification center with read / unread workflows, Action Cable |


---

## Tech Stack

* **Framework:** Ruby on Rails 8
* **Database:** PostgreSQL
* **Deployment:** Heroku
* **Testing:**
    * RSpec (Unit Testing)
    * Cucumber (User Stories)

---

## Local Setup Instructions

To run this project locally on your machine:

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/Aya-Jmd/CUHK-Marketplace.git]
    cd CUHK-Marketplace
    ```

2.  **Install dependencies:**
    ```bash
    bundle install
    ```

3.  **Setup the database:**
  
*==> Requirement : PostgreSQL must be installed in your machine. You should have access to at least one PostgreSQL role (username, credentials).*

* Open `config/database.yml`.
    * Find the `development:` section.
    * Update the `username` and `password` fields with your local PostgreSQL credentials.
    * Run the setup commands:
    ```bash
    rails db:create
    rails db:migrate
    rails db:seed
    ```

1.  **Start the server:**
    ```bash
    rails server
    ```

2.  **Visit the app:**
    Open your browser and go to `http://localhost:3000`


## SimpleCov report

Insert the SimpleCov screenshot below before submission.

![SimpleCov report screenshot]()

### NOTE 
* The project contains a hardcoded System Administrator in the database, as seed.
  * Administrator email : admin@link.cuhk.edu.hk
  * Administrator password : 12345678