select distinct chain
from transactions
where chain is not null
order by chain;
