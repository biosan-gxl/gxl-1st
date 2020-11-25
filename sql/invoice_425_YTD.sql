-- 1. 先得到各地级市各项目各年月的收入

-- 先生成基础数据 来源 pdm.invoice_order 并且把finnal_ccuscode = multi的处理掉
drop  temporary table if exists shujuzu.invoice_425_tem00;
create  temporary table if not exists shujuzu.invoice_425_tem00
select 
	cohr
	,ddate
	,if(finnal_ccuscode = 'mulit', ccuscode,finnal_ccuscode) as ccuscode 
	,cinvcode
	,isum
from pdm.invoice_order 
where year(ddate) >= 2018 and item_code != 'JK0101';
alter  table shujuzu.invoice_425_tem00 add index(ccuscode),add index(cinvcode);

-- 为了核对数据方便, 这里取所有的数据, 杭州贝生 将sales_dept写为 杭州贝生 
drop   table if exists shujuzu.invoice_425_tem01;
create  temporary table if not exists shujuzu.invoice_425_tem01
select
concat(if(a.cohr = '杭州贝生','杭州贝生',b.sales_dept),if(a.cohr = '杭州贝生','杭州贝生',b.sales_region_new),if(b.city is null,'',b.city),if(c.item_code is null,'',c.item_code),year(a.ddate),month(a.ddate)) as concatid
	,case 
		when a.cohr = '杭州贝生' then '杭州贝生'
		else b.sales_dept 
	end as sales_dept1 
	,if(a.cohr = '杭州贝生','杭州贝生',b.sales_region_new) as sales_region_new1
	,b.province
	,if(b.city is null,' ',b.city) as city
	,if(c.item_code is null,' ',c.item_code) as item_code
	,c.level_three as item_name 
	,c.425_item 
	,year(a.ddate) as year_ 
	,month(a.ddate) as month_ 
	,round(sum(a.isum),4) as isum 
from shujuzu.invoice_425_tem00 as a 
left join edw.map_customer as b 
on a.ccuscode = b.bi_cuscode 
left join edw.map_inventory as c  
on a.cinvcode = c.bi_cinvcode
group by a.cohr,sales_dept1,sales_region_new1,b.city,c.item_code,c.425_item,year(a.ddate),month(a.ddate);

alter  table shujuzu.invoice_425_tem01 add index(concatid);

-- 求YTD的收入
-- 2.2 处理YTD数据
drop   table if exists shujuzu.invoice_425_YTDtem04;
create  temporary  table if not exists shujuzu.invoice_425_YTDtem04(
	concatid varchar(255),
	sales_dept1 varchar(20),
	sales_region_new1 varchar(20),
	province varchar(10),
  	city varchar(60),
  	item_code varchar(10),
  	item_name varchar(20),
	425_item varchar(10), 
	year_ smallint,
	month_ smallint,
	isum_YTD decimal(30,0),
	key index_tem04_concatid (concatid)
)engine=innodb default charset=utf8;

-- 创建存储过程提取送样YTD数据
drop procedure if exists shujuzu.n425_pro_2;
delimiter $$
create procedure shujuzu.n425_pro_2()
begin
	declare i int default 1;
	while i <= 12 do
		insert into shujuzu.invoice_425_YTDtem04
		select 
		concat(city,item_code,year_,i) as concatid
			,sales_dept1 
	,a.sales_region_new1
	,a.province
	,a.city
	,a.item_code
	,a.item_name 
	,a.425_item 
	,a.year_ 
	,i as month_
	,sum(isum) as isum_YTD
		from shujuzu.invoice_425_tem01 a
		where month_ <= i
		group by sales_dept1,sales_region_new1,city,item_code,year_;
	set i=i+1;
	end while;
  commit;
end
$$
delimiter ;

call shujuzu.n425_pro_2();

alter  table shujuzu.invoice_425_YTDtem04 add index(concatid);

#关联送样，处理收入分摊
drop   table if exists shujuzu.invoice_425_YTDtem05;
create  temporary  table if not exists shujuzu.invoice_425_YTDtem05
select concatid
	,a.sales_dept1 
	,a.sales_region_new1
	,a.province
	,a.city
	,a.item_code
	,a.item_name 
	,a.425_item 
	,a.year_ 
	,a.month_
	,a.isum_YTD
	,b.city_give
	,b.inum_person_songyang
	,b.inum_person_all
	,isum_YTD*inum_person_songyang/inum_person_all as fentan_YTD
from shujuzu.invoice_425_YTDtem04 a
left join shujuzu.new425_03_delivery_ytd b 
on a.concatid = b.concatid
where a.sales_dept1 = '销售一部' or a.sales_dept1 = '销售二部'
;
delete from shujuzu.invoice_425_YTDtem05 where fentan_YTD is null or fentan_YTD = 0;

#得本院的收入，通过收入YTD减去分摊掉的收入
drop   table if exists shujuzu.invoice_425_YTDtem06;
create  temporary  table if not exists shujuzu.invoice_425_YTDtem06
select
     a.concatid
	,a.sales_dept1 
	,a.sales_region_new1
	,a.province
	,a.city
	,a.item_code
	,a.item_name 
	,a.425_item 
	,a.year_ 
	,a.month_
	,a.isum_YTD - if(b.fentan_YTD is null,0,b.fentan_YTD) as benyuan_YTD
from shujuzu.invoice_425_YTDtem04 a
left join 
        (select concatid
        	,a.sales_dept1 
        	,a.sales_region_new1
        	,a.province
        	,a.city
        	,a.item_code
        	,a.item_name 
        	,a.425_item 
        	,a.year_ 
        	,a.month_
        	,sum(fentan_YTD) as fentan_YTD
        from shujuzu.invoice_425_YTDtem05 a
        group by concatid)b 
on a.concatid = b.concatid;

#将收样医院本院的收入与送样医院被分摊到的收入合并
drop   table if exists shujuzu.invoice_425_YTDtem07;
create  temporary  table if not exists shujuzu.invoice_425_YTDtem07
select
     a.concatid
	,a.sales_dept1 
	,a.sales_region_new1
	,a.province
	,a.city
	,a.item_code
	,a.item_name 
	,a.425_item 
	,a.year_ 
	,a.month_
	,a.benyuan_YTD
from shujuzu.invoice_425_YTDtem06 a 
union 
select 
concat(city_give,item_code,year_,month_) as concatid
	,a.sales_dept1 
	,a.sales_region_new1
	,a.province
	,a.city_give as city
	,a.item_code
	,a.item_name 
	,a.425_item 
	,a.year_ 
	,a.month_
	,a.fentan_YTD as benyuan_YTD
from shujuzu.invoice_425_YTDtem05 a
;
alter  table shujuzu.invoice_425_YTDtem07 add index(city);	
alter  table shujuzu.invoice_425_YTDtem07 add index(year_);	
alter  table shujuzu.invoice_425_YTDtem07 add index(month_);	

drop   table if exists shujuzu.invoice_425_YTD;
create   table if not exists shujuzu.invoice_425_YTD
select a.concatid
     	,a.sales_dept1 
     	,a.sales_region_new1
     	,a.province
     	,a.city
     	,a.425_item 
     	,a.year_ 
     	,a.month_
     	,a.benyuan_YTD
		,b.population_fenmu_YTD
	    ,a.benyuan_YTD/b.population_fenmu_YTD as 425_price
from 
     (select
          a.concatid
     	,a.sales_dept1 
     	,a.sales_region_new1
     	,a.province
     	,a.city
     	,a.item_code
     	,a.item_name 
     	,a.425_item 
     	,a.year_ 
     	,a.month_
     	,sum(a.benyuan_YTD) as benyuan_YTD
     from shujuzu.invoice_425_YTDtem07 a 
     group by sales_dept1,sales_region_new1,city,425_item,year_,month_)a
left join shujuzu.new425_population b
on a.city = b.city and a.year_ = b.year_ and a.month_ = b.month_
;

