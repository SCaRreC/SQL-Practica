-- exercise 2. Create code to create the database designed previously.

-- Crear tabla Teachers
create table teachers (
    teacher_id serial primary key not null,
    teacher_name varchar(50) not null,
    surname varchar(50) not null,
    email varchar(100) constraint unique_email unique,
    phone varchar(20),
    dni varchar(20) not null unique  
);

-- Crear tabla Schedules
create table schedules (
    schedule_id serial primary key not null,
    start_date date not null,
    end_date date not null
);

-- Crear tabla Modules
create table modules (
    module_id serial primary key,
    class_name varchar(100) not null,
    teacher_id int,
    schedule_id int,
    foreign key (teacher_id) references teachers(teacher_id),
    foreign key (schedule_id) references schedules(schedule_id)
);
-- Crear tabla payments

create table payments (
    payment_id serial primary key,
    modality varchar(50),
    amount_paid numeric(10,2) not null, 
    payment_date date not null
    
);
-- Crear tabla Bootcamps
create table bootcamps (
    bootcamp_id serial primary key,
    bootcamp_name_edition varchar(100) not null,
    description VARCHAR(100),
    price NUMERIC(10,2),
    schedule_id int, 
    teacher_id int,
    foreign key (schedule_id) references schedules(schedule_id),
    foreign key (teacher_id) references teachers(teacher_id)
);

-- Crear tabla intermedia Modules-Bootcamps
create table boot_mod (
    boot_mod_id serial primary key,
    bootcamp_id int not null,
    module_id int not null,
    foreign key (bootcamp_id) references bootcamps(bootcamp_id),
    foreign key (module_id) references modules(module_id)
);


--Crear tabla students

create table students (
    student_id serial primary key,
    student_name varchar(50) not null,
    surname varchar(50) not null,
    email varchar(100) unique,
    phone varchar(20),
    dni varchar(20) not null,
    bootcamp_id int not null,
    payment_id int not null,
    foreign key (bootcamp_id) references bootcamps(bootcamp_id),
    foreign key (payment_id) references payments(payment_id)
);

-- Crear tabla grades

create table grades (
    grade_id serial primary key,
    student_id int not null,
    module_id int not null,
    grade varchar(10),
    foreign key (student_id) references students(student_id),
    foreign key (module_id) references modules (module_id)
);