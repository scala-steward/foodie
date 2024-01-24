create table profile
(
    id      uuid not null,
    user_id uuid not null,
    name    text not null
);

alter table profile
    add constraint profile_pk primary key (id),
    add constraint profile_user_id_fk foreign key (user_id) references "user" (id);

alter table meal
    add column profile_id uuid;

alter table meal
    add constraint meal_profile_id_fk foreign key (profile_id) references profile (id);

-- Create a default profile for each user with the same name as their nickname.
insert into profile (id, user_id, name)
select distinct on (id) uuid_generate_v4(), id, nickname
from "user";