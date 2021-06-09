-- 1. 筛选出日期为2020-01-01至2021-04-30的所有宝荣产品发货数据
drop table if exists shujuzu.baorong_temp01;
create temporary table shujuzu.baorong_temp01 as 
SELECT 
DATE_FORMAT(ddate,'%Y-%m-01') as ddate
,bi_ccuscode
,bi_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,finnal_ccuscode
,finnal_ccusname
,item_code
,item_name
,cinvbrand
,iquantity
,itaxunitprice
,isum
FROM db_111.sales_dispatch_list
where cinvbrand = '宝荣' and ddate BETWEEN '2020-01-01'  and '2021-04-30' and if_gl = '非关联'
;

-- 2. 按月聚合
drop table if exists shujuzu.baorong_temp02;
create temporary table shujuzu.baorong_temp02 as 
select
ddate
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,item_code
,item_name
,cinvbrand
,sum(iquantity) as dispath_iquantity
,max(itaxunitprice) as dispath_max_price
,min(itaxunitprice) as dispath_min_price
,sum(isum) as dispath_isum
,0 as invoice_iquantity
,0 as invoice_max_price
,0 as invoice_min_price
,0 as invoice_isum
from shujuzu.baorong_temp01
group by bi_ccuscode,finnal_ccuscode,sales_dept,sales_region,dept_zx_21,bi_cinvcode,ddate
;

-- 3. 筛选出所有宝荣产品的开票数据

drop table if exists shujuzu.baorong_temp03;
create temporary table shujuzu.baorong_temp03 as 
SELECT 
DATE_FORMAT(ddate,'%Y-%m-01') as ddate
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,item_code
,item_name
,cinvbrand
,iquantity
,itaxunitprice
,isum
FROM db_111.sales_invoice_list_all
where cinvbrand = '宝荣' and ddate BETWEEN '2020-01-01'  and '2021-04-30' and if_gl = '非关联'
;

-- 4.开票数据按月聚合
drop table if exists shujuzu.baorong_temp04;
create temporary table shujuzu.baorong_temp04 as
select
ddate
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,item_code
,item_name
,cinvbrand
,0 as dispath_iquantity
,0 as dispath_max_price
,0 as dispath_min_price
,0 as dispath_isum
,sum(iquantity) as invoice_iquantity
,max(itaxunitprice) as invoice_max_price
,min(itaxunitprice) as invoice_min_price
,sum(isum) as invoice_isum
from shujuzu.baorong_temp03
group by bi_ccuscode,finnal_ccuscode,sales_dept,sales_region,dept_zx_21,bi_cinvcode,ddate
;

-- 5. 发货开票数据关联
drop table if exists shujuzu.baorong_temp05;
create temporary table shujuzu.baorong_temp05 as
select
ddate
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,item_code
,item_name
,cinvbrand
,dispath_iquantity
,dispath_max_price
,dispath_min_price
,dispath_isum
,invoice_iquantity
,invoice_max_price
,invoice_min_price
,invoice_isum
from shujuzu.baorong_temp02
union all
select
ddate
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,item_code
,item_name
,cinvbrand
,dispath_iquantity
,dispath_max_price
,dispath_min_price
,dispath_isum
,invoice_iquantity
,invoice_max_price
,invoice_min_price
,invoice_isum
from shujuzu.baorong_temp04
;

drop table if exists shujuzu.baorong_temp06;
create temporary table shujuzu.baorong_temp06 as
select
ddate
,bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,sales_dept
,sales_region
,dept_zx_21 
,bi_cinvcode
,bi_cinvname
,item_code
,item_name
,cinvbrand
,sum(dispath_iquantity) as dispath_iquantity
,max(dispath_max_price) as dispath_max_price
,min(dispath_min_price) as dispath_min_price
,sum(dispath_isum) as dispath_isum
,sum(invoice_iquantity) as invoice_iquantity
,max(invoice_max_price) as invoice_max_price
,min(invoice_min_price) as invoice_min_price
,sum(invoice_isum) as invoice_isum
from shujuzu.baorong_temp05
group by bi_ccuscode,finnal_ccuscode,sales_dept,sales_region,dept_zx_21,bi_cinvcode,ddate
;

alter table shujuzu.baorong_temp06 add index(bi_ccuscode),add index(finnal_ccuscode),add index(bi_cinvcode);

-- 找出宝荣产品的合同，取最新合同价
drop table if exists shujuzu.baorong_temp07;
create temporary table shujuzu.baorong_temp07 as
select 
bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,cinvcode
,cinvname
,new_dstart
,new_itaxprice
,new_cdefine12
from db_111.crm_contract a
left join edw.map_inventory b
on a.cinvcode = b.bi_cinvcode
where b.cinvbrand = '宝荣'
;
drop table if exists shujuzu.baorong_temp07a;
create temporary table shujuzu.baorong_temp07a as
select 
bi_ccuscode
,bi_ccusname
,finnal_ccuscode
,finnal_ccusname
,cinvcode
,cinvname
,max(new_dstart) as max_new_dstart
from shujuzu.baorong_temp07 group by bi_ccuscode,finnal_ccuscode,cinvcode
;

drop table if exists shujuzu.baorong_temp08;
create temporary table shujuzu.baorong_temp08 as
select a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.cinvcode
,a.cinvname
,a.new_dstart
,a.new_itaxprice
,a.new_cdefine12
from shujuzu.baorong_temp07 a
left join shujuzu.baorong_temp07a b
on a.bi_ccuscode= b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and a.cinvcode= b.cinvcode
where a.new_dstart = b.max_new_dstart
;

-- 为避免同一份合同同一个产品有多个合同价，取最大的一个
drop table if exists shujuzu.baorong_temp09;
create temporary table shujuzu.baorong_temp09 as
select a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.cinvcode
,a.cinvname
,a.new_dstart
,max(a.new_itaxprice) as new_itaxprice
,a.new_cdefine12
from shujuzu.baorong_temp08 a
group by bi_ccuscode,cinvcode,finnal_ccuscode
;

alter table shujuzu.baorong_temp09 add index(bi_ccuscode),add index(finnal_ccuscode),add index(cinvcode);

drop table if exists shujuzu.baorong;
create  table shujuzu.baorong as
select
a.ddate
,a.bi_ccuscode
,a.bi_ccusname
,a.finnal_ccuscode
,a.finnal_ccusname
,a.sales_dept
,a.sales_region
,a.dept_zx_21 
,a.bi_cinvcode
,a.bi_cinvname
,c.specification_type
,c.inum_unit_person
,a.item_code
,a.item_name
,a.cinvbrand
,a.dispath_iquantity
,a.dispath_max_price
,a.dispath_min_price
,a.dispath_isum
,a.invoice_iquantity
,a.invoice_max_price
,a.invoice_min_price
,a.invoice_isum
,b.new_dstart
,b.new_itaxprice
,b.new_cdefine12
from shujuzu.baorong_temp06 a
left join shujuzu.baorong_temp09 b
on a.bi_ccuscode= b.bi_ccuscode and a.finnal_ccuscode = b.finnal_ccuscode and a.bi_cinvcode = b.cinvcode
left join edw.map_inventory c
on a.bi_cinvcode = c.bi_cinvcode
;

select sum(isum) from shujuzu.baorong_temp01;
select sum(dispath_isum) from shujuzu.baorong;
select sum(isum) from shujuzu.baorong_temp03;
select sum(invoice_isum) from shujuzu.baorong;
