# APEX UI Guide

This guide explains how to configure and run the application using the Oracle APEX interface.

## 1. Access APEX

Open your browser and go to:

http://localhost:8080/ords/apex

<img src="/app/img/01-image.PNG" width="300">

## 2. Login

Use the credentials defined during setup:

* Username: ADMIN
* Password: Matching12345!

<img src="/app/img/02-image.PNG" width="300" height="300"> 

## 3. Create Workspace

After logging in:

1. Go to **Administration**
2. Click on **Manage Workspaces**
3. Click **Create Workspace**

Fill in:

* Workspace Name
* Schema (you can use `MATCHING_APP`)
* Commit the changes

<img src="/app/img/03-image.PNG" width="300"> <img src="/app/img/04-image.PNG" width="300"> <img src="/app/img/05-image.PNG" width="300">

---

## 4. Switch to New Workspace

* Logout
* Login again using the newly created workspace

<img src="/app/img/logout.png" width="300" height="295">  <img src="/app/img/login.png" width="300">

---

## 5. Import Application

1. Go to **App Builder**
2. Click **Import**
3. Upload the file:

```text
f100.sql
```

4. Follow the import steps and confirm

<img src="/app/img/07-image.png" width="300" height="310"> <img src="/app/img/08-image.png" width="300"> <img src="/app/img/09-image.png" width="300">

---

## 6. Run Application

After import:

1. Open the application
2. Click **Run**

The application will open in a new tab.

![Run Application](images/05-run-app.png)

---

## 7. Test the Application

You can now:

* Create operators
* Create tasks
* Define assignments
* Execute the matching algorithm

---

## Notes

* Make sure your schema (`MATCHING_APP`) has all required objects
* If no data appears, verify that the database script was executed successfully
* If login fails, check workspace and credentials

---
