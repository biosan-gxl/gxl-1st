#志坚总需要统计的连续几年的收入出库装机数据，目前全部为临时表，需要的时候手动修改下

DROP TABLE if EXISTS shujuzu.sales_section1;			
CREATE TEMPORARY TABLE shujuzu.sales_section1 as 			
SELECT 			
     case when cohr='杭州贝生' then '杭州贝生'			
          when sales_region_new is null then '其他'			
     		  else sales_region_new 
					end as sales_region_new1	
     ,if(cohr='杭州贝生' ,'杭州贝生',sales_dept) as sales_dept			
     ,ccusname			
     ,finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,DATE_FORMAT(ddate,'%Y-%m-01') as ddate			
     ,citemname as item_name			
     ,year(ddate) as date_section
     ,sum(iquantity) as iquantity			
     ,sum(isum) as isum			
FROM pdm.invoice_order			
WHERE ddate >= '2017-01-01' and ddate <= '2020-12-31' and sales_dept <> '供应链中心' and sales_dept <> 'BD部'			
GROUP BY sales_region_new1,ccusname,finnal_ccusname,cinvcode,year(ddate),month(ddate);			
			
DROP TABLE if EXISTS shujuzu.sales_section2;			
CREATE TEMPORARY TABLE shujuzu.sales_section2 as			
SELECT 
     sales_dept			
     ,sales_region_new1			
     ,ccusname			
     ,finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,item_name			
     ,date_section			
     ,sum(case when left(cinvcode,2)='YQ' and iquantity is null and isum > 0 then 1  #对设备而言，有的设备数量是空，如果是收入大于0，则数量算1.这个只能在表1分月统计后才能这样算，因为有的一个月甚至同一天一个设备有多张票，存在一个设备开多张票的情况			
               when left(cinvcode,2)='YQ' and iquantity is null and isum < 0 then -1 else iquantity end) as iquantity			
     ,sum(isum) as isum			
FROM shujuzu.sales_section1			
GROUP BY sales_region_new1,ccusname,finnal_ccusname,cinvcode,date_section;			
			
			
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
			
			
CREATE index index_sales_section1_cinvcode on shujuzu.sales_section2(cinvcode);			
			
DROP TABLE if EXISTS shujuzu.sales_section;			
CREATE  TABLE shujuzu.sales_section as 			
SELECT sales_dept			
       ,sales_region_new1			
       ,ccusname			
       ,finnal_ccusname			
       ,cinvcode			
       ,cinvname			
       ,item_name			
       ,cbustype			
       ,b.level_one			
       ,b.equipment			
       ,b.screen_class			
       ,b.business_class			
       ,date_section			
       ,iquantity*b.inum_unit_person as iquantity_person			
       ,iquantity			
       ,isum/1000 as isum			
,case 		
			when item_name regexp 'NIPT'  and b.cinvbrand REGEXP '甄元|杰毅麦特' then '杰毅NIPT(含plus)'
			when item_name regexp 'NIPT' then '其他NIPT'
			when item_name = 'Free hCGβ（早）' or  item_name = 'PAPP-A' then '早孕'
			when item_name = 'AFP/Free hCGβ' or  item_name = 'UE3' then '中孕' 
			when item_name = 'CNV-seq'  then 'CNV-seq' 
			when item_name like '%全外%'  then 'WES'
			when item_name = 'GCMS' or  item_name = '遗传代谢病panel' then 'IEM'
			when item_name = 'TSH' or item_name = 'PKU' or item_name = '17α-OH-P' or item_name = 'G6PD' then '新筛四项'
			when item_name = '串联试剂' then '串联'
			when item_name='CMA' and  b.business_class='产品类' then 'CMA自建'
			when item_name='CMA' and  b.business_class='LDT' then 'CMA外送'
			when b.cinv_key_2020 = '服务_软件' then '软件'
			when b.equipment = '是' then '设备'
			when item_name = '子痫前期预测' then '子痫(试剂+外送)'
			when item_name = '耳聋基因'  and business_class = '产品类' then '耳聋试剂'
			when item_name regexp '地贫' and business_class = '产品类' then '地贫试剂'
			when b.business_class='LDT' then '其他LDT'
			else '其他'
			end as classify
			,b.cinvbrand
FROM shujuzu.sales_section2 a			
LEFT JOIN edw.map_inventory b			
ON a.cinvcode = b.bi_cinvcode;			
			
#出库			
DROP TABLE if EXISTS shujuzu.out_depot_section1;			
CREATE TEMPORARY TABLE shujuzu.out_depot_section1 as 			
SELECT 			
     case when cohr='杭州贝生' then '杭州贝生'			
          when sales_region_new is null then '其他'			
     		  else sales_region_new 
				  end as sales_region_new1	
     ,if(cohr='杭州贝生' ,'杭州贝生',sales_dept) as sales_dept			
     ,ccusname			
     ,finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,citemname as item_name			
     ,year(ddate) as date_section
     ,sum(inum_person) as iquantity_inum_person			
FROM pdm.outdepot_order			
WHERE ddate >= '2017-01-01' and ddate <= '2020-12-31' and sales_dept <> '供应链中心' and sales_dept <> 'BD部' 			
GROUP BY sales_region_new1,ccusname,finnal_ccusname,cinvcode,date_section;			
			
DROP TABLE if EXISTS shujuzu.out_depot_section;			
CREATE  TABLE shujuzu.out_depot_section as 			
SELECT sales_dept			
      ,sales_region_new1			
      ,ccusname			
      ,finnal_ccusname			
      ,cinvcode			
      ,cinvname			
      ,item_name			
      ,cbustype			
      ,date_section			
      ,iquantity_inum_person			
      ,case when item_name regexp 'NIPT'  and b.cinvbrand REGEXP '甄元|杰毅麦特' then '杰毅NIPT(含plus)'
			when item_name regexp 'NIPT' then '其他NIPT'
			when item_name = 'PAPP-A' then 'PAPP-A'
			when item_name = 'AFP/Free hCGβ'  then 'AFP/Free hCGβ' 
			when item_name = 'CNV-seq'  then 'CNV-seq' 
			when item_name like '%全外%'  then 'WES'
			when item_name = 'GCMS' or  item_name = '遗传代谢病panel' then 'IEM'
			when item_name = 'TSH'  then 'TSH'
			when item_name = '串联试剂' then '串联'
			when item_name='CMA' and  b.business_class='产品类' then 'CMA自建'
			when item_name='CMA' and  b.business_class='LDT' then 'CMA外送'
			when b.cinv_key_2020 = '服务_软件' then '软件'
			when b.equipment = '是' then '设备'
			when item_name = '子痫前期预测' then '子痫(试剂+外送)'
			when item_name = '耳聋基因'  and business_class = '产品类' then '耳聋试剂'
			when item_name regexp '地贫' and business_class = '产品类' then '地贫试剂'
			when b.business_class='LDT' then '其他LDT'
			else '其他'
			end as classify
FROM shujuzu.out_depot_section1 a
LEFT JOIN edw.map_inventory b			
ON a.cinvcode = b.bi_cinvcode;			
			
#出库只取自定义的项目及设备，其余不需要统计数量，因此直接删掉			
DELETE FROM shujuzu.out_depot_section			
WHERE classify is null;			
			
#装机			
DROP TABLE if EXISTS shujuzu.euipment_section0;			
CREATE TEMPORARY TABLE shujuzu.euipment_section0 as 			
SELECT bi_cusname			
      ,bi_cinvcode			
      ,bi_cinvname			
      ,year(new_installation_date) as date_section
FROM edw.crm_account_equipments			
WHERE new_installation_date >= '2017-01-01' and new_installation_date <= '2020-12-31' ;		

DELETE FROM shujuzu.euipment_section0			
WHERE date_section is null;			
			
DROP TABLE if EXISTS shujuzu.euipment_section01;			
CREATE TEMPORARY TABLE shujuzu.euipment_section01 as 			
SELECT a.bi_cusname			
      ,a.bi_cinvcode			
      ,a.bi_cinvname			
      ,b.level_three			
      ,1 as quantity			
      ,a.date_section			
FROM shujuzu.euipment_section0 a			
LEFT JOIN edw.map_inventory b			
ON a.bi_cinvcode = b.bi_cinvcode;			
			
DROP TABLE if EXISTS shujuzu.euipment_section1;			
CREATE  TABLE shujuzu.euipment_section1 as 			
SELECT b.sales_region_new			
      ,a.bi_cusname			
      ,a.bi_cinvcode			
      ,a.bi_cinvname			
      ,a.level_three			
      ,quantity			
      ,a.date_section			
FROM shujuzu.euipment_section01 a			
LEFT JOIN edw.map_customer b			
ON a.bi_cusname = b.bi_cusname;			
