-- DATA ANALYST PORTFOLIO PROJECT 1
-- CREATE FIRST DATA TABLE IN EXCEL
-- CREATE SECOND DATA TABLE IN EXCEL
-- CREATE NEW DATABASE AS PortfolioProject1
-- IMPORT DATA FROM EXCEL INTO SQL SERVER

SELECT *
FROM PortfolioProject1..CovidDataDeaths
ORDER BY 3, 4

SELECT *
FROM PortfolioProject1..CovidDataVaccinations
ORDER BY 3, 4

--change data type (change to int or float for numbers)

ALTER TABLE CovidDataDeaths
ALTER COLUMN total_cases float

ALTER TABLE CovidDataDeaths
ALTER COLUMN total_deaths float

--select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDataDeaths
ORDER BY 1, 2

--looking at total cases vs total deaths
--shows likelihood of dying

SELECT location, date, total_cases, total_deaths,
(total_deaths/total_cases)*100 AS DeathsPercentage
FROM PortfolioProject1..CovidDataDeaths
WHERE location like '%states%'
ORDER BY 1, 2

--looking at total cases vs population
--shows what percentage of population got covid

SELECT location, date, population, total_cases,
(total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject1..CovidDataDeaths
--WHERE location like '%states%'
ORDER BY 1, 2

--looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject1..CovidDataDeaths
GROUP BY location, population
ORDER BY 4 DESC

--showing countries with highest death count per population
--use cast to change data type to use aggregated function like max, min, avg, sum

SELECT location, population, MAX(CAST(total_deaths AS int)) AS TotalDeathCount,
MAX((total_deaths/population))*100 AS PercentagePopulationDeath
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

SELECT *
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NULL
ORDER BY 3, 4

--let's break things down by continent

SELECT location, population, MAX(CAST(total_deaths AS int)) AS TotalDeathCount,
MAX((total_deaths/population))*100 AS PercentagePopulationDeaths
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NULL
GROUP BY location, population
ORDER BY 4 DESC

--showing continent with highest death count per population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY 2 DESC

ALTER TABLE CovidDataDeaths
ALTER COLUMN new_cases float

ALTER TABLE CovidDataDeaths
ALTER COLUMN new_deaths int

--global numbers of covid cases
--group by is used with aggregated function
--NULLIF, ISNULL function to avoid divide by zero error

SELECT date, SUM(new_cases) AS GlobalDailyCases,
SUM(new_deaths) AS GlobalDailyDeaths,
--SUM(new_deaths)/SUM(new_cases) * 100 AS DeathPercentage --> error divide by 0
ISNULL(SUM(new_deaths)/NULLIF(SUM(new_cases), 0), 0)*100 AS DeathPercentage
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1

--divide by zero error with case statement

SELECT date, SUM(new_cases) AS GlobalDailyCases,
SUM(new_deaths) AS GlobalDailyDeaths,
CASE
	WHEN SUM(new_cases) = 0 THEN ''
	ELSE SUM(new_deaths)/SUM(new_cases)*100
END AS DeathPercentage
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1

--remove date from above

SELECT SUM(new_cases) AS GlobalDailyCases, SUM(new_deaths) AS GlobalDailyDeaths,
CASE
	WHEN SUM(new_cases) = 0 THEN NULL
	ELSE SUM(new_deaths)/SUM(new_cases)*100
END AS DeathPercentage
FROM PortfolioProject1..CovidDataDeaths
WHERE continent is NOT NULL
GROUP BY date
ORDER BY 1

--looking into vacciantion table and join with death table

SELECT *
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
ORDER BY 3, 4

--looking at total populations vs vaccinations

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL
ORDER BY 2, 3

ALTER TABLE CovidDataVaccinations
ALTER COLUMN new_vaccinations int

--rolling count (daily accumalation study)
--use convert to change data type for aggregated function

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(bigint, Vac.new_vaccinations))
OVER (PARTITION BY Dea.location) --only SUM, not rolling count
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL
ORDER BY 2, 3

--further add order by after partition by
--change position of order by

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(bigint, Vac.new_vaccinations))
OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL
--ORDER BY 2, 3

--MAX(RollingPeopleVaccinated) vs population --> error
--RollingPeopleVaccinated is not recognized

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(bigint, Vac.new_vaccinations))
OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
AS RollingPeopleVaccinated,
(RollingPeopleVaccinated/population)*100 --> not recognized
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL

--solution by CTE, temp table
--option 1 by CTE, number of column must match

WITH PopvsVac (continent, location, date, population, new_vaccinations,
RollingPeopleVaccinated) AS
(
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(bigint, Vac.new_vaccinations))
OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentPeopleVaccinated
FROM PopvsVac
ORDER BY 2, 3

--option 2 by temp table

DROP TABLE IF EXISTS #Temp_PercentPopulationVaccinated
CREATE TABLE #Temp_PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #Temp_PercentPopulationVaccinated
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vac.new_vaccinations,
SUM(CONVERT(bigint, Vac.new_vaccinations))
OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #Temp_PercentPopulationVaccinated
ORDER BY 2, 3

--creating view to store data for later visualizations
--can be connected to Tableau for visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT Dea.continent, Dea.location, Dea.date, Dea.population,
Vac.new_vaccinations,
SUM(CONVERT(bigint, Vac.new_vaccinations)) OVER
(PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
AS RollingPeopleVaccinated
FROM PortfolioProject1..CovidDataDeaths AS Dea
JOIN PortfolioProject1..CovidDataVaccinations AS Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent is NOT NULL

SELECT *
FROM PercentPopulationVaccinated
ORDER BY 2, 3