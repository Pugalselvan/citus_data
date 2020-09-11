//To download sample data

/curl https://examples.citusdata.com/tutorial/users.csv > users.csv
/curl https://examples.citusdata.com/tutorial/events.csv > events.csv

// start the server
/usr/lib/postgresql/12/bin/pg_ctl -D /var/lib/postgresql/citus/coordinator start
 
/usr/lib/postgresql/12/bin/pg_ctl -D /var/lib/postgresql/citus/worker1 start

/usr/lib/postgresql/12/bin/pg_ctl -D /var/lib/postgresql/citus/worker2 start

 psql -p 5433 -d postgres
//create extension for all cluster
CREATE EXTENSION CITUS;

//adding node to coordinator

SELECT * from master_add_node('localhost', 5434);
SELECT * from master_add_node('localhost', 5435);
select * from master_get_active_worker_nodes();

//coordinator port running on :5433

CREATE TABLE github_events
(
    event_id bigint,
    event_type text,
    event_public boolean,
    repo_id bigint,
    payload jsonb,
    repo jsonb,
    user_id bigint,
    org jsonb,
    created_at timestamp
);

CREATE TABLE github_users
(
    user_id bigint,
    url text,
    login text,
    avatar_url text,
    gravatar_id text,
    display_login text
);

CREATE INDEX event_type_index ON github_events (event_type);
CREATE INDEX payload_index ON github_events USING GIN (payload jsonb_path_ops);

// to distribute the tables in the worker nodes

SELECT create_distributed_table('github_users', 'user_id');
SELECT create_distributed_table('github_events', 'user_id');

//load the data into the tables using \copy command

\copy github_users from '/home/pugal/Documents/users.csv' with csv
\copy github_events from '/home/pugal/Documents/events.csv' with csv


// sample queries

SELECT date_trunc('minute', created_at) AS minute,
       sum((payload->>'distinct_size')::int) AS num_commits
FROM github_events
WHERE event_type = 'PushEvent'
GROUP BY minute
ORDER BY minute;

SELECT login, count(*)
FROM github_events ge
JOIN github_users gu
ON ge.user_id = gu.user_id
WHERE event_type = 'CreateEvent' AND payload @> '{"ref_type": "repository"}'
GROUP BY login
ORDER BY count(*) DESC LIMIT 10;

UPDATE github_users SET display_login = 'no1youknow' WHERE user_id = 24305673;

\d //run this command to view the list of distributed tables







