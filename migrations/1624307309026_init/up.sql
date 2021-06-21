SET check_function_bodies = false;
CREATE TABLE public."jobPostings" (
    id integer NOT NULL,
    "jobId" integer NOT NULL,
    "startDate" timestamp with time zone NOT NULL,
    "endDate" timestamp with time zone NOT NULL,
    active boolean NOT NULL,
    "paymentReference" jsonb NOT NULL
);
CREATE SEQUENCE public."jobPosting_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public."jobPosting_id_seq" OWNED BY public."jobPostings".id;
CREATE TABLE public.jobs (
    id integer NOT NULL,
    "organisationName" text NOT NULL,
    "organisationUrl" text NOT NULL,
    "jobTitle" text NOT NULL,
    "jobUrl" text NOT NULL,
    remote boolean NOT NULL,
    location text NOT NULL,
    "contactEmail" text NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    modified timestamp with time zone DEFAULT now() NOT NULL,
    academic boolean NOT NULL,
    token uuid DEFAULT public.gen_random_uuid() NOT NULL,
    "contactName" text NOT NULL,
    tags text,
    "closingDate" timestamp with time zone NOT NULL,
    withdrawn boolean DEFAULT false NOT NULL,
    approved boolean NOT NULL,
    "emailedConfirmation" boolean DEFAULT false NOT NULL
);
CREATE SEQUENCE public.job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
ALTER SEQUENCE public.job_id_seq OWNED BY public.jobs.id;
ALTER TABLE ONLY public."jobPostings" ALTER COLUMN id SET DEFAULT nextval('public."jobPosting_id_seq"'::regclass);
ALTER TABLE ONLY public.jobs ALTER COLUMN id SET DEFAULT nextval('public.job_id_seq'::regclass);
ALTER TABLE ONLY public."jobPostings"
    ADD CONSTRAINT "jobPosting_pkey" PRIMARY KEY (id);
ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.jobs
    ADD CONSTRAINT jobs_token_key UNIQUE (token);
ALTER TABLE ONLY public."jobPostings"
    ADD CONSTRAINT "jobPosting_jobId_fkey" FOREIGN KEY ("jobId") REFERENCES public.jobs(id) ON UPDATE RESTRICT ON DELETE RESTRICT;
