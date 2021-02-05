-- 得2020年客户非设备销售情况的负责人
drop table if exists shujuzu.kpi_cus_person_temp01;
create temporary table shujuzu.kpi_cus_person_temp01 as
SELECT sales_dept
      ,sales_region_new
      ,ccuscode
      ,bi_cusname
			,b.screen_class
      ,areadirector
      ,cverifier
      ,isum
      ,isum_budget
FROM report.bonus_base_person a
left join edw.map_inventory b
on a.cinvcode = b.bi_cinvcode
where ddate >= '2020-01-01' and ddate <= '2020-12-31' and sales_dept like '销售%' and sales_region_new <> '其他' and b.equipment <> '是'
;
-- 得每个人所负责的客户
drop table if exists shujuzu.kpi_cus_person_temp02;
create temporary table shujuzu.kpi_cus_person_temp02 as
SELECT sales_dept
      ,sales_region_new
      ,ccuscode
      ,bi_cusname
      ,areadirector
from shujuzu.kpi_cus_person_temp01
;
-- 不重复的人
drop table if exists shujuzu.kpi_cus_person_temp03;
create temporary table shujuzu.kpi_cus_person_temp03 as
SELECT sales_dept
      ,sales_region_new
      ,ccuscode
      ,bi_cusname
      ,cverifier
from shujuzu.kpi_cus_person_temp01 
union
SELECT sales_dept
      ,sales_region_new
      ,ccuscode
      ,bi_cusname
      ,areadirector
from shujuzu.kpi_cus_person_temp02
;

-- 非设备的应收回款过滤
drop table if exists shujuzu.kpi_cus_person_temp04;
create temporary table shujuzu.kpi_cus_person_temp04 as
SELECT sales_dept
      ,sales_region_new
      ,ccuscode
      ,ccusname
			,year(ddate) as year_
			,month(ddate) as month_
			,amount_plan
			,amount_act
from report.kpi_03_ar_plan_base_person
where ddate >= '2020-01-01' and ddate <= '2020-12-31' and sales_dept like '销售%' and sales_region_new <> '其他' and ar_class <> '设备'
;

-- 计算当期应收、回款，当期的计划=历史回款+当月计划
drop table if exists shujuzu.kpi_cus_person_temp05;
create temporary table shujuzu.kpi_cus_person_temp05 as
SELECT sales_dept
      ,sales_region_new
      ,ccuscode
      ,ccusname
			,sum(if(month_< 12,amount_act,amount_plan)) as amount_plan
			,sum(amount_act) as amount_act
from shujuzu.kpi_cus_person_temp04
group by sales_dept,sales_region_new,ccuscode
;

-- 以客户负责人为左表，关联客户的应收、回款
drop table if exists shujuzu.kpi_cus_person_arplan;
create  table shujuzu.kpi_cus_person_arplan as
select a.sales_dept
      ,a.sales_region_new
      ,a.ccuscode
      ,a.bi_cusname
      ,a.cverifier
			,b.amount_plan
			,b.amount_act
from shujuzu.kpi_cus_person_temp03 a
left join shujuzu.kpi_cus_person_temp05 b
on a.ccuscode = b.ccuscode
;

-- 计算副省区所负责的客户，只要有诊断业务的客户就算副省区负责的客户
drop table if exists shujuzu.kpi_cus_person_temp06;
create temporary table shujuzu.kpi_cus_person_temp06 as
 select      
			 sales_dept
      ,sales_region_new
      ,ccuscode
      ,bi_cusname
from shujuzu.kpi_cus_person_temp01
where screen_class = '诊断'
group by sales_dept,sales_region_new,ccuscode
;

 -- 匹配副省区负责的客户的计划和回款
 drop table if exists shujuzu.kpi_cus_person_arplan_fushengqu;
create  table shujuzu.kpi_cus_person_arplan_fushengqu as
 select      
			 a.sales_dept
      ,a.sales_region_new
			,case when a.sales_region_new = '浙江' then '杨晓利'
						when a.sales_region_new = '山东' then '柳汝忠'
						when a.sales_region_new = '江苏' then '蒋赛君'
						when a.sales_region_new = '福建' then '陈阳春'
				end as fushengqu
      ,a.ccuscode
      ,a.bi_cusname
			,b.amount_plan
			,b.amount_act
	from shujuzu.kpi_cus_person_temp06 a
	left join shujuzu.kpi_cus_person_temp05 b
	on a.ccuscode = b.ccuscode