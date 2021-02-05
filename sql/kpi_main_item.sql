DROP table if EXISTS main_item1;
CREATE TEMPORARY TABLE main_item1 as 
SELECT a.*
			,year(ddate) as year_
			,month(ddate) as month_
			,QUARTER(ddate) as quarter
			,b.cinv_key_2020
			,if(a.item_code = 'CQ0706','CNV_seq',b.cinv_key_2020) as main_item
			,b.equipment
			,b.screen_class
			,b.level_three as item_name
FROM report.bonus_base_person a		
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
WHERE (b.cinv_key_2020 REGEXP '甄元LDT|杰毅麦特NIPT|服务_软件|东方海洋VD' or a.item_code = 'CQ0706')
and ddate >='2020-07-01' and ddate <= '2020-12-31';

DROP table if EXISTS main_item01;
CREATE TEMPORARY TABLE main_item01 as 
SELECT a.year_
			,a.month_
			,a.sales_dept
			,a.sales_region_new
			,a.province
			,a.mark_province
			,a.areadirector
			,a.cverifier
			,a.cinv_key_2020
			,a.screen_class
			,a.equipment
			,sum(a.isum) as isum
			,sum(a.isum_budget) as isum_budget 
			,quarter
			,main_item
FROM main_item1 a
WHERE  sales_dept = '销售一部' or sales_dept = '销售二部'
GROUP BY year_,month_,sales_dept,sales_region_new,areadirector,cverifier,cinv_key_2020,screen_class,main_item;

drop table if exists shujuzu.bonus_base_ehr;
CREATE  TABLE if not exists shujuzu.bonus_base_ehr
select 
	   name 
    ,employeestatus
    ,TransitionType
		#,lastworkdate
		,adddate(lastworkdate,1) as lastworkdate
    ,year(adddate(lastworkdate,1)) as year_ 
    ,month(adddate(lastworkdate,1)) as month_ 
from pdm.ehr_employee 
where employeestatus = '离职' and year(lastworkdate) = 2020; 
alter table report.bonus_base_ehr add index (name);

DROP table if EXISTS main_item;
CREATE  TABLE main_item as 
SELECT  a.year_
				,a.month_
				,a.sales_dept
				,a.sales_region_new
				,a.province
				,a.mark_province
				,a.areadirector
				,a.cverifier
				,a.cinv_key_2020
				,a.screen_class
				,a.equipment
				,a.isum
				,a.isum_budget
				,a.quarter
					,b.TransitionType as TransitionType_area
					,b.lastworkdate as lastworkdate_area
					,b.month_ as month_area
					,c.TransitionType as TransitionType_cver
					,c.lastworkdate as lastworkdate_cver
					,c.month_ as month_cver
				,a.main_item
FROM main_item01 a
left join shujuzu.bonus_base_ehr as b 
on a.areadirector = b.name 
left join shujuzu.bonus_base_ehr as c 
on a.cverifier = c.name ;

-- update  main_item set areadirector = '确认空' where TransitionType_area = '被动离职';
-- update  main_item set cverifier = '确认空' where TransitionType_cver = '被动离职';

-- 主动离职的, 根据最后工作日期判断
-- 1. 最后工作日期在Q1, 改 确认空
-- update  main_item set areadirector = '确认空' 
-- where TransitionType_area != '被动离职' and lastworkdate_area is not null 
-- and month_area <= 3;
-- 
-- update  main_item set cverifier = '确认空' 
-- where TransitionType_cver != '被动离职' and lastworkdate_cver is not null 
-- and month_cver <= 3;
-- 
-- -- 2. 最后工作日期在Q2 , Q1不变, 其余改 确认空 
-- update  main_item set areadirector = '确认空' 
-- where (TransitionType_area = '主动离职' or TransitionType_area is null )and lastworkdate_area is not null 
-- and month_area > 3 and month_area <= 6 and month_ >3;
-- 
-- update  main_item set cverifier = '确认空' 
-- where (TransitionType_cver = '主动离职' or TransitionType_cver is null ) and lastworkdate_cver is not null 
-- and month_cver > 3 and month_cver <= 6 and month_ >3;
-- 
-- -- 3. 最后工作日期在Q3 , Q1-Q2不变, 其余改 确认空 
-- update  main_item set areadirector = '确认空' 
-- where (TransitionType_area = '主动离职' or TransitionType_area is null ) and lastworkdate_area is not null 
-- and month_area > 6 and month_area <= 9 and month_ >6;
-- 
-- update  main_item set cverifier = '确认空' 
-- where (TransitionType_cver = '主动离职' or TransitionType_cver is null )  and lastworkdate_cver is not null 
-- and month_cver > 6 and month_cver <= 9 and month_ >6;
-- 
-- -- 4. 最后工作日期在Q4 , Q1-Q3不变, 其余改 确认空 
-- update  main_item set areadirector = '确认空' 
-- where (TransitionType_area = '主动离职' or TransitionType_area is null ) and lastworkdate_area is not null 
-- and month_area > 9 and month_area <= 12 and month_ >9;
-- 
-- update  main_item set cverifier = '确认空' 
-- where (TransitionType_cver = '主动离职' or TransitionType_cver is null )  and lastworkdate_cver is not null 
-- and month_cver > 9 and month_cver <= 12 and month_ >9;


SELECT sum(isum)
FROM main_item1
where sales_dept = '销售一部' or sales_dept = '销售二部';

SELECT sum(isum)
FROM main_item01;

SELECT sum(isum)
FROM main_item;

-- 计算CMA超额单项奖

DROP table if EXISTS year_CMA;
CREATE  TABLE year_CMA as 
SELECT a.*
			,year(ddate) as year_
			,month(ddate) as month_
FROM report.bonus_base_person a		
WHERE  a.item_code = 'CQ0704' and ddate >='2020-01-01' and ddate <= '2020-12-31';

