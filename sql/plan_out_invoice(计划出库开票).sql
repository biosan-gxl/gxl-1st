-- 1. 销售收入数据
-- 1.1 筛选出销售中心、共同承担的数据，并整理销售区域，将辅助、耗材、配套的统一称为其他
drop table if exists test.salse_order_TEMP01;
create temporary table test.salse_order_TEMP01 as 

SELECT sales_dept
      ,case when sales_region regexp '爱尔康|金筛查|联兆' then '其他'
            when sales_region regexp '爱博|河南' then '爱博'
            else sales_region end as sales_region
      ,province
      ,city
      ,finnal_cuscode
      ,finnal_cusname
      ,DATE_FORMAT(date,'%Y-%m-01') as date
      ,if(item_name regexp '辅助|耗材|配套','其他',cbustype) as cbustype
      ,if(item_name regexp '辅助|耗材|配套','其他',cinv_xian) as cinv_xian
      ,if(item_name regexp '辅助|耗材|配套','其他',item_code) as item_code
      ,if(item_name regexp '辅助|耗材|配套','其他',item_name) as item_name
      ,if(item_name regexp '辅助|耗材|配套','其他',equipment) as equipment
      ,if(item_name regexp '辅助|耗材|配套','其他',cinvbrand) as cinvbrand
      ,if(item_name regexp '辅助|耗材|配套','其他',cinvcode) as cinvcode
      ,if(item_name regexp '辅助|耗材|配套','其他',cinvname) as cinvname
      ,iquantity
      ,isum
FROM shujuzu.x_sale_order
where (dept_zx_21 = '共同承担' or dept_zx_21 ='销售中心') and sales_dept regexp '销售' 
;

alter table test.salse_order_TEMP01 add index(cinvcode);

-- 1.2 按客户产品年月聚合，减少数据行数
drop table if exists test.salse_order_TEMP001;
create temporary table test.salse_order_TEMP001 as 

SELECT sales_dept
      ,sales_region
      ,province
      ,city
      ,finnal_cuscode
      ,finnal_cusname
      ,date
      ,cbustype
      ,cinv_xian
      ,item_code
      ,item_name
      ,equipment
      ,cinvbrand
      ,cinvcode
      ,cinvname
      ,sum(iquantity) as iquantity
      ,sum(isum) as isum
FROM test.salse_order_TEMP01
group by sales_dept,sales_region,finnal_cuscode,cinvcode,date
;

alter table test.salse_order_TEMP001 add index(cinvcode);


drop table if exists test.map_inventory;
create temporary table test.map_inventory as
select bi_cinvcode
       ,business_class as cbustype
       ,inum_unit_person
			 ,equipment
			 ,cinvbrand
from edw.map_inventory
;

alter table test.map_inventory add index(bi_cinvcode);

-- 1.3 关联产品档案，目的是计算开票人份数
drop table if exists test.salse_order_TEMP02;
create temporary table test.salse_order_TEMP02 as 
select
     a.sales_dept
     ,a.sales_region
     ,a.province
     ,a.city
     ,a.finnal_cuscode
     ,a.finnal_cusname
     ,a.date
     ,a.cbustype
     ,a.cinv_xian
     ,a.item_code
     ,a.item_name
     ,a.equipment
     ,a.cinvbrand
     ,a.cinvcode
     ,a.cinvname
     ,a.iquantity*b.inum_unit_person as invoice_iquantity_person
     ,a.isum as invoice_isum
     ,0 as out_iquantity_person
     ,0 as plan_iquantity_person
     ,0 as plan_isum
from test.salse_order_TEMP001 a
left join test.map_inventory b
on a.cinvcode = b.bi_cinvcode
;

-- 2. 出库数据
-- 2.1 筛选出销售中心、共同承担的数据，并整理销售区域，将辅助、耗材、配套的统一称为其他
drop table if exists test.out_depot_TEMP001;
create temporary table test.out_depot_TEMP001 as 

SELECT sales_dept
       ,case when sales_region regexp '爱尔康|金筛查|联兆' then '其他'
             when sales_region regexp '爱博|河南' then '爱博'
             else sales_region end as sales_region
       ,province
       ,city
       ,finnal_cuscode
       ,finnal_cusname
       ,DATE_FORMAT(date,'%Y-%m-01') as date
       ,if(item_name regexp '辅助|耗材|配套','其他',cbustype) as cbustype
       ,if(item_name regexp '辅助|耗材|配套','其他',cinv_xian) as cinv_xian
       ,if(item_name regexp '辅助|耗材|配套','其他',item_code) as item_code
       ,if(item_name regexp '辅助|耗材|配套','其他',item_name) as item_name
       ,if(item_name regexp '辅助|耗材|配套','其他',equipment) as equipment
       ,if(item_name regexp '辅助|耗材|配套','其他',cinvbrand) as cinvbrand
       ,if(item_name regexp '辅助|耗材|配套','其他',cinvcode) as cinvcode
       ,if(item_name regexp '辅助|耗材|配套','其他',cinvname) as cinvname
       ,0 as invoice_iquantity_person
       ,0 as invoice_isum
       ,iquantity_person as out_iquantity_person
       ,0 as plan_iquantity_person
       ,0 as plan_isum
FROM shujuzu.x_out_depot
where (dept_zx_21 = '共同承担' or dept_zx_21 ='销售中心') and sales_dept regexp '销售' 
;

-- 2.2 出库数据按照客户产品年月聚合
drop table if exists test.out_depot_TEMP01;
create temporary table test.out_depot_TEMP01 as 

SELECT sales_dept
      ,sales_region
      ,province
      ,city
      ,finnal_cuscode
      ,finnal_cusname
      ,date
      ,cbustype
      ,cinv_xian
      ,item_code
      , item_name
      ,equipment
      ,cinvbrand
      ,cinvcode
      ,cinvname
      ,sum(invoice_iquantity_person) as invoice_iquantity_person
      ,sum(invoice_isum) as invoice_isum
      ,sum(out_iquantity_person) as out_iquantity_person
      ,sum(plan_iquantity_person) as plan_iquantity_person
      ,sum(plan_isum) as plan_isum
FROM test.out_depot_TEMP001
group by sales_dept,sales_region,finnal_cuscode,cinvcode,date
;

-- 3. 销售计划
-- 3.1 销售计划关联产品档案
# 计划
drop table if exists test.plan_21_TEMP01;
create temporary table test.plan_21_TEMP01 as 

SELECT sales_dept
      ,case when sales_region regexp '爱尔康|金筛查|联兆' then '其他'
            when sales_region regexp '爱博|河南' then '爱博'
            else sales_region end as sales_region
      ,province
      ,city
      ,bi_ccuscode
      ,bi_ccusname
      ,date
      ,b.cbustype
      ,cinv_xian
      ,item_code
      ,a.item_name
      ,b.equipment
      ,b.cinvbrand
      ,a.cinvcode
      ,a.cinvname
      ,0 as invoice_iquantity_person
      ,0 as invoice_isum
      ,0 as out_iquantity_person
      ,plan_person as plan_iquantity_person
      ,plan_isum
FROM shujuzu.x_plan_21 a
left join test.map_inventory b
on a.cinvcode = b.bi_cinvcode
;

-- 4. 销售收入、出库、计划表合并
drop table if exists test.plan_out_invoice01;
create temporary table test.plan_out_invoice01 as
select
     a.sales_dept
     ,a.sales_region
     ,a.province
     ,a.city
     ,a.finnal_cuscode
     ,a.finnal_cusname
     ,a.date
     ,a.cbustype
     ,a.cinv_xian
     ,a.item_code
     ,a.item_name
     ,a.equipment
     ,a.cinvbrand
     ,a.cinvcode
     ,a.cinvname
     ,a.invoice_iquantity_person
     ,a.invoice_isum
     ,out_iquantity_person
     ,plan_iquantity_person
     ,plan_isum
from test.salse_order_TEMP02 a
union all
select
     sales_dept
     ,sales_region
     ,province
     ,city
     ,finnal_cuscode
     ,finnal_cusname
     ,date
     ,cbustype
     ,cinv_xian
     ,item_code
     ,item_name
     ,equipment
     ,cinvbrand
     ,cinvcode
     ,cinvname
     ,invoice_iquantity_person
     ,invoice_isum
     , out_iquantity_person
     ,plan_iquantity_person
     ,plan_isum
from test.out_depot_TEMP01
union all
select
     sales_dept
     ,sales_region
     ,province
     ,city
     ,bi_ccuscode
     ,bi_ccusname
     ,date
     ,cbustype
     ,cinv_xian
     ,item_code
     ,item_name
     ,equipment
     ,cinvbrand
     ,cinvcode
     ,cinvname
     ,invoice_iquantity_person
     ,invoice_isum
     , out_iquantity_person
     ,plan_iquantity_person
     ,plan_isum
from test.plan_21_TEMP01
;
-- 5. 得最终表，销售计划、出库、开票
drop table if exists shujuzu.plan_out_invoice;
create  table shujuzu.plan_out_invoice as
select 
     sales_dept
     ,sales_region
     ,province
     ,city
     ,finnal_cuscode
     ,finnal_cusname
     ,date
     ,cbustype
     ,cinv_xian
     ,item_code
     ,item_name
     ,equipment
     ,cinvbrand
     ,cinvcode
     ,cinvname
     ,sum(invoice_iquantity_person) as invoice_iquantity_person
     ,sum(invoice_isum) as invoice_isum
     ,sum(out_iquantity_person) as out_iquantity_person
     ,sum(plan_iquantity_person) as plan_iquantity_person
     ,sum(plan_isum) as plan_isum
from test.plan_out_invoice01
group by sales_dept,sales_region,finnal_cuscode,cinvcode,date
;
-- 6. 复核经过一系列操作后的结果，与原表是否一致
select sum(isum)
from shujuzu.x_sale_order
where (dept_zx_21 = '共同承担' or dept_zx_21 ='销售中心') and sales_dept regexp '销售' ;

select sum(iquantity_person)
from shujuzu.x_out_depot
where (dept_zx_21 = '共同承担' or dept_zx_21 ='销售中心') and sales_dept regexp '销售' ;
select
sum(plan_isum)
FROM shujuzu.x_plan_21
;
select sum(invoice_isum),sum(out_iquantity_person),sum(plan_isum)
from shujuzu.plan_out_invoice