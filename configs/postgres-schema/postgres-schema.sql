--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4
-- Dumped by pg_dump version 11.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: get_session(text); Type: FUNCTION; Schema: public; Owner: todor
--

CREATE FUNCTION public.get_session(session_id text) RETURNS TABLE(commands text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY select input from logstash where session=session_id and event_id='cowrie.command.input' order by ts asc;
END;
$$;


ALTER FUNCTION public.get_session(session_id text) OWNER TO todor;

--
-- Name: refreshallmaterializedviews(text); Type: FUNCTION; Schema: public; Owner: todor
--

CREATE FUNCTION public.refreshallmaterializedviews(schema_arg text DEFAULT 'public'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
r RECORD;
BEGIN
RAISE NOTICE 'Refreshing materialized view in schema %', schema_arg;
FOR r IN SELECT matviewname FROM pg_matviews WHERE schemaname = schema_arg 
LOOP
RAISE NOTICE 'Refreshing %.%', schema_arg, r.matviewname;
EXECUTE 'REFRESH MATERIALIZED VIEW ' || schema_arg || '.' || r.matviewname; 
END LOOP;

RETURN 1;
END 
$$;


ALTER FUNCTION public.refreshallmaterializedviews(schema_arg text) OWNER TO todor;

--
-- Name: refreshallmaterializedviewsconcurrently(text); Type: FUNCTION; Schema: public; Owner: todor
--

CREATE FUNCTION public.refreshallmaterializedviewsconcurrently(schema_arg text DEFAULT 'public'::text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
    DECLARE
        r RECORD;
    BEGIN
        RAISE NOTICE 'Refreshing materialized view in schema %', schema_arg;
        FOR r IN SELECT matviewname FROM pg_matviews WHERE schemaname = schema_arg
        LOOP
            RAISE NOTICE 'Refreshing %.%', schema_arg, r.matviewname;
            EXECUTE 'REFRESH MATERIALIZED VIEW CONCURRENTLY ' || schema_arg || '.' || r.matviewname;
        END LOOP;

        RETURN 1;
    END
$$;


ALTER FUNCTION public.refreshallmaterializedviewsconcurrently(schema_arg text) OWNER TO todor;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: logstash; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.logstash (
    ts timestamp without time zone,
    session character varying(16),
    aws_region text,
    event_id text,
    duration double precision,
    instance_id character varying(32),
    input text,
    outfile text,
    cowrie_ip inet,
    src_ip inet,
    src_port integer,
    dst_port integer,
    size bigint,
    cowrie_kernel_version text,
    cowrie_kernel_build text,
    cowrie_elf_arch text,
    cowrie_hardware_platform text,
    protocol text,
    cowrie_config text
);


ALTER TABLE public.logstash OWNER TO todor;

--
-- Name: gen1; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen1 AS
 SELECT logstash.ts,
    logstash.session,
    logstash.aws_region,
    logstash.event_id,
    logstash.duration,
    logstash.instance_id,
    logstash.input,
    logstash.outfile,
    logstash.cowrie_ip,
    logstash.src_ip,
    logstash.src_port,
    logstash.dst_port,
    logstash.size,
    logstash.cowrie_kernel_version,
    logstash.cowrie_kernel_build,
    logstash.cowrie_elf_arch,
    logstash.cowrie_hardware_platform,
    logstash.protocol
   FROM public.logstash
  WHERE ((logstash.ts > '2018-03-27 00:00:00'::timestamp without time zone) AND (logstash.ts < '2018-04-18 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen1 OWNER TO todor;

--
-- Name: hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.hourly_events AS
 SELECT date_trunc('hour'::text, (logstash.ts - '00:01:00'::interval)) AS "time",
    logstash.event_id,
    count(logstash.event_id) AS count
   FROM public.logstash
  GROUP BY (date_trunc('hour'::text, (logstash.ts - '00:01:00'::interval))), logstash.event_id
  ORDER BY (date_trunc('hour'::text, (logstash.ts - '00:01:00'::interval)))
  WITH NO DATA;


ALTER TABLE public.hourly_events OWNER TO todor;

--
-- Name: gen1_hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen1_hourly_events AS
 SELECT hourly_events."time",
    hourly_events.event_id,
    hourly_events.count
   FROM public.hourly_events
  WHERE ((hourly_events."time" > '2018-03-27 00:00:00'::timestamp without time zone) AND (hourly_events."time" < '2018-04-18 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen1_hourly_events OWNER TO todor;

--
-- Name: hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.hourly_sessions AS
 SELECT date_trunc('hour'::text, (logstash.ts - '00:01:00'::interval)) AS "time",
    count(DISTINCT logstash.session) AS sessions
   FROM public.logstash
  GROUP BY (date_trunc('hour'::text, (logstash.ts - '00:01:00'::interval)))
  ORDER BY (date_trunc('hour'::text, (logstash.ts - '00:01:00'::interval)))
  WITH NO DATA;


ALTER TABLE public.hourly_sessions OWNER TO todor;

--
-- Name: gen1_hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen1_hourly_sessions AS
 SELECT hourly_sessions."time",
    hourly_sessions.sessions
   FROM public.hourly_sessions
  WHERE ((hourly_sessions."time" > '2018-03-27 00:00:00'::timestamp without time zone) AND (hourly_sessions."time" < '2018-04-18 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen1_hourly_sessions OWNER TO todor;

--
-- Name: gen2; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen2 AS
 SELECT logstash.ts,
    logstash.session,
    logstash.aws_region,
    logstash.event_id,
    logstash.duration,
    logstash.instance_id,
    logstash.input,
    logstash.outfile,
    logstash.cowrie_ip,
    logstash.src_ip,
    logstash.src_port,
    logstash.dst_port,
    logstash.size,
    logstash.cowrie_kernel_version,
    logstash.cowrie_kernel_build,
    logstash.cowrie_elf_arch,
    logstash.cowrie_hardware_platform,
    logstash.protocol
   FROM public.logstash
  WHERE ((logstash.ts > '2018-05-15 00:00:00'::timestamp without time zone) AND (logstash.ts < '2018-06-04 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen2 OWNER TO todor;

--
-- Name: gen2_hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen2_hourly_events AS
 SELECT hourly_events."time",
    hourly_events.event_id,
    hourly_events.count
   FROM public.hourly_events
  WHERE ((hourly_events."time" > '2018-05-15 00:00:00'::timestamp without time zone) AND (hourly_events."time" < '2018-06-04 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen2_hourly_events OWNER TO todor;

--
-- Name: gen2_hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen2_hourly_sessions AS
 SELECT hourly_sessions."time",
    hourly_sessions.sessions
   FROM public.hourly_sessions
  WHERE ((hourly_sessions."time" > '2018-05-15 00:00:00'::timestamp without time zone) AND (hourly_sessions."time" < '2018-06-04 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen2_hourly_sessions OWNER TO todor;

--
-- Name: gen3; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen3 AS
 SELECT logstash.ts,
    logstash.session,
    logstash.aws_region,
    logstash.event_id,
    logstash.duration,
    logstash.instance_id,
    logstash.input,
    logstash.outfile,
    logstash.cowrie_ip,
    logstash.src_ip,
    logstash.src_port,
    logstash.dst_port,
    logstash.size,
    logstash.cowrie_kernel_version,
    logstash.cowrie_kernel_build,
    logstash.cowrie_elf_arch,
    logstash.cowrie_hardware_platform,
    logstash.protocol
   FROM public.logstash
  WHERE ((logstash.ts > '2018-06-10 00:00:00'::timestamp without time zone) AND (logstash.ts < '2018-07-02 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen3 OWNER TO todor;

--
-- Name: gen3_hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen3_hourly_events AS
 SELECT hourly_events."time",
    hourly_events.event_id,
    hourly_events.count
   FROM public.hourly_events
  WHERE ((hourly_events."time" > '2018-06-10 00:00:00'::timestamp without time zone) AND (hourly_events."time" < '2018-07-02 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen3_hourly_events OWNER TO todor;

--
-- Name: gen3_hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen3_hourly_sessions AS
 SELECT hourly_sessions."time",
    hourly_sessions.sessions
   FROM public.hourly_sessions
  WHERE ((hourly_sessions."time" > '2018-06-10 00:00:00'::timestamp without time zone) AND (hourly_sessions."time" < '2018-07-02 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen3_hourly_sessions OWNER TO todor;

--
-- Name: gen4; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen4 AS
 SELECT logstash.ts,
    logstash.session,
    logstash.aws_region,
    logstash.event_id,
    logstash.duration,
    logstash.instance_id,
    logstash.input,
    logstash.outfile,
    logstash.cowrie_ip,
    logstash.src_ip,
    logstash.src_port,
    logstash.dst_port,
    logstash.size,
    logstash.cowrie_kernel_version,
    logstash.cowrie_kernel_build,
    logstash.cowrie_elf_arch,
    logstash.cowrie_hardware_platform,
    logstash.protocol
   FROM public.logstash
  WHERE ((logstash.ts > '2018-07-19 00:00:00'::timestamp without time zone) AND (logstash.ts < '2018-07-21 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen4 OWNER TO todor;

--
-- Name: gen4_hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen4_hourly_events AS
 SELECT hourly_events."time",
    hourly_events.event_id,
    hourly_events.count
   FROM public.hourly_events
  WHERE ((hourly_events."time" > '2018-07-19 00:00:00'::timestamp without time zone) AND (hourly_events."time" < '2018-07-21 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen4_hourly_events OWNER TO todor;

--
-- Name: gen4_hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen4_hourly_sessions AS
 SELECT hourly_sessions."time",
    hourly_sessions.sessions
   FROM public.hourly_sessions
  WHERE ((hourly_sessions."time" > '2018-07-19 00:00:00'::timestamp without time zone) AND (hourly_sessions."time" < '2018-07-21 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen4_hourly_sessions OWNER TO todor;

--
-- Name: gen5; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen5 AS
 SELECT logstash.ts,
    logstash.session,
    logstash.aws_region,
    logstash.event_id,
    logstash.duration,
    logstash.instance_id,
    logstash.input,
    logstash.outfile,
    logstash.cowrie_ip,
    logstash.src_ip,
    logstash.src_port,
    logstash.dst_port,
    logstash.size,
    logstash.cowrie_kernel_version,
    logstash.cowrie_kernel_build,
    logstash.cowrie_elf_arch,
    logstash.cowrie_hardware_platform,
    logstash.protocol
   FROM public.logstash
  WHERE ((logstash.ts > '2019-07-11 00:00:00'::timestamp without time zone) AND (logstash.ts < '2019-07-17 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen5 OWNER TO todor;

--
-- Name: gen5_hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen5_hourly_events AS
 SELECT hourly_events."time",
    hourly_events.event_id,
    hourly_events.count
   FROM public.hourly_events
  WHERE ((hourly_events."time" > '2019-07-11 00:00:00'::timestamp without time zone) AND (hourly_events."time" < '2019-07-17 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen5_hourly_events OWNER TO todor;

--
-- Name: gen5_hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen5_hourly_sessions AS
 SELECT hourly_sessions."time",
    hourly_sessions.sessions
   FROM public.hourly_sessions
  WHERE ((hourly_sessions."time" > '2019-07-11 00:00:00'::timestamp without time zone) AND (hourly_sessions."time" < '2019-07-17 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen5_hourly_sessions OWNER TO todor;

--
-- Name: gen6; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen6 AS
 SELECT logstash.ts,
    logstash.session,
    logstash.aws_region,
    logstash.event_id,
    logstash.duration,
    logstash.instance_id,
    logstash.input,
    logstash.outfile,
    logstash.cowrie_ip,
    logstash.src_ip,
    logstash.src_port,
    logstash.dst_port,
    logstash.size,
    logstash.cowrie_kernel_version,
    logstash.cowrie_kernel_build,
    logstash.cowrie_elf_arch,
    logstash.cowrie_hardware_platform,
    logstash.protocol
   FROM public.logstash
  WHERE ((logstash.ts > '2019-07-30 00:00:00'::timestamp without time zone) AND (logstash.ts < '2019-08-05 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen6 OWNER TO todor;

--
-- Name: gen6_hourly_events; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen6_hourly_events AS
 SELECT hourly_events."time",
    hourly_events.event_id,
    hourly_events.count
   FROM public.hourly_events
  WHERE ((hourly_events."time" > '2019-07-30 00:00:00'::timestamp without time zone) AND (hourly_events."time" < '2019-08-05 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen6_hourly_events OWNER TO todor;

--
-- Name: gen6_hourly_sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.gen6_hourly_sessions AS
 SELECT hourly_sessions."time",
    hourly_sessions.sessions
   FROM public.hourly_sessions
  WHERE ((hourly_sessions."time" > '2019-07-30 00:00:00'::timestamp without time zone) AND (hourly_sessions."time" < '2019-08-05 23:59:59'::timestamp without time zone))
  WITH NO DATA;


ALTER TABLE public.gen6_hourly_sessions OWNER TO todor;

--
-- Name: generations; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.generations (
    index integer,
    start_ts timestamp without time zone,
    end_ts timestamp without time zone
);


ALTER TABLE public.generations OWNER TO todor;

--
-- Name: malware_report; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.malware_report (
    sha256 text NOT NULL,
    vt_report json NOT NULL,
    type character varying,
    platform character varying(32)
);


ALTER TABLE public.malware_report OWNER TO todor;

--
-- Name: malware_types; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.malware_types AS
 SELECT malware_report.sha256,
    (((malware_report.vt_report -> 'scans'::text) -> 'Symantec'::text) ->> 'detected'::text) AS detected,
    (((malware_report.vt_report -> 'scans'::text) -> 'Symantec'::text) ->> 'result'::text) AS result,
    malware_report.type,
    malware_report.platform
   FROM public.malware_report
  WITH NO DATA;


ALTER TABLE public.malware_types OWNER TO todor;

--
-- Name: session_dedup; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.session_dedup (
    id uuid NOT NULL,
    "time" timestamp without time zone,
    commands text[],
    sha256_sum uuid
);


ALTER TABLE public.session_dedup OWNER TO todor;

--
-- Name: session_duration; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.session_duration AS
 SELECT logstash.session,
    min(logstash.ts) AS start,
    max(logstash.ts) AS "end",
    (max(logstash.ts) - min(logstash.ts)) AS duration
   FROM public.logstash
  WHERE (logstash.event_id = 'cowrie.command.input'::text)
  GROUP BY logstash.session
  ORDER BY (min(logstash.ts))
  WITH NO DATA;


ALTER TABLE public.session_duration OWNER TO todor;

--
-- Name: session_trainer; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.session_trainer (
    sha256_hash text NOT NULL,
    trained boolean
);


ALTER TABLE public.session_trainer OWNER TO todor;

--
-- Name: sessions; Type: MATERIALIZED VIEW; Schema: public; Owner: todor
--

CREATE MATERIALIZED VIEW public.sessions AS
 SELECT logstash.session,
    min(logstash.ts) AS "timestamp"
   FROM public.logstash
  WHERE (logstash.event_id = 'cowrie.command.input'::text)
  GROUP BY logstash.session
  ORDER BY (min(logstash.ts))
  WITH NO DATA;


ALTER TABLE public.sessions OWNER TO todor;

--
-- Name: sessions_hash_map; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.sessions_hash_map (
    session text NOT NULL,
    sha256_hash text
);


ALTER TABLE public.sessions_hash_map OWNER TO todor;

--
-- Name: ssh_proxy; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.ssh_proxy (
    src inet,
    dst text,
    port integer
);

ALTER TABLE ONLY public.ssh_proxy REPLICA IDENTITY FULL;


ALTER TABLE public.ssh_proxy OWNER TO todor;

--
-- Name: tcp_data; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.tcp_data (
    source inet,
    dst text,
    dst_port integer,
    data text
);


ALTER TABLE public.tcp_data OWNER TO todor;

--
-- Name: test; Type: TABLE; Schema: public; Owner: todor
--

CREATE TABLE public.test (
    i bigint
);


ALTER TABLE public.test OWNER TO todor;

--
-- Name: generations generations_index_key; Type: CONSTRAINT; Schema: public; Owner: todor
--

ALTER TABLE ONLY public.generations
    ADD CONSTRAINT generations_index_key UNIQUE (index);


--
-- Name: malware_report malware_report_pkey; Type: CONSTRAINT; Schema: public; Owner: todor
--

ALTER TABLE ONLY public.malware_report
    ADD CONSTRAINT malware_report_pkey PRIMARY KEY (sha256);


--
-- Name: session_trainer session_trainer_pkey; Type: CONSTRAINT; Schema: public; Owner: todor
--

ALTER TABLE ONLY public.session_trainer
    ADD CONSTRAINT session_trainer_pkey PRIMARY KEY (sha256_hash);


--
-- Name: sessions_hash_map sessions_hash_map_pkey; Type: CONSTRAINT; Schema: public; Owner: todor
--

ALTER TABLE ONLY public.sessions_hash_map
    ADD CONSTRAINT sessions_hash_map_pkey PRIMARY KEY (session);


--
-- Name: malware_report unique_sha256; Type: CONSTRAINT; Schema: public; Owner: todor
--

ALTER TABLE ONLY public.malware_report
    ADD CONSTRAINT unique_sha256 UNIQUE (sha256);


--
-- Name: logstash_arch; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_arch ON public.logstash USING btree (cowrie_elf_arch);


--
-- Name: logstash_event_id; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_event_id ON public.logstash USING btree (event_id);


--
-- Name: logstash_instance_id; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_instance_id ON public.logstash USING btree (instance_id);


--
-- Name: logstash_platform; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_platform ON public.logstash USING btree (cowrie_hardware_platform);


--
-- Name: logstash_session; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_session ON public.logstash USING btree (session);


--
-- Name: logstash_src_ip; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_src_ip ON public.logstash USING btree (src_ip);


--
-- Name: logstash_ts; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_ts ON public.logstash USING btree (ts);


--
-- Name: ssh_proxy_dst; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ssh_proxy_dst ON public.ssh_proxy USING btree (dst);


--
-- Name: ssh_proxy_port; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ssh_proxy_port ON public.ssh_proxy USING btree (port);


--
-- Name: ssh_proxy_src; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ssh_proxy_src ON public.ssh_proxy USING btree (src);


--
-- Name: ts_gen1; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ts_gen1 ON public.gen1 USING btree (ts);


--
-- Name: ts_gen2; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ts_gen2 ON public.gen2 USING btree (ts);


--
-- Name: ts_gen3; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ts_gen3 ON public.gen3 USING btree (ts);


--
-- Name: ts_gen4; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX ts_gen4 ON public.gen4 USING btree (ts);


--
-- PostgreSQL database dump complete
--

