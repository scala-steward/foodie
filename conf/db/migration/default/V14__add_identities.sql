create table identity
(
    id   uuid not null,
    name text not null
);

alter table identity
    add constraint identity_pk primary key (id);