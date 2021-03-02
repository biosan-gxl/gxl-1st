# 1. 线下销售计划分类聚合

#1.1 2021年计划明细与线下整理的产品标准关联，得产品的备注分类

drop table if EXISTS shujuzu.budget_2021_temp01;
create temporary  table  shujuzu.budget_2021_temp01 as 
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
		 ,a.ddate
     ,case when a.item_name='CNV-seq' then 'CNV-seq'
					 when a.item_name='CMA' or a.item_name='CMA设备' then 'CMA' 
					 else b.beizhu
					 end as beizhu_item
		 ,b.beizhu
FROM shujuzu.x_budget_2021 a
left join shujuzu.x_newcus_standard b
on a.cinvcode = b.bi_cinvcode 
;

#1.2 通过销售部门、区域、客户、产品分类聚合，并求得最大成功率、最小成功率，金额、人份数求和
drop table if EXISTS shujuzu.budget_2021_temp02;
create temporary  table  shujuzu.budget_2021_temp02 as
select sales_dept 
      ,a.sales_region_new
      ,a.ccusname
			,beizhu_item
      ,a.beizhu
      ,min(rate) as min_rate
      ,max(rate) as max_rate
      ,sum(isum) as isum
			,sum(inum_person) as inum_person
			,min(ddate) as min_date
from shujuzu.budget_2021_temp01 a
group by sales_dept,sales_region_new,ccusname,beizhu_item 
;

#2. 2020年的收入分类聚合

-- 2.1 2020年收入，并关联线下整理的产品分类
drop table if EXISTS shujuzu.budget_2021_temp03;
create temporary  table  shujuzu.budget_2021_temp03 as
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
#2.2 通过销售部门、区域、客户、产品分类聚合，得2020年个客户分类的收入额
drop table if EXISTS shujuzu.budget_2021_temp04;
create temporary  table  shujuzu.budget_2021_temp04 as
select sales_dept
      ,sales_region_new
      ,a.ccusname
			,beizhu_item
      ,a.beizhu
      ,sum(a.isum) as isum_2020
from shujuzu.budget_2021_temp03 a
group by sales_dept,sales_region_new,ccusname,beizhu_item
;

# 3. 2021年计划与2020年收入关联

# 3.1 2021年计划与2020年收入关联
drop table if EXISTS shujuzu.budget_2021_temp05;
create temporary  table  shujuzu.budget_2021_temp05 as
select
     a.sales_dept
     ,a.sales_region_new
     ,a.ccusname
		 ,a.beizhu_item
     ,a.beizhu
		 ,a.min_date
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
		 ,'2022-01-01' -- 随便写一个大的日期，目的是获得21年客户产品分类的最小计划日期
     ,0
     ,0
     ,0
		 ,0
     ,isum_2020
from shujuzu.budget_2021_temp04 a
;

drop table if EXISTS shujuzu.budget_2021_temp06;
create temporary  table  shujuzu.budget_2021_temp06 as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
		,a.beizhu_item
    ,a.beizhu
		,min(a.min_date) as min_date
    ,sum(min_rate) as min_rate
    ,sum(a.max_rate) as max_rate
    ,sum(a.isum) as isum
		,sum(inum_person) as inum_person
    ,sum(isum_2020) as isum_2020
		,if(sum(isum_2020)<=0 , '新增','') as new_cus
from shujuzu.budget_2021_temp05 a
group by sales_dept,sales_region_new,ccusname,beizhu_item
;

--  drop table if EXISTS shujuzu.budget_2021_temp06;
--  create temporary  table  shujuzu.budget_2021_temp06 as
--  select
--       a.sales_dept
--       ,a.sales_region_new
--       ,a.ccusname
--  		 ,a.beizhu_item
--       ,a.beizhu
--       ,a.min_rate
--       ,a.max_rate
--  		 ,a.min_date
--       ,a.isum
--  		 ,a.inum_person
--       ,b.isum_2020
--  		 ,if(b.isum_2020<=0 ,'新增','') as new_cus -- 客户项目2020年收入小于0，则定义为该项目的新增用户
--    from shujuzu.budget_2021_temp02 a
--    left join shujuzu.budget_2021_temp04 b
--    on  a.sales_dept = b.sales_dept and a.sales_region_new = b.sales_region_new and a.ccusname = b.ccusname and a.beizhu_item = b.beizhu_item
--  ;


# 3.2 按客户分类聚合，求最大成功率，目的是求该项目的新增用户数（只要项目中的一个产品成功，则算成功，因此要计算最大陈功率）
drop table if EXISTS shujuzu.budget_2021_temp07;
create temporary  table  shujuzu.budget_2021_temp07 as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
    ,a.beizhu
		,min(min_date) as min_date
    ,min(min_rate) as min_rate
    ,max(if(new_cus ='新增',a.max_rate,0)) as max_rate
    ,sum(a.isum) as isum
		,sum(inum_person) as inum_person
    ,sum(isum_2020) as isum_2020
		,GROUP_CONCAT(new_cus) as new_cus
from shujuzu.budget_2021_temp06 a
group by sales_dept,sales_region_new,ccusname,beizhu  -- 此处为按严格的分类来聚合，而不是按项目来聚合。之前CMA、CNV_seq是分开的，现在是合一起的
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

# 求的客户的最小成功率，目的是求新增的产诊机构数、区县机构数
drop table if EXISTS shujuzu.budget_2021_temp08;
create temporary  table  shujuzu.budget_2021_temp08 as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
    ,min(min_rate) as min_rate
from shujuzu.budget_2021_temp07 a
where LENGTH(beizhu)>1
group by sales_dept,sales_region_new,ccusname
;
#关联客户的最小成功率
drop table if EXISTS shujuzu.budget_2021_newcus;
create   table  shujuzu.budget_2021_newcus as
select
    a.sales_dept
    ,a.sales_region_new
    ,a.ccusname
    ,a.beizhu
		,a.min_date
		,CONCAT('Q',QUARTER(a.min_date)) as quarter_
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
FROM shujuzu.x_budget_2021
;
select sum(isum)
from pdm.invoice_order
where ddate >= '2020-01-01' and ddate <= '2020-12-31'
