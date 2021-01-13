DROP TABLE if EXISTS shujuzu.test0;				
CREATE TEMPORARY TABLE shujuzu.test0 as 				
SELECT sales_dept				
       ,sales_region_new	#销售区域是按直接客户区分的，但是bi上是按照最终客户区分的			
       ,ddate				
       ,case when ddate >= '2020-11-01' and ddate <= '2020-11-08' then '1102-08'				
             when ddate >= '2020-11-09' and ddate <= '2020-11-15' then '1109-15'				
             when ddate >= '2020-11-16' and ddate <= '2020-11-22' then '1116-22'				
             when ddate >= '2020-11-23' and ddate <= '2020-11-30' then '1123-30'
						 when ddate >= '2020-12-01' and ddate <= '2020-12-07' then '1201-07'
						 when ddate >= '2020-12-08' and ddate <= '2020-12-14' then '1208-14'
						 when ddate >= '2020-12-15' and ddate <= '2020-12-21' then '1215-21'
						 when ddate >= '2020-12-22' and ddate <= '2020-12-28' then '1222-28'
						 when ddate >= '2020-12-29' and ddate <= '2020-12-31' then '1229-31'
             else null 				
             end as ddate1				
       ,finnal_ccusname				
       ,sum(invoice_isum)/1000 as invoice_isum				
       ,sum(order_isum)/1000 as order_isum				
FROM 				
    (SELECT if(cohr='杭州贝生','杭州贝生',sales_dept) as sales_dept				
            ,if(cohr='杭州贝生','杭州贝生',sales_region_new) as sales_region_new				
    				,ddate
    				,finnal_ccusname
    				,isum as invoice_isum
    				,null as order_isum
    FROM pdm.invoice_order				
    WHERE ddate >= '2020-11-01'	and item_code <> 'JK0101'			
    UNION ALL				
    SELECT if(cohr='杭州贝生','杭州贝生',sales_dept) as sales_dept				
           ,if(cohr='杭州贝生','杭州贝生',sales_region_new) as sales_region_new				
           ,ddate				
           ,finnal_ccusname				
    			 ,null as invoice_isum	
           ,isum as order_isum				
    FROM pdm.sales_order				
    WHERE ddate >= '2020-11-01' and item_code <> 'JK0101')a				
GROUP BY sales_region_new,ddate,finnal_ccusname;

DROP TABLE if EXISTS shujuzu.test1;				
CREATE TABLE shujuzu.test1 as
SELECT if(a.sales_dept = '杭州贝生','杭州贝生',b.sales_dept) as sales_dept	#销售区域和部分重新按照最终客户匹配		
       ,if(a.sales_region_new = '杭州贝生','杭州贝生',b.sales_region_new) as sales_region_new		#销售区域和部分重新按照最终客户匹配		
       ,a.ddate				
       ,a.ddate1				
       ,a.finnal_ccusname				
       ,a.invoice_isum				
       ,a.order_isum	
FROM shujuzu.test0 a
LEFT JOIN edw.map_customer b
ON a.finnal_ccusname = b.bi_cusname
;
#复核				
SELECT sum(invoice_isum),sum(order_isum)				
FROM shujuzu.test1;				
SELECT sum(isum)				
FROM pdm.invoice_order				
WHERE ddate >= '2020-11-01' and item_code <> 'JK0101';				
SELECT sum(isum)				
FROM pdm.sales_order				
WHERE ddate >= '2020-11-01'	 and item_code <> 'JK0101'			
