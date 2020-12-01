-- 1.取2018年后的销售收入数据，取最终客户，如果最终客户为NULL，则取直接客户；取2020年的调整后计划
drop table if exists shujuzu.invoice_tem00;
create temporary table shujuzu.invoice_tem00 as
SELECT 
     if(cohr= '杭州贝生','杭州贝生','博圣体系') as cohr
     ,if(finnal_ccuscode is null,ccuscode,finnal_ccuscode) as ccuscode
     ,if(finnal_ccusname is null,ccusname,finnal_ccusname) as ccusname 
     ,DATE_FORMAT(ddate,'%Y-%m-01') as ddate
		 ,year(ddate) as year_
		 ,month(ddate) as month_
     ,cbustype
     ,cinvcode
     ,cinvname
     ,item_code
     ,citemname as item_name
     ,isum
		 ,0 as isum_budget
FROM pdm.invoice_order
where ddate >= '2018-01-01' and item_code <> 'JK0101'
union all
SELECT cohr
      ,ccuscode
      ,ccusname
      ,ddate
      ,year(ddate) as year_
      ,month(ddate) as month_ 
      ,cbustype
      ,bi_cinvcode as cinvcode
      ,bi_cinvname as cinvname
      ,item_code
      ,item_name
      ,0 as isum
      ,isum_budget
from edw.x_sales_budget_20
;


-- 1.1 分组求和，目的是将收入和计划合一张表
drop table if exists shujuzu.invoice_tem01;
create temporary table shujuzu.invoice_tem01 as
SELECT cohr
      ,ccuscode
      ,ccusname
      ,ddate
      ,year_
      ,month_ 
      ,cbustype
      ,cinvcode
      ,cinvname
      ,item_code
      ,item_name
      ,sum(isum) as isum
      ,sum(isum_budget) as isum_budget
from shujuzu.invoice_tem00
group by cohr,ccuscode,ddate,cinvcode
;


-- 2.关联客户档案，得到最终客户的区域划分
drop table if exists shujuzu.invoice_tem02;
create temporary table shujuzu.invoice_tem02 as
SELECT cohr 
		 ,concat(a.ccuscode,a.item_code,a.cbustype) as concatid
		 ,if(a.cohr = '杭州贝生','杭州贝生',b.sales_dept) as sales_dept
		 ,if(a.cohr = '杭州贝生','杭州贝生',b.sales_region_new) as sales_region_new
     ,a.ccuscode
     ,a.ccusname 
     ,a.ddate
		 ,a.year_
		 ,a.month_
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.item_code
     ,a.item_name
     ,a.isum
		 ,a.isum_budget
FROM shujuzu.invoice_tem01 a
left join edw.map_customer b
on a.ccuscode = b.bi_cuscode 
;

alter table shujuzu.invoice_tem02 add index(concatid);
alter table shujuzu.invoice_tem02 add index(ddate);
alter table shujuzu.invoice_tem02 add index(year_);
alter table shujuzu.invoice_tem02 add index(month_);


-- 3.取线下确认的客户项目负责人，匹配到收入的表，得到实际的客户项目负责人
-- 3.1 实际每年每月的线下确认的客户项目负责人
drop table if exists shujuzu.cusperson_tem01;
create temporary table shujuzu.cusperson_tem01 as
select 
			concat(bi_cuscode,item_code,cbustype) as concatid
     ,start_dt
     ,end_dt
     ,bi_cuscode
     ,bi_cusname
     ,item_code
     ,item_name
     ,areadirector
     ,cverifier
		 ,cbustype
from edw.x_cusitem_person
;
alter table shujuzu.cusperson_tem01 add index(concatid);
alter table shujuzu.cusperson_tem01 add index(start_dt);
alter table shujuzu.cusperson_tem01 add index(end_dt);

-- 3.2 取2020年的线下客户项目负责人，用于同比到其他年份
drop table if exists shujuzu.cusperson_tem02;
create temporary table shujuzu.cusperson_tem02 as
select 
			concat(bi_cuscode,item_code,cbustype) as concatid
     ,month(start_dt) as start_month
     ,month(end_dt) as end_month
     ,bi_cuscode
     ,bi_cusname
     ,item_code
     ,item_name
     ,areadirector
     ,cverifier
		 ,cbustype
from edw.x_cusitem_person
where start_dt >= '2020-01-01'
;
alter table shujuzu.cusperson_tem02 add index(concatid);
alter table shujuzu.cusperson_tem02 add index(start_month);
alter table shujuzu.cusperson_tem02 add index(end_month);

-- 3.2 匹配收入表

drop table if exists shujuzu.invoice_tem03;
create temporary table shujuzu.invoice_tem03 as
select a.concatid
		 ,a.sales_dept
		 ,a.sales_region_new
     ,a.ccuscode
     ,a.ccusname 
     ,a.ddate
		 ,a.year_
		 ,a.month_
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.item_code
     ,a.item_name
		 ,b.areadirector
		 ,b.cverifier
     ,a.isum
		 ,a.isum_budget
from shujuzu.invoice_tem02 a
left join shujuzu.cusperson_tem01 b
on a.concatid = b.concatid and a.ddate >= b.start_dt and a.ddate <= b.end_dt
;

-- 3.3 因19年的客户项目负责人时间有交叉，因此用group by 随机取一条
drop table if exists shujuzu.invoice_tem04;
create temporary table shujuzu.invoice_tem04 as
select a.concatid
		 ,a.sales_dept
		 ,a.sales_region_new
     ,a.ccuscode 
     ,a.ccusname 
     ,a.ddate
		 ,a.year_
		 ,a.month_
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.item_code
     ,a.item_name
		 ,a.areadirector
		 ,a.cverifier
     ,a.isum
		 ,a.isum_budget
from shujuzu.invoice_tem03 a
group by concatid,sales_region_new,cinvcode,ddate
;

-- 4. 用2020年的负责人来同理处理历史年份的负责人
drop table if exists shujuzu.invoice_person;
create  table shujuzu.invoice_person as
select a.concatid
		 ,a.sales_dept
		 ,a.sales_region_new
     ,a.ccuscode
     ,a.ccusname 
     ,a.ddate
		 ,a.year_
		 ,a.month_
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.item_code
     ,a.item_name
		 ,a.areadirector
		 ,a.cverifier
		 ,b.areadirector as areadirector_2020
		 ,b.cverifier as cverifier_2020
     ,a.isum
		 ,a.isum_budget
from shujuzu.invoice_tem04 a
left join shujuzu.cusperson_tem02 b
on a.concatid = b.concatid and a.month_ >= b.start_month and a.month_ <= b.end_month
;
#复核
SELECT sum(isum),sum(isum_budget)
from shujuzu.invoice_tem01;
select sum(isum),sum(isum_budget)
from shujuzu.invoice_person;

