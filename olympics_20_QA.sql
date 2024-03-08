SELECT * 
FROM athlete_events$

SELECT COUNT(*) 
FROM athlete_events$

SELECT * 
FROM noc_regions$

--1)How many olympics games have been held?
SELECT *
FROM athlete_events$

SELECT COUNT(DISTINCT(Games))
FROM athlete_events$

--2)List down all Olympics games held so far

SELECT DISTINCT(Year),Season,City
FROM athlete_events$
ORDER BY Year

--3) Mention the total no of nations who participated in each olympics game?

WITH t1(games,nation) AS
(
SELECT athl.Games,reg.NOC
FROM athlete_events$ AS athl
JOIN noc_regions$  AS reg
ON athl.NOC=reg.NOC
GROUP BY athl.Games,reg.NOC)

SELECT games,COUNT(nation)
FROM t1
GROUP BY games
ORDER BY games


--4). Which year saw the highest and lowest no of countries participating in olympics

WITH t1(games,nation) AS
(
SELECT athl.Games,reg.NOC
FROM athlete_events$ AS athl
JOIN noc_regions$  AS reg
ON athl.NOC=reg.NOC
GROUP BY athl.Games,reg.NOC),

t2(games,total_nations) AS 
(
SELECT games,COUNT(nation)
FROM t1
GROUP BY games)

SELECT DISTINCT CONCAT(first_value(games) OVER (ORDER BY total_nations),'-',
       first_value(total_nations) OVER (ORDER BY total_nations)),
	   CONCAT(first_value(games) OVER (ORDER BY total_nations DESC),'-',
	   first_value(total_nations) OVER (ORDER BY total_nations DESC))
FROM t2
ORDER BY 1

--5)Which nation has participated in all of the olympic games

WITH total_games(total) AS 
(
SELECT COUNT(DISTINCT(Games))
FROM athlete_events$),

t2(region,total_parti) AS
(
SELECT region,COUNT(DISTINCT(Games))
FROM noc_regions$ AS regi
JOIN athlete_events$ AS athl
ON regi.NOC=athl.NOC
GROUP BY region)


SELECT region,total_parti
FROM total_games,t2
WHERE total_parti = total_games.total
ORDER BY region

--6)Identify the sport which was played in all summer olympics.

WITH t1(total_count) AS 
(SELECT COUNT(DISTINCT(Games))
FROM athlete_events$
WHERE Season = 'Summer'),

t2(sport,count_of_happened) AS 
(SELECT Sport,COUNT(DISTINCT(Games))
FROM athlete_events$
WHERE Season= 'Summer'
GROUP BY Sport)

SELECT *
FROM t2,t1
WHERE t2.count_of_happened = t1.total_count

------OR-----------------------------------------------------------------------------------------------------------

--6)Identify the sport which was played in all summer olympics.

WITH total_summ(total) AS 
(
SELECT COUNT(DISTINCT(Games))
FROM athlete_events$
WHERE Season='Summer'),

t2(sport,games) AS 
(
SELECT Sport,Games
FROM athlete_events$
WHERE Season = 'Summer'
GROUP BY Sport,Games),

t3(sport,total_games) AS 
(
SELECT sport,COUNT(games)
FROM t2
GROUP BY sport)

SELECT sport,total_games
FROM t3,total_summ
WHERE total_games=total


--7) Which Sports were just played only once in the olympics

WITH games(sport,game) AS
(
SELECT Sport,Games
FROM athlete_events$
GROUP BY Sport,Games)

SELECT t1.*,games.game
FROM (SELECT Sport,COUNT(DISTINCT(Games)) AS total_parti
FROM athlete_events$
GROUP BY Sport) AS t1
JOIN games
ON t1.Sport=games.sport
WHERE t1.total_parti=1


--8)Fetch the total no of sports played in each olympic games

SELECT DISTINCT(Sport)
FROM athlete_events$

SELECT Games,COUNT(Distinct(Sport)) AS no_of_sport
FROM athlete_events$
GROUP BY Games
ORDER BY no_of_sport DESC

--9)Fetch oldest athletes to win a gold medal

SELECT *
FROM athlete_events$

WITH t1(name,age,team,medal,game,sport,event) AS 
(
SELECT Name,Age,Team,Medal,Games,Sport,Event
FROM athlete_events$
WHERE Medal ='Gold'),

t2(name,age,team,medal,game,sport,event,rank) AS
(
SELECT *,RANK() OVER (ORDER BY Age DESC)
FROM t1)

SELECT *
FROM t2
WHERE rank=1


--10)Find the Ratio of male and female athletes participated in all olympic games

WITH t1(sex,total) AS 
(
SELECT Sex,COUNT(Sex)
FROM athlete_events$
GROUP BY Sex),

t2(sex,total,row_no) AS 
(
SELECT *,ROW_NUMBER() OVER (ORDER BY total)
FROM t1),

female(fno) AS 
(
SELECT CAST(total AS float)
FROM t2
WHERE row_no=1),

male(mno) AS 
(
SELECT CAST(total AS float) 
FROM t2
WHERE row_no=2)


--SELECT CONCAT('1:',male.mno/female.fno) AS ration
--FROM female,male

SELECT (SELECT CONCAT(male.mno/(male.mno+female.fno)*100,'%') FROM male,female) AS male_per,
       (SELECT CONCAT(female.fno/(male.mno+female.fno)*100,'%') FROM male,female) AS female_per,
	   (SELECT CONCAT((male.mno/(male.mno+female.fno)*100)+(female.fno/(male.mno+female.fno)*100),'%')) AS total 
from female,male

--11)Fetch the top 5 athletes who have won the most gold medals

WITH t1(Name,team,total_gold) AS 
(
SELECT Name,Team,COUNT(Medal)
FROM athlete_events$
WHERE Medal='Gold'
GROUP BY Name,Team),

t2(Name,team,total_gold,ranking) AS 
(
SELECT *,DENSE_RANK() OVER (ORDER BY total_gold DESC)
FROM t1)

SELECT *
FROM t2
WHERE ranking<=5
ORDER BY ranking

--12)Fetch the top 5 athletes who have won the most medals (gold/silver/bronze)

WITH t1(name,team,cnt) AS
(
SELECT Name,Team,COUNT(Medal)
FROM athlete_events$
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY Name,Team),

t2(name,team,cnt,rnk) AS
(
SELECT *,DENSE_RANK() OVER (ORDER BY cnt DESC )
FROM t1)

SELECT *
FROM t2
WHERE rnk<=5
ORDER BY rnk

--13)Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won

WITH t1(nation,medal_cnt) AS 
(
SELECT regi.region,COUNT(Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY regi.region),

t2(nation,medal_cnt,rnk) AS 
(
SELECT *,DEM=DENSE_RANK() OVER (ORDER BY medal_cnt DESC)
FROM t1)

SELECT *
FROM t2
WHERE rnk<6

--14) List down total gold, silver and bronze medals won by each country

WITH t1(nations,ttl_cnt) AS 
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
FULL OUTER JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY region),

t2(nations,gold_cnt) AS 
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
FULL OUTER JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold'
GROUP BY region),

t3(nations,silver_cnt) AS
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Silver' 
GROUP BY region),

t4(nations,bronze_cnt) AS 
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
FULL OUTER JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Bronze'
GROUP BY region)

SELECT t1.nations,t1.ttl_cnt,t2.gold_cnt,t3.silver_cnt,t4.bronze_cnt 
FROM t1
FULL OUTER JOIN t2
ON t1.nations=t2.nations
FULL OUTER JOIN t3 
ON t1.nations=t3.nations
FULL OUTER JOIN t4 
ON t1.nations=t4.nations
ORDER BY nations

--15)List down total gold, silver and bronze medals won by each country corresponding to each olympic games



WITH t1(nations,game,ttl_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY region,Games),

t2(nations,game,gold_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold'
GROUP BY region,Games),

t3(nations,game,silver_cnt) AS
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Silver' 
GROUP BY region,Games),

t4(nations,game,bronze_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Bronze'
GROUP BY region,Games)

SELECT t1.nations,t1.game,t1.ttl_cnt,t2.gold_cnt,t3.silver_cnt,t4.bronze_cnt 
FROM t1
FULL JOIN t2
ON t1.nations=t2.nations AND t1.game=t2.game
FULL JOIN t3 
ON t1.nations=t3.nations AND t1.game=t3.game
FULL JOIN t4 
ON t1.nations=t4.nations AND t1.game=t4.game
ORDER BY t1.game

--16)Identify which country won the most gold, most silver and most bronze medals in each olympic games

SELECT *
FROM athlete_events$


WITH t1(nations,game,ttl_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY region,Games),

t2(nations,game,gold_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold'
GROUP BY region,Games),

t3(nations,game,silver_cnt) AS
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Silver' 
GROUP BY region,Games),

t4(nations,game,bronze_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Bronze'
GROUP BY region,Games),

t5(nations,game,ttl_cnt,gold_cnt,silver_cnt,bronze_cnt) AS 
(
SELECT t1.nations,t1.game,t1.ttl_cnt,t2.gold_cnt,t3.silver_cnt,t4.bronze_cnt 
FROM t1
FULL JOIN t2
ON t1.nations=t2.nations AND t1.game=t2.game
FULL JOIN t3 
ON t1.nations=t3.nations AND t1.game=t3.game
FULL JOIN t4 
ON t1.nations=t4.nations AND t1.game=t4.game)

SELECT DISTINCT(game),CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY gold_cnt DESC),'-',
                             FIRST_VALUE(gold_cnt) OVER (PARTITION BY game ORDER BY gold_cnt DESC)) AS most_gold,
                      CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY silver_cnt DESC),'-',
					         FIRST_VALUE(silver_cnt) OVER (PARTITION BY game ORDER BY silver_cnt DESC)) AS most_silver,
					  CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY bronze_cnt DESC),'-',
					         FIRST_VALUE(bronze_cnt) OVER (PARTITION BY game ORDER BY bronze_cnt DESC)) AS most_bronze
FROM t5
ORDER BY game


--17)Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games

WITH t1(nations,game,ttl_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY region,Games),

t2(nations,game,gold_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold'
GROUP BY region,Games),

t3(nations,game,silver_cnt) AS
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Silver' 
GROUP BY region,Games),

t4(nations,game,bronze_cnt) AS 
(
SELECT regi.region,athl.Games,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Bronze'
GROUP BY region,Games),

t5(nations,game,ttl_cnt,gold_cnt,silver_cnt,bronze_cnt) AS 
(
SELECT t1.nations,t1.game,t1.ttl_cnt,t2.gold_cnt,t3.silver_cnt,t4.bronze_cnt 
FROM t1
FULL JOIN t2
ON t1.nations=t2.nations AND t1.game=t2.game
JOIN t3 
ON t1.nations=t3.nations AND t1.game=t3.game
JOIN t4 
ON t1.nations=t4.nations AND t1.game=t4.game)

SELECT DISTINCT(game),CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY gold_cnt DESC),'-',
                             FIRST_VALUE(gold_cnt) OVER (PARTITION BY game ORDER BY gold_cnt DESC)) AS most_gold,
                      CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY silver_cnt DESC),'-',
					         FIRST_VALUE(silver_cnt) OVER (PARTITION BY game ORDER BY silver_cnt DESC)) AS most_silver,
					  CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY bronze_cnt DESC),'-',
					         FIRST_VALUE(bronze_cnt) OVER (PARTITION BY game ORDER BY bronze_cnt DESC)) AS most_bronze,
					  CONCAT(FIRST_VALUE(nations) OVER (PARTITION BY game ORDER BY ttl_cnt DESC),'-',
					  FIRST_VALUE(ttl_cnt) OVER (PARTITION BY game ORDER BY ttl_cnt DESC)) AS most_ttl
FROM t5
ORDER BY game

--18) Which countries have never won gold medal but have won silver/bronze medals?


WITH t1(nations,ttl_cnt) AS 
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY region),

t2(nations,gold_cnt) AS 
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal = 'Gold'
GROUP BY region),

t3(nations,silver_cnt) AS
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Silver' 
GROUP BY region),

t4(nations,bronze_cnt) AS 
(
SELECT regi.region,COUNT(athl.Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Bronze'
GROUP BY region)

SELECT t1.nations,t1.ttl_cnt,t2.gold_cnt,t3.silver_cnt,t4.bronze_cnt
FROM t1
FULL JOIN t2
ON t1.nations=t2.nations 
FULL JOIN t3 
ON t1.nations=t3.nations 
FULL JOIN t4 
ON t1.nations=t4.nations
WHERE t2.gold_cnt IS NULL
ORDER BY t1.ttl_cnt

--19) In which Sport/event, India has won highest medals

WITH t1(sport,nation,ttl_medals) AS
(
SELECT Sport,region,COUNT(Medal) AS ttl_medals
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY Sport,region)


SELECT DISTINCT CONCAT(FIRST_VALUE(sport) OVER (ORDER BY ttl_medals DESC),'-',
              FIRST_VALUE(ttl_medals) OVER (ORDER BY ttl_medals DESC)) AS most_medals_in
FROM t1
WHERE nation ='India'

--20) Break down all olympic games where India won medal for Hockey and how many medals in each olympic games

WITH t1(game,nation,sport,ttl_medals) AS 
(
SELECT Games,region,Sport,COUNT(Medal)
FROM athlete_events$ AS athl
JOIN noc_regions$ AS regi
ON athl.NOC=regi.NOC
WHERE Medal='Gold' OR Medal='Silver' OR Medal='Bronze'
GROUP BY Games,region,Sport)

SELECT *
FROM t1
WHERE nation = 'India' AND sport = 'Hockey'
ORDER BY ttl_medals