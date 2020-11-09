#已发货未开票的跟踪
DROP TABLE if EXISTS shujuzu.contract_price0;
CREATE TEMPORARY TABLE   shujuzu.contract_price0 as
SELECT a.finnal_ccuscode as cuscode
      ,a.finnal_ccusname as cusname
      ,a.cinvcode 
      ,a.cinvname 
      ,a.new_cdefine12 as cdefine12
      ,a.new_name as strcontractid
      ,a.new_dstartdate as strcontractstartdate
      ,cast( a.new_itaxprice/b.inum_unit_person as DECIMAL(10,1)) as contract_price_person    
FROM  edw.crm_contract a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
;

DROP TABLE if EXISTS shujuzu.contract_price1;
CREATE TEMPORARY TABLE   shujuzu.contract_price1 as
SELECT  CONCAT(cuscode,cinvcode) as concatid
       ,cuscode
       ,cusname
       ,cinvcode
       ,cinvname
       ,strcontractid
       ,strcontractstartdate
       ,cdefine12
       ,max(contract_price_person) as contract_price_person  
FROM shujuzu.contract_price0
WHERE cuscode is not null and cinvcode is not null and cinvcode <>'请核查'
GROUP BY cusname,cinvcode,strcontractstartdate
; #避免一个合同里有2个个产品价格

#求每个客户产品同一个合同里的最大价格，避免一个合同两份价格的情况

CREATE index index_contract_price1_cuscode on shujuzu.contract_price1(cuscode);
CREATE index index_contract_price1_cinvcode on shujuzu.contract_price1(cinvcode);

#求每个客户产品的最新日期
DROP TABLE if EXISTS shujuzu.contract_price2;
CREATE TEMPORARY TABLE   shujuzu.contract_price2 as
SELECT concatid
				,max(strcontractstartdate) as star_max 
FROM shujuzu.contract_price1
GROUP BY concatid
;

#在用合同价

#最新价格（若有两个价格，取价格较大的）
DROP TABLE if EXISTS shujuzu.contract_price3; 
CREATE TEMPORARY TABLE   shujuzu.contract_price3 as 
SELECT  a.concatid
       ,a.cuscode
       ,a.cusname
       ,a.cinvcode
       ,a.cinvname
       ,a.strcontractstartdate
       ,a.cdefine12
       ,a.contract_price_person as contract_price_person_new  
FROM shujuzu.contract_price1 a
LEFT JOIN shujuzu.contract_price2 b
ON a.concatid = b.concatid
WHERE a.strcontractstartdate = b.star_max
;

#最大价格
DROP TABLE if EXISTS shujuzu.contract_price4;
CREATE TEMPORARY TABLE   shujuzu.contract_price4 as
SELECT  concatid
       ,cuscode
       ,cusname
       ,cinvcode
       ,cinvname
       ,max(contract_price_person) as contract_price_person_max 
FROM shujuzu.contract_price1
GROUP BY concatid
;

DROP TABLE if EXISTS shujuzu.contract_price5;
CREATE TEMPORARY TABLE   shujuzu.contract_price5 as
SELECT a.cuscode
       ,a.cusname
       ,a.cinvcode
       ,a.cinvname
       ,a.strcontractstartdate
       ,a.cdefine12       ,a.contract_price_person_new
       ,b.contract_price_person_max
FROM shujuzu.contract_price3 a
LEFT JOIN shujuzu.contract_price4 b
ON a.concatid = b.concatid
;


#最后一次出库日期
DROP TABLE if EXISTS shujuzu.out_invoice2; 
CREATE TEMPORARY TABLE   shujuzu.out_invoice2 as 
SELECT finnal_ccusname as ccusname
      ,cinvcode
      ,max(ddate) as last_out_dt
      ,min(ddate) as first_out_dt
FROM pdm.outdepot_order
GROUP BY finnal_ccusname,cinvcode
;

#最后一次开票日期
DROP TABLE if EXISTS shujuzu.out_invoice3;
CREATE TEMPORARY TABLE   shujuzu.out_invoice3 as 
SELECT finnal_ccusname as ccusname
      ,cinvcode
      ,max(ddate) as last_invoice_dt
FROM pdm.invoice_order
GROUP BY finnal_ccusname,cinvcode
;
#关联已发货未开票的表
/*DROP TABLE if EXISTS shujuzu.out_invoice4;
CREATE TEMPORARY TABLE   shujuzu.out_invoice4 as
SELECT province,finnal_ccuscode,finnal_ccusname as ccusname,cinvcode,cinvname,price,sum(iquantity-isettlequantity) as iquantity_noinvoice,sum((iquantity-isettlequantity)*price) as isum_noinvoice
FROM pdm.out_inv_relation a
GROUP BY finnal_ccusname,cinvcode;*/

#因姜孙惠pdm.out_inv_relation里的价格使用直接客户匹配的，我们需要用最终客户匹配
DROP TABLE if EXISTS shujuzu.out_inv_relation1;
CREATE TEMPORARY TABLE   shujuzu.out_inv_relation1 as
SELECT a.db
       ,a.province
       ,a.ccusname
       ,a.ccuscode
       ,a.finnal_ccusname
       ,a.ddate
       ,a.cinvcode
       ,a.cinvname
       ,a.iquantity
       ,a.isettlequantity
       ,b.itaxunitprice as price
FROM pdm.out_inv_relation a
LEFT JOIN (SELECT * FROM pdm.invoice_price WHERE state = '最后一次价格') b
on a.finnal_ccusname = b.finnal_ccusname  and a.ccusname = b.ccusname and a.cinvcode = b.cinvcode
;#同一个直接客户有多个最终客户，同一个最终客户有多个直接客户，因此既要用直接客户匹配，又要用最终客户匹配

/*SELECT sum(iquantity)
FROM shujuzu.out_inv_relation1 a
WHERE a.ccuscode not like 'GL%';

SELECT sum(iquantity)
FROM pdm.out_inv_relation a
WHERE a.ccuscode not like 'GL%';*/





DROP TABLE if EXISTS shujuzu.out_invoice5;
CREATE TEMPORARY TABLE   shujuzu.out_invoice5 as
SELECT if(a.db='UFDATA_168_2019','杭州贝生','博圣体系') as cohr
      ,a.province
      ,a.ccusname
      ,a.finnal_ccusname
      ,a.ddate
      ,a.cinvcode
      ,a.cinvname
      ,price
      ,iquantity
      ,isettlequantity
      ,b.last_invoice_dt
      ,c.last_out_dt
      ,c.first_out_dt
FROM shujuzu.out_inv_relation1 a
LEFT JOIN shujuzu.out_invoice3 b
ON a.finnal_ccusname = b.ccusname and a.cinvcode = b.cinvcode  
LEFT JOIN shujuzu.out_invoice2 c
ON a.finnal_ccusname = c.ccusname and a.cinvcode = c.cinvcode 
WHERE a.ccuscode not like 'GL%'
;

DROP TABLE if EXISTS shujuzu.out_invoice6;
CREATE TEMPORARY TABLE   shujuzu.out_invoice6 as
SELECT a.*
      ,b.contract_price_person_new
      ,b.contract_price_person_max
      ,b.strcontractstartdate
      ,b.cdefine12
FROM shujuzu.out_invoice5 a
LEFT JOIN shujuzu.contract_price5 b
ON a.finnal_ccusname = b.cusname and a.cinvcode = b.cinvcode
; 


DROP TABLE if EXISTS shujuzu.out_invoice7;
CREATE TEMPORARY TABLE   shujuzu.out_invoice7 as
SELECT a.cohr
      ,a.province
      ,a.ccusname
      ,a.finnal_ccusname
      ,a.ddate
      ,a.cinvcode
      ,a.cinvname
      ,b.level_three as item_name
      ,price/b.inum_unit_person as person_price
      ,iquantity*b.inum_unit_person as iquantity_person 
      ,isettlequantity*b.inum_unit_person as isettlequantity_person
      ,a.last_invoice_dt
      ,a.last_out_dt
      ,a.first_out_dt
      ,a.contract_price_person_new
      ,a.contract_price_person_max
      ,a.strcontractstartdate
      ,a.cdefine12
FROM shujuzu.out_invoice6 a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
;

DROP TABLE if EXISTS shujuzu.out_invoice;
CREATE TABLE  shujuzu.out_invoice as
SELECT *
,case when contract_price_person_new= 0 and contract_price_person_max=0 and ddate >= strcontractstartdate then '合同签订价格为0'
      when contract_price_person_new= 0 and contract_price_person_max=0 and ddate < strcontractstartdate then '补签合同，价格为0'
      when contract_price_person_new= 0 and contract_price_person_max>0 and ddate >= strcontractstartdate then '之前有非0合同价，后签价格为0，该记录为补签之后'
      when contract_price_person_new= 0 and contract_price_person_max>0 and ddate < strcontractstartdate then '之前有非0合同价，后补签价格为0，该记录为补签之前' 
			when person_price is null  and last_invoice_dt is null and contract_price_person_new is null then '无合同，且从未开票' end as beizhu
FROM shujuzu.out_invoice7 a;


#按检测量开票的备注
update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='常德市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='常德市妇幼保健院' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='国药集团湖南省医疗器械有限公司' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='邵阳市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='湘潭市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='湘潭市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='益阳市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='岳阳市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='长沙市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='江苏恒龙生物科技有限公司' and item_name = 'BoBs';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='江苏恒龙生物科技有限公司' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='江苏恒龙生物科技有限公司' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='连云港市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='泰州市人民医院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='无锡市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='徐州市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='徐州市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='徐州市妇幼保健院' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='嘉兴市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='嘉兴市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='嘉兴市妇幼保健院' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='丽水市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='宁波市妇女儿童医院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='宁波市妇女儿童医院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='温州市中心医院' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='浙江大学医学院附属妇产科医院' and item_name = 'BoBs';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='浙江大学医学院附属妇产科医院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='浙江大学医学院附属妇产科医院' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='扬州市妇幼保健院' and item_name = 'CMA';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='嘉兴市妇幼保健院' and item_name = 'NIPT';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='绍兴市妇幼保健院' and item_name = 'BoBs';
 update shujuzu.out_invoice set beizhu='按检测量开票' where finnal_ccusname ='绍兴市妇幼保健院' and item_name = 'NIPT';

#更新最后一次开票价，孙惠加工的最后一次价格是非0价格，如果有开票，但一直是开票价为0，则将最后一次开票价更新为0
UPDATE shujuzu.out_invoice set person_price = 0 WHERE person_price is null and last_invoice_dt is not null;


#复核
SELECT sum(iquantity_person)
FROM shujuzu.out_invoice;
SELECT sum(iquantity*b.inum_unit_person)
FROM pdm.out_inv_relation a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
WHERE ccuscode not like 'GL%';















