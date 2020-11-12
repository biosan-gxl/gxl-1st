

DROP TABLE if EXISTS shujuzu.contract_price0;
CREATE TEMPORARY TABLE   shujuzu.contract_price0 as
SELECT a.bi_ccuscode
			,a.bi_ccusname
      ,a.finnal_ccuscode 
      ,a.finnal_ccusname 
      ,a.cinvcode 
      ,a.cinvname 
      ,a.new_cdefine12 as cdefine12
      ,a.new_name as strcontractid
      ,a.new_dstartdate as strcontractstartdate
      ,cast( a.new_itaxprice/b.inum_unit_person as DECIMAL(10,1)) as contract_price_person    
FROM  db_111.crm_contract a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
;

DROP TABLE if EXISTS shujuzu.contract_price1;
CREATE TEMPORARY TABLE   shujuzu.contract_price1 as
SELECT  a.bi_ccuscode
			 ,a.bi_ccusname
       ,a.finnal_ccuscode 
       ,a.finnal_ccusname
       ,cinvcode
       ,cinvname
       ,strcontractid
       ,strcontractstartdate
       ,cdefine12
       ,max(contract_price_person) as contract_price_person  
FROM shujuzu.contract_price0 a
WHERE a.bi_ccuscode is not null  and a.finnal_ccuscode is not null and cinvcode is not null and cinvcode <>'请核查'
GROUP BY a.bi_ccusname,a.finnal_ccusname,cinvcode,strcontractstartdate
; #避免一个合同里有2个个产品价格

#求每个客户产品同一个合同里的最大价格，避免一个合同两份价格的情况
CREATE index index_contract_price1_ccuscode on shujuzu.contract_price1(bi_ccuscode);
CREATE index index_contract_price1_finnal_ccuscode on shujuzu.contract_price1(finnal_ccuscode);
CREATE index index_contract_price1_cinvcode on shujuzu.contract_price1(cinvcode);

#求每个客户产品的最新日期
DROP TABLE if EXISTS shujuzu.contract_price2;
CREATE TEMPORARY TABLE   shujuzu.contract_price2 as
SELECT a.bi_ccusname,a.finnal_ccusname,cinvcode
				,max(strcontractstartdate) as star_max 
FROM shujuzu.contract_price1 a
GROUP BY  a.bi_ccusname,a.finnal_ccusname,cinvcode
;

#在用合同价

#最新价格（若有两个价格，取价格较大的）
DROP TABLE if EXISTS shujuzu.contract_price3; 
CREATE TEMPORARY TABLE   shujuzu.contract_price3 as 
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
#111_db 产品编码清洗
DROP TABLE if EXISTS shujuzu.sales_devdis_relation_pre1; 
CREATE  TABLE   shujuzu.sales_devdis_relation_pre1 as 
SELECT a.db
       ,a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.cdepname
       ,a.cpersonname
       ,a.ccuscode
       ,a.ccusname
       ,case when a.cdefine10 is null or a.cdefine10='' then ccusname else a.cdefine10 end as cdefine10
       ,a.province
       ,a.city
       ,a.cmemo
       ,a.cinvcode
			 ,b.bi_cinvcode
			 ,b.bi_cinvname
       ,a.cinvname
       ,a.cinvaddcode
       ,a.cinvstd
       ,a.ccomunitname
       ,a.cinvdefine5
       ,if(a.iquantity is null,0,a.iquantity) as iquantity
       ,a.cdefine34
       ,a.iunitcost
       ,a.price_crm
       ,a.price_oa
			 ,if(a.fsettleqty is null,0,a.fsettleqty) as fsettleqty
       ,a.idlsid
       ,a.cdefine22
       ,a.cdefine23
       ,a.cdefine36
       ,a.type
       ,a.date_type
			 ,c.inum_unit_person
FROM db_111.sales_devdis_relation a
LEFT JOIN (SELECT * FROM edw.dic_inventory  GROUP BY cinvcode) b
ON a.cinvcode  = b.cinvcode
LEFT JOIN edw.map_inventory c
ON b.bi_cinvcode = c.bi_cinvcode
;

#111_db 客户名称清洗
DROP TABLE if EXISTS shujuzu.sales_devdis_relation_pre; 
CREATE  TABLE   shujuzu.sales_devdis_relation_pre as 
SELECT a.db
       ,a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.cdepname
       ,a.cpersonname
       ,a.ccuscode
       ,a.ccusname
       ,b.bi_cusname as finnal_cusname
       ,a.province
       ,a.city
       ,a.cmemo
       ,a.cinvcode
			 ,a.bi_cinvcode
			 ,a.bi_cinvname
       ,a.cinvname
       ,a.cinvaddcode
       ,a.cinvstd
       ,a.ccomunitname
       ,a.cinvdefine5
       ,a.iquantity
       ,a.cdefine34
       ,a.iunitcost
       ,a.price_crm
       ,a.price_oa
			 ,a.fsettleqty
       ,a.idlsid
       ,a.cdefine22
       ,a.cdefine23
       ,a.cdefine36
       ,a.type
       ,a.date_type
			 ,a.inum_unit_person
			 ,if(a.subsidiary='杭州贝生','杭州贝生',c.sales_region_new) as sales_region_new
FROM shujuzu.sales_devdis_relation_pre1 a
LEFT JOIN (SELECT * FROM edw.dic_customer  GROUP BY ccusname) b
ON a.cdefine10  = b.ccusname
LEFT JOIN edw.map_customer c
ON b.bi_cusname = c.bi_cusname
;


DROP TABLE if EXISTS shujuzu.out_invoice_pre_111; 
CREATE  TABLE   shujuzu.out_invoice_pre_111 as 
SELECT a.db
       ,a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.cdepname
       ,a.cpersonname
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_cusname
       ,a.province
       ,a.city
       ,a.cmemo
       ,a.cinvcode
			 ,a.bi_cinvcode
			 ,a.bi_cinvname
       ,a.cinvname
       ,a.cinvaddcode
       ,a.cinvstd
       ,a.ccomunitname
       ,a.cinvdefine5
       ,iquantity
       ,a.cdefine34
       ,a.iunitcost
       ,a.price_crm
       ,a.price_oa
			 ,fsettleqty
       ,a.idlsid
       ,a.cdefine22
       ,a.cdefine23
       ,a.cdefine36
       ,a.type
       ,a.date_type
       ,case when finnal_cusname ='浙江大学医学院附属妇产科医院' and a.bi_cinvcode = 'SJ02019' then 420 else b.contract_price_person_new end as contract_price_person_new
			 ,a.inum_unit_person
       ,case       when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'HC01246' then  '按检测量开票'
 when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
 when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ03007' then  '按检测量开票'
 when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
 when  finnal_cusname ='常德市妇幼保健院' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
 when  finnal_cusname ='国药集团湖南省医疗器械有限公司' and a.bi_cinvcode = 'HC01201' then  '按检测量开票'
 when  finnal_cusname ='国药集团湖南省医疗器械有限公司' and a.bi_cinvcode = 'SJ02003' then  '按检测量开票'
 when  finnal_cusname ='国药集团湖南省医疗器械有限公司' and a.bi_cinvcode = 'SJ05124' then  '按检测量开票'
 when  finnal_cusname ='国药集团湖南省医疗器械有限公司' and a.bi_cinvcode = 'SJ05132' then  '按检测量开票'
 when  finnal_cusname ='国药集团湖南省医疗器械有限公司' and a.bi_cinvcode = 'SJ05257' then  '按检测量开票'
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
 when  finnal_cusname ='江苏恒龙生物科技有限公司' and a.bi_cinvcode = 'SJ02018' then  '按检测量开票'
 when  finnal_cusname ='江苏恒龙生物科技有限公司' and a.bi_cinvcode = 'SJ02019' then  '按检测量开票'
 when  finnal_cusname ='江苏恒龙生物科技有限公司' and a.bi_cinvcode = 'SJ03008' then  '按检测量开票'
 when  finnal_cusname ='江苏恒龙生物科技有限公司' and a.bi_cinvcode = 'SJ05126' then  '按检测量开票'
 when  finnal_cusname ='江苏恒龙生物科技有限公司' and a.bi_cinvcode = 'SJ05133' then  '按检测量开票'
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



 end as beizhu
 ,a.sales_region_new
FROM shujuzu.sales_devdis_relation_pre a
LEFT JOIN shujuzu.contract_price3 b
ON a.ccusname = b.bi_ccusname and a.finnal_cusname = b.finnal_ccusname and a.bi_cinvcode = b.cinvcode
;

DROP TABLE if EXISTS shujuzu.out_invoice_111; 
CREATE  TABLE   shujuzu.out_invoice_111 as 
SELECT a.db
       ,a.subsidiary
       ,a.ccode
       ,a.ddate
       ,a.cstcode
       ,a.cdepname
       ,a.cpersonname
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_cusname
       ,a.province
       ,a.city
       ,a.cmemo
       ,a.bi_cinvcode
			 ,a.bi_cinvname
       ,a.cinvaddcode
       ,a.cinvstd
       ,a.ccomunitname
       ,a.cinvdefine5
       ,a.iquantity
       ,a.cdefine34
       ,a.iunitcost
       ,a.price_crm
       ,a.price_oa
       ,a.fsettleqty
       ,a.idlsid
       ,a.cdefine22
       ,a.cdefine23
       ,a.cdefine36
       ,a.type
       ,a.date_type
       ,a.contract_price_person_new
       ,a.beizhu
			 ,case when price_crm is null or price_crm = 0 then inum_unit_person*contract_price_person_new*(iquantity-fsettleqty)
						 else price_crm*(iquantity-fsettleqty) end as no_invoice_isum
			 ,sales_region_new
 FROM shujuzu.out_invoice_pre_111 a
 WHERE cstcode <> '关联销售';
 
 
 
 
 SELECT sum((if(iquantity is null,0,iquantity)-if(fsettleqty is null,0,fsettleqty))*price_crm) FROM db_111.sales_devdis_relation
 WHERE cstcode <> '关联销售';
SELECT sum((if(iquantity is null,0,iquantity)-if(fsettleqty is null,0,fsettleqty))*price_crm)
FROM shujuzu.out_invoice_111
WHERE cstcode <> '关联销售';

SELECT sum((if(iquantity is null,0,iquantity)-if(fsettleqty is null,0,fsettleqty))*price_crm)
FROM shujuzu.sales_devdis_relation_pre
WHERE cstcode <> '关联销售';
