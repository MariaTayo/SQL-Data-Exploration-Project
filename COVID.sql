/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT * FROM `sql-projects-381215.SQLProject.CovidDeaths` 
ORDER BY 3,4;

-- Retrieving Covid deaths data 

SELECT Location, date, total_cases, new_cases, total_deaths, population 
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
order by 1,2;

-- Reviewing Total Cases vs Total Deaths for the United Kingdom

SELECT Location, date, total_cases, total_deaths, (Total_deaths/total_cases) *100 AS DeathPercentage
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
WHERE Location = 'United Kingdom'
order by 1,2;

-- Reviewing Total Cases vs Population. This shows the percentage of the United Kingdom population that has been reported to have contracted Covid.

SELECT Location, date, Population, total_cases, (total_cases/population) *100 AS Percent_Of_Population_Infected
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
WHERE Location = 'United Kingdom'
ORDER BY 1,2;

-- Reviewing at Countries with Highest Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS Highest_Infection_Count, MAX((total_cases/population)) *100 AS Percentage_Of_Population_Infected
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
GROUP BY Location, Population
ORDER BY Percentage_Of_Population_Infected DESC;

-- This shows the countries with the highest death count per Population

SELECT Location, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
GROUP BY Location
ORDER BY Total_Death_Count DESC;

-- To only show continents that are not null 

SELECT * FROM `sql-projects-381215.SQLProject.CovidDeaths`
WHERE Continent IS NOT NULL
order by 3,4;

-- Breaking total deaths down by Continent
-- Showing continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS Total_Death_Count
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
WHERE continent is not null
GROUP BY continent
ORDER BY Total_Death_Count DESC;

-- Global Figures of total cases, total deaths and total death percentage (where continent is not null)

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS Death_Percentage
FROM `sql-projects-381215.SQLProject.CovidDeaths` 
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2;

-- Retrieving Covid Vaccinations data

SELECT * FROM `sql-projects-381215.SQLProject.CovidVaccinations` 
order by 3,4;

-- Joining both tables and looking at Total Population vs Vaccinations
-- This shows the percentage of the population that has received at least one covid vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations 
FROM `sql-projects-381215.SQLProject.CovidDeaths` dea
JOIN `sql-projects-381215.SQLProject.CovidVaccinations` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM `sql-projects-381215.SQLProject.CovidDeaths` dea
JOIN `sql-projects-381215.SQLProject.CovidVaccinations` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3;

-- Using CTE to perform calculation on Partition By from previous query

WITH PopvsVac --(Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated) 
AS 
(
  SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS Rolling_People_Vaccinated
FROM `sql-projects-381215.SQLProject.CovidDeaths` dea
JOIN `sql-projects-381215.SQLProject.CovidVaccinations` vac
  ON dea.location = vac.location
  AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (Rolling_People_Vaccinated/Population)*100 
FROM PopvsVac;


-- Creating a Temp Table as an alternative to a CTE

DROP Table if exists #PercentPopulationVaccinated
Create  Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From `sql-projects-381215.SQLProject.CovidDeaths` dea
Join `sql-projects-381215.SQLProject.CovidVaccinations` vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM `sql-projects-381215.SQLProject.CovidDeaths` dea
JOIN `sql-projects-381215.SQLProject.CovidVaccinations` vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
