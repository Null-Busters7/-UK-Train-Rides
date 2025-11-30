/* --------------------------------------------------------
   📊 Operational KPIs
   On-Time Performance (%)
   
   Metric: Percentage of journeys arriving on time.
---------------------------------------------------------*/
Use UK_train
SELECT 
    CONCAT(ROUND((CAST(SUM(CASE WHEN S.Journey_Status = 'On Time' THEN 1 ELSE 0 END) AS FLOAT)
             / COUNT(F.Transaction__id)) * 100,2),'%') AS OnTime_Percentage
FROM 
    Fact_TrainRides AS F
INNER JOIN 
    Dim_Status AS S ON F.Status_Key = S.Status_Key;


/* --------------------------------------------------------
   📊 Operational KPIs
   Query — Average Delay (Minutes) for Delayed Trips Only

   Metric: Mean delay time for only delayed journeys.
---------------------------------------------------------*/
SELECT ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S ON F.Status_Key = S.Status_Key
WHERE S.Journey_Status = 'Delayed';


/* --------------------------------------------------------
   📊 Operational KPIs
   Average Delay by Time of Day

   Metric: Mean delay time for delayed journeys segmented by time.
---------------------------------------------------------*/
SELECT 
    CASE 
        WHEN DATEPART(HOUR, T.Departure_Time) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, T.Departure_Time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, T.Departure_Time) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END AS Time_Period,

    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S ON F.Status_Key = S.Status_Key
INNER JOIN Dim_Time AS T ON F.Time_key = T.Time_key
WHERE S.Journey_Status = 'Delayed'
GROUP BY
    CASE 
        WHEN DATEPART(HOUR, T.Departure_Time) BETWEEN 5 AND 11 THEN 'Morning'
        WHEN DATEPART(HOUR, T.Departure_Time) BETWEEN 12 AND 16 THEN 'Afternoon'
        WHEN DATEPART(HOUR, T.Departure_Time) BETWEEN 17 AND 20 THEN 'Evening'
        ELSE 'Night'
    END;


/* --------------------------------------------------------
   📊 Operational KPIs
   Journey Completion Rate (%)
   
   Metric: Percentage of trips completed successfully (not cancelled).
---------------------------------------------------------*/
SELECT 
    ROUND(CAST(SUM(CASE WHEN S.Journey_Status <> 'Cancelled' THEN 1 ELSE 0 END) AS FLOAT)
        / COUNT(*) * 100,
        2
    ) AS CompletionRate_Percentage
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key;


/* --------------------------------------------------------
   📊 Operational KPIs
   Cancellation Rate (%)
   
   Metric: Percentage of scheduled trips that were cancelled.
---------------------------------------------------------*/
SELECT 
    ROUND(CAST(SUM(CASE WHEN S.Journey_Status = 'Cancelled' THEN 1 ELSE 0 END) AS FLOAT)
        / COUNT(*) * 100,
        2
    ) AS CancellationRate_Percentage
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key;


/* --------------------------------------------------------
   📊 Operational KPIs
   Top 5 Routes/Stations by Average Delay (Minutes)
   
   Metric: Mean delay time segmented by arrival station and route.
---------------------------------------------------------*/
SELECT TOP 5
    R.Arrival_Destination AS Arrival_Station,
    CONCAT(R.Departure_Station, ' -> ', R.Arrival_Destination) AS Route_Name,
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY
    R.Arrival_Destination,
    R.Departure_Station
ORDER BY Average_Delay_Minutes DESC; 


/* --------------------------------------------------------
   📊 Operational KPIs
   Turnaround Time Analysis
   
   Metric: Comparison of average actual journey duration vs. scheduled time.
---------------------------------------------------------*/
SELECT TOP 1000
    CONCAT(R.Departure_Station, ' -> ', R.Arrival_Destination) AS Route_Name,
    ROUND(AVG(F.journey_duration_mins * 60), 2) AS Avg_Actual_Duration_Mins,
    MIN(
        CASE 
            WHEN R.Arrival_Time < R.Departure_Time THEN 
                1440 + DATEDIFF(minute, R.Departure_Time, R.Arrival_Time)
            ELSE 
                DATEDIFF(minute, R.Departure_Time, R.Arrival_Time)
        END
    ) AS Scheduled_Duration_Mins,
    ROUND(AVG(F.journey_duration_mins * 60), 2) - MIN(
        CASE 
            WHEN R.Arrival_Time < R.Departure_Time THEN 
                1440 + DATEDIFF(minute, R.Departure_Time, R.Arrival_Time)
            ELSE 
                DATEDIFF(minute, R.Departure_Time, R.Arrival_Time)
        END
    ) AS Duration_Difference_Mins

FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY
    R.Departure_Station,
    R.Arrival_Destination
ORDER BY Duration_Difference_Mins DESC;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Total Tickets Sold
   
   Metric: Total number of tickets (transactions) recorded.
---------------------------------------------------------*/
SELECT FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold
FROM Fact_TrainRides;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Overall Average Ticket Price
   
   Metric: Mean ticket price across all transactions.
---------------------------------------------------------*/
SELECT
    ROUND(AVG(F.Price_Original), 2) AS Overall_Average_Price
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Average Ticket Price by Class & Type
   
   Metric: Mean ticket price segmented by ticket class and type.
---------------------------------------------------------*/
SELECT
    D.Ticket_Class,
    D.Ticket_Type,
    ROUND(AVG(F.Price_Original), 2) AS Average_Price
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS D
    ON F.Ticket_Key = D.Ticket_Key
GROUP BY
    D.Ticket_Class,
    D.Ticket_Type
ORDER BY
    D.Ticket_Class,
    Average_Price DESC;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Passenger Volume per Route / Class
   
   Metric: Total number of tickets sold segmented by route and class.
---------------------------------------------------------*/
SELECT TOP 1000
    CONCAT(R.Departure_Station, ' -> ', R.Arrival_Destination) AS Route_Name,
    D.Ticket_Class,
    COUNT(*) AS Passenger_Volume_Count
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS D
    ON F.Ticket_Key = D.Ticket_Key
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY
    R.Departure_Station,
    R.Arrival_Destination,
    D.Ticket_Class
ORDER BY Passenger_Volume_Count DESC;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Refund Request Rate (%)
   
   Metric: Percentage of tickets requested for refund.
---------------------------------------------------------*/
SELECT
    FORMAT(CAST(SUM(CASE WHEN F.Refund_Request = 'Yes' THEN 1 ELSE 0 END) AS FLOAT)
	/ COUNT(*),'P2' 
    ) AS RefundRate_Percentage_Formatted
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Passenger Volume per Ticket Class
   
   Metric: Total number of tickets sold segmented by ticket class.
---------------------------------------------------------*/
SELECT D.Ticket_Class, COUNT(*) AS Passenger_Volume
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS D 
    ON F.Ticket_Key = D.Ticket_Key
GROUP BY D.Ticket_Class
ORDER BY Passenger_Volume DESC;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Passenger Volume per Ticket Type
   
   Metric: Total number of tickets sold segmented by ticket type.
---------------------------------------------------------*/
SELECT D.Ticket_Type,COUNT(*) AS Passenger_Volume
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS D 
    ON F.Ticket_Key = D.Ticket_Key
GROUP BY D.Ticket_Type
ORDER BY Passenger_Volume DESC;


/* --------------------------------------------------------
   📊 Customer & Ticketing
   Passenger Volume per Railcard
   
   Metric: Total number of tickets sold segmented by railcard type.
---------------------------------------------------------*/
SELECT P.Railcard,
    FORMAT(COUNT(*), '#,##0') AS Passenger_Volume_Formatted
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P 
    ON F.Purchase_Key = P.Purchase_Key
GROUP BY P.Railcard
ORDER BY COUNT(*) DESC; 


/* --------------------------------------------------------
   📊 Financial
   Total Revenue
   
   Metric: Sum of all ticket prices recorded.
---------------------------------------------------------*/
SELECT FORMAT(SUM(F.Price_Original), '#,##0.00') AS Total_Revenue
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   📊 Financial
   Revenue by Route
   
   Metric: Total revenue segmented by the full route (Departure -> Arrival).
---------------------------------------------------------*/
SELECT TOP 1000
    CONCAT(R.Departure_Station, ' -> ', R.Arrival_Destination) AS Route_Name,
    FORMAT(SUM(F.Price_Original), '#,##0.00') AS Total_Revenue
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY 
       R.Departure_Station,
	   R.Arrival_Destination
ORDER BY SUM(F.Price_Original) DESC;


/* --------------------------------------------------------
   📊 Financial
   Revenue by Arrival Station
   
   Metric: Total revenue segmented by the final destination station.
---------------------------------------------------------*/
SELECT TOP 1000 R.Arrival_Destination AS Arrival_Station,
    FORMAT(SUM(F.Price_Original), '#,##0.00') AS Total_Revenue
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY R.Arrival_Destination
ORDER BY SUM(F.Price_Original) DESC;


/* --------------------------------------------------------
   📊 Financial
   Revenue by Ticket Class
   
   Metric: Total revenue segmented by ticket class (Standard/First Class).
---------------------------------------------------------*/
SELECT D.Ticket_Class,
    FORMAT(SUM(F.Price_Original), '#,##0.00') AS Total_Revenue
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS D
    ON F.Ticket_Key = D.Ticket_Key
GROUP BY D.Ticket_Class
ORDER BY SUM(F.Price_Original) DESC;


/* --------------------------------------------------------
   📊 Financial
   Revenue per Passenger (Yield)
   
   Metric: Total Revenue divided by Total Passenger Volume.
---------------------------------------------------------*/
SELECT ROUND(SUM(F.Price_Original) / COUNT(*), 2) AS Revenue_Per_Passenger_Yield
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   📊 Financial
   Refund Cost Analysis (Value and Percentage)
   
   Metric: Total revenue lost (Value) and its ratio to total revenue (%).
---------------------------------------------------------*/
SELECT
    FORMAT(SUM(F.Price_Original), '#,##0.00') AS Total_Revenue, 
    FORMAT(SUM(CASE WHEN F.Refund_Request = 'Yes' THEN F.Price_Original ELSE 0 END),'#,##0.00') AS Total_Refund_Cost, 
    FORMAT((SUM(CASE WHEN F.Refund_Request = 'Yes' THEN F.Price_Original ELSE 0 END) / SUM(F.Price_Original)), 'P2' ) AS Refund_Cost_Percentage
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   📊 Service Quality
   Refund Reasons Analysis (Volume and Percentage)
   
   Metric: Volume and percentage distribution of refunds by delay reason.
---------------------------------------------------------*/
SELECT
    S.Reason_for_Delay,
    COUNT(*) AS Refund_Volume,
    FORMAT(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER(), 'P1') AS Refund_Percentage,
    SUM(COUNT(*)) OVER() AS Total_Refunds
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key
WHERE F.Refund_Request = 'Yes'
GROUP BY S.Reason_for_Delay
ORDER BY Refund_Volume DESC;


/* --------------------------------------------------------
   📊 Service Quality
   On-Time Reliability Trend (Monthly Trend)
   
   Metric: Percentage of journeys completed on time, trended monthly across 4 months.
---------------------------------------------------------*/
SELECT
    FORMAT(F.journeydate_Key, 'yyyy-MM') AS Analysis_Month,
    COUNT(CASE WHEN S.Journey_Status = 'On Time' THEN 1 ELSE NULL END) AS On_Time_Count,
    COUNT(*) AS Total_Journeys,
    FORMAT(CAST(COUNT(CASE WHEN S.Journey_Status = 'On Time' THEN 1 ELSE NULL END) AS FLOAT)
        / COUNT(*),
        'P1' 
    ) AS Reliability_Percentage
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key
GROUP BY FORMAT(F.journeydate_Key, 'yyyy-MM')
ORDER BY Analysis_Month;


/* --------------------------------------------------------
   📊 Operational
   Busiest Hours for Purchases (Joining Dim_Purchase)
   
   Metric: Transaction volume grouped by hour of the day (0-23).
---------------------------------------------------------*/

SELECT
    -- P.purchase_hour موجود في جدول أبعاد الشراء
    P.purchase_hour,
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
GROUP BY P.purchase_hour
ORDER BY Transaction_Volume DESC;


	/* --------------------------------------------------------
   📊 Operational
   Passenger Volume & Revenue: Weekday vs. Weekend
   
   Metric: Total transactions and revenue segmented by day type.
---------------------------------------------------------*/
SELECT
    CASE
        WHEN DATEPART(dw, F.journeydate_Key) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type,
        FORMAT(COUNT(*), '#,##0') AS Passenger_Volume,
        FORMAT(SUM(F.Price), '#,##0.00') AS Total_Revenue,
        FORMAT(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Fact_TrainRides), 
        'P1' -- نسبة مئوية بمنزلة عشرية واحدة
    ) AS Volume_Percentage
FROM Fact_TrainRides AS F
GROUP BY
    CASE
        WHEN DATEPART(dw, F.journeydate_Key) IN (1, 7) THEN 'Weekend'
        ELSE 'Weekday'
    END
ORDER BY Passenger_Volume DESC;


/* --------------------------------------------------------
   📊 Operational
   Busiest Day of the Week
   
   Metric: Total transaction volume grouped by the day name.
---------------------------------------------------------*/
SELECT
    DATENAME(dw, F.journeydate_Key) AS Day_Name,
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume
FROM Fact_TrainRides AS F
GROUP BY DATENAME(dw, F.journeydate_Key)
ORDER BY Transaction_Volume DESC;


/* --------------------------------------------------------
   📊 Operational
   Channel Usage Analysis (القناة الأكثر استخداماً)
   
   Metric: Transaction volume segmented by purchase channel.
---------------------------------------------------------*/
SELECT
    P.Purchase_Type AS Purchase_Channel,
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
GROUP BY P.Purchase_Type
ORDER BY Transaction_Volume DESC;


/* --------------------------------------------------------
   📊 Customer Behavior / Operational
   Channel Behavior & Top Destinations Analysis (Using Route Key)
   
   Metric: Transaction Volume, Average Ticket Price (Behavior), and Top Route (Key) 
           split by P.Purchase_Type ('Online' vs. 'Station').
---------------------------------------------------------*/
WITH ChannelVolume AS (SELECT
        P.Purchase_Type,
        F.Route_Key,
        COUNT(*) AS Transaction_Volume,
        ROUND(AVG(F.Price), 2) AS Average_Ticket_Price, 
        ROW_NUMBER() OVER(PARTITION BY P.Purchase_Type ORDER BY COUNT(*) DESC) AS Rank_by_Channel
    FROM Fact_TrainRides AS F
    INNER JOIN Dim_Purchase AS P
        ON F.Purchase_key = P.Purchase_key
    GROUP BY P.Purchase_Type, F.Route_Key)
SELECT CV.Purchase_Type AS Purchase_Channel,
        SUM(CV.Transaction_Volume) OVER(PARTITION BY CV.Purchase_Type) AS Total_Channel_Volume,
    AVG(CV.Average_Ticket_Price) OVER(PARTITION BY CV.Purchase_Type) AS Channel_Average_Price,
    CASE WHEN CV.Rank_by_Channel = 1 THEN CV.Route_Key ELSE NULL END AS Top_Destination_Route_Key,
    CASE WHEN CV.Rank_by_Channel = 1 THEN CV.Transaction_Volume ELSE NULL END AS Top_Route_Volume
FROM ChannelVolume AS CV
WHERE CV.Rank_by_Channel = 1
ORDER BY Total_Channel_Volume DESC;


/* --------------------------------------------------------
   💳 Enhanced Analysis: Card Type vs. Price Class (Fixed Ordering)
---------------------------------------------------------*/
WITH TicketPriceClassification AS (
    SELECT
        F.Price,
        F.Purchase_key,
        CASE
            WHEN F.Price > 0.20 THEN 'High Price' 
            WHEN F.Price > 0.10 THEN 'Medium Price' 
            ELSE 'Low/Discount Price' 
        END AS Price_Class
    FROM Fact_TrainRides AS F
),
AggregatedMetrics AS (
    SELECT
        P.Payment_Method AS Card_Type, 
        T.Price_Class,
        COUNT(*) AS Transaction_Volume,
        AVG(T.Price) AS Average_Price_in_Class
    FROM TicketPriceClassification AS T
    INNER JOIN Dim_Purchase AS P
        ON T.Purchase_key = P.Purchase_key
    GROUP BY
        P.Payment_Method,
        T.Price_Class
)
SELECT
    A.Card_Type,
    A.Price_Class,
    FORMAT(A.Transaction_Volume, '#,##0') AS Transaction_Volume,
    ROUND(A.Average_Price_in_Class, 2) AS Average_Price_in_Class,
        ROUND((CAST(A.Transaction_Volume AS FLOAT) * 100.0) / 
        SUM(A.Transaction_Volume) OVER(PARTITION BY A.Card_Type),1) AS Share_of_Card_Type_Percent    
FROM AggregatedMetrics AS A
ORDER BY A.Card_Type,
    ROUND((CAST(A.Transaction_Volume AS FLOAT) * 100.0) / 
        SUM(A.Transaction_Volume) OVER(PARTITION BY A.Card_Type), 1 ) DESC;


/* --------------------------------------------------------
   💰 Financial & Customer
   Discount Card Preferences Analysis
   
   Metric: Transaction volume segmented by the type of discount card used.
---------------------------------------------------------*/
SELECT
    P.Railcard AS Discount_Card_Type,
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume, 
    FORMAT(AVG(F.Price_Original - F.Price), '#,##0.00') AS Average_Discount_Amount,
    FORMAT((CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Fact_TrainRides WHERE Price_Original > Price))
        , 'P1'
    ) AS Share_of_Total_Discount_Volume
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
WHERE
    F.Price_Original > F.Price
GROUP BY P.Railcard
ORDER BY COUNT(*) DESC;


/* --------------------------------------------------------
   💰 Financial & Customer
   Share of Total Refund Requests 
---------------------------------------------------------*/
SELECT
    P.Payment_Method,
        FORMAT(SUM(CASE WHEN F.Refund_Request IS NOT NULL THEN 1 ELSE 0 
    END), '#,##0') AS Method_Refund_Requests,
    
    FORMAT((CAST(SUM(CASE WHEN F.Refund_Request IS NOT NULL THEN 1 ELSE 0 END) AS FLOAT) / 
        (SELECT SUM(CASE WHEN Refund_Request IS NOT NULL THEN 1 ELSE 0 END) 
         FROM Fact_TrainRides))
        , 'P2') AS Share_of_Total_Refunds_Percent
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
GROUP BY P.Payment_Method
ORDER BY SUM(CASE WHEN F.Refund_Request IS NOT NULL THEN 1 ELSE 0 END) DESC;


/* --------------------------------------------------------
   📊 Operational & Behavioral
   Most Common Departure and Arrival Stations/Routes 
---------------------------------------------------------*/
SELECT F.Route_Key,
    R.Departure_Station + ' -> ' + R.Arrival_Destination AS Full_Route_Description, 
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY
    F.Route_Key,
    R.Departure_Station, 
    R.Arrival_Destination
ORDER BY COUNT(*) DESC;


/* --------------------------------------------------------
   💰 Financial & Customer
   Average Ticket Price by Ticket Type (Advance, Off-Peak, Anytime)
---------------------------------------------------------*/
SELECT
    T.Ticket_Type, 
    FORMAT(AVG(F.Price_Original), '#,##0.00') AS Average_Ticket_Price,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
GROUP BY T.Ticket_Type
ORDER BY AVG(F.Price_Original) DESC;


/* --------------------------------------------------------
   📊 Customer & Behavioral
   Online vs. Station Sales Ratio
   
   Metric: Percentage of tickets sold via Online vs. Station channels.
---------------------------------------------------------*/
SELECT
    P.Purchase_Type AS Sales_Channel,
    FORMAT(COUNT(*), '#,##0') AS Total_Transactions,
    FORMAT((CAST(COUNT(*) AS FLOAT) / 
        (SELECT COUNT(*) FROM Fact_TrainRides))
        , 'P2' 
    ) AS Share_of_Total_Sales_Percent
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
GROUP BY P.Purchase_Type
ORDER BY COUNT(*) DESC;


/* --------------------------------------------------------
   💰 Financial & Customer
   Most Used Payment Method (Including Percentage Share)
---------------------------------------------------------*/
SELECT
    P.Payment_Method,
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume,
        FORMAT((CAST(COUNT(*) AS FLOAT) / 
        (SELECT COUNT(*) FROM Fact_TrainRides))
        , 'P2'
    ) AS Share_of_Total_Transactions_Percent
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
GROUP BY P.Payment_Method
ORDER BY COUNT(*) DESC;


/* --------------------------------------------------------
   📊 Operational & Behavioral
   Monthly Booking Volume
---------------------------------------------------------*/

SELECT
    FORMAT(F.journeydate_Key, 'yyyy-MM') AS Booking_Month,
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume
FROM 
    Fact_TrainRides AS F
GROUP BY FORMAT(F.journeydate_Key, 'yyyy-MM')
ORDER BY COUNT(*) DESC;


	/* --------------------------------------------------------
   📊 Operational & Behavioral
   Weekday Booking Volume
---------------------------------------------------------*/

SELECT
    FORMAT(F.journeydate_Key, 'dddd') AS Booking_Day_of_Week,
    DATEPART(dw, F.journeydate_Key) AS Day_Sort_Order, 
    FORMAT(COUNT(*), '#,##0') AS Transaction_Volume
FROM 
    Fact_TrainRides AS F
GROUP BY
    FORMAT(F.journeydate_Key, 'dddd'),
    DATEPART(dw, F.journeydate_Key)
ORDER BY
    COUNT(*) DESC;


/* --------------------------------------------------------
   📊 Customer & Behavioral
   Online vs. Station Sales Ratio (Channel Preference)
---------------------------------------------------------*/
SELECT
    P.Purchase_Type AS Sales_Channel,
    FORMAT(COUNT(*), '#,##0') AS Total_Transactions,
    FORMAT((CAST(COUNT(*) AS FLOAT) / 
        (SELECT COUNT(*) FROM Fact_TrainRides))
        , 'P2' 
    ) AS Share_of_Total_Sales_Percent
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Purchase AS P
    ON F.Purchase_key = P.Purchase_key
GROUP BY P.Purchase_Type
ORDER BY COUNT(*) DESC;


/* --------------------------------------------------------
   📊 Behavioral vs. Operational Performance
   Advance Booking vs. Average Delay
---------------------------------------------------------*/
SELECT
    T.Ticket_Type,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
WHERE 
    T.Ticket_Type IN ('Advance', 'Off-Peak', 'Anytime') 
GROUP BY T.Ticket_Type
ORDER BY Average_Delay_Minutes ASC;


/* --------------------------------------------------------
   ⏱️ Operational Performance
   On-Time vs. Delayed vs. Canceled Ratio 
   
   FIX: Using S.Journey_Status
---------------------------------------------------------*/

SELECT
    CASE 
        WHEN S.Journey_Status = 'Canceled' THEN 'Canceled' 
        WHEN F.delay_minutes > 0 THEN 'Delayed'
        ELSE 'On-Time'
    END AS Trip_Status,
    FORMAT(COUNT(*), '#,##0') AS Total_Trips,
    
    FORMAT((CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM Fact_TrainRides))
        , 'P2' 
    ) AS Share_of_Total_Percent
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S 
    ON F.Status_Key = S.Status_Key
GROUP BY
    CASE 
        WHEN S.Journey_Status = 'Canceled' THEN 'Canceled' 
        WHEN F.delay_minutes > 0 THEN 'Delayed'
        ELSE 'On-Time'
    END
ORDER BY COUNT(*) DESC;


/* --------------------------------------------------------
   ⏱️ Operational Performance
   Most Common Reasons for Delay
---------------------------------------------------------*/
SELECT
    S.Reason_for_Delay AS Delay_Reason,
    FORMAT(COUNT(*), '#,##0') AS Frequency_of_Delay_Reason,
    ROUND(SUM(F.delay_minutes), 0) AS Total_Delay_Minutes_Caused
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key
WHERE
    S.Reason_for_Delay IS NOT NULL 
    AND S.Reason_for_Delay NOT IN ('N/A', 'None', 'No Delay', 'NULL') 
GROUP BY S.Reason_for_Delay
ORDER BY COUNT(*) DESC; 


/* --------------------------------------------------------
   ⏱️ Operational Performance
   Average Delay by Day of the Week (Sorted by Delay)
---------------------------------------------------------*/
SELECT
    FORMAT(F.journeydate_Key, 'dddd') AS Day_of_Week,
    DATEPART(dw, F.journeydate_Key) AS Day_Sort_Order, 
    FORMAT(COUNT(*), '#,##0') AS Total_Trips,
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
    FROM Fact_TrainRides AS F
GROUP BY
    FORMAT(F.journeydate_Key, 'dddd'),
    DATEPART(dw, F.journeydate_Key)
ORDER BY Average_Delay_Minutes DESC; 


/* --------------------------------------------------------
   ⏱️ Operational Performance
   Percentage of Severe Delays (Over 15 Minutes)
---------------------------------------------------------*/
SELECT
    FORMAT(COUNT(*), '#,##0') AS Total_Trips,
	FORMAT(SUM(CASE WHEN F.delay_minutes > 15 THEN 1 ELSE 0 END), '#,##0') AS Severe_Delay_Trips_Count,
    FORMAT((CAST(SUM(CASE WHEN F.delay_minutes > 15 THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*))
        , 'P2' -- تنسيق كنسبة مئوية
    ) AS Severe_Delay_Rate_Percent 
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   ✨ Customer Quality & Operational
   Comparison of Trip Punctuality by Ticket Type
---------------------------------------------------------*/
SELECT
    T.Ticket_Type, 
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold, 
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
GROUP BY T.Ticket_Type
ORDER BY Average_Delay_Minutes ASC; 


/* --------------------------------------------------------
   ⏱️ Operational Performance
   Average Delay by Route Segment
---------------------------------------------------------*/

SELECT
    (R.Departure_Station + ' to ' + R.Arrival_Destination) AS Route_Description,
    FORMAT(COUNT(*), '#,##0') AS Total_Trips_on_Route,
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
WHERE
    F.delay_minutes > 0 
GROUP BY
    R.Departure_Station, R.Arrival_Destination,
    (R.Departure_Station + ' to ' + R.Arrival_Destination)
ORDER BY Average_Delay_Minutes DESC;


/* --------------------------------------------------------
   💰 Financial & Behavioral
   Correlation: Delay Severity vs. Refund Count
---------------------------------------------------------*/
SELECT
    CASE 
        WHEN F.delay_minutes = 0 THEN '0 - No Delay'
        WHEN F.delay_minutes > 0 AND F.delay_minutes <= 15 THEN '1 - Minor Delay (1-15 min)'
        WHEN F.delay_minutes > 15 THEN '2 - Significant Delay (> 15 min)'
        ELSE '3 - Unknown/N/A' 
    END AS Delay_Severity_Category,
    FORMAT(COUNT(*), '#,##0') AS Total_Trips_in_Category,
        SUM(CASE 
        WHEN F.Refund_Request IS NOT NULL THEN 1 
        ELSE 0 
    END) AS Total_Refunds 
    
FROM Fact_TrainRides AS F
GROUP BY
    CASE 
        WHEN F.delay_minutes = 0 THEN '0 - No Delay'
        WHEN F.delay_minutes > 0 AND F.delay_minutes <= 15 THEN '1 - Minor Delay (1-15 min)'
        WHEN F.delay_minutes > 15 THEN '2 - Significant Delay (> 15 min)'
        ELSE '3 - Unknown/N/A'
    END
ORDER BY Total_Refunds DESC; 


/* --------------------------------------------------------
   ⏱️ Operational Performance
   Volume of Delays by Weather Condition (FINAL SOLUTION)
---------------------------------------------------------*/
SELECT
    S.Reason_for_Delay AS Weather_Impact,
    FORMAT(COUNT(*), '#,##0') AS Total_Delayed_Trips_Count,
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key
WHERE
    F.delay_minutes > 0 
    AND S.Reason_for_Delay IN ('Weather', 'Weather Conditions') 
GROUP BY S.Reason_for_Delay
ORDER BY COUNT(*) DESC; 


/* --------------------------------------------------------
   🛑 Operational Performance:
   Most Common Reasons for Delay and Impact
---------------------------------------------------------*/
SELECT
    S.Reason_for_Delay AS Delay_Reason,
    FORMAT(COUNT(*), '#,##0') AS Frequency_of_Delay_Reason,
    ROUND(SUM(F.delay_minutes), 0) AS Total_Delay_Minutes_Caused
FROM Fact_TrainRides AS F
INNER JOIN Dim_Status AS S
    ON F.Status_Key = S.Status_Key
WHERE
    S.Reason_for_Delay IS NOT NULL 
    AND S.Reason_for_Delay NOT IN ('N/A', 'None', 'No Delay', 'NULL', 'Not Applicable') 
GROUP BY S.Reason_for_Delay
ORDER BY COUNT(*) DESC;

/* --------------------------------------------------------
   📅 Operational Performance:
   Average Delay by Day of the Week
---------------------------------------------------------*/
SELECT
    FORMAT(F.journeydate_Key, 'dddd') AS Day_of_Week,
    FORMAT(COUNT(*), '#,##0') AS Total_Trips,
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
    FROM Fact_TrainRides AS F
GROUP BY FORMAT(F.journeydate_Key, 'dddd')
ORDER BY Average_Delay_Minutes DESC; 


/* --------------------------------------------------------
   ⏱️ Operational Performance:
   Average Delay by Journey Length (Duration)
---------------------------------------------------------*/

SELECT
    CASE 
        WHEN F.journey_duration_mins < 60 THEN '1 - Short Trip (< 60 mins)'
        WHEN F.journey_duration_mins >= 60 AND F.journey_duration_mins <= 180 THEN '2 - Medium Trip (1-3 hours)'
        WHEN F.journey_duration_mins > 180 THEN '3 - Long Trip (> 3 hours)'
        ELSE '4 - Unknown/N/A' 
    END AS Journey_Length_Category,
    
    FORMAT(COUNT(*), '#,##0') AS Total_Trips_Count,
    
    -- حساب متوسط التأخير بالدقائق لكل فئة
    ROUND(AVG(F.delay_minutes), 2) AS Average_Delay_Minutes
    
FROM 
    Fact_TrainRides AS F
WHERE
    F.journey_duration_mins IS NOT NULL AND F.journey_duration_mins > 0
GROUP BY
    CASE 
        WHEN F.journey_duration_mins < 60 THEN '1 - Short Trip (< 60 mins)'
        WHEN F.journey_duration_mins >= 60 AND F.journey_duration_mins <= 180 THEN '2 - Medium Trip (1-3 hours)'
        WHEN F.journey_duration_mins > 180 THEN '3 - Long Trip (> 3 hours)'
        ELSE '4 - Unknown/N/A'
    END
ORDER BY
    Average_Delay_Minutes DESC;


/* --------------------------------------------------------
   💰 Financial & Customer Quality:
   Refund Rate as a Percentage of Total Tickets (Final Corrected)
---------------------------------------------------------*/
SELECT
    FORMAT(SUM(CASE WHEN F.Refund_Request != 'No' THEN 1 ELSE 0 END), '#,##0') AS Total_Tickets_With_Refund_Request, 
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT((CAST(SUM(CASE WHEN F.Refund_Request != 'No' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*))
        , 'P2' 
    ) AS Refund_Rate_Percent
FROM Fact_TrainRides AS F;

/* --------------------------------------------------------
   💰 Financial & Customer Quality:
   Refund Rate Comparison by Ticket Class
---------------------------------------------------------*/
SELECT
    T.Ticket_Type, 
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT(SUM(CASE WHEN F.Refund_Request != 'No' THEN 1 ELSE 0 END), '#,##0') AS Total_Refund_Requests,
    FORMAT((CAST(SUM(CASE WHEN F.Refund_Request != 'No' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*))
        , 'P2' 
    ) AS Refund_Rate_Percent
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
GROUP BY T.Ticket_Type
ORDER BY Refund_Rate_Percent DESC; 


/* --------------------------------------------------------
   💸 Financial & Behavioral:
   Refund Likelihood for Delayed vs. On-Time Trips
---------------------------------------------------------*/
SELECT
    CASE 
        WHEN F.delay_minutes > 0 THEN 'Delayed Trips' 
        ELSE 'On-Time Trips' 
    END AS Trip_Punctuality_Status,
    
    FORMAT(COUNT(*), '#,##0') AS Total_Trips_Count,
    FORMAT(SUM(CASE WHEN F.Refund_Request != 'No' THEN 1 ELSE 0 END), '#,##0') AS Total_Refunds,
    FORMAT((CAST(SUM(CASE WHEN F.Refund_Request != 'No' THEN 1 ELSE 0 END) AS FLOAT) / COUNT(*))
        , 'P2'
    ) AS Refund_Rate_Percent
    
FROM Fact_TrainRides AS F
GROUP BY
    CASE 
        WHEN F.delay_minutes > 0 THEN 'Delayed Trips' 
        ELSE 'On-Time Trips'
    END
ORDER BY Refund_Rate_Percent DESC; 


/* --------------------------------------------------------
   💰 Financial Performance:
   Ticket Class with Highest Total Revenue (FINAL)
---------------------------------------------------------*/
SELECT
    T.Ticket_Type, 
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    ROUND(SUM(F.Price), 2) AS Total_Revenue,
    ROUND(AVG(F.Price), 2) AS Average_Revenue_Per_Ticket
    
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
GROUP BY T.Ticket_Type
ORDER BY Total_Revenue DESC; 


/* --------------------------------------------------------
   💰 Financial Performance:
   Stations with the Highest Total Revenue
---------------------------------------------------------*/
SELECT
    R.Departure_Station AS Station_Name,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    ROUND(SUM(F.Price), 2) AS Total_Revenue,
    ROUND(AVG(F.Price), 2) AS Average_Revenue_Per_Ticket   
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY R.Departure_Station
ORDER BY Total_Revenue DESC; 


/* --------------------------------------------------------
   💰 Financial Performance:
   Daily Total Revenue
---------------------------------------------------------*/
SELECT
    F.journeydate_Key AS Transaction_Date,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT(ROUND(SUM(F.Price), 2), '#,##0.00') AS Daily_Total_Revenue
    FROM Fact_TrainRides AS F
GROUP BY F.journeydate_Key
ORDER BY F.journeydate_Key;


/* --------------------------------------------------------
   💰 Financial Performance:
   Weekly Total Revenue
---------------------------------------------------------*/
SELECT
    DATEPART(yy, F.journeydate_Key) AS Revenue_Year,
    DATEPART(wk, F.journeydate_Key) AS Week_Number,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
     FORMAT(ROUND(SUM(F.Price), 2), '#,##0.00') AS Weekly_Total_Revenue
    FROM Fact_TrainRides AS F
GROUP BY
    DATEPART(yy, F.journeydate_Key),
    DATEPART(wk, F.journeydate_Key)
ORDER BY Revenue_Year, Week_Number;


/* --------------------------------------------------------
   💰 Financial Performance:
   Monthly Total Revenue
---------------------------------------------------------*/
SELECT
    FORMAT(F.journeydate_Key, 'yyyy-MM') AS Revenue_Month,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT(ROUND(SUM(F.Price), 2), '#,##0.00') AS Monthly_Total_Revenue   
FROM Fact_TrainRides AS F
GROUP BY FORMAT(F.journeydate_Key, 'yyyy-MM')
ORDER BY Revenue_Month;


/* --------------------------------------------------------
   💰 Financial Performance:
   Most Profitable Ticket Type (Average Revenue Proxy)
---------------------------------------------------------*/
SELECT
    T.Ticket_Type,
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT(ROUND(SUM(F.Price), 2), '#,##0.00') AS Total_Revenue,
	ROUND(AVG(F.Price), 2) AS Average_Revenue_Per_Ticket   
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
GROUP BY T.Ticket_Type
ORDER BY Average_Revenue_Per_Ticket DESC; 


/* --------------------------------------------------------
   💰 Financial Performance:
   Impact of Discount Cards on Revenue
---------------------------------------------------------*/
SELECT
    FORMAT(ROUND(SUM(F.Price_Original), 2), '#,##0.00') AS Total_Potential_Revenue, 
    FORMAT(ROUND(SUM(F.Price), 2), '#,##0.00') AS Total_Discount_Given, 
    FORMAT(ROUND(SUM(F.Price_Original) - SUM(F.Price), 2), '#,##0.00') AS Total_Actual_Revenue, 
    FORMAT((SUM(F.Price_Original) - SUM(F.Price)) / SUM(F.Price_Original), 'P2') AS Revenue_Loss_Rate_Percent,
    FORMAT(SUM(F.Price) / SUM(F.Price_Original),'P2' ) AS Revenue_Retention_Rate_Percent
FROM Fact_TrainRides AS F
WHERE F.Price < F.Price_Original;


/* --------------------------------------------------------
   💰 Financial Performance:
   Total Revenue Impacted by Refund Requests
---------------------------------------------------------*/
SELECT FORMAT(ROUND(SUM(CASE WHEN F.Refund_Request != 'No' THEN F.Price ELSE 0 END), 2) , '#,##0.00'
    ) AS Total_Revenue_Refunded,
        FORMAT(ROUND(SUM(F.Price), 2) , '#,##0.00'
    ) AS Grand_Total_Revenue,
    FORMAT((SUM(CASE WHEN F.Refund_Request != 'No' THEN F.Price ELSE 0 END) / SUM(F.Price))
        , 'P2' 
    ) AS Refunded_Revenue_Rate_Percent
    FROM Fact_TrainRides AS F;


	/* --------------------------------------------------------
   💰 Financial Performance:
   Average Revenue Per Trip/Transaction
---------------------------------------------------------*/
SELECT
    FORMAT(COUNT(*), '#,##0') AS Total_Trips_Count,
    FORMAT(ROUND(SUM(F.Price), 2), '#,##0.00') AS Total_Revenue,
    ROUND(AVG(F.Price), 2) AS Average_Revenue_Per_Trip  
FROM Fact_TrainRides AS F;


/* --------------------------------------------------------
   💰 Financial Performance:
   Average Ticket Price by Ticket Class
---------------------------------------------------------*/
SELECT
    T.Ticket_Type,  
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    ROUND(AVG(F.Price), 2) AS Average_Ticket_Price   
FROM Fact_TrainRides AS F
INNER JOIN Dim_Ticket AS T
    ON F.Ticket_Key = T.Ticket_Key
GROUP BY T.Ticket_Type
ORDER BY Average_Ticket_Price DESC; 


/* --------------------------------------------------------
   📈 Financial Performance:
   Revenue Trend Analysis by Month (Seasonality)
---------------------------------------------------------*/
SELECT
    FORMAT(F.journeydate_Key, 'yyyy-MM') AS Revenue_Month, 
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT(ROUND(SUM(F.Price_Original), 2), '#,##0.00') AS Monthly_Total_Revenue  
FROM Fact_TrainRides AS F
GROUP BY FORMAT(F.journeydate_Key, 'yyyy-MM')
ORDER BY Revenue_Month; 


/* --------------------------------------------------------
   💰 Financial Performance:
   Stations with Highest Average Revenue Per Trip
---------------------------------------------------------*/
SELECT
    R.Departure_Station AS Station_Name,
    FORMAT(COUNT(*), '#,##0') AS Total_Trips_Count,
    FORMAT(ROUND(SUM(F.Price_Original), 2), '#,##0.00') AS Total_Revenue,
    ROUND(AVG(F.Price_Original), 2) AS Average_Revenue_Per_Trip
FROM Fact_TrainRides AS F
INNER JOIN Dim_Route AS R
    ON F.Route_Key = R.Route_Key
GROUP BY R.Departure_Station
ORDER BY Average_Revenue_Per_Trip DESC;


/* --------------------------------------------------------
   💸 Financial & Operational:
   Revenue Loss Due to Delays (Refund Impact)
---------------------------------------------------------*/
SELECT
    CASE 
        WHEN F.delay_minutes > 0 THEN '1 - Delayed Trips' 
        ELSE '2 - On-Time Trips'
    END AS Trip_Punctuality_Status,
    
    FORMAT(COUNT(*), '#,##0') AS Total_Tickets_Sold,
    FORMAT(ROUND(SUM(F.Price_Original), 2), '#,##0.00') AS Total_Revenue,
    
    FORMAT(ROUND(SUM(CASE WHEN F.Refund_Request != 'No' THEN F.Price_Original ELSE 0 END), 2), '#,##0.00'
    ) AS Total_Refunded_Revenue,
    FORMAT((SUM(CASE WHEN F.Refund_Request != 'No' THEN F.Price_Original ELSE 0 END) / SUM(F.Price_Original))
        , 'P2' 
    ) AS Refunded_Revenue_Rate_Percent 
FROM Fact_TrainRides AS F
GROUP BY
    CASE 
        WHEN F.delay_minutes > 0 THEN '1 - Delayed Trips' 
        ELSE '2 - On-Time Trips'
    END
ORDER BY Refunded_Revenue_Rate_Percent DESC;