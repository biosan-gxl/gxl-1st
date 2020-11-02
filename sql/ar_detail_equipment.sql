DROP TABLE if EXISTS shujuzu.ar_detail_equipment1;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment1 as 
SELECT 
     ccovouchid
     ,a.ar_ap 
     ,a.cohr 
     ,sales_region_new
     ,sales_dept
     ,ccusname
     ,cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid
     ,a.date_ar 
     ,a.idamount
     ,a.date_ap 
     ,a.icamount 
FROM pdm.ar_detail a
WHERE ccovouchid IN
                   (SELECT ccovouchid
										FROM pdm.ar_detail
										WHERE date_ap >= '2020-01-01' and date_ap <= '2020-09-30'
										GROUP BY ccovouchid
										Having SUM(icamount)>0)															
			AND (ar_class ='设备' or cinvcode = 'QT00005' or cinvcode = 'QT01010') #设备租赁
;

DROP TABLE if EXISTS shujuzu.ar_detail_equipment2;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment2 as 
SELECT ccovouchid
FROM shujuzu.ar_detail_equipment1
WHERE date_ar <='2019-01-01'
GROUP BY ccovouchid
;

DROP TABLE if EXISTS shujuzu.ar_detail_equipment3; 
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment3 as 
SELECT a.ccovouchid
       ,a.ar_ap 
       ,a.cohr 
       ,sales_region_new
       ,sales_dept
       ,ccusname
       ,cinvcode
       ,c.bi_cinvname
       ,c.equipment
       ,a.ar_class 
       ,a.cdigest
       ,a.cvouchid
       ,a.date_ar 
       ,a.idamount
       ,a.date_ap 
       ,a.icamount 
FROM shujuzu.ar_detail_equipment1 a
LEFT JOIN shujuzu.ar_detail_equipment2 b
On a.ccovouchid = b.ccovouchid
LEFT JOIN edw.map_inventory c
ON a.cinvcode = c.bi_cinvcode
WHERE b.ccovouchid is null
;


DROP TABLE if EXISTS shujuzu.ar_detail_equipment;
CREATE  TABLE shujuzu.ar_detail_equipment as
SELECT a.ccovouchid
      ,a.ar_ap 
      ,a.cohr 
      ,sales_region_new
      ,sales_dept
      ,a.ccusname
      ,b.finnal_ccusname
      ,a.cinvcode
      ,a.bi_cinvname
      ,a.equipment
      ,a.ar_class 
      ,a.cdigest
      ,a.cvouchid
      ,a.date_ar 
      ,a.idamount
      ,a.date_ap 
      ,a.icamount 
FROM shujuzu.ar_detail_equipment3 a
LEFT JOIN 
         (SELECT ccusname
         ,finnal_ccusname
         ,cinvcode
         FROM pdm.invoice_order a
         WHERE ddate >= '2019-01-01' and cinvcode like 'YQ%'
         GROUP BY ccusname,finnal_ccusname,cinvcode)b
ON a.cinvcode  = b.cinvcode and a.ccusname = b.ccusname
;

DELETE
FROM shujuzu.ar_detail_equipment
WHERE cohr = '杭州贝生' or equipment = '否' or date_ap <= '2020-01-01';
