#目的是看有特殊条款的合同，是否达标
#先将pdm.cm_contractch的产品按项目分类，只取合同涉及的一些项目													
DROP table if EXISTS shujuzu.contract_mid1;												
CREATE TEMPORARY table shujuzu.contract_mid1 as										
SELECT a.strcontractid											
			,a.bi_cuscode										
			,a.bi_cusname										
			,a.bi_cinvcode										
			,a.bi_cinvname										
			,a.y_mon										
			,a.inum_person_out										
			,if(b.level_three='AFP/Free hCGβ' or b.level_three = 'UE3','中孕三项',b.level_three) as content										
FROM pdm.cm_contract a													
LEFT JOIN edw.map_inventory b													
ON a.bi_cinvcode = b.bi_cinvcode													
WHERE b.level_three = '串联试剂' or b.level_three = 'CMA' or b.level_three = 'AFP/Free hCGβ' or b.level_three = 'UE3';													
													
#找出合同生效后的第一次发货日期													
DROP table if EXISTS shujuzu.contract_mid2;													
CREATE TEMPORARY table shujuzu.contract_mid2 as													
SELECT a.strcontractid													
			,a.bi_cusname										
			,a.content										
			,min(y_mon) as out_1st										
			,b.assess_mon										
FROM shujuzu.contract_mid1 a													
LEFT JOIN (SELECT DISTINCT strcontractid,strcontractstartdate,assess_mon													
						FROM shujuzu.contract_standad) b							
ON a.strcontractid = b.strcontractid													
WHERE a.y_mon >= b.strcontractstartdate													
GROUP BY strcontractid,content;													
													
#找出发货的日期距第一次发货的年数													
DROP table if EXISTS shujuzu.contract_mid3;													
CREATE TEMPORARY table shujuzu.contract_mid3 as													
SELECT a.strcontractid													
			,a.bi_cuscode										
			,a.bi_cusname										
			,a.bi_cinvcode										
			,a.bi_cinvname										
			,a.y_mon										
			,a.inum_person_out										
			,a.content										
			,b.out_1st										
			,b.assess_mon										
			,if(b.out_1st > a.y_mon,-1,TIMESTAMPDIFF(year,b.out_1st,a.y_mon)+1) as until_year										
FROM shujuzu.contract_mid1 a													
LEFT JOIN shujuzu.contract_mid2 b													
ON a.strcontractid = b.strcontractid and a.content = b.content;													
													
#得到首次发货日期后第n年的发货人份数													
DROP table if EXISTS shujuzu.contract_mid4;													
CREATE TEMPORARY table shujuzu.contract_mid4 as													
SELECT a.strcontractid													
			,a.bi_cuscode										
			,a.bi_cusname										
			,a.content										
			,a.out_1st										
			,a.assess_mon										
			,a.until_year										
			,sum(a.inum_person_out) as inum_person_out										
FROM shujuzu.contract_mid3 a													
WHERE a.out_1st is not null and a.until_year > 0 and a.assess_mon/12 >=a.until_year													
GROUP BY a.strcontractid,a.content,a.until_year;													
													
DROP table if EXISTS shujuzu.contract_mid5;													
CREATE TEMPORARY table shujuzu.contract_mid5 as													
SELECT a.strcontractid													
			,a.classify										
			,a.content																		
			,a.bi_cusname										
			,a.strcontractstartdate										
			,a.strcontractenddate										
			,a.assess_mon										
			,a.standard_total										
			,a.year_rd										
			,a.inum_person										
			,a.screen_rate										
			,b.out_1st										
			,b.inum_person_out										
			,c.inum_person_ttl										
FROM shujuzu.contract_standad a													
LEFT JOIN shujuzu.contract_mid4 b													
ON a.strcontractid = b.strcontractid and a.content = b.content and a.year_rd=b.until_year													
LEFT JOIN (SELECT strcontractid,content,sum(inum_person_out) as inum_person_ttl													
FROM shujuzu.contract_mid4													
GROUP BY strcontractid,content)c													
ON a.strcontractid = c.strcontractid and a.content = c.content;													
													
UPDATE shujuzu.contract_mid5 a													
LEFT JOIN shujuzu.contract_mid2 b													
ON a.strcontractid = b.strcontractid and a.content = b.content													
SET a.out_1st = b.out_1st;													
													
DROP table if EXISTS shujuzu.contract_mid6_TSH;													
CREATE TEMPORARY table shujuzu.contract_mid6_TSH as													
SELECT a.bi_cusname													
			,a.bi_cinvcode										
			,a.bi_cinvname										
			,a.y_mon										
			,a.inum_person_out										
		  ,b.out_1st											
			,b.assess_mon										
		 	,if(b.out_1st > a.y_mon,-1,TIMESTAMPDIFF(year,b.out_1st,a.y_mon)+1) as until_year										
FROM pdm.cm_contract a													
LEFT JOIN shujuzu.contract_mid2 b													
ON a.bi_cusname = b.bi_cusname													
WHERE a.bi_cinvname regexp 'TSH' and b.content='串联试剂';													
													
DROP table if EXISTS shujuzu.contract_mid7_TSH;													
CREATE TEMPORARY table shujuzu.contract_mid7_TSH as													
SELECT a.bi_cusname													
			,a.until_year										
			,sum(a.inum_person_out) as TSH_num										
			,b.TSH_num_ttl										
FROM shujuzu.contract_mid6_TSH a													
LEFT JOIN (SELECT a.bi_cusname													
									,sum(a.inum_person_out) as TSH_num_ttl				
						FROM shujuzu.contract_mid6_TSH a							
						WHERE a.until_year<=a.assess_mon/12 and until_year>0							
						GROUP BY a.bi_cusname)b							
ON a.bi_cusname = b.bi_cusname													
WHERE a.until_year<=a.assess_mon/12 and until_year>0													
GROUP BY a.bi_cusname,a.until_year;													
													
#用pdm.invoice_order 找TSH发货人份数，但是缺少2018年前的数据													
/*DROP table if EXISTS shujuzu.contract_mid6_TSH;													
CREATE TEMPORARY table shujuzu.contract_mid6_TSH as													
SELECT a.finnal_ccusname as bi_cusname													
			,a.cinvcode										
			,a.cinvname										
			,a.ddate										
			,(a.iquantity *c.inum_unit_person) as inum_person_out										
		  ,b.out_1st											
			,b.assess_mon										
		 	,if(b.out_1st > a.ddate,-1,TIMESTAMPDIFF(year,b.out_1st,a.ddate)+1) as until_year										
FROM pdm.invoice_order a													
LEFT JOIN shujuzu.contract_mid2 b													
ON a.finnal_ccusname = b.bi_cusname													
LEFT JOIN edw.map_inventory c													
ON a.cinvcode = c.bi_cinvcode													
WHERE a.citemname = 'TSH' and b.content='串联试剂';*/													
													
DROP table if EXISTS shujuzu.contract_equipment0;													
CREATE TEMPORARY table shujuzu.contract_equipment0 as													
SELECT a.strcontractid													
			,a.classify										
			,a.content																	
			,a.bi_cusname										
			,a.strcontractstartdate										
			,a.strcontractenddate										
			,a.out_1st										
			,a.assess_mon										
			,a.standard_total										
			,a.year_rd										
			,a.inum_person										
			,a.screen_rate										
			,TIMESTAMPDIFF(month,a.out_1st,now()) as until_mon										
			,a.inum_person_out										
			,a.inum_person_ttl										
			,b.TSH_num										
			,b.TSH_num_ttl										
			,standard_total/(3.12*(assess_mon/12)-3.76) as plan1st										
FROM shujuzu.contract_mid5 a													
LEFT JOIN shujuzu.contract_mid7_TSH b													
ON a.bi_cusname = b.bi_cusname and a.year_rd = b.until_year;													
													
#考察总量的情况，第一年完成X，第二年2X，第三年2X(1+0.3)=2.6X,第四年2.6x(1+0.2)=3.12X,后续n年都是3.12X，总量是3.12nx-3.76x													
DROP table if EXISTS shujuzu.contract_equipment;													
CREATE  table shujuzu.contract_equipment as													
SELECT *													
		,case when classify = '每年量' and standard_total is null 											
					     THEN (case when until_mon div 12 >= year_rd THEN inum_person_out/inum_person								
		               else inum_person_out/((inum_person/12)*(until_mon mod 12)) end)											
					 when classify = '总量' and standard_total > 0 								
					 								
							 THEN (case when until_mon <=12 then inum_person_ttl/(plan1st/12*until_mon)						
													when until_mon >12  and until_mon <=24  then inum_person_ttl/(plan1st+2*plan1st/12*(until_mon mod 12))
													when until_mon >24  and until_mon <=36  then inum_person_ttl/(plan1st+2*plan1st+2.6*plan1st/12*(until_mon mod 12) )
													when until_mon >36 then inum_person_ttl/(5.6*plan1st+3.12*plan1st*(until_mon-36)/12) else null end)
													
					else inum_person_out/TSH_num/screen_rate end as wanchenglv								
			,case when until_mon <=12 then plan1st/12*until_mon										
													when until_mon >12  and until_mon <=24  then plan1st+2*plan1st/12*(until_mon mod 12)
													when until_mon >24  and until_mon <=36  then plan1st+2*plan1st+2.6*plan1st/12*(until_mon mod 12) 
													when until_mon >36 then 5.6*plan1st+3.12*plan1st*(until_mon-36)/12 else null end as lilunzongliang
													
FROM test.contract_equipment0;													
