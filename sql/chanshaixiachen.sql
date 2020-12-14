-- 1. 设备装机信息
-- 1.1 1235装机信息
drop table if exists shujuzu.equipment_temp00;
create temporary table shujuzu.equipment_temp00 as
SELECT bi_cuscode as cuscode
     ,bi_cusname as cusname
     ,bi_cinvcode as cinvcode
     ,bi_cinvname as cinvname
     ,new_installation_date 
FROM edw.crm_account_equipments
WHERE bi_cinvname = '1235（产前）' or bi_cinvname = 'DX6000'
GROUP BY bi_cuscode;
alter table shujuzu.equipment_temp00 add index(cuscode);

drop table if exists shujuzu.equipment_temp01;
create temporary table shujuzu.equipment_temp01 as
SELECT cuscode
     ,cusname
     ,min(new_installation_date) as new_installation_date 
from shujuzu.equipment_temp00
group by cuscode;
alter table shujuzu.equipment_temp01 add index(cuscode);
-- 1.2 芯片装机信息
drop table if exists shujuzu.equipment_temp02;
create temporary table shujuzu.equipment_temp02 as
SELECT bi_cuscode as cuscode
     ,bi_cusname as cusname
     ,new_installation_date 
FROM edw.crm_account_equipments
WHERE bi_cinvname = '芯片设备'
GROUP BY bi_cuscode;
alter table shujuzu.equipment_temp02 add index(cuscode); 
-- 1.3 GSL 120装机信息
drop table if exists shujuzu.equipment_temp021;
create temporary table shujuzu.equipment_temp021 as
SELECT bi_cuscode as cuscode
     ,bi_cusname as cusname
     ,new_installation_date 
FROM edw.crm_account_equipments
WHERE bi_cinvname = 'GSL-120'
GROUP BY bi_cuscode;
alter table shujuzu.equipment_temp02 add index(cuscode); 

-- 1.4 安装1235的客户再安装芯片的信息
drop table if exists shujuzu.equipment_temp03;
create temporary table shujuzu.equipment_temp03 as
select a.cuscode
    ,a.cusname
    ,a.new_installation_date as  install_dt_1235_DX
	  ,b.new_installation_date as install_dt_CMA
		,c.new_installation_date as install_dt_GSL120
from shujuzu.equipment_temp01 a
left join shujuzu.equipment_temp02 b
on a.cuscode = b.cuscode
left join shujuzu.equipment_temp021 c
on a.cuscode = c.cuscode;

-- 2. 客户收入，2020年1-11月取实际收入，12月取预期收入
drop table if exists shujuzu.invoice_temp01;
create temporary table shujuzu.invoice_temp01 as
select ddate
	,finnal_ccuscode
	,finnal_ccusname 
	,cinvcode
	,cinvname
	,sum(isum) as isum
from 
    (select 
    	date_format(ddate,'%Y-%m-01') as ddate
    	,finnal_ccuscode
    	,finnal_ccusname 
    	,cinvcode
    	,cinvname
    	,isum
    from pdm.invoice_order 
    where ddate >= '2017-01-01' and ddate <= '2020-11-30' and item_code != 'JK0101' and cohr <> '杭州贝生'
    union all
    select 
        ddate
        ,bi_cuscode
        ,bi_cusname
        ,bi_cinvcode
        ,bi_cinvname
        ,isum_budget_new
    from edw.x_sales_budget_20_new
    where ddate >= '2020-12-01' and cohr <> '杭州贝生')a
	group by ddate,finnal_ccuscode,cinvcode;
alter table shujuzu.invoice_temp01 add index(finnal_ccuscode),add index(cinvcode);


	
-- 2.1关联产品档案，得产品属性；关联客户属性，得客户区域

drop table if exists shujuzu.invoice_temp02;
create temporary table shujuzu.invoice_temp02 as
select c.sales_dept
  ,c.sales_region_new
  ,c.city
  ,c.county
	,a.ddate
	,a.finnal_ccuscode
	,a.finnal_ccusname
  ,c.nsieve_mechanism	
	,c.medical_mechanism
	,c.screen_mechanism
	,a.cinvcode
	,a.cinvname
	,a.isum
	,b.item_code
	,b.level_three as item_name
	,b.screen_class
	,b.equipment
	,b.business_class
from shujuzu.invoice_temp01 a
left join edw.map_inventory b
on a.cinvcode = b.bi_cinvcode
left join edw.map_customer c 
on a.finnal_ccuscode = c.bi_cuscode;

alter table shujuzu.invoice_temp02 add index(finnal_ccuscode);

drop table if exists shujuzu.chanshaixiacheng;
create  table shujuzu.chanshaixiacheng as
select a.sales_dept
  ,a.sales_region_new
  ,a.city
  ,a.county
	,a.ddate
	,a.finnal_ccuscode
	,a.finnal_ccusname
  ,a.nsieve_mechanism
  ,a.medical_mechanism
  ,a.screen_mechanism
	,a.cinvcode
	,a.cinvname
	,a.isum/1000 as isum
	,a.item_code
	,a.item_name
	,a.screen_class
	,a.equipment
	,a.business_class
	,b.install_dt_1235_DX
	,b.install_dt_CMA
	,b.install_dt_GSL120
	,case when b.install_dt_1235_DX is not null and a.medical_mechanism ='False'  then '产筛下沉'  end as clasify
from shujuzu.invoice_temp02 a 
left join shujuzu.equipment_temp03 b 
on a.finnal_ccuscode = b.cuscode;

#复核
select sum(isum)
from shujuzu.chanshaixiacheng;

select sum(isum)
from 
(SELECT sum(isum) as isum
from  pdm.invoice_order 
where ddate >= '2017-01-01' and ddate <= '2020-11-30' and item_code != 'JK0101' and cohr <> '杭州贝生'
union
select sum(isum_budget_new) as isum_budget_new
from edw.x_sales_budget_20_new
where ddate >= '2020-12-01' and cohr <> '杭州贝生')a

	
	
	
	
	
	
	
	