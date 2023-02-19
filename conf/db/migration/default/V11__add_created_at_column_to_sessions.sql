alter table session
    add column created_at date;

update session
    set created_at = now();

alter table session
    alter column created_at set not null;