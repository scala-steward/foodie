alter table recipe
    add constraint recipe_pk primary key (user_id, id);

alter table recipe_ingredient
    add constraint recipe_ingredient_pk primary key (user_id, recipe_id, id),
    add constraint recipe_ingredient_user_id_fk foreign key (user_id) references "user" (id) on delete cascade,
    add constraint recipe_ingredient_user_id_recipe_id_fk foreign key (user_id, recipe_id) references recipe (user_id, id) on delete cascade;

alter table meal
    add constraint meal_pk primary key (user_id, id);

alter table meal_entry
    add constraint meal_entry_pk primary key (user_id, meal_id, id),
    add constraint meal_entry_user_id_fk foreign key (user_id) references "user" (id) on delete cascade,
    add constraint meal_entry_user_id_meal_id_fk foreign key (user_id, meal_id) references meal (user_id, id) on delete cascade,
    add constraint meal_entry_user_id_recipe_id_fk foreign key (user_id, recipe_id) references recipe (user_id, id) on delete cascade;

alter table complex_food
    add constraint complex_food_pk primary key (user_id, recipe_id),
    add constraint complex_food_user_id_fk foreign key (user_id) references "user" (id) on delete cascade,
    add constraint complex_food_user_id_recipe_id_fk foreign key (user_id, recipe_id) references recipe (user_id, id) on delete cascade;

alter table complex_ingredient
    add constraint complex_ingredient_pk primary key (user_id, recipe_id, complex_food_id),
    add constraint complex_ingredient_user_id_fk foreign key (user_id) references "user" (id) on delete cascade,
    add constraint complex_ingredient_user_id_recipe_id_fk foreign key (user_id, recipe_id) references recipe (user_id, id) on delete cascade,
    add constraint complex_ingredient_user_id_complex_food_id_fk foreign key (user_id, complex_food_id) references complex_food (user_id, recipe_id) on delete cascade;

alter table reference_map
    add constraint reference_map_pk primary key (user_id, id);

alter table reference_entry
    add constraint reference_entry_pk primary key (user_id, reference_map_id, nutrient_code),
    add constraint reference_entry_user_id_fk foreign key (user_id) references "user" (id) on delete cascade,
    add constraint reference_entry_user_id_reference_map_id_fk foreign key (user_id, reference_map_id) references reference_map (user_id, id) on delete cascade;
