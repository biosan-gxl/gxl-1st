UPDATE contract_standad a
LEFT JOIN
(SELECT a.*,e.month_YTD_1,e.date_1st_1,e.inum_person_YTD_1
FROM contract_standad a
LEFT JOIN
(SELECT b.strcontractid,b.content,c.date_1st_1,c.month_YTD_1,sum(b.inum_person_out) inum_person_YTD_1
FROM contract_actual b
LEFT JOIN 
(SELECT b.strcontractid,b.content,min(b.y_mon) as date_1st_1,IF(TIMESTAMPDIFF(MONTH,min(b.y_mon),now())>a.assess_mon,a.assess_mon,TIMESTAMPDIFF(MONTH,min(b.y_mon),now())) as month_YTD_1
FROM contract_standad a
LEFT JOIN contract_actual b
ON a.strcontractid= b.strcontractid AND a.content=b.content
WHERE date_format(b.y_mon,'%Y-%m')>=date_format(a.strcontractstartdate,'%Y-%m')
GROUP BY b.strcontractid,b.content)c
ON c.strcontractid= b.strcontractid AND c.content=b.content
WHERE b.y_mon>=c.date_1st_1 AND TIMESTAMPDIFF(MONTH,c.date_1st_1,b.y_mon)<=c.month_YTD_1
GROUP BY b.strcontractid,b.content)e
ON a.strcontractid= e.strcontractid AND a.content=e.content)f
ON a.strcontractid= f.strcontractid AND a.content=f.content
SET a.month_YTD=f.month_YTD_1, a.inum_person_YTD=f.inum_person_YTD_1,a.date_1st=f.date_1st_1;

UPDATE contract_standad a
SET rate_reach = NULL


UPDATE contract_standad a
SET rate_reach = 
CASE WHEN standard_classify='数量' THEN(CASE  WHEN standard_1st is NULL THEN inum_person_YTD/(standard_total/assess_mon*month_YTD)
	WHEN month_YTD<=12 THEN inum_person_YTD/(standard_1st/12*month_YTD)
	WHEN month_YTD>12 AND month_YTD<=24 THEN inum_person_YTD/(standard_1st+standard_2nd/12*(month_YTD-12))
	WHEN month_YTD>24 AND month_YTD<=36 THEN inum_person_YTD/(standard_1st+standard_2nd+standard_3rd/12*(month_YTD-24))
	WHEN month_YTD>36 AND month_YTD<=48 THEN inum_person_YTD/(standard_1st+standard_2nd+standard_3rd+standard_4th/12*(month_YTD-36))
	WHEN month_YTD>48 AND month_YTD<=60 THEN inum_person_YTD/(standard_1st+standard_2nd+standard_3rd+standard_4th+standard_5th/12*(month_YTD-48))
	ELSE NULL END)
ELSE NULL END;

UPDATE contract_standad a
LEFT JOIN 
(SELECT a.bi_cusname,SUM(g.inum_person) as TSH_YTD_1
FROM contract_standad a
LEFT JOIN tsh_modified g
ON a.bi_cusname=g.ccusname
WHERE g.ddate>=a.date_1st AND TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)<=a.assess_mon
GROUP BY a.bi_cusname)h
ON a.bi_cusname=h.bi_cusname
SET a.TSH_YTD=h.TSH_YTD_1;

UPDATE contract_standad 
SET rate_reach = NULL
WHERE standard_classify='筛查率'

UPDATE contract_standad 
SET rate_reach = 
CASE WHEN standard_classify='筛查率' 
		 THEN(CASE  WHEN month_YTD<=12 THEN (inum_person_YTD/TSH_YTD)/standard_1st
								WHEN month_YTD>12 AND month_YTD<=24 THEN (inum_person_YTD/TSH_YTD)/((standard_1st*12+standard_2nd*(month_YTD-12))/month_YTD)
								WHEN month_YTD>24 AND month_YTD<=36 THEN (inum_person_YTD/TSH_YTD)/((standard_1st*12+standard_2nd*12+standard_3rd*(month_YTD-24))/month_YTD)
								WHEN month_YTD>36 AND month_YTD<=48 THEN (inum_person_YTD/TSH_YTD)/((standard_1st*12+standard_2nd*12+standard_3rd*12+standard_4th*(month_YTD-36))/month_YTD)
								WHEN month_YTD>48 AND month_YTD<=60 THEN (inum_person_YTD/TSH_YTD)/((standard_1st*12+standard_2nd*12+standard_3rd*12+standard_4th*12+standard_5th*(month_YTD-48))/month_YTD)
								ELSE NULL END)
ELSE rate_reach END,reach=IF(rate_reach>=1,'达标','未达标');


UPDATE contract_standad a
LEFT JOIN
(SELECT a.strcontractid,a.content,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1<=12 THEN inum_person_out ELSE 0 END) AS a_1st,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1>12 AND TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1<=24 THEN inum_person_out ELSE 0 END) AS a_2nd,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1>24 AND TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1<=36 THEN inum_person_out ELSE 0 END) AS a_3rd,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1>36 AND TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1<=48 THEN inum_person_out ELSE 0 END) AS a_4th,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1>48 AND TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1<=60 THEN inum_person_out ELSE 0 END) AS a_5th,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1>60 AND TIMESTAMPDIFF(MONTH,a.date_1st,b.y_mon)+1<=72 THEN inum_person_out ELSE 0 END) AS a_6th
FROM contract_standad a
LEFT JOIN contract_actual b
ON a.strcontractid= b.strcontractid AND a.content=b.content
WHERE b.y_mon>=a.date_1st 
GROUP BY a.strcontractid,a.content)i
ON a.strcontractid= i.strcontractid AND a.content=i.content
SET actual_1st=a_1st,actual_2nd=a_2nd,actual_3rd=a_3rd,actual_4th=a_4th,actual_5th=a_5th,actual_6th=a_6th


UPDATE contract_standad a
LEFT JOIN
(SELECT a.strcontractid,a.content,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1<=12 THEN g.inum_person ELSE 0 END) AS tsh_1st,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1>12 AND TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1<=24 THEN g.inum_person ELSE 0 END) AS tsh_2nd,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1>24 AND TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1<=36 THEN g.inum_person ELSE 0 END) AS tsh_3rd,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1>36 AND TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1<=48 THEN g.inum_person ELSE 0 END) AS tsh_4th,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1>48 AND TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1<=60 THEN g.inum_person ELSE 0 END) AS tsh_5th,
sum(CASE WHEN TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1>60 AND TIMESTAMPDIFF(MONTH,a.date_1st,g.ddate)+1<=72 THEN g.inum_person ELSE 0 END) AS tsh_6th
FROM contract_standad a
LEFT JOIN tsh_modified g
ON a.bi_cusname=g.ccusname
WHERE g.ddate>=a.date_1st 
GROUP BY g.ccusname)j
ON a.strcontractid= j.strcontractid AND a.content=j.content
SET a.actual_1st = a.actual_1st/j.tsh_1st,a.actual_2nd = a.actual_2nd/j.tsh_2nd,a.actual_3rd=a.actual_3rd/j.tsh_3rd,a.actual_4th=a.actual_4th/j.tsh_4th,a.actual_5th=a.actual_5th/j.tsh_4th,a.actual_6th=a.actual_6th/j.tsh_6th
WHERE standard_classify='筛查率'  



















