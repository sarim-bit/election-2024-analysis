-- Total Seats
SELECT 
	DISTINCT(COUNT(Constituency_ID)) AS total_seats
FROM
	constituencywise_results

-- Total Seats in each state
SELECT 
	s.State,
	COUNT(sr.Const_No) AS total_seats
FROM 
	statewise_results AS sr
INNER JOIN 
	states AS s 
	ON s.State_ID = sr.State_ID
GROUP BY
	s.State

-- Add Alliance Column
ALTER TABLE partywise_results
ADD Alliance VARCHAR(50);

-- Update Alliance values based on Party_ID
UPDATE partywise_results
SET Alliance = CASE
    WHEN Party_ID IN (742, 1, 140, 3482, 547, 545, 544, 582, 772, 834, 852, 911, 
                      1046, 3620, 1420, 2484, 1534, 1680, 3369, 1847)
        THEN 'INDIA'
    WHEN Party_ID IN (369, 805, 1745, 3529, 3165, 160, 2070, 83, 664, 860, 804, 
                      1142, 1458, 1658)
        THEN 'NDA'
    ELSE 'OTHER'
END;
SELECT * FROM partywise_results



-- Total Seats won by NDA
SELECT 
	SUM(Won) AS NDA_Seats_Won
FROM 
	partywise_results
WHERE 
	alliance = 'NDA'



-- Partywise Seat Distribution in NDA
SELECT 
	Party AS Party_Name,
	Won AS Seats_Won
FROM 
	partywise_results
WHERE 
	alliance = 'NDA'
ORDER BY 
	Seats_Won DESC



-- Total Seats won by I.N.D.I.A
SELECT 
	SUM(Won) AS INDIA_Seats_Won
FROM 
	partywise_results
WHERE 
	alliance = 'INDIA'



-- I.N.D.I.A Seat distribution
SELECT 
	Party AS Party_Name,
	Won AS Seats_Won
FROM 
	partywise_results
WHERE 
	alliance = 'INDIA'
ORDER BY 
	Seats_Won DESC

-- Alliance Result Comparison
SELECT
	Alliance,
	SUM(Won) AS Seats_Won
FROM
	partywise_results
GROUP BY
	Alliance
ORDER BY
	Seats_Won DESC

-- Winning Candidate Info of a specific Constituency
SELECT 
	cr.Winning_Candidate, p.Party, p.Alliance, cr.Total_Votes, cr.Margin, cr.Constituency_Name, s.State
FROM 
	constituencywise_results AS cr
INNER JOIN
	partywise_results AS p 
	ON p.Party_ID = cr.Party_ID
INNER JOIN
	statewise_results AS sr
	ON sr.Parliament_Constituency = cr.Parliament_Constituency
INNER JOIN
	states AS s
	ON s.State_ID = sr.State_ID
WHERE s.State = 'Uttar Pradesh' AND cr.Constituency_Name = 'Lucknow'

-- EVM Votes vs Postal Votes
SELECT 
	cd.Candidate, cd.Party, cr.Constituency_Name, cd.EVM_Votes, cd.Postal_Votes, cd.Total_Votes, 
	cd.EVM_Votes*100/ cd.Total_Votes AS EVM_Votes_Pct 
FROM 
	constituencywise_details AS cd
INNER JOIN
	constituencywise_results AS cr
	ON cr.Constituency_ID = cd.Constituency_ID
WHERE cd.Total_Votes > 0
ORDER BY
	cr.Constituency_Name

-- Statewise Party Seats Distribution
SELECT 
	s.State, p.Party,
	COUNT(cr.Constituency_ID) AS Seats_Won
FROM 
	constituencywise_results AS cr
INNER JOIN 
	partywise_results AS p
	ON p.Party_ID = cr.Party_ID
INNER JOIN
	statewise_results AS sr
	ON sr.Parliament_Constituency = cr.Parliament_Constituency
INNER JOIN
	states AS s
	ON s.State_ID = sr.State_ID
GROUP BY 
	p.Party, s.State
ORDER BY
	s.State

-- Statewise Alliance Seats Distribution
SELECT 
	s.State,
	SUM(CASE WHEN p.Alliance = 'NDA' THEN 1 ELSE 0 END) AS NDA_Seats_Won,
	SUM(CASE WHEN p.Alliance = 'INDIA' THEN 1 ELSE 0 END) AS INDIA_Seats_Won,
	SUM(CASE WHEN p.Alliance = 'OTHER' THEN 1 ELSE 0 END) AS Others_Seats_Won
FROM 
	constituencywise_results AS cr
INNER JOIN 
	partywise_results AS p
	ON p.Party_ID = cr.Party_ID
INNER JOIN
	statewise_results AS sr
	ON sr.Parliament_Constituency = cr.Parliament_Constituency
INNER JOIN
	states AS s
	ON s.State_ID = sr.State_ID
GROUP BY 
	s.State
ORDER BY
	s.State

-- Constituencywise winner and runnerup
WITH Ranked_Candidates AS (
	SELECT 
	Constituency_ID, Candidate, Party, Total_Votes,
	RANK() OVER(PARTITION BY Constituency_ID ORDER BY Total_Votes) AS Rank
	FROM
	constituencywise_details
)

SELECT 
	cr.Constituency_Name, 
	MAX(CASE WHEN rc.Rank = 1 THEN rc.Candidate END) AS Winning_Candidate,
	MAX(CASE WHEN rc.Rank = 1 THEN rc.Party END) AS Winning_Party,
	MAX(CASE WHEN rc.Rank = 2 THEN rc.Candidate END) AS Runnerup_Candidate,
	MAX(CASE WHEN rc.Rank = 2 THEN rc.Party END) AS Runnerup_Party
FROM 
	constituencywise_results AS cr
INNER JOIN 
	Ranked_Candidates AS rc
	ON rc.Constituency_ID = cr.Constituency_ID
GROUP BY 
	cr.Constituency_Name
ORDER BY
	cr.Constituency_Name


-- Statewise Details
SELECT
	s.State,
	COUNT(DISTINCT cd.Constituency_ID) AS Total_Seats,
	COUNT(DISTINCT cd.Candidate) AS Total_Candidates,
	COUNT(DISTINCT cd.Party) AS Total_Parties,
	SUM(cd.Total_Votes) AS Total_Votes
FROM
	constituencywise_details AS cd
INNER JOIN
	constituencywise_results AS cr
	ON cr.Constituency_ID = cd.Constituency_ID
INNER JOIN
	statewise_results AS sr
	ON sr.Parliament_Constituency = cr.Parliament_Constituency
INNER JOIN
	states AS s
	ON s.State_ID = sr.State_ID
INNER JOIN 
	partywise_results AS p
	ON p.Party_ID = cr.Party_ID
WHERE 
	cd.Party <> 'None of the Above'
GROUP BY 
	s.State
ORDER BY Total_Votes DESC