CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
SET search_path = public, pg_catalog;

CREATE FUNCTION update_updated_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at= now();
  RETURN NEW;
END;
$$;

-- ALTER FUNCTION public.update_updated_column() OWNER TO postgres;

CREATE TABLE w_acl (
    pattern character varying(100) NOT NULL,
    actor character varying(100) NOT NULL,
    mode integer DEFAULT 0 NOT NULL
);

CREATE TABLE w_pages (
    id integer NOT NULL,
    rev integer DEFAULT 0 NOT NULL,
    name character varying(255) NOT NULL,
    body text NOT NULL,
    author integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);

CREATE TABLE w_users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone,
    url character varying(255),
    body text
);

CREATE SEQUENCE w_pages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE w_pages_id_seq OWNED BY w_pages.id;

CREATE SEQUENCE w_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE w_users_id_seq OWNED BY w_users.id;

ALTER TABLE ONLY w_pages ALTER COLUMN id SET DEFAULT nextval('w_pages_id_seq'::regclass);
ALTER TABLE ONLY w_users ALTER COLUMN id SET DEFAULT nextval('w_users_id_seq'::regclass);


COPY w_acl (pattern, actor, mode) FROM stdin;
secret:.*	0	0
secret:.*	1	2
wheee:.*	0	1
.*	1	2
wheee:.*	1	2
.*	0	2
\.


COPY w_pages (id, rev, name, body, author, created_at) FROM stdin;
2	1	secret:test	A non-public test page!	1	2015-03-12 21:46:14.788051
5	2	foo	some text4\n\n  * a list with\n  * stuff\n  * yeah	1	2017-01-08 19:49:18.41597
4	1	foo	# Header\nhtext	1	2015-03-03 23:49:16.230103
1	1	wheee:index	Welcome to *[wheee](https://github.com/winks/wheee)*, a wiki written in Lua, with Lapis and Postgres.	1	2016-04-17 10:38:34.253348
3	2	wheee:index	Welcome to *[wheee](https://github.com/winks/wheee)*, a wiki written in [Lua](https://www.lua.org/), with [Lapis](http://leafo.net/lapis/) and [Postgres](http://www.postgresql.org/).	1	2016-04-17 10:39:36.252761
\.
SELECT pg_catalog.setval('w_pages_id_seq', 5, true);


-- password is 'wheeeIsAwesome'
COPY w_users (id, username, password, email, created_at, updated_at, url, body) FROM stdin;
2	randomuser	$2b$09$p7lhFrPhodk1d6rf.UhyGurJDFV.lUEVCqAHBN8BaibY1N0sIDtVC	randomuser@example.org	2015-03-02 23:23:23	2015-03-04 23:55:55.589147		Random User\N
1	wheee	$2b$09$p7lhFrPhodk1d6rf.UhyGurJDFV.lUEVCqAHBN8BaibY1N0sIDtVC	wheee@example.org	2015-03-02 23:23:23	2017-01-08 19:48:23.785384	http://example.org	This *is* **a** test!\n\nTEEEST yes
\.

SELECT pg_catalog.setval('w_users_id_seq', 4, true);


ALTER TABLE ONLY w_acl
    ADD CONSTRAINT w_acl_pkey PRIMARY KEY (pattern, actor);

ALTER TABLE ONLY w_pages
    ADD CONSTRAINT w_pages_pkey PRIMARY KEY (id);

ALTER TABLE ONLY w_users
    ADD CONSTRAINT w_users_pkey PRIMARY KEY (id);


CREATE UNIQUE INDEX w_pages_rev ON w_pages USING btree (name, rev);
CREATE UNIQUE INDEX w_users_email ON w_users USING btree (email);
CREATE UNIQUE INDEX w_users_username ON w_users USING btree (username);

CREATE TRIGGER update_w_users_updated BEFORE UPDATE ON w_users FOR EACH ROW EXECUTE PROCEDURE update_updated_column();
