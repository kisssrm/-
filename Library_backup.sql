--
-- PostgreSQL database cluster dump
--

-- Started on 2026-10-29 13:32:41

\restrict YJeeEHKup6a1iRfJG1FrmqgjTBEM0yI6Z5HtFF5RUkp1CwEmwQKZBPoHJrrJbmK

SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE kisssrm;
ALTER ROLE kisssrm WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS PASSWORD 'SCRAM-SHA-256$4096:573PR5SKWgxOZ5J0nrVaew==$134wP6V3ai17/i5TunTXcudB91j+O2xSVgBv94k3C6E=:OBZz2dUW/WV6nDTR5jpHA4lOf5Wq4DMOt7eQyIAWqVk=';

--
-- User Configurations
--








\unrestrict YJeeEHKup6a1iRfJG1FrmqgjTBEM0yI6Z5HtFF5RUkp1CwEmwQKZBPoHJrrJbmK

--
-- Databases
--

--
-- Database "template1" dump
--

\connect template1

--
-- PostgreSQL database dump
--

\restrict dhrhuucCaAtq9D5ODXcane0vAfDWZ7zZboPN8y4OIyxJh7ykTSd7uA5HdtBaW0T

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-29 13:32:41

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

-- Completed on 2026-10-29 13:32:41

--
-- PostgreSQL database dump complete
--

\unrestrict dhrhuucCaAtq9D5ODXcane0vAfDWZ7zZboPN8y4OIyxJh7ykTSd7uA5HdtBaW0T

--
-- Database "Zagrebelniy" dump
--

--
-- PostgreSQL database dump
--

\restrict ozZlyhpaiP7OKeHyPbYMXIarCtYjtJeo5Ob8vBsgV8n3ImvHcu8cmfcMviGLLyS

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-29 13:32:41

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

--
-- TOC entry 3571 (class 1262 OID 16384)
-- Name: Zagrebelniy; Type: DATABASE; Schema: -; Owner: kisssrm
--

CREATE DATABASE "Zagrebelniy" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.utf8';


ALTER DATABASE "Zagrebelniy" OWNER TO kisssrm;

\unrestrict ozZlyhpaiP7OKeHyPbYMXIarCtYjtJeo5Ob8vBsgV8n3ImvHcu8cmfcMviGLLyS
\connect "Zagrebelniy"
\restrict ozZlyhpaiP7OKeHyPbYMXIarCtYjtJeo5Ob8vBsgV8n3ImvHcu8cmfcMviGLLyS

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

--
-- TOC entry 876 (class 1247 OID 16913)
-- Name: email_d; Type: DOMAIN; Schema: public; Owner: kisssrm
--

CREATE DOMAIN public.email_d AS character varying(100)
	CONSTRAINT email_d_check CHECK (((VALUE)::text ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'::text));


ALTER DOMAIN public.email_d OWNER TO kisssrm;

--
-- TOC entry 880 (class 1247 OID 16916)
-- Name: phone_d; Type: DOMAIN; Schema: public; Owner: kisssrm
--

CREATE DOMAIN public.phone_d AS character varying(20)
	CONSTRAINT phone_d_check CHECK (((VALUE)::text ~ '^\+?[0-9]{10,15}$'::text));


ALTER DOMAIN public.phone_d OWNER TO kisssrm;

--
-- TOC entry 872 (class 1247 OID 16910)
-- Name: positive_int_d; Type: DOMAIN; Schema: public; Owner: kisssrm
--

CREATE DOMAIN public.positive_int_d AS integer
	CONSTRAINT positive_int_d_check CHECK ((VALUE > 0));


ALTER DOMAIN public.positive_int_d OWNER TO kisssrm;

--
-- TOC entry 868 (class 1247 OID 16907)
-- Name: year_d; Type: DOMAIN; Schema: public; Owner: kisssrm
--

CREATE DOMAIN public.year_d AS integer
	CONSTRAINT year_d_check CHECK (((VALUE >= 1400) AND (VALUE <= 2100)));


ALTER DOMAIN public.year_d OWNER TO kisssrm;

--
-- TOC entry 235 (class 1255 OID 16555)
-- Name: forbid_id_change(); Type: FUNCTION; Schema: public; Owner: kisssrm
--

CREATE FUNCTION public.forbid_id_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF to_jsonb(NEW)->>TG_ARGV[0] IS DISTINCT FROM to_jsonb(OLD)->>TG_ARGV[0] THEN
    RAISE EXCEPTION 'Изменение идентификатора % запрещено', TG_ARGV[0];
  END IF;
  RETURN NEW;
END; $$;


ALTER FUNCTION public.forbid_id_change() OWNER TO kisssrm;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 226 (class 1259 OID 16952)
-- Name: authors; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.authors (
    author_id integer NOT NULL,
    full_name character varying(120) NOT NULL,
    birth_year public.year_d,
    country character varying(60)
);


ALTER TABLE public.authors OWNER TO kisssrm;

--
-- TOC entry 225 (class 1259 OID 16951)
-- Name: authors_author_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.authors_author_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.authors_author_id_seq OWNER TO kisssrm;

--
-- TOC entry 3572 (class 0 OID 0)
-- Dependencies: 225
-- Name: authors_author_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.authors_author_id_seq OWNED BY public.authors.author_id;


--
-- TOC entry 232 (class 1259 OID 16999)
-- Name: books; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.books (
    book_id integer NOT NULL,
    title character varying(200) NOT NULL,
    author_id integer NOT NULL,
    genre_id integer NOT NULL,
    publisher_id integer NOT NULL,
    publish_year public.year_d NOT NULL,
    isbn character varying(17) NOT NULL,
    pages public.positive_int_d NOT NULL,
    total_copies integer DEFAULT 1 NOT NULL,
    available_copies integer DEFAULT 1 NOT NULL,
    CONSTRAINT books_available_copies_check CHECK ((available_copies >= 0)),
    CONSTRAINT books_total_copies_check CHECK ((total_copies >= 0)),
    CONSTRAINT chk_available_le_total CHECK ((available_copies <= total_copies))
);


ALTER TABLE public.books OWNER TO kisssrm;

--
-- TOC entry 231 (class 1259 OID 16998)
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.books_book_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.books_book_id_seq OWNER TO kisssrm;

--
-- TOC entry 3573 (class 0 OID 0)
-- Dependencies: 231
-- Name: books_book_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.books_book_id_seq OWNED BY public.books.book_id;


--
-- TOC entry 224 (class 1259 OID 16941)
-- Name: genres; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.genres (
    genre_id integer NOT NULL,
    name character varying(60) NOT NULL
);


ALTER TABLE public.genres OWNER TO kisssrm;

--
-- TOC entry 223 (class 1259 OID 16940)
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.genres_genre_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.genres_genre_id_seq OWNER TO kisssrm;

--
-- TOC entry 3574 (class 0 OID 0)
-- Dependencies: 223
-- Name: genres_genre_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.genres_genre_id_seq OWNED BY public.genres.genre_id;


--
-- TOC entry 222 (class 1259 OID 16930)
-- Name: loan_statuses; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.loan_statuses (
    status_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE public.loan_statuses OWNER TO kisssrm;

--
-- TOC entry 221 (class 1259 OID 16929)
-- Name: loan_statuses_status_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.loan_statuses_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loan_statuses_status_id_seq OWNER TO kisssrm;

--
-- TOC entry 3575 (class 0 OID 0)
-- Dependencies: 221
-- Name: loan_statuses_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.loan_statuses_status_id_seq OWNED BY public.loan_statuses.status_id;


--
-- TOC entry 234 (class 1259 OID 17038)
-- Name: loans; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.loans (
    loan_id integer NOT NULL,
    user_id integer NOT NULL,
    book_id integer NOT NULL,
    status_id integer NOT NULL,
    manager_id integer,
    requested_at timestamp without time zone DEFAULT now() NOT NULL,
    issued_at date,
    due_date date,
    returned_at date,
    CONSTRAINT chk_due CHECK (((due_date IS NULL) OR (issued_at IS NULL) OR (due_date >= issued_at))),
    CONSTRAINT chk_ret CHECK (((returned_at IS NULL) OR (issued_at IS NULL) OR (returned_at >= issued_at)))
);


ALTER TABLE public.loans OWNER TO kisssrm;

--
-- TOC entry 233 (class 1259 OID 17037)
-- Name: loans_loan_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.loans_loan_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.loans_loan_id_seq OWNER TO kisssrm;

--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 233
-- Name: loans_loan_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.loans_loan_id_seq OWNED BY public.loans.loan_id;


--
-- TOC entry 228 (class 1259 OID 16961)
-- Name: publishers; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.publishers (
    publisher_id integer NOT NULL,
    name character varying(120) NOT NULL,
    city character varying(60)
);


ALTER TABLE public.publishers OWNER TO kisssrm;

--
-- TOC entry 227 (class 1259 OID 16960)
-- Name: publishers_publisher_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.publishers_publisher_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.publishers_publisher_id_seq OWNER TO kisssrm;

--
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 227
-- Name: publishers_publisher_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.publishers_publisher_id_seq OWNED BY public.publishers.publisher_id;


--
-- TOC entry 220 (class 1259 OID 16919)
-- Name: roles; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.roles (
    role_id integer NOT NULL,
    name character varying(30) NOT NULL
);


ALTER TABLE public.roles OWNER TO kisssrm;

--
-- TOC entry 219 (class 1259 OID 16918)
-- Name: roles_role_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.roles_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roles_role_id_seq OWNER TO kisssrm;

--
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 219
-- Name: roles_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.roles_role_id_seq OWNED BY public.roles.role_id;


--
-- TOC entry 230 (class 1259 OID 16972)
-- Name: users; Type: TABLE; Schema: public; Owner: kisssrm
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    login character varying(40) NOT NULL,
    password_hash character varying(128) NOT NULL,
    full_name character varying(120) NOT NULL,
    email public.email_d NOT NULL,
    phone public.phone_d,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_login_check CHECK ((char_length((login)::text) >= 3))
);


ALTER TABLE public.users OWNER TO kisssrm;

--
-- TOC entry 229 (class 1259 OID 16971)
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: kisssrm
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO kisssrm;

--
-- TOC entry 3579 (class 0 OID 0)
-- Dependencies: 229
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: kisssrm
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- TOC entry 3344 (class 2604 OID 16955)
-- Name: authors author_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.authors ALTER COLUMN author_id SET DEFAULT nextval('public.authors_author_id_seq'::regclass);


--
-- TOC entry 3348 (class 2604 OID 17002)
-- Name: books book_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.books ALTER COLUMN book_id SET DEFAULT nextval('public.books_book_id_seq'::regclass);


--
-- TOC entry 3343 (class 2604 OID 16944)
-- Name: genres genre_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.genres ALTER COLUMN genre_id SET DEFAULT nextval('public.genres_genre_id_seq'::regclass);


--
-- TOC entry 3342 (class 2604 OID 16933)
-- Name: loan_statuses status_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loan_statuses ALTER COLUMN status_id SET DEFAULT nextval('public.loan_statuses_status_id_seq'::regclass);


--
-- TOC entry 3351 (class 2604 OID 17041)
-- Name: loans loan_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loans ALTER COLUMN loan_id SET DEFAULT nextval('public.loans_loan_id_seq'::regclass);


--
-- TOC entry 3345 (class 2604 OID 16964)
-- Name: publishers publisher_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.publishers ALTER COLUMN publisher_id SET DEFAULT nextval('public.publishers_publisher_id_seq'::regclass);


--
-- TOC entry 3341 (class 2604 OID 16922)
-- Name: roles role_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.roles ALTER COLUMN role_id SET DEFAULT nextval('public.roles_role_id_seq'::regclass);


--
-- TOC entry 3346 (class 2604 OID 16975)
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- TOC entry 3557 (class 0 OID 16952)
-- Dependencies: 226
-- Data for Name: authors; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.authors (author_id, full_name, birth_year, country) FROM stdin;
1	Иван Петров	1853	Англия
2	Дмитрий Смирнов	1856	США
3	Сергей Кузнецов	1859	Франция
4	Андрей Попов	1862	Германия
5	Михаил Соколов	1865	Россия
6	Александр Лебедев	1868	Англия
7	Иван Иванов	1871	США
8	Дмитрий Петров	1874	Франция
9	Сергей Смирнов	1877	Германия
10	Андрей Кузнецов	1880	Россия
11	Михаил Попов	1883	Англия
12	Александр Соколов	1886	США
13	Иван Лебедев	1889	Франция
14	Дмитрий Иванов	1892	Германия
15	Сергей Петров	1895	Россия
16	Андрей Смирнов	1898	Англия
17	Михаил Кузнецов	1901	США
18	Александр Попов	1904	Франция
19	Иван Соколов	1907	Германия
20	Дмитрий Лебедев	1910	Россия
21	Сергей Иванов	1913	Англия
22	Андрей Петров	1916	США
23	Михаил Смирнов	1919	Франция
24	Александр Кузнецов	1922	Германия
25	Иван Попов	1925	Россия
26	Дмитрий Соколов	1928	Англия
27	Сергей Лебедев	1931	США
28	Андрей Иванов	1934	Франция
29	Михаил Петров	1937	Германия
30	Александр Смирнов	1940	Россия
31	Иван Кузнецов	1943	Англия
32	Дмитрий Попов	1946	США
33	Сергей Соколов	1949	Франция
34	Андрей Лебедев	1952	Германия
35	Михаил Иванов	1955	Россия
36	Александр Петров	1958	Англия
37	Иван Смирнов	1961	США
38	Дмитрий Кузнецов	1964	Франция
39	Сергей Попов	1967	Германия
40	Андрей Соколов	1970	Россия
\.


--
-- TOC entry 3563 (class 0 OID 16999)
-- Dependencies: 232
-- Data for Name: books; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.books (book_id, title, author_id, genre_id, publisher_id, publish_year, isbn, pages, total_copies, available_copies) FROM stdin;
1	Книга №1	2	2	2	1981	978-5-00001-000-0	105	3	3
2	Книга №2	3	3	3	1982	978-5-00002-000-0	110	3	1
3	Книга №3	4	4	4	1983	978-5-00003-000-0	115	3	3
4	Книга №4	5	5	5	1984	978-5-00004-000-0	120	3	3
5	Книга №5	6	6	6	1985	978-5-00005-000-0	125	3	3
6	Книга №6	7	7	7	1986	978-5-00006-000-0	130	3	1
7	Книга №7	8	8	8	1987	978-5-00007-000-0	135	3	3
8	Книга №8	9	1	9	1988	978-5-00008-000-0	140	3	3
9	Книга №9	10	2	10	1989	978-5-00009-000-0	145	3	3
10	Книга №10	11	3	1	1990	978-5-00010-000-0	150	3	1
11	Книга №11	12	4	2	1991	978-5-00011-000-0	155	3	3
12	Книга №12	13	5	3	1992	978-5-00012-000-0	160	3	3
13	Книга №13	14	6	4	1993	978-5-00013-000-0	165	3	3
14	Книга №14	15	7	5	1994	978-5-00014-000-0	170	3	1
15	Книга №15	16	8	6	1995	978-5-00015-000-0	175	3	3
16	Книга №16	17	1	7	1996	978-5-00016-000-0	180	3	3
17	Книга №17	18	2	8	1997	978-5-00017-000-0	185	3	3
18	Книга №18	19	3	9	1998	978-5-00018-000-0	190	3	1
19	Книга №19	20	4	10	1999	978-5-00019-000-0	195	3	3
20	Книга №20	21	5	1	2000	978-5-00020-000-0	200	3	3
21	Книга №21	22	6	2	2001	978-5-00021-000-0	205	3	3
22	Книга №22	23	7	3	2002	978-5-00022-000-0	210	3	1
23	Книга №23	24	8	4	2003	978-5-00023-000-0	215	3	3
24	Книга №24	25	1	5	2004	978-5-00024-000-0	220	3	3
25	Книга №25	26	2	6	2005	978-5-00025-000-0	225	3	3
26	Книга №26	27	3	7	2006	978-5-00026-000-0	230	3	1
27	Книга №27	28	4	8	2007	978-5-00027-000-0	235	3	3
28	Книга №28	29	5	9	2008	978-5-00028-000-0	240	3	3
29	Книга №29	30	6	10	2009	978-5-00029-000-0	245	3	3
30	Книга №30	31	7	1	2010	978-5-00030-000-0	250	3	1
31	Книга №31	32	8	2	2011	978-5-00031-000-0	255	3	3
32	Книга №32	33	1	3	2012	978-5-00032-000-0	260	3	3
33	Книга №33	34	2	4	2013	978-5-00033-000-0	265	3	3
34	Книга №34	35	3	5	2014	978-5-00034-000-0	270	3	2
35	Книга №35	36	4	6	2015	978-5-00035-000-0	275	3	3
36	Книга №36	37	5	7	2016	978-5-00036-000-0	280	3	3
37	Книга №37	38	6	8	2017	978-5-00037-000-0	285	3	3
38	Книга №38	39	7	9	2018	978-5-00038-000-0	290	3	2
39	Книга №39	40	8	10	2019	978-5-00039-000-0	295	3	3
40	Книга №40	1	1	1	2020	978-5-00040-000-0	300	3	3
41	Книга №41	2	2	2	2021	978-5-00041-000-0	305	3	3
42	Книга №42	3	3	3	2022	978-5-00042-000-0	310	3	2
43	Книга №43	4	4	4	2023	978-5-00043-000-0	315	3	3
44	Книга №44	5	5	5	2024	978-5-00044-000-0	320	3	3
45	Книга №45	6	6	6	1980	978-5-00045-000-0	325	3	3
46	Книга №46	7	7	7	1981	978-5-00046-000-0	330	3	2
47	Книга №47	8	8	8	1982	978-5-00047-000-0	335	3	3
48	Книга №48	9	1	9	1983	978-5-00048-000-0	340	3	3
49	Книга №49	10	2	10	1984	978-5-00049-000-0	345	3	3
50	Книга №50	11	3	1	1985	978-5-00050-000-0	350	3	2
51	Книга №51	12	4	2	1986	978-5-00051-000-0	355	3	3
52	Книга №52	13	5	3	1987	978-5-00052-000-0	360	3	3
53	Книга №53	14	6	4	1988	978-5-00053-000-0	365	3	3
54	Книга №54	15	7	5	1989	978-5-00054-000-0	370	3	2
55	Книга №55	16	8	6	1990	978-5-00055-000-0	375	3	3
56	Книга №56	17	1	7	1991	978-5-00056-000-0	380	3	3
57	Книга №57	18	2	8	1992	978-5-00057-000-0	385	3	3
58	Книга №58	19	3	9	1993	978-5-00058-000-0	390	3	2
59	Книга №59	20	4	10	1994	978-5-00059-000-0	395	3	3
60	Книга №60	21	5	1	1995	978-5-00060-000-0	400	3	3
61	Книга №61	22	6	2	1996	978-5-00061-000-0	405	3	3
62	Книга №62	23	7	3	1997	978-5-00062-000-0	410	3	2
63	Книга №63	24	8	4	1998	978-5-00063-000-0	415	3	3
64	Книга №64	25	1	5	1999	978-5-00064-000-0	420	3	3
65	Книга №65	26	2	6	2000	978-5-00065-000-0	425	3	3
66	Книга №66	27	3	7	2001	978-5-00066-000-0	430	3	2
67	Книга №67	28	4	8	2002	978-5-00067-000-0	435	3	3
68	Книга №68	29	5	9	2003	978-5-00068-000-0	440	3	3
69	Книга №69	30	6	10	2004	978-5-00069-000-0	445	3	3
70	Книга №70	31	7	1	2005	978-5-00070-000-0	450	3	2
71	Книга №71	32	8	2	2006	978-5-00071-000-0	455	3	3
72	Книга №72	33	1	3	2007	978-5-00072-000-0	460	3	3
73	Книга №73	34	2	4	2008	978-5-00073-000-0	465	3	3
74	Книга №74	35	3	5	2009	978-5-00074-000-0	470	3	2
75	Книга №75	36	4	6	2010	978-5-00075-000-0	475	3	3
76	Книга №76	37	5	7	2011	978-5-00076-000-0	480	3	3
77	Книга №77	38	6	8	2012	978-5-00077-000-0	485	3	3
78	Книга №78	39	7	9	2013	978-5-00078-000-0	490	3	2
79	Книга №79	40	8	10	2014	978-5-00079-000-0	495	3	3
80	Книга №80	1	1	1	2015	978-5-00080-000-0	500	3	3
81	Книга №81	2	2	2	2016	978-5-00081-000-0	505	3	3
82	Книга №82	3	3	3	2017	978-5-00082-000-0	510	3	2
83	Книга №83	4	4	4	2018	978-5-00083-000-0	515	3	3
84	Книга №84	5	5	5	2019	978-5-00084-000-0	520	3	3
85	Книга №85	6	6	6	2020	978-5-00085-000-0	525	3	3
86	Книга №86	7	7	7	2021	978-5-00086-000-0	530	3	2
87	Книга №87	8	8	8	2022	978-5-00087-000-0	535	3	3
88	Книга №88	9	1	9	2023	978-5-00088-000-0	540	3	3
89	Книга №89	10	2	10	2024	978-5-00089-000-0	545	3	3
90	Книга №90	11	3	1	1980	978-5-00090-000-0	550	3	2
91	Книга №91	12	4	2	1981	978-5-00091-000-0	555	3	3
92	Книга №92	13	5	3	1982	978-5-00092-000-0	560	3	3
93	Книга №93	14	6	4	1983	978-5-00093-000-0	565	3	3
94	Книга №94	15	7	5	1984	978-5-00094-000-0	570	3	2
95	Книга №95	16	8	6	1985	978-5-00095-000-0	575	3	3
96	Книга №96	17	1	7	1986	978-5-00096-000-0	580	3	3
97	Книга №97	18	2	8	1987	978-5-00097-000-0	585	3	3
98	Книга №98	19	3	9	1988	978-5-00098-000-0	590	3	2
99	Книга №99	20	4	10	1989	978-5-00099-000-0	595	3	3
100	Книга №100	21	5	1	1990	978-5-00100-000-0	600	3	3
101	Книга №101	22	6	2	1991	978-5-00101-000-0	605	3	3
102	Книга №102	23	7	3	1992	978-5-00102-000-0	610	3	2
103	Книга №103	24	8	4	1993	978-5-00103-000-0	615	3	3
104	Книга №104	25	1	5	1994	978-5-00104-000-0	620	3	3
105	Книга №105	26	2	6	1995	978-5-00105-000-0	625	3	3
106	Книга №106	27	3	7	1996	978-5-00106-000-0	630	3	2
107	Книга №107	28	4	8	1997	978-5-00107-000-0	635	3	3
108	Книга №108	29	5	9	1998	978-5-00108-000-0	640	3	3
109	Книга №109	30	6	10	1999	978-5-00109-000-0	645	3	3
110	Книга №110	31	7	1	2000	978-5-00110-000-0	650	3	2
111	Книга №111	32	8	2	2001	978-5-00111-000-0	655	3	3
112	Книга №112	33	1	3	2002	978-5-00112-000-0	660	3	3
113	Книга №113	34	2	4	2003	978-5-00113-000-0	665	3	3
114	Книга №114	35	3	5	2004	978-5-00114-000-0	670	3	2
115	Книга №115	36	4	6	2005	978-5-00115-000-0	675	3	3
116	Книга №116	37	5	7	2006	978-5-00116-000-0	680	3	3
117	Книга №117	38	6	8	2007	978-5-00117-000-0	685	3	3
118	Книга №118	39	7	9	2008	978-5-00118-000-0	690	3	2
119	Книга №119	40	8	10	2009	978-5-00119-000-0	695	3	3
120	Книга №120	1	1	1	2010	978-5-00120-000-0	700	3	3
\.


--
-- TOC entry 3555 (class 0 OID 16941)
-- Dependencies: 224
-- Data for Name: genres; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.genres (genre_id, name) FROM stdin;
1	Роман
2	Фантастика
3	Детектив
4	Фэнтези
5	Поэзия
6	Научпоп
7	История
8	Классика
\.


--
-- TOC entry 3553 (class 0 OID 16930)
-- Dependencies: 222
-- Data for Name: loan_statuses; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.loan_statuses (status_id, name) FROM stdin;
1	requested
2	issued
3	returned
4	rejected
\.


--
-- TOC entry 3565 (class 0 OID 17038)
-- Dependencies: 234
-- Data for Name: loans; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.loans (loan_id, user_id, book_id, status_id, manager_id, requested_at, issued_at, due_date, returned_at) FROM stdin;
1	5	2	2	3	2026-10-28 08:23:47.578089	2026-09-28	2026-10-12	\N
2	6	3	3	2	2026-10-27 08:23:47.578089	2026-09-27	2026-10-11	2026-10-02
3	7	4	4	3	2026-10-26 08:23:47.578089	\N	\N	\N
4	8	5	1	\N	2026-10-25 08:23:47.578089	\N	\N	\N
5	9	6	2	3	2026-10-24 08:23:47.578089	2026-09-24	2026-10-08	\N
6	10	7	3	2	2026-10-23 08:23:47.578089	2026-09-23	2026-10-07	2026-09-28
7	11	8	4	3	2026-10-22 08:23:47.578089	\N	\N	\N
8	12	9	1	\N	2026-10-21 08:23:47.578089	\N	\N	\N
9	13	10	2	3	2026-10-20 08:23:47.578089	2026-09-20	2026-10-04	\N
10	14	11	3	2	2026-10-19 08:23:47.578089	2026-09-19	2026-10-03	2026-09-24
11	15	12	4	3	2026-10-18 08:23:47.578089	\N	\N	\N
12	16	13	1	\N	2026-10-17 08:23:47.578089	\N	\N	\N
13	17	14	2	3	2026-10-16 08:23:47.578089	2026-09-16	2026-09-30	\N
14	18	15	3	2	2026-10-15 08:23:47.578089	2026-09-15	2026-09-29	2026-09-20
15	19	16	4	3	2026-10-14 08:23:47.578089	\N	\N	\N
16	20	17	1	\N	2026-10-13 08:23:47.578089	\N	\N	\N
17	21	18	2	3	2026-10-12 08:23:47.578089	2026-09-12	2026-09-26	\N
18	22	19	3	2	2026-10-11 08:23:47.578089	2026-09-11	2026-09-25	2026-09-16
19	23	20	4	3	2026-10-10 08:23:47.578089	\N	\N	\N
20	24	21	1	\N	2026-10-09 08:23:47.578089	\N	\N	\N
21	25	22	2	3	2026-10-08 08:23:47.578089	2026-09-08	2026-09-22	\N
22	26	23	3	2	2026-10-07 08:23:47.578089	2026-09-07	2026-09-21	2026-09-12
23	27	24	4	3	2026-10-06 08:23:47.578089	\N	\N	\N
24	28	25	1	\N	2026-10-05 08:23:47.578089	\N	\N	\N
25	29	26	2	3	2026-10-04 08:23:47.578089	2026-09-04	2026-09-18	\N
26	30	27	3	2	2026-10-03 08:23:47.578089	2026-09-03	2026-09-17	2026-09-08
27	31	28	4	3	2026-10-02 08:23:47.578089	\N	\N	\N
28	32	29	1	\N	2026-10-01 08:23:47.578089	\N	\N	\N
29	33	30	2	3	2026-09-30 08:23:47.578089	2026-08-31	2026-09-14	\N
30	34	31	3	2	2026-09-29 08:23:47.578089	2026-08-30	2026-09-13	2026-09-04
31	35	32	4	3	2026-09-28 08:23:47.578089	\N	\N	\N
32	36	33	1	\N	2026-09-27 08:23:47.578089	\N	\N	\N
33	37	34	2	3	2026-09-26 08:23:47.578089	2026-08-27	2026-09-10	\N
34	38	35	3	2	2026-09-25 08:23:47.578089	2026-08-26	2026-09-09	2026-08-31
35	39	36	4	3	2026-09-24 08:23:47.578089	\N	\N	\N
36	40	37	1	\N	2026-09-23 08:23:47.578089	\N	\N	\N
37	41	38	2	3	2026-09-22 08:23:47.578089	2026-08-23	2026-09-06	\N
38	42	39	3	2	2026-09-21 08:23:47.578089	2026-08-22	2026-09-05	2026-08-27
39	43	40	4	3	2026-09-20 08:23:47.578089	\N	\N	\N
40	4	41	1	\N	2026-09-19 08:23:47.578089	\N	\N	\N
41	5	42	2	3	2026-09-18 08:23:47.578089	2026-08-19	2026-09-02	\N
42	6	43	3	2	2026-09-17 08:23:47.578089	2026-08-18	2026-09-01	2026-08-23
43	7	44	4	3	2026-09-16 08:23:47.578089	\N	\N	\N
44	8	45	1	\N	2026-09-15 08:23:47.578089	\N	\N	\N
45	9	46	2	3	2026-09-14 08:23:47.578089	2026-08-15	2026-08-29	\N
46	10	47	3	2	2026-09-13 08:23:47.578089	2026-08-14	2026-08-28	2026-08-19
47	11	48	4	3	2026-09-12 08:23:47.578089	\N	\N	\N
48	12	49	1	\N	2026-09-11 08:23:47.578089	\N	\N	\N
49	13	50	2	3	2026-09-10 08:23:47.578089	2026-08-11	2026-08-25	\N
50	14	51	3	2	2026-09-09 08:23:47.578089	2026-08-10	2026-08-24	2026-08-15
51	15	52	4	3	2026-09-08 08:23:47.578089	\N	\N	\N
52	16	53	1	\N	2026-09-07 08:23:47.578089	\N	\N	\N
53	17	54	2	3	2026-09-06 08:23:47.578089	2026-08-07	2026-08-21	\N
54	18	55	3	2	2026-09-05 08:23:47.578089	2026-08-06	2026-08-20	2026-08-11
55	19	56	4	3	2026-09-04 08:23:47.578089	\N	\N	\N
56	20	57	1	\N	2026-09-03 08:23:47.578089	\N	\N	\N
57	21	58	2	3	2026-09-02 08:23:47.578089	2026-08-03	2026-08-17	\N
58	22	59	3	2	2026-09-01 08:23:47.578089	2026-08-02	2026-08-16	2026-08-07
59	23	60	4	3	2026-08-31 08:23:47.578089	\N	\N	\N
60	24	61	1	\N	2026-08-30 08:23:47.578089	\N	\N	\N
61	25	62	2	3	2026-08-29 08:23:47.578089	2026-09-28	2026-10-12	\N
62	26	63	3	2	2026-08-28 08:23:47.578089	2026-09-27	2026-10-11	2026-10-02
63	27	64	4	3	2026-08-27 08:23:47.578089	\N	\N	\N
64	28	65	1	\N	2026-08-26 08:23:47.578089	\N	\N	\N
65	29	66	2	3	2026-08-25 08:23:47.578089	2026-09-24	2026-10-08	\N
66	30	67	3	2	2026-08-24 08:23:47.578089	2026-09-23	2026-10-07	2026-09-28
67	31	68	4	3	2026-08-23 08:23:47.578089	\N	\N	\N
68	32	69	1	\N	2026-08-22 08:23:47.578089	\N	\N	\N
69	33	70	2	3	2026-08-21 08:23:47.578089	2026-09-20	2026-10-04	\N
70	34	71	3	2	2026-08-20 08:23:47.578089	2026-09-19	2026-10-03	2026-09-24
71	35	72	4	3	2026-08-19 08:23:47.578089	\N	\N	\N
72	36	73	1	\N	2026-08-18 08:23:47.578089	\N	\N	\N
73	37	74	2	3	2026-08-17 08:23:47.578089	2026-09-16	2026-09-30	\N
74	38	75	3	2	2026-08-16 08:23:47.578089	2026-09-15	2026-09-29	2026-09-20
75	39	76	4	3	2026-08-15 08:23:47.578089	\N	\N	\N
76	40	77	1	\N	2026-08-14 08:23:47.578089	\N	\N	\N
77	41	78	2	3	2026-08-13 08:23:47.578089	2026-09-12	2026-09-26	\N
78	42	79	3	2	2026-08-12 08:23:47.578089	2026-09-11	2026-09-25	2026-09-16
79	43	80	4	3	2026-08-11 08:23:47.578089	\N	\N	\N
80	4	81	1	\N	2026-08-10 08:23:47.578089	\N	\N	\N
81	5	82	2	3	2026-08-09 08:23:47.578089	2026-09-08	2026-09-22	\N
82	6	83	3	2	2026-08-08 08:23:47.578089	2026-09-07	2026-09-21	2026-09-12
83	7	84	4	3	2026-08-07 08:23:47.578089	\N	\N	\N
84	8	85	1	\N	2026-08-06 08:23:47.578089	\N	\N	\N
85	9	86	2	3	2026-08-05 08:23:47.578089	2026-09-04	2026-09-18	\N
86	10	87	3	2	2026-08-04 08:23:47.578089	2026-09-03	2026-09-17	2026-09-08
87	11	88	4	3	2026-08-03 08:23:47.578089	\N	\N	\N
88	12	89	1	\N	2026-08-02 08:23:47.578089	\N	\N	\N
89	13	90	2	3	2026-08-01 08:23:47.578089	2026-08-31	2026-09-14	\N
90	14	91	3	2	2026-07-31 08:23:47.578089	2026-08-30	2026-09-13	2026-09-04
91	15	92	4	3	2026-07-30 08:23:47.578089	\N	\N	\N
92	16	93	1	\N	2026-07-29 08:23:47.578089	\N	\N	\N
93	17	94	2	3	2026-07-28 08:23:47.578089	2026-08-27	2026-09-10	\N
94	18	95	3	2	2026-07-27 08:23:47.578089	2026-08-26	2026-09-09	2026-08-31
95	19	96	4	3	2026-07-26 08:23:47.578089	\N	\N	\N
96	20	97	1	\N	2026-07-25 08:23:47.578089	\N	\N	\N
97	21	98	2	3	2026-07-24 08:23:47.578089	2026-08-23	2026-09-06	\N
98	22	99	3	2	2026-07-23 08:23:47.578089	2026-08-22	2026-09-05	2026-08-27
99	23	100	4	3	2026-07-22 08:23:47.578089	\N	\N	\N
100	24	101	1	\N	2026-07-21 08:23:47.578089	\N	\N	\N
101	25	102	2	3	2026-07-20 08:23:47.578089	2026-08-19	2026-09-02	\N
102	26	103	3	2	2026-07-19 08:23:47.578089	2026-08-18	2026-09-01	2026-08-23
103	27	104	4	3	2026-07-18 08:23:47.578089	\N	\N	\N
104	28	105	1	\N	2026-07-17 08:23:47.578089	\N	\N	\N
105	29	106	2	3	2026-07-16 08:23:47.578089	2026-08-15	2026-08-29	\N
106	30	107	3	2	2026-07-15 08:23:47.578089	2026-08-14	2026-08-28	2026-08-19
107	31	108	4	3	2026-07-14 08:23:47.578089	\N	\N	\N
108	32	109	1	\N	2026-07-13 08:23:47.578089	\N	\N	\N
109	33	110	2	3	2026-07-12 08:23:47.578089	2026-08-11	2026-08-25	\N
110	34	111	3	2	2026-07-11 08:23:47.578089	2026-08-10	2026-08-24	2026-08-15
111	35	112	4	3	2026-07-10 08:23:47.578089	\N	\N	\N
112	36	113	1	\N	2026-07-09 08:23:47.578089	\N	\N	\N
113	37	114	2	3	2026-07-08 08:23:47.578089	2026-08-07	2026-08-21	\N
114	38	115	3	2	2026-07-07 08:23:47.578089	2026-08-06	2026-08-20	2026-08-11
115	39	116	4	3	2026-07-06 08:23:47.578089	\N	\N	\N
116	40	117	1	\N	2026-07-05 08:23:47.578089	\N	\N	\N
117	41	118	2	3	2026-07-04 08:23:47.578089	2026-08-03	2026-08-17	\N
118	42	119	3	2	2026-07-03 08:23:47.578089	2026-08-02	2026-08-16	2026-08-07
119	43	120	4	3	2026-07-02 08:23:47.578089	\N	\N	\N
120	4	1	1	\N	2026-07-01 08:23:47.578089	\N	\N	\N
121	5	2	2	3	2026-06-30 08:23:47.578089	2026-09-28	2026-10-12	\N
122	6	3	3	2	2026-06-29 08:23:47.578089	2026-09-27	2026-10-11	2026-10-02
123	7	4	4	3	2026-06-28 08:23:47.578089	\N	\N	\N
124	8	5	1	\N	2026-06-27 08:23:47.578089	\N	\N	\N
125	9	6	2	3	2026-06-26 08:23:47.578089	2026-09-24	2026-10-08	\N
126	10	7	3	2	2026-06-25 08:23:47.578089	2026-09-23	2026-10-07	2026-09-28
127	11	8	4	3	2026-06-24 08:23:47.578089	\N	\N	\N
128	12	9	1	\N	2026-06-23 08:23:47.578089	\N	\N	\N
129	13	10	2	3	2026-06-22 08:23:47.578089	2026-09-20	2026-10-04	\N
130	14	11	3	2	2026-06-21 08:23:47.578089	2026-09-19	2026-10-03	2026-09-24
131	15	12	4	3	2026-06-20 08:23:47.578089	\N	\N	\N
132	16	13	1	\N	2026-06-19 08:23:47.578089	\N	\N	\N
133	17	14	2	3	2026-06-18 08:23:47.578089	2026-09-16	2026-09-30	\N
134	18	15	3	2	2026-06-17 08:23:47.578089	2026-09-15	2026-09-29	2026-09-20
135	19	16	4	3	2026-06-16 08:23:47.578089	\N	\N	\N
136	20	17	1	\N	2026-06-15 08:23:47.578089	\N	\N	\N
137	21	18	2	3	2026-06-14 08:23:47.578089	2026-09-12	2026-09-26	\N
138	22	19	3	2	2026-06-13 08:23:47.578089	2026-09-11	2026-09-25	2026-09-16
139	23	20	4	3	2026-06-12 08:23:47.578089	\N	\N	\N
140	24	21	1	\N	2026-06-11 08:23:47.578089	\N	\N	\N
141	25	22	2	3	2026-06-10 08:23:47.578089	2026-09-08	2026-09-22	\N
142	26	23	3	2	2026-06-09 08:23:47.578089	2026-09-07	2026-09-21	2026-09-12
143	27	24	4	3	2026-06-08 08:23:47.578089	\N	\N	\N
144	28	25	1	\N	2026-06-07 08:23:47.578089	\N	\N	\N
145	29	26	2	3	2026-06-06 08:23:47.578089	2026-09-04	2026-09-18	\N
146	30	27	3	2	2026-06-05 08:23:47.578089	2026-09-03	2026-09-17	2026-09-08
147	31	28	4	3	2026-06-04 08:23:47.578089	\N	\N	\N
148	32	29	1	\N	2026-06-03 08:23:47.578089	\N	\N	\N
149	33	30	2	3	2026-06-02 08:23:47.578089	2026-08-31	2026-09-14	\N
150	34	31	3	2	2026-06-01 08:23:47.578089	2026-08-30	2026-09-13	2026-09-04
\.


--
-- TOC entry 3559 (class 0 OID 16961)
-- Dependencies: 228
-- Data for Name: publishers; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.publishers (publisher_id, name, city) FROM stdin;
1	Издательство 1	Санкт-Петербург
2	Издательство 2	Казань
3	Издательство 3	Москва
4	Издательство 4	Санкт-Петербург
5	Издательство 5	Казань
6	Издательство 6	Москва
7	Издательство 7	Санкт-Петербург
8	Издательство 8	Казань
9	Издательство 9	Москва
10	Издательство 10	Санкт-Петербург
\.


--
-- TOC entry 3551 (class 0 OID 16919)
-- Dependencies: 220
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.roles (role_id, name) FROM stdin;
1	admin
2	manager
3	user
\.


--
-- TOC entry 3561 (class 0 OID 16972)
-- Dependencies: 230
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: kisssrm
--

COPY public.users (user_id, role_id, login, password_hash, full_name, email, phone, created_at) FROM stdin;
1	1	admin	21232f297a57a5a743894a0e4a801fc3	Администратор	admin@library.test	+79001000001	2026-10-29 08:23:47.578089
2	2	manager1	c240642ddef994358c96da82c0361a58	Менеджер Первый	manager1@library.test	+79001000002	2026-10-29 08:23:47.578089
3	2	manager2	8df5127cd164b5bc2d2b78410a7eea0c	Менеджер Второй	manager2@library.test	+79001000003	2026-10-29 08:23:47.578089
4	3	user1	24c9e15e52afc47c225b757e7bee1f9d	Читатель 1	user1@library.test	+79002000001	2026-10-29 08:23:47.578089
5	3	user2	7e58d63b60197ceb55a1c487989a3720	Читатель 2	user2@library.test	+79002000002	2026-10-29 08:23:47.578089
6	3	user3	92877af70a45fd6a2ed7fe81e1236b78	Читатель 3	user3@library.test	+79002000003	2026-10-29 08:23:47.578089
7	3	user4	3f02ebe3d7929b091e3d8ccfde2f3bc6	Читатель 4	user4@library.test	+79002000004	2026-10-29 08:23:47.578089
8	3	user5	0a791842f52a0acfbb3a783378c066b8	Читатель 5	user5@library.test	+79002000005	2026-10-29 08:23:47.578089
9	3	user6	affec3b64cf90492377a8114c86fc093	Читатель 6	user6@library.test	+79002000006	2026-10-29 08:23:47.578089
10	3	user7	3e0469fb134991f8f75a2760e409c6ed	Читатель 7	user7@library.test	+79002000007	2026-10-29 08:23:47.578089
11	3	user8	7668f673d5669995175ef91b5d171945	Читатель 8	user8@library.test	+79002000008	2026-10-29 08:23:47.578089
12	3	user9	8808a13b854c2563da1a5f6cb2130868	Читатель 9	user9@library.test	+79002000009	2026-10-29 08:23:47.578089
13	3	user10	990d67a9f94696b1abe2dccf06900322	Читатель 10	user10@library.test	+79002000010	2026-10-29 08:23:47.578089
14	3	user11	03aa1a0b0375b0461c1b8f35b234e67a	Читатель 11	user11@library.test	+79002000011	2026-10-29 08:23:47.578089
15	3	user12	d781eaae8248db6ce1a7b82e58e60435	Читатель 12	user12@library.test	+79002000012	2026-10-29 08:23:47.578089
16	3	user13	d09979d794a6ee60d836f884739f7196	Читатель 13	user13@library.test	+79002000013	2026-10-29 08:23:47.578089
17	3	user14	ef06d5cbf35386ff2203d186eeff7923	Читатель 14	user14@library.test	+79002000014	2026-10-29 08:23:47.578089
18	3	user15	726dedc0d6788b05f486730edcc0e871	Читатель 15	user15@library.test	+79002000015	2026-10-29 08:23:47.578089
19	3	user16	8a62f0beaa5ae938956f5ea290321336	Читатель 16	user16@library.test	+79002000016	2026-10-29 08:23:47.578089
20	3	user17	2b4233ebec7a45e1fb8ddd1aab794f7b	Читатель 17	user17@library.test	+79002000017	2026-10-29 08:23:47.578089
21	3	user18	7ac18a1893e1d2bd5b46958ce1d2a8d0	Читатель 18	user18@library.test	+79002000018	2026-10-29 08:23:47.578089
22	3	user19	2baab43f784b5b530b5347a50490bb0a	Читатель 19	user19@library.test	+79002000019	2026-10-29 08:23:47.578089
23	3	user20	10880c7f4e4209eeda79711e1ea1723e	Читатель 20	user20@library.test	+79002000020	2026-10-29 08:23:47.578089
24	3	user21	2e129db15b6d6db5342ba5d328642262	Читатель 21	user21@library.test	+79002000021	2026-10-29 08:23:47.578089
25	3	user22	87dc1e131a1369fdf8f1c824a6a62dff	Читатель 22	user22@library.test	+79002000022	2026-10-29 08:23:47.578089
26	3	user23	00a65dd47e842bcc3d82a296301071fb	Читатель 23	user23@library.test	+79002000023	2026-10-29 08:23:47.578089
27	3	user24	5e6c9b24829588e0ac8f7d8074a4bfd4	Читатель 24	user24@library.test	+79002000024	2026-10-29 08:23:47.578089
28	3	user25	0f8f84c18bfd5244ed976f63924a8a0e	Читатель 25	user25@library.test	+79002000025	2026-10-29 08:23:47.578089
29	3	user26	a507ac920f797876259f3c91f5cdef99	Читатель 26	user26@library.test	+79002000026	2026-10-29 08:23:47.578089
30	3	user27	078d079e6146dec4dbf2135a8e513e2e	Читатель 27	user27@library.test	+79002000027	2026-10-29 08:23:47.578089
31	3	user28	b6f7fac0074f6508e5a4540ad89b55c0	Читатель 28	user28@library.test	+79002000028	2026-10-29 08:23:47.578089
32	3	user29	244fd63d0adbf673130fce2f222078a5	Читатель 29	user29@library.test	+79002000029	2026-10-29 08:23:47.578089
33	3	user30	40b13b85e6e4fc9c4a6f24379db20a39	Читатель 30	user30@library.test	+79002000030	2026-10-29 08:23:47.578089
34	3	user31	0c673c53a29acb19c7e55b292d259e4d	Читатель 31	user31@library.test	+79002000031	2026-10-29 08:23:47.578089
35	3	user32	d21dbd2c4e178b2cb55dce0c6a43effc	Читатель 32	user32@library.test	+79002000032	2026-10-29 08:23:47.578089
36	3	user33	c6f273ac241a04216e0a703c18c36532	Читатель 33	user33@library.test	+79002000033	2026-10-29 08:23:47.578089
37	3	user34	9ece8c4020f8aed10676cd1c56a41889	Читатель 34	user34@library.test	+79002000034	2026-10-29 08:23:47.578089
38	3	user35	8cd5a487792e95045574fe205e4efdf9	Читатель 35	user35@library.test	+79002000035	2026-10-29 08:23:47.578089
39	3	user36	41a2abe109f243e12e72133cf46ea5db	Читатель 36	user36@library.test	+79002000036	2026-10-29 08:23:47.578089
40	3	user37	657bc81a9e2fba4293ed712d02a82191	Читатель 37	user37@library.test	+79002000037	2026-10-29 08:23:47.578089
41	3	user38	e6f3956464556eb0f7e310ccfaebe1d1	Читатель 38	user38@library.test	+79002000038	2026-10-29 08:23:47.578089
42	3	user39	89a0afa8bca03ba74e75fe1e36d1a431	Читатель 39	user39@library.test	+79002000039	2026-10-29 08:23:47.578089
43	3	user40	3695b09d29f3d88d21ad2bbfc230edae	Читатель 40	user40@library.test	+79002000040	2026-10-29 08:23:47.578089
\.


--
-- TOC entry 3580 (class 0 OID 0)
-- Dependencies: 225
-- Name: authors_author_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.authors_author_id_seq', 40, true);


--
-- TOC entry 3581 (class 0 OID 0)
-- Dependencies: 231
-- Name: books_book_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.books_book_id_seq', 120, true);


--
-- TOC entry 3582 (class 0 OID 0)
-- Dependencies: 223
-- Name: genres_genre_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.genres_genre_id_seq', 8, true);


--
-- TOC entry 3583 (class 0 OID 0)
-- Dependencies: 221
-- Name: loan_statuses_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.loan_statuses_status_id_seq', 4, true);


--
-- TOC entry 3584 (class 0 OID 0)
-- Dependencies: 233
-- Name: loans_loan_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.loans_loan_id_seq', 150, true);


--
-- TOC entry 3585 (class 0 OID 0)
-- Dependencies: 227
-- Name: publishers_publisher_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.publishers_publisher_id_seq', 10, true);


--
-- TOC entry 3586 (class 0 OID 0)
-- Dependencies: 219
-- Name: roles_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.roles_role_id_seq', 3, true);


--
-- TOC entry 3587 (class 0 OID 0)
-- Dependencies: 229
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kisssrm
--

SELECT pg_catalog.setval('public.users_user_id_seq', 43, true);


--
-- TOC entry 3372 (class 2606 OID 16959)
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);


--
-- TOC entry 3384 (class 2606 OID 17021)
-- Name: books books_isbn_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_isbn_key UNIQUE (isbn);


--
-- TOC entry 3386 (class 2606 OID 17019)
-- Name: books books_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- TOC entry 3368 (class 2606 OID 16950)
-- Name: genres genres_name_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_name_key UNIQUE (name);


--
-- TOC entry 3370 (class 2606 OID 16948)
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- TOC entry 3364 (class 2606 OID 16939)
-- Name: loan_statuses loan_statuses_name_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loan_statuses
    ADD CONSTRAINT loan_statuses_name_key UNIQUE (name);


--
-- TOC entry 3366 (class 2606 OID 16937)
-- Name: loan_statuses loan_statuses_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loan_statuses
    ADD CONSTRAINT loan_statuses_pkey PRIMARY KEY (status_id);


--
-- TOC entry 3391 (class 2606 OID 17051)
-- Name: loans loans_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_pkey PRIMARY KEY (loan_id);


--
-- TOC entry 3374 (class 2606 OID 16970)
-- Name: publishers publishers_name_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_name_key UNIQUE (name);


--
-- TOC entry 3376 (class 2606 OID 16968)
-- Name: publishers publishers_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.publishers
    ADD CONSTRAINT publishers_pkey PRIMARY KEY (publisher_id);


--
-- TOC entry 3360 (class 2606 OID 16928)
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- TOC entry 3362 (class 2606 OID 16926)
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (role_id);


--
-- TOC entry 3378 (class 2606 OID 16992)
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- TOC entry 3380 (class 2606 OID 16990)
-- Name: users users_login_key; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_login_key UNIQUE (login);


--
-- TOC entry 3382 (class 2606 OID 16988)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- TOC entry 3387 (class 1259 OID 17075)
-- Name: idx_books_title; Type: INDEX; Schema: public; Owner: kisssrm
--

CREATE INDEX idx_books_title ON public.books USING btree (title);


--
-- TOC entry 3388 (class 1259 OID 17077)
-- Name: idx_loans_book; Type: INDEX; Schema: public; Owner: kisssrm
--

CREATE INDEX idx_loans_book ON public.loans USING btree (book_id);


--
-- TOC entry 3389 (class 1259 OID 17076)
-- Name: idx_loans_user; Type: INDEX; Schema: public; Owner: kisssrm
--

CREATE INDEX idx_loans_user ON public.loans USING btree (user_id);


--
-- TOC entry 3401 (class 2620 OID 17073)
-- Name: books trg_books_id; Type: TRIGGER; Schema: public; Owner: kisssrm
--

CREATE TRIGGER trg_books_id BEFORE UPDATE ON public.books FOR EACH ROW EXECUTE FUNCTION public.forbid_id_change('book_id');


--
-- TOC entry 3402 (class 2620 OID 17074)
-- Name: loans trg_loans_id; Type: TRIGGER; Schema: public; Owner: kisssrm
--

CREATE TRIGGER trg_loans_id BEFORE UPDATE ON public.loans FOR EACH ROW EXECUTE FUNCTION public.forbid_id_change('loan_id');


--
-- TOC entry 3400 (class 2620 OID 17072)
-- Name: users trg_users_id; Type: TRIGGER; Schema: public; Owner: kisssrm
--

CREATE TRIGGER trg_users_id BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.forbid_id_change('user_id');


--
-- TOC entry 3393 (class 2606 OID 17022)
-- Name: books books_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.authors(author_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3394 (class 2606 OID 17027)
-- Name: books books_genre_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES public.genres(genre_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3395 (class 2606 OID 17032)
-- Name: books books_publisher_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.books
    ADD CONSTRAINT books_publisher_id_fkey FOREIGN KEY (publisher_id) REFERENCES public.publishers(publisher_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3396 (class 2606 OID 17057)
-- Name: loans loans_book_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(book_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3397 (class 2606 OID 17067)
-- Name: loans loans_manager_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_manager_id_fkey FOREIGN KEY (manager_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 3398 (class 2606 OID 17062)
-- Name: loans loans_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.loan_statuses(status_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3399 (class 2606 OID 17052)
-- Name: loans loans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.loans
    ADD CONSTRAINT loans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 3392 (class 2606 OID 16993)
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: kisssrm
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(role_id) ON UPDATE CASCADE ON DELETE RESTRICT;


-- Completed on 2026-10-29 13:32:42

--
-- PostgreSQL database dump complete
--

\unrestrict ozZlyhpaiP7OKeHyPbYMXIarCtYjtJeo5Ob8vBsgV8n3ImvHcu8cmfcMviGLLyS

--
-- Database "postgres" dump
--

\connect postgres

--
-- PostgreSQL database dump
--

\restrict p6A4VTHNtR68UpgilYTu6mEwIhrITgRYszg6iz42mVsKBU01JXw4afwwfSERCu2

-- Dumped from database version 18.6 (Debian 18.6-1.pgdg13+2)
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-29 13:32:42

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

-- Completed on 2026-10-29 13:32:42

--
-- PostgreSQL database dump complete
--

\unrestrict p6A4VTHNtR68UpgilYTu6mEwIhrITgRYszg6iz42mVsKBU01JXw4afwwfSERCu2

-- Completed on 2026-10-29 13:32:42

--
-- PostgreSQL database cluster dump complete
--

