create table food_group (
    food_group_id integer not null primary key,
    food_group_code text,
    food_group_name text,
    food_group_name_f text
);

create table food_source (
    food_source_id integer not null primary key,
    food_source_code integer not null,
    food_source_description text,
    food_source_description_f text
);

create table nutrient_source (
    nutrient_source_id integer not null primary key,
    nutrient_source_code integer not null,
    nutrient_source_description text,
    nutrient_source_description_f text
);

create table nutrient_name(
    nutrient_name_id integer not null primary key,
    nutrient_code integer,
    nutrient_symbol text not null,
    nutrient_unit text not null,
    nutrient_name text not null,
    nutrient_name_f text not null,
    tagname text,
    nutrient_decimals integer not null
);

create table nutrient_amount (
    food_id integer not null,
    nutrient_id integer not null references nutrient_name(nutrient_name_id),
    nutrient_value numeric not null,
    standard_error numeric,
    number_of_observation integer,
    nutrient_source_id integer not null references nutrient_source(nutrient_source_id),
    nutrient_date_of_entry date,
    primary key (food_id, nutrient_id, nutrient_source_id)
);

create table food_name (
   food_id integer not null,
   food_code integer not null,
   food_group_id integer not null references food_group(food_group_id),
   food_source_id integer not null references food_source(food_source_id),
   food_description text not null,
   food_description_f text not null,
   food_date_of_entry date not null,
   food_date_of_publication date,
   country_code integer,
   scientific_name text,

   primary key (food_id, food_group_id, food_source_id)
);

create table yield_name (
    yield_id integer not null primary key,
    yield_description text not null,
    yield_description_f text not null
);

create table yield_amount (
    food_id integer not null,
    yield_id integer not null references yield_name(yield_id),
    yield_amount integer not null,
    yield_date_of_entry date not null,
    primary key (food_id, yield_id)
);

create table refuse_name (
    refuse_id integer not null primary key,
    refuse_description text not null,
    refuse_description_f text not null
);

create table refuse_amount (
    food_id integer not null,
    refuse_id integer not null references refuse_name(refuse_id),
    refuse_amount integer not null,
    refuse_date_of_entry date not null,
    primary key (food_id, refuse_id)
);

create table measure_name (
    measure_id integer not null primary key,
    measure_description text not null,
    measure_description_f text not null
);

create table conversion_factor (
    food_id integer not null,
    measure_id integer not null references measure_name(measure_id),
    conversion_factor_value numeric not null,
    conv_factor_date_of_entry date not null,
    primary key (food_id, measure_id)
);

