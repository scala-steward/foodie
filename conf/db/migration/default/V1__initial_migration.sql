create schema cnf;

create table cnf.food_group (
    food_group_id integer not null,
    food_group_code text,
    food_group_name text,
    food_group_name_f text
);

alter table cnf.food_group
    add constraint food_group_pk primary key (food_group_id);

create table cnf.food_source (
    food_source_id integer not null,
    food_source_code integer not null,
    food_source_description text,
    food_source_description_f text
);

alter table cnf.food_source
    add constraint food_source_pk primary key(food_source_id);

create table cnf.nutrient_source (
    nutrient_source_id integer not null,
    nutrient_source_code integer not null,
    nutrient_source_description text,
    nutrient_source_description_f text
);

alter table cnf.nutrient_source
    add constraint nutrient_source_pk primary key (nutrient_source_id);

create table cnf.nutrient_name(
    nutrient_name_id integer not null,
    nutrient_code integer not null,
    nutrient_symbol text not null,
    nutrient_unit text not null,
    nutrient_name text not null,
    nutrient_name_f text not null,
    tagname text,
    nutrient_decimals integer not null
);

alter table cnf.nutrient_name
    add constraint nutrient_name_pk primary key (nutrient_code);

create table cnf.nutrient_amount (
    food_id integer not null,
    nutrient_id integer not null, -- references either nutrient_name(nutrient_name_id) or nutrient_name(nutrient_code)
    nutrient_value numeric not null,
    standard_error numeric,
    number_of_observation integer,
    nutrient_source_id integer not null ,
    nutrient_date_of_entry date
);

alter table cnf.nutrient_amount
    add constraint nutrient_amount_pk primary key (food_id, nutrient_id, nutrient_source_id),
    add constraint nutrient_amount_nutrient_source_id_fk foreign key (nutrient_source_id) references cnf.nutrient_source(nutrient_source_id);

create table cnf.food_name (
   food_id integer unique not null,
   food_code integer not null,
   food_group_id integer not null ,
   food_source_id integer not null, -- should reference food_source(food_source_id), but at least one value is missing.
   food_description text not null,
   food_description_f text not null,
   food_date_of_entry date not null,
   food_date_of_publication date,
   country_code integer,
   scientific_name text
);

alter table cnf.food_name
    add constraint food_name_pk primary key (food_id, food_group_id, food_source_id),
    add constraint food_name_food_group_id_fk foreign key (food_group_id) references cnf.food_group(food_group_id);

create table cnf.yield_name (
    yield_id integer not null ,
    yield_description text not null,
    yield_description_f text not null
);

alter table cnf.yield_name
    add constraint yield_name_pk primary key (yield_id);

create table cnf.yield_amount (
    food_id integer not null,
    yield_id integer not null,
    yield_amount integer not null,
    yield_date_of_entry date not null
);

alter table cnf.yield_amount
    add constraint yield_amount_pk primary key (food_id, yield_id),
    add constraint yield_amount_yield_id_fk foreign key (yield_id) references cnf.yield_name(yield_id);

create table cnf.refuse_name (
    refuse_id integer not null,
    refuse_description text not null,
    refuse_description_f text not null
);

alter table cnf.refuse_name
    add constraint refuse_name_pk primary key (refuse_id);

create table cnf.refuse_amount (
    food_id integer not null,
    refuse_id integer not null ,
    refuse_amount integer not null,
    refuse_date_of_entry date not null
);

alter table cnf.refuse_amount
    add constraint refuse_amount_pk primary key (food_id, refuse_id),
    add constraint refuse_amount_refuse_id_fk foreign key (refuse_id) references cnf.refuse_name(refuse_id);

create table cnf.measure_name (
    measure_id integer not null,
    measure_description text not null,
    measure_description_f text not null
);

alter table cnf.measure_name
    add constraint measure_name_pk primary key (measure_id);

create table cnf.conversion_factor (
    food_id integer not null,
    measure_id integer not null, -- should reference measure_name(measure_id), but at least one value is missing
    conversion_factor_value numeric not null,
    conv_factor_date_of_entry date not null
);

alter table cnf.conversion_factor
    add constraint conversion_factor_pk primary key (food_id, measure_id);

create table "user"(
    id uuid not null,
    nickname text not null,
    display_name text,
    email text not null,
    salt text not null,
    hash text not null
);

alter table "user"
    add constraint user_pk primary key (id);

create table recipe(
    id uuid not null,
    user_id uuid not null,
    name text not null,
    description text
);

alter table recipe
    add constraint recipe_pk primary key (id),
    add constraint recipe_user_id_fk foreign key (user_id) references "user"(id);

create table recipe_ingredient(
    id uuid not null,
    recipe_id uuid not null,
    food_name_id integer not null,
    amount decimal not null
);

alter table recipe_ingredient
    add constraint recipe_ingredient_pk primary key (id),
    add constraint recipe_ingredient_recipe_id_fk foreign key (recipe_id) references recipe(id),
    add constraint recipe_ingredient_food_name_id_fk foreign key (food_name_id) references cnf.food_name(food_id);

create table meal_plan_entry(
  id uuid not null,
  user_id uuid not null,
  consumed_on timestamp not null,
  amount decimal not null
);

alter table meal_plan_entry
    add constraint meal_plan_entry_pk primary key (id),
    add constraint meal_plan_entry_user_id_fk foreign key (user_id) references "user"(id),
    add constraint meal_plan_entry_amount_positive check (amount > 0);
