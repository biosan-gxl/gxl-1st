-- 425项目客单价

-- 关于有集中送样情况的, 来源分 本院 送样医院 
-- CRM检测量填写规则记录:   
-- 浙江全部: 本院
-- 安徽NIPT: 本院
-- 湖北宜昌新筛: 本院  (恩施送样)
-- 其余所有: 本院+送样医院
-- pdm.checklist
-- edw.x_macrodata
-- edw.x_ccus_delivery_new

-- 1. 先处理人口数据 (TSH,或人口) 
-- 1.1 获取7省所有省份+地级市
drop table if exists shujuzu.new425_01_population;

create temporary table shujuzu.new425_01_population(
	province varchar(10)
	,city varchar(10)
	,year_ int(4)
	,month_  int(4)
	,rules_crm varchar(20) comment 'CRM填写规则'
	,inum_ori_tsh  int(8) comment 'pdmchecklisttsh检测量'
	,inum_shouyang_tsh int(8) comment 'tsh收样数量'
	,inum_songyang_tsh int(8) comment 'tsh送样数量'
	,inum_confirm_tsh int(8) comment '确认tsh数量'
	,inum_ori_17 int(8) comment 'pdmchecklist17oh检测量'
	,inum_shouyang_17 int(8) comment '17oh收样数量'
	,inum_songyang_17 int(8) comment '17oh送样数量'
	,inum_confirm_17 int(8) comment '确认17oh数量'
	,newborn_popu int(8) comment '宏观人口数据'
	,population_fenmu int(8) comment '最终确认的人口数（分母）'
	,mark_result varchar(20) comment '最终确认的数据来源')
	;

drop temporary table if exists shujuzu.c425_citys_tem01;
create temporary table if not exists shujuzu.c425_citys_tem01
select 
	province
	,city
from edw.map_customer 
where province in ('浙江省','江苏省','安徽省','福建省','山东省','湖南省','湖北省')
group by province,city;

-- 1.2 生成年月基础表 从 ufdata.x_calendar取数, 2017年开始 暂定到20年 
drop temporary table if exists shujuzu.c425_months_tem01;
create temporary table if not exists shujuzu.c425_months_tem01
select 
	year(ddate) as year_
	,month(ddate) as month_
from ufdata.x_calendar
where year(ddate) >= 2017 and year(ddate) <= 2020
group by year(ddate),month(ddate);

-- 1.3 组合生成425地级市年月基础表  生成concatid用于jion
drop temporary table if exists shujuzu.c425_city_month_tem01;
create temporary table if not exists shujuzu.c425_city_month_tem01
select 
	concat(a.province,a.city,b.year_,b.month_) as concatid
	,a.province,a.city,b.year_,b.month_
from shujuzu.c425_citys_tem01 as a 
left join shujuzu.c425_months_tem01 as b 
on 1 = 1;
alter table shujuzu.c425_city_month_tem01 add index(concatid);  -- concatid: a.province,a.city,b.year_,b.month_


-- 1.4 通过上面基础表关联   1.pdm检测量checklist中TSH与17羟原始数据 2. 宏观人口数据 3.集中送样中tsh与17羟数据
-- 1.4.1 tsh与17羟检测量
drop temporary table if exists shujuzu.c425_checklist_tsh_17;
create temporary table if not exists shujuzu.c425_checklist_tsh_17
select 
	concat(b.province,b.city,year(a.ddate),month(a.ddate)) as concatid
	,b.province
	,b.city 
	,year(a.ddate) as year_
	,month(a.ddate) as month_
	,sum(case when a.item_name = 'TSH' then inum_person else 0 end) as inum_ori_tsh
	,sum(case when a.item_name = '17α-OH-P' then inum_person else 0 end) as inum_ori_17
from pdm.checklist as a 
left join edw.map_customer as b 
on a.ccuscode = b.bi_cuscode 
where year(a.ddate) >= 2017 
group by b.province,b.city,year(a.ddate),month(a.ddate);
alter table shujuzu.c425_city_month_tem01 add index(concatid);

-- 1.4.2 宏观人口数据, 来源edw.x_macrodata  取总人口 乘以 出生率 算出每年的出生人口 除以12估算每月每月的出生人口(单位:人)
drop temporary table if exists shujuzu.c425_macrodata;
create temporary table if not exists shujuzu.c425_macrodata
select 
	province
	,city
	,year_
	,round(tp*natality*10/12,0) as newborn_popu-- tp:总人口(万人) natality:出生率(千分之一), 不保留小数
from edw.x_macrodata 
where year_ >= 2017;

-- 1.4.3 集中送样中tsh与17羟数据  省份地级市收样数据
drop temporary table if exists shujuzu.c425_delivery_shouyang;
create temporary table if not exists shujuzu.c425_delivery_shouyang
select 
	concat(province_get,city_get,year(ddate),month(ddate)) as concatid
	,province_get as province
	,city_get
	,year(ddate) as year_ 
	,month(ddate) as month_ 
	,sum(case when item_name = 'TSH' then inum_person else 0 end) as inum_shouyang_tsh
	,sum(case when item_name = '17α-OH-P' then inum_person else 0 end) as inum_shouyang_17
from edw.x_ccus_delivery_new 
where year(ddate) >= 2017 
group by province_get,city_get,year_,month_;
alter table shujuzu.c425_delivery_shouyang add index(concatid);


-- 1.4.4 集中送样中tsh与17羟数据  省份地级市送样数据
drop temporary table if exists shujuzu.c425_delivery_songyang;
create temporary table if not exists shujuzu.c425_delivery_songyang
select 
	concat(b.province,a.city_give,year(a.ddate),month(a.ddate)) as concatid
	,b.province
	,a.city_give
	,year(a.ddate) as year_ 
	,month(a.ddate) as month_ 
	,sum(case when a.item_name = 'TSH' then inum_person else 0 end) as inum_songyang_tsh
	,sum(case when a.item_name = '17α-OH-P' then inum_person else 0 end) as inum_songyang_17
from edw.x_ccus_delivery_new as a 
left join (select province,city from edw.map_customer group by city) as b  -- 目前没有发现跨省送样情况, 保险起见通过客户档案关联得到送样地级市对应省份
on a.city_give = b.city
where year(ddate) >= 2017 
group by b.province,a.city_give,year_,month_;
alter table shujuzu.c425_delivery_songyang add index(concatid);

-- 1.4.5 通过基础表关联以上所有 
drop temporary table if exists shujuzu.new425_population_tem01;
create temporary table if not exists shujuzu.new425_population_tem01
select 
	a.*
	,case 
		when a.province = '浙江省' then 'CRM填本院'
		when a.province = '湖北省' and a.city = '宜昌市' then 'CRM填本院' 
		else 'CRM填本院+送样医院'
	end as rules_crm
	,b.inum_ori_tsh 
	,d.inum_shouyang_tsh
	,e.inum_songyang_tsh
	,case 
		when a.province = '浙江省' then b.inum_ori_tsh 
		when a.province = '湖北省' and a.city = '宜昌市' then b.inum_ori_tsh 
		else ifnull(b.inum_ori_tsh,0) - ifnull(d.inum_shouyang_tsh,0) + ifnull(e.inum_songyang_tsh,0)
	end as inum_confirm_tsh
	,b.inum_ori_17
	,d.inum_shouyang_17
	,e.inum_songyang_17
	,case 
		when a.province = '浙江省' then b.inum_ori_17
		when a.province = '湖北省' and a.city = '宜昌市' then b.inum_ori_17
		else ifnull(b.inum_ori_17,0) - ifnull(d.inum_shouyang_17,0) + ifnull(e.inum_songyang_17,0)
	end as inum_confirm_17
	,c.newborn_popu
from shujuzu.c425_city_month_tem01 as a 
left join shujuzu.c425_checklist_tsh_17 as b 
on a.concatid = b.concatid
left join shujuzu.c425_macrodata as c 
on a.province = c.province and a.city = c.city and a.year_ = c.year_
left join shujuzu.c425_delivery_shouyang as d 
on a.concatid = d.concatid
left join shujuzu.c425_delivery_songyang as e
on a.concatid = e.concatid
;

-- 1.4.6 判断用哪个金额做为人口分母 
truncate table shujuzu.new425_01_population;
insert into shujuzu.new425_01_population
select 
	province
	,city
	,year_
	,month_ 
	,rules_crm
	,inum_ori_tsh
	,inum_shouyang_tsh
	,inum_songyang_tsh
	,inum_confirm_tsh
	,inum_ori_17
	,inum_shouyang_17
	,inum_songyang_17
	,inum_confirm_17
	,newborn_popu
	,case  
		when ifnull(inum_confirm_tsh,0) > 50 then inum_confirm_tsh  -- 避免异常数据 例如潜江2020年3月TSH检测量5 (来源送样)
		when ifnull(inum_confirm_tsh,0) < 50 and ifnull(inum_confirm_17,0) > 50 then inum_confirm_17 -- 无TSH时用 17羟的检测量
		when ifnull(inum_confirm_tsh,0) < 50 and ifnull(inum_confirm_17,0) < 50 then newborn_popu  -- TSH与17羟都无数据, 用出生人口 
		else newborn_popu
	end as population_fenmu
	,case  
		when ifnull(inum_confirm_tsh,0) > 50 then 'tsh'  -- 避免异常数据 例如潜江2020年3月TSH检测量5 (来源送样)
		when ifnull(inum_confirm_tsh,0) < 50 and ifnull(inum_confirm_17,0) > 50 then '17α' -- 无TSH时用 17羟的检测量
		when ifnull(inum_confirm_tsh,0) < 50 and ifnull(inum_confirm_17,0) < 50 then 'newborn_popu'  -- TSH与17羟都无数据, 用出生人口 
		else 'newborn_popu'
	end as mark_result
from shujuzu.new425_population_tem01;

-- 补充: 处理中间是空的或者未填写的部门 以平均值暂估
-- 1.5.0 先将population_fenmu = 0 的 改为null 方便计数
update shujuzu.new425_01_population set population_fenmu = null where population_fenmu = 0;

-- 1.5.1 取2019-2020年各省份地级市平均值 
drop temporary table if exists shujuzu.new425_chulikong_tem01;
create temporary table if not exists shujuzu.new425_chulikong_tem01
select 
	province 
	,city
	,sum(ifnull(population_fenmu,0)) as population_fenmu_sum 
	,count(population_fenmu) as population_fenmu_sum_count
	,ifnull(sum(ifnull(population_fenmu,0)),0) / ifnull(count(population_fenmu),1) as population_fenmu_cal
from shujuzu.new425_01_population 
where year_ >= 2019
group by province,city;

-- 1.5.2 全部年份 各省份地级市平均值 
drop temporary table if exists shujuzu.new425_chulikong_tem02;
create temporary table if not exists shujuzu.new425_chulikong_tem02
select 
	province 
	,city
	,sum(ifnull(population_fenmu,0)) as population_fenmu_sum 
	,count(population_fenmu) as population_fenmu_sum_count
	,ifnull(sum(ifnull(population_fenmu,0)),0) / ifnull(count(population_fenmu),1) as population_fenmu_cal
from shujuzu.new425_01_population 
group by province,city;
	
-- 1.5.3 用2019-2020 代替null
update shujuzu.new425_01_population as a
inner join shujuzu.new425_chulikong_tem01 as b 
on a.province = b.province and a.city = b.city 
set a.population_fenmu = b.population_fenmu_cal ,mark_result = '用19-20年数据暂估'
where population_fenmu is null ;

-- 1.5.4 用全部年份 代替null
update shujuzu.new425_01_population as a
inner join shujuzu.new425_chulikong_tem02 as b 
on a.province = b.province and a.city = b.city 
set a.population_fenmu = b.population_fenmu_cal ,mark_result = '用全部年份数据暂估'
where population_fenmu is null ;
	
	
#创建存储过程，求YTD人口
drop table if exists shujuzu.new425_population;

create temporary table shujuzu.new425_population(
	province varchar(10)
	,city varchar(10)
	,year_ int(4)
	,month_  int(4)
	,population_fenmu_YTD int(8) comment '最终确认的人口数（分母）')
	;
drop procedure if exists shujuzu.population;
delimiter $$
create procedure shujuzu.population()
begin
	declare i int default 1;
	while i <= 12 do
		insert into shujuzu.new425_population
		select 
		province 
	    ,city 
	    ,year_ 
	    ,i as month_
	    ,sum(population_fenmu) as population_fenmu_YTD
		from shujuzu.new425_01_population
		where month_ <= i
		group by city,year_;
	set i=i+1;
	end while;
  commit;
end
$$
delimiter ;

call shujuzu.population();
	
alter  table shujuzu.new425_population add index(city);	
alter  table shujuzu.new425_population add index(year_);	
alter  table shujuzu.new425_population add index(month_);	

-- 处理集中送样YTD的送样量 

-- 2. 处理出收样地级市的本院检测量 与 收样检测量 
-- 2.1 获取原始检测量数据 省份+地级市+项目 2018年开始按年月聚合 检测量  产品类 非竞争对手的 
drop temporary table if exists shujuzu.n425_checklist_gb;
create temporary table if not exists shujuzu.n425_checklist_gb
select 
	concat(b.city,a.item_code,year(a.ddate),month(a.ddate)) as concatid
	,b.province
	,b.city
	,a.item_code
	,a.item_name
	,year(a.ddate) as year_ 
	,month(a.ddate) as month_ 
	,sum(inum_person) as inum_person_ori
from pdm.checklist as a 
left join edw.map_customer as b 
on a.ccuscode = b.bi_cuscode 
where year(a.ddate) >= 2018 and a.competitor = '否' and a.cbustype = '产品类' -- 2018年开始, 集中送样只有2018年开始有数据
-- and a.item_code in (select item_code from edw.x_ccus_delivery_new group by item_code) -- 只获取集中送样里的项目 减少数据量
-- and b.city in (select city_get from edw.x_ccus_delivery_new group by city_get)  -- 只获取集中送样里的收样地级市 减少数据量
group by b.province,b.city,a.item_code,year(a.ddate),month(a.ddate);
alter table shujuzu.n425_checklist_gb add index(concatid);

-- select count(*) from shujuzu.n425_checklist_gb;

-- 2.2 生成集中送样基础表 收样省份,地级市, 项目,收样量
drop temporary table if exists shujuzu.n425_delivery_tem00;
create temporary table if not exists shujuzu.n425_delivery_tem00
select 
	concat(city_get,item_code,year(ddate),month(ddate)) as concatid
	,province_get as province
	,city_get as city
	,item_code
	,item_name
	,year(ddate) as year_
	,month(ddate) as month_
	,sum(inum_person) as inum_person_shouyang
from edw.x_ccus_delivery_new 
group by city_get,item_code,item_name,year(ddate),month(ddate);
alter table shujuzu.n425_delivery_tem00 add index(concatid);

-- 2.3 通过shujuzu.n425_delivery_tem00  关联 shujuzu.n425_checklist_gb  获取收样地级市原始检测量
drop temporary table if exists shujuzu.n425_delivery_tem01;
create temporary table if not exists shujuzu.n425_delivery_tem01
select 
	a.province
	,a.city
	,a.item_code 
	,a.item_name
	,a.year_
	,a.month_
	,case 
		when a.province = '浙江省' then 'CRM填本院'
		when a.province = '湖北省' and a.city = '宜昌市' then 'CRM填本院' 
		when a.province = '安徽省' and a.item_name = 'NIPT' then 'CRM填本院'  -- 填报规则见上个脚本 
		else 'CRM填本院+送样医院'
	end as rules_crm
	,a.inum_person_shouyang
	,b.inum_person_ori
from shujuzu.n425_delivery_tem00 as a 
left join shujuzu.n425_checklist_gb as b 
on a.concatid = b.concatid;

-- 2.4 通过规则标签 判断本院检测量 与 全部检测量 
drop temporary table if exists shujuzu.n425_delivery_tem02;
create temporary table if not exists shujuzu.n425_delivery_tem02
select 
	concat(city,item_code,year_,month_) as concatid
	,province
	,city
	,item_code 
	,item_name
	,year_
	,month_
	,rules_crm
	,inum_person_shouyang
	,inum_person_ori
	,case 
		when rules_crm = 'CRM填本院' then inum_person_ori
		else ifnull(inum_person_ori,0) - ifnull(inum_person_shouyang,0)
	end as inum_person_benyuan
	,case 
		when rules_crm = 'CRM填本院' then ifnull(inum_person_ori,0) + ifnull(inum_person_shouyang,0)
		else ifnull(inum_person_ori,0)
	end as inum_person_all 
from shujuzu.n425_delivery_tem01;
alter table shujuzu.n425_delivery_tem02 add index(concatid);

-- 3. 关联送样关系表 获取每月的 收样 与 送样数据  
-- 3.1 获取集中送样基础表 
drop temporary table if exists shujuzu.n425_delivery_tem10;
create temporary table if not exists shujuzu.n425_delivery_tem10
select 
	concat(city_get,item_code,year(ddate),month(ddate)) as concatid
	,province_get 
	,city_get 
	,city_give
	,item_code
	,item_name
	,year(ddate) as year_
	,month(ddate) as month_
	,sum(inum_person) as inum_person_songyang
from edw.x_ccus_delivery_new 
group by city_get,city_give,item_code,item_name,year(ddate),month(ddate);
alter table shujuzu.n425_delivery_tem10 add index(concatid);

-- 3.2 获取每月的 收样 与 送样数据   这里收样地级市的数据会重复, 调用时需要去重 
drop table if exists shujuzu.new425_02_delivery;
create temporary table if not exists shujuzu.new425_02_delivery
select 
	a.concatid 
	,a.province_get 
	,a.city_get 
	,a.city_give
	,a.item_code
	,a.item_name
	,a.year_
	,a.month_ 
	,a.inum_person_songyang
	,b.rules_crm
	,b.inum_person_shouyang
	,b.inum_person_ori
	,b.inum_person_benyuan
	,b.inum_person_all 
from shujuzu.n425_delivery_tem10 as a 
left join shujuzu.n425_delivery_tem02 as b 
on a.concatid = b.concatid;

-- 处理分摊比例 计算YTD数据与比例 

-- 3.3. 处理YTD 送样数据 
drop temporary table if exists shujuzu.new425_03_delivery_tem00;
create temporary table if not exists shujuzu.new425_03_delivery_tem00(
	concatid varchar(255),
	province_get varchar(60),
	city_get varchar(60),
	city_give varchar(60),
	item_code varchar(60),
	item_name varchar(90),
	year_ smallint,
	month_ smallint,
	inum_person_songyang decimal(30,0),
	key index_tem00_concatid (concatid)
)engine=innodb default charset=utf8;

-- 创建存储过程提取送样TYD数据
drop procedure if exists shujuzu.n425_pro;
delimiter $$
create procedure shujuzu.n425_pro()
begin
	declare i int default 1;
	while i <= 12 do
		insert into shujuzu.new425_03_delivery_tem00
		select 
			concat(city_get,item_code,year_,i) as concatid
			,province_get
			,city_get
			,city_give
			,item_code
			,item_name
			,year_
			,i as month_
			,sum(inum_person_songyang) as inum_person_songyang
		from new425_02_delivery 
		where month_ <= i
		group by city_get,city_give,item_code,year_;
	set i=i+1;
	end while;
  commit;
end
$$
delimiter ;

call shujuzu.n425_pro();

-- 3.4. 处理YTD 收样地级市 检测量
--  先生成基础数据 
drop temporary table if exists shujuzu.new425_03_delivery_tem01;
create temporary table if not exists shujuzu.new425_03_delivery_tem01
select 
	city_get
	,item_code
	,year_
	,month_
	,inum_person_all
from new425_02_delivery 
group by city_get,item_code,year_,month_;

-- 3.5 处理YTD数据
drop temporary table if exists shujuzu.new425_03_delivery_tem02;
create temporary table if not exists shujuzu.new425_03_delivery_tem02(
	concatid varchar(255),
	city_get varchar(60),
	item_code varchar(60),
	year_ smallint,
	month_ smallint,
	inum_person_all decimal(30,0),
	key index_tem02_concatid (concatid)
)engine=innodb default charset=utf8;

-- 创建存储过程提取送样YTD数据
drop procedure if exists shujuzu.n425_pro_2;
delimiter $$
create procedure shujuzu.n425_pro_2()
begin
	declare i int default 1;
	while i <= 12 do
		insert into shujuzu.new425_03_delivery_tem02
		select 
			concat(city_get,item_code,year_,i) as concatid
			,city_get
			,item_code
			,year_
			,i as month_
			,sum(inum_person_all) as inum_person_all
		from new425_03_delivery_tem01 
		where month_ <= i
		group by city_get,item_code,year_;
	set i=i+1;
	end while;
  commit;
end
$$
delimiter ;

call shujuzu.n425_pro_2();
	

-- 关联获取比例数据 
drop table if exists shujuzu.new425_03_delivery_ytd;
create temporary table if not exists shujuzu.new425_03_delivery_ytd
select concat(a.city_get,a.item_code,a.year_,a.month_) as concatid
	,a.province_get
	,a.city_get
	,a.city_give
	,a.item_code
	,a.item_name
	,a.year_
	,a.month_
	,a.inum_person_songyang
	,b.inum_person_all
from new425_03_delivery_tem00 as a 
left join new425_03_delivery_tem02 as b 
on a.concatid = b.concatid;
-- select * from shujuzu.new425_03_delivery_ytd;
	
#删除inum_person_all = 0的数据
delete from shujuzu.new425_03_delivery_ytd
where inum_person_all = 0;

#增加索引
alter table shujuzu.new425_03_delivery_ytd add index(concatid);
	
	
-- 4. 先得到各地级市各项目各年月的收入

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
-- 4.2 处理YTD数据
drop   table if exists shujuzu.new425_cuspricetem04;
create  temporary  table if not exists shujuzu.new425_cuspricetem04(
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
		insert into shujuzu.new425_cuspricetem04
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

alter  table shujuzu.new425_cuspricetem04 add index(concatid);

#关联送样，处理收入分摊
drop   table if exists shujuzu.new425_cuspricetem05;
create  temporary  table if not exists shujuzu.new425_cuspricetem05
select a.concatid
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
from shujuzu.new425_cuspricetem04 a
left join shujuzu.new425_03_delivery_ytd b 
on a.concatid = b.concatid
where a.sales_dept1 = '销售一部' or a.sales_dept1 = '销售二部'
;
delete from shujuzu.new425_cuspricetem05 where fentan_YTD is null or fentan_YTD = 0;

#得本院的收入，通过收入YTD减去分摊掉的收入
drop   table if exists shujuzu.new425_cuspricetem06;
create  temporary  table if not exists shujuzu.new425_cuspricetem06
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
from shujuzu.new425_cuspricetem04 a
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
        from shujuzu.new425_cuspricetem05 a
        group by concatid)b 
on a.concatid = b.concatid;

#将收样医院本院的收入与送样医院被分摊到的收入合并
drop   table if exists shujuzu.new425_cuspricetem07;
create  temporary  table if not exists shujuzu.new425_cuspricetem07
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
from shujuzu.new425_cuspricetem06 a 
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
from shujuzu.new425_cuspricetem05 a
;
alter  table shujuzu.new425_cuspricetem07 add index(city);	
alter  table shujuzu.new425_cuspricetem07 add index(year_);	
alter  table shujuzu.new425_cuspricetem07 add index(month_);	

drop   table if exists shujuzu.new425_cusprice;
create   table if not exists shujuzu.new425_cusprice
select a.sales_dept1 
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
     from shujuzu.new425_cuspricetem07 a 
     group by sales_dept1,sales_region_new1,city,425_item,year_,month_)a
left join shujuzu.new425_population b
on a.city = b.city and a.year_ = b.year_ and a.month_ = b.month_
;




	
	
	
	
	
	
	
	
	

