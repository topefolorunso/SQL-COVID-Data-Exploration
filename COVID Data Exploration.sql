/*
EXPLORING COVID DEATH DATA
*/

SELECT *
FROM PortfolioDB..COVIDDeathData
WHERE continent IS NOT NULL
ORDER BY location, date


-- Retrieve death data to be used 
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioDB..COVIDDeathData
WHERE continent IS NOT NULL
ORDER BY location, date


-- exploring total cases v. total deaths for Nigeria
-- this shows the chance of dying after contracting the virus
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percent_death
FROM PortfolioDB..COVIDDeathData
WHERE location = 'Nigeria'
ORDER BY location, date


-- exploring total cases v. population for Nigeria
-- shows the percentage of population have covid, and chance of contracting the virus
SELECT location, date, total_cases, population, (total_cases/population)*100 as percent_cases
FROM PortfolioDB..COVIDDeathData
WHERE location = 'Nigeria'
ORDER BY location, date

-- exploring total cases v. population
-- shows countries with the highest infection rate
SELECT location, population, MAX(total_cases) as total_infection, (MAX(total_cases)/population*100) as percent_cases
FROM PortfolioDB..COVIDDeathData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_cases DESC


--Shows countries with highest death count, death rate
SELECT location, population, MAX(CAST(total_deaths AS int)) as total_death, (MAX(CAST(total_deaths AS int))/population)*100 as percent_death
FROM PortfolioDB..COVIDDeathData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_death DESC


--Shows continents with highest death count, death rate
SELECT continent, MAX(CAST(total_deaths AS int)) as total_death
FROM PortfolioDB..COVIDDeathData
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death DESC
--more accurate
SELECT location, population, MAX(CAST(total_deaths AS int)) as total_death, (MAX(CAST(total_deaths AS int))/population)*100 as percent_death
FROM PortfolioDB..COVIDDeathData
WHERE continent IS NULL
GROUP BY location, population
ORDER BY total_death DESC


--Global total cases vs total deaths per day
SELECT date, SUM(total_cases) AS total_cases, SUM(new_cases) AS daily_cases, SUM(CAST(total_deaths AS int)) as total_deaths, (SUM(CAST(total_deaths AS int))/SUM(total_cases))*100 as percent_death
FROM PortfolioDB..COVIDDeathData
WHERE continent is not null
GROUP BY date
ORDER BY date

SELECT SUM(new_cases) AS total_cases, SUM(CAST(total_deaths AS int)) as total_deaths, (SUM(CAST(total_deaths AS int))/SUM(total_cases))*100 as percent_death
FROM PortfolioDB..COVIDDeathData
WHERE continent is not null
ORDER BY total_cases


/*
EXPLORING COVID VACCINATION DATA
*/

SELECT *
FROM PortfolioDB..COVIDVaxData
WHERE continent IS NOT NULL
ORDER BY location, date


--Join Death Data with Vaccination Data on Location and Date
SELECT *
FROM PortfolioDB..COVIDDeathData AS Death
JOIN PortfolioDB..COVIDVaxData AS Vax
ON Death.location = Vax.location
AND Death.date = Vax.date


-- Show Total population vs Vaccinations
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations
FROM PortfolioDB..COVIDDeathData AS Death
JOIN PortfolioDB..COVIDVaxData AS Vax
ON Death.location = Vax.location
AND Death.date = Vax.date
WHERE Death.continent is not null
ORDER BY location, date


--get rolling vaccinations count, rolling percent vaccinated

--using CTE
WITH RollingVax (continent, location, date, population, daily_vax_count, rolling_vax_count) AS (
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations,
SUM(CONVERT(bigint,Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.date) AS rolling_vax_count
FROM PortfolioDB..COVIDDeathData AS Death
JOIN PortfolioDB..COVIDVaxData AS Vax
ON Death.location = Vax.location
AND Death.date = Vax.date
WHERE Death.continent is not null

)

SELECT *, (rolling_vax_count/population)/100 as rolling_vax_percent
FROM RollingVax
ORDER BY location, date


--using TEMP Table
DROP TABLE IF EXISTS #RollingVax

CREATE TABLE #RollingVax (continent nvarchar(255), location nvarchar(255), date datetime, population numeric, daily_vax_count numeric, rolling_vax_count numeric)

INSERT INTO #RollingVax

SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations,
SUM(CONVERT(bigint,Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.date) AS rolling_vax_count
FROM PortfolioDB..COVIDDeathData AS Death
JOIN PortfolioDB..COVIDVaxData AS Vax
ON Death.location = Vax.location
AND Death.date = Vax.date
WHERE Death.continent is not null

SELECT *, (rolling_vax_count/population)/100 as rolling_vax_percent
FROM #RollingVax
ORDER BY location, date


--Create View to store data for visualization
CREATE VIEW PercentVax AS
SELECT Death.continent, Death.location, Death.date, Death.population, Vax.new_vaccinations,
SUM(CONVERT(bigint,Vax.new_vaccinations)) OVER (PARTITION BY Death.location ORDER BY Death.date) AS rolling_vax_count
FROM PortfolioDB..COVIDDeathData AS Death
JOIN PortfolioDB..COVIDVaxData AS Vax
ON Death.location = Vax.location
AND Death.date = Vax.date
WHERE Death.continent is not null

SELECT *, (rolling_vax_count/population)/100 as rolling_vax_percent
FROM PortfolioDB..PercentVax
ORDER BY location, date