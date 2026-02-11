# CUHK Second-Hand Marketplace (Group 21)

A centralized, multi-tenant SaaS marketplace tailored specifically for the CUHK community. This platform connects students across different colleges to facilitate secure and efficient second-hand trading.

## Team Members

| Student Name | Student ID | GitHub Username |

| **Ben**                  | 1155214136 | [@Ben-34](https://github.com/Ben-34) |
| **Abdulrahman Mohammed** | 1155264624 | [@JotaroLivesAlone](https://github.com/JotaroLivesAlone) | 
| **Abous Houssameddine**  | 1155256354 | [@housss77](https://github.com/housss77) |
| **Jmoud Aya**            | 1155256382 | [@Aya-Jmd](https://github.com/Aya-Jmd) |

##  Project Links
* **Deployed Application:** [https://cuhk-marketplace-group-21-217132cb7477.herokuapp.com/]
* **Repository:** [https://github.com/Aya-Jmd/CUHK-Marketplace]

---

## Project Overview

### Market Pain Point
Second-hand trading at CUHK is currently fragmented across disorganized social channels (Facebook, WeChat), lacking structured data for effective filtering. Informal comment threads create confusion regarding real-time item availability (Available vs. Sold), while the lack of location visibility causes logistical friction when arranging pickups between distant hostels.

### Solution
We propose a centralized, **multi-tenant SaaS marketplace**. Following the SaaS architecture, the system treats different Colleges (e.g., Shaw, New Asia, Wu Yee Sun) as distinct "Communities" (Tenants).

* **Core Workflow:** Students can list items either globally or restricted to their specific College community. The system manages the full lifecycle of an item (Available → Reserved → Sold) to prevent double-booking.
* **SaaS Angle:** Each College acting as a tenant can have custom listing rules (e.g., expiry times) and isolated views, ensuring relevant local trading while maintaining a university-wide search capability.

---

## Planned "N-1" Advanced Features

1.  **Real-Time Chat**
    * A WebSocket-based messaging system enabling secure, in-app negotiations without exchanging personal phone numbers.
2.  **Intelligent Search**
    * Fuzzy search capability handling typos and partial matches (e.g., "Calc" matches "Calculus") to significantly improve item discoverability.
3.  **Location Integration**
    * Visualizes seller hostel locations to help buyers assess logistical difficulty (e.g., distance for carrying items).
4.  **Price Analytics**
    * Interactive dashboards displaying historical price trends by category, empowering users to evaluate fair market value.

---

## 🛠 Tech Stack

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
* Open `config/database.yml`.
    * Find the `development:` section.
    * Update the `username` and `password` fields with your local PostgreSQL credentials.
    * Run the setup commands:
    ```bash
    rails db:create
    rails db:migrate
    ```

4.  **Start the server:**
    ```bash
    rails server
    ```

5.  **Visit the app:**
    Open your browser and go to `http://localhost:3000`