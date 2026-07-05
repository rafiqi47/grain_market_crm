# Grain Market CRM

Grain Market CRM is a high-performance customer relationship management platform built with Ruby on Rails, Hotwire, and Tailwind CSS. It features a reactive, single-page-application feel ("no full-page reloads") using Turbo Frames and Stimulus modals, role-based access control, and an integrated GraphQL engine engineered to maintain absolute feature and API parity with a future Flutter mobile application.

---

## 💎 System Requirements & Stack

* **Ruby Version:** `3.3.x` (Recommended)
* **Rails Version:** `7.x` or `8.x`
* **Database System:** PostgreSQL (Required for advanced data layer integration and GraphQL indexing)
* **Frontend Architecture:** Hotwire (`Turbo Drive`, `Turbo Frames`, `Stimulus`)
* **CSS Framework:** Tailwind CSS (via `tailwindcss-rails` gem)
* **Authentication:** Devise (Customized for Turbo Stream compatibility)
* **API Engine:** GraphQL

---

## 🛠️ System Dependencies

Before setting up the application, ensure your system has the following background processes running:
* **PostgreSQL:** A local running instance of PostgreSQL (`postgresql@14` or later recommended).
* **OpenSSL & Libpq:** Ensure native compiler packages are up to date for your OS to allow the compilation of the `pg` and `grpc`/`graphql` extensions.

---

## ⚙️ Configuration & Environment Setup

This application utilizes `dotenv-rails` to manage secure configurations and credentials.

1. Install backend dependencies:
   ```bash
   bundle install

2. Create a local environment file at the root of the project repository:
  ```bash
  touch .env

  Open the .env file and define any external database configuration, secrets, or API tokens needed by your development environment.

3. Database Setup & Initialization
  ```bash
  rails db:prepare

4. Run Unapplied Migrations:
  ```bash
  rails db:migrate

5. Seed Operational Archetypes:
  Populates default system lookups, default roles (super_admin, owner, manager), and default mock metrics for clean evaluation:
  ```bash
  rails db:seed

6. Hard Database Reset (Nuke and Rebuild):
  Drops the existing structures, recreates them fresh from the schema file, and runs the seeds:
  ```bash
  rails db:drop db:create db:schema:load db:seed

7. Running the Application
  Standard Development Server
  ```bash
  bin/dev

8. Separate Process Execution
  If your environment structure or debugger demands explicit thread isolation:

  a. Run the Rails Framework Web Server alone:
  ```bash
  rails server # (or 'rails s')

  b. Run the Tailwind Asset Engine watcher alone:
  ```bash
  rails tailwindcss:watch
