#对合同里的客户产品，对应的开票价、数量，目的是看合同是否达标

#得到有效的合同，结束时间大于当前时间，或者（合同结束时间为空，且合同开始时间大于等于2018年）
DROP TABLE  if exists shujuzu.cm_contract_effective;
CREATE TEMPORARY  table shujuzu.cm_contract_effective as 
SELECT a.ccusname
			,a.strcontractname
			,a.cdefine10 as finnalccusname
			,a.bi_cuscode
			,a.bi_cusname
			,a.cdefine12 as xiaoshou_type
			,a.strcontractstartdate
			,a.strcontractenddate
			,a.strcontractdesc
			,case when strcontractdesc like '报价流程%'  then substring_index(strcontractdesc,'：',-1) end as liuchengid
			,a.cdefine11 as yongzhangdanwei
			,a.strcontractid
			,a.strName
			,a.bi_cinvcode
			,a.bi_cinvname
			,a.item_code
			,a.item_name
			,a.cbustype
			,CAST(a.dblPriceRMB as DECIMAL(10,1)) as dblPriceRMB
			,CAST(a.dblQuantity as DECIMAL(10,1)) as dblQuantity
			,a.strMeasureUnit
			,a.cDefine27 as personprice
			,a.cDefine26 as personpriceshoufei
			,a.dblSumRMB
FROM edw.cm_contract a 
WHERE  (strcontractenddate is null and strcontractstartdate >= '2018-01-01')  OR strcontractenddate > NOW();

create index index_cm_contract_effective_bi_cuscode on shujuzu.cm_contract_effective(bi_cuscode);
create index index_cm_contract_effective_bi_cinvcode on shujuzu.cm_contract_effective(bi_cinvcode);
create index index_cm_contract_effective_strcontractid on shujuzu.cm_contract_effective(strcontractid);

# 有流程编号的合同（取流程的起始日期和标准价）
DROP TABLE  if exists shujuzu.cm_contract_effective_add00;
CREATE TEMPORARY  table shujuzu.cm_contract_effective_add00 as 
SELECT a.ccusname 
,a.strcontractname
,a.finnalccusname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,DATE_FORMAT(if(strcontractstartdate is not null,strcontractstartdate,b.shenqingr),'%Y-%m-%d') as startdate_modify
,DATE_FORMAT(if(strcontractenddate is not null,strcontractenddate,b.hezuoqx),'%Y-%m-%d') as enddate_modify
,a.strcontractdesc
,a.liuchengid
,a.yongzhangdanwei
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,a.dblQuantity
,CAST(b.biaozhundj as DECIMAL(10,1)) as biaozhundj
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
FROM (SELECT * FROM shujuzu.cm_contract_effective WHERE liuchengid is not null)a
LEFT JOIN (SELECT* from edw.oa_quotation_process WHERE liuchengbh is not null and bi_cinvcode <>'请核查' GROUP BY liuchengbh,bi_cinvcode) b 
#用gruop by 的目的是有重复的流程和产品，但是其他内容不完全重复，因此不能用distinct
ON a.liuchengid = b.liuchengbh and a.bi_cinvcode = b.bi_cinvcode;

create index index_cm_contract_effective_add00_bi_cuscode on shujuzu.cm_contract_effective_add00(bi_cuscode);
create index index_cm_contract_effective_add00_bi_cinvcode on shujuzu.cm_contract_effective_add00(bi_cinvcode);
create index index_cm_contract_effective_add00_strcontractid on shujuzu.cm_contract_effective_add00(strcontractid);


DROP TABLE  if exists shujuzu.cm_contract_effective_add0;
CREATE TEMPORARY  table shujuzu.cm_contract_effective_add0 as 
SELECT *   #得有流程编号的合同
FROM shujuzu.cm_contract_effective_add00
UNION 
SELECT a.ccusname  #没有流程编号的合同
,a.strcontractname
,a.finnalccusname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,null as startdate_modify
,null as enddate_modify
,a.strcontractdesc
,a.liuchengid
,a.yongzhangdanwei
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,a.dblQuantity
,null as biaozhundj 
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
FROM shujuzu.cm_contract_effective a
WHERE liuchengid is null;


create index index_cm_contract_effectiveadd0_bi_cuscode on shujuzu.cm_contract_effective_add0(bi_cuscode);
create index index_cm_contract_effectiveadd0_bi_cinvcode on shujuzu.cm_contract_effective_add0(bi_cinvcode);
create index index_cm_contract_effectiveadd0_strcontractid on shujuzu.cm_contract_effective_add0(strcontractid);

#报价流程里，有的产品有多个单价，比如A产品，买10赠1，则会有2条数据，A产品  价格x  10盒；A产品   价格0    1盒。
#检查后发现U8合同里的价格都录入了，但是数量没有录，因此要用流程号、产品号、价格作为分组
DROP TABLE  if exists shujuzu.cm_contract_effective_add;
CREATE TEMPORARY  table shujuzu.cm_contract_effective_add as
SELECT a.ccusname
,a.strcontractname
,a.finnalccusname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,DATE_FORMAT(if(strcontractstartdate is not null,strcontractstartdate,b.shenqingr),'%Y-%m-%d') as startdate_modify
,DATE_FORMAT(if(strcontractenddate is not null,strcontractenddate,b.hezuoqx),'%Y-%m-%d') as enddate_modify
,a.strcontractdesc
,a.liuchengid
,a.yongzhangdanwei
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,a.dblQuantity
,if(b.shuliang is null,a.dblQuantity,CAST(b.shuliang as DECIMAL(10,1))) as Quantity_modify
,a.biaozhundj
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
FROM shujuzu.cm_contract_effective_add0 a
LEFT JOIN (SELECT* from edw.oa_quotation_process WHERE liuchengbh is not null and bi_cinvcode <>'请核查' GROUP BY liuchengbh,bi_cinvcode,baojiadanj) b 
ON a.liuchengid = b.liuchengbh and a.bi_cinvcode = b.bi_cinvcode and a.dblPriceRMB = b.baojiadanj;


create index index_cm_contract_effectiveadd_bi_cuscode on shujuzu.cm_contract_effective_add(bi_cuscode);
create index index_cm_contract_effectiveadd_bi_cinvcode on shujuzu.cm_contract_effective_add(bi_cinvcode);
create index index_cm_contract_effectiveadd_strcontractid on shujuzu.cm_contract_effective_add(strcontractid);

#补充最后一次开票价格
DROP TABLE  if exists shujuzu.cm_contract_mid1;
CREATE TEMPORARY  table shujuzu.cm_contract_mid1 as
SELECT  a.ccusname
,a.strcontractname
,a.finnalccusname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,case when startdate_modify is not null and enddate_modify is not null then TIMESTAMPDIFF(MONTH,startdate_modify,enddate_modify) end as asses_mon
,case when startdate_modify is not null and enddate_modify is not null then ROUND(TIMESTAMPDIFF(month,startdate_modify,enddate_modify)/12) end as asses_year
,case when startdate_modify is not null then TIMESTAMPDIFF(MONTH,startdate_modify,now()) end as untill_mon
,a.strcontractdesc
,a.liuchengid
,a.yongzhangdanwei
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,a.dblQuantity
,a.Quantity_modify
,a.biaozhundj
,b.itaxunitprice as last_price
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
FROM shujuzu.cm_contract_effective_add a
LEFT JOIN (SELECT * FROM pdm.invoice_price  WHERE state = '最后一次价格' GROUP BY finnal_ccuscode,cinvcode )b
ON a.bi_cuscode = b.finnal_ccuscode and a.bi_cinvcode = b.cinvcode;

create index index_cm_contract_mid1_bi_cuscode on shujuzu.cm_contract_mid1(bi_cuscode);
create index index_cm_contract_mid1_bi_cinvcode on shujuzu.cm_contract_mid1(bi_cinvcode);
create index index_cm_contract_mid1_strcontractid on shujuzu.cm_contract_mid1(strcontractid);

#理论数量=总数量/合同月*至今月份数
DROP TABLE  if exists shujuzu.cm_contract_mid3;
CREATE TEMPORARY  table shujuzu.cm_contract_mid3 as
SELECT a.strcontractname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,a.asses_mon
,a.untill_mon
,a.strcontractdesc
,a.liuchengid
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,a.dblQuantity
,a.Quantity_modify
,asses_year
,a.Quantity_modify/a.asses_mon*a.untill_mon as lilunzongliang
,a.biaozhundj
,a.last_price
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
FROM shujuzu.cm_contract_mid1 a;

CREATE index index_cm_contract_mid3_bi_cuscode on shujuzu.cm_contract_mid3(bi_cuscode);
CREATE index index_cm_contract_mid3_bi_cinvcode on shujuzu.cm_contract_mid3(bi_cinvcode);
CREATE index index_cm_contract_mid3_dblPriceRMB on shujuzu.cm_contract_mid3(dblPriceRMB);

#至今的理论考核数量
/*DROP TABLE  if exists shujuzu.cm_contract_mid3;
CREATE TEMPORARY  table shujuzu.cm_contract_mid3 as
SELECT a.strcontractname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,a.asses_mon
,a.untill_mon
,a.strcontractdesc
,a.liuchengid
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,a.dblQuantity
,a.Quantity_modify
,case when asses_mon > 0 and untill_mon <=12 then plan1st/12*untill_mon
													when asses_mon > 0 and untill_mon >12  and untill_mon <=24  then plan1st+2*plan1st/12*(untill_mon mod 12)
													when asses_mon > 0 and untill_mon >24  and untill_mon <=36  then plan1st+2*plan1st+2.6*plan1st/12*(untill_mon mod 12) 
													when asses_mon > 0 and untill_mon >36 then 5.6*plan1st+3.12*plan1st*(untill_mon-36)/12 else null end as lilunzongliang
,a.biaozhundj
,a.last_price
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
FROM shujuzu.cm_contract_mid2 a;
CREATE index index_cm_contract_mid3_bi_cuscode ON shujuzu.cm_contract_mid3(bi_cuscode);
CREATE index index_cm_contract_mid3_bi_cinvcode ON shujuzu.cm_contract_mid3(bi_cinvcode);*/

#取合同生效后的开票记录，如果一个合同一个产品有多条记录，则开票记录也会相应的增加

DROP TABLE  if exists shujuzu.invoice_order;
CREATE TEMPORARY  table shujuzu.invoice_order as
SELECT  a.ddate
,a.finnal_ccuscode 
,a.finnal_ccusname 
,a.cinvcode
,a.cinvname 
,a.item_code
,a.citemname
,CAST(a.itaxunitprice as DECIMAL(10,1)) as itaxunitprice
,a.iquantity
,a.itax
,a.isum
FROM pdm.invoice_order a 
WHERE ddate >= '2018-01-01';

create index index_invoice_order_ccuscode on shujuzu.invoice_order(finnal_ccuscode);
create index index_invoice_order_cinvcode on shujuzu.invoice_order(cinvcode);


DROP TABLE  if exists shujuzu.cm_contract_mid4;
CREATE TEMPORARY  table shujuzu.cm_contract_mid4 as
SELECT a.ddate
,a.finnal_ccuscode as ccuscode
,a.finnal_ccusname as ccusname
,a.cinvcode
,a.cinvname 
,a.item_code
,a.citemname as item_name
,a.itaxunitprice
,sum(a.iquantity) as iquantity
,a.itax
,sum(a.isum) as isum
,b.strcontractid
,b.xiaoshou_type
,b.strcontractname
,b.startdate_modify
,b.enddate_modify
FROM shujuzu.invoice_order a
LEFT JOIN (SELECT * FROM shujuzu.cm_contract_mid3 GROUP BY strcontractid,bi_cinvcode) b
ON a.finnal_ccuscode = b.bi_cuscode and a.cinvcode = b.bi_cinvcode 
WHERE a.ddate >= b.startdate_modify and b.startdate_modify is not null
GROUP BY b.strcontractid,a.cinvcode,a.itaxunitprice;

create index index_cm_contract_mid4_ccuscode on shujuzu.cm_contract_mid4(ccuscode);
create index index_cm_contract_mid4_cinvcode on shujuzu.cm_contract_mid4(cinvcode);
create index index_cm_contract_mid4_strcontractid on shujuzu.cm_contract_mid4(strcontractid);



#判断价格是否等于合同价格
/*DROP TABLE  if exists shujuzu.cm_contract_mid40;
CREATE TEMPORARY  table shujuzu.cm_contract_mid40 as
SELECT a.ddate
,a.finnal_ccuscode as ccuscode
,a.finnal_ccusname as ccusname
,a.cinvcode
,a.cinvname
,a.item_code
,a.item_name
,a.itaxunitprice
,a.iquantity
,a.itax
,a.isum
,a.strcontractid
,a.startdate_modify
,a.dblPriceRMB
,
FROM shujuzu.cm_contract_mid4 a;*/
DROP TABLE  if exists shujuzu.cm_contract_mid5;
CREATE TEMPORARY  table shujuzu.cm_contract_mid5 as
SELECT a.strcontractname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,a.asses_mon
,a.untill_mon
,a.strcontractdesc
,a.liuchengid
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,b.itaxunitprice
,'合同价' as price_class
,a.dblQuantity
,a.Quantity_modify
,a.asses_year
,a.lilunzongliang
,a.biaozhundj
,a.last_price
,a.strMeasureUnit
,a.personprice
,a.personpriceshoufei
,a.dblSumRMB
,b.iquantity
,b.isum
FROM shujuzu.cm_contract_mid3 a
LEFT JOIN shujuzu.cm_contract_mid4 b
ON a.strcontractid = b.strcontractid and a.bi_cinvcode = b.cinvcode and a.dblPriceRMB = b.itaxunitprice;

#根据合同编号，产品编号，产品价格，求开票数量和开票额
/*DROP TABLE  if exists shujuzu.cm_contract_mid5;
CREATE TEMPORARY  table shujuzu.cm_contract_mid5 as
SELECT ccuscode
,ccusname
,strcontractid
,startdate_modify
,enddate_modify
,cinvcode
,cinvname
,item_code
,item_name
,itaxunitprice
,sum(iquantity) as ttl_iquantity
,sum(isum) as ttl_isum
FROM shujuzu.cm_contract_mid4
GROUP BY strcontractid,cinvcode,itaxunitprice;*/

create index index_cm_contract_mid5_ccuscode on shujuzu.cm_contract_mid5(bi_cuscode);
create index index_cm_contract_mid5_cinvcode on shujuzu.cm_contract_mid5(bi_cinvcode);
create index index_cm_contract_mid5_strcontractid on shujuzu.cm_contract_mid5(strcontractid);

#将合同号、产品、产品价格与合同的表左合并
/*DROP TABLE  if exists shujuzu.cm_contract_track0;
CREATE TEMPORARY  table shujuzu.cm_contract_track0 as
SELECT a.strcontractname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,a.asses_mon
,a.untill_mon
,a.strcontractdesc
,a.liuchengid
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblPriceRMB
,b.itaxunitprice
,'合同价' as price_class
,a.dblQuantity
,a.Quantity_modify
,a.lilunzongliang
,a.biaozhundj
,if(ttl_isum is null or ttl_isum = 0,null,a.last_price) as last_price
,b.ttl_iquantity
,b.ttl_isum
FROM shujuzu.cm_contract_mid3 a
LEFT JOIN shujuzu.cm_contract_mid5 b
ON a.strcontractid = b.strcontractid and a.bi_cinvcode = b.cinvcode and a.dblPriceRMB = b.itaxunitprice;*/

#合同产品最大的合同价
DROP TABLE  if exists shujuzu.cm_contract_mid6;
CREATE TEMPORARY  table shujuzu.cm_contract_mid6 as
SELECT strcontractid,bi_cinvcode,max(dblPriceRMB) as max_u8Price
FROM shujuzu.cm_contract_effective
GROUP BY strcontractid,bi_cinvcode;

create index index_cm_contract_mid6_cinvcode on shujuzu.cm_contract_mid6(bi_cinvcode);
create index index_cm_contract_mid6_strcontractid on shujuzu.cm_contract_mid6(strcontractid);

#找出非合同价的数据
DROP TABLE  if exists shujuzu.cm_contract_mid7;
CREATE TEMPORARY  table shujuzu.cm_contract_mid7 as
SELECT a.ccuscode
,a.ccusname
,a.strcontractid
,a.xiaoshou_type
,a.strcontractname
,a.startdate_modify
,a.enddate_modify
,a.cinvcode
,a.cinvname
,a.item_code
,a.item_name
,a.itaxunitprice
,'非合同价' as price_class
,a.iquantity
,a.isum
FROM shujuzu.cm_contract_mid4 a
LEFT JOIN shujuzu.cm_contract_mid3 b
ON a.strcontractid = b.strcontractid and a.cinvcode = b.bi_cinvcode and a.itaxunitprice = b.dblPriceRMB
WHERE a.strcontractid is not null and a.cinvcode is not null and b.dblPriceRMB is null;

create index index_cm_contract_mid7_cinvcode on shujuzu.cm_contract_mid7(cinvcode);
create index index_cm_contract_mid7_strcontractid on shujuzu.cm_contract_mid7(strcontractid);

#非合同价的情况，补充最后一次开票价格
DROP TABLE  if exists shujuzu.cm_contract_mid8;
CREATE TEMPORARY  table shujuzu.cm_contract_mid8 as
SELECT  a.ccuscode
,a.ccusname
,a.strcontractid
,a.xiaoshou_type
,a.strcontractname
,a.startdate_modify
,a.enddate_modify
,a.cinvcode
,a.cinvname
,a.item_code
,a.item_name
,a.itaxunitprice
,a.price_class
,a.iquantity
,a.isum
,b.itaxunitprice as last_price
FROM shujuzu.cm_contract_mid7 a
LEFT JOIN (SELECT * FROM pdm.invoice_price  WHERE state = '最后一次价格' GROUP BY finnal_ccuscode,cinvcode) b
ON a.ccuscode = b.finnal_ccuscode and a.cinvcode = b.cinvcode;

DROP TABLE  if exists shujuzu.cm_contract_track1;
CREATE TEMPORARY  table shujuzu.cm_contract_track1 as
SELECT *
FROM shujuzu.cm_contract_mid5
UNION 
SELECT a.strcontractname
,a.ccuscode
,a.ccusname
,a.xiaoshou_type
,null
,null
,a.startdate_modify
,a.enddate_modify
,null
,null
,null
,null
,a.strcontractid
,null
,a.cinvcode
,a.cinvname
,a.item_code
,a.item_name
,null
,null
,itaxunitprice
,a.price_class
,null
,null
,null
,null
,null
,last_price
,null
,null
,null
,null
,iquantity
,isum
FROM shujuzu.cm_contract_mid8 a;

create index index_cm_contract_track1_cinvcode on shujuzu.cm_contract_track1(bi_cinvcode);
create index index_cm_contract_track1_strcontractid on shujuzu.cm_contract_track1(strcontractid);

#补充加上最大合同单价
DROP TABLE  if exists shujuzu.cm_contract_track2;
CREATE TEMPORARY  table shujuzu.cm_contract_track2 as
SELECT a.strcontractname
,a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,a.asses_mon
,a.untill_mon
,a.strcontractdesc
,a.liuchengid
,a.strcontractid
,a.strName
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblQuantity
,a.Quantity_modify
,a.dblPriceRMB
,a.itaxunitprice
,a.price_class
,a.last_price
,a.biaozhundj
,a.lilunzongliang
,a.iquantity as ttl_iquantity #这里是因为之前那加工的一份交这个名字，没有其他特殊含义
,a.isum as ttl_isum
,b.max_u8Price
FROM shujuzu.cm_contract_track1 a
LEFT JOIN shujuzu.cm_contract_mid6 b
ON a.strcontractid = b.strcontractid and a.bi_cinvcode = b.bi_cinvcode;

DELETE
FROM shujuzu.cm_contract_track2
WHERE (ttl_isum = 0 and ttl_iquantity <= 0) or ttl_isum < 0;#调历史账目情况，删除

DROP TABLE  if exists shujuzu.cm_contract_track;
CREATE   table shujuzu.cm_contract_track as
SELECT a.bi_cuscode
,a.bi_cusname
,a.xiaoshou_type
,a.strcontractstartdate
,a.strcontractenddate
,a.startdate_modify
,a.enddate_modify
,a.asses_mon
,a.untill_mon
,a.strcontractdesc
,a.liuchengid
,a.strcontractid
,a.bi_cinvcode
,a.bi_cinvname
,a.item_code
,a.item_name
,a.cbustype
,a.dblQuantity
,a.Quantity_modify
,a.dblPriceRMB
,a.itaxunitprice
,if (price_class = '非合同价' and itaxunitprice > max_u8Price,'非合同价，大于合同价',a.price_class) as price_class
,a.last_price
,a.biaozhundj
,a.lilunzongliang
,a.ttl_iquantity #这里是因为之前那加工的一份交这个名字，没有其他特殊含义
,a.ttl_isum
,a.max_u8Price
,Quantity_modify*dblPriceRMB
,Quantity_modify*biaozhundj
,ttl_iquantity*itaxunitprice
,ttl_iquantity*biaozhundj
,case when itaxunitprice>0 and lilunzongliang>0 and ttl_iquantity < lilunzongliang then 1
			  when itaxunitprice=0 and lilunzongliang>0 and ttl_iquantity > lilunzongliang then 1 else 0 end as iquantity_track
,IF(price_class="非合同价",1,0) as price_track
,case when ttl_isum is null then '合同签订后2018年后没有开票记录'
      when ttl_isum < 0 then '包含财务退补数据，时间范围问题，导致收入为负'
			when max_u8Price = 0  and itaxunitprice >0 then '合同价格为0，但是开票价大于0'
			when itaxunitprice = 0 and price_class='非合同价' then '非合同价的赠送' end as comment 
,case when xiaoshou_type like '%设备移库%' then '设备投放合同'
      when strcontractname like '%租%' then '设备租赁合同'  else '其他合同' end as contract_type
FROM shujuzu.cm_contract_track2 a;


