update cusplan_21 set sales_dept = '河南'  where sales_dept = '爱博';
update cusplan_21 set sales_region = '河南'  where sales_region = '爱博';
update cusplan_21 set sales_region = '上海区'  where sales_region = '京沪区';
update cusplan_21 set province = '重庆'  where province = '重庆市';
update planrate_21 set sales_region = '上海区'  where sales_region = '京沪区';
drop table if exists cusplan_21person_TEMP01;
create TEMPORARY table cusplan_21person_TEMP01 as
select a.sales_dept
,a.sales_region
,a.province
,a.city
,a.bi_ccusname
,a.product_line
,a.plan_isum
,b.month
,b.rate
,a.plan_isum* b.rate as rate_isum
from cusplan_21 a
left join planrate_21 b
on a.sales_dept = b.sales_dept and a.sales_region = b.sales_region
order by a.sales_dept
,a.sales_region
,a.city
,a.bi_ccusname
,b.month
;

#七省区域主管
drop table if exists cusplan_21person_TEMP02;
create TEMPORARY table cusplan_21person_TEMP02 as 
select a.sales_dept
,a.sales_region
,a.province
,a.city
,a.bi_ccusname
,a.product_line
,a.plan_isum
,a.month
,a.rate
,a.rate_isum
,b.person_name_ad as zhuguan
from  cusplan_21person_TEMP01 a
left join (select * from person_21 where rule_type = '七省区域主管' )b
on a.sales_region = b.sales_region and a.city = b.city and a.month = b.imonth
;
#七省外区域主管_不分产线

drop table if exists cusplan_21person_TEMP03;
create TEMPORARY table cusplan_21person_TEMP03 as
select a.sales_dept
,a.sales_region
,a.province
,a.city
,a.bi_ccusname
,a.product_line
,a.plan_isum
,a.month
,a.rate
,a.rate_isum
,if(a.zhuguan is null, b.person_name_ad,a.zhuguan) as zhuguan
from  cusplan_21person_TEMP02 a
left join (select * from person_21 where rule_type = '七省外区域主管_不分产线' )b
on a.province = b.province and a.month = b.imonth
;

#七省外区域主管_区分分产线
drop table if exists cusplan_21person_TEMP04;
create TEMPORARY table cusplan_21person_TEMP04 as
select a.sales_dept
,a.sales_region
,a.province
,a.city
,a.bi_ccusname
,a.product_line
,a.plan_isum
,a.month
,a.rate
,a.rate_isum
,if(a.zhuguan is null, b.person_name_ad,a.zhuguan) as zhuguan
from  cusplan_21person_TEMP03 a
left join (select * from person_21 where rule_type = '七省外区域主管_区分产线' )b
on a.sales_region = b.sales_region and a.product_line = b.product_line and a.month = b.imonth
;
drop table if exists cusplan_21person_TEMP05;
create TEMPORARY table cusplan_21person_TEMP05 as
select a.sales_dept
,a.sales_region
,a.province
,a.city
,a.bi_ccusname
,a.product_line
,a.plan_isum
,a.month
,a.rate
,a.rate_isum
,a.zhuguan
,b.person_name_ad as yixian
from  cusplan_21person_TEMP04 a
left join (select * from person_21 where rule_type = '销售负责人_不分产线' )b
on a.sales_region = b.sales_region and a.bi_ccusname = b.bi_ccusname and a.month = b.imonth
;


drop table if exists cusplan_21person;
create  table cusplan_21person as
select a.sales_dept
,a.sales_region
,a.province
,a.city
,a.bi_ccusname
,a.product_line
,a.plan_isum
,a.month
,a.rate
,a.rate_isum
,a.zhuguan
,if(a.yixian is null, b.person_name_ad, a.yixian)as yixian
from  cusplan_21person_TEMP05 a
left join (select * from person_21 where rule_type = '销售负责人_区分产线' )b
on a.sales_region = b.sales_region and a.bi_ccusname = b.bi_ccusname  and a.product_line = b.product_line and a.month = b.imonth
;

select sum(plan_isum)
from cusplan_21;
select sum(rate_isum)
from cusplan_21person;