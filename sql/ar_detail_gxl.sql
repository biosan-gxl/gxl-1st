#获取筛选标签是非空的数据
DROP TABLE if EXISTS shujuzu.ar_detail_temp01;
CREATE TEMPORARY TABLE shujuzu.ar_detail_temp01 as 
SELECT 
     a.ccovouchid
		 ,cvouchid
     ,a.cohr 
		 ,a.cdwcode
     ,a.sales_region_new  #这个销售区域是直接客户的销售区域
     ,a.sales_dept
     ,a.ccusname
     ,a.cinvcode
     ,a.date_ar 
     ,a.idamount
		 ,a.date_ap
		 ,a.icamount
		 ,a.ccovouchtype
		 ,a.aperiod
		 ,a.ar_class
FROM pdm.ar_detail a
where mark_ is not null
;

#26、27、R0是应收，48、49、51、50是回款，48是有了回款，相应的要做一笔假的应收
delete from shujuzu.ar_detail_temp01 where (ccovouchtype = 48 or ccovouchtype = 49) and idamount <> 0
;

#根据关联ID、账套等分组
DROP TABLE if EXISTS shujuzu.ar_detail_temp02;
CREATE TEMPORARY TABLE shujuzu.ar_detail_temp02 as 
SELECT 
     a.ccovouchid
		 ,cvouchid
     ,a.cohr 
		 ,a.sales_dept
     ,a.sales_region_new  
		 ,a.cdwcode
     ,a.ccusname
     ,max(a.date_ar) as date_ar 
		 ,a.aperiod
		 ,a.ar_class
		 ,sum(a.idamount) as idamount
		
		 ,max(a.date_ap) as max_date_ap
		 ,sum(a.icamount) as icamount
		 ,convert(sum(a.idamount)-sum(a.icamount),decimal(10,1)) as yingshouyue
FROM shujuzu.ar_detail_temp01 a
group by a.ccovouchid
     ,a.cohr 
		 ,a.cdwcode
     ,a.sales_region_new  
     ,a.sales_dept
     ,a.ccusname
		 ,a.aperiod
		 ,a.ar_class
 order by a.sales_dept,a.sales_region_new ,a.ccusname 
;

alter table shujuzu.ar_detail_temp02 add index(ccovouchid);
#删除应收、回款都是0的记录
delete from shujuzu.ar_detail_temp02 where idamount = 0 and icamount = 0;

-- alter table shujuzu.ar_detail_temp02 add index(cinvcode);

#目的是想取关联ID对应的应收款的项目名称
DROP TABLE if EXISTS shujuzu.id_cinvcode01;
CREATE TEMPORARY table shujuzu.id_cinvcode01 as 
select ccovouchid,cinvcode,b.bi_cinvname,b.level_three
FROM pdm.ar_detail a
left join edw.map_inventory b
on a.cinvcode = b.bi_cinvcode
where cinvcode is not null and idamount is not null
GROUP BY ccovouchid,cinvcode
;

DROP TABLE if EXISTS shujuzu.id_cinvcode02;
CREATE TEMPORARY table shujuzu.id_cinvcode02 as
select ccovouchid,GROUP_CONCAT(distinct level_three) as item_name
from shujuzu.id_cinvcode01
group by ccovouchid
;
alter table shujuzu.id_cinvcode02 add index(ccovouchid);


DROP TABLE if EXISTS shujuzu.ar_detail_gxl;
CREATE  TABLE shujuzu.ar_detail_gxl as 
select a.ccovouchid
		 ,a.cvouchid
     ,a.cohr 
		 ,a.sales_dept
     ,a.sales_region_new  
		 ,a.cdwcode
     ,a.ccusname
     -- ,a.cinvcode
		 -- ,b.bi_cinvname
		 ,b.item_name
     ,a.date_ar 
		 ,a.aperiod
		 ,a.ar_class
		 ,a.idamount
		 ,ADDDATE(a.date_ar, INTERVAL a.aperiod month) as date_yinghui
		 ,case 
		      when timestampdiff(month,date_ar,now())-aperiod >= 0  and yingshouyue <>0 #判断超期 且未回款
					     then timestampdiff(month,date_ar,now())-aperiod 
					else null
					end as chaozhangqiyue 
		 ,a.max_date_ap
		 ,a.icamount
		 ,a.yingshouyue
from shujuzu.ar_detail_temp02 a
-- left join edw.map_inventory b
-- on a.cinvcode = b.bi_cinvcode
left join shujuzu.id_cinvcode02 b
on a.ccovouchid = b.ccovouchid
;
