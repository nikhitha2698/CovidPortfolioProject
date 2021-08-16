--select * from CovidDeaths;
--select top(2) total_deaths from CovidPortfolioProject.dbo.CovidDeaths;
--select * from CovidPortfolioProject..CovidDeaths;
--select * from CovidVaccinations order by 3,4;

-- selected data that is needed for the project

-------------------------DISTINCT-------------------------
--#1
select distinct(continent) from CovidDeaths
order by continent;
--#2
select location,date,total_cases,new_cases,total_deaths,population 
from CovidDeaths 
order by 1,2

-- Looking for percentage of deaths for the cases listed 
--#3
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage,population 
from CovidDeaths 
order by 1,2

-- Looking for percentage of deaths for the cases listed for a specific country
--#4
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as death_percentage,population 
from CovidDeaths 
--where location = 'United States'
where location like '%State%'
order by 1,2

-- Looking for percentage of cases for the total no of population listed
--#5
select location,population,total_cases,(total_cases/population)*100 as cases_percentage
from CovidDeaths
--where location like '%State%'
group by location,population
order by 1,2


-- Looking for highest percentage of cases per population   ------------------------- AGGREGATE FUNCTION-------------------------
--#6
select location,population,Max(total_cases) as highest,Max((total_cases/population))*100 as cases_percentage_population
from CovidDeaths
group by location,population
order by cases_percentage_population desc

-- Looking for highest percentage of deaths per population 
--#7
select location,population,Max(total_deaths) as highest,Max((total_deaths/population))*100 as death_percentage_population
from CovidDeaths
group by location,population
order by death_percentage_population desc

-- Showing countries in the order of highest death count 
--#8
select location,Max(total_deaths) as highest
from CovidDeaths
group by location
order by highest desc
-- result received above will have an issue with the data -- its related to datatype nvarchar and aggregate max function, after casting it should fix the issue 
--( from this result we still see data issue so added continent not null)

------------------------- CAST-------------------------
--#9
select location,Max(cast(total_deaths as int)) as highest
from CovidDeaths
where continent is null
group by location
order by highest desc
--#10
select continent,Max(cast(total_deaths as int)) as highest
from CovidDeaths
where continent is not null
group by continent
order by highest desc
--#11
select distinct continent,location from CovidDeaths where location ='North America';
select distinct location from CovidDeaths where continent ='North America';
--#12
select location,Max(cast(total_deaths as int)) as highest
from CovidDeaths
where continent  ='North America'
group by location
order by highest desc

-- the above few queries are to understand how the data is populated if you go by country or directly the continent
-- we will use the below query as it gives the numbers of entire continent
--#13
select location,Max(cast(total_deaths as int)) as highest
from CovidDeaths
where continent is null
group by location
order by highest desc

-- Below query is to find the highest death count in the continent
--#14
select continent,Max(cast(total_deaths as int)) as highest
from CovidDeaths
where continent is not null
group by continent
order by highest desc

-- so now we are trying to new_cases column -- the sum of all new cases based on a date will add back to total_cases count
-- below will give total number of cases/deaths and percentage for a given date
-------------------------SUM-------------------------
--#15
select date,SUM(new_cases) as total_cases,SUM(cast (new_deaths as int)) as total_deaths, SUM (cast (new_deaths as int))/SUM(new_cases)*100 as death_percentage 
from CovidDeaths 
where continent is not null
group by date
order by date desc

-- Without Date 
--#16
select SUM(new_cases) as total_cases,SUM(cast (new_deaths as int)) as total_deaths, SUM (cast (new_deaths as int))/SUM(new_cases)*100 as death_percentage 
from CovidDeaths 
where continent is not null

-------------------------JOINS-------------------------: to join both the tables
--#17
select * 
from CovidDeaths dea
join CovidVaccinations vac 
ON dea.location = vac.location and dea.date = vac.date

-- Q : total population vaccinated - so we can try to get it from direct sol1 :total_vaccinations sol2 : new_vaccinations
--#18
select dea.continent,dea.location as loc,dea.date as date, max(population) as population,max(total_vaccinations) as total_vaccinations,max(new_vaccinations) as new_vaccinations
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null and dea.location ='Canada' and dea.date > '2020-12-14 00:00:00.000'
group by dea.continent,dea.location,dea.date
order by population desc

-- sol2 get the total vaccinations with new_vaccinations column  -------------------------CONVERT/OVER/PARTITION-------------------------
--#19
select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as rollingpeoplevaccinated
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--group by dea.continent,dea.location,dea.date
order by 2,3



-- Now trying to find the percentage of people vaccinated in those countries  ----------------WE HAVE OPTION TO USE CTE OR TEMP------------------

--------------------USE CTE--------------------
--#20
With PopvsVac(continent,location,date,population,new_vaccinations,rollingpeoplevaccinated)
as
(
select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as rollingpeoplevaccinated
--,(rollingpeoplevaccinated/population)*100  --////uncomment to see the error -- it will not allow us to use the defined column
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--group by dea.continent,dea.location,dea.date
--order by 2,3 --- //COMMENTED AS IT DOESN'T WORK WHEN IT IT INSIDE CTE
)
select *,(rollingpeoplevaccinated/population)*100 as percentagevaccinated from PopvsVac

-------------------------TEMP--------------------------
--#21
Drop table if exists #temptocalculatepercent

Create table #temptocalculatepercent
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
rollingpeoplevaccinated numeric
)

insert into #temptocalculatepercent
select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as rollingpeoplevaccinated
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null

select *,(rollingpeoplevaccinated/population)*100 as percentagevaccinated from #temptocalculatepercent

---------------------------------------------------------------------------------------------------------------


-- Ran below queries just to figure out the discrepancy found with new_vaccinations for date 12/14 canada
--#22
select dea.date,vac.date,total_vaccinations,new_vaccinations 
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where vac.location ='Canada' and vac.date = '2020-12-14 00:00:00.000'
--#23
select dea.date,vac.date,total_vaccinations,new_vaccinations 
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.location ='Canada' and dea.date = '2020-12-14 00:00:00.000'

---------------VIEW CREATION--------------------
--#24
create view PercentPopulationVaccinated1 AS 
select dea.continent,dea.location,dea.date, dea.population,vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location,dea.date) as rollingpeoplevaccinated
from CovidDeaths dea 
join CovidVaccinations vac ON dea.location = vac.location and dea.date = vac.date
where dea.continent is not null;

select * from PercentPopulationVaccinated

-----------------------------------------------------------------------------------------------------------------------------------------
--QUERIES USED FOR VISUALIZATION -- SAME AS ABOVE

--#1
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From CovidDeaths
where continent is not null 
order by 1,2

--#2
-- We take these out as they are not inluded in the above queries and want to stay consistent
-- European Union is part of Europe

Select location, SUM(cast(new_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is null 
and location not in ('World', 'European Union', 'International')
Group by location
order by TotalDeathCount desc

--#3
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc

--#4
Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc