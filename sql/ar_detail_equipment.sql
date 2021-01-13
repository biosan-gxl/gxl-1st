#修改日期范围，即可得到每个季度的设备回款，需要改日期范围表shujuzu.ar_detail_equipment0、shujuzu.ar_detail_equipment2
#应收类型是设备或者设备租赁的关联id
DROP TABLE if EXISTS shujuzu.ar_detail_equipment0 ;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment0 as 
SELECT ccovouchid
FROM pdm.ar_detail
WHERE date_ap >= '2020-01-01' and date_ap <= '2020-12-31' AND (ar_class ='设备' or cinvcode = 'QT00005' or cinvcode = 'QT01010')
GROUP BY ccovouchid
Having SUM(icamount)>0
;

#应收数据
DROP TABLE if EXISTS shujuzu.ar_detail_equipment1;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment1 as 
SELECT 
     a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new  #这个销售区域是直接客户的销售区域
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid
     ,a.date_ar 
     ,a.idamount
FROM pdm.ar_detail a
RIGHT JOIN shujuzu.ar_detail_equipment0 b
ON a.ccovouchid = b.ccovouchid
WHERE a.ar_ap = 'ar' AND (ar_class ='设备' or cinvcode = 'QT00005' or cinvcode = 'QT01010')
;
#回款数据
DROP TABLE if EXISTS shujuzu.ar_detail_equipment2;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment2 as 
SELECT 
     a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid
		 ,a.date_ap 
     ,a.icamount 
FROM pdm.ar_detail a
RIGHT JOIN shujuzu.ar_detail_equipment0 b
ON a.ccovouchid = b.ccovouchid
WHERE a.ar_ap = 'ap' AND (ar_class ='设备' or cinvcode = 'QT00005' or cinvcode = 'QT01010') and a.date_ap >= '2020-01-01' and a.date_ap <= '2020-12-31'
;


#应收和回款联合

DROP TABLE if EXISTS shujuzu.ar_detail_equipment30;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment30 as 
SELECT 
     a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid as cvouchid_ar
     ,a.date_ar 
     ,a.idamount
		 ,b.cvouchid as cvouchid_ap
		 ,b.date_ap 
     ,b.icamount
 FROM shujuzu.ar_detail_equipment1 a
 LEFT JOIN shujuzu.ar_detail_equipment2  b
 ON a.ccovouchid = b.ccovouchid and a.cinvcode = b.cinvcode
 ;
DROP TABLE if EXISTS shujuzu.ar_detail_equipment3;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment3 as 
SELECT a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid_ar
     ,a.date_ar 
     ,a.idamount
		 ,a.cvouchid_ap
		 ,a.date_ap 
     ,a.icamount
FROM shujuzu.ar_detail_equipment30 a
UNION
SELECT 
     a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,null as cvouchid_ar
     ,null as date_ar 
     ,null as idamount
		 ,a.cvouchid as cvouchid_ap
		 ,a.date_ap 
     ,a.icamount
 FROM shujuzu.ar_detail_equipment2 a
 WHERE a.cinvcode is null #补充上产品编码是空的回款类型
 ;
 
#为了根据ccovouchid排序，ccovouchid是根据回款日期增序的
set @n = 0;
DROP TABLE if EXISTS shujuzu.ar_detail_id;
CREATE TEMPORARY TABLE shujuzu.ar_detail_id as
SELECT (@n := @n + 1) as id,ccovouchid
FROM 
    (SELECT ccovouchid
    FROM shujuzu.ar_detail_equipment2 
    GROUP BY ccovouchid 
    ORDER BY date_ap)a;

DROP TABLE if EXISTS shujuzu.ar_detail_equipment4;
CREATE TEMPORARY TABLE shujuzu.ar_detail_equipment4 as 
SELECT 
     a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid_ar
     ,a.date_ar 
     ,a.idamount
		 ,a.cvouchid_ap
		 ,a.date_ap 
     ,a.icamount
FROM shujuzu.ar_detail_equipment3 a
LEFT JOIN shujuzu.ar_detail_id b
ON a.ccovouchid = b.ccovouchid
ORDER BY b.id
; 
#补充最终客户，仅供参考
DROP TABLE if EXISTS shujuzu.ar_detail_equipment;
CREATE  TABLE shujuzu.ar_detail_equipment as 
SELECT 
     a.ccovouchid
     ,a.cohr 
     ,a.sales_region_new
     ,a.sales_dept
     ,a.ccusname
		 ,b.finnal_ccusname
     ,a.cinvcode
		 ,c.bi_cinvname
     ,a.ar_class 
     ,a.cdigest
     ,a.cvouchid_ar
     ,a.date_ar 
     ,a.idamount
		 ,a.cvouchid_ap
		 ,a.date_ap 
     ,a.icamount
		 ,c.equipment
FROM shujuzu.ar_detail_equipment4 a
LEFT JOIN 
         (SELECT ccusname
         ,finnal_ccusname
         ,cinvcode
         FROM pdm.invoice_order a
         WHERE ddate >= '2019-01-01' and cinvcode like 'YQ%'
         GROUP BY ccusname,cinvcode)b #一个客户有多个最终客户的情况，任意取一个
ON a.cinvcode  = b.cinvcode and a.ccusname = b.ccusname
LEFT JOIN edw.map_inventory c
ON a.cinvcode = c.bi_cinvcode
;
#回款额复核
SELECT sum(icamount)
FROM shujuzu.ar_detail_equipment2;
SELECT sum(icamount)
FROM shujuzu.ar_detail_equipment
;
#删除非设备的和杭州贝生的
DELETE
FROM shujuzu.ar_detail_equipment
WHERE equipment = '否' or cohr = '杭州贝生'
;
#删除字段是否设备，无其他用途
ALTER TABLE shujuzu.ar_detail_equipment DROP COLUMN equipment;
