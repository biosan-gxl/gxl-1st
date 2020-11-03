#源表：report.kpi_02_newcus_base_person，pdm.invoice_order，edw.x_sales_budget_20，shujuzu.gxl_cusitem_person
#开发日期 2020-07-09
#从report.kpi_02_newcus_base_person得到新客户新项目是计划内、计划外
DROP TABLE if EXISTS shujuzu.cus_item_new1;
CREATE TEMPORARY TABLE shujuzu.cus_item_new1 as
SELECT a.sales_dept
			,a.sales_region_new
			,a.province
			,a.new_item
			,a.ccusname
			,a.mark_2
			,b.act_plan
			,b.ddate as plan_ddate
			,c.act
			,c.ddate
			,b.plan_success_rate
			,a.areadirector_result
from (SELECT DISTINCT a.sales_dept
						,a.sales_region_new
						,a.province
						,IF(new_item is null,'新客户',new_item) as new_item
						,a.ccusname
						,mark_2
						,areadirector_result
      from report.kpi_02_newcus_base_person a)a
LEFT JOIN (SELECT ccusname,IF(new_item is null,'新客户',new_item) as new_item,ddate,'计划内' as act_plan,plan_success_rate
      from report.kpi_02_newcus_base_person
			WHERE mark_1='plan' 
		  GROUP BY ccusname,new_item)b
	on a.ccusname=b.ccusname and a.new_item = b.new_item
LEFT JOIN (SELECT ccusname,IF(new_item is null,'新客户',new_item) as new_item,ddate,'已完成' as act
      from report.kpi_02_newcus_base_person
			WHERE mark_1='act' 
			GROUP BY ccusname,new_item)c
	on  a.ccusname=c.ccusname and a.new_item = c.new_item;


#20年收入，增加新项目字段
DROP TABLE if EXISTS shujuzu.cus_item_new2;
CREATE TEMPORARY TABLE shujuzu.cus_item_new2 as
SELECT finnal_ccusname,new_item,sum(isum) as 20isum
FROM 
(SELECT finnal_ccusname
			,isum
			,CASE
				WHEN
					cinvcode in ("SJ02030","SJ02027","SJ02029") THEN
						"杰毅NIPT" 
						WHEN item_code IN ( "CQ0704", "CQ0705" ) THEN
						"CMA(含设备)" 
						WHEN item_code = "CQ0608" THEN
						"早孕" -- 只取CQ0608
						
						WHEN cinvcode = "TEMP2020_1" THEN
						"东方海洋VD" -- 临时的编码, 后面有正式的需要修改
						
						WHEN item_code IN ( "XS0501", "XS0909" ) THEN
						"耳聋基因" -- 加XS0909
						
						WHEN item_code IN ( "XS0301", "XS0201" ) THEN
						"串联试剂(含设备)"  else null end as new_item
FROM pdm.invoice_order
WHERE ddate >= '2020-01-01' and cohr <> '杭州贝生')a
GROUP BY finnal_ccusname,new_item;


#20年计划，增加新项目字段
DROP TABLE if EXISTS shujuzu.cus_item_new3;
CREATE TEMPORARY TABLE shujuzu.cus_item_new3 as
SELECT bi_cusname,new_item,sum(isum_budget) as 20budget
FROM 
(SELECT bi_cusname
			,isum_budget
			,CASE
				WHEN
					bi_cinvcode in ("SJ02030","SJ02027","SJ02029") THEN
						"杰毅NIPT" 
						WHEN item_code IN ( "CQ0704", "CQ0705" ) THEN
						"CMA(含设备)" 
						WHEN item_code = "CQ0608" THEN
						"早孕" -- 只取CQ0608
						
						WHEN cinvcode = "TEMP2020_1" THEN
						"东方海洋VD" -- 临时的编码, 后面有正式的需要修改
						
						WHEN item_code IN ( "XS0501", "XS0909" ) THEN
						"耳聋基因" -- 加XS0909
						
						WHEN item_code IN ( "XS0301", "XS0201" ) THEN
						"串联试剂(含设备)"  else null end as new_item
FROM edw.x_sales_budget_20
WHERE ddate >= '2020-01-01' and cohr <> '杭州贝生')a
GROUP BY bi_cusname,new_item;

#如果新客户，按客户聚合收入和计划
DROP TABLE if EXISTS shujuzu.cus_item_new4;
CREATE TEMPORARY TABLE shujuzu.cus_item_new4 as
SELECT a.sales_dept
			,a.sales_region_new
			,a.province
			,a.new_item
			,a.ccusname
			,a.mark_2
			,a.act_plan
			,a.plan_ddate
			,a.act
			,a.ddate as act_ddate
			,IF(a.mark_2 = 'newcus',b.isum,null) as isum
			,IF(a.mark_2 = 'newcus',c.isum_budget,null) as isum_budget
			,a.plan_success_rate
			,a.areadirector_result

FROM shujuzu.cus_item_new1 a
LEFT JOIN (SELECT finnal_ccusname,sum(20isum) as isum
					FROM shujuzu.cus_item_new2
					GROUP BY finnal_ccusname)b
ON a.ccusname = b.finnal_ccusname 

LEFT JOIN (SELECT bi_cusname,sum(20budget) as isum_budget
					FROM shujuzu.cus_item_new3
					GROUP BY bi_cusname)c
ON a.ccusname = c.bi_cusname ;

#如果是新项目，按项目聚合收入和计划
DROP TABLE if EXISTS shujuzu.cus_item_new5;
CREATE TEMPORARY TABLE shujuzu.cus_item_new5 as
SELECT a.sales_dept
			,a.sales_region_new
			,a.province
			,a.new_item
			,a.ccusname
			,a.mark_2
			,a.act_plan
			,a.plan_ddate
			,a.act
			,a.act_ddate
      ,IF(a.mark_2 = 'newitem',b.isum,a.isum) as isum
			,IF(a.mark_2 = 'newitem',c.isum_budget,a.isum_budget) as isum_budget
			,a.plan_success_rate
			,a.areadirector_result
FROM shujuzu.cus_item_new4 a
LEFT JOIN (SELECT finnal_ccusname,new_item,sum(20isum) as isum
					FROM shujuzu.cus_item_new2
					GROUP BY finnal_ccusname,new_item)b
ON a.ccusname = b.finnal_ccusname  and a.new_item = b.new_item

LEFT JOIN (SELECT bi_cusname,new_item,sum(20budget) as isum_budget
					FROM shujuzu.cus_item_new3
					GROUP BY bi_cusname,new_item)c
ON a.ccusname = c.bi_cusname and a.new_item = c.new_item;

#加上处理的主管，客户资质，新客户已完成的项目
DROP TABLE if EXISTS shujuzu.cus_item_new;
CREATE  TABLE shujuzu.cus_item_new as
SELECT a.sales_dept
			,a.sales_region_new
			,a.province
			,a.ccusname
			,case when c.nsieve_mechanism = 'True' then '新筛中心'
		  when c.nsieve_mechanism = '筹' then '新筛中心(筹)'
			WHEN c.medical_mechanism = 'True' then '产诊中心'
			WHEN c.medical_mechanism = '筹' then '产诊中心(筹)'
			WHEN c.screen_mechanism = 'True' then '产筛中心'
			WHEN c.screen_mechanism = '筹' then '产筛中心(筹)'
			else null end as zizhi
			,a.new_item
			,a.mark_2
			,a.act_plan
			,a.plan_ddate
			,a.isum_budget
			,a.act
			,a.act_ddate
      ,a.isum
			,IF(mark_2 = 'newcus',d.itemname_concat,null) as itemname_concat
				,a.plan_success_rate
			,a.areadirector_result
FROM shujuzu.cus_item_new5 a
LEFT JOIN edw.map_customer c
ON a.ccusname = c.bi_cusname
LEFT JOIN (SELECT finnal_ccusname ,GROUP_CONCAT(DISTINCT citemname) as itemname_concat
						FROM pdm.invoice_order
						WHERE year(ddate) = 2020
						GROUP BY finnal_ccusname)d
ON a.ccusname = d.finnal_ccusname;

UPDATE shujuzu.cus_item_new
SET new_item = null WHERE mark_2='newcus';


