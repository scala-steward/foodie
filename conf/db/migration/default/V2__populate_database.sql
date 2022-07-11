copy cnf.food_group
from '../../cnf/FOOD GROUP.csv' delimiter ',' csv header;

copy cnf.food_source(food_source_id, food_source_code, food_source_description, food_source_description_f)
from '../../cnf/FOOD SOURCE.csv' delimiter ',' csv header;

copy cnf.nutrient_source
from '../../cnf/NUTRIENT SOURCE.csv' delimiter ',' csv header;

copy cnf.nutrient_name
from '../../cnf/NUTRIENT NAME.csv' delimiter ',' csv header;

copy cnf.nutrient_amount
from '../../cnf/NUTRIENT AMOUNT.csv' delimiter ',' csv header;

copy cnf.food_name
from '../../cnf/FOOD NAME.csv' delimiter ',' csv header;

copy cnf.yield_name
from '../../cnf/YIELD NAME.csv' delimiter ',' csv header;

copy cnf.yield_amount(food_id, yield_id, yield_amount, yield_date_of_entry)
from '../../cnf/YIELD AMOUNT.csv' delimiter ',' csv header;

copy cnf.refuse_name
from '../../cnf/REFUSE NAME.csv' delimiter ',' csv header;

copy cnf.refuse_amount
from '../../cnf/REFUSE AMOUNT.csv' delimiter ',' csv header;

copy cnf.measure_name(measure_id, measure_description, measure_description_f)
from '../../cnf/MEASURE NAME.csv' delimiter ',' csv header;

copy cnf.conversion_factor
from '../../cnf/CONVERSION FACTOR.csv' delimiter ',' csv header;
