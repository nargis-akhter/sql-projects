/* COVID-19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

USE portfolioproject;

SELECT 
    *
FROM
    covid_deaths;
    
    
-- Select data that we are going to be starting with
SELECT 
    location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    covid_deaths;
    

-- Total Cases VS Total Deaths
-- Shows likelihood of dying if you contracted covid in a country
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_cases / total_deaths) * 100 AS death_percentage
FROM
    covid_deaths
WHERE
	continent IS NOT NULL;
    

-- Total Cases VS Population
-- Shows what percentage of population infected with Covid
SELECT 
    location,
    date,
    population,
    total_cases,
    (total_cases / population) * 100 AS percent_population_infected
FROM
    covid_deaths;
    

-- Countries with Highest Infection Rate compared to Population
SELECT 
    location,
    population,
    MAX(total_cases) AS highest_infection_count,
    MAX((total_cases / population) * 100) AS percent_population_infected
FROM
    covid_deaths
GROUP BY 
	location, population
ORDER BY 
	percent_population_infected DESC;


-- Countries with Highest Death Count per Population
SELECT 
    location, 
    MAX(total_deaths) AS total_death_count
FROM
    covid_deaths
GROUP BY 
	location
ORDER BY 
	total_death_count DESC;


-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the Highest Death Count per Population
SELECT 
	continent,
    MAX(total_deaths) AS total_death_count
FROM 
	covid_deaths
GROUP BY 
	continent
ORDER BY 
	total_death_count DESC;


-- GLOBAL NUMBERS
SELECT 
	SUM(new_cases) as total_cases, 
    SUM(new_deaths) as total_deaths, 
    SUM(new_deaths) / SUM(new_cases)*100 as death_percentage
FROM 
	covid_deaths
WHERE 
	continent IS NOT NULL;
    
    
-- Total Population VS Vaccinations
-- Shows Percentage of Population that has received at least one Covid Vaccine
SELECT 
	dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations_smoothed,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
	covid_deaths dea
JOIN 
	covid_vaccinations vac
ON 
	dea.location = vac.location
AND 
	dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL;
    

-- Using CTE to perform calculation on Partition By in previous query
WITH pop_vs_vac (continent, location, date, population, new_Vaccinations_smoothed, rolling_people_vaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations_smoothed,
        SUM(vac.new_vaccinations_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
    FROM covid_deaths dea
    JOIN covid_vaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL 
)
SELECT *, (rolling_people_vaccinated * 100 / population) AS vaccination_percentage
FROM pop_vs_vac;


-- Using Temp Table to perform calculation on Partition By in previous query
DROP TABLE IF EXISTS percent_population_vaccinated;
CREATE TABLE percent_population_vaccinated (
	continent VARCHAR(255),
	location VARCHAR(255),
	date DATE,
	population INT,
	new_vaccinations_smoothed INT,
	rolling_people_vaccinated INT
);

INSERT INTO percent_population_vaccinated
SELECT 
	dea.continent, 
	dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations_smoothed, 
    SUM(vac.new_vaccinations_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM 
	covid_deaths dea
JOIN 
	covid_vaccinations vac
ON 
	dea.location = vac.location
AND 
	dea.date = vac.date;

SELECT *, 
	(rolling_people_vaccinated/population) * 100
FROM 
	percent_population_vaccinated;


-- Creating View to store data for later visualizations
Create View percent_population_vaccinated AS
SELECT 
	dea.continent, 
	dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations_smoothed,
	SUM(vac.new_vaccinations_smoothed) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated,
    (rolling_people_vaccinated/population) * 100
FROM 
	covid_deaths dea
JOIN 
	covid_vaccinations vac
ON 
	dea.location = vac.location
AND 
	dea.date = vac.date
WHERE 
	dea.continent IS NOT NULL; 


