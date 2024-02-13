alter table meal_entry
    add column user_id uuid;

update meal_entry
set user_id = meal.user_id
from meal
where meal.id = meal_entry.meal_id;

alter table meal_entry
    alter column user_id set not null;

alter table recipe_ingredient
    add column user_id uuid;

update recipe_ingredient
set user_id = recipe.user_id
from recipe
where recipe.id = recipe_ingredient.recipe_id;

alter table recipe_ingredient
    alter column user_id set not null;

alter table complex_food
    add column user_id uuid;

update complex_food
set user_id = recipe.user_id
from recipe
where recipe.id = complex_food.recipe_id;

alter table complex_food
    alter column user_id set not null;

alter table complex_ingredient
    add column user_id uuid;

update complex_ingredient
set user_id = complex_food.user_id
from complex_food
where complex_food.recipe_id = complex_ingredient.complex_food_id;

alter table complex_ingredient
    alter column user_id set not null;

alter table reference_entry
    add column user_id uuid;

update reference_entry
set user_id = reference_map.user_id
from reference_map
where reference_map.id = reference_entry.reference_map_id;

alter table reference_entry
    alter column user_id set not null;
