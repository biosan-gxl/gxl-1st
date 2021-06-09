drop table if exists shujuzu.ar_cvouchid_hx;
create table shujuzu.ar_cvouchid_hx as
SELECT ddate_cut
,mark_hx
,subsidiary
,ar_ap
,cvouchid
,dvouchdate
,ccusname
,bi_ccuscode
,bi_ccusname
,round(idamount,0) as idamount
,round(icamount,0) as icamount
,round(balance_amount,0) as balance_amount
,dvouchdate_ap
,ar_class
,aperiod
,sales_dept
,sales_region
,if_gl
,ADDDATE(dvouchdate, INTERVAL aperiod*30 day) as date_yinghui
,if(b.u8code is not null,'登记为设备回款',null) as huikuanbiaoji
FROM db_111.ar_cvouchid_hx a
left join shujuzu.x_equipment_u8code b
on a.subsidiary = b.db and a.bi_ccuscode = b.cuscode and a.cvouchid = b.U8code
;

select subsidiary,sum(balance_amount)
from shujuzu.ar_cvouchid_hx
where ddate_cut = '2021-04-30'  and bi_ccusname ='湖北省妇幼保健院' and date_yinghui <= '2021-05-31'  and huikuanbiaoji is null
group by subsidiary
