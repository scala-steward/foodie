alter table complex_food
    rename column amount to amount_grams;

alter table complex_food
    add column amount_milli_litres decimal;

update complex_food
    set amount_milli_litres = amount_grams
    where unit = 'ML';

alter table complex_food
    drop column unit;

alter table complex_food
    drop constraint amount_positive,
    add constraint amount_grams_positive check (amount_grams > 0);