
/*CREATE TABLE cinv_price_out_checklist(
sales_region_new	varchar(20)  comment '销售区域',
cusname	varchar(60) comment '客户名称',
cinvcode	varchar(20) comment '产品编码',
cinvname	varchar(60) comment '产品名称',
item_name	varchar(20) comment '项目名称',
ddate	date comment '日期',
invoice_price_person	mediumtext comment '开票人分价',
invoice_iquantity_person	decimal comment '开票价为非0的开票人分数',
invoice_iquantity_person0 decimal comment '开票价为0的开票人分数',
isum	decimal comment '开票额',
out_inum_person	decimal comment '出库人份数',
contract_price_person	mediumtext comment '合同人份价',
checklist	decimal comment '项目检测量',
beizhu varchar(60) comment '是否按检测量开票的备注');*/


#客户每月的开票人份数、开票人份单价、开票额
DROP TABLE if EXISTS shujuzu.invoice01;
CREATE TEMPORARY TABLE  shujuzu.invoice01 as 
SELECT 
     a.sales_region_new
     ,a.finnal_ccuscode as cuscode
     ,a.finnal_ccusname as cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.citemname as item_name
     ,DATE_FORMAT(a.ddate,'%Y-%m-01') as ddate
     ,cast(a.itaxunitprice/b.inum_unit_person as decimal(10,1)) as invoice_price_person
     ,a.iquantity*b.inum_unit_person as invoice_iquantity_person
     ,a.isum
FROM pdm.invoice_order a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
WHERE  citemname REGEXP 'CMA|NIPT|BoBs' and cbustype = '产品类'
;

DROP TABLE if EXISTS shujuzu.invoice02;
CREATE TEMPORARY TABLE  shujuzu.invoice02 as 
SELECT 
     a.sales_region_new
     ,CONCAT(cuscode,cinvcode) as concatid 
     ,a.cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.item_name
     ,a.ddate
     ,GROUP_CONCAT( DISTINCT invoice_price_person) as invoice_price_person
     ,sum(invoice_iquantity_person) as invoice_iquantity_person
     ,sum(a.isum) as isum
FROM shujuzu.invoice01 a
GROUP BY cusname,cinvcode,ddate
;

#开票价为0的开票人份数，目的是按检测量开票的情况，有的是浪费掉的，肯定是按0开票，检测量-非0的开票数量=未开票数量
DROP TABLE if EXISTS shujuzu.invoice03;
CREATE TEMPORARY TABLE  shujuzu.invoice03 as 
SELECT 
       a.sales_region_new
      ,CONCAT(cuscode,cinvcode) as concatid
      ,a.cusname
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,a.ddate
      ,sum(invoice_iquantity_person) as invoice_iquantity_person0
FROM shujuzu.invoice01 a
WHERE invoice_price_person = 0
GROUP BY cusname,cinvcode,ddate
;

/*复核
SELECT sum(isum)
FROM shujuzu.invoice01;
SELECT sum(isum)
FROM shujuzu.invoice02;*/

#客户产品每月的发货量（出库）
DROP TABLE if EXISTS shujuzu.out_depot0; 
CREATE TEMPORARY TABLE  shujuzu.out_depot0 as 
SELECT 
     a.sales_region_new
     ,a.finnal_ccuscode as cuscode
     ,a.finnal_ccusname as cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.citemname as item_name
     ,DATE_FORMAT(a.ddate,'%Y-%m-01') as ddate
     ,inum_person as out_inum_person
FROM pdm.outdepot_order a
WHERE citemname REGEXP 'CMA|NIPT|BoBs' and cbustype = '产品类'
;

DROP TABLE if EXISTS shujuzu.out_depot1;
CREATE TEMPORARY TABLE  shujuzu.out_depot1 as 
SELECT 
     a.sales_region_new
     ,CONCAT(cuscode,cinvcode) as concatid
     ,a.cuscode
     ,a.cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.item_name
     ,a.ddate
     ,sum(a.out_inum_person) as out_inum_person
FROM shujuzu.out_depot0 a
GROUP BY cusname,cinvcode,ddate
;

#客户项目检测量
DROP TABLE if EXISTS shujuzu.checklist0;
CREATE TEMPORARY TABLE  shujuzu.checklist0 as 
SELECT 
     b.sales_region_new
     ,b.province
     ,b.city
     ,ccusname
     ,item_name
     ,ddate
     ,inum_person
FROM pdm.checklist a
LEFT JOIN edw.map_customer b
ON a.ccusname = b.bi_cusnameWHERE  item_name REGEXP 'CMA|NIPT|BoBs' and cbustype = '产品类'
;

#送检地市,送样医院检测量
DROP TABLE if EXISTS shujuzu.checklist1;
CREATE TEMPORARY TABLE  shujuzu.checklist1 as
SELECT  
     a.sales_region_new
     ,a.province
     ,a.city
     ,a.ccusname
     ,a.item_name
     ,a.ddate
     ,a.inum_person
     ,b.finnal_cusname
     ,b.city_get
FROM shujuzu.checklist0 a
LEFT JOIN edw.x_ccus_delivery b
ON a.item_name = b.item_name and a.city = b.county
WHERE b.item_name is not null and b.county is not null
;

#对于CRM上只填本院数据的客户项目，在原有的基础上要补充送样医院的数据
DROP TABLE if EXISTS shujuzu.checklist2;
CREATE TEMPORARY TABLE  shujuzu.checklist2 as
SELECT sales_region_new
      ,a.province
      ,a.city
      ,a.finnal_cusname
      ,a.item_name
      ,a.ddate
      ,a.inum_person #通过送检关系得到的检测量，送样的检测量
FROM shujuzu.checklist1 a 
LEFT JOIN 
         (SELECT DISTINCT province_get,city_get,city_give,item_name,rules_crm 
         FROM report.new425_02_delivery WHERE rules_crm = 'CRM填本院') b
ON a.city_get = b.city_get and a.item_name = b.item_name
WHERE b.city_get is not null and b.item_name is not null
;

#对于CRM上只填本院的情况，补充上送检医院的检测量
DROP TABLE if EXISTS shujuzu.checklist3;
CREATE TEMPORARY TABLE  shujuzu.checklist3 as
SELECT 
     a.sales_region_new
     ,a.province
     ,a.city
     ,a.ccusname
     ,a.item_name
     ,a.ddate
     ,sum(a.inum_person) as inum_person
FROM 
     (SELECT  a.sales_region_new,a.province,a.city,a.ccusname,a.item_name,a.ddate,a.inum_person #CRM上填的收样医院的检测量，有的是填本院，有的是填本院+送样医院
     FROM shujuzu.checklist0 a
     LEFT JOIN edw.x_ccus_delivery b
     ON a.item_name = b.item_name and a.city = b.county
     WHERE b.item_name is null and b.county is null
     union 
     SELECT sales_region_new,a.province,a.city,a.finnal_cusname,a.item_name,a.ddate,a.inum_person #通过送检关系得到的检测量，送样的检测量
     FROM shujuzu.checklist2 a)a
GROUP BY a.ccusname,a.item_name,a.ddate
;


#客户产品合同价格
DROP TABLE if EXISTS shujuzu.contract_price0;
CREATE TEMPORARY TABLE  shujuzu.contract_price0 as
SELECT 
     a.finnal_ccuscode as cuscode
     ,a.finnal_ccusname as cusname
     ,a.cinvcode 
     ,a.cinvname 
     ,cast( a.new_itaxprice/b.inum_unit_person as DECIMAL(10,1)) as contract_price_person   
FROM  edw.crm_contract a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
WHERE b.level_three REGEXP 'CMA|NIPT|BoBs'
;

DROP TABLE if EXISTS shujuzu.contract_price1; 
CREATE TEMPORARY TABLE  shujuzu.contract_price1 as
SELECT  
     CONCAT(cuscode,cinvcode) as concatid
     ,cuscode
     ,cusname
     ,cinvcode
     ,cinvname
     ,GROUP_CONCAT(DISTINCT contract_price_person) as contract_price_person  
FROM shujuzu.contract_price0
GROUP BY cusname,cinvcode;

#有发货或者收入的客户产品
DROP TABLE if EXISTS shujuzu.cinv_price_out_checklist1;
CREATE TEMPORARY TABLE  shujuzu.cinv_price_out_checklist1 as
SELECT 
      a.sales_region_new
      ,concatid
      ,a.cusname
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,a.ddate
FROM shujuzu.invoice02 a
UNION
SELECT a.sales_region_new a
      ,concatid
      ,a.cusname
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,a.ddate
FROM shujuzu.out_depot1 a;  


DROP TABLE if EXISTS shujuzu.cinv_price_out_checklist2;
CREATE TEMPORARY TABLE  shujuzu.cinv_price_out_checklist2 as
SELECT  
     a.sales_region_new
     ,a.concatid
     ,a.cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.item_name
     ,a.ddate
     ,b.invoice_price_person
     ,b.invoice_iquantity_person
     ,b.isum
     ,c.out_inum_person
     ,d.contract_price_person
FROM shujuzu.cinv_price_out_checklist1 a
LEFT JOIN shujuzu.invoice02 b
ON a.concatid = b.concatid and a.ddate = b.ddate
LEFT JOIN shujuzu.out_depot1 c
ON a.concatid = c.concatid and a.ddate = c.ddate
LEFT JOIN shujuzu.contract_price1 d
ON a.concatid = d.concatid 
;

DROP TABLE if EXISTS shujuzu.cinv_price_out_checklist03;
CREATE TEMPORARY TABLE  shujuzu.cinv_price_out_checklist03 as
SELECT 
     a.sales_region_new
     ,a.concatid
     ,a.cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.item_name
     ,a.ddate
     ,invoice_price_person
     ,cast(a.invoice_iquantity_person as DECIMAL(10,1)) as invoice_iquantity_person 
     ,cast(a.isum as DECIMAL(10,1)) as isum
     ,cast(a.out_inum_person as decimal(10,1)) as out_inum_person
     ,a.contract_price_person
     ,b.inum_person as checklist
FROM shujuzu.cinv_price_out_checklist2 a
LEFT JOIN shujuzu.checklist3 b
ON a.cusname = b.ccusname and a.item_name = b.item_name and a.ddate = b.ddate
;

DROP TABLE if EXISTS shujuzu.cinv_price_out_checklist4;
CREATE TEMPORARY TABLE  shujuzu.cinv_price_out_checklist4 as
SELECT 
     b.sales_region_new
     ,b.ccusname
     ,b.item_name
     ,b.ddate
     ,b.inum_person
FROM shujuzu.cinv_price_out_checklist03 a
RIGHT JOIN shujuzu.checklist3 b
ON a.cusname = b.ccusname and a.item_name = b.item_name and a.ddate = b.ddate
WHERE a.cusname is null and a.item_name is null and a.ddate is null
;

DROP TABLE if EXISTS shujuzu.cinv_price_out_checklist3;
CREATE TEMPORARY TABLE  shujuzu.cinv_price_out_checklist3 as
SELECT 
     a.sales_region_new
     ,a.concatid
     ,a.cusname
     ,a.cinvcode
     ,a.cinvname
     ,a.item_name
     ,a.ddate
     ,a.invoice_price_person
     ,a.invoice_iquantity_person
     ,a.isum
     ,a.out_inum_person
     ,a.contract_price_person
     ,a.checklist
     ,b.invoice_iquantity_person0
FROM shujuzu.cinv_price_out_checklist03 a
LEFT JOIN shujuzu.invoice03 b
ON a.cusname = b.cusname and a.cinvcode = b.cinvcode and a.ddate = b.ddate
;

truncate table shujuzu.cinv_price_out_checklist;

INSERT INTO  shujuzu.cinv_price_out_checklist 
SELECT *
FROM 
    (SELECT a.sales_region_new
    ,a.cusname
    ,a.cinvcode
    ,a.cinvname
    ,a.item_name
    ,a.ddate
    ,a.invoice_price_person
    ,ROUND(a.invoice_iquantity_person-if(a.invoice_iquantity_person0 is null,0,a.invoice_iquantity_person0)) as invoice_iquantity_person
    ,ROUND(a.invoice_iquantity_person0) as invoice_iquantity_person0
    ,a.isum
    ,a.out_inum_person
    ,a.contract_price_person
    ,a.checklist
    ,null
FROM shujuzu.cinv_price_out_checklist3 a
UNION 
SELECT sales_region_new,ccusname,'','',item_name,ddate,null,null,null,null,null,null,inum_person,null
FROM shujuzu.cinv_price_out_checklist4)a
ORDER BY cusname,item_name,ddate;

DELETE
FROM shujuzu.cinv_price_out_checklist
WHERE item_name like '%设备';

  update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='常德市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='常德市妇幼保健院' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='国药集团湖南省医疗器械有限公司' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='邵阳市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='湘潭市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='湘潭市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='益阳市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='岳阳市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='长沙市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='江苏恒龙生物科技有限公司' and item_name = 'BoBs';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='江苏恒龙生物科技有限公司' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='江苏恒龙生物科技有限公司' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='连云港市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='泰州市人民医院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='无锡市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='徐州市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='徐州市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='徐州市妇幼保健院' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='嘉兴市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='嘉兴市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='嘉兴市妇幼保健院' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='丽水市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='宁波市妇女儿童医院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='宁波市妇女儿童医院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='温州市中心医院' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='浙江大学医学院附属妇产科医院' and item_name = 'BoBs';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='浙江大学医学院附属妇产科医院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='浙江大学医学院附属妇产科医院' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='扬州市妇幼保健院' and item_name = 'CMA';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='嘉兴市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='绍兴市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.cinv_price_out_checklist set beizhu='按检测量开票' where cusname ='绍兴市妇幼保健院' and item_name = 'NIPT';

# 删除备注为空的，即仅保留按检测量开票的
DELETE 
FROM shujuzu.cinv_price_out_checklist
WHERE beizhu is null ;



SELECT sum(isum)
FROM shujuzu.invoice01;
SELECT sum(out_inum_person)
FROM shujuzu.out_depot0;
SELECT sum(isum),sum(out_inum_person)
FROM shujuzu.cinv_price_out_checklist3