# 🚆 UK Train Rides Data Analysis

This project presents a complete data analysis workflow for the **UK Train Ticket Dataset**, covering the entire analytical pipeline — from raw data preprocessing to dashboard visualization and forecasting.
It aims to generate actionable insights for **revenue optimization, operational efficiency, and customer satisfaction** across the UK railway network.
---

## 📘 1. Project Overview
The UK Train Rides project analyzes 31,653 train ticket transactions to identify patterns in ticket sales, delays, refunds, and customer behavior.
Through data modeling, cleaning, and forecasting, the project supports data-driven decision-making for train service providers.

**Objectives:**
* Understand travel and purchasing behaviors.
* Evaluate operational performance (on-time, delayed, cancelled).
* Forecast future demand and revenue.
* Identify improvement opportunities across routes and ticket types.
---

## 💾 2. Dataset Description
**Total Records:** 31,653
**Columns:** 18
**Missing Values:** None

Each record represents a unique ticket purchase containing:

* Transaction details (ID, price, purchase type, payment method)
* Travel details (date, time, departure, arrival, journey status)
* Delay and refund information (reason for delay, refund request)

---

## 🧰 3. Tools & Technologies Used
* **Python:** pandas, matplotlib, scikit-learn
* **SQL:** for data querying and joins
* **Tableau / Power BI:** for interactive dashboards
* **Excel:** preliminary data exploration

---

## ⚙️ 4. Data Preprocessing & Cleaning
Performed extensive preprocessing steps:

* Converted time fields into datetime format (`Date of Journey`, `Departure Time`, `Arrival Time`, `Actual Arrival Time`).
* Created derived features such as `Delay Duration` and `Revenue per Class`.
* Standardized categorical values (e.g., `Online / In-person`).
* Checked for outliers (negative prices, invalid times).
* Extracted **Month**, **Weekday**, and **Hour** for temporal analysis.

**Deliverables:**
* Cleaned dataset ready for analysis.
* Python notebook for preprocessing steps.

---

## 📊 5. Exploratory & Analytical Questions
**Key analytical questions include:**

* Which departure and arrival stations are the most popular?
* What are the average ticket prices by type and class?
* How does online vs in-person purchasing differ?
* What are the top reasons for train delays?
* Do longer trips experience higher delay rates?
* What is the relationship between ticket class, price, and refund requests?

---

## 💡 6. Key Performance Indicators (KPIs)

| Category                 | Example KPIs                                                             |
| ------------------------ | ------------------------------------------------------------------------ |
| **Operational**          | On-Time Performance (%), Average Delay (min), Cancellation Rate          |
| **Customer & Ticketing** | Total Tickets Sold, Refund Request Rate, Passenger Volume per Route      |
| **Financial**            | Total Revenue, Revenue per Route/Class, Refund Cost %, Fare Distribution |
| **Forecasting**          | Passenger Demand Forecast, Revenue Forecast, Seasonal Demand Patterns    |

---

## 🔮 7. Forecasting & Modeling
**Goal:** Predict ride demand and revenue trends for the next month.
**Approach:**

* Used **Time Series Forecasting (ARIMA / Linear Regression)** to predict total rides.
* Built regression models to estimate daily revenue and ticket demand by class.
* Evaluated performance using RMSE and R² metrics.

**Output:**

* Predicted rides and revenue per day for the upcoming month.
* Visualizations of seasonal demand patterns and class-based demand shifts.

---

## 📈 8. Visualization Dashboard
**Tools:** Tableau
The interactive dashboard visualizes:

* Journey Status (On-time / Delayed / Cancelled)
* Delay Reasons and Average Delay per Route
* Refund Rate by Ticket Type
* Revenue by Route, Station, and Class
* Forecasted Demand and Revenue Trends

**Dashboard KPIs:**

* Total Revenue
* Average Delay (minutes)
* Refund Rate (%)
* On-Time Performance (%)

---

## 🚀 9. Results & Insights

**Key Findings:**
* Majority of trips depart on time; however, delays cluster around specific stations.
* “Advance” ticket type generates higher revenue but higher refund rates.
* Technical and weather issues are top delay causes.
* Demand peaks in weekends and holiday seasons.
* Routes with better punctuality directly correlate with higher customer retention.

---

## 🔁 10. Future Work & Recommendations

**Strategic Recommendations:**
* Prioritize improvement in top 10 delay-prone stations.
* Automate customer refunds to enhance satisfaction.
* Implement predictive maintenance for frequent technical issues.
* Focus on dynamic pricing for peak vs. off-peak periods.
* Expand forecasting model with external factors (weather, events).

---


## 🧑‍💻 11. How to Run the Project
1. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/UK_Train_Rides_Analysis.git
   ```
2. Navigate into the project directory:
   ```bash
   cd UK_Train_Rides_Analysis
   ```
3. Install dependencies:

   ```bash
   pip install pandas matplotlib scikit-learn
   ```
4. Run the Jupyter notebooks in sequence:

   * `01_data_preprocessing.ipynb`
   * `02_data_analysis.ipynb`
   * `03_forecasting.ipynb`
5. Open the Tableau dashboard for interactive visualization.

---

### 🌟 Author
**Project:** UK Train Rides Data Analysis
**Role:** Data Analyst – Data Modeling, Forecasting, and Visualization

---
