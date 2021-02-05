-- 实际收入处理
-- 20年收入 最终客户是multi的 改为ccuscode 不取健康检测, 不取杭州贝生 分组聚合
drop table if exists test.bonus_biaozhunjia;
create table if not exists test.bonus_biaozhunjia
select 
    case 
		when left(a.db,6) = 'UFDATA' then 'U8'
		else 'xx'
	end as source 
	,a.cohr
    ,a.ddate
	,a.finnal_ccuscode as bi_ccuscode
	,c.bi_cusname
	,case 
		when a.if_xs is null then c.sales_dept
		else '其他'
	end as sales_dept 
    ,case 
		when a.if_xs is null then c.sales_region_new
		else '其他'
	  end as sales_region_new
    ,c.province
    ,a.cinvcode
	,b.bi_cinvname
	,b.item_code 
	,b.level_three
	,b.level_two
	,b.level_one
	,b.equipment
	,b.screen_class
	,b.cinv_key_2020
	,b.cinv_own
	,a.iquantity as iquantity_fapiao
    ,case 
        when a.db = "UFDATA_889_2018" then ifnull(a.iquantity,0)
        when a.itb = "退补" then ifnull(a.tbquantity,0)
        when a.itb = "1" then ifnull(a.tbquantity,0) 
        else ifnull(a.iquantity,0) 
        end as iquantity_adjust
	,a.itaxunitprice
    ,a.isum
	,d.biaozhunjg
    ,case 
        when a.db = "UFDATA_889_2018" then ifnull(a.iquantity,0) * ifnull(d.biaozhunjg,0)
        when a.itb = "退补" then ifnull(a.tbquantity,0) * ifnull(d.biaozhunjg,0)
        when a.itb = "1" then ifnull(a.tbquantity,0) * ifnull(d.biaozhunjg,0)
        else ifnull(a.iquantity,0) * ifnull(d.biaozhunjg,0)
        end as biaozhunjia
	,a.if_xs
from pdm.invoice_order as a 
left join edw.map_inventory as b 
on a.cinvcode = b.bi_cinvcode
left join edw.map_customer as c 
on a.finnal_ccuscode = c.bi_cuscode 
left join (select chanpinbh,biaozhunjg from test.oa_uf_shebeicpqd group by chanpinbh) as d 
on a.cinvcode = d.chanpinbh
where a.item_code != 'JK0101' and year(ddate) = 2020
;

