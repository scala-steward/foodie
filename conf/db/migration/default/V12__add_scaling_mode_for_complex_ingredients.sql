alter table complex_ingredients
    add column scaling_mode text;

update complex_ingredient
    set scaling_mode = 'Recipe';

alter table complex_ingredients
    alter column scaling_mode set not null;

alter table complex_ingredients
    add constraint scaling_mode_enumeration check (scaling_mode = 'Recipe' or scaling_mode = 'Weight' or scaling_mode = 'Volume');