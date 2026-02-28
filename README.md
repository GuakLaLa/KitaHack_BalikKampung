# 🌊 FloodSense

### AI-Powered Flood Monitoring & Emergency Response System

> **Shifting flood response from reactive evacuation to proactive preparedness.**  
> **Supporting SDG 11, SDG 13, and SDG 9**

---

## 📌 Project Overview

FloodSense is an AI-driven mobile application designed to improve flood preparedness, early warning, and emergency coordination in Malaysia.  
The platform transforms raw rainfall and geographical data into localized, predictive flood alerts, helping communities act before disaster strikes.  
Our mission is to shift flood response from reactive evacuation to proactive 

### 🚨 Problem Statement

Malaysia experiences severe seasonal flooding, particularly in low-lying and river-adjacent regions such as:
* Kelantan (Rantau Panjang, Kota Bharu)
* Johor (Segamat)
* Selangor (Shah Alam)

Traditional forecasts provide rainfall totals but fail to translate them into **actual flood impact**, leaving residents with minutes to evacuate.

* **Flash Floods:** Occur with minimal warning.
* **Data Gap:** Vulnerable groups lack actionable countdowns.
* **Economic Loss:** Property damage increases without early alerts.  

For example, in Rantau Panjang, even 10mm rainfall can lead to 0.47 km² of flooding due to geographical vulnerability.

---

## ✨ Key Features

* **0–3 Day Predictive Alerts:** AI-based risk levels (Low, Medium, High) for specific districts.
* **"Days Until Flood" Countdown:** A clear timer helping families plan evacuations.
* **Real-Time Shelter Finder:** Instant access to InfoBencana JKM PPS data with live capacity monitoring.
* **AI-Prioritized Reporting:** Gemini AI evaluates community reports based on vulnerability and severity for faster rescue triage.
* **Intelligent Map Layers:** Official AI markers combined with clustered community reports for a "double-verification" view.

---

## 🌍 SDG Alignment

| SDG | Target | FloodSense Implementation |
| --- | --- | --- |
| **11: Sustainable Cities & Communities** | 11.5: Reduce The Adverse Effects Of Natural Disasters | * Predicting affected flood areas in square kilometers ($km^2$) <br> * Providing actionable safety checklists <br> Enabling one-tap emergency calls <br> * AI-prioritizing high-risk cases for faster response|
| **13: Climate Action** | 13.1: Strengthen Resilience And Adaptive Capacity To Climate Related Disasters | * Using real-time rainfall data <br> * Calculating cumulative 3-day rainfall impact <br> * Providing early warning countdowns <br> * Sending dynamic flood alerts |
| **9: Industry, Innovation & Infrastructure** | 9.1: Develop Sustainable, Resilient And Inclusive Infrastructures | * BigQuery ML predictive modeling <br> * Cloud-based scalable infrastructure <br> * AI-powered emergency triage <br> * Digital disaster-management systems |

---

## 🛠 Technology Stack

### 📱 Frontend

**Flutter:**
* Single codebase for Android & iOS
* Fast UI development
* Seamless integration with Google services

### ☁ Backend & Cloud

**Firebase:** Authentication, Firestore (real-time data), and Cloud Functions.  
**Cloud Run:** Hosting for Python-based AI prediction services.

### 🧠 AI & Data

**BigQuery ML:**
* Linear Regression Model:`flood_model_v1`
* Predicts flood risk based on:
  * Rainfall
  * Elevation
  * District
* Powers:
  * “Days Until Flood”
  * 3-day Flood Forecast
  * Risk classification (High/Medium/Low)
* Current validation accuracy: 94.7%.

**Gemini AI:**
* Analyzes emergency reports.
* Evaluates:
  * Number of people affected
  * Water level
  * Vulnerable individuals
  * Situation description
  * Assigns priority score for admin triage

**Weather & External APIs**
* Open Meteo API (Rainfall anomaly)
* Google Weather API (7-day forecast)
* InfoBencana JKM (Live PPS shelter data – HTML parsed)

**Google Maps API**
* AI flood risk markers
* Clustered user reports
* Shelter navigation
* Real-time geolocation

---

## 🏗 Solution Architecture

1. **User → Flutter App:**  
   Users: View predictions, Report floods, Find shelters
2. **Flutter ↔ Firebase:**
   * Authentication verifies users
   * Firestore stores flood reports & profiles
   * Real-time updates for admin dashboard
3. **BigQuery ML:**
   * Receives rainfall & district data
   * Predicts flood risk & affected area
   * Returns results via Cloud Functions.
4. **Gemini AI → Admin Dashboard:**
   * Scores emergency reports
   * Sorts by urgency
   * Helps admins prioritize rescue efforts
5. **Google Maps API:**
   * Displays AI markers
   * Clusters reports
   * Shows nearby shelters
   * Provides directions

---

## **👥 User Validation & Testing**

* **Distribution**: We distributed the Android (.apk) version to real residents in flood-prone areas (non-team members).
* **Feedback Collection**: Feedback was collected via Google Forms including:
* **Usability**
* **Alert clarity**
* **Shelter finder efficiency**
* **AI prioritization usefulness**


* **Data Gathering**: We gathered both quantitative ratings and qualitative suggestions.

---

## **📊 Success Metrics**

We measure impact through:

1. **1️⃣ Model Accuracy**: BigQuery ML model validation accuracy: **94.7%**.
2. **2️⃣ Shelter Accessibility**: Users can locate a non-full evacuation centre within **3 taps**.
3. **3️⃣ Emergency Prioritization**: AI sorts high-risk cases automatically, reducing admin manual review time.

---

## **🤖 Why AI Matters**

* **Without AI**:
* No “Days Until Flood” countdown
* No localized predictive risk levels
* Forecast charts become static
* Admin must manually review all reports
* No intelligent prioritization


* **AI enables**:
* District-specific flood simulation
* Vulnerability-aware emergency scoring
* Faster resource allocation

---

## **⚙ Technical Challenges**

### **1️⃣ HTML Parsing from InfoBencana**

* **Problem**: Comma-formatted numbers (e.g., 2,165) were misread as 2.
* **Solution**:
* Updated regex to `([\d,]+)`
* Removed commas before parsing
* Expanded HTML capture window

### **2️⃣ AI Model Compatibility**

* **Problem**:
* Gemini model version mismatch with SDK
* Missing role field in Firestore caused navigation errors

* **Solution**:
* Updated to supported model
* Ensured default role assignment
* Refined async data handling

---

## **⚖ Technical Trade-Offs**

* **Decision**: We chose to scrape InfoBencana HTML rather than build our own shelter database.
* **Trade-off**: Scraping may break if structure changes.
* **Reason**:
* Guarantees real-time authoritative data
* Avoids outdated manual database maintenance

---

## **📈 Scalability & Growth Potential**

* **Short-Term**:
* Expand to all Malaysian states
* Train district-specific ML models
* Add multilingual support


* **Medium-Term**:
* Partner with NADMA and local councils
* Replace HTML scraping with official API


* **Long-Term**:
* Expand to Southeast Asia
* Offer API services to:
* Insurance companies
* Logistics firms
* Urban planners

---

## **🔥 What Makes FloodSense Unique?**

* **Predictive** (not reactive)
* **AI-based localized simulation**
* **Centralized verified reporting**
* **Real-time PPS capacity monitoring**
* **Community + Government integration**
* **Scalable cloud infrastructure**
* **Conclusion**: Unlike generic weather apps or social media reports, FloodSense provides structured, verified, and predictive flood intelligence.

---

## 🚀 Installation & Setup

1. **Clone the Repo:**
```bash
git clone https://github.com/your-username/floodsense.git

```


2. **Install Dependencies:**
```bash
flutter pub get

```


3. **Environment Setup:**
* Add `google_services.json` (Android) and `GoogleService-Info.plist` (iOS) to respective folders.
* Configure API Keys for Google Maps, Weather, and Firebase in your `.env` or configuration file.


4. **Run:**
```bash
flutter run

```
---

## 📄 License
Developed for educational and competition purposes

---
