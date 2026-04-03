-- File: 05_distinct_chain_values.sql
select distinct chain
from transactions
where chain is not null
order by chain;
