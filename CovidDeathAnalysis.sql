SELECT *
FROM CovidDeathAnalysis.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,5

--Select data to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeathAnalysis..CovidDeaths
ORDER BY 1, 2


-- Looking at total cases vs total deaths (percentage)
-- Likelihood of dying if conracted COVID by Location

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM CovidDeathAnalysis..CovidDeaths
ORDER BY 1, 2


--Looking at total cases vs population
-- Percentage of Population contracted COVID

SELECT location, date, population, total_cases, (total_cases/population)*100 as contract_percentage
FROM CovidDeathAnalysis..CovidDeaths
WHERE location like 'germany'
ORDER BY 1, 2


-- Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 as population_contract_percentage
FROM CovidDeathAnalysis..CovidDeaths
--WHERE location like 'germany'
GROUP BY population, location
ORDER BY population_contract_percentage desc


-- Looking at Countries with Highest Death Count per Population

SELECT location, population, MAX(cast(total_deaths as bigint)) as highest_death_count
FROM CovidDeathAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY population, location
ORDER BY highest_death_count desc



-- Analyze by Continent
-- Looking at Continents with the highest Death counts per population

SELECT continent, MAX(cast(total_deaths as bigint)) as highest_death_count
FROM CovidDeathAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY highest_death_count desc


-- Analyze Globally

SELECT date, SUM(new_cases) as global_cases, SUM(cast(new_deaths as bigint)) as global_deaths, (SUM(cast(new_deaths as bigint))/SUM(new_cases))*100 as global_death_percentage
FROM CovidDeathAnalysis..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) as global_cases, SUM(cast(new_deaths as bigint)) as global_deaths, (SUM(cast(new_deaths as bigint))/SUM(new_cases))*100 as global_death_percentage
FROM CovidDeathAnalysis..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


SELECT *
FROM CovidDeathAnalysis.dbo.CovidVaccinations
ORDER BY 3,5


-- Joining two tables

SELECT *
FROM CovidDeathAnalysis..CovidDeaths death
JOIN CovidDeathAnalysis..CovidVaccinations vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date


--Looking at total Population vs Vaccinations

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CAST(vaccine.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccine_count  
FROM CovidDeathAnalysis..CovidDeaths death
JOIN CovidDeathAnalysis..CovidVaccinations vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date
WHERE death.continent is not null
ORDER BY 1, 2, 3


-- Using CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations,cumulative_vaccine_count)
as
(
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CAST(vaccine.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccine_count  
FROM CovidDeathAnalysis..CovidDeaths death
JOIN CovidDeathAnalysis..CovidVaccinations vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date
WHERE death.continent is not null
)

SELECT *, (cumulative_vaccine_count/population)*100/3 as complete_vaccine_rate_per_population
FROM PopvsVac


-- Using Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population bigint,
new_vaccinations bigint,
cumulative_vaccine_count numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CAST(vaccine.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccine_count  
FROM CovidDeathAnalysis..CovidDeaths death
JOIN CovidDeathAnalysis..CovidVaccinations vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date
WHERE death.continent is not null

SELECT *, (cumulative_vaccine_count/population)*100/3 as complete_vaccine_rate_per_population
FROM #PercentPopulationVaccinated


-- Creat view for visualization
CREATE VIEW PercentPopulationVaccinated  AS
SELECT death.continent, death.location, death.date, death.population, vaccine.new_vaccinations, SUM(CAST(vaccine.new_vaccinations as bigint)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS cumulative_vaccine_count  
FROM CovidDeathAnalysis..CovidDeaths death
JOIN CovidDeathAnalysis..CovidVaccinations vaccine
ON death.location = vaccine.location
AND death.date = vaccine.date
WHERE death.continent is not null
