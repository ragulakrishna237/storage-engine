--
-- PostgreSQL database dump
--

\restrict abgoCXZlKFhGJZzo0ZCXjHtbb9UqPRgsM7SaVzy5MGb9yQtnfkNH8tMeuWherLZ

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.0

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: advisors; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.advisors (
    advisor_id integer NOT NULL,
    advisor_name character varying(100),
    advisor_office character varying(20),
    advisor_phone character varying(20),
    dept_name character varying(80)
);


ALTER TABLE public.advisors OWNER TO postgres;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.courses (
    course_id character varying(10) NOT NULL,
    course_name character varying(150),
    credits integer,
    dept_id character varying(10)
);


ALTER TABLE public.courses OWNER TO postgres;

--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.enrollments (
    student_id integer NOT NULL,
    course_id character varying(10) NOT NULL,
    student_name character varying(100),
    student_email character varying(150),
    student_major character varying(80),
    course_name character varying(150),
    course_credits integer,
    dept_name character varying(80),
    grade character(2),
    enrollment_date date
);


ALTER TABLE public.enrollments OWNER TO postgres;

--
-- Name: prerequisites; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prerequisites (
    student_id integer NOT NULL,
    course_id character varying(10) NOT NULL,
    prereq_id character varying(10) NOT NULL
);


ALTER TABLE public.prerequisites OWNER TO postgres;

--
-- Name: student_info; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_info (
    student_id integer NOT NULL,
    student_name character varying(100),
    gpa numeric(3,2),
    major character varying(80),
    advisor_id integer,
    advisor_name character varying(100),
    advisor_office character varying(20),
    advisor_phone character varying(20),
    dept_name character varying(80),
    dept_building character varying(80)
);


ALTER TABLE public.student_info OWNER TO postgres;

--
-- Name: student_profiles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student_profiles (
    student_id integer NOT NULL,
    language character varying(50) NOT NULL,
    activity character varying(80) NOT NULL
);


ALTER TABLE public.student_profiles OWNER TO postgres;

--
-- Name: students; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.students (
    student_id integer,
    student_name character varying(100),
    phone_numbers character varying(200),
    enrolled_courses character varying(300),
    grades character varying(200)
);


ALTER TABLE public.students OWNER TO postgres;

--
-- Name: teaching_schedule; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.teaching_schedule (
    course_id character varying(10) NOT NULL,
    instructor_id integer NOT NULL,
    dept_id character varying(10),
    semester character varying(20),
    room character varying(15),
    time_slot character varying(30)
);


ALTER TABLE public.teaching_schedule OWNER TO postgres;

--
-- Data for Name: advisors; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.advisors VALUES
	(101, 'Dr. Patricia Moore', 'SCI-201', '555-9101', 'Computer Science'),
	(102, 'Dr. Richard Stone', 'SCI-305', '555-9102', 'Physics'),
	(103, 'Prof. Sandra Hill', 'MATH-110', '555-9103', 'Mathematics'),
	(104, 'Dr. Thomas Reed', 'HUM-204', '555-9104', 'English'),
	(105, 'Dr. Nancy Young', 'SCI-410', '555-9105', 'Biology'),
	(106, 'Prof. George Clark', 'HUM-310', '555-9106', 'History');


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.courses VALUES
	('CS101', 'Intro to Programming', 3, 'CS'),
	('CS201', 'Data Structures', 3, 'CS'),
	('CS301', 'Algorithms', 3, 'CS'),
	('MATH201', 'Calculus II', 4, 'MATH'),
	('MATH301', 'Linear Algebra', 3, 'MATH'),
	('PHYS101', 'General Physics I', 4, 'PHYS'),
	('PHYS201', 'General Physics II', 4, 'PHYS'),
	('BIO101', 'Intro to Biology', 3, 'BIO'),
	('BIO201', 'Cell Biology', 3, 'BIO'),
	('CHEM101', 'General Chemistry I', 4, 'CHEM'),
	('ENG110', 'Academic Writing', 3, 'ENG'),
	('HIST101', 'World History I', 3, 'HIST'),
	('HIST201', 'World History II', 3, 'HIST'),
	('PSYC101', 'Intro to Psychology', 3, 'PSYC'),
	('SOC101', 'Intro to Sociology', 3, 'SOC');


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.enrollments VALUES
	(1, 'CS101', 'Alice Johnson', 'alice@uni.edu', 'Computer Science', 'Intro to Programming', 3, 'Computer Science', 'A ', '2024-09-03'),
	(1, 'MATH201', 'Alice Johnson', 'alice@uni.edu', 'Computer Science', 'Calculus II', 4, 'Mathematics', 'B+', '2024-09-03'),
	(1, 'ENG110', 'Alice Johnson', 'alice@uni.edu', 'Computer Science', 'Academic Writing', 3, 'English', 'A-', '2024-09-03'),
	(2, 'CS101', 'Bob Martinez', 'bob@uni.edu', 'Physics', 'Intro to Programming', 3, 'Computer Science', 'B ', '2024-09-03'),
	(2, 'PHYS101', 'Bob Martinez', 'bob@uni.edu', 'Physics', 'General Physics I', 4, 'Physics', 'A ', '2024-09-03'),
	(2, 'CS201', 'Bob Martinez', 'bob@uni.edu', 'Physics', 'Data Structures', 3, 'Computer Science', 'B+', '2024-09-04'),
	(3, 'MATH201', 'Carol Lee', 'carol@uni.edu', 'Mathematics', 'Calculus II', 4, 'Mathematics', 'A ', '2024-09-03'),
	(3, 'CHEM101', 'Carol Lee', 'carol@uni.edu', 'Mathematics', 'General Chemistry I', 4, 'Chemistry', 'A-', '2024-09-03'),
	(4, 'CS201', 'David Kim', 'david@uni.edu', 'Computer Science', 'Data Structures', 3, 'Computer Science', 'B+', '2024-09-03'),
	(4, 'CS301', 'David Kim', 'david@uni.edu', 'Computer Science', 'Algorithms', 3, 'Computer Science', 'A ', '2024-09-03'),
	(5, 'ENG110', 'Emma Wilson', 'emma@uni.edu', 'English', 'Academic Writing', 3, 'English', 'A ', '2024-09-03'),
	(5, 'HIST101', 'Emma Wilson', 'emma@uni.edu', 'English', 'World History I', 3, 'History', 'B+', '2024-09-03'),
	(6, 'PHYS101', 'Frank Brown', 'frank@uni.edu', 'Physics', 'General Physics I', 4, 'Physics', 'B ', '2024-09-04'),
	(6, 'PHYS201', 'Frank Brown', 'frank@uni.edu', 'Physics', 'General Physics II', 4, 'Physics', 'B+', '2024-09-04'),
	(7, 'BIO101', 'Grace Davis', 'grace@uni.edu', 'Biology', 'Intro to Biology', 3, 'Biology', 'A ', '2024-09-03'),
	(7, 'CHEM101', 'Grace Davis', 'grace@uni.edu', 'Biology', 'General Chemistry I', 4, 'Chemistry', 'A ', '2024-09-03'),
	(8, 'HIST101', 'Henry White', 'henry@uni.edu', 'History', 'World History I', 3, 'History', 'B+', '2024-09-03'),
	(9, 'CS101', 'Iris Taylor', 'iris@uni.edu', 'Computer Science', 'Intro to Programming', 3, 'Computer Science', 'A ', '2024-09-03'),
	(9, 'CS201', 'Iris Taylor', 'iris@uni.edu', 'Computer Science', 'Data Structures', 3, 'Computer Science', 'A-', '2024-09-03'),
	(10, 'MATH301', 'James Anderson', 'james@uni.edu', 'Mathematics', 'Linear Algebra', 3, 'Mathematics', 'B ', '2024-09-03');


--
-- Data for Name: prerequisites; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.prerequisites VALUES
	(1, 'CS201', 'CS101'),
	(1, 'CS301', 'CS201'),
	(2, 'CS201', 'CS101'),
	(2, 'PHYS201', 'PHYS101'),
	(3, 'MATH301', 'MATH201'),
	(4, 'CS301', 'CS201'),
	(4, 'CS301', 'MATH201'),
	(4, 'MATH301', 'MATH201'),
	(6, 'PHYS201', 'PHYS101'),
	(7, 'BIO201', 'BIO101'),
	(7, 'BIO201', 'CHEM101'),
	(8, 'HIST201', 'HIST101'),
	(9, 'CS201', 'CS101'),
	(9, 'CS301', 'CS201');


--
-- Data for Name: student_info; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.student_info VALUES
	(1, 'Alice Johnson', 3.85, 'Computer Science', 101, 'Dr. Patricia Moore', 'SCI-201', '555-9101', 'Computer Science', 'Science Hall'),
	(2, 'Bob Martinez', 3.40, 'Physics', 102, 'Dr. Richard Stone', 'SCI-305', '555-9102', 'Physics', 'Science Hall'),
	(3, 'Carol Lee', 3.95, 'Mathematics', 103, 'Prof. Sandra Hill', 'MATH-110', '555-9103', 'Mathematics', 'Math Building'),
	(4, 'David Kim', 3.70, 'Computer Science', 101, 'Dr. Patricia Moore', 'SCI-201', '555-9101', 'Computer Science', 'Science Hall'),
	(5, 'Emma Wilson', 3.60, 'English', 104, 'Dr. Thomas Reed', 'HUM-204', '555-9104', 'English', 'Humanities Hall'),
	(6, 'Frank Brown', 3.20, 'Physics', 102, 'Dr. Richard Stone', 'SCI-305', '555-9102', 'Physics', 'Science Hall'),
	(7, 'Grace Davis', 3.90, 'Biology', 105, 'Dr. Nancy Young', 'SCI-410', '555-9105', 'Biology', 'Science Hall'),
	(8, 'Henry White', 3.10, 'History', 106, 'Prof. George Clark', 'HUM-310', '555-9106', 'History', 'Humanities Hall'),
	(9, 'Iris Taylor', 3.80, 'Computer Science', 101, 'Dr. Patricia Moore', 'SCI-201', '555-9101', 'Computer Science', 'Science Hall'),
	(10, 'James Anderson', 3.55, 'Mathematics', 103, 'Prof. Sandra Hill', 'MATH-110', '555-9103', 'Mathematics', 'Math Building'),
	(11, 'Karen Lewis', 3.45, 'Biology', 105, 'Dr. Nancy Young', 'SCI-410', '555-9105', 'Biology', 'Science Hall'),
	(12, 'Leo Walker', 3.30, 'History', 106, 'Prof. George Clark', 'HUM-310', '555-9106', 'History', 'Humanities Hall');


--
-- Data for Name: student_profiles; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.student_profiles VALUES
	(1, 'English', 'Chess Club'),
	(1, 'English', 'Debate Team'),
	(1, 'French', 'Chess Club'),
	(1, 'French', 'Debate Team'),
	(2, 'English', 'Soccer Team'),
	(2, 'English', 'Basketball Team'),
	(2, 'Spanish', 'Soccer Team'),
	(2, 'Spanish', 'Basketball Team'),
	(3, 'English', 'Math Club'),
	(3, 'English', 'Science Bowl'),
	(4, 'English', 'Robotics Club'),
	(4, 'Korean', 'Robotics Club'),
	(4, 'Mandarin', 'Robotics Club'),
	(5, 'English', 'Drama Club'),
	(5, 'English', 'Choir'),
	(5, 'English', 'Art Club'),
	(5, 'French', 'Drama Club'),
	(5, 'French', 'Choir'),
	(5, 'French', 'Art Club'),
	(6, 'English', 'Swimming Team'),
	(6, 'English', 'Track Team'),
	(7, 'English', 'Science Bowl'),
	(7, 'English', 'Biology Club'),
	(7, 'Mandarin', 'Science Bowl'),
	(7, 'Mandarin', 'Biology Club');


--
-- Data for Name: students; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.students VALUES
	(1, 'Alice Johnson', '555-1001, 555-1002', 'CS101, MATH201, ENG110', 'A, B+, A-'),
	(2, 'Bob Martinez', '555-2001', 'CS101, PHYS101, CS201', 'B, A, B+'),
	(3, 'Carol Lee', '555-3001, 555-3002, 555-3003', 'MATH201, CHEM101, BIO101', 'A, A-, B'),
	(4, 'David Kim', '555-4001, 555-4002', 'CS201, CS301, MATH301', 'B+, A, A-'),
	(5, 'Emma Wilson', '555-5001', 'ENG110, HIST101, PSYC101', 'A, B+, A'),
	(6, 'Frank Brown', '555-6001, 555-6002', 'PHYS101, PHYS201, MATH201, CS101', 'B, B+, A-, A'),
	(7, 'Grace Davis', '555-7001', 'BIO101, CHEM101, PSYC101', 'A, A, B+'),
	(8, 'Henry White', '555-8001, 555-8002', 'HIST101, ENG110, SOC101', 'B+, A, B'),
	(9, 'Iris Taylor', '555-9001', 'CS101, CS201', 'A, A-'),
	(10, 'James Anderson', '555-1010, 555-1011', 'MATH301, PHYS201, CS301', 'B, A-, B+');


--
-- Data for Name: teaching_schedule; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.teaching_schedule VALUES
	('CS101', 201, 'CS', 'Fall2024', 'SCI-101', 'MWF 09:00-09:50'),
	('CS101', 202, 'CS', 'Fall2024', 'SCI-102', 'TTH 10:30-11:45'),
	('CS201', 201, 'CS', 'Fall2024', 'SCI-103', 'MWF 11:00-11:50'),
	('CS201', 203, 'CS', 'Spring2025', 'SCI-101', 'MWF 09:00-09:50'),
	('MATH201', 301, 'MATH', 'Fall2024', 'MATH-101', 'MWF 10:00-10:50'),
	('MATH201', 302, 'MATH', 'Spring2025', 'MATH-102', 'TTH 08:00-09:15'),
	('MATH301', 301, 'MATH', 'Fall2024', 'MATH-103', 'TTH 13:00-14:15'),
	('PHYS101', 401, 'PHYS', 'Fall2024', 'SCI-201', 'MWF 13:00-13:50'),
	('PHYS101', 402, 'PHYS', 'Spring2025', 'SCI-202', 'TTH 15:00-16:15'),
	('PHYS201', 401, 'PHYS', 'Spring2025', 'SCI-201', 'MWF 10:00-10:50'),
	('CS301', 201, 'CS', 'Fall2024', 'SCI-104', 'TTH 13:00-14:15'),
	('CS301', 301, 'MATH', 'Fall2024', 'MATH-104', 'MWF 14:00-14:50'),
	('BIO101', 501, 'BIO', 'Fall2024', 'SCI-301', 'MWF 09:00-09:50'),
	('CHEM101', 601, 'CHEM', 'Fall2024', 'SCI-401', 'TTH 10:30-11:45'),
	('ENG110', 701, 'ENG', 'Fall2024', 'HUM-101', 'MWF 11:00-11:50'),
	('HIST101', 801, 'HIST', 'Fall2024', 'HUM-201', 'TTH 09:30-10:45');


--
-- Name: advisors advisors_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.advisors
    ADD CONSTRAINT advisors_pkey PRIMARY KEY (advisor_id);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (course_id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (student_id, course_id);


--
-- Name: prerequisites prerequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prerequisites
    ADD CONSTRAINT prerequisites_pkey PRIMARY KEY (student_id, course_id, prereq_id);


--
-- Name: student_info student_info_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_info
    ADD CONSTRAINT student_info_pkey PRIMARY KEY (student_id);


--
-- Name: student_profiles student_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_pkey PRIMARY KEY (student_id, language, activity);


--
-- Name: teaching_schedule teaching_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.teaching_schedule
    ADD CONSTRAINT teaching_schedule_pkey PRIMARY KEY (course_id, instructor_id);


--
-- PostgreSQL database dump complete
--

\unrestrict abgoCXZlKFhGJZzo0ZCXjHtbb9UqPRgsM7SaVzy5MGb9yQtnfkNH8tMeuWherLZ

