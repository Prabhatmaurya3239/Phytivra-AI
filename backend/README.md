# Phytivra-AI Backend

Backend API for the **Phytivra-AI** project. The backend is developed using **Django** and **Django REST Framework (DRF)** and provides APIs for crops, diseases, pesticides, pesticide recommendations, and crop-leaf image uploads.

This README is intended for the **frontend developer** to set up and run the backend locally and connect the frontend application to the APIs.

---

## 1. Project Overview

Phytivra-AI provides backend services for:

- Crop information
- Disease information
- Pesticide information
- Disease-to-pesticide recommendations
- Crop leaf image upload
- JSON-based REST APIs
- Media/image serving during local development

---

## 2. Technology Stack

| Technology | Purpose |
|---|---|
| Python | Backend programming language |
| Django | Web framework |
| Django REST Framework | REST API development |
| SQLite | Default development database |
| Pillow | Image upload and processing |
| Git | Version control |

---

## 3. Project Structure

The backend follows an `apps/` based Django structure.

```text
backend/
│
├── apps/
│   ├── crop/
│   ├── disease/
│   ├── pesticides/
│   ├── recommendations/
│   └── prediction/
│
├── api/
│   └── urls.py
│
├── config/
│   ├── settings.py
│   └── urls.py
│
├── media/
│   ├── crop_images/
│   ├── disease_images/
│   ├── pesticide_images/
│   └── leaf_images/
│
├── manage.py
├── db.sqlite3
└── requirements.txt
```

> The exact project/app folder names may differ if the backend structure has been customized. The commands below assume `manage.py` is located in the `backend` directory.

---

# 4. Prerequisites

Before running the backend, install:

- Python 3.x
- Git
- pip
- A code editor such as VS Code

Verify Python:

```bash
python --version
```

Verify pip:

```bash
pip --version
```

---

# 5. Clone the Project

If the project is hosted on GitHub, clone it using:

```bash
git clone <YOUR_REPOSITORY_URL>
```

Move into the backend directory:

```bash
cd Phytivra-AI\backend
```

If the project has already been downloaded, simply open a terminal in the `backend` directory.

---

# 6. Create a Virtual Environment

Creating a virtual environment keeps the backend dependencies isolated from other Python projects.

From the `backend` directory:

```bash
python -m venv venv
```

---

# 7. Activate the Virtual Environment

## Windows PowerShell

```powershell
.\venv\Scripts\Activate.ps1
```

If PowerShell blocks the activation script, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

Then activate again:

```powershell
.\venv\Scripts\Activate.ps1
```

## Windows Command Prompt

```cmd
venv\Scripts\activate
```

After successful activation, the terminal should show something similar to:

```text
(venv) C:\...\Phytivra-AI\backend>
```

---

# 8. Install Dependencies

If `requirements.txt` is available:

```bash
pip install -r requirements.txt
```

If the requirements file is not available, install the main dependencies:

```bash
pip install django djangorestframework Pillow
```

You can verify Django:

```bash
python -m django --version
```

---

# 9. Configure the Database

The project uses Django migrations to create and update database tables.

Run:

```bash
python manage.py makemigrations
```

Then:

```bash
python manage.py migrate
```

If the project already contains a working `db.sqlite3` and migration files, normally you only need:

```bash
python manage.py migrate
```

---

# 10. Create a Superuser

Creating a superuser is optional but recommended because it allows the developer to manage crops, diseases, pesticides, and recommendations through Django Admin.

Run:

```bash
python manage.py createsuperuser
```

Enter:

```text
Username:
Email:
Password:
Password (again):
```

Then start the server and open:

```text
http://127.0.0.1:8000/admin/
```

---

# 11. Check the Backend

Before starting the server, run:

```bash
python manage.py check
```

Expected output:

```text
System check identified no issues (0 silenced).
```

If there are errors, resolve them before connecting the frontend.

---

# 12. Run the Backend Server

Run:

```bash
python manage.py runserver
```

Expected output will be similar to:

```text
Starting development server at http://127.0.0.1:8000/
```

The backend is now running at:

```text
http://127.0.0.1:8000/
```

Keep this terminal running while developing the frontend.

---

# 13. Backend Base URL

For local frontend development, use:

```text
http://127.0.0.1:8000
```

API base URL:

```text
http://127.0.0.1:8000/api/
```

---

