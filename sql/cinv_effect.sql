#产品成效
#源表-edw.x_eq_depreciation_18,edw.x_eq_depreciation_19,edw.x_eq_depreciation_20,shujuzu.x_equipment_depretion,得设备折旧，且对应到相应的设备上
#源表-report.fin_11_sales_cost_base,shujuzu.x_main_child_relation（线下整理的主辅关系）,edw.x_insure_cover
#
#将18年的折旧费年月由横板转为竖版
DROP TABLE if EXISTS shujuzu.nianyue;
CREATE TEMPORARY TABLE  shujuzu.nianyue ( 
ddate date) ;
INSERT INTO shujuzu.nianyue VALUES ('2018-01-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-02-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-03-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-04-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-05-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-06-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-07-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-08-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-09-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-10-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-11-01');
INSERT INTO shujuzu.nianyue VALUES ('2018-12-01'); 

DROP TABLE if EXISTS shujuzu.x_eq_depreciation_18pre;
CREATE TEMPORARY TABLE  shujuzu.x_eq_depreciation_18pre as  
SELECT a.* ,b.ddate
FROM (SELECT * FROM edw.x_eq_depreciation_18 )a
LEFT JOIN shujuzu.nianyue b
ON 1=1;

DROP TABLE if EXISTS shujuzu.x_eq_depreciation_18; 
CREATE TEMPORARY TABLE  shujuzu.x_eq_depreciation_18 as 
SELECT cohr
		,year_belong
		,vouchid
		,ddate_belong
		,vouchnum
		,province
		,sales_region
		,ccusname
		,bi_cuscode
		,bi_cusname
		,eq_name
		,cinvcode
		,cinvname
		,item_code
		,level_three
		,level_two
		,level_one
		,isum
		,iquantity
		,amount_depre_mon
		,ddate
,case when ddate='2018-01-01' THEN amount_depre_1
			when ddate='2018-02-01' THEN amount_depre_2
			when ddate='2018-03-01' THEN amount_depre_3
			when ddate='2018-04-01' THEN amount_depre_4
			when ddate='2018-05-01' THEN amount_depre_5
			when ddate='2018-06-01' THEN amount_depre_6
			when ddate='2018-07-01' THEN amount_depre_7
			when ddate='2018-08-01' THEN amount_depre_8
			when ddate='2018-09-01' THEN amount_depre_9
			when ddate='2018-10-01' THEN amount_depre_10
			when ddate='2018-11-01' THEN amount_depre_11
			when ddate='2018-12-01' THEN amount_depre_12 end as amount_depre
FROM shujuzu.x_eq_depreciation_18pre;

#将18-20的折旧费用统一成一张表
DROP TABLE if EXISTS shujuzu.eq_depreciation_pre;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation_pre as
SELECT cohr
			,ddate_belong
			,vouchid  #必须要，浙江省儿保，GSP设备，除了vouchid不一样，其他信息完全一样
			,bi_cusname  as ccusname
			,eq_name
			,cinvcode
			,cinvname
			,ddate
			,CAST(amount_depre AS DECIMAL(9,2)) as amount_depre
			FROM shujuzu.x_eq_depreciation_18
			WHERE eq_name <> '嘉兴妇保调整为制造费用-浙江直辖区'
			UNION
			SELECT
			cohr
			,ddate_belong
			,vouchid
			,finnal_cusname
			,eq_name
			,cinvcode
			,cinvname
			,ddate
			,CAST(amount_depre AS DECIMAL(9,2)) as amount_depre
FROM edw.x_eq_depreciation_19
WHERE eq_name <> '嘉兴妇保调整为制造费用-浙江直辖区'
UNION
SELECT
			cohr
			,ddate_belong
			,vouchid
			,finnal_cusname
			,eq_name
			,cinvcode
			,cinvname
			,ddate
			,CAST(amount_depre AS DECIMAL(9,2)) as amount_depre
FROM edw.x_eq_depreciation_20;

#嘉兴妇保调整为制造费用-浙江直辖区的折旧费根据edw层的备注删除的原因是，财务开始做账时作的是制造费，后来实际又转为折旧，这一笔实际就是折旧费，因为已经归入制造费用科目，因此做了这一笔负账

#将一些一正一负的情况找出来，抵消掉
#存在负数的情况
DROP TABLE if EXISTS shujuzu.eq_depreciation_neg;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation_neg as
SELECT cohr
			,ddate_belong
			,ccusname
			,eq_name
			,cinvcode
			,cinvname
			,ddate
			,ABS(amount_depre) as amount_depre_neg # 负数negative number
FROM shujuzu.eq_depreciation_pre
WHERE amount_depre < 0;

DROP TABLE if EXISTS shujuzu.eq_depreciation;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation as
SELECT a.cohr
			,LEFT(a.ddate_belong,6) as ddate_belong
			,a.ccusname
			,a.eq_name
			,a.cinvcode
			,a.cinvname
			,a.ddate
			,a.amount_depre
FROM shujuzu.eq_depreciation_pre a
LEFT JOIN shujuzu.eq_depreciation_neg b
ON a.ccusname = b.ccusname and a.ddate = b.ddate  /*and a.eq_name = b.eq_name*/ and abs(a.amount_depre) = b.amount_depre_neg #举例徐州妇幼基因芯片设备名称写的不完全一样
WHERE b.ccusname is null and b.ddate is null and  b.amount_depre_neg is null;

CREATE index index_eq_depreciation_ddate_belong ON shujuzu.eq_depreciation(ddate_belong);
CREATE index index_eq_depreciation_ccusname ON shujuzu.eq_depreciation(ccusname);
CREATE index index_eq_depreciation_eq_name ON shujuzu.eq_depreciation(eq_name);

#线下客户名称清洗
DROP TABLE if EXISTS shujuzu.dic_relation_depreciation0;
CREATE TEMPORARY TABLE  shujuzu.dic_relation_depreciation0 as
SELECT a.cohr
			,a.ddate_belong
			,b.bi_cusname as ccusname
			,a.eq_name
			,a.cinvcode
			,a.cinvname
			,macth_equiepment as equiepment_name 
FROM shujuzu.x_equipment_depretion a
LEFT JOIN (SELECT ccusname,bi_cuscode,bi_cusname FROM edw.dic_customer  GROUP BY ccusname) b
ON a.ccusname = b.ccusname;


#所有折旧产品对应的设备，根据线下确认的表关联
DROP TABLE if EXISTS shujuzu.eq_depreciation_relation0;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation_relation0 as
SELECT a.cohr
			,a.ddate_belong
			,a.ccusname
			,a.eq_name
			,a.cinvcode
			,a.cinvname
			,a.ddate
			,b.equiepment_name
			,a.amount_depre
FROM shujuzu.eq_depreciation a
LEFT JOIN shujuzu.dic_relation_depreciation0 b
ON a.ccusname = b.ccusname and a.ddate_belong = b.ddate_belong and a.eq_name = b.eq_name and a.cinvcode = b.cinvcode;

DROP TABLE if EXISTS shujuzu.eq_depreciation_relation;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation_relation as
SELECT 
			a.ccusname
			,a.ddate
			,a.equiepment_name
			,sum(a.amount_depre) as amount_depre
FROM shujuzu.eq_depreciation_relation0 a
GROUP BY ccusname,ddate,equiepment_name;

#以上内容处理的是设备折旧，根据线下对照的关系处理。

#按产品、年月分组
DROP TABLE if EXISTS shujuzu.sales_cost_pre0;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre0 as 
SELECT 
			if(cohr = '杭州贝生','杭州贝生',sales_region_new) as sales_region_new1
			,ccusname
			,cbustype
			,cinvcode
			,cinvname
			,DATE_FORMAT(ddate,'%Y-%m-01') as ddate
			,sum(isum) as isum
			,sum(isum_notax) as isum_notax 
			,sum(cost) as cost
			,sum(iquantity_adjust) as iquantity_adjust
FROM report.fin_11_sales_cost_base a
WHERE year(ddate) > 2017
GROUP BY sales_region_new1,ccusname,cinvcode,cinvname,year(ddate),month(ddate);

/*复核SELECT sum(isum)
FROM shujuzu.sales_cost_pre4;
SELECT sum(isum)
FROM report.fin_11_sales_cost_base
WHERE year(ddate)>2017*/

#关联产品档案，的产品相关信息，便于分类
DROP TABLE if EXISTS shujuzu.sales_cost_pre1;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre1 as
SELECT 
			a.sales_region_new1
			,a.ccusname
			,a.cbustype
			,a.cinvcode
			,a.cinvname
			,a.ddate
			,a.isum
			,a.isum_notax 
			,a.cost
			,a.iquantity_adjust*b.inum_unit_person as iquantity_person
				,b.item_code
				,b.level_three as item_name
				,b.cinvbrand
				,b.cinv_key_2020
FROM shujuzu.sales_cost_pre0 a
LEFT JOIN edw.map_inventory b
ON a.cinvcode = b.bi_cinvcode;

#关联线下整理的主辅关系表，将产品分类
DROP TABLE if EXISTS shujuzu.sales_cost_pre2;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre2 as
SELECT 
    if(a.sales_region_new1 is null,'请核查',sales_region_new1) as sales_region_new1
    ,if(a.ccusname is null,'请核查',a.ccusname) as ccusname  
    ,a.cbustype
    ,a.cinvcode
    ,a.cinvname
    ,a.ddate
    ,a.isum
    ,a.isum_notax 
    ,a.cost
    ,a.iquantity_person
    ,a.item_name
    ,case when b.relation_cx is not  null then b.relation_cx
          when cbustype = 'LDT' and cinvbrand = '甄元'  then 'qt甄元LDT'
          when cbustype = 'LDT' and cinvbrand = '贝康'  then 'qt贝康LDT'
          when cbustype = 'LDT' then 'qt其他LDT'
          when cinv_key_2020 = '服务_软件' then 'qt软件服务'
          when cinv_key_2020 = '服务_物流' then 'qt物流服务'
          when left(item_name,4) = '维保服务' then 'qt维保服务'
          when cbustype = '服务类' then 'qt其他服务'
      else 'qt其他' 
			end as relation_cx
    ,cinvname_main
FROM shujuzu.sales_cost_pre1 a
LEFT JOIN (SELECT cinvcode_child,relation_cx,cinvname_main FROM shujuzu.x_main_child_relation  GROUP BY cinvcode_child) b
ON a.cinvcode = b.cinvcode_child;


DROP TABLE if EXISTS shujuzu.sales_cost_pre3;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre3 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,if(left(relation_cx,2)='qt',relation_cx,a.cinvcode) as cinvcode
     ,if(left(relation_cx,2)='qt',relation_cx,a.cinvname) as cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax 
     ,a.cost
     ,a.iquantity_person
     ,if(left(relation_cx,2)='qt',relation_cx,a.item_name) as item_name
     ,a.relation_cx
     ,a.cinvname_main
FROM shujuzu.sales_cost_pre2 a;

#得到包含所有产品的表，产品根据需要进行了分类
DROP TABLE if EXISTS shujuzu.sales_cost_pre4;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre4 as
SELECT a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.ddate
      ,sum(a.isum) as isum
      ,sum(a.isum_notax ) as isum_notax
      ,sum(a.cost) as cost
      ,sum(a.iquantity_person) as iquantity_person
      ,a.item_name
      ,a.relation_cx
      ,a.cinvname_main
FROM shujuzu.sales_cost_pre3 a
GROUP BY ccusname,cinvcode,year(ddate),month(ddate);

#得到主试剂、其他没有主辅关系的产品的表，最终表的行数和此表一致
DROP TABLE if EXISTS shujuzu.sales_cost_pre5;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre5 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.relation_cx
     ,a.cinvname_main
FROM shujuzu.sales_cost_pre4 a
WHERE relation_cx = '主试剂' OR LEFT(relation_cx,2)='qt';

CREATE INDEX index_sales_cost_pre5_ccusname ON shujuzu.sales_cost_pre5(ccusname);
CREATE INDEX index_sales_cost_pre5_cinvcode ON shujuzu.sales_cost_pre5(cinvcode);
CREATE INDEX index_sales_cost_pre5_ddate ON shujuzu.sales_cost_pre5(ddate);

#得到分摊依据的表，即主试剂的成本
DROP TABLE if EXISTS shujuzu.sales_cost_pre60;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre60 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.relation_cx
     ,a.cinvname_main
FROM shujuzu.sales_cost_pre5 a
WHERE relation_cx = '主试剂';

CREATE INDEX index_sales_cost_pre60_ccusname ON shujuzu.sales_cost_pre60(ccusname);
CREATE INDEX index_sales_cost_pre60_cinvcode ON shujuzu.sales_cost_pre60(cinvcode);
CREATE INDEX index_sales_cost_pre60_ddate ON shujuzu.sales_cost_pre60(ddate);

#因计算累计收入，要对应每个客户产品每一个年月
DROP TABLE if EXISTS shujuzu.gxl_cusitem_person_mon0;
CREATE TEMPORARY TABLE if not exists shujuzu.gxl_cusitem_person_mon0(
    ddate date comment'年月'
)engine=innodb;
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-01-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-02-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-03-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-04-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-05-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-06-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-07-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-08-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-09-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-10-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-11-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2018-12-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-01-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-02-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-03-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-04-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-05-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-06-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-07-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-08-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-09-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-10-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-11-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2019-12-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-01-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-02-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-03-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-04-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-05-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-06-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-07-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-08-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-09-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-10-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-11-01');
insert into shujuzu.gxl_cusitem_person_mon0 values ('2020-12-01');

DROP TABLE if EXISTS shujuzu.sales_cost_pre61;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre61 as
SELECT a.*,b.ddate
FROM 
			(SELECT DISTINCT a.sales_region_new1
			,a.ccusname
			,a.cbustype
			,a.cinvcode
			,a.cinvname
			,a.item_name
			,a.relation_cx
			,a.cinvname_main
			from shujuzu.sales_cost_pre60 a )a
left join shujuzu.gxl_cusitem_person_mon0 b
ON 1=1;

CREATE INDEX index_sales_cost_pre61_ccusname ON shujuzu.sales_cost_pre61(ccusname);
CREATE INDEX index_sales_cost_pre61_cinvcode ON shujuzu.sales_cost_pre61(cinvcode);
CREATE INDEX index_sales_cost_pre61_ddate ON shujuzu.sales_cost_pre61(ddate);

DROP TABLE if EXISTS shujuzu.sales_cost_pre6;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre6 as
SELECT 
     b.sales_region_new1
     ,b.ccusname
     ,b.cbustype
     ,b.cinvcode
     ,b.cinvname
     ,b.ddate
     ,a.isum
     ,a.isum_notax
     ,a.cost
     ,a.iquantity_person
     ,b.item_name
     ,b.relation_cx
     ,b.cinvname_main
FROM shujuzu.sales_cost_pre5 a
RIGHT JOIN  shujuzu.sales_cost_pre61 b
ON a.ccusname = b.ccusname  and a.cinvcode = b.cinvcode and a.ddate = b.ddate;

#得各月累计的主试剂成本
DROP TABLE if EXISTS shujuzu.sales_cost_pre7;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_pre7 as
SELECT a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.ddate
      ,a.isum
      ,a.isum_notax
      ,a.cost
      ,a.iquantity_person
      ,a.item_name
      ,a.relation_cx
      ,a.cinvname_main
      ,sum(b.cost) as add_cost #各客户产品各月累计成本
FROM shujuzu.sales_cost_pre6 a
left join (SELECT * FROM shujuzu.sales_cost_pre5 WHERE relation_cx = '主试剂') b
ON a.ccusname = b.ccusname and a.cinvcode = b.cinvcode and a.ddate >= b.ddate
GROUP BY a.ccusname,a.cinvcode,a.ddate;

#因每个客户产品都是从2018年1月算起的，有的是2019年才开展的，因此删掉开展之前的记录，即累计成本为空的
/*DELETE 
FROM shujuzu.sales_cost_pre7
WHERE add_cost is null;*/

CREATE INDEX index_sales_cost_pre7_ccusname ON shujuzu.sales_cost_pre7(ccusname);
CREATE INDEX index_sales_cost_pre7_cinvcode ON shujuzu.sales_cost_pre7(cinvcode);
CREATE INDEX index_sales_cost_pre7_ddate ON shujuzu.sales_cost_pre7(ddate);

#得到各月客户主试剂成本求和，按对应设备分组
DROP TABLE if EXISTS shujuzu.sales_cost_main;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_main as
SELECT 
     ccusname
     ,ddate
     ,cinvname_main
     ,sum(add_cost) as add_cost_main
FROM shujuzu.sales_cost_pre7
GROUP BY ccusname,ddate,cinvname_main;

CREATE index index_sales_cost_main_ccusname ON shujuzu.sales_cost_main(ccusname);
CREATE index index_sales_cost_main_ddate ON shujuzu.sales_cost_main(ddate);
CREATE index index_sales_cost_main_cinvname_main ON shujuzu.sales_cost_main(cinvname_main);


#得到主辅关系唯一的对应关系
DROP TABLE if EXISTS shujuzu.sales_cost_child1;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child1 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax 
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,b.cinvname_main
FROM shujuzu.sales_cost_pre2 a
LEFT JOIN 
        (SELECT cinvcode_child,cinvname_main,COUNT(cinvcode_child) as relation_unm
         FROM shujuzu.x_main_child_relation
         GROUP BY cinvcode_child
         HAVING relation_unm = 1)b
ON a.cinvcode = b.cinvcode_child
WHERE LEFT(a.relation_cx,2) = '辅助' and b.cinvcode_child is not null; 

CREATE INDEX index_sales_cost_child1_ccusname ON shujuzu.sales_cost_child1(ccusname);
CREATE INDEX index_sales_cost_child1_cinvname_main ON shujuzu.sales_cost_child1(cinvname_main);
CREATE INDEX index_sales_cost_child1_ddate ON shujuzu.sales_cost_child1(ddate);

#有唯一对应关系的辅助产品，但是其对应的设备，可能根本没有主试剂的成本和收入，即主辅关系可能有误。因此将主设备各月累计的成本额匹配过来，如果没有成本额，就将该产品归类为其他

DROP TABLE if EXISTS shujuzu.sales_cost_child10;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child10 as
SELECT
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax 
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.cinvname_main
     ,if(b.add_cost_main > 0,'辅助','其他') as fenlei
FROM shujuzu.sales_cost_child1 a
LEFT JOIN shujuzu.sales_cost_main b
ON a.ccusname = b.ccusname and a.ddate = b.ddate and a.cinvname_main= b.cinvname_main;

#得到关系不唯一的主辅关系表
DROP TABLE if EXISTS shujuzu.sales_cost_child02;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child02 as
SELECT a.*
FROM shujuzu.x_main_child_relation a
LEFT JOIN (SELECT cinvcode_child,cinvname_main,COUNT(cinvcode_child) as relation_unm
           FROM shujuzu.x_main_child_relation
           GROUP BY cinvcode_child
           HAVING relation_unm > 1)b
ON a.cinvcode_child = b.cinvcode_child
WHERE b.cinvcode_child is not null;
#得到主辅关系一对多的对应关系
DROP TABLE if EXISTS shujuzu.sales_cost_child2;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child2 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax 
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,b.cinvname_main
FROM shujuzu.sales_cost_pre2 a
LEFT JOIN shujuzu.sales_cost_child02 b
ON a.cinvcode = b.cinvcode_child
WHERE LEFT(a.relation_cx,2) = '辅助' and b.cinvcode_child is not null;

CREATE INDEX index_sales_cost_child2_ccusname ON shujuzu.sales_cost_child2(ccusname);
CREATE INDEX index_sales_cost_child2_cinvname_main ON shujuzu.sales_cost_child2(cinvname_main);
CREATE INDEX index_sales_cost_child2_ddate ON shujuzu.sales_cost_child2(ddate);

#主辅关系1对多的产品，匹配对应设备的当月的累计主试剂成本
DROP TABLE if EXISTS shujuzu.sales_cost_child3;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child3 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax 
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.cinvname_main
     ,if(b.add_cost_main < 0 ,0,add_cost_main) as add_cost_main #像厦门妇幼GSP、串联质谱仪，采血卡，一个主试剂成本为正，一个为负，无法分摊，因此将主试剂成本为负的等于0，不用于分摊
FROM shujuzu.sales_cost_child2 a
LEFT JOIN shujuzu.sales_cost_main b
ON a.ccusname = b.ccusname and a.ddate = b.ddate and a.cinvname_main = b.cinvname_main;

CREATE INDEX index_sales_cost_child3_ccusname ON shujuzu.sales_cost_child3(ccusname);
CREATE INDEX index_sales_cost_child3_cinvname_main ON shujuzu.sales_cost_child3(cinvname_main);
CREATE INDEX index_sales_cost_child3_ddate ON shujuzu.sales_cost_child3(ddate);

#主辅关系1对多的产品，按照产品分组，求其对应的月份的所有设备的主试剂成本，用于做分摊的分母
DROP TABLE if EXISTS shujuzu.sales_cost_child4;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child4 as
SELECT  
      a.ccusname
      ,ddate
      ,a.cinvcode
      ,sum(a.add_cost_main) as add_cost_main_ttl
FROM shujuzu.sales_cost_child3 a
GROUP BY ccusname,cinvcode,ddate;

CREATE INDEX index_sales_cost_child4_ccusname ON shujuzu.sales_cost_child4(ccusname);
CREATE INDEX index_sales_cost_child4_cinvcode ON shujuzu.sales_cost_child4(cinvcode);
CREATE INDEX index_sales_cost_child4_ddate ON shujuzu.sales_cost_child4(ddate);

#主辅关系1对多的产品，分摊后的记录（因有的客户月份主试剂成本）
DROP TABLE if EXISTS shujuzu.sales_cost_child5;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child5 as
SELECT 
      a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.ddate
      ,a.isum
      ,a.isum*add_cost_main/add_cost_main_ttl as isum_share
      ,a.isum_notax      ,a.isum_notax*add_cost_main/add_cost_main_ttl as isum_notax_share
      ,a.cost
      ,a.cost*add_cost_main/add_cost_main_ttl as cost_share
      ,a.iquantity_person
      ,a.item_name
      ,a.cinvname_main
      ,a.add_cost_main
      ,b.add_cost_main_ttl
FROM shujuzu.sales_cost_child3 a
LEFT JOIN shujuzu.sales_cost_child4 b
ON a.ccusname = b.ccusname  and a.cinvcode = b.cinvcode and a.ddate = b.ddate;

#得到所有辅助试剂、设备的记录
DROP TABLE if EXISTS shujuzu.sales_cost_child_ttl0;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child_ttl0 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax 
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.cinvname_main
FROM shujuzu.sales_cost_child10 a
WHERE fenlei = '辅助'
UNION
SELECT 
      a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.ddate
      ,a.isum_share
      ,a.isum_notax_share
      ,a.cost_share
      ,a.iquantity_person
      ,a.item_name
      ,a.cinvname_main
FROM shujuzu.sales_cost_child5 a
WHERE add_cost_main_ttl>0; #过滤掉因主试剂成本为0而不能分摊的数据，为了保证所有收入数据的准确性，要将这部分放在其他里

#得到每个主设备、每月的辅助试剂耗材的收入、成本等信息
DROP TABLE if EXISTS shujuzu.sales_cost_child_ttl;
CREATE TEMPORARY TABLE  shujuzu.sales_cost_child_ttl as
SELECT 
      a.sales_region_new1
      ,a.ccusname
      ,a.cinvname_main
      ,ddate
      ,sum(a.isum) as isum
      ,sum(a.isum_notax) as isum_notax
      ,sum(a.cost) as cost
FROM shujuzu.sales_cost_child_ttl0 a
GROUP BY ccusname,cinvname_main,ddate;

CREATE INDEX index_sales_cost_child_ttl_ccusname ON shujuzu.sales_cost_child_ttl(ccusname);
CREATE INDEX index_sales_cost_child_ttl_cinvname_main ON shujuzu.sales_cost_child_ttl(cinvname_main);
CREATE INDEX index_sales_cost_child_ttl_ddate ON shujuzu.sales_cost_child_ttl(ddate);

#各客户各月各主试剂累计成本、应对设备的所有主试剂各月成本之和，用于计算分摊
DROP TABLE if EXISTS shujuzu.cinv_effect01;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect01 as
SELECT 
      a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.ddate
      ,a.isum
      ,a.isum_notax
      ,a.cost
      ,a.iquantity_person
      ,a.item_name
      ,a.relation_cx
      ,a.cinvname_main
      ,a.add_cost
      ,b.add_cost_main
FROM shujuzu.sales_cost_pre7 a
LEFT JOIN shujuzu.sales_cost_main b
ON a.ccusname = b.ccusname and a.cinvname_main = b.cinvname_main and a.ddate = b.ddate;

CREATE INDEX index_cinv_effect01_ccusname ON shujuzu.cinv_effect01(ccusname);
CREATE INDEX index_cinv_effect01_cinvname_main ON shujuzu.cinv_effect01(cinvname_main);
CREATE INDEX index_cinv_effect01_ddate ON shujuzu.cinv_effect01(ddate);

#关联辅助试剂成本收入的表
DROP TABLE if EXISTS shujuzu.cinv_effect02;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect02 as
SELECT 
      a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.ddate
      ,a.isum
      ,a.isum_notax
      ,a.cost
      ,a.iquantity_person
      ,a.item_name
      ,a.relation_cx
      ,a.cinvname_main
      ,a.add_cost
      ,a.add_cost_main
      ,b.cost as iunitcost_child_eq
      ,b.isum as isum_child_eq
      ,b.isum_notax as invoice_amount_child_eq
FROM shujuzu.cinv_effect01 a
LEFT JOIN shujuzu.sales_cost_child_ttl b
ON a.ccusname = b.ccusname and a.cinvname_main = b.cinvname_main and a.ddate = b.ddate;


CREATE INDEX index_cinv_effect02_ccusname ON shujuzu.cinv_effect02(ccusname);
CREATE INDEX index_cinv_effect02_cinvname_main ON shujuzu.cinv_effect02(cinvname_main);
CREATE INDEX index_cinv_effect02_ddate ON shujuzu.cinv_effect02(ddate);

DROP TABLE if EXISTS shujuzu.eq_depreciation_relation_cx;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation_relation_cx as
SELECT *
FROM shujuzu.eq_depreciation_relation;

CREATE INDEX index_eq_depreciation_relation_cx_ccusname ON shujuzu.eq_depreciation_relation_cx(ccusname);
CREATE INDEX index_eq_depreciation_relation_cx_equiepment_name ON shujuzu.eq_depreciation_relation_cx(equiepment_name);
CREATE INDEX index_eq_depreciation_relation_cx_ddate ON shujuzu.eq_depreciation_relation_cx(ddate);


#关联设备折旧
DROP TABLE if EXISTS shujuzu.cinv_effect03;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect03 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.relation_cx
     ,a.cinvname_main
     ,a.add_cost
     ,a.add_cost_main
     ,a.iunitcost_child_eq
     ,a.isum_child_eq
     ,a.invoice_amount_child_eq
     ,b.amount_depre
FROM shujuzu.cinv_effect02 a
LEFT JOIN shujuzu.eq_depreciation_relation_cx b
ON a.ccusname = b.ccusname and a.cinvname_main = b.equiepment_name and a.ddate = b.ddate;

CREATE INDEX index_cinv_effect03_ccusname ON shujuzu.cinv_effect03(ccusname);
CREATE INDEX index_cinv_effect03_cinvname_main ON shujuzu.cinv_effect03(cinvname_main);
CREATE INDEX index_cinv_effect03_ddate ON shujuzu.cinv_effect03(ddate);

DROP TABLE if EXISTS shujuzu.cinv_effect030;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect030 as
SELECT ccusname,cinvname_main,COUNT(DISTINCT cinvcode) as num_main FROM shujuzu.cinv_effect03  GROUP BY ccusname,cinvname_main;

#特殊情况有的主试剂2019年1月才开始有成本，但是2018年就开始有折旧，这部分折旧也要分摊，如果设备有3个主试剂，那么每个主试剂分摊到的折旧是1/3

DROP TABLE if EXISTS shujuzu.cinv_effect031;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect031 as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cbustype
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,a.isum
     ,a.isum_notax
     ,a.cost
     ,a.iquantity_person
     ,a.item_name
     ,a.relation_cx
     ,a.cinvname_main
     ,a.add_cost
     ,a.add_cost_main
     ,a.iunitcost_child_eq
     ,a.isum_child_eq
     ,a.invoice_amount_child_eq
     ,a.amount_depre
     ,b.num_main
FROM shujuzu.cinv_effect03 a
LEFT JOIN shujuzu.cinv_effect030 b
ON a.ccusname = b.ccusname and a.cinvname_main = b.cinvname_main ;

#有的客户设备有折旧，但是没有主试剂的成本收入等信息
DROP TABLE if EXISTS shujuzu.eq_depreciation1;
CREATE TEMPORARY TABLE  shujuzu.eq_depreciation1 as
SELECT c.sales_region_new as sales_region_new1,a.*
FROM shujuzu.eq_depreciation_relation_cx a
LEFT JOIN 
         (SELECT DISTINCT ccusname,cinvname_main
         FROM shujuzu.cinv_effect031)b
ON a.ccusname = b.ccusname and a.equiepment_name = b.cinvname_main
LEFT JOIN edw.map_customer c
ON a.ccusname = c.bi_cusname
WHERE b.ccusname is null and b.cinvname_main is null and a.amount_depre is not null;

#主设备收入信息
DROP TABLE if EXISTS shujuzu.main_eqipment;
CREATE TEMPORARY TABLE  shujuzu.main_eqipment as
SELECT 
     a.sales_region_new1
     ,a.ccusname
     ,a.cinvcode
     ,a.cinvname
     ,a.ddate
     ,sum(a.isum) as isum_eqipment
     ,sum(a.isum_notax) as isum_notax_eqipment
     ,sum(a.cost) as cost_eqipment
     ,sum(a.iquantity_person) as iquantity_eqipment
     ,a.cinvname_main
FROM shujuzu.sales_cost_pre2 a
WHERE relation_cx = '主设备'
GROUP BY ccusname,ddate,cinvcode;


DROP TABLE if EXISTS shujuzu.cinv_effect04;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect04 as
SELECT a.sales_region_new1
       ,a.ccusname
       ,a.cbustype
       ,a.cinvcode
       ,a.cinvname
       ,a.ddate
       ,a.isum
       ,a.isum_notax
       ,a.cost
       ,a.iquantity_person
       ,a.item_name
       ,a.relation_cx
       ,a.cinvname_main
       ,a.add_cost
       ,a.add_cost_main
       ,iunitcost_child_eq*add_cost/add_cost_main as iunitcost_child
       ,isum_child_eq*add_cost/add_cost_main as isum_child
       ,invoice_amount_child_eq*add_cost/add_cost_main as invoice_amount_child
       ,if(add_cost_main is null or add_cost_main = 0,amount_depre/num_main,amount_depre *add_cost/add_cost_main) as equipment_depretion#特殊情况有的主试剂2019年1月才开始有成本，但是2018年就开始有折旧，这部分折旧也要分摊，如果设备有3个主试剂，那么每个主试剂分摊到的折旧是1/3
       ,a.iunitcost_child_eq
       ,a.isum_child_eq
       ,a.invoice_amount_child_eq
       ,a.amount_depre
       ,num_main
FROM shujuzu.cinv_effect031 a;

DROP TABLE if EXISTS shujuzu.cinv_effect05;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect05 as
SELECT a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,a.cinvname_main
      ,a.ddate
      ,a.iquantity_person as iquantity_person_main
      ,a.isum as isum_main
      ,a.isum_child
      ,a.isum_notax as isum_notax_main
      ,a.invoice_amount_child as isum_notax_child
      ,a.cost as cost_main
      ,a.iunitcost_child as cost_child
      ,a.equipment_depretion
      ,a.add_cost
      ,a.add_cost_main
      ,num_main
FROM shujuzu.cinv_effect04 a
UNION
SELECT a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,a.cinvname_main
      ,a.ddate
      ,a.iquantity_person as iquantity_person_main
      ,a.isum as isum_main
      ,'' as isum_child
      ,a.isum_notax as isum_notax_main
      ,'' as isum_notax_child
      ,a.cost as cost_main
      ,'' as cost_child
      ,'' as equipment_depretion
      ,'' as add_cost
      ,'' as add_cost_main
      ,''
FROM shujuzu.sales_cost_pre5 a
WHERE left(cinvcode,2) = 'qt'
UNION
SELECT a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,'qt其他' as cinvcode
      ,'qt其他' as cinvname
      ,'qt其他' as item_name
      ,'' as cinvname_main
      ,a.ddate
      ,a.iquantity_person as iquantity_person_main
      ,a.isum as isum_main
      ,'' as isum_child
      ,a.isum_notax as isum_notax_main
      ,'' as isum_notax_child
      ,a.cost as cost_main
      ,'' as cost_child
      ,'' as equipment_depretion
      ,'' as add_cost
      ,'' as add_cost_main
      ,''
FROM shujuzu.sales_cost_child10 a
WHERE fenlei = '其他'
UNION
SELECT  a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,'qt其他' as cinvcode
      ,'qt其他' as cinvname
      ,'qt其他' as item_name
      ,'' as cinvname_main
      ,a.ddate
      ,a.iquantity_person as iquantity_person_main
      ,a.isum as isum_main
      ,'' as isum_child
      ,a.isum_notax as isum_notax_main
      ,'' as isum_notax_child
      ,a.cost as cost_main
      ,'' as cost_child
      ,'' as equipment_depretion
      ,'' as add_cost
      ,'' as add_cost_main
      ,''
FROM shujuzu.sales_cost_child5 a
WHERE add_cost_main_ttl is null OR  add_cost_main_ttl <= 0
GROUP BY ccusname,cinvcode,ddate #有重复的，分组是为了避免重复
UNION
SELECT a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,'' as cinvname_main
      ,a.ddate
      ,a.iquantity_person
      ,a.isum
      ,'' as isum_child
      ,a.isum_notax
      ,'' as isum_notax_child
      ,a.cost 
      ,'' as cost_child
      ,'' as equipment_depretion
      ,'' as add_cost
      ,'' as add_cost_main
      ,''
FROM shujuzu.sales_cost_pre2 a
WHERE relation_cx = '主设备'
UNION 
#加上有的设备有折旧但是没有主试剂成本收入的情况
SELECT sales_region_new1
     ,a.ccusname
     ,''
     ,''
     ,''
     ,''
     ,equiepment_name
     ,ddate
     ,''
     ,''
     ,''
     ,''
     ,''
     ,''
     ,''
     ,amount_depre
     ,''
     ,''
     ,''
FROM shujuzu.eq_depreciation1 a;

DROP TABLE if EXISTS shujuzu.cinv_effect06;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect06 as
SELECT  a.sales_region_new1
      ,a.ccusname
      ,a.cbustype
      ,a.cinvcode
      ,a.cinvname
      ,a.item_name
      ,if(a.cinvname_main is null,a.item_name,a.cinvname_main) as cinvname_main
      ,a.ddate
      ,sum(iquantity_person_main) as iquantity_person_main
      ,sum(a.isum_main) as isum_main
      ,sum(a.isum_child) as isum_child
      ,sum(a.isum_notax_main) as isum_notax_main
      ,sum(a.isum_notax_child) as isum_notax_child
      ,sum(a.cost_main) as cost_main
      ,sum(a.cost_child) as cost_child
      ,sum(a.equipment_depretion) as equipment_depretion
      ,sum(a.add_cost) as add_cost
      ,sum(a.add_cost_main) as add_cost_main
      
FROM shujuzu.cinv_effect05 a
GROUP BY a.ccusname,a.cinvcode,a.ddate;


CREATE INDEX index_cinv_effect06_ccusname ON shujuzu.cinv_effect06(ccusname);
CREATE INDEX index_cinv_effect06_cinvname_main ON shujuzu.cinv_effect06(cinvname_main);
CREATE INDEX index_cinv_effect06_ddate ON shujuzu.cinv_effect06(ddate);


#对应主设备名称，将二代测序仪修改为BGI500或者安诺优达，便于看保险是否需要计算。主辅关系用二代测序仪是为了便于计算分摊
UPDATE shujuzu.cinv_effect06
SET cinvname_main = 'BGISEQ-500' WHERE cinvcode = 'SJ02019' or cinvcode = 'SJ02001' or cinvcode = 'JC02080';
UPDATE shujuzu.cinv_effect06
SET cinvname_main = 'Nextseq 550AR' WHERE cinvcode = 'SJ02030' or cinvcode = 'SJ02003' or cinvcode = 'SJ05294' or cinvcode = 'SJ02029';
 UPDATE shujuzu.cinv_effect06
SET cinvname_main = 'Nextseq 550AR' WHERE ccusname = '中国福利会国际和平妇幼保健院' and cinvname_main = '二代测序仪';
 UPDATE shujuzu.cinv_effect06
SET cinvname_main = 'Nextseq 550AR' WHERE ccusname = '恩施州土家族苗族自治州中心医院' and cinvname_main = '二代测序仪';
 UPDATE shujuzu.cinv_effect06
SET cinvname_main = 'Nextseq 550AR' WHERE ccusname = '淄博市妇幼保健院' and cinvname_main = '二代测序仪';
 UPDATE shujuzu.cinv_effect06
SET cinvname_main = 'Nextseq 550AR' WHERE ccusname = '湖南省妇幼保健院' and cinvname_main = '二代测序仪';#根据折旧关系判断的

#保险 #edw.x_insure_cover已经将华大的保险成本弄成0了，因此可以直接将对应的主设备写成安诺优达的设备，对结果不影响
DROP TABLE if EXISTS shujuzu.cinv_effect_insure;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect_insure as
SELECT b.sales_region_new as sales_region_new1,ccusname,ddate,cinvname_main,sum(insure_cost) as insure_cost
FROM 
    (SELECT bi_cusname as ccusname,DATE_FORMAT(ddate,'%Y-%m-01') as ddate,
		        case when item_name = 'NIPT' then 'qt其他LDT'
								 when item_name = 'NIPT plus' then 'qt甄元LDT'
						     when left(item_name,4)='串联保险' then 'ACQUITY  I-X'
								 else 'Nextseq 550AR'
								 end as cinvname_main
						, insure_num*iunitcost as insure_cost
FROM edw.x_insure_cover) a
LEFT JOIN edw.map_customer b
ON a.ccusname = b.bi_cusname
WHERE insure_cost > 0
GROUP BY ccusname,ddate,cinvname_main;

DROP TABLE if EXISTS shujuzu.cinv_effect_insure_1;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect_insure_1 as
SELECT ccusname,ddate,cinvname_main,COUNT(DISTINCT cinvcode) as num_main1 ,sum(add_cost) as add_cost_main1 FROM shujuzu.cinv_effect06  GROUP BY ccusname,cinvname_main,ddate;

CREATE INDEX index_cinv_effect_insure_1_ccusname ON shujuzu.cinv_effect_insure_1(ccusname);
CREATE INDEX index_cinv_effect_insure_1_cinvname_main ON shujuzu.cinv_effect_insure_1(cinvname_main);
CREATE INDEX index_cinv_effect_insure_1_ddate ON shujuzu.cinv_effect_insure_1(ddate);

/*DROP TABLE if EXISTS shujuzu.add_cost_main;
CREATE TEMPORARY TABLE  shujuzu.add_cost_main as
SELECT ccusname ,ddate, cinvname_main,sum(add_cost) as add_cost_main
FROM shujuzu.cinv_effect06 a
GROUP BY ccusname ,ddate, cinvname_main;*/

DROP TABLE if EXISTS shujuzu.cinv_effect07;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect07 as
SELECT a.*,b.num_main1,b.add_cost_main1
FROM shujuzu.cinv_effect06 a
LEFT JOIN shujuzu.cinv_effect_insure_1 b
ON a.ccusname = b.ccusname and a.ddate = b.ddate and a.cinvname_main = b.cinvname_main;

CREATE INDEX index_cinv_effect07_ccusname ON shujuzu.cinv_effect07(ccusname);
CREATE INDEX index_cinv_effect07_cinvname_main ON shujuzu.cinv_effect07(cinvname_main);
CREATE INDEX index_cinv_effect07_ddate ON shujuzu.cinv_effect07(ddate);

DROP TABLE if EXISTS shujuzu.cinv_effect08;
CREATE TEMPORARY TABLE  shujuzu.cinv_effect08 as
SELECT  a.sales_region_new1
       ,a.ccusname
       ,a.cbustype
       ,a.cinvcode
       ,a.cinvname
       ,a.item_name
       ,a.cinvname_main
       ,a.ddate
       ,a.iquantity_person_main
       ,a.isum_main
       ,a.isum_child
       ,a.isum_notax_main
       ,a.isum_notax_child
       ,a.cost_main
       ,a.cost_child
       ,a.equipment_depretion
       ,if(add_cost_main1 is null or add_cost_main1 = 0,b.insure_cost*1/num_main1,b.insure_cost*(add_cost/add_cost_main1)) as insure_cost
       ,a.add_cost #按客户产品分的主试剂累计成本
       ,a.add_cost_main1 #按客户对应主设备分的主试剂累计成本
FROM shujuzu.cinv_effect07 a
LEFT JOIN (SELECT * FROM shujuzu.cinv_effect_insure WHERE  cinvname_main = 'Nextseq 550AR' or cinvname_main = 'ACQUITY  I-X')b
ON a.ccusname = b.ccusname and a.ddate = b.ddate and a.cinvname_main = b.cinvname_main
;


DROP TABLE if EXISTS shujuzu.cinv_effect;
CREATE  TABLE  shujuzu.cinv_effect as
SELECT a.sales_region_new1
       ,a.ccusname
       ,a.cbustype
       ,a.cinvcode
       ,a.cinvname
       ,a.item_name
       ,a.cinvname_main
       ,a.ddate
       ,a.iquantity_person_main
       ,a.isum_main
       ,a.isum_child
       ,a.isum_notax_main
       ,a.isum_notax_child
       ,a.cost_main
       ,a.cost_child
       ,a.equipment_depretion
       ,sum(a.insure_cost) as insure_cost
       ,a.add_cost #按客户产品分的主试剂累计成本
       ,a.add_cost_main1
FROM(
      SELECT  a.sales_region_new1
             ,a.ccusname
             ,a.cbustype
             ,a.cinvcode
             ,a.cinvname
             ,a.item_name
             ,a.cinvname_main
             ,a.ddate
             ,a.iquantity_person_main
             ,a.isum_main
             ,a.isum_child
             ,a.isum_notax_main
             ,a.isum_notax_child
             ,a.cost_main
             ,a.cost_child
             ,a.equipment_depretion
             ,a.insure_cost
             ,a.add_cost #按客户产品分的主试剂累计成本
             ,a.add_cost_main1 #按客户对应主设备分的主试剂累计成本
      FROM shujuzu.cinv_effect08 a
      UNION
      SELECT sales_region_new1
             ,ccusname
             ,'LDT'
             ,cinvname_main
             ,cinvname_main
             ,cinvname_main
             ,cinvname_main
             ,ddate
             ,null
             ,null
             ,null
             ,null
             ,null
             ,null
             ,null
             ,null
             ,insure_cost
             ,null
             ,null
      FROM shujuzu.cinv_effect_insure
      WHERE cinvname_main = 'qt其他LDT' or cinvname_main = 'qt甄元LDT')a
GROUP BY ccusname,cinvcode,ddate
;
#保险复核
SELECT sum(insure_cost)
FROM shujuzu.cinv_effect;

SELECT sum(insure_cost)
FROM shujuzu.cinv_effect_insure;
#保险存在部分差异，因为有的保险
DELETE
FROM shujuzu.cinv_effect
WHERE iquantity_person_main is null and isum_main is null and isum_child is null and isum_notax_main is null and isum_notax_child is null  and cost_main is null and cost_child is null and equipment_depretion is  null  and insure_cost is null;

#复核
SELECT sum(isum_main) +sum(isum_child)
FROM shujuzu.cinv_effect06;
SELECT sum(isum)
FROM shujuzu.sales_cost_pre2;
SELECT sum(isum_main) +sum(isum_child)
FROM shujuzu.cinv_effect;

SELECT sum(equipment_depretion) 
FROM shujuzu.cinv_effect06;

SELECT sum(amount_depre)
FROM shujuzu.eq_depreciation_relation;

update shujuzu.cinv_effect set cinvname_main = item_name where cinvname_main ='';
update shujuzu.cinv_effect set cinvname_main = '核型' where  item_name='KM1' or item_name='KM2' ;
update shujuzu.cinv_effect set cinvname_main = cinvname where item_name = '二代测序仪';
update shujuzu.cinv_effect set cinvcode= 'YQ01011' ,cinvname = 'Nextseq 550AR'  ,cinvname_main = 'Nextseq 550AR' where   cinvname_main = '二代测序仪' and ccusname = '安徽兰迪医学实验室有限公司';
update shujuzu.cinv_effect set cinvname_main = 'ACQUITY  I-X' where item_name ='串联质谱仪';
update shujuzu.cinv_effect set cinvname_main = '芯片设备' where item_name ='CMA设备';
update shujuzu.cinv_effect set cinvname_main = '毛细管电泳仪' where item_name ='产筛毛细管电泳仪';
update shujuzu.cinv_effect set cinvname_main = 'luminex 200' where item_name ='BoBs设备';
update shujuzu.cinv_effect set cinvname_main = '核型' where item_name ='GSL-120';












