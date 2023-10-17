-- Tính Recency, Frequency, Monetary xog dựa vào đó tính điểm R, F, M rồi ghép thành điểm RFM
create table Customer_RFM_Statistics (
with customer_statistics as (
Select customerid,
       abs(datediff(max(STR_TO_DATE(Purchase_Date,'%m/%d/%Y')),'2022-09-01')) as recency,
       coalesce(round((count(distinct(STR_TO_DATE(Purchase_Date,'%m/%d/%Y')))) /
             (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),2),0) as frequency,
       coalesce(round((sum(GMV))/
             (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),0),0) as monetary,
       (row_number() over (order by abs(datediff(max(STR_TO_DATE(Purchase_Date,'%m/%d/%Y')),'2022-09-01')))) as rn_recency,
       (row_number() over (order by coalesce(round((count(distinct(STR_TO_DATE(Purchase_Date,'%m/%d/%Y')))) /
             (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),2),0))) as rn_frequency,
       (row_number() over (order by coalesce(round((sum(GMV)) /
             (round(abs(datediff(max(cast(created_date as date)),'2022-09-01'))/365,0)),0),0))) as rn_monetary
from customer_transaction CT
join customer_registered CR on CT.CustomerID = CR.ID
where customerid <> 0 and stopdate is null
group by customerid),
RFM_MAPPING as (
select * , case
    when recency <= ((select recency from customer_statistics
                                    where rn_recency = ((select count(distinct(customerid))*0.25 from customer_statistics))))
        and recency >= (select recency from customer_statistics where rn_recency = 1) then '4'
    when recency <= ((select recency from customer_statistics
                                    where rn_recency = ((select count(distinct(customerid))*0.5 from customer_statistics))))
        and recency > ((select recency from customer_statistics
                                    where rn_recency = ((select count(distinct(customerid))*0.25 from customer_statistics)))) then '3'
    when recency <= ((select recency from customer_statistics
                                    where rn_recency = ((select count(distinct(customerid))*0.75 from customer_statistics))))
        and recency > ((select recency from customer_statistics
                                    where rn_recency = ((select count(distinct(customerid))*0.5 from customer_statistics)))) then '2'
else '1' end as R ,
case
    when frequency <= ((select frequency from customer_statistics
                                    where rn_frequency = ((select count(distinct(customerid))*0.25 from customer_statistics))))
        and frequency >= (select frequency from customer_statistics where rn_frequency = 1) then '1'
    when frequency <= ((select frequency from customer_statistics
                                    where rn_frequency = ((select count(distinct(customerid))*0.5 from customer_statistics))))
        and frequency > ((select frequency from customer_statistics
                                    where rn_frequency = ((select count(distinct(customerid))*0.25 from customer_statistics)))) then '2'
    when frequency <= ((select frequency from customer_statistics
                                    where rn_frequency = ((select count(distinct(customerid))*0.75 from customer_statistics))))
        and frequency > ((select frequency from customer_statistics
                                    where rn_frequency = ((select count(distinct(customerid))*0.5 from customer_statistics)))) then '3'
else '4' end as F,
case
    when monetary <= ((select monetary from customer_statistics
                                    where rn_monetary = ((select count(distinct(customerid))*0.25 from customer_statistics))))
        and monetary >= (select monetary from customer_statistics where rn_monetary = 1) then '1'
    when monetary <= ((select monetary from customer_statistics
                                    where rn_monetary = ((select count(distinct(customerid))*0.5 from customer_statistics))))
        and monetary > ((select monetary from customer_statistics
                                    where rn_monetary = ((select count(distinct(customerid))*0.25 from customer_statistics)))) then '2'
    when monetary <= ((select monetary from customer_statistics
                                    where rn_monetary = ((select count(distinct(customerid))*0.75 from customer_statistics))))
        and monetary > ((select monetary from customer_statistics
                                    where rn_monetary = ((select count(distinct(customerid))*0.5 from customer_statistics)))) then '3'
else '4' end as M
from customer_statistics )
select CustomerID,recency,frequency,monetary,R,F,M, concat(R,F,M) as RFM, '2022-09-01' as Date
from RFM_Mapping)

-- Dựa vào điểm RFM chia thành 4 nhóm khách hàng
create table Customer_Statistics (
select * from (
select * , case
            when RFM like ('_44') or RFM like ('_43') or RFM like ('_34') or RFM like ('_33') then 'VIP'
            when RFM like ('_32') or RFM like ('_42') or RFM like ('_41') or RFM like ('_31') then 'Cash cow'
            when RFM like ('_23') or RFM like ('_24') or RFM like ('_13') then 'Question Mark'
else 'Dog' end as Customer_Segmentation
from customer_rfm_statistics) A)