#线下整理的合同标准
DROP table if EXISTS shujuzu.contract_standad;												
CREATE TEMPORARY table shujuzu.contract_standad (
strcontractid varchar(20),
classify varchar(10),
content varchar(10),
bi_cusname varchar(60),
strcontractstartdate date,
strcontractenddate date,
out_1st date,
assess_mon int(8),
standard_total int(8),
year_rd int(8),
inum_person int(8),
screen_rate DECIMAL(5,2)
);

insert into shujuzu.contract_standad values('ZJBSHT180412024','每年量','中孕三项','蚌埠市妇幼保健院','2015-10-13','2023-10-12','2016-01-01','36','0','1','5000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412024','每年量','中孕三项','蚌埠市妇幼保健院','2015-10-13','2023-10-12','2016-01-01','36','0','2','10000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412024','每年量','中孕三项','蚌埠市妇幼保健院','2015-10-13','2023-10-12','2016-01-01','36','0','3','20000','0');
insert into shujuzu.contract_standad values('ZJBSHT180411070','每年量','中孕三项','亳州市人民医院','2016-01-28','2021-01-19','2016-02-01','36','0','1','5000','0');
insert into shujuzu.contract_standad values('ZJBSHT180411070','每年量','中孕三项','亳州市人民医院','2016-01-28','2021-01-19','2016-02-01','36','0','2','10000','0');
insert into shujuzu.contract_standad values('ZJBSHT180411070','每年量','中孕三项','亳州市人民医院','2016-01-28','2021-01-19','2016-02-01','36','0','3','20000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412022','每年量','中孕三项','六安市金安区妇幼保健院','2016-12-23','2019-12-22','2017-01-01','36','0','1','8000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412022','每年量','中孕三项','六安市金安区妇幼保健院','2016-12-23','2019-12-22','2017-01-01','36','0','2','8000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412022','每年量','中孕三项','六安市金安区妇幼保健院','2016-12-23','2019-12-22','2017-01-01','36','0','3','8000','0');
insert into shujuzu.contract_standad values('ZJBSHT180517007','每年量','串联试剂','威海市妇女儿童医院（威海市妇幼保健院）','2014-06-01','2024-06-30','2014-08-01','36','0','1','6000','0');
insert into shujuzu.contract_standad values('ZJBSHT180517007','每年量','串联试剂','威海市妇女儿童医院（威海市妇幼保健院）','2014-06-01','2024-06-30','2014-08-01','36','0','2','10000','0');
insert into shujuzu.contract_standad values('ZJBSHT180517007','筛查率','串联试剂','威海市妇女儿童医院（威海市妇幼保健院）','2014-06-01','2024-06-30','2014-08-01','36','0','3','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180412082','每年量','串联试剂','宿迁市妇幼保健院','2016-06-22','2024-06-21','2016-07-01','96','0','1','20000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412082','每年量','串联试剂','宿迁市妇幼保健院','2016-06-22','2024-06-21','2016-07-01','96','0','2','50000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412082','每年量','串联试剂','宿迁市妇幼保健院','2016-06-22','2024-06-21','2016-07-01','96','0','3','60000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412082','每年量','串联试剂','宿迁市妇幼保健院','2016-06-22','2024-06-21','2016-07-01','96','0','4','80000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412082','筛查率','串联试剂','宿迁市妇幼保健院','2016-06-22','2024-06-21','2016-07-01','96','0','5','0','0.85');
insert into shujuzu.contract_standad values('ZJBSHT180412082','总量','串联试剂','宿迁市妇幼保健院','2016-06-22','2024-06-21','2016-07-01','96','400000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180417019','每年量','串联试剂','徐州市妇幼保健院','2015-09-18','2021-09-17','2015-12-01','60','0','1','4000','0');
insert into shujuzu.contract_standad values('ZJBSHT180417019','每年量','串联试剂','徐州市妇幼保健院','2015-09-18','2021-09-17','2015-12-01','60','0','2','25000','0');
insert into shujuzu.contract_standad values('ZJBSHT180417019','每年量','串联试剂','徐州市妇幼保健院','2015-09-18','2021-09-17','2015-12-01','60','0','3','50000','0');
insert into shujuzu.contract_standad values('ZJBSHT180417019','每年量','串联试剂','徐州市妇幼保健院','2015-09-18','2021-09-17','2015-12-01','60','0','4','60000','0');
insert into shujuzu.contract_standad values('ZJBSHT180417019','每年量','串联试剂','徐州市妇幼保健院','2015-09-18','2021-09-17','2015-12-01','60','0','5','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180412058','每年量','串联试剂','盐城市妇幼保健院','2014-04-11','2019-04-10','2014-05-01','60','0','1','4000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412058','每年量','串联试剂','盐城市妇幼保健院','2014-04-11','2019-04-10','2014-05-01','60','0','2','25000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412058','每年量','串联试剂','盐城市妇幼保健院','2014-04-11','2019-04-10','2014-05-01','60','0','3','50000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412058','每年量','串联试剂','盐城市妇幼保健院','2014-04-11','2019-04-10','2014-05-01','60','0','4','60000','0');
insert into shujuzu.contract_standad values('ZJBSHT180412058','筛查率','串联试剂','盐城市妇幼保健院','2014-04-11','2019-04-10','2014-05-01','60','0','5','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180428003','每年量','串联试剂','淄博市妇幼保健院','2013-09-02','2021-09-01','2014-02-01','60','0','1','6000','0');
insert into shujuzu.contract_standad values('ZJBSHT180428003','每年量','串联试剂','淄博市妇幼保健院','2013-09-02','2021-09-01','2014-02-01','60','0','2','15000','0');
insert into shujuzu.contract_standad values('ZJBSHT180428003','每年量','串联试剂','淄博市妇幼保健院','2013-09-02','2021-09-01','2014-02-01','60','0','3','25000','0');
insert into shujuzu.contract_standad values('ZJBSHT180428003','每年量','串联试剂','淄博市妇幼保健院','2013-09-02','2021-09-01','2014-02-01','60','0','4','30000','0');
insert into shujuzu.contract_standad values('ZJBSHT180428003','筛查率','串联试剂','淄博市妇幼保健院','2013-09-02','2021-09-01','2014-02-01','60','0','5','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180411052','筛查率','串联试剂','郴州市妇幼保健院','2016-07-01','2020-12-31','2016-09-01','48','0','1','0','0.2');
insert into shujuzu.contract_standad values('ZJBSHT180411052','筛查率','串联试剂','郴州市妇幼保健院','2016-07-01','2020-12-31','2016-09-01','48','0','2','0','0.35');
insert into shujuzu.contract_standad values('ZJBSHT180411052','筛查率','串联试剂','郴州市妇幼保健院','2016-07-01','2020-12-31','2016-09-01','48','0','3','0','0.5');
insert into shujuzu.contract_standad values('ZJBSHT180411052','筛查率','串联试剂','郴州市妇幼保健院','2016-07-01','2020-12-31','2016-09-01','48','0','4','0','0.65');
insert into shujuzu.contract_standad values('ZJBSHT180412037','筛查率','串联试剂','衡阳市妇幼保健院','2016-08-01','2026-07-31','2016-10-01','60','0','1','0','0.2');
insert into shujuzu.contract_standad values('ZJBSHT180412037','筛查率','串联试剂','衡阳市妇幼保健院','2016-08-01','2026-07-31','2016-10-01','60','0','2','0','0.35');
insert into shujuzu.contract_standad values('ZJBSHT180412037','筛查率','串联试剂','衡阳市妇幼保健院','2016-08-01','2026-07-31','2016-10-01','60','0','3','0','0.5');
insert into shujuzu.contract_standad values('ZJBSHT180412037','筛查率','串联试剂','衡阳市妇幼保健院','2016-08-01','2026-07-31','2016-10-01','60','0','4','0','0.65');
insert into shujuzu.contract_standad values('ZJBSHT180412037','筛查率','串联试剂','衡阳市妇幼保健院','2016-08-01','2026-07-31','2016-10-01','60','0','5','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180413012','筛查率','串联试剂','邵阳市妇幼保健院','2015-10-01','2023-09-30','2015-12-01','60','0','1','0','0.2');
insert into shujuzu.contract_standad values('ZJBSHT180413012','筛查率','串联试剂','邵阳市妇幼保健院','2015-10-01','2023-09-30','2015-12-01','60','0','2','0','0.35');
insert into shujuzu.contract_standad values('ZJBSHT180413012','筛查率','串联试剂','邵阳市妇幼保健院','2015-10-01','2023-09-30','2015-12-01','60','0','3','0','0.5');
insert into shujuzu.contract_standad values('ZJBSHT180413012','筛查率','串联试剂','邵阳市妇幼保健院','2015-10-01','2023-09-30','2015-12-01','60','0','4','0','0.65');
insert into shujuzu.contract_standad values('ZJBSHT180413012','筛查率','串联试剂','邵阳市妇幼保健院','2015-10-01','2023-09-30','2015-12-01','60','0','5','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180410034','筛查率','串联试剂','益阳市妇幼保健院','2016-04-01','2026-03-31','2016-07-01','60','0','1','0','0.2');
insert into shujuzu.contract_standad values('ZJBSHT180410034','筛查率','串联试剂','益阳市妇幼保健院','2016-04-01','2026-03-31','2016-07-01','60','0','2','0','0.35');
insert into shujuzu.contract_standad values('ZJBSHT180410034','筛查率','串联试剂','益阳市妇幼保健院','2016-04-01','2026-03-31','2016-07-01','60','0','3','0','0.5');
insert into shujuzu.contract_standad values('ZJBSHT180410034','筛查率','串联试剂','益阳市妇幼保健院','2016-04-01','2026-03-31','2016-07-01','60','0','4','0','0.65');
insert into shujuzu.contract_standad values('ZJBSHT180410034','筛查率','串联试剂','益阳市妇幼保健院','2016-04-01','2026-03-31','2016-07-01','60','0','5','0','0.8');
insert into shujuzu.contract_standad values('ZJBSHT180412023','总量','串联试剂','蚌埠市妇幼保健院','2016-05-01','2022-04-30','2017-03-01','72','200000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180417039','总量','串联试剂','聊城市妇幼保健院','2014-05-01','2019-04-30','2014-08-01','60','160000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180521002','总量','CMA','临沂市妇幼保健院（临沂市妇女儿童医院）','2016-03-04','2022-03-03','2016-06-01','72','7500','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180521004','总量','中孕三项','临沂市妇幼保健院（临沂市妇女儿童医院）','2016-03-04','2022-03-03','2016-04-01','72','400000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180411028','总量','中孕三项','南京鼓楼医院集团宿迁市人民医院','2017-02-27','2022-02-26','2017-06-01','60','30000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180517002','总量','串联试剂','日照市妇幼保健院','2015-10-23','2025-10-22','2015-12-01','60','120000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180518004','总量','串联试剂','山东省妇幼保健院','2013-12-01','2023-11-30','2014-06-01','120','50500','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180131027','总量','CMA','泰安市妇幼保健院','2016-12-30','2022-12-29','2017-04-01','72','3000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180131027','总量','串联试剂','泰安市妇幼保健院','2016-12-30','2022-12-29','2017-01-01','72','120000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180412053','总量','中孕三项','新沂市妇幼保健计划生育服务中心','2017-07-12','2022-07-11','2017-11-01','60','80000','0','0','0');
insert into shujuzu.contract_standad values('ZJBSHT180417019','总量','串联试剂','徐州市妇幼保健院','2015-09-18','2021-09-17','2015-12-01','60','200000','0','0','0');

update shujuzu.contract_standad set standard_total = null where standard_total=0;
update shujuzu.contract_standad set year_rd = null where year_rd=0;
update shujuzu.contract_standad set inum_person = null where inum_person=0;
update shujuzu.contract_standad set screen_rate = null where screen_rate=0;


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

DROP table if EXISTS shujuzu.contract_mid40;													
CREATE TEMPORARY table shujuzu.contract_mid40 as	
SELECT strcontractid,content,sum(inum_person_out) as inum_person_ttl													
FROM shujuzu.contract_mid4													
GROUP BY strcontractid,content;

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
LEFT JOIN shujuzu.contract_mid40 c																									
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

DROP table if EXISTS shujuzu.contract_mid60;													
CREATE TEMPORARY table shujuzu.contract_mid60 as
SELECT a.bi_cusname													
			,sum(a.inum_person_out) as TSH_num_ttl				
FROM shujuzu.contract_mid6_TSH a							
WHERE a.until_year<=a.assess_mon/12 and until_year>0							
GROUP BY a.bi_cusname;
						
DROP table if EXISTS shujuzu.contract_mid7_TSH;													
CREATE TEMPORARY table shujuzu.contract_mid7_TSH as													
SELECT a.bi_cusname													
			,a.until_year										
			,sum(a.inum_person_out) as TSH_num										
			,b.TSH_num_ttl										
FROM shujuzu.contract_mid6_TSH a													
LEFT JOIN shujuzu.contract_mid60 b							
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
