alter table complex_food
    add constraint volume_positive check (amount_milli_litres is null or amount_milli_litres > 0);