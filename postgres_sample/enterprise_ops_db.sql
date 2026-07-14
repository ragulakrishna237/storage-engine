--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

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
-- Name: clients; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clients (
    client_id integer NOT NULL,
    client_name character varying(80),
    proj_id integer
);


-- ALTER TABLE public.clients OWNER TO postgres;

--
-- Name: clients_client_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.clients_client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER SEQUENCE public.clients_client_id_seq OWNER TO postgres;

--
-- Name: clients_client_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.clients_client_id_seq OWNED BY public.clients.client_id;


--
-- Name: countries; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.countries (
    id integer NOT NULL,
    country_name character varying(50)
);


-- ALTER TABLE public.countries OWNER TO postgres;

--
-- Name: countries_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.countries_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER SEQUENCE public.countries_id_seq OWNER TO postgres;

--
-- Name: countries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.countries_id_seq OWNED BY public.countries.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.departments (
    dept_id integer NOT NULL,
    dept_name character varying(60) NOT NULL,
    location character varying(50)
);


-- ALTER TABLE public.departments OWNER TO postgres;

--
-- Name: departments_dept_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.departments_dept_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER SEQUENCE public.departments_dept_id_seq OWNER TO postgres;

--
-- Name: departments_dept_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.departments_dept_id_seq OWNED BY public.departments.dept_id;


--
-- Name: employee_projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employee_projects (
    emp_id integer NOT NULL,
    proj_id integer NOT NULL,
    role character varying(50)
);


-- ALTER TABLE public.employee_projects OWNER TO postgres;

--
-- Name: employees; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.employees (
    emp_id integer NOT NULL,
    emp_name character varying(50) NOT NULL,
    job_title character varying(50),
    salary numeric(10,2),
    dept_id integer,
    manager_id integer
);


-- ALTER TABLE public.employees OWNER TO postgres;

--
-- Name: employees_emp_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.employees_emp_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER SEQUENCE public.employees_emp_id_seq OWNER TO postgres;

--
-- Name: employees_emp_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.employees_emp_id_seq OWNED BY public.employees.emp_id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projects (
    proj_id integer NOT NULL,
    proj_name character varying(80) NOT NULL,
    dept_id integer,
    start_date date,
    end_date date
);


-- ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: projects_proj_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projects_proj_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER SEQUENCE public.projects_proj_id_seq OWNER TO postgres;

--
-- Name: projects_proj_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projects_proj_id_seq OWNED BY public.projects.proj_id;


--
-- Name: sales; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sales (
    sale_id integer NOT NULL,
    proj_id integer,
    amount numeric(12,2),
    sale_date date
);


-- ALTER TABLE public.sales OWNER TO postgres;

--
-- Name: sales_sale_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sales_sale_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- ALTER SEQUENCE public.sales_sale_id_seq OWNER TO postgres;

--
-- Name: sales_sale_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sales_sale_id_seq OWNED BY public.sales.sale_id;


--
-- Name: clients client_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients ALTER COLUMN client_id SET DEFAULT nextval('public.clients_client_id_seq'::regclass);


--
-- Name: countries id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries ALTER COLUMN id SET DEFAULT nextval('public.countries_id_seq'::regclass);


--
-- Name: departments dept_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments ALTER COLUMN dept_id SET DEFAULT nextval('public.departments_dept_id_seq'::regclass);


--
-- Name: employees emp_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees ALTER COLUMN emp_id SET DEFAULT nextval('public.employees_emp_id_seq'::regclass);


--
-- Name: projects proj_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects ALTER COLUMN proj_id SET DEFAULT nextval('public.projects_proj_id_seq'::regclass);


--
-- Name: sales sale_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales ALTER COLUMN sale_id SET DEFAULT nextval('public.sales_sale_id_seq'::regclass);


--
-- Data for Name: clients; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.clients VALUES
	(1, 'Acme Corp', 3),
	(2, 'BrightFuture Inc', 4),
	(3, 'Zenith Bank', 2),
	(4, 'EcoWorld', 5),
	(5, 'TechWave', NULL),
	(6, 'MediLife', 6),
	(7, 'NovaCare', 1),
	(8, 'Streamline Co.', NULL);


--
-- Data for Name: countries; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.countries VALUES
	(1, 'USA'),
	(2, 'Canada'),
	(3, 'Germany'),
	(4, 'India'),
	(5, 'Japan'),
	(6, 'UK');


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.departments VALUES
	(1, 'Human Resources', 'New York'),
	(2, 'Information Technology', 'Chicago'),
	(3, 'Finance', 'Dallas'),
	(4, 'Marketing', 'Boston'),
	(5, 'Operations', 'San Francisco'),
	(6, 'Research & Development', 'Austin');


--
-- Data for Name: employee_projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.employee_projects VALUES
	(1, 1, 'Supervisor'),
	(2, 1, 'Recruiter'),
	(3, 3, 'Developer'),
	(4, 3, 'DevOps'),
	(13, 3, 'Data Analyst'),
	(15, 4, 'Coordinator'),
	(7, 4, 'Lead'),
	(8, 4, 'Support'),
	(9, 5, 'Manager'),
	(10, 5, 'Logistics'),
	(11, 6, 'Principal Researcher'),
	(12, 6, 'Lab Tech'),
	(17, 6, 'Assistant'),
	(5, 2, 'Analyst'),
	(6, 2, 'Accountant'),
	(14, 2, 'Intern'),
	(16, 3, 'Tech Support');


--
-- Data for Name: employees; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.employees VALUES
	(1, 'Alice Johnson', 'HR Manager', 82000.00, 1, NULL),
	(2, 'Ben Davis', 'Recruiter', 52000.00, 1, 1),
	(3, 'Clara Zhang', 'Software Engineer', 95000.00, 2, NULL),
	(4, 'Daniel Lee', 'DevOps Engineer', 88000.00, 2, 3),
	(5, 'Eva Brown', 'Financial Analyst', 78000.00, 3, NULL),
	(6, 'Frank Harris', 'Accountant', 71000.00, 3, 5),
	(7, 'Grace Kim', 'Marketing Lead', 84000.00, 4, NULL),
	(8, 'Henry Walker', 'Marketing Intern', 42000.00, 4, 7),
	(9, 'Irene Ford', 'Operations Manager', 90000.00, 5, NULL),
	(10, 'Jack Allen', 'Logistics Coordinator', 55000.00, 5, 9),
	(11, 'Karen White', 'Research Scientist', 97000.00, 6, NULL),
	(12, 'Leo Martin', 'Lab Technician', 61000.00, 6, 11),
	(13, 'Maria Gonzalez', 'Data Analyst', 88000.00, 2, 3),
	(14, 'Nina Patel', 'Finance Intern', 45000.00, 3, 5),
	(15, 'Oscar Reed', 'Product Manager', 91000.00, 4, 7),
	(16, 'Paul Chen', 'IT Support', 64000.00, 2, 3),
	(17, 'Quincy Adams', 'Research Intern', 40000.00, 6, 11);


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.projects VALUES
	(1, 'Recruitment Portal', 1, '2025-01-15', '2025-03-30'),
	(2, 'Payroll Automation', 3, '2025-02-01', '2025-06-01'),
	(3, 'Cloud Migration', 2, '2025-03-01', NULL),
	(4, 'CRM Platform', 4, '2025-01-10', '2025-07-15'),
	(5, 'Warehouse Optimization', 5, '2025-04-01', NULL),
	(6, 'AI Research Tool', 6, '2025-02-10', NULL),
	(7, 'Sustainability Report', 3, '2025-05-01', NULL),
	(8, 'Security Enhancement', 2, '2025-06-10', NULL);


--
-- Data for Name: sales; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO public.sales VALUES
	(1, 2, 25000.00, '2025-03-05'),
	(2, 3, 48000.00, '2025-04-10'),
	(3, 3, 52000.00, '2025-05-15'),
	(4, 4, 30000.00, '2025-06-20'),
	(5, 5, 15000.00, '2025-07-05'),
	(6, 6, 80000.00, '2025-05-10'),
	(7, 8, 27000.00, '2025-08-01');


--
-- Name: clients_client_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.clients_client_id_seq', 8, true);


--
-- Name: countries_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.countries_id_seq', 6, true);


--
-- Name: departments_dept_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.departments_dept_id_seq', 6, true);


--
-- Name: employees_emp_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.employees_emp_id_seq', 17, true);


--
-- Name: projects_proj_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.projects_proj_id_seq', 8, true);


--
-- Name: sales_sale_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sales_sale_id_seq', 7, true);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (client_id);


--
-- Name: countries countries_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (id);


--
-- Name: departments departments_dept_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_dept_name_key UNIQUE (dept_name);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (dept_id);


--
-- Name: employee_projects employee_projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_projects
    ADD CONSTRAINT employee_projects_pkey PRIMARY KEY (emp_id, proj_id);


--
-- Name: employees employees_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_pkey PRIMARY KEY (emp_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (proj_id);


--
-- Name: sales sales_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_pkey PRIMARY KEY (sale_id);


--
-- Name: clients clients_proj_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_proj_id_fkey FOREIGN KEY (proj_id) REFERENCES public.projects(proj_id);


--
-- Name: employee_projects employee_projects_emp_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_projects
    ADD CONSTRAINT employee_projects_emp_id_fkey FOREIGN KEY (emp_id) REFERENCES public.employees(emp_id);


--
-- Name: employee_projects employee_projects_proj_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employee_projects
    ADD CONSTRAINT employee_projects_proj_id_fkey FOREIGN KEY (proj_id) REFERENCES public.projects(proj_id);


--
-- Name: employees employees_dept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.departments(dept_id);


--
-- Name: employees employees_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.employees
    ADD CONSTRAINT employees_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.employees(emp_id);


--
-- Name: projects projects_dept_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_dept_id_fkey FOREIGN KEY (dept_id) REFERENCES public.departments(dept_id);


--
-- Name: sales sales_proj_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sales
    ADD CONSTRAINT sales_proj_id_fkey FOREIGN KEY (proj_id) REFERENCES public.projects(proj_id);


--
-- PostgreSQL database dump complete
--

