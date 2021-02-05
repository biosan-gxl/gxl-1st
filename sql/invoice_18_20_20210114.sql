#志坚总需要统计的连续几年的收入出库装机数据，目前全部为临时表，需要的时候手动修改下
select distinct if_xs
from pdm.invoice_order

DROP TABLE if EXISTS shujuzu.sales_section0;			
CREATE TEMPORARY TABLE shujuzu.sales_section0 as 			
SELECT 			
     cohr	
      ,finnal_ccuscode
      ,finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,DATE_FORMAT(ddate,'%Y-%m-01') as ddate			
     ,citemname as item_name			
     ,year(ddate) as year_
     ,sum(iquantity) as iquantity			
     ,sum(isum) as isum			
FROM pdm.invoice_order			
WHERE ddate >= '2018-01-01' and ddate <= '2020-12-31' 	and item_code <> 'JK0101'		and if_xs is null
GROUP BY cohr,finnal_ccuscode,cinvcode,year_;			



DROP TABLE if EXISTS shujuzu.sales_section1;			
CREATE TEMPORARY TABLE shujuzu.sales_section1 as 			
SELECT 			
     case when cohr='杭州贝生' and b.sales_region_new='西南区' then '西南区'	
	        when cohr='杭州贝生' and b.sales_region_new='西北区' then '西北区'
					when cohr='杭州贝生' and b.sales_region_new='东北区' then '东北区'
					when cohr='杭州贝生'  then '代理商运营'
          when b.sales_region_new is null then '其他'			
     		  else b.sales_region_new 
					end as sales_region_new1	
     ,case when cohr='杭州贝生' then '杭州贝生'
		       else b.sales_dept end as sales_dept1			
     ,a.finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,DATE_FORMAT(ddate,'%Y-%m-01') as ddate			
     ,item_name			
     ,year(ddate) as year_
     ,sum(iquantity) as iquantity			
     ,sum(isum) as isum			
FROM shujuzu.sales_section0	a
left join edw.map_customer b
on a.finnal_ccuscode = b.bi_cuscode
GROUP BY sales_dept1,sales_region_new1,finnal_ccusname,cinvcode,year_;	


-- DROP TABLE if EXISTS shujuzu.sales_section1;			
-- CREATE  TABLE shujuzu.sales_section1 as 			
-- SELECT 			
--      case when cohr='杭州贝生' and b.sales_region_new='西南区' then '西南区'	
-- 	        when cohr='杭州贝生' and b.sales_region_new='西北区' then '西北区'
-- 					when cohr='杭州贝生' and b.sales_region_new='东北区' then '东北区'
-- 					when cohr='杭州贝生'  then '代理商运营'
--           when b.sales_region_new is null then '其他'			
--      		  else b.sales_region_new 
-- 					end as sales_region_new1	
--      ,case when cohr='杭州贝生' then '杭州贝生'
-- 		       else b.sales_dept end as sales_dept
-- 			,cohr		 
--      ,a.finnal_ccusname			
--      ,cbustype			
--      ,cinvcode			
--      ,cinvname			
--      ,DATE_FORMAT(ddate,'%Y-%m-01') as ddate			
--      ,item_name			
--      ,year(ddate) as year_
--      ,iquantity	
--      ,isum		
-- FROM shujuzu.sales_section0	a
-- left join edw.map_customer b
-- on a.finnal_ccuscode = b.bi_cuscode
-- DROP TABLE if EXISTS shujuzu.sales_section2;			
-- CREATE TEMPORARY TABLE shujuzu.sales_section2 as			
-- SELECT 
--      sales_dept			
--      ,sales_region_new1			
--      ,ccusname			
--      ,finnal_ccusname			
--      ,cbustype			
--      ,cinvcode			
--      ,cinvname			
--      ,item_name			
--      ,year_			
--      ,sum(case when left(cinvcode,2)='YQ' and iquantity is null and isum > 0 then 1  #对设备而言，有的设备数量是空，如果是收入大于0，则数量算1.这个只能在表1分月统计后才能这样算，因为有的一个月甚至同一天一个设备有多张票，存在一个设备开多张票的情况			
--                when left(cinvcode,2)='YQ' and iquantity is null and isum < 0 then -1 else iquantity end) as iquantity			
--      ,sum(isum) as isum			
-- FROM shujuzu.sales_section1			
-- GROUP BY sales_region_new1,ccusname,finnal_ccusname,cinvcode,year_;			
			
			
/*SELECT *,case when left(cinvcode,2)='YQ' and iquantity is null and isum > 0 then 1			
          when left(cinvcode,2)='YQ' and iquantity is null and isum < 0 then -1 else iquantity end as qi			
FROM pdm.invoice_order			
WHERE  ddate >= '2016-10-01' and iquantity is null and cinvcode like 'YQ%' 			
ORDER BY ddate*/			
#复核			
/*SELECT sum(isum)			
FROM shujuzu.sales_section;			
SELECT sum(isum)/1000			
FROM pdm.invoice_order			
WHERE ddate >= '2016-10-01' and ddate <= '2020-09-30' and sales_dept <> '供应链中心' and sales_dept <> 'BD部'*/			
			
/*SELECT sum(isum)/1000 as isum			
FROM pdm.invoice_order			
WHERE ddate >='2016-10-01' and ddate <='2017-09-30'*/			
			
			
-- CREATE index index_sales_section1_cinvcode on shujuzu.sales_section2(cinvcode);			
			
DROP TABLE if EXISTS shujuzu.invoice_18_20_20210114;			
CREATE  TABLE shujuzu.invoice_18_20_20210114 as 			
SELECT sales_dept1 as sales_dept			
       ,sales_region_new1				
       ,finnal_ccusname			
       ,cinvcode			
       ,cinvname			
       ,item_name			
       ,cbustype			
       ,b.level_one			
       ,b.equipment			
       ,b.screen_class			
       ,b.business_class			
       ,year_			
       ,iquantity*b.inum_unit_person as iquantity_person					
       ,isum/1000 as isum
       ,b.cinv_own
			 ,b.cinvbrand
			
			 
   ,case when item_name = 'NIPT' then 'NIPT'			
   			when item_name = 'NIPT-Plus' then 'NIPT-Plus'
   			when item_name = 'Free hCGβ（早）' or  item_name = 'PAPP-A' then '早孕'
   			when item_name = 'AFP/Free hCGβ' or  item_name = 'UE3' then '中孕' 
   			when item_name = 'CNV-seq'  then 'CNV-seq' 
   			when item_name like '%全外%'  then 'WES'
   			when item_name = 'GCMS' or  item_name = '遗传代谢病panel' then 'IEM'
   			when item_name = 'TSH' or item_name = 'PKU' or item_name = '17α-OH-P' or item_name = 'G6PD' then '新筛四项'
   			when item_name = '串联试剂' then '串联'
   			when item_name='CMA' and  b.business_class='产品类' then 'CMA自建'
   			when item_name='CMA' and  b.business_class='LDT' then 'CMA外送'
				when item_name='维生素D' then 'VD'
   			when b.cinv_key_2020 = '服务_软件' then '软件'
   			when b.business_class='LDT' then '其他LDT'
   			end as classify
FROM shujuzu.sales_section1 a			
LEFT JOIN edw.map_inventory b			
ON a.cinvcode = b.bi_cinvcode;			
			

-- DROP TABLE if EXISTS shujuzu.test1;			
-- CREATE  TABLE shujuzu.test1 as 
-- select bi_cinvcode,
-- case when level_three = 'NIPT' then 'NIPT'			
--    			when level_three = 'NIPT-Plus' then 'NIPT-Plus'
--    			when level_three = 'Free hCGβ（早）' or  level_three = 'PAPP-A' then '早孕'
--    			when level_three = 'AFP/Free hCGβ' or  level_three = 'UE3' then '中孕' 
--    			when level_three = 'CNV-seq'  then 'CNV-seq' 
--    			when level_three like '%全外%'  then 'WES'
--    			when level_three = 'GCMS' or  level_three = '遗传代谢病panel' then 'IEM'
--    			when level_three = 'TSH' or level_three = 'PKU' or level_three = '17α-OH-P' or level_three = 'G6PD' then '新筛四项'
--    			when level_three = '串联试剂' then '串联'
--    			when level_three='CMA' and  business_class='产品类' then 'CMA自建'
--    			when level_three='CMA' and  business_class='LDT' then 'CMA外送'
--    			when cinv_key_2020 = '服务_软件' then '软件'
--    			when business_class='LDT' then '其他LDT'
--    			end as classify
-- from edw.map_inventory
	
