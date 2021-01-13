-- 1. 得到分析的基础表，筛选销售中心、市场中心、技术保障中心的差旅报销记录
-- 1.1 匹配人员的二级部门
drop table if exists shujuzu.account_fy_temp01;
create temporary table shujuzu.account_fy_temp01 as 
SELECT 
     cpersonname
	 ,if(fashengrq is null,dbill_date,fashengrq) as fashengrq
     ,case when b.second_dept is null or b.second_dept = '浙江博圣生物技术股份有限公司' then c.second_dept
           else b.second_dept 
		   end as second_dept
     ,if(ccuscode is null,'请核查',ccuscode) as ccuscode
     ,ccusname
     ,md
FROM  pdm.account_fy a
left join edw.ehr_employee b
on a.cpersonname = b.name
left join db_111.ehr_employee c
on a.cpersonname = c.name
where cpersonname is not null and code_name_lv2 = '差旅费'
;
		  
-- 1.2 过滤部门，只取销售中心、市场中心、技术保障中心
drop table if exists shujuzu.account_fy_temp02;
create temporary table shujuzu.account_fy_temp02 as 
SELECT 
     cpersonname
	 ,fashengrq
     ,second_dept
     ,ccuscode
     ,ccusname
     ,md
FROM shujuzu.account_fy_temp01
where second_dept regexp '销售中心|市场中心|技术保障中心' and fashengrq >= '2019-01-01'
;
-- 2. 人员维度
drop table if exists shujuzu.account_fy_person01;
create temporary table shujuzu.account_fy_person01 as 
select second_dept
      ,cpersonname
	  ,year(fashengrq) as year_
	  ,month(fashengrq) as month_
      ,count(fashengrq) as person_account_unm
      ,sum(md) as md
from 
    (select cpersonname,fashengrq,second_dept,sum(md) as md
    from shujuzu.account_fy_temp02
    group by cpersonname,fashengrq)a
group by cpersonname,year_,month_
;

-- 3. 客户维度
drop table if exists shujuzu.account_fy_customer01;
create temporary table shujuzu.account_fy_customer01 as 
select second_dept
      ,ccuscode
      ,ccusname
	  ,year(fashengrq) as year_
	  ,month(fashengrq) as month_
      ,count(fashengrq) as customer_account_unm
      ,sum(md) as md
from 
    (select second_dept,ccuscode,ccusname,fashengrq,sum(md) as md
    from shujuzu.account_fy_temp02
    group by ccuscode,second_dept,fashengrq)a
group by second_dept,ccuscode,year_,month_
;

alter table shujuzu.account_fy_customer01 add index(ccuscode);

-- 3.1 客户区域匹配
drop table if exists shujuzu.account_fy_customer02;
create temporary table shujuzu.account_fy_customer02 as 
select b.sales_region_new
	  ,b.city
      ,second_dept
      ,ccuscode
      ,ccusname
	  ,year_
	  ,month_
      ,customer_account_unm
      ,md
from shujuzu.account_fy_customer01 a 
left join edw.map_customer b 
on a.ccuscode = b.bi_cuscode
;

-- 4. 招待费
-- 4.1 取业务招待费
drop table if exists shujuzu.account_zd_temp01;
create temporary table shujuzu.account_zd_temp01 as 
SELECT 
     cpersonname
	 ,if(fashengrq is null,dbill_date,fashengrq) as fashengrq
     ,case when b.second_dept is null or b.second_dept = '浙江博圣生物技术股份有限公司' then c.second_dept
           else b.second_dept 
		   end as second_dept
     ,if(ccuscode is null,'请核查',ccuscode) as ccuscode
     ,ccusname
     ,md as zd_md
FROM  pdm.account_fy a
left join edw.ehr_employee b
on a.cpersonname = b.name
left join db_111.ehr_employee c
on a.cpersonname = c.name
where cpersonname is not null and code_name_lv2 = '业务招待费'
;
		  
-- 4.2 过滤部门，只取销售中心、市场中心、技术保障中心
drop table if exists shujuzu.account_zd_temp02;
create temporary table shujuzu.account_zd_temp02 as 
SELECT 
     cpersonname
	 ,year(fashengrq) as year_
	 ,month(fashengrq) as month_
	 ,fashengrq
     ,second_dept
     ,ccuscode
     ,ccusname
     ,zd_md
FROM shujuzu.account_zd_temp01
where second_dept regexp '销售中心|市场中心|技术保障中心' and fashengrq >= '2019-01-01'
;

-- 4.3 汇总得各月各部门各客户的招待费用
drop table if exists shujuzu.account_zd_temp03;
create temporary table shujuzu.account_zd_temp03 as 
select second_dept
      ,ccuscode
      ,ccusname
      ,year_
      ,month_
      ,sum(zd_md) as zd_md
from shujuzu.account_zd_temp02
group by second_dept,ccuscode,year_,month_
;
alter table shujuzu.account_zd_temp03 add index(ccuscode);

drop table if exists shujuzu.account_zd_temp;
create temporary table shujuzu.account_zd_temp as 
select second_dept
      ,b.sales_region_new
	  ,b.city
      ,ccuscode
      ,ccusname
      ,year_
      ,month_
      ,zd_md
from shujuzu.account_zd_temp03 a 
left join edw.map_customer b 
on a.ccuscode = b.bi_cuscode
;


-- 4.4 汇总得每个人每年月的招待费用
drop table if exists shujuzu.account_zd_temp04;
create temporary table shujuzu.account_zd_temp04 as 
select second_dept
      ,cpersonname
      ,year_
      ,month_
      ,sum(zd_md) as zd_md
from shujuzu.account_zd_temp02
group by second_dept,cpersonname,year_,month_
;

drop table if exists shujuzu.account_fy_customer04;
create temporary table shujuzu.account_fy_customer04 as 
select second_dept
      ,sales_region_new
	  ,city
      ,ccuscode
      ,ccusname
	  ,year_
	  ,month_
      ,customer_account_unm
      ,md
	  ,0 as zd_md
from shujuzu.account_fy_customer02 a 
union all
select second_dept
      ,sales_region_new
	  ,city
      ,ccuscode
      ,ccusname
	  ,year_
	  ,month_
      ,0
      ,0
	  ,zd_md
from shujuzu.account_zd_temp
;

alter table  shujuzu.account_fy_customer04 add index(second_dept);
alter table  shujuzu.account_fy_customer04 add index(ccuscode);
alter table  shujuzu.account_fy_customer04 add index(year_);
alter table  shujuzu.account_fy_customer04 add index(month_);


drop table if exists shujuzu.account_fy_customer;
create  table shujuzu.account_fy_customer as 
select second_dept
      ,sales_region_new
	  ,city
      ,ccuscode
      ,ccusname
	  ,year_
	  ,month_
      ,sum(customer_account_unm) as customer_account_unm
      ,sum(md) as md
	  ,sum(zd_md) as zd_md
from shujuzu.account_fy_customer04
group by second_dept,ccuscode,year_,month_
;
alter table  shujuzu.account_fy_customer add index(ccuscode);

--  drop table if exists shujuzu.account_fy_customer06;
--  create temporary table shujuzu.account_fy_customer06 as 
--  select second_dept
--        ,sales_region_new
--        ,ccuscode
--        ,ccusname
--  	  ,b.year_
--  	  ,b.month_
--        ,customer_account_unm
--        ,md
--  	  ,zd_md
--  from shujuzu.account_fy_customer05
--  left join 
--  (select
--  from ufdata.x_calendar
--  where year>=2019 and year<=2020)b
--  on 1=1
--  ;
--  alter table  shujuzu.account_fy_customer06 add index(ccuscode);
--  alter table  shujuzu.account_fy_customer06 add index(year_);
--  alter table  shujuzu.account_fy_customer06 add index(month_);
--  
-- 计算客户每年月收入
drop table if exists shujuzu.cusromer_invoice;
create  table shujuzu.cusromer_invoice as
select finnal_ccuscode as bi_cuscode
       ,finnal_ccusname as bi_cusname
       ,year(ddate) as year_
	   ,month(ddate) as month_
       ,sum(isum) as isum
from pdm.invoice_order
where ddate >= '2019-01-01' and item_code <> 'Jk0101'
group by finnal_ccuscode,year_,month_
;
--  alter table  shujuzu.cusromer_invoice add index(bi_cuscode);
--  alter table  shujuzu.cusromer_invoice add index(year_);
--  alter table  shujuzu.cusromer_invoice add index(month_);
--  
--  drop table if exists shujuzu.account_fy_customer07;
--  create temporary table shujuzu.account_fy_customer07 as 
--  select second_dept
--        ,sales_region_new
--        ,ccuscode
--        ,ccusname
--  	  ,year_
--  	  ,month_
--        ,customer_account_unm
--        ,md
--  	  ,zd_md
--  from shujuzu.account_fy_customer06 a 
--  left join shujuzu.cusromer_invoice b 
--  on a.ccuscode = b.bi_cuscode and a.year_ = b.year_ and a.month_ = b.month_
--  ;

drop table if exists shujuzu.account_fy_person02;
create temporary table shujuzu.account_fy_person02 as 
select second_dept
      ,cpersonname
	  ,year_
	  ,month_
      ,person_account_unm
      ,md
	  ,0 as zd_md
from shujuzu.account_fy_person01
union all 
select second_dept
      ,cpersonname
	  ,year_
	  ,month_
      ,0
	  ,0
      ,zd_md
from shujuzu.account_zd_temp04
;

alter table  shujuzu.account_fy_person02 add index(cpersonname);
alter table  shujuzu.account_fy_person02 add index(year_);
alter table  shujuzu.account_fy_person02 add index(month_);

drop table if exists shujuzu.account_fy_person3;
create  table shujuzu.account_fy_person3 as 
select second_dept
      ,cpersonname
	  ,year_
	  ,month_
      ,sum(person_account_unm) as person_account_unm 
      ,sum(md) as md
	  ,sum(zd_md) as zd_md
from shujuzu.account_fy_person02
group by cpersonname,year_,month_
;

-- 计算客户排名
drop table if exists shujuzu.cusromer_order;
create  table shujuzu.cusromer_order as
select @n:= case when @year=year then @n+1 else 1 end as rownumber
		,bi_cusname
		,bi_cuscode
		,@year:=year as year
		,isum
from (select finnal_ccuscode as bi_cuscode, finnal_ccusname as bi_cusname,year(ddate) as year,sum(isum) as isum
		from pdm.invoice_order
		where ddate >= '2019-01-01' and item_code <> 'Jk0101'
		group by finnal_ccusname,year(ddate)
	  HAVING sum(isum)>0	
		order by year,isum desc)a, (select @n:=1,@year:='')b;

alter table  shujuzu.cusromer_order add index(bi_cuscode);
		
--  drop table if exists shujuzu.account_fy_customer;
--  create  table shujuzu.account_fy_customer as 
--  select second_dept
--        ,sales_region_new
--        ,ccuscode
--        ,ccusname
--  	  ,b.rownumber
--  	  ,year_
--  	  ,month_
--        ,customer_account_unm
--        ,md
--  	  ,zd_md
--  from shujuzu.account_fy_customer05 a 
--  left join shujuzu.cusromer_order b 
--  on a.ccuscode = b.bi_cuscode and a.year_ = b.year
--  ;
-- 人员档案处理
drop table if exists shujuzu.ehr_employee;
create  table shujuzu.ehr_employee as
select name,case when fourth_dept = '销售一部' or fourth_dept = '销售二部' then fifth_dept else fourth_dept end as fourth_dept,entrydate,employeestatus,position_name
from 
(select name,fourth_dept,fifth_dept,entrydate,employeestatus,position_name
from pdm.ehr_employee
order by entrydate desc)a
group by name
;

drop table if exists shujuzu.account_fy_person4;
create  table shujuzu.account_fy_person4 as 
select second_dept
      ,cpersonname
	  ,b.fourth_dept
	  ,b.entrydate
	  ,b.employeestatus
	  ,b.position_name
	  ,year_
	  ,month_
      ,person_account_unm 
      ,md
	  ,zd_md
from shujuzu.account_fy_person3 a 
left join shujuzu.ehr_employee b
on a.cpersonname = b.name
--  left join db_111.ehr_employee c
--  on a.cpersonname = c.name
;
-- 得到无差旅报销的销售人员
drop table if exists shujuzu.person;
create  table shujuzu.person as 
select a.second_dept,name,a.fourth_dept,a.entrydate,a.employeestatus,a.position_name
from 
   (select '销售中心' as second_dept,name,fourth_dept,entrydate,employeestatus,position_name
   from shujuzu.ehr_employee
   where position_name like '临床学术%' or position_name like '销售工程师%')a 
left join shujuzu.account_fy_person4 b 
on b.cpersonname = a.name 
where b.cpersonname is null and a.employeestatus <> '离职'
;
drop table if exists shujuzu.account_fy_person;
create  table shujuzu.account_fy_person as 
select second_dept
      ,cpersonname
	  ,fourth_dept
	  ,entrydate
	  ,TIMESTAMPDIFF(month,entrydate,now()) as diff_month
	  ,employeestatus
	  ,position_name
	  ,year_
	  ,month_
      ,person_account_unm 
      ,md
	  ,zd_md
from shujuzu.account_fy_person4
union 
select second_dept,name,fourth_dept,entrydate,TIMESTAMPDIFF(month,entrydate,now()) as diff_month,employeestatus,position_name,'','',0,0,0
from shujuzu.person

--  drop table if exists shujuzu.ehr_employee;
--  create  table shujuzu.ehr_employee as
--  select name,case when fourth_dept = '销售一部' or fourth_dept = '销售二部' then fifth_dept else fourth_dept end as fourth_dept,entrydate,employeestatus,position_name
--  from 
--  (select name,fourth_dept,fifth_dept,entrydate,employeestatus,position_name
--  from pdm.ehr_employee
--  order by entrydate desc)a
--  group by name
--  ;
--  
--  drop table if exists shujuzu.account_fy_person4;
--  create  table shujuzu.account_fy_person4 as 
--  select second_dept
--        ,cpersonname
--  	  ,b.fourth_dept
--  	  ,b.entrydate
--  	  ,b.employeestatus
--  	  ,b.position_name
--  	  ,year_
--  	  ,month_
--        ,person_account_unm 
--        ,md
--  	  ,zd_md
--  from shujuzu.account_fy_person3 a 
--  left join shujuzu.ehr_employee b
--  on a.cpersonname = b.name
--  --  left join db_111.ehr_employee c
--  --  on a.cpersonname = c.name
--  ;
--  -- 得到无差旅报销的销售人员
--  drop table if exists shujuzu.person;
--  create  table shujuzu.person as 
--  select a.second_dept,name,a.fourth_dept,a.entrydate,a.employeestatus,a.position_name
--  from 
--     (select '销售中心' as second_dept,name,fourth_dept,entrydate,employeestatus,position_name
--     from shujuzu.ehr_employee
--     where position_name like '临床学术%' or position_name like '销售工程师%')a 
--  left join shujuzu.account_fy_person4 b 
--  on b.cpersonname = a.name 
--  where b.cpersonname is null and a.employeestatus <> '离职'
--  ;
--  drop table if exists shujuzu.account_fy_person;
--  create  table shujuzu.account_fy_person as 
--  select second_dept
--        ,cpersonname
--  	  ,fourth_dept
--  	  ,entrydate
--  	  ,TIMESTAMPDIFF(month,entrydate,now()) as diff_month
--  	  ,employeestatus
--  	  ,position_name
--  	  ,year_
--  	  ,month_
--        ,person_account_unm 
--        ,md
--  	  ,zd_md
--  from shujuzu.account_fy_person4
--  union 
--  select second_dept,name,fourth_dept,entrydate,TIMESTAMPDIFF(month,entrydate,now()) as diff_month,employeestatus,position_name,'','',0,0,0
--  from shujuzu.person
