UPDATE edw.map_inventory b
left JOIN 
(SELECT DISTINCT cinvcode
FROM pdm.outdepot_order
WHERE TIMESTAMPDIFF(MONTH,ddate,now())<=18 and cinvcode is NOT NULL
UNION
SELECT DISTINCT cinvcode
FROM pdm.invoice_order
WHERE TIMESTAMPDIFF(MONTH,ddate,now())<=18 and cinvcode is NOT NULL
UNION 
SELECT DISTINCT cinvcode
FROM pdm.dispatch_order
WHERE TIMESTAMPDIFF(MONTH,ddate,now())<=18 and cinvcode is NOT NULL)a
ON a.cinvcode=b.bi_cinvcode
SET availability=IF(a.cinvcode is null,"不可用","可用" )
WHERE b.business_class<>'LDT';
