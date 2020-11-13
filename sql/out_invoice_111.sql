
#匹配产品档案，得产品的人份数，目的是得到产品的人份单价，同时清洗产品编码
DROP TABLE if EXISTS shujuzu.contract_price0;
CREATE  TEMPORARY TABLE   shujuzu.contract_price0 as
SELECT a.bi_ccuscode
			,a.bi_ccusname
      ,a.finnal_ccuscode 
      ,a.finnal_ccusname 
      ,b.bi_cinvcode as cinvcode
      ,b.bi_cinvname as cinvname 
      ,a.new_cdefine12 as cdefine12
      ,a.new_name as strcontractid
      ,a.new_dstartdate as strcontractstartdate
	  ,a.statuscode
      ,cast( a.new_itaxprice/b.inum_unit_person as DECIMAL(10,1)) as contract_price_person    
FROM  db_111.crm_contract a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
;
#按照直接客户、最终客户、产品编码、合同起始日期分组，求同一个合同里的产品最大价格，避免一个合同两份价格的情况
DROP TABLE if EXISTS shujuzu.contract_price1;
CREATE  TEMPORARY TABLE   shujuzu.contract_price1 as
SELECT  a.bi_ccuscode
			 ,a.bi_ccusname
       ,a.finnal_ccuscode 
       ,a.finnal_ccusname
       ,cinvcode
       ,cinvname
       ,strcontractid
       ,strcontractstartdate
       ,cdefine12
	   ,a.statuscode
       ,max(contract_price_person) as contract_price_person  
FROM shujuzu.contract_price0 a
WHERE a.bi_ccuscode is not null  and a.finnal_ccuscode is not null and cinvcode is not null and cinvcode <>'请核查'
GROUP BY a.bi_ccusname,a.finnal_ccusname,cinvcode,strcontractstartdate
; 

CREATE index index_contract_price1_ccuscode on shujuzu.contract_price1(bi_ccuscode);
CREATE index index_contract_price1_finnal_ccuscode on shujuzu.contract_price1(finnal_ccuscode);
CREATE index index_contract_price1_cinvcode on shujuzu.contract_price1(cinvcode);

#求每个客户产品的最新合同日期日期
DROP TABLE if EXISTS shujuzu.contract_price2;
CREATE  TEMPORARY TABLE   shujuzu.contract_price2 as
SELECT a.bi_ccusname,a.finnal_ccusname,cinvcode
				,max(strcontractstartdate) as star_max 
FROM shujuzu.contract_price1 a
GROUP BY  a.bi_ccusname,a.finnal_ccusname,cinvcode
;


#最新价格（若有两个价格，取价格较大的）
DROP TABLE if EXISTS shujuzu.contract_price3; 
CREATE  TEMPORARY TABLE   shujuzu.contract_price3 as 
SELECT   a.bi_ccuscode
			 ,a.bi_ccusname
       ,a.finnal_ccuscode 
       ,a.finnal_ccusname
       ,a.cinvcode
       ,a.cinvname
       ,a.strcontractstartdate
       ,a.cdefine12
       ,a.contract_price_person as contract_price_person_new  
FROM shujuzu.contract_price1 a
LEFT JOIN shujuzu.contract_price2 b
ON a.bi_ccusname = b.bi_ccusname and a.finnal_ccusname = b.finnal_ccusname and a.cinvcode = b.cinvcode
WHERE a.strcontractstartdate = b.star_max
;
create  index index_contract_price3_bi_ccusname on shujuzu.contract_price3(bi_ccusname);
create  index index_contract_price3_finnal_ccusname on shujuzu.contract_price3(finnal_ccusname);
create  index index_contract_price3_cinvcode on shujuzu.contract_price3(cinvcode);
#求最大价格
DROP TABLE if EXISTS shujuzu.contract_price4;
CREATE  TEMPORARY TABLE   shujuzu.contract_price4 as
SELECT  a.bi_ccuscode
		,a.bi_ccusname
       ,a.finnal_ccuscode 
       ,a.finnal_ccusname
       ,cinvcode
       ,cinvname
       ,strcontractid
       ,max(contract_price_person) as contract_price_person_max 
FROM shujuzu.contract_price1 a
GROUP BY bi_ccuscode,finnal_ccuscode,cinvcode
;
create  index index_contract_price4_bi_ccusname on shujuzu.contract_price4(bi_ccusname);
create  index index_contract_price4_finnal_ccusname on shujuzu.contract_price4(finnal_ccusname);
create  index index_contract_price4_cinvcode on shujuzu.contract_price4(cinvcode);
#在用合同价
DROP TABLE if EXISTS shujuzu.contract_price5;
CREATE  TEMPORARY TABLE   shujuzu.contract_price5 as
SELECT  a.bi_ccuscode
		,a.bi_ccusname
       ,a.finnal_ccuscode 
       ,a.finnal_ccusname
       ,cinvcode
       ,cinvname
       ,GROUP_CONCAT(distinct contract_price_person) as contract_price_person_effect 
FROM shujuzu.contract_price1 a
where statuscode = '在用'
GROUP BY bi_ccuscode,finnal_ccuscode,cinvcode
;
create  index index_contract_price5_bi_ccusname on shujuzu.contract_price5(bi_ccusname);
create  index index_contract_price5_finnal_ccusname on shujuzu.contract_price5(finnal_ccusname);
create  index index_contract_price5_cinvcode on shujuzu.contract_price5(cinvcode);
#最后一次出库日期
DROP TABLE if EXISTS shujuzu.out_date; 
CREATE  TEMPORARY TABLE   shujuzu.out_date as 
SELECT ccusname
	  ,finnal_ccusname 
      ,cinvcode
      ,max(ddate) as last_out_dt
      ,min(ddate) as first_out_dt
FROM pdm.outdepot_order a
GROUP BY ccusname,finnal_ccusname,cinvcode
;
create  index index_out_date_ccusname on shujuzu.out_date(ccusname);
create  index index_out_date_finnal_ccusname on shujuzu.out_date(finnal_ccusname);
create  index index_out_date_cinvcode on shujuzu.out_date(cinvcode);
#最后一次开票日期
DROP TABLE if EXISTS shujuzu.invoice_date;
CREATE  TEMPORARY TABLE   shujuzu.invoice_date as 
SELECT ccusname
	  ,finnal_ccusname
      ,cinvcode
      ,max(ddate) as last_invoice_dt
FROM pdm.invoice_order
GROUP BY ccusname,finnal_ccusname,cinvcode
;
create  index index_invoice_date_ccusname on shujuzu.invoice_date(ccusname);
create  index index_invoice_date_finnal_ccusname on shujuzu.invoice_date(finnal_ccusname);
create  index index_invoice_date_cinvcode on shujuzu.invoice_date(cinvcode);
#最后一次开票价格
DROP TABLE if EXISTS shujuzu.last_invoice_price;
CREATE  TEMPORARY TABLE   shujuzu.last_invoice_price as
SELECT a.ccusname
       ,a.ccuscode
       ,a.finnal_ccusname
	   ,a.cinvcode
	   ,itaxunitprice as last_invoice_price
FROM pdm.invoice_price a 
WHERE state = '最后一次价格'
;
#同一个直接客户有多个最终客户，同一个最终客户有多个直接客户，因此既要用直接客户匹配，又要用最终客户匹配
create  index index_last_invoice_price_ccusname on shujuzu.last_invoice_price(ccusname);
create  index index_last_invoice_price_finnal_ccusname on shujuzu.last_invoice_price(finnal_ccusname);
create  index index_last_invoice_price_cinvcode on shujuzu.last_invoice_price(cinvcode);

#111_db 产品编码清洗
DROP TABLE if EXISTS shujuzu.sales_devdis_relation_pre0; 
CREATE  TEMPORARY TABLE   shujuzu.sales_devdis_relation_pre0 as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,a.ccusname
       ,case when a.cdefine10 is null or a.cdefine10='' then ccusname else a.cdefine10 end as cdefine10
       ,a.province
       ,a.city
			 ,b.bi_cinvcode
			 ,b.bi_cinvname
       ,a.cinvname
       ,if(a.iquantity is null,0,a.iquantity) as iquantity
       ,a.price_crm
       ,a.price_oa
       ,if(a.fsettleqty is null,0,a.fsettleqty) as fsettleqty
       ,a.idlsid
			 ,c.inum_unit_person
FROM db_111.sales_devdis_relation a
LEFT JOIN (SELECT * FROM edw.dic_inventory  GROUP BY cinvcode) b
ON a.cinvcode  = b.cinvcode
LEFT JOIN edw.map_inventory c
ON b.bi_cinvcode = c.bi_cinvcode
;

#111_db 直接客户名称清洗
DROP TABLE if EXISTS shujuzu.sales_devdis_relation_pre1; 
CREATE  TEMPORARY TABLE   shujuzu.sales_devdis_relation_pre1 as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,b.bi_cusname as ccusname
       ,a.cdefine10
       ,a.province
       ,a.city
	   ,a.bi_cinvcode
	   ,a.bi_cinvname
       ,a.cinvname
       ,a.iquantity
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
	   ,a.inum_unit_person
FROM shujuzu.sales_devdis_relation_pre0 a
LEFT JOIN (SELECT * FROM edw.dic_customer  GROUP BY ccusname) b
ON a.ccusname = b.ccusname
;
#最终客户名称清洗
DROP TABLE if EXISTS shujuzu.sales_devdis_relation_pre; 
CREATE  TEMPORARY TABLE   shujuzu.sales_devdis_relation_pre as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,a.ccusname
       ,b.bi_cusname as finnal_cusname
       ,a.province
       ,a.city
	   ,a.bi_cinvcode
	   ,a.bi_cinvname
       ,a.cinvname
       ,a.iquantity
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
	   ,a.inum_unit_person
			 ,if(a.subsidiary='杭州贝生','杭州贝生',c.sales_region_new) as sales_region_new
FROM shujuzu.sales_devdis_relation_pre0 a
LEFT JOIN (SELECT * FROM edw.dic_customer  GROUP BY ccusname) b
ON a.cdefine10  = b.ccusname
LEFT JOIN edw.map_customer c
ON b.bi_cusname = c.bi_cusname
;
create  index index_sales_devdis_relation_pre_ccusname on shujuzu.sales_devdis_relation_pre(ccusname);
create  index index_sales_devdis_relation_pre_finnal_cusname on shujuzu.sales_devdis_relation_pre(finnal_cusname);
create  index index_sales_devdis_relation_pre_bi_cinvcode on shujuzu.sales_devdis_relation_pre(bi_cinvcode);

DROP TABLE if EXISTS shujuzu.out_invoice_0; 
CREATE  TEMPORARY TABLE   shujuzu.out_invoice_0 as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_cusname
       ,a.province
       ,a.city
	   ,a.bi_cinvcode
	   ,a.bi_cinvname
       ,a.cinvname
       ,a.iquantity
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
	   ,a.inum_unit_person
	   ,a.sales_region_new
       ,case when finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ02019' then 420 else b.contract_price_person_new end as contract_price_person_new #因没有合同价、没有CRM订单价，特殊处理
	   ,b.strcontractstartdate
FROM shujuzu.sales_devdis_relation_pre a
LEFT JOIN shujuzu.contract_price3 b
ON a.ccusname = b.bi_ccusname and a.finnal_cusname = b.finnal_ccusname and a.bi_cinvcode = b.cinvcode
;

#匹配最大合同价、在用合同价
DROP TABLE if EXISTS shujuzu.out_invoice_1; 
CREATE  TEMPORARY TABLE   shujuzu.out_invoice_1 as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_cusname
       ,a.province
       ,a.city
	   ,a.bi_cinvcode
	   ,a.bi_cinvname
       ,a.cinvname
       ,a.iquantity
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
	   ,a.inum_unit_person
	   ,a.sales_region_new
       ,a.contract_price_person_new 
	   ,b.contract_price_person_max
	   ,c.contract_price_person_effect
	   ,a.strcontractstartdate
from shujuzu.out_invoice_0 a
left join shujuzu.contract_price4 b
on a.ccusname = b.bi_ccusname and a.finnal_cusname = b.finnal_ccusname and a.bi_cinvcode = b.cinvcode
left join shujuzu.contract_price5 c
on a.ccusname = c.bi_ccusname and a.finnal_cusname = c.finnal_ccusname and a.bi_cinvcode = c.cinvcode
;

#匹配最后一次开票日期、最后一次开票价格
DROP TABLE if EXISTS shujuzu.out_invoice_pre_111; 
CREATE  TEMPORARY TABLE   shujuzu.out_invoice_pre_111 as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_cusname
       ,a.province
       ,a.city
	   ,a.bi_cinvcode
	   ,a.bi_cinvname
       ,a.cinvname
       ,a.iquantity
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
	   ,a.inum_unit_person
	   ,a.sales_region_new
       ,a.contract_price_person_new 
	   ,a.contract_price_person_max
	   ,a.contract_price_person_effect
	   ,b.last_invoice_dt
	   ,c.last_invoice_price
	   ,a.strcontractstartdate
from shujuzu.out_invoice_1 a
left join shujuzu.invoice_date b
on a.ccusname = b.ccusname and a.finnal_cusname = b.finnal_ccusname and a.bi_cinvcode = b.cinvcode
left join shujuzu.last_invoice_price c
on a.ccusname = c.ccusname and a.finnal_cusname = c.finnal_ccusname and a.bi_cinvcode = c.cinvcode
;

DROP TABLE if EXISTS shujuzu.out_invoice_111; 
CREATE   TABLE   shujuzu.out_invoice_111 as 
SELECT a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_cusname
       ,a.province
       ,a.city
	   ,a.bi_cinvcode
	   ,a.bi_cinvname
       ,a.cinvname
       ,a.iquantity
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
	   ,a.inum_unit_person
	   ,a.sales_region_new
       ,a.contract_price_person_new 
	   ,a.contract_price_person_max
	   ,a.contract_price_person_effect
	   ,a.last_invoice_dt
	   ,a.last_invoice_price/a.inum_unit_person as last_invoice_price_person
	   ,case when price_crm is null or price_crm = 0 then inum_unit_person*contract_price_person_new*(iquantity-fsettleqty)
			 else price_crm*(iquantity-fsettleqty) 
			 end as no_invoice_isum
	  ,case  when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'HC01246' then  '按检测量开票'
             when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ03007' then  '按检测量开票'
             when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='株洲市妇幼保健院' and a.bi_cinvcode = 'HC01201' then  '按检测量开票'
             when  finnal_cusname ='株洲市妇幼保健院' and a.bi_cinvcode = 'SJ02003' then  '按检测量开票'
             when  finnal_cusname ='株洲市妇幼保健院' and a.bi_cinvcode = 'SJ05124' then  '按检测量开票'
             when  finnal_cusname ='株洲市妇幼保健院' and a.bi_cinvcode = 'SJ05132' then  '按检测量开票'
             when  finnal_cusname ='株洲市妇幼保健院' and a.bi_cinvcode = 'SJ05257' then  '按检测量开票'
             when  finnal_cusname ='邵阳市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='邵阳市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='邵阳市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='湘潭市妇幼保健院' and a.bi_cinvcode = 'SJ02001' then  '按检测量开票'
             when  finnal_cusname ='湘潭市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='湘潭市妇幼保健院' and a.bi_cinvcode = 'SJ05001' then  '按检测量开票'
             when  finnal_cusname ='湘潭市妇幼保健院' and a.bi_cinvcode = 'SJ05018' then  '按检测量开票'
             when  finnal_cusname ='湘潭市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='湘潭市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01012' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01161' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01201' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01214' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01271' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01345' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01416' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01640' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01649' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'HC01651' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'SJ05092' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='益阳市妇幼保健院' and a.bi_cinvcode = 'SJ05244' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01040' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01052' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01075' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01146' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01201' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01214' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01505' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01509' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01552' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01553' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01566' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01634' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01640' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01641' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01643' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01648' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01649' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'HC01750' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'SJ02003' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'SJ05124' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'SJ05132' then  '按检测量开票'
             when  finnal_cusname ='岳阳市妇幼保健院' and a.bi_cinvcode = 'SJ05257' then  '按检测量开票'
             when  finnal_cusname ='长沙市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ02018' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ03008' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='连云港市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='连云港市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='连云港市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='泰州市人民医院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='泰州市人民医院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='泰州市人民医院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='无锡市妇幼保健院' and a.bi_cinvcode = 'SJ02003' then  '按检测量开票'
             when  finnal_cusname ='无锡市妇幼保健院' and a.bi_cinvcode = 'SJ05020' then  '按检测量开票'
             when  finnal_cusname ='无锡市妇幼保健院' and a.bi_cinvcode = 'SJ05124' then  '按检测量开票'
             when  finnal_cusname ='无锡市妇幼保健院' and a.bi_cinvcode = 'SJ05132' then  '按检测量开票'
             when  finnal_cusname ='无锡市妇幼保健院' and a.bi_cinvcode = 'SJ05257' then  '按检测量开票'
             when  finnal_cusname ='宿迁市第一人民医院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ02018' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ03008' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='徐州市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ02018' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ03002' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ03007' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ05023' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ05026' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ05093' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ05244' then  '按检测量开票'
             when  finnal_cusname ='丽水市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='丽水市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='丽水市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='宁波市妇女儿童医院' and a.bi_cinvcode = 'JC02080' then  '按检测量开票'
             when  finnal_cusname ='宁波市妇女儿童医院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='宁波市妇女儿童医院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='宁波市妇女儿童医院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='绍兴市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='绍兴市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='温州市中心医院' and a.bi_cinvcode = 'SJ03007' then  '按检测量开票'
             when  finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ02018' then  '按检测量开票'
             when  finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ03008' then  '按检测量开票'
             when  finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ05018' then  '按检测量开票'
             when  finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
             when  finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
             when  finnal_cusname ='扬州市妇幼保健院' and a.bi_cinvcode = 'SJ03007' then  '按检测量开票'
             when  finnal_cusname ='嘉兴市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
             when  finnal_cusname ='绍兴市妇幼保健院' and a.bi_cinvcode = 'SJ02018' then  '按检测量开票'
             when  finnal_cusname ='绍兴市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票' 
	         when contract_price_person_new= 0 and contract_price_person_max=0 and ddate >= strcontractstartdate then '合同签订价格为0'
             when contract_price_person_new= 0 and contract_price_person_max=0 and ddate < strcontractstartdate then '补签合同，价格为0'
             when contract_price_person_new= 0 and contract_price_person_max>0 and ddate >= strcontractstartdate then '之前有非0合同价，后签价格为0，该记录为补签之后'
             when contract_price_person_new= 0 and contract_price_person_max>0 and ddate < strcontractstartdate then '之前有非0合同价，后补签价格为0，该记录为补签之前' 
	         when last_invoice_dt is null and contract_price_person_new is null then '无合同，且从未开票' end as beizhu
 FROM shujuzu.out_invoice_pre_111 a
 WHERE cstcode <> '关联销售';
 
 UPDATE shujuzu.out_invoice_111 set last_invoice_price_person = 0 WHERE last_invoice_dt is not null and last_invoice_price_person is null;
 
 
 SELECT sum((if(iquantity is null,0,iquantity)-if(fsettleqty is null,0,fsettleqty))*price_crm) FROM db_111.sales_devdis_relation
 WHERE cstcode <> '关联销售';
SELECT sum((if(iquantity is null,0,iquantity)-if(fsettleqty is null,0,fsettleqty))*price_crm)
FROM shujuzu.out_invoice_111
WHERE cstcode <> '关联销售';

SELECT sum((if(iquantity is null,0,iquantity)-if(fsettleqty is null,0,fsettleqty))*price_crm)
FROM shujuzu.sales_devdis_relation_pre
WHERE cstcode <> '关联销售';
