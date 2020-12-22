#客户差旅、拜访情况
drop table if exists shujuzu.crmbf_mid0;
create  temporary table shujuzu.crmbf_mid0 as 
select ccusname 
		,statuscode
		,yomifullname 
		,case when new_num='AP191007008' then '2019-10-08'
				when new_num='AP191007009' then '2019-10-09'
				when new_num='AP191007011' then '2019-10-10'	
				when new_num='AP191007012' then '2019-10-11'
				when new_num='AP191013054' then '2019-10-14'
				when new_num='AP191013055' then '2019-10-15'
				else actualstart end as actualstart
		,case when new_num='AP191007008' then '2019-10-08'
				when new_num='AP191007009' then '2019-10-09'
				when new_num='AP191007011' then '2019-10-10'	
				when new_num='AP191007012' then '2019-10-11'
				when new_num='AP191013054' then '2019-10-14'
				when new_num='AP191013055' then '2019-10-15'
				else actualend  end as actualend 
from edw.crm_appointments;
#拜访次数
drop table if exists shujuzu.crmbf_mid1;
create  temporary table shujuzu.crmbf_mid1
select @r:= case when @name=a.name and @bi_cusname=a.bi_cusname and DATEDIFF(s_dt,@e_dt)>1 then @r+1 else @r end as rownum
       ,DATEDIFF(s_dt,@e_dt) as date_diff
      ,@bi_cusname:= a.bi_cusname as bi_cusname
      ,@name:= a.name as name
      ,@e_dt:= a.e_dt as e_dt_old
      ,s_dt
      ,e_dt
  from (select b.bi_cusname ,yomifullname as name, actualstart as s_dt,actualend as e_dt 
        from shujuzu.crmbf_mid0 a
		left join edw.dic_customer b
		on a.ccusname=b.ccusname
		where statuscode = '已完成' and b.bi_cusname is not null order by bi_cusname,name,s_dt) a
,(select @r:=1,@bi_cusname:='',@name:='',@e_dt:='1900-01-01') b
;
drop table if exists shujuzu.crmbf_mid2;
create  temporary table shujuzu.crmbf_mid2 as 
select bi_cusname
		,name
		,y_mon
		,count(*) as bf_num
		,max(bf_day_diff) as max_bf_daydiff
from(select bi_cusname
		,name
		,DATE_FORMAT(min(s_dt),'%Y-%m-01') as y_mon
		,TIMESTAMPDIFF(day,min(s_dt),max(e_dt))+1 as bf_day_diff
		from shujuzu.crmbf_mid1
         group by bi_cusname,name,rownum)a
group by bi_cusname,name,y_mon;

create index index_crmbf_mid2_bi_cusname on shujuzu.crmbf_mid2(bi_cusname);
create index index_crmbf_mid2_name on shujuzu.crmbf_mid2(name);
create index index_crmbf_mid2_s_dt on shujuzu.crmbf_mid2(y_mon);



#差旅次数
drop table if exists shujuzu.crmbf_mid3;
create  temporary table shujuzu.crmbf_mid3 as		
select a.name
       ,a.bi_cusname
	   ,a.y_mon
	   ,count(*) as cl_num
	   ,sum(a.md) as md
	   ,max(a.cl_day_diff) as max_cl_daydiff
from 
(select a.cpersonname as name
		,a.ccusname as bi_cusname
		,DATE_FORMAT(s_dt,'%Y-%m-01') as y_mon
		,TIMESTAMPDIFF(day,s_dt,e_dt)+1 as cl_day_diff
		,sum(a.md) as md
from report.cost_01_account_fy_ccus_person a
group by a.cpersonname,a.ccusname,s_dt)a
GROUP BY bi_cusname,name,y_mon;

create index index_crmbf_mid3_bi_cusname on shujuzu.crmbf_mid3(bi_cusname);
create index index_crmbf_mid3_name on shujuzu.crmbf_mid3(name);
create index index_crmbf_mid3_s_dt on shujuzu.crmbf_mid3(y_mon);

#得到差旅和拜访的合集
drop table if exists shujuzu.crmbf_mid4;
create  temporary table shujuzu.crmbf_mid4 as
select distinct bi_cusname
		,name
		,y_mon
from shujuzu.crmbf_mid2
union
select distinct bi_cusname
		,name
		,y_mon
from shujuzu.crmbf_mid3;

create index index_crmbf_mid4_bi_cusname on shujuzu.crmbf_mid4(bi_cusname);
create index index_crmbf_mid4_name on shujuzu.crmbf_mid4(name);
create index index_crmbf_mid4_s_dt on shujuzu.crmbf_mid4(y_mon);

#得到所有客户人员的差旅拜访次数
drop table if exists shujuzu.crmbf_mid5;
create  temporary table shujuzu.crmbf_mid5 as
select a.bi_cusname,a.name,if(d.second_dept is null or d.second_dept='',d.third_dept,d.second_dept) as second_dept
		,d.position_name,a.y_mon,b.bf_num,b.max_bf_daydiff,c.cl_num,c.md,c.max_cl_daydiff
from shujuzu.crmbf_mid4 a
left join shujuzu.crmbf_mid2 b
on a.bi_cusname=b.bi_cusname and a.name=b.name and a.y_mon=b.y_mon
left join shujuzu.crmbf_mid3 c
on a.bi_cusname=c.bi_cusname and a.name=c.name and a.y_mon=c.y_mon
left join pdm.ehr_employee d
on a.name=d.name;

create index index_crmbf_mid5_bi_cusname on shujuzu.crmbf_mid5(bi_cusname);
create index index_crmbf_mid5_name on shujuzu.crmbf_mid5(name);
create index index_crmbf_mid5_s_dt on shujuzu.crmbf_mid5(y_mon);

#客户第一次发生差旅的日期
drop table if exists shujuzu.bf_clmid6;
create  temporary table shujuzu.bf_clmid6 as
select ccusname as bi_cusname
		,min(s_dt) as cl_min_sdt
		,max(s_dt) as cl_max_sdt
from report.cost_01_account_fy_ccus_person
group by ccusname;

#客户第一次发生拜访的日期
drop table if exists shujuzu.bf_clmid7;
create  temporary table shujuzu.bf_clmid7 as
select  bi_cusname
		,min(s_dt) as bf_min_sdt
		,max(s_dt) as bf_max_sdt
from shujuzu.crmbf_mid1
group by bi_cusname; 

drop table if exists shujuzu.bf_clmid8;
create  temporary table shujuzu.bf_clmid8 as
select a.bi_cusname
		,a.name
		,a.second_dept
		,a.position_name
		,a.y_mon
		,a.bf_num
		,a.max_bf_daydiff
		,c.bf_min_sdt
		,c.bf_max_sdt
		,a.cl_num
		,a.md
		,a.max_cl_daydiff
		,b.cl_min_sdt
		,b.cl_max_sdt
		
from shujuzu.crmbf_mid5 a
left join shujuzu.bf_clmid6 b
on a.bi_cusname=b.bi_cusname 
left join shujuzu.bf_clmid7 c
on a.bi_cusname=c.bi_cusname;

create index index_crmbf_mid8_bi_cusname on shujuzu.bf_clmid8(bi_cusname);
create index index_crmbf_mid8_name on shujuzu.bf_clmid8(name);
create index index_crmbf_mid8_s_dt on shujuzu.bf_clmid8(y_mon); 



#计算客户当年的收入和当年的收入排名
drop table if exists shujuzu.bfclmid9;
create  temporary table shujuzu.bfclmid9 as
select @n:= case when @year=year then @n+1 else 1 end as rownumber
		,bi_cusname
		,@year:=year as year
		,isum
from (select finnal_ccusname as bi_cusname,year(ddate) as year,sum(isum) as isum
		from pdm.invoice_order
		where cohr<>'杭州贝生'
		group by finnal_ccusname,year(ddate)
	  HAVING sum(isum)>0	
		order by year,isum desc)a, (select @n:=1,@year:='')b;

create index index_bfclmid9_bi_cusname on shujuzu.bfclmid9(bi_cusname);
create index index_bfclmid9_year on shujuzu.bfclmid9(year);


drop table if exists shujuzu.bf_clmid10;
create  temporary table shujuzu.bf_clmid10 as
select a.bi_cusname
		,a.name
		,a.second_dept
		,a.position_name
		,a.y_mon
		,a.bf_num
		,a.max_bf_daydiff
		,a.bf_min_sdt
		,a.bf_max_sdt
		,a.cl_num
		,a.md
		,a.max_cl_daydiff
		,a.cl_min_sdt
		,a.cl_max_sdt
		,b.rownumber as invoice_num
from shujuzu.bf_clmid8 a
left join shujuzu.bfclmid9 b
on a.bi_cusname=b.bi_cusname and year(a.y_mon)=b.year;

create index index_crmbf_mid10_bi_cusname on shujuzu.bf_clmid10(bi_cusname);
create index index_crmbf_mid10_name on shujuzu.bf_clmid10(name);
create index index_crmbf_mid10_s_dt on shujuzu.bf_clmid10(y_mon); 


#新客户新项目清单
drop table if exists shujuzu.new_cusitem_person01;
create TEMPORARY table shujuzu.new_cusitem_person01 as 
SELECT a.ccusname,a.mark_2,if(b.ccusname is not null,'计划内','计划外') as act_plan,b.ddate as plan_ddate,if(c.ccusname is not null,'已完成','') as act,c.ddate
from (SELECT DISTINCT ccusname,mark_2
      from report.kpi_02_newcus_base_person)a
LEFT JOIN (SELECT ccusname,ddate
      from report.kpi_02_newcus_base_person
			WHERE mark_1='plan' 
		  GROUP BY ccusname)b
	on a.ccusname=b.ccusname
LEFT JOIN (SELECT ccusname,ddate
      from report.kpi_02_newcus_base_person
			WHERE mark_1='act'
			GROUP BY ccusname)c
			on  a.ccusname=c.ccusname;
create index index_new_cusitem_person01_ccusname on shujuzu.new_cusitem_person01(ccusname);

drop table if exists shujuzu.cust_travel_visit;
create  table shujuzu.cust_travel_visit as
select a.bi_cusname
		,a.name
		,a.second_dept
		,a.position_name
		,a.y_mon
		,a.bf_num
		,a.max_bf_daydiff
		,DATE_FORMAT(a.bf_min_sdt,'%Y-%m-%d') as bf_min_sdt
		,DATE_FORMAT(a.bf_max_sdt,'%Y-%m-%d') as bf_max_sdt
		,a.cl_num
		,a.md
		,a.max_cl_daydiff
		,DATE_FORMAT(a.cl_min_sdt,'%Y-%m-%d') as cl_min_sdt
		,DATE_FORMAT(a.cl_max_sdt,'%Y-%m-%d') as cl_max_sdt
		,a.invoice_num
		,c.year1_isum
		,b.act_plan
		,b.plan_ddate
		,b.mark_2
		,b.act
		,b.ddate as act_ddate
from shujuzu.bf_clmid10 a
left join shujuzu.new_cusitem_person01 b
on a.bi_cusname=b.ccusname 
left join (select finnal_ccusname as bi_cusname,sum(isum) as year1_isum
		from pdm.invoice_order
		where cohr<>'杭州贝生' and TIMESTAMPDIFF(month,ddate,now())<=12
		group by finnal_ccusname)c
on a.bi_cusname=c.bi_cusname;

#插入没有拜访和差旅的新客户
INSERT INTO shujuzu.cust_travel_visit (bi_cusname,act_plan,mark_2)
select b.ccusname,'计划内' as act_plan,'newcus' as mark_2
from (select DISTINCT b.bi_cusname 
        from edw.crm_appointments a
		left join edw.dic_customer b
		on a.ccusname=b.ccusname
		where statuscode = '已完成' and b.bi_cusname is not null
		union
		SELECT DISTINCT ccusname
		from report.cost_01_account_fy_ccus_person) a
RIGHT join (select DISTINCT ccusname
from report.kpi_02_newcus_base_person)b
on a.bi_cusname=b.ccusname
where a.bi_cusname is null;
#更新新插入的没有拜访和差旅客户的计划日期
UPDATE shujuzu.cust_travel_visit a
LEFT JOIN report.kpi_02_newcus_base_person b
ON a.bi_cusname=b.ccusname
SET a.plan_ddate = b.ddate
WHERE a.act_plan='计划内' and a.plan_ddate is null;

UPDATE shujuzu.cust_travel_visit set second_dept='技术保障中心' WHERE second_dept='技术保障部';
UPDATE shujuzu.cust_travel_visit set second_dept='销售中心' WHERE second_dept='销售部';
UPDATE shujuzu.cust_travel_visit set second_dept='市场中心' WHERE second_dept='市场部';
UPDATE test.cust_travel_visit set second_dept='技术保障中心' WHERE second_dept='技术保障中心（原）';


#因架构调整，临床学术的二级部门变成了浙江博圣生物股份，对统计销售中心的拜访次数有影响
update test.cust_travel_visit set second_dept='销售中心' where position_name like '临床学术%';

