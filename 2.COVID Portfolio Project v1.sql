SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

SELECT *
FROM PortfolioProject..CovidVaccination
ORDER BY 3,4

--Select the data that we are using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

--Looking at total cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in Colombia
SELECT location, (TRY_CONVERT(date, date, 103)) as date, total_cases, total_deaths, (CONVERT(float,total_deaths)/CONVERT(float,total_cases))*100 as DeathsPercentagee
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%colombia%'
ORDER BY 1,2

--Looking at the total cases vs population
--Shows what percentage of population got COVID in Colombia
SELECT location, date, (TRY_CONVERT(date, date, 103)) as date2, total_cases, population, 
(CONVERT(float,total_cases)/CONVERT(float,population))*100 as CasesPercentage
FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%colombia%'
ORDER BY 1,2

--looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount,
MAX((CONVERT(float,total_cases)/ NULLIF(CONVERT(float,population),0))*100)as PercenPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%colombia%'
GROUP BY location, population
ORDER BY PercenPopulationInfected desc


--Showing Countries with the highest Death count per population
UPDATE CovidDeaths
SET continent = NULL 
WHERE continent = ''
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%colombia%'
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


--Lets break things down by continent by highest death counts
UPDATE CovidDeaths
SET continent = NULL 
WHERE continent = ''
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%colombia%'
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc


--GLOBAL NUMBERS, cases, deaths and % deaths across the world by day
SELECT TRY_CONVERT(date,date,103)as date, SUM(cast(new_cases as int)) as total_cases , SUM(CAST(new_deaths as int)) as total_deaths, 
(SUM(CAST(new_deaths as float))/    NULLIF (SUM(CAST(new_cases as float)),0)   )*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%colombia%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--Total cases in the world without date (just remove date del SELECT y el group by)
SELECT SUM(cast(new_cases as int)) as total_cases , SUM(CAST(new_deaths as int)) as total_deaths, 
(SUM(CAST(new_deaths as float))/    NULLIF (SUM(CAST(new_cases as float)),0)   )*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE location LIKE '%colombia%'
WHERE continent is not null
ORDER BY 1,2


--Looking at total population vs vaccionation 
UPDATE CovidVaccination
SET new_vaccinations = NULL
WHERE new_vaccinations = ''
SELECT dea.continent, dea.location, (TRY_CONVERT(date, dea.date, 103)) as date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(date, dea.date, 103))
as RollingPeopleVaccionated
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccination as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


--USE CTE
UPDATE CovidVaccination
SET new_vaccinations = NULL
WHERE new_vaccinations = '';
With PopvsVac(Continent, Location, date, population, new_vaccinations, RollingPeopleVaccionated)
as
(
SELECT dea.continent, dea.location, (TRY_CONVERT(date, dea.date, 103)) as date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(date, dea.date, 103))
as RollingPeopleVaccionated
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccination as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *,(cast(RollingPeopleVaccionated as float)/CONVERT(FLOAT,population))*100 as PopvsVac
FROM PopvsVac


--TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(225),
date date,
population int,
new_Vaccinations int,
RollingPeopleVaccinated int
)
insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, (TRY_CONVERT(date, dea.date, 103)) as date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(date, dea.date, 103))
as RollingPeopleVaccionated
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccination as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


--CREATING A VIEW TO StORE DATA FOR LATER VISUALIZATIONS
CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, (TRY_CONVERT(date, dea.date, 103)) as date, dea.population, vac.new_vaccinations,
SUM(cast(new_vaccinations as int)) OVER (Partition by dea.location order by dea.location, TRY_CONVERT(date, dea.date, 103))
as RollingPeopleVaccionated
FROM PortfolioProject..CovidDeaths as dea
JOIN PortfolioProject..CovidVaccination as vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
SELECT*
FROM PercentPopulationVaccinated

