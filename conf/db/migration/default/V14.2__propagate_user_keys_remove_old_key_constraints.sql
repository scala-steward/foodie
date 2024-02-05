-- We remove all key related constraints bottom up.
-- The current structure is as follows (reduced to the relevant part):
--   complex_food -> recipe
--   complex_ingredient -> complex_food, recipe
--   meal_entry -> meal, recipe
--   recipe -> user
--   reference_entry -> reference_map
alter table complex_ingredient
    drop constraint complex_ingredient_recipe_id_fk,
    drop constraint complex_ingredient_complex_food_id_fk,
    drop constraint complex_ingredient_pk;

alter table complex_food
    drop constraint complex_food_recipe_id_fk,
    drop constraint complex_food_pk;

alter table meal_entry
    drop constraint meal_entry_recipe_id_fk,
    drop constraint meal_entry_pk,
    drop constraint meal_entry_meal_id_fk;

alter table recipe_ingredient
    drop constraint recipe_ingredient_pk,
    drop constraint recipe_ingredient_recipe_id_fk;

alter table reference_entry
    drop constraint reference_entry_pk,
    drop constraint reference_entry_reference_map_id_fk;

alter table meal
    drop constraint meal_pk;

alter table recipe
    drop constraint recipe_pk;

alter table reference_map
    drop constraint reference_map_pk;
