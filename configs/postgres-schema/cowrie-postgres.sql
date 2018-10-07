--
-- PostgreSQL database dump
--

-- Dumped from database version 10.5
-- Dumped by pg_dump version 10.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


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
    protocol text
);


ALTER TABLE public.logstash OWNER TO todor;

--
-- Name: logstash_arch; Type: INDEX; Schema: public; Owner: todor
--

CREATE INDEX logstash_arch ON public.logstash USING btree (cowrie_elf_arch);


--
-- Name: logstash_eveit_id; Type: INDEX; Schema: public; Owner: todor
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
-- PostgreSQL database dump complete
--

