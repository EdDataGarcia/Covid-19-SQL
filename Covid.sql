/* 
Covid-19 Data Exploration Project using SQL Server and Tableau Desktop
Ed Garcia
August 18, 2021
*/

--Check import of CovidDeaths table
SELECT	*
FROM	PortfolioProject..CovidDeaths
WHERE	continent IS NOT NULL 
ORDER BY 3,4 --order by country and date

--Check import of CovidVaccinations table
SELECT	*
FROM	PortfolioProject..CovidVaccinations
ORDER BY 3,4

--Explore CovidDeaths table

--Select relevant columns for exploration 
SELECT	location, date, total_cases, new_cases, total_deaths, population 
FROM	PortfolioProject..CovidDeaths
ORDER BY 1,2 --order by country and date



--How likely is death if you contract Covid (by country)?

--Total Cases vs Total Deaths (I selected a few countries per query)
SELECT	location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM	PortfolioProject..CovidDeaths
--WHERE	location = 'United States' 
--WHERE	location = 'China'
--WHERE	location = 'South Africa'
ORDER BY 1,2


--EXPLORATION BY COUNTRY
--What % of population has been infected with Covid (by country)?
--Total Cases vs Population (I selected some different countries)
SELECT	location, date, population, total_cases, (total_cases / population) * 100 AS PercentagePopulationInfected
FROM	PortfolioProject..CovidDeaths
--WHERE	location = 'United States' 
--WHERE	location = 'Indonesia'
--WHERE	location = 'United Kingdom'
ORDER BY 1,2

--Countries with Highest Infection Rate compared to Population (TABLEAU VIZ 3)
SELECT	location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentagePopulationInfected
FROM	PortfolioProject..CovidDeaths
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

--Countries with Highest Infection Rate compared to Population by Date (TABLEAU VIZ 4)
SELECT	location, population, date, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentagePopulationInfected
FROM	PortfolioProject..CovidDeaths
GROUP BY location, population, date
ORDER BY PercentagePopulationInfected DESC

--Countries with Highest Death Count per Population
SELECT	location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM	PortfolioProject..CovidDeaths
WHERE	continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC



--EXPLORATION BY CONTINENT
--Continents with highest death count per population (TABLEAU VIZ 2)
SELECT	location, SUM(CAST(new_deaths AS int)) AS TotalDeathCount
FROM	PortfolioProject..CovidDeaths
WHERE	continent IS NULL
	AND	location NOT IN ('European Union', --this is included in Europe count and isn't a continent
							'International', --very little data in this cateogry and isn't a continent
									'World') --this is an aggregate of the whole world and isn't a continent
GROUP BY location
ORDER BY TotalDeathCount DESC



--GLOBAL NUMBERS BY DATE 
SELECT	date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathPercentage
FROM	PortfolioProject..CovidDeaths
WHERE	continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

--GLOBAL NUMBERS TOTAL (TABLEAU VIZ 1)
SELECT	SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int)) / SUM(new_cases) * 100 AS DeathPercentage
FROM	PortfolioProject..CovidDeaths
WHERE	continent IS NOT NULL
ORDER BY 1,2



--Explore CovidVaccinations table

--Total Population vs Rolling Count of Population with at least one Vaccinations
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCountofVaccinations
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1,2,3

--Find the Percent of Population that is Fully Vaccinated (TABLEAU VIZ 5)
SELECT	vac.location, MAX(people_fully_vaccinated) AS people_fully_vaccinated, MAX(population) AS population, (MAX(people_fully_vaccinated) / MAX(population)) * 100 AS percent_fully_vaccinated  
FROM	PortfolioProject..CovidVaccinations vac
JOIN	PortfolioProject..CovidDeaths dea
	ON	vac.location = dea.location
--WHERE	vac.location = 'United States'
GROUP BY vac.location
ORDER BY percent_fully_vaccinated DESC

--Option 1: Utilize a Common Table Expression with the Previous Query
WITH	PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingCountofVaccinations) 
AS
(
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCountofVaccinations
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT	*, (RollingCountofVaccinations / Population) * 100 AS PercentofPopulationVaccinated
FROM	PopvsVac
WHERE	Location = 'United States'
ORDER BY 2,3

--Option 1: This is how to insert this as an Initial SQL in Tableau
WITH	PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingCountofVaccinations) 
AS
(
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCountofVaccinations
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT	Continent, Location, Date, Population, new_vaccinations, RollingCountofVaccinations
INTO	#PercentofPopulationVaccinated
FROM	PopvsVac
--And then create a Custom SQL Query that selects from the temp table you inserted the records into
SELECT	*, (RollingCountofVaccinations / Population) * 100 AS PercentofPopulationVaccinated
FROM	#PercentofPopulationVaccinated

--Option 2: Utilize a Temporary Table with the Previous Query
DROP TABLE IF EXISTS #PercentofPopulationVaccinated
CREATE TABLE	#PercentofPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingCountofVaccinations numeric
)
INSERT INTO	#PercentofPopulationVaccinated
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCountofVaccinations
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent IS NOT NULL
SELECT	*, (RollingCountofVaccinations / Population) * 100 AS PercentofPopulationVaccinated
FROM	#PercentofPopulationVaccinated
ORDER BY 2,3
GO



--Create a View to store data for future visualizations
CREATE VIEW PercentofPopulationVaccinated 
AS
SELECT	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingCountofVaccinations
FROM	PortfolioProject..CovidDeaths dea
JOIN	PortfolioProject..CovidVaccinations vac
	ON	dea.location = vac.location
	AND	dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT	*
FROM	PercentofPopulationVaccinated