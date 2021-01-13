drop table if EXISTS shujuzu.budget_2021_temp01;
create table  shujuzu.budget_2021_temp01 as 
SELECT  sales_dept
     ,a.sales_region_new
     ,a.ccusname
     ,a.item_name
     ,a.cinvcode
     ,a.cinvname
     ,a.inum_person
     ,a.isum
     ,a.fenlei
     ,a.rate
     ,case when a.item_name='CNV-seq' then 'CNV-seq'
					 when a.item_name='CMA' or a.item_name='CMA设备' then 'CMA' 
					 else b.beizhu
					 end as beizhu_item
		 ,b.beizhu
FROM shujuzu.x_budget_2021 a
left join shujuzu.x_newcus_standard b
on a.cinvcode = b.bi_cinvcode
;

drop table if EXISTS shujuzu.budget_2021_temp02;
create table  shujuzu.budget_2021_temp02 as
select sales_dept
      ,a.sales_region_new
      ,a.ccusname
			,beizhu_item
      ,a.beizhu
      ,min(rate) as min_rate
      ,max(rate) as max_rate
      ,sum(isum) as isum
			,sum(inum_person) as inum_person
from shujuzu.budget_2021_temp01 a
group by sales_dept,sales_region_new,ccusname,beizhu_item
;

-- 2020年收入
drop table if EXISTS shujuzu.budget_2021_temp03;
create table  shujuzu.budget_2021_temp03 as
select 
      if(cohr='杭州贝生','杭州贝生',c.sales_dept) as sales_dept
      ,if(cohr='杭州贝生','杭州贝生',c.sales_region_new) as sales_region_new
      ,a.finnal_ccusname as ccusname
      ,a.cinvcode
      ,a.cinvname
      ,a.isum
			,case when a.citemname='CNV-seq' then 'CNV-seq'
					 when a.citemname='CMA' or a.citemname='CMA设备' then 'CMA' 
					 else b.beizhu
					 end as beizhu_item
      ,b.beizhu
from pdm.invoice_order a
left join shujuzu.x_newcus_standard b
on a.cinvcode = b.bi_cinvcode
left join edw.map_customer c
on a.finnal_ccuscode = c.bi_cuscode
where ddate >= '2020-01-01' and ddate <= '2020-12-31'
;

drop table if EXISTS shujuzu.budget_2021_temp04;
create table  shujuzu.budget_2021_temp04 as
select sales_dept
      ,sales_region_new
      ,a.ccusname
			,beizhu_item
      ,a.beizhu
      ,sum(a.isum) as isum_2020
from shujuzu.budget_2021_temp03 a
group by sales_dept,sales_region_new,ccusname,beizhu_item
;

drop table if EXISTS shujuzu.budget_2021_temp05;
create table  shujuzu.budget_2021_temp05 as
select
     a.sales_dept
     ,a.sales_region_new
     ,a.ccusname
		 ,a.beizhu_item
     ,a.beizhu
     ,a.min_rate
     ,a.max_rate
     ,a.isum
		 ,a.inum_person
     ,0 as isum_2020
     from shujuzu.budget_2021_temp02 a
     union all
     select sales_dept
     ,sales_region_new
     ,a.ccusname
		 ,a.beizhu_item
     ,a.beizhu
     ,0
     ,0
     ,0
		 ,0
     ,isum_2020
from shujuzu.budget_2021_temp04 a
;

drop table if EXISTS shujuzu.budget_2021_temp06;
create table  shujuzu.budget_2021_temp06 as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
		,a.beizhu_item
    ,a.beizhu
    ,sum(min_rate) as min_rate
    ,sum(a.max_rate) as max_rate
    ,sum(a.isum) as isum
		,sum(inum_person) as inum_person
    ,sum(isum_2020) as isum_2020
		,if(sum(isum_2020)<=0 , '新增','') as new_cus
from shujuzu.budget_2021_temp05 a
group by sales_dept,sales_region_new,ccusname,beizhu_item
;

drop table if EXISTS shujuzu.budget_2021_temp07;
create table  shujuzu.budget_2021_temp07 as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
    ,a.beizhu
    ,min(min_rate) as min_rate
    ,max(if(new_cus ='新增',a.max_rate,0)) as max_rate
    ,sum(a.isum) as isum
		,sum(inum_person) as inum_person
    ,sum(isum_2020) as isum_2020
		,GROUP_CONCAT(new_cus) as new_cus
from shujuzu.budget_2021_temp06 a
group by sales_dept,sales_region_new,ccusname,beizhu
;
update shujuzu.budget_2021_temp07
set  new_cus='新增' where new_cus regexp '新增'
;

update shujuzu.budget_2021_temp07
set  new_cus='' where isum=0
;
update shujuzu.budget_2021_temp07
set  beizhu='' where isum=0 and inum_person=0 #计划数量和金额为0，则清除备注
;

drop table if EXISTS shujuzu.budget_2021_temp08;
create table  shujuzu.budget_2021_temp08 as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
    ,min(min_rate) as min_rate
from shujuzu.budget_2021_temp07 a
where LENGTH(beizhu)>1
group by sales_dept,sales_region_new,ccusname
;

drop table if EXISTS shujuzu.budget_2021_newcus;
create table  shujuzu.budget_2021_newcus as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
    ,a.beizhu
    ,b.min_rate
    ,a.max_rate
    ,a.isum
		,a.inum_person
    ,a.isum_2020
		,a.new_cus
from shujuzu.budget_2021_temp07 a
left join shujuzu.budget_2021_temp08 b
on a.sales_dept = b.sales_dept and a.sales_region_new = b.sales_region_new and a.ccusname = b.ccusname
;
select sum(isum),sum(isum_2020)
from shujuzu.budget_2021_newcus
;
select sum(isum)
from pdm.invoice_order
where ddate >= '2020-01-01' and ddate <= '2020-12-31'