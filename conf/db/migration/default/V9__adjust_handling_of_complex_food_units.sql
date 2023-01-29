alter table complex_food
    rename column amount to amount_grams;

alter table complex_food
    add column amount_milli_litres decimal;

update complex_food
    set amount_grams = amount where unit = 'G';

update complex_food
    set amount_milli_litres = amount where unit = 'ML';

alter table complex_food
    drop column unit;
