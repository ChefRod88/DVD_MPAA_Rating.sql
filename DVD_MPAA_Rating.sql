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
