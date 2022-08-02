use PortfolioProject

select location
from CovidDeaths
where continent is null
--order by 3,4

----Select data that we're going to be using 
select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by 1,2

--Looking at total_cases vs total_deaths
--shows the likelihood of dying if you contract covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths
where location like 'Arg%' and continent is not null
order by 1,2

--Looking at total_cases vs popluation
--shows what percentage of popluation got Covid19
select distinct location, date, population,total_cases,(total_cases/population)*100 as Percentaje_Of_Population_Infected
from CovidDeaths
where location like '%states%' and continent is not null
order by 1,2

--Looking at countries with highest infection rate compared to population
select distinct location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 as Percentaje_Of_Population_Infected
from CovidDeaths
where continent is not null
group by location, population
order by Percentaje_Of_Population_Infected desc

--cast total_deaths since nvarchar(255), we need more
select location, MAX(CAST(total_deaths as int)) as totalDeathCount
from CovidDeaths
where continent is not null 
group by location
order by totalDeathCount desc

--Showing continents with the highest death count per population
select location, MAX(CAST(total_deaths as int)) as totalDeathCount
from CovidDeaths
where continent is null and location not like 'Upper middle income' and location not like 'High income' and location not like 'Lower middle income' and location not like 'Low income'
group by location
order by totalDeathCount desc

--Global numbers
--how many people got infected, died, and deadPercentage per day
select date, SUM(new_cases) as totalCases, SUM(CAST(new_deaths as int)) as totalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
from CovidDeaths
where continent is not null
group by date
order by 1,2

--Looking at total population vs Vaccination
--How many people in the world got vaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rollingPeopleVaccinated 
from CovidDeaths as d 
	join CovidVaccinations as v 
	on d.location = v.location and d.date = v.date
where d.continent is not null
order by 2,3


--#1 Using CTE to determine the % of people vaccinated by continent 
with PopVsVac (continent, location, date, population,new_vaccinations, rollingPeopleVaccinated)
as
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rollingPeopleVaccinated 
from CovidDeaths as d 
	join CovidVaccinations as v 
	on d.location = v.location 
	and d.date = v.date
where d.continent is not null
--order by 2,3
)
select *,
(rollingPeopleVaccinated/population)*100 as PercentageOfPeopleVaccinated
from PopVsVac


-- #2 Using Temp Table
--drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rollingPeopleVaccinated numeric
)
insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rollingPeopleVaccinated 
from CovidDeaths as d 
	join CovidVaccinations as v 
	on d.location = v.location 
	and d.date = v.date
where d.continent is not null
--order by 2,3
select *,
(rollingPeopleVaccinated/population)*100 as PercentageOfPeopleVaccinated
from #PercentPopulationVaccinated


--Creating a view to store data for later vizualizations
create view PercentPopulationVaccinated as 
select d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(CONVERT(bigint,v.new_vaccinations)) over (partition by d.location order by d.location, d.date) as rollingPeopleVaccinated 
from CovidDeaths as d 
	join CovidVaccinations as v 
	on d.location = v.location 
	and d.date = v.date
where d.continent is not null

select *
from PercentPopulationVaccinated