
#客户产品201910-202009的收入、出库数量、最后一次非0开票价，便于对预算做参考

#得到收入
DROP TABLE if EXISTS shujuzu.sales_section1;			
CREATE TEMPORARY TABLE shujuzu.sales_section1 as 			
SELECT 	cohr		
     ,case 			
          when sales_region_new is null then '其他'			
     		  else sales_region_new 
					end as sales_region_new1
		 ,province	
     ,sales_dept	
     ,ccusname
     ,finnal_ccuscode		 
     ,finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,DATE_FORMAT(ddate,'%Y-%m-01') as ddate			
     ,citemname as item_name			
     ,case when ddate >= '2016-10-01' and  ddate <= '2017-09-30' then '1610-1709'			
     		  when ddate >= '2017-10-01' and  ddate <= '2018-09-30' then '1710-1809'	
     			when ddate >= '2018-10-01' and  ddate <= '2019-09-30' then '1810-1909'
     			when ddate >= '2019-10-01' and  ddate <= '2020-09-30' then '1910-2009' 
					end as date_section
     ,sum(iquantity) as iquantity			
     ,sum(isum) as isum			
FROM pdm.invoice_order			
WHERE ddate >= '2016-10-01' and ddate <= '2020-09-30' and sales_dept <> '供应链中心' and sales_dept <> 'BD部'			
GROUP BY cohr,sales_region_new1,ccusname,finnal_ccuscode,cinvcode,year(ddate),month(ddate);			
			
DROP TABLE if EXISTS shujuzu.sales_section2;			
CREATE TEMPORARY TABLE shujuzu.sales_section2 as			
SELECT 
			cohr
     ,sales_dept			
     ,sales_region_new1
		 ,province		 
     ,ccusname
     ,finnal_ccuscode		 
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
GROUP BY cohr,sales_region_new1,ccusname,finnal_ccuscode,cinvcode,date_section;

#得到出库数量
DROP TABLE if EXISTS shujuzu.out_depot_section;			
CREATE TEMPORARY TABLE shujuzu.out_depot_section as 			
SELECT 			
     	cohr		
     ,case 			
          when sales_region_new is null then '其他'			
     		  else sales_region_new 
					end as sales_region_new1
		 ,sales_dept
		 ,province			
     ,ccusname
     ,finnal_ccuscode		 
     ,finnal_ccusname			
     ,cbustype			
     ,cinvcode			
     ,cinvname			
     ,citemname as item_name			
     ,case when ddate >= '2016-10-01' and  ddate <= '2017-09-30' then '1610-1709'			
     		  when ddate >= '2017-10-01' and  ddate <= '2018-09-30' then '1710-1809'	
     			when ddate >= '2018-10-01' and  ddate <= '2019-09-30' then '1810-1909'
     			when ddate >= '2019-10-01' and  ddate <= '2020-09-30' then '1910-2009' 
					end as date_section
     ,sum(inum_person) as iquantity_inum_person			
FROM pdm.outdepot_order			
WHERE ddate >= '2016-10-01' and ddate <= '2020-09-30' and sales_dept <> '供应链中心' and sales_dept <> 'BD部' 			
GROUP BY sales_region_new1,ccusname,finnal_ccuscode,cinvcode,date_section;			#得收入发货人份数的表


DROP TABLE if EXISTS shujuzu.sales_out_section1;			
CREATE TEMPORARY TABLE shujuzu.sales_out_section1 as	
SELECT cohr
           ,sales_dept			
           ,sales_region_new1
      		 ,province		 
           ,ccusname
			     ,finnal_ccuscode		 
           ,finnal_ccusname			
           ,cbustype			
           ,cinvcode			
           ,cinvname			
           ,item_name			
           ,date_section				
           ,sum(isum) as isum
           ,sum(iquantity_inum_person) as iquantity_inum_person	
FROM
      (SELECT 
      			cohr
           ,sales_dept			
           ,sales_region_new1
      		 ,province		 
           ,ccusname
			     ,finnal_ccuscode		 
           ,finnal_ccusname			
           ,cbustype			
           ,cinvcode			
           ,cinvname			
           ,item_name			
           ,date_section				
           ,isum
           ,null as iquantity_inum_person		 
      FROM shujuzu.sales_section2
      UNION
      SELECT 
      			cohr
           ,sales_dept			
           ,sales_region_new1
      		 ,province		 
           ,ccusname
			     ,finnal_ccuscode		 
           ,finnal_ccusname			
           ,cbustype			
           ,cinvcode			
           ,cinvname			
           ,item_name			
           ,date_section				
           ,null
      	   ,iquantity_inum_person	 
      FROM shujuzu.out_depot_section)a
WHERE date_section = '1910-2009'  
GROUP BY cohr,sales_region_new1,ccusname,finnal_ccusname,cinvcode,date_section;

#得客户资质
DROP TABLE if EXISTS shujuzu.map_customer_license;
CREATE TEMPORARY TABLE shujuzu.map_customer_license as
SELECT bi_cuscode
			,bi_cusname
			,finnal_cuscode
			,finnal_ccusname
			,type
			,sales_dept
			,sales_region_new
			,province
			,city
			,ccusgrade_new
			,cus_type
			,ccus_Hierarchy
			,Hospital_grade
			,cus_nature
			,ccus_sname
			,nsieve_mechanism
			,medical_mechanism
			,screen_mechanism
			,license_plate
			,cssc_mechanism
			,tlsc_mechanism
			,tlzd_mechanism
			,case when nsieve_mechanism = 'True' and medical_mechanism = 'True' and screen_mechanism = 'True' then '出防中心（含产筛诊、新筛中心）'
			      when screen_mechanism = '筹' then '产筛机构(筹)'
						when medical_mechanism = '筹' then '产诊机构(筹)'
						when nsieve_mechanism = '筹' then '新筛中心(筹)'
						when nsieve_mechanism = 'True' then '新筛中心'
						when medical_mechanism = 'True' then '产诊机构'
						when screen_mechanism = 'True' then '产筛机构' end as kehuzizhi
FROM edw.map_customer;

#关联客户档案，得客户资质
DROP TABLE if EXISTS shujuzu.sales_out_section2;			
CREATE TEMPORARY TABLE shujuzu.sales_out_section2 as
SELECT a.cohr
           ,a.sales_dept			
           ,a.sales_region_new1
      		 ,a.province
			       ,b.city		 
           ,a.ccusname			
           ,a.finnal_ccusname			
           ,a.cbustype			
           ,a.cinvcode			
           ,a.cinvname			
           ,a.item_name			
           ,a.date_section				
           ,a.isum
           ,a.iquantity_inum_person
					   ,b.kehuzizhi
from  shujuzu.sales_out_section1 a
LEFT JOIN shujuzu.map_customer_license b
ON a.finnal_ccuscode = b.bi_cuscode
;

#关联产品档案，得产品相关信息
DROP TABLE if EXISTS shujuzu.sales_out_section3;			
CREATE TEMPORARY TABLE shujuzu.sales_out_section3 as
SELECT a.cohr
           ,a.sales_dept			
           ,a.sales_region_new1
      		 ,a.province
			     ,a.city		 	
           ,a.finnal_ccusname	 		
           ,a.cbustype			
           ,a.cinvcode			
           ,a.cinvname			
           ,a.item_name			
           ,a.date_section				
           ,sum(a.isum) as isum
           ,sum(a.iquantity_inum_person) as iquantity_inum_person
					 ,a.kehuzizhi
					   ,b.level_one
					   ,b.level_two
					   ,b.equipment
					   ,b.business_class
					   ,b.screen_class
					   ,b.cinvbrand
from  shujuzu.sales_out_section2 a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode
GROUP BY a.finnal_ccusname,a.cinvcode
;

#得最后一次单价，一个最终客户有多个单价即多个直接客户，取最新的价格
DROP TABLE if EXISTS shujuzu.invoice_price;			
CREATE TEMPORARY TABLE shujuzu.invoice_price as
SELECT finnal_ccusname 
     ,cinvcode
     ,person_price
from (SELECT 
           ccusname
           ,finnal_ccusname
           ,cinvcode
           ,itaxunitprice/inum_unit_person as person_price 
      FROM pdm.invoice_price WHERE state = '最后一次价格' ORDER BY start_dt DESC)a
GROUP BY finnal_ccusname,cinvcode
;
#关联最后一次单价
DROP TABLE if EXISTS shujuzu.sales_out_section;			
CREATE  TABLE shujuzu.sales_out_section as
SELECT if(a.cohr = '杭州贝生','杭州贝生','博圣体系') as cohr
           ,a.sales_dept			
           ,a.sales_region_new1
      		 ,a.province
			     ,a.city		 	
           ,a.finnal_ccusname
			     ,a.kehuzizhi
			     ,a.screen_class		 
			     ,a.level_one
				   ,a.level_two
				   ,a.item_name		 
           ,a.cinvcode			
           ,a.cinvname			
           ,a.cbustype
					 ,a.equipment
					 ,a.cinvbrand
           ,a.isum
           ,a.iquantity_inum_person
					 ,round(b.person_price,2) as person_price
					 ,a.business_class
					 ,a.date_section				   
from  shujuzu.sales_out_section3 a
LEFT JOIN  shujuzu.invoice_price b
ON a.finnal_ccusname = b.finnal_ccusname and a.cinvcode = b.cinvcode
ORDER BY cohr,sales_dept,sales_region_new1,province,city,finnal_ccusname
;
SELECT sum(isum)
FROM shujuzu.sales_section2
WHERE date_section = '1910-2009';
SELECT sum(iquantity_inum_person)
FROM shujuzu.out_depot_section
WHERE date_section = '1910-2009';
SELECT sum(isum),sum(iquantity_inum_person)
FROM shujuzu.sales_out_section
;
DELETE
FROM shujuzu.sales_out_section
WHERE level_two = '维保服务' or item_name = '健康检测' ;

