-- 用到的表源db_111.crm_contract,db_111.sales_dispatch_list

-- 筛选出设备移库的合同，并计算出迄今为止的理论数量
drop table if exists shujuzu.euipment_yiku;
create temporary  table shujuzu.euipment_yiku as 
SELECT 
new_name
,new_contract_name
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,new_cdefine12
,new_dstartdate
,new_denddate
,new_desc
,cinvcode
,cinvname
,new_iquantity
,case when new_denddate is not null and new_dstartdate is not null
       then timestampdiff(month,new_dstartdate,now())/timestampdiff(month,new_dstartdate,new_denddate)* new_iquantity
			 end as lilunshuliang
,new_itaxprice
,new_isum
FROM db_111.crm_contract
where new_cdefine12  like '设备移库%'
;


alter table shujuzu.euipment_yiku add index(bi_ccuscode);
alter table shujuzu.euipment_yiku add index(finnal_ccuscode);
alter table shujuzu.euipment_yiku add index(cinvcode);

-- 客户产品的最大合同日期
drop table if exists shujuzu.cusname_cinvcode_price01;
create temporary  table shujuzu.cusname_cinvcode_price01 as
select
bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,cinvcode
,cinvname
,max(new_dstartdate) as max_startdate -- 最大合同日期
FROM db_111.crm_contract
where new_dstartdate is not null and new_itaxprice > 0
group by bi_ccuscode,finnal_ccuscode,cinvcode
;
alter table shujuzu.cusname_cinvcode_price01 add index(bi_ccuscode);
alter table shujuzu.cusname_cinvcode_price01 add index(finnal_ccuscode);
alter table shujuzu.cusname_cinvcode_price01 add index(cinvcode);



-- 客户产品的最新合同价格
drop table if exists shujuzu.cusname_cinvcode_price;
create temporary  table shujuzu.cusname_cinvcode_price as 
select a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.cinvcode
,a.cinvname
,a.new_dstartdate
,max(a.new_itaxprice) as new_itaxprice -- 最新合同价
FROM db_111.crm_contract a
left join shujuzu.cusname_cinvcode_price01 b
on a.bi_ccuscode = b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and a.cinvcode = b.cinvcode
where a.new_dstartdate = b.max_startdate 
group by a.bi_ccuscode
,a.finnal_ccuscode
,a.cinvcode
;

alter table shujuzu.cusname_cinvcode_price add index(bi_ccuscode);
alter table shujuzu.cusname_cinvcode_price add index(finnal_ccuscode);
alter table shujuzu.cusname_cinvcode_price add index(cinvcode);

#关联最新合同价
drop table if exists shujuzu.euipment_yiku_pricenew01;
create temporary  table shujuzu.euipment_yiku_pricenew01 as 
select
new_name
,a.new_contract_name
,a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.new_cdefine12
,a.new_dstartdate
,a.new_denddate
,a.new_desc
,a.cinvcode
,a.cinvname
,a.new_iquantity
,a.new_itaxprice
,a.new_isum
,a.lilunshuliang
,b.new_itaxprice as new_price
from shujuzu.euipment_yiku a
left join shujuzu.cusname_cinvcode_price b
on a.bi_ccuscode = b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and a.cinvcode = b.cinvcode
;
alter table shujuzu.euipment_yiku_pricenew01 add index(bi_ccuscode);
alter table shujuzu.euipment_yiku_pricenew01 add index(finnal_ccuscode);
alter table shujuzu.euipment_yiku_pricenew01 add index(cinvcode);

-- 目的是取合同生效后的发货数量、最近一年的发货数量

-- 筛选出合同起始日期为非空的合同信息
drop table if exists shujuzu.out_depot_temp01;
create temporary  table shujuzu.out_depot_temp01 as
select new_name
,bi_ccuscode
,finnal_ccuscode
,cinvcode
,new_dstartdate
from shujuzu.euipment_yiku_pricenew01
where new_dstartdate is not null
 
;
alter table shujuzu.out_depot_temp01 add index(bi_ccuscode);
alter table shujuzu.out_depot_temp01 add index(finnal_ccuscode);
alter table shujuzu.out_depot_temp01 add index(cinvcode);

-- 筛选出与合同的客户产品相关的发货信息
drop table if exists shujuzu.out_depot_temp02;
create temporary  table shujuzu.out_depot_temp02 as
select b.bi_ccuscode
,b.finnal_ccuscode
,b.cinvcode
,a.ddate
,a.iquantity
from db_111.sales_dispatch_list a
left join (select bi_ccuscode,finnal_ccuscode, cinvcode from shujuzu.out_depot_temp01 group by bi_ccuscode,finnal_ccuscode, cinvcode) b -- 分组的目的是让客户产品唯一
on a.bi_ccuscode = b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and b.cinvcode = a.bi_cinvcode
;

alter table shujuzu.out_depot_temp02 add index(bi_ccuscode);
alter table shujuzu.out_depot_temp02 add index(finnal_ccuscode);
alter table shujuzu.out_depot_temp02 add index(cinvcode);

-- 筛选出发货日期大于合同日期的发货信息
drop table if exists shujuzu.out_depot_temp03;
create temporary  table shujuzu.out_depot_temp03 as
select
a.bi_ccuscode
,a.finnal_ccuscode
,a.cinvcode
,a.ddate
,a.iquantity
,b.new_name
,b.new_dstartdate
,timestampdiff(month,a.ddate,now()) as utl_month
from shujuzu.out_depot_temp02 a
left join shujuzu.out_depot_temp01 b -- 一个客户一个产品存在多个合同
on a.bi_ccuscode = b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and b.cinvcode = a.cinvcode
where a.ddate >= b.new_dstartdate 
;

-- 分组求和，得到合同生效后的发货数量
drop table if exists shujuzu.out_depot_temp04;
create temporary  table shujuzu.out_depot_temp04 as
select
a.bi_ccuscode
,a.finnal_ccuscode
,a.cinvcode
,sum(a.iquantity) as ttl_iquantity
,a.new_name
,a.new_dstartdate
from shujuzu.out_depot_temp03 a
group by a.bi_ccuscode
,a.finnal_ccuscode
,a.cinvcode
,a.new_name
;

alter table shujuzu.out_depot_temp04 add index(bi_ccuscode);
alter table shujuzu.out_depot_temp04 add index(finnal_ccuscode);
alter table shujuzu.out_depot_temp04 add index(cinvcode);
alter table shujuzu.out_depot_temp04 add index(new_name);

#求最近一年的发货量
drop table if exists shujuzu.out_depot_temp05;
create temporary  table shujuzu.out_depot_temp05 as
select
a.bi_ccuscode
,a.finnal_ccuscode
,a.cinvcode
,sum(a.iquantity) as utl_1year_iquantity
,a.new_name
,a.new_dstartdate
from shujuzu.out_depot_temp03 a
where utl_month < 12
group by a.bi_ccuscode
,a.finnal_ccuscode
,a.cinvcode
,a.new_name
;
alter table shujuzu.out_depot_temp05 add index(bi_ccuscode);
alter table shujuzu.out_depot_temp05 add index(finnal_ccuscode);
alter table shujuzu.out_depot_temp05 add index(cinvcode);
alter table shujuzu.out_depot_temp05 add index(new_name);

-- 关联发货数量
drop table if exists shujuzu.out_depot_temp06;
create temporary  table shujuzu.out_depot_temp06 as 
select
a.new_name
,a.new_contract_name
,a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.new_cdefine12
,a.new_dstartdate
,a.new_denddate
,a.new_desc
,a.cinvcode
,a.cinvname
,a.new_iquantity
,a.new_itaxprice
,a.new_isum
,a.lilunshuliang
,a.new_price
,b.ttl_iquantity as dispatch_iquantity
from shujuzu.euipment_yiku_pricenew01 a
left join shujuzu.out_depot_temp04 b
on a.bi_ccuscode = b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and b.cinvcode = a.cinvcode and a.new_name = b.new_name
;

-- 关联最近一年的发货数量
drop table if exists shujuzu.out_depot_temp07;
create temporary  table shujuzu.out_depot_temp07 as 
select
a.new_name
,a.new_contract_name
,a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.new_cdefine12
,a.new_dstartdate
,a.new_denddate
,a.new_desc
,a.cinvcode
,a.cinvname
,a.new_iquantity
,a.new_itaxprice
,a.new_isum
,a.lilunshuliang
,a.new_price
-- ,a.min_startdate
-- ,a.max_startdate
,a.dispatch_iquantity
-- ,a.invoice_iquantity
,b.utl_1year_iquantity
from shujuzu.out_depot_temp06 a
left join shujuzu.out_depot_temp05 b
on a.bi_ccuscode = b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and b.cinvcode = a.cinvcode and a.new_name = b.new_name
;


alter table shujuzu.out_depot_temp07 add index(cinvcode);

#清洗产品编号
drop table if exists shujuzu.out_depot_temp08;
create temporary  table shujuzu.out_depot_temp08 as 
select
a.new_name
,a.new_contract_name
,a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.new_cdefine12
,a.new_dstartdate
,a.new_denddate
,a.new_desc
,b.bi_cinvcode as cinvcode
,a.cinvname
,a.new_iquantity
,a.new_itaxprice
,a.new_isum
,a.lilunshuliang
,a.new_price
,a.dispatch_iquantity
,a.utl_1year_iquantity
from shujuzu.out_depot_temp07 a
left join (SELECT * from edw.dic_inventory group by cinvcode)b
on a.cinvcode = b.cinvcode
;

#关联产品档案，取产品规格人份

drop table if exists shujuzu.euipment_yiku_pricenew02;
create temporary  table shujuzu.euipment_yiku_pricenew02 as 
select
a.new_name
,a.new_contract_name
,a.bi_ccuscode
,a.bi_ccusname
,if(a.finnal_ccuscode='请核查',a.bi_ccuscode,finnal_ccuscode) as finnal_ccuscode
,if(a.finnal_ccusname='请核查',a.bi_ccusname,finnal_ccusname) as finnal_ccusname
,a.new_cdefine12
,a.new_dstartdate
,a.new_denddate
,a.new_desc
,a.cinvcode
,a.cinvname
,a.new_iquantity*inum_unit_person as contract_person_iquantity
,round(a.new_itaxprice/inum_unit_person,1) as contract_person_price
,a.new_isum
,a.lilunshuliang*inum_unit_person as lilunshuliang
,round(a.new_price/inum_unit_person,1) as contract_person_price_new
,a.dispatch_iquantity*inum_unit_person as dispatch_person_iquantity
,a.utl_1year_iquantity*inum_unit_person as utl_1year_person_iquantity
from shujuzu.out_depot_temp08 a
left join edw.map_inventory b
on a.cinvcode = b.bi_cinvcode
;

update  shujuzu.euipment_yiku_pricenew02 set contract_person_price_new = contract_person_price where contract_person_price > 0 and contract_person_price_new is null;

drop table if exists shujuzu.euipment_yiku_pricenew;
create   table shujuzu.euipment_yiku_pricenew as 
select
a.new_name
,a.new_contract_name
,b.sales_region_new
,a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.new_cdefine12
,a.new_dstartdate
,a.new_denddate
,a.new_desc
,a.cinvcode
,a.cinvname
,a.contract_person_iquantity
,a.contract_person_price
,a.new_isum
,a.lilunshuliang
,a.contract_person_price_new
,a.dispatch_person_iquantity
,a.utl_1year_person_iquantity
,if(a.contract_person_price_new < a.contract_person_price,'合同价格下降','') as price_judgment
,case when lilunshuliang is null or lilunshuliang = 0 
      then '无合同数量，无法判断数量是否达标'
			when lilunshuliang > dispatch_person_iquantity then '实际发货数量少于合同理论数量'
			end as iquantity_judgment
from shujuzu.euipment_yiku_pricenew02 a
left join edw.map_customer b
on a.finnal_ccuscode = b.bi_cuscode