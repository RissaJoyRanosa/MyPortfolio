
SELECT * 
FROM MyPortfolio..CovidDeath
--WHERE Continent is not null
order by 3,4

--SELECT * 
--FROM MyPortfolio..CovidVaccine
--order by 3,4

--SELECT DATA THET WE GOING TO BE USING

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM MyPortfolio..CovidDeath
order by 1,2

--Looking at total cases vs total death

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Percent_Population_Infected
FROM MyPortfolio..CovidDeath
Where Location like '%Philippines%'
order by 1,2


--I've Got a problem here that total cases have nvarchar datatype and invalid for divide operator so i needed to alter its datatype to Float.
EXEC SP_HELP 'dbo.CovidDeath';

ALTER TABLE dbo.CovidDeath
ALTER COLUMN total_cases float

--Looking at total cases vs population
--Shows what percentage of population got covid 

SELECT Location, date, population, total_cases, (total_cases/population)*100 as Percent_Population_Infected
FROM MyPortfolio..CovidDeath
--Where Location like '%Philippines%'
order by 1,2

--Looking at countries with highest infection rate compared to population

SELECT Location, population, MAX(total_cases) AS Highest_Inferction_Count, MAX(total_cases/population)*100 as Percent_Population_Infected
FROM MyPortfolio..CovidDeath
--Where Location like '%Philippines%'
GROUP BY Location, Population
order by Percent_Population_Infected desc

--Showing countries with highest death count per population

SELECT 
	Location, MAX(CAST(total_deaths AS int)) AS Total_Death_Count
FROM MyPortfolio..CovidDeath
--Where Location like '%Philippines%'
Where Continent is not null
GROUP BY Location
order by Total_Death_Count desc


--Showing the continents with the highest death count per population

SELECT 
	continent, MAX(CAST(total_deaths AS int)) AS Total_Death_Count
FROM MyPortfolio..CovidDeath
--Where Location like '%Philippines%'
	Where continent is not null
	GROUP BY continent
	order by Total_Death_Count desc;

--Global Numbers

SELECT
    date,
    SUM(New_cases) AS Total_Cases,
    SUM(New_Deaths) AS Total_Deaths,
    CASE
        WHEN SUM(New_Deaths) = 0 THEN 0
        ELSE (SUM(New_cases) * 100.0) / NULLIF(SUM(New_Deaths), 0)
    END AS Death_Percentage
FROM MyPortfolio..CovidDeath
-- WHERE Location LIKE '%Philippines%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;



--Looking at Total Population vs Vaccinations / USE CTE

SELECT 
	dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CAST(vac.new_vaccinations as float)) OVER (Partition By dea.location order by dea.location, dea.date)
	as People_Vaccinated
FROM MyPortfolio..CovidDeath dea
JOIN MyPortfolio..CovidVaccine vac
    ON dea.location = vac.location
    AND dea.date = vac.date
	where dea.continent is not null
	ORDER BY 1,2,3;

-- CTE
WITH VaccineData AS (
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS People_Vaccinated
    FROM MyPortfolio..CovidDeath dea
    JOIN MyPortfolio..CovidVaccine vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL )

SELECT 
    continent, 
    location, 
    date, 
    population, 
    new_vaccinations, 
    People_Vaccinated, 
    (People_Vaccinated / population) * 100 AS Vaccination_Percentage
FROM VaccineData
ORDER BY continent, location, date;




-- Create the temporary table
CREATE TABLE #percentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_Vaccinations numeric,
    People_Vaccinated numeric
);

-- Insert data into the temporary table
INSERT INTO #percentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS float)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS People_Vaccinated 
FROM MyPortfolio..CovidDeath dea
JOIN MyPortfolio..CovidVaccine vac
    ON dea.location = vac.location
    AND dea.date = vac.date;
    -- WHERE dea.continent IS NOT NULL
    -- ORDER BY 1, 2, 3;

-- Select data from the temporary table
SELECT *, (People_Vaccinated / Population) * 100 AS Vaccination_Percentage
FROM #percentPopulationVaccinated;

-- Drop the temporary table when you're done
DROP TABLE #percentPopulationVaccinated;

--Creating view to store data for later vizualizations

CREATE VIEW PercentPopulationVaccinated AS 
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS float)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS People_Vaccinated 
FROM MyPortfolio..CovidDeath dea
JOIN MyPortfolio..CovidVaccine vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
--ORDER BY 1, 2, 3;

SELECT *
FROM PercentPopulationVaccinated