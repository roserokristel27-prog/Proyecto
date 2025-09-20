USE futbol;

--  Parte 1: Conociendo la Data (4 preguntas)
-- 1 ¿Cuántas competiciones diferentes existen en la base de datos?
SELECT COUNT(*) as Cantidad_de_competiciones
FROM competitions; 

-- 2 ¿Cuántas temporadas se registran en total?
SELECT COUNT(*) as Cantidad_de_temporadas
FROM seasons; 

-- 3 ¿Cuántos equipos distintos están registrados?
SELECT COUNT(DISTINCT team_id) as Cantidad_de_equipos
FROM teams; 

-- 4 ¿Cuántos árbitros distintos aparecen en los partidos?
SELECT COUNT(DISTINCT referee_id) as Arbitros
FROM referees;


-- Parte 2 Consultas de análisis (6 preguntas)
-- 5  ¿Cuál es el equipo con mayor cantidad de partidos jugados como local?
SELECT t.team_name, COUNT(*) as partidos_local
FROM matches m
INNER JOIN teams t ON m.home_team_id = t.team_id
WHERE m.status = "FINISHED"
GROUP BY t.team_id, t.team_name
ORDER BY partidos_local desc
LIMIT 1;

-- 6 ¿Cuál es el equipo con mayor cantidad de victorias en total?
SELECT t.team_name, COUNT(*) AS partidos_visitante
FROM matches m
INNER JOIN teams t ON m.away_team_id = t.team_id
WHERE m.status = "FINISHED"
GROUP BY t.team_name
ORDER BY partidos_visitante DESC
LIMIT 1;

-- 7 ¿Qué temporada tuvo la mayor cantidad de goles anotados (suma de todos los partidos)?
with  GolesTemporada (Temporada, Total_Goles) as 
		(
        Select  SE.Season_id as Temporada, 
		sum(Total_goals) as Total_Goles
        from matches as MA
        inner join seasons as SE on SE.Season_ID = MA.Season_ID
        where MA.Status = "FINISHED"
        Group by SE.season_ID
        )
        Select * from GolesTemporada
            Where Total_Goles = (Select max(Total_goles) from GolesTemporada);
            
-- 8 ¿Cuál es la diferencia promedio de goles por competición?
SELECT competition_name,
       ROUND((SELECT AVG(ABS(m.goal_difference))
            FROM matches m
            INNER JOIN seasons s ON m.season_id = s.season_id
            WHERE s.competition_code = c.competition_code 
              AND m.status = 'FINISHED'), 2) as diferencia_por_competicion
FROM competitions c
ORDER BY diferencia_por_competicion DESC;

-- 9¿Qué árbitro ha dirigido la mayor cantidad de partidos?
SELECT r.referee, COUNT(*) AS partidos_dirigidos
FROM matches m
INNER JOIN referees r ON m.referee_id = r.referee_id
WHERE m.status = "FINISHED"
GROUP BY r.referee
ORDER BY partidos_dirigidos DESC
LIMIT 1;

-- 10 ¿Qué equipo tiene un mejor promedio de goles anotados por partido en laBundesliga?
SELECT 
    t.team_name,
    AVG(
        CASE 
            WHEN m.home_team_id = t.team_id THEN m.fulltime_home
            WHEN m.away_team_id = t.team_id THEN m.fulltime_away
        END
    ) AS avg_goals_per_match,
    COUNT(m.match_id) AS matches_played,
    SUM(
        CASE 
            WHEN m.home_team_id = t.team_id THEN m.fulltime_home
            WHEN m.away_team_id = t.team_id THEN m.fulltime_away
        END
    ) AS total_goals
FROM matches m
JOIN seasons s ON m.season_id = s.season_id
JOIN competitions c ON s.competition_code = c.competition_code
JOIN teams t ON t.team_id IN (m.home_team_id, m.away_team_id)
WHERE c.competition_name = 'Bundesliga'
  AND m.status = 'Finished'
GROUP BY t.team_id, t.team_name
ORDER BY avg_goals_per_match DESC
LIMIT 1;

-- Preguntas individuales

-- ¿cuántos partidos han terminado en empate y en que temporada ocurrieron?
SELECT s.season, COUNT(*) AS total_empates
FROM matches m
INNER JOIN seasons s ON m.season_id = s.season_id
WHERE m.match_outcome = 'Draw'
GROUP BY s.season
ORDER BY total_empates DESC;

-- ¿Qué árbitro ha dirigido la mayor cantidad de partidos en la  temporada 6?
with Resultado1 as 
(SELECT a.referee,
COUNT(p.match_ID) AS total_partidos
FROM matches p
JOIN referees a  ON p.Referee_ID = a.Referee_ID
JOIN seasons t ON p.Season_ID = t.Season_ID
JOIN competitions c ON c.Competition_code = t.Competition_code
WHERE p.Season_ID = 6
  AND c.competition_code = 'CL'
  AND t.season = '2024/2025'
GROUP BY a.referee
) Select * from Resultado1 
	order by Total_partidos DESC
	Limit 1;

-- Mostrar Informacion de los PARTIDOS con mas GOLES de: 
-- LOCAL - VISITANTE - EMPATE

-- Observación:Esta consulta funciona correctamente cuando se ejecuta de forma local, 
-- pero falla cuando se corre a través de la conexión.

WITH MaximoGoles AS (
(Select match_id as Partido, 
		max(total_goals) as Goles
		from matches 
		where match_outcome = "Home Win"
	 	  and Status = "FINISHED"
		group by match_id
		order by Goles DESC
        Limit 1)
UNION 
(Select match_id as Partido, 
		max(total_goals) as Goles
		from matches 
		where match_outcome = "Away Win" 
		  and Status = "FINISHED"
		group by match_id
		order by Goles DESC
        Limit 1)
UNION
(Select match_id as Partido, 
		max(total_goals) as Goles
		from matches 
		where match_outcome = "Draw" 
		  and Status = "FINISHED"
		group by match_id
		order by Goles DESC
        Limit 1)
)
Select 	match_outcome			as RESULTADO, 
		competition_name 		as Competicion,
		date_utc				as Fecha, 
		referee					as Arbitro, 
		D.team_name				as EQUIPO_Local,
		fulltime_home			as GOLES_Local,
		E.team_name				as EQUIPO_Visitante,
		Fulltime_away			as GOLES_Visitante
		from MaximoGoles 		as A
        inner join matches  	as B on B.match_ID = A.Partido 
        inner join referees 	as C on C.referee_ID = B.Referee_ID
		inner join teams    	as D on D.team_id = B.Home_team_Id
		inner join teams    	as E on E.team_id = B.Away_team_Id
        inner join seasons    	as F on F.season_ID = B.season_Id
        inner join Competitions as G on G.competition_code = F.competition_code;
        
        
-- -- ¿Cuál es la ventaja de jugar como local por competición?
select 
    c.competition_name,
    round(AVG(CASE WHEN m.match_outcome = "Home Win" THEN 1 ELSE 0 END) * 100, 2) as porcentaje_victorias_local,
    round(AVG(CASE WHEN m.match_outcome = "Away Win" THEN 1 ELSE 0 END) * 100, 2) as porcentaje_victorias_visitante,
    round(AVG(CASE WHEN m.match_outcome = "Draw" THEN 1 ELSE 0 END) * 100, 2) as porcentaje_empates,COUNT(*) as total_partidos
from  matches m
inner join seasons s ON m.season_id = s.season_id
inner join  competitions c ON s.competition_code = c.competition_code
where m.status = "FINISHED"
group by  c.competition_code, c.competition_name
order by  porcentaje_victorias_local DESC;

-- MUESTRA EL TOP DE ARBITROS CON MAYOR CANTIDAD DE PARTIDOS EN QUE LA VICTORIA LA OBTUVO EL EQUIPO LOCAL?
SELECT
  r.referee_id,
  r.referee AS referee_name,
  COUNT(*) AS matches_total_referee,
  SUM(CASE WHEN m.fulltime_home > m.fulltime_away THEN 1 ELSE 0 END) AS home_wins_count,
  ROUND(100.0 * SUM(CASE WHEN m.fulltime_home > m.fulltime_away THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_home_wins
FROM matches m
JOIN referees r ON m.referee_id = r.referee_id


WHERE m.status = 'Finished'
GROUP BY r.referee_id, r.referee
HAVING home_wins_count > 0
ORDER BY home_wins_count DESC, matches_total_referee DESC
LIMIT 10;


