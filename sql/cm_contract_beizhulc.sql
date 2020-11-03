
#得有效合同，且合同描述包含“流程”这两个字
DROP TABLE if EXISTS shujuzu.cm_contract_01;
CREATE TEMPORARY TABLE shujuzu.cm_contract_01 as
SELECT bi_cusname
			,strcontractstartdate
			,cdefine12
			,strcontractenddate
			,REPLACE(strcontractdesc,'/','-') as strcontractdesc
			,strcontractid
			,GROUP_CONCAT(DISTINCT bi_cinvname) as cinvnames
FROM edw.cm_contract
WHERE  ((strcontractenddate is null and strcontractstartdate >= '2018-01-01')  OR strcontractenddate > NOW()) and strcontractdesc like '%流程%' 
GROUP BY strcontractid
ORDER BY strcontractid;

DROP TABLE if EXISTS shujuzu.cm_contract_1;
CREATE TEMPORARY TABLE shujuzu.cm_contract_1 as
SELECT bi_cusname
			,strcontractstartdate
			,cdefine12
			,strcontractenddate
			,REPLACE(strcontractdesc,'，20','-20') as strcontractdesc
			,strcontractid
			,cinvnames
FROM shujuzu.cm_contract_01;
/*SELECT strcontractid,strcontractdesc,substring_index(strcontractdesc,'-',2),LENGTH(substring_index(strcontractdesc,'-',2)),substring(strcontractdesc,LENGTH(substring_index(strcontractdesc,'-',2)-8),12),substring(strcontractdesc,37),substring_index(strcontractdesc,'2019',-2)
FROM shujuzu.cm_contract_1
WHERE strcontractdesc like '%2019%';*/

#
DROP TABLE if EXISTS shujuzu.cm_contract_ETLpre;
CREATE TEMPORARY TABLE shujuzu.cm_contract_ETLpre as
SELECT bi_cusname
			,strcontractstartdate
			,strcontractenddate
			,cdefine12
			,strcontractdesc
			,strcontractid
			,cinvnames
			,LEFT(substring_index(strcontractdesc,'-20',-1),10) as id1
			,LEFT(substring_index(strcontractdesc,'-20',-2),10) as id2
			,LEFT(substring_index(strcontractdesc,'-20',-3),10) as id3
			,LEFT(substring_index(strcontractdesc,'-20',-4),10) as id4
FROM shujuzu.cm_contract_1;

DROP TABLE if EXISTS shujuzu.cm_contract_ETL; 
CREATE TEMPORARY TABLE shujuzu.cm_contract_ETL as 
SELECT bi_cusname
				,strcontractstartdate
				,strcontractenddate
				,cdefine12
				,strcontractdesc
				,strcontractid
				,cinvnames
				,if(LEFT(id1,2)=19 or LEFT(id1,2)=20,id1,'') as id1
				,if(LEFT(id2,2)=19 or LEFT(id2,2)=20,id2,'') as id2
				,if(LEFT(id3,2)=19 or LEFT(id3,2)=20,id3,'') as id3
				,if(LEFT(id4,2)=19 or LEFT(id4,2)=20,id4,'') as id4
FROM shujuzu.cm_contract_ETLpre;


/*DROP TABLE if EXISTS shujuzu.cm_contract_2020pre;
CREATE TEMPORARY TABLE shujuzu.cm_contract_2020pre as
SELECT bi_cusname
,strcontractstartdate
,strcontractenddate
,cdefine12
,strcontractdesc
,strcontractid
,cinvnames
,LEFT(substring_index(strcontractdesc,'-20',-1),10) as id1
,LEFT(substring_index(strcontractdesc,'-20',-2),10) as id2
,LEFT(substring_index(strcontractdesc,'-20',-3),10) as id3
,LEFT(substring_index(strcontractdesc,'-20',-4),10) as id4
FROM shujuzu.cm_contract_1
WHERE strcontractdesc like '%2020%';

DROP TABLE if EXISTS shujuzu.cm_contract_2020;
CREATE TEMPORARY TABLE shujuzu.cm_contract_2020 as
SELECT bi_cusname
,strcontractstartdate
,strcontractenddate
,cdefine12
,strcontractdesc
,strcontractid
,cinvnames
,if(LEFT(id1,2)=19 or LEFT(id1,2)=20,id1,'') as id1
,if(LEFT(id2,2)=19 or LEFT(id2,2)=20,id2,'') as id2
,if(LEFT(id3,2)=19 or LEFT(id3,2)=20,id3,'') as id3
,if(LEFT(id4,2)=19 or LEFT(id4,2)=20,id4,'') as id4
FROM shujuzu.cm_contract_2020pre;

DROP TABLE if EXISTS shujuzu.cm_contract_ETL;
CREATE TEMPORARY TABLE shujuzu.cm_contract_ETL as
SELECT *
FROM shujuzu.cm_contract_2019
UNION 
SELECT*
FROM shujuzu.cm_contract_2020;*/

DROP TABLE if EXISTS shujuzu.cm_contract_beizhu1;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhu1 as
SELECT a.*
			,if(b.beizhu is null,'',b.beizhu) as beizhu1
FROM shujuzu.cm_contract_ETL a
LEFT JOIN (SELECT RIGHT(liuchengbh,10) as liuchengbh,beizhu FROM edw.oa_quotation_process GROUP BY liuchengbh) b
ON a.id1 = b.liuchengbh;

DROP TABLE if EXISTS shujuzu.cm_contract_beizhu2;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhu2 as
SELECT a.*,if(b.beizhu is null,'',b.beizhu) as beizhu2
FROM (SELECT * FROM shujuzu.cm_contract_ETL WHERE id2 <> '') a
LEFT JOIN (SELECT RIGHT(liuchengbh,10) as liuchengbh,beizhu FROM edw.oa_quotation_process GROUP BY liuchengbh) b
ON a.id2 = b.liuchengbh;

DROP TABLE if EXISTS shujuzu.cm_contract_beizhu3;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhu3 as
SELECT a.*,if(b.beizhu is null,'',b.beizhu) as beizhu3
FROM (SELECT * FROM shujuzu.cm_contract_ETL WHERE id3  <> '') a
LEFT JOIN (SELECT RIGHT(liuchengbh,10) as liuchengbh,beizhu FROM edw.oa_quotation_process GROUP BY liuchengbh) b
ON a.id3 = b.liuchengbh;

DROP TABLE if EXISTS shujuzu.cm_contract_beizhu4;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhu4 as
SELECT a.*,if(b.beizhu is null,'',b.beizhu) as beizhu4
FROM (SELECT * FROM shujuzu.cm_contract_ETL WHERE id4  <> '') a
LEFT JOIN (SELECT RIGHT(liuchengbh,10) as liuchengbh,beizhu FROM edw.oa_quotation_process GROUP BY liuchengbh) b
ON a.id4 = b.liuchengbh;


DROP TABLE if EXISTS shujuzu.cm_contract_beizhulc1;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhulc1 as
SELECT a.bi_cusname
			,a.strcontractstartdate
			,a.strcontractenddate
			,a.cdefine12
			,a.strcontractdesc
			,a.strcontractid
			,a.cinvnames
			,LENGTH(a.strcontractdesc) as len
			,CONCAT(if(beizhu1 ='','','流程1备注：'),beizhu1,if(beizhu1 ='','','；'),if(beizhu2 is null or beizhu2='','','流程2备注：'),if(beizhu2 is null,'',beizhu2)) as beizhu
FROM shujuzu.cm_contract_beizhu1 a
LEFT JOIN shujuzu.cm_contract_beizhu2 b
ON a.strcontractid = b.strcontractid;

DROP TABLE if EXISTS shujuzu.cm_contract_beizhulc2;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhulc2 as
SELECT a.bi_cusname
			,a.strcontractstartdate
			,a.strcontractenddate
			,a.cdefine12
			,a.strcontractdesc
			,a.strcontractid
			,a.cinvnames
			,LENGTH(a.strcontractdesc) as len
			,CONCAT(beizhu,if(beizhu ='','','；'),if(beizhu3 is null or beizhu3='','','流程3备注：'),if(beizhu3 is null,'',beizhu3)) as beizhu
FROM shujuzu.cm_contract_beizhulc1 a
LEFT JOIN shujuzu.cm_contract_beizhu3 b
ON a.strcontractid = b.strcontractid;


DROP TABLE if EXISTS shujuzu.cm_contract_beizhulc1;
CREATE TEMPORARY TABLE shujuzu.cm_contract_beizhulc1 as
SELECT a.bi_cusname
			,a.strcontractstartdate
			,a.strcontractenddate
			,a.cdefine12
			,a.strcontractdesc
			,a.strcontractid
			,a.cinvnames
			,CONCAT(beizhu,if(beizhu ='','','；'),if(beizhu4 is null or beizhu4='','','流程4备注：'),if(beizhu4 is null,'',beizhu4)) as beizhu
FROM shujuzu.cm_contract_beizhulc2 a
LEFT JOIN shujuzu.cm_contract_beizhu4 b
ON a.strcontractid = b.strcontractid
UNION 
#得没有流程的其他包含备注的合同
SELECT bi_cusname
			,strcontractstartdate
			,strcontractenddate
			,cdefine12
			,strcontractdesc
			,strcontractid
			,GROUP_CONCAT(DISTINCT bi_cinvname) as cinvnames
			,CONCAT('合同备注：',strcontractdesc) as beizhu
FROM edw.cm_contract
WHERE  ((strcontractenddate is null and strcontractstartdate >= '2018-01-01')  OR strcontractenddate > NOW()) and strcontractdesc  not REGEXP '流程'  and strcontractdesc is not null and  strcontractdesc <> '有通知书' and strcontractdesc <> '无通知书'
GROUP BY strcontractid;

DROP TABLE if EXISTS shujuzu.cm_contract_beizhulc;
CREATE   TABLE shujuzu.cm_contract_beizhulc as
SELECT 
		b.sales_region_new
		,a.bi_cusname
		,a.strcontractstartdate
		,a.strcontractenddate
		,a.cdefine12
		,a.strcontractdesc
		,a.strcontractid
		,a.cinvnames
		,a.beizhu
FROM shujuzu.cm_contract_beizhulc1 a
LEFT JOIN edw.map_customer b
ON a.bi_cusname = b.bi_cusname;