#18个月内有过出库、开票、发货记录的非LDT产品定义为可用产品
#LDT产品是否可用根据线下复核的定
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
