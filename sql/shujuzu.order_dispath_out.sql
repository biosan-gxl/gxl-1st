drop table if exists shujuzu.order_dispath_out_tem01;
create temporary table shujuzu.order_dispath_out_tem01 as 
select db
       ,isosid
       ,ddate
       ,ccuscode
       ,ccusname
       ,if(finnal_ccuscode='multi',ccuscode,finnal_ccuscode) as finnal_ccuscode
       ,finnal_ccusname  
       ,cinvcode
       ,cinvname
       ,item_code
       ,item_name
       ,sum(order_iquantity) as order_iquantity
	     ,sum(dispath_iquantity) as dispath_iquantity
	     ,sum(out_iquantity) as out_iquantity
			 ,sum(order_isum) as order_isum
from 
(SELECT db
       ,isosid
       ,ddate
			 ,true_ccuscode as ccuscode
       ,true_ccusname as ccusname
       ,true_finnal_ccuscode as finnal_ccuscode
       ,true_finnal_ccusname1 as finnal_ccusname
       
       ,bi_cinvcode as cinvcode
       ,bi_cinvname as cinvname
       ,true_itemcode as item_code
       ,citemname as item_name
       ,iquantity as order_iquantity
	     ,0 as dispath_iquantity
	     ,0 as out_iquantity
			 ,isum as order_isum
FROM edw.sales_order 
where ddate >= '2020-01-01' and true_itemcode <> 'JK0101'
union all
SELECT  db
       ,isosid
       ,ddate
       ,true_ccuscode as ccuscode
       ,true_ccusname as ccusname
       ,true_finnal_ccuscode as finnal_ccuscode
       ,true_finnal_ccusname1 as finnal_ccusname
       
       ,bi_cinvcode as cinvcode
       ,bi_cinvname as cinvname
       ,true_itemcode as item_code
       ,citemname as item_name
	     ,0
       ,iquantity as dispath_iquantity
	     ,0
			 ,0
FROM edw.dispatch_order 
where ddate >= '2020-01-01' and true_itemcode <> 'JK0101'
union all
SELECT db
       ,iorderdid
       ,ddate
       ,true_ccuscode as ccuscode
       ,true_ccusname as ccusname
       ,true_finnal_ccuscode as finnal_ccuscode
       ,true_finnal_ccusname1 as finnal_ccusname
       
       ,bi_cinvcode as cinvcode
       ,bi_cinvname as cinvname
       ,true_itemcode as item_code
       ,citemname as item_name
	     ,0
	     ,0
       ,iquantity as out_iquantity
			 ,0
FROM edw.outdepot_order
where ddate >= '2020-01-01' and true_itemcode <> 'JK0101')a
group by db,isosid,finnal_ccuscode,cinvcode;
alter table shujuzu.order_dispath_out_tem01 add index(finnal_ccuscode),add index(cinvcode);


drop table if exists shujuzu.order_dispath_out;
create table shujuzu.order_dispath_out as 
select a.db
			   ,b.sales_region_new
       ,a.isosid
       ,a.ddate
       ,a.ccuscode
       ,a.ccusname
       ,a.finnal_ccuscode
         ,d.bi_cusname as finnal_ccusname
       ,a.cinvcode
       ,a.cinvname
         ,c.item_code
         ,c.level_three as item_name
			 ,a.order_isum
       ,a.order_iquantity
	     ,a.dispath_iquantity
	     ,a.out_iquantity
			 ,case when order_iquantity >0 and dispath_iquantity>=0 then order_iquantity - dispath_iquantity end as 'order_iquantity - dispath_iquantity'
			 ,case when order_iquantity >0 and out_iquantity>=0 then order_iquantity - out_iquantity end as 'order_iquantity - out_iquantity'
from shujuzu.order_dispath_out_tem01 a
left join edw.map_customer b
on a.finnal_ccuscode = b.bi_cuscode
left join edw.map_inventory c
on a.cinvcode =c.bi_cinvcode
left join edw.map_customer d
on a.finnal_ccuscode = d.bi_cuscode;

#复核
select 'edw',sum(order_iquantity) as order_iquantity,sum(dispath_iquantity) as dispath_iquantity,sum(out_iquantity) as out_iquantity
from 
(select 'edw',sum(iquantity) as order_iquantity,0 as dispath_iquantity,0 as out_iquantity
FROM edw.sales_order 
where ddate >= '2020-01-01' and true_itemcode <> 'JK0101'
union 
select 'edw',0,sum(iquantity) as dispath_iquantity,0
FROM edw.dispatch_order 
where ddate >= '2020-01-01' and true_itemcode <> 'JK0101'
union
select 'edw',0,0,sum(iquantity) as out_iquantity
FROM edw.outdepot_order
where ddate >= '2020-01-01' and true_itemcode <> 'JK0101')a
union
select 'shujuzu',sum(order_iquantity) as order_iquantity
	   ,sum(dispath_iquantity) as dispath_iquantity
	   ,sum(out_iquantity) as out_iquantity
from shujuzu.order_dispath_out;

DELETE 
from shujuzu.order_dispath_out
where ccuscode like 'GL%';