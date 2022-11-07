SELECT   *
FROM     covid..coviddeaths
WHERE    continent IS NOT NULL
ORDER BY 3,
         4
-- select *
-- from covid..CovidVaccination
-- order by 3,4
SELECT location,
       date,
       total_cases,
       new_cases,
       total_deaths,
       population_density
FROM   covid..coviddeaths
WHERE  [location] ='Vietnam'
--Looking at Total Cases vs Total Deaths
--shows likelihood of dying if contract covid
SELECT   location,
         date,
         total_cases,
         total_deaths,
         (total_deaths/total_cases)*100 AS death_percent
FROM     covid..coviddeaths
WHERE    [location] LIKE '%states%'
AND      total_deaths IS NOT NULL
AND      continent IS NOT NULL
ORDER BY 1,
         2
--Looking at Total Cases vs Population
--Shows what percentage of population got Covid
SELECT   location,
         date,
         total_cases,
         population,
         (total_cases/population)*100 AS percentage_population_got_covid
FROM     covid..coviddeaths
WHERE    [location] LIKE '%states%'
AND      total_deaths IS NOT NULL
AND      continent IS NOT NULL
ORDER BY 1,
         2
--Looking at country with highest Infection Rate compared to Population
SELECT   location,
         population,
         Max(total_cases)                  AS HighestInfectionCount,
         (Max(total_cases)/population)*100 AS percentage_population_got_covid
FROM     covid..coviddeaths
         --where [location] like '%states%' and total_deaths is not NULL
WHERE    continent IS NOT NULL
GROUP BY location,
         population
ORDER BY 4 DESC
--showing the country with Highest Death Count per Population
SELECT   location,
         population,
         Max(total_deaths) AS TotalDeathCount
FROM     covid..coviddeaths
WHERE    continent IS NOT NULL
AND      total_deaths IS NOT NULL
GROUP BY location,
         population
ORDER BY 3 DESC
--LET'S BREAK THINGS DOWN BY CONTINENT
--showing continents with Highest Death Count
SELECT   [continent],
         Max(total_deaths) AS TotalDeathCount
FROM     covid..coviddeaths
WHERE    continent IS NOT NULL
AND      total_deaths IS NOT NULL
GROUP BY [continent]
ORDER BY totaldeathcount DESC
--GLOBAL NUMBER
--Total_cases, total_deaths, new_cases and new_deaths by date
SELECT   date,
         total_cases,
         total_deaths,
         new_deaths,
         (new_deaths/new_cases)*100 AS deathpercentagebydate
FROM     covid..coviddeaths
WHERE    [location] = 'World'
AND      new_cases !=0
         --group by date
ORDER BY date
--total cases, total deaths and dealth percentage in the world up to now
         with t1 AS
         (
                  SELECT   [location],
                           max(total_deaths) AS total_dealths
                  FROM     covid..coviddeaths
                  WHERE    [location] = 'World'
                  GROUP BY location ),
         t2 AS
         (
                  SELECT   location,
                           max(total_cases) AS total_cases
                  FROM     covid..coviddeaths
                  WHERE    [location] = 'World'
                  GROUP BY location )
SELECT t1.total_dealths ,
       t2.total_cases,
       (t1.total_dealths/t2.total_cases)*100 AS DeathPercentage
FROM   t1
JOIN   t2
ON     t1.[location] = t2.[location]
--Looking at total population and vaccinations
SELECT   dea.continent,
         dea.[location],
         dea.date,
         dea.population,
         vac.new_vaccinations,
         Sum(vac.new_vaccinations) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM     covid..coviddeaths dea
JOIN     covid..covidvaccination vac
ON       dea.date = vac.date
AND      dea.[location] = vac.[location]
WHERE    dea.continent IS NOT NULL
ORDER BY 2,
         3
-- USE CTE
with popvsvac
     (
          continent,
          location,
          date,
          total_cases,
          population,
          new_vaccinations,
          rollingpeoplevaccinated
     )
     AS
     (
              SELECT   dea.continent,
                       dea.[location],
                       dea.date,
                       dea.total_cases,
                       dea.population,
                       vac.new_vaccinations,
                       sum(vac.new_vaccinations) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
              FROM     covid..coviddeaths dea
              JOIN     covid..covidvaccination vac
              ON       dea.date = vac.date
              AND      dea.[location] = vac.[location]
              WHERE    dea.continent IS NOT NULL
              AND      dea.total_cases IS NOT NULL --and dea.[location] = 'Vietnam'
                       --order by 1,2,3
     )
SELECT   *,
         (rollingpeoplevaccinated/population)*100 AS vaccinated_percent
FROM     popvsvac
WHERE    total_cases IS NOT NULL
ORDER BY location,
         date
----TEMP TABLEDROP TABLEIF EXISTS #percentpopulationvaccinated
CREATE TABLE #percentpopulationvaccinated
             (
                          continent               nvarchar(255),
                          location                nvarchar(255),
                                                  date datetime,
                          population              numeric,
                          new_vaccinations        numeric,
                          rollingpeoplevaccinated numeric
             )
INSERT INTO #percentpopulationvaccinated
SELECT   dea.continent,
         dea.[location],
         dea.date,
         dea.population,
         vac.new_vaccinations,
         Sum(vac.new_vaccinations) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM     covid..coviddeaths dea
JOIN     covid..covidvaccination vac
ON       dea.date = vac.date
AND      dea.[location] = vac.[location]
WHERE    dea.continent IS NOT NULL --and dea.total_cases is not null --and dea.[location] = 'Vietnam'
--order by 1,2,3
SELECT   *,
         (rollingpeoplevaccinated/population)*100 AS vaccinated_percent
FROM     #percentpopulationvaccinated
ORDER BY location,
         date
--Create View to store data for later Visualization
CREATE VIEW percentpopulationvaccinated AS
SELECT   dea.continent,
         dea.[location],
         dea.date,
         dea.population,
         vac.new_vaccinations,
         Sum(vac.new_vaccinations) OVER (partition BY dea.location ORDER BY dea.location, dea.date) AS rollingpeoplevaccinated
FROM     covid..coviddeaths dea
JOIN     covid..covidvaccination vac
ON       dea.date = vac.date
AND      dea.[location] = vac.[location]
WHERE    dea.continent IS NOT NULL --and dea.total_cases is not null --and dea.[location] = 'Vietnam'
--order by 1,2,3
select *
FROM   percentpopulationvaccinated