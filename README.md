# DVD_MPAA_Rating.sql
This script sets up the detailed and summary tables for your DVD rental business reporting system, defines functions and triggers for transforming and updating data, and provides procedures for refreshing data.

create sql file: How many DVDs do we have for the most common MPAA rating category G?
 
1. My project focuses on developing a reporting system tailored for DVD rental businesses, with a specific emphasis on analyzing DVD inventory based on MPAA ratings.
 
2. The primary business question we aim to address is: What is the quantity of DVDs available in the most common MPAA rating category, G? By answering this question, we provide valuable insights into the inventory composition and customer preferences related to family-friendly content.
 
3. DVD businesses can benefit from my reports in the following ways:
   - **Customer Satisfaction**: By ensuring a sufficient quantity of DVDs with the G rating, businesses can cater to the needs of families and individuals seeking wholesome entertainment options. This can lead to increased customer satisfaction and loyalty.
   - **Revenue Generation**: Understanding the demand for G-rated DVDs allows businesses to optimize their inventory management strategies. By stocking popular titles in this category, businesses can attract more customers and generate higher rental revenues.
   - **Operational Efficiency**: Our reports enable businesses to monitor inventory levels accurately and make informed decisions about stocking and replenishment. This can help reduce excess inventory costs and minimize instances of stockouts, thereby improving operational efficiency.
 
In summary, my reports provide DVD businesses with actionable insights to meet customer demands, increase revenue, and operate more efficiently, particularly regarding the availability of DVDs in the G rating category.
 
 
A1. For the detailed table section of the report, specific fields such as dvd_title, release_year, actor_id, first_name,last_name, lenghth, date and rating would be included. These fields provide comprehensive information about each DVD, aiding enthusiasts, retailers, or collectors in making informed decisions about purchases or rentals. The summary table section, on the other hand, would contain aggregated data such as total_number_dvds and  most_common_ratings, offering high-level insights into overall trends in DVD consumption.
 
A2. Data fields used for the report encompass various types such as string, date, and numeric. String data types would be applicable for dvd_title,first_name,last_name , and rating, while date fields would be used for release dates. Numeric data types would likely be utilized for duration and ratings, allowing for numerical analysis and aggregation.
 
A3. The necessary data for the detailed table section can be extracted from the "Film" table and "Actor" table, which likely contains comprehensive information about each DVD, including title, release date, genre, director, actors, duration, and ratings. For the summary table section, data from the "Inventory" and "Film" table could be utilized to provide insights into rental statistics, which can then be aggregated to identify trends.
 
A4. In the detailed table section, a custom transformation might be applied to the "rating" field.  could be translated into descriptive terms using Motion Picture Content Rating System using a user-defined function for easier interpretation. This transformation enhances the readability and usability of the data for stakeholders.
 
A5. The detailed table section serves specific needs of stakeholders who require detailed information about individual DVDs, facilitating informed decisions about purchases or rentals. On the other hand, the summary table section offers broader insights into overall trends and patterns in DVD consumption, catering to stakeholders interested in high-level analysis and decision-making.
 
A6. To remain relevant to stakeholders, the report should be refreshed periodically. Depending on the industry dynamics and business requirements, refresh frequency could range from weekly to monthly updates. For instance, a DVD rental service might require more frequent updates to adapt to changing viewer preferences, while a DVD retailer might suffice with monthly updates to track broader trends. Regular refreshes ensure stakeholders have access to up-to-date information for making informed decisions.

 
-- Create a detailed movie table to store DVD information
CREATE TABLE DetailedMovieTable (
    film_id INT PRIMARY KEY,
    title VARCHAR(255),
    release_year INT,
    actor_id INT,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    length_minutes SMALLINT,
    rating VARCHAR(5)
);

-- Insert data into DetailedMovieTable
INSERT INTO DetailedMovieTable(film_id, title, release_year, actor_id, first_name, last_name, length_minutes, rating)
SELECT film.film_id, film.title, film.release_year, actor.actor_id, actor.first_name, actor.last_name, film.length, film.rating
FROM actor
JOIN film ON actor.actor_id = film.film_id;

-- Create a summary table for aggregated data
CREATE TABLE SummaryTable (
    total_dvds INT,
    most_common_rating VARCHAR(5)
);

-- Insert summary data
INSERT INTO SummaryTable (total_dvds, most_common_rating)
SELECT
    COUNT(*) AS total_dvds,
    rating AS most_common_rating
FROM DetailedMovieTable
GROUP BY rating
ORDER BY COUNT(*) DESC
LIMIT 1;

-- Function to translate MPAA rating to descriptions
CREATE OR REPLACE FUNCTION TranslateRatingDescriptionMPAA(rating VARCHAR(5))
RETURNS VARCHAR(100) AS $$
DECLARE
    rating_description VARCHAR(100);
BEGIN
    CASE rating
        WHEN 'NC-17' THEN rating_description := 'No one 17 and under admitted';
        WHEN 'R' THEN rating_description := 'Restricted. May be unsuitable for children under 17';
        WHEN 'PG-13' THEN rating_description := 'Parents strongly cautioned. Some material may be inappropriate for children under 13';
        WHEN 'PG' THEN rating_description := 'Parental guidance suggested. Some material may not be suitable for children';
        WHEN 'G' THEN rating_description := 'General audiences. All ages admitted';
        ELSE rating_description := 'Unknown';
    END CASE;
    RETURN rating_description;
END;
$$ LANGUAGE plpgsql;

-- Update rating column with translated descriptions
UPDATE DetailedMovieTable
SET rating = TranslateRatingDescriptionMPAA(rating);

-- Trigger to update summary table when new data is added to DetailedMovieTable
CREATE OR REPLACE FUNCTION UpdateSummaryTable()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE SummaryTable
    SET total_dvds = (SELECT COUNT(*) FROM DetailedMovieTable),
        most_common_rating = (SELECT rating FROM (SELECT rating, COUNT(*) AS rating_count FROM DetailedMovieTable GROUP BY rating ORDER BY rating_count DESC LIMIT 1) AS subquery);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER UpdateSummaryOnInsert
AFTER INSERT ON DetailedMovieTable
FOR EACH ROW
EXECUTE FUNCTION UpdateSummaryTable();

-- Procedure to refresh data in DetailedMovieTable and SummaryTable
CREATE OR REPLACE PROCEDURE RefreshTables()
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM DetailedMovieTable;
    DELETE FROM SummaryTable;
END;
$$;

-- Procedure to extract raw data
CREATE OR REPLACE PROCEDURE RawDataExtraction()
LANGUAGE plpgsql
AS $$
BEGIN
    -- Refresh DetailedMovieTable
    INSERT INTO DetailedMovieTable(film_id, title, release_year, actor_id, first_name, last_name, length_minutes, rating)
    SELECT film.film_id, film.title, film.release_year, actor.actor_id, actor.first_name, actor.last_name, film.length, film.rating
    FROM actor
    JOIN film ON actor.actor_id = film.film_id;

    -- Refresh SummaryTable
    INSERT INTO SummaryTable (total_dvds, most_common_rating)
    SELECT COUNT(*) AS total_dvds, rating AS most_common_rating
    FROM DetailedMovieTable
    GROUP BY rating
    ORDER BY COUNT(*) DESC
    LIMIT 1;
END;
$$;

-- Call procedures to refresh tables and extract raw data
CALL RefreshTables();
CALL RawDataExtraction();

-- Sample queries to view data
SELECT * FROM public.detailedmovietable;
SELECT * FROM public.summarytable;
