-- JAVA DONE
CREATE OR REPLACE FUNCTION create_tweet(tweet_text varchar(140), creator_id integer, created_at timestamp, image_url varchar(100) DEFAULT null)
RETURNS SETOF tweets AS $$
  BEGIN
    INSERT INTO tweets(tweet_text, creator_id, created_at, image_url) VALUES (tweet_text, creator_id, created_at, image_url);
    return query
    SELECT * FROM tweets WHERE id = CURRVAL(pg_get_serial_sequence('tweets','id'));
    END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION delete_tweet(tweet_id integer)
RETURNS void AS $$
  BEGIN
    DELETE FROM tweets T WHERE T.id = tweet_id;
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE / JSON DONE
CREATE OR REPLACE FUNCTION get_tweet(tweet_id integer)
RETURNS refcursor AS $$
DECLARE cursor refcursor := 'cur';
  BEGIN
    OPEN cursor FOR
    SELECT T.*, U.username, U.name, U.avatar_url, get_retweets_count(tweet_id) AS "retweets", get_favorites_count(tweet_id) AS "favorites"
    FROM tweets T INNER JOIN users U ON T.creator_id = U.id
    WHERE T.id = tweet_id;
    RETURN cursor;
  END; $$
LANGUAGE PLPGSQL;

-- NOT USED
CREATE OR REPLACE FUNCTION get_retweets(tweet_id integer)
RETURNS refcursor AS $$
DECLARE cursor refcursor := 'cur';
  BEGIN
    OPEN cursor FOR
    SELECT U.username, U.name, U.avatar_url
    FROM retweets R INNER JOIN users U ON R.user_id = U.id
    WHERE R.tweet_id = $1
    LIMIT 6;
    RETURN cursor;
  END; $$
LANGUAGE PLPGSQL;

-- NOT USED
CREATE OR REPLACE FUNCTION get_favorites(tweet_id integer)
RETURNS refcursor AS $$
DECLARE cursor refcursor := 'cur';
  BEGIN
    OPEN cursor FOR
    SELECT U.username, U.name, U.avatar_url
    FROM favorites F INNER JOIN users U ON F.user_id = U.id
    WHERE F.tweet_id = $1
    LIMIT 6;
    RETURN cursor;
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION favorite(tweet_id integer, user_id integer, created_at timestamp)
RETURNS integer AS $$
  BEGIN
    INSERT INTO favorites(tweet_id, user_id, created_at) VALUES (tweet_id, user_id, created_at);
    RETURN get_favorites_count(tweet_id);
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION unfavorite(tweet_id integer, user_id integer)
RETURNS integer AS $$
  BEGIN
    DELETE FROM favorites F WHERE F.tweet_id = $1 AND F.user_id = $2;
    RETURN get_favorites_count(tweet_id);
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION retweet(tweet_id integer, user_id integer, created_at timestamp)
RETURNS integer AS $$
DECLARE temp integer;
  BEGIN
    SELECT T.creator_id INTO temp FROM tweets T WHERE T.id = $1 LIMIT 1;
    IF temp != user_id THEN
      INSERT INTO retweets(tweet_id, creator_id, retweeter_id, created_at) VALUES (tweet_id, temp, user_id, created_at);
    END IF;
    RETURN get_retweets_count(tweet_id);
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION unretweet(tweet_id integer, user_id integer)
RETURNS integer AS $$
  BEGIN
    DELETE FROM retweets R WHERE R.tweet_id = $1 AND R.retweeter_id = $2;
    RETURN get_retweets_count(tweet_id);
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION get_retweets_count(tweet_id integer)
RETURNS integer AS $$
DECLARE res integer;
  BEGIN
    SELECT count(*) INTO res FROM retweets R WHERE R.tweet_id = $1;
    RETURN res;
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION get_favorites_count(tweet_id integer)
RETURNS integer AS $$
DECLARE res integer;
  BEGIN
    SELECT count(*) INTO res FROM favorites F WHERE F.tweet_id = $1;
    RETURN res;
  END; $$
LANGUAGE PLPGSQL;

-- JAVA / JSON DONE
CREATE OR REPLACE FUNCTION reply(tweet_id integer, tweet_text varchar(140), creator_id integer, created_at timestamp, image_url varchar(100) DEFAULT null)
RETURNS void AS $$
DECLARE reply_id integer;
  BEGIN
    SELECT id FROM create_tweet(tweet_text, creator_id, created_at, image_url) INTO reply_id;
    INSERT INTO replies(original_tweet_id, reply_id, created_at) VALUES (tweet_id, reply_id, created_at);
  END; $$
LANGUAGE PLPGSQL;

-- JAVA DONE
CREATE OR REPLACE FUNCTION report_tweet(reported_id integer, creator_id integer, created_at timestamp)
RETURNS void AS $$
  BEGIN
    INSERT INTO reports(reported_id, creator_id, created_at) VALUES (reported_id, creator_id, created_at);
  END; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION get_earliest_replies(tweet_id integer, user_id integer)
RETURNS refcursor AS $$
DECLARE cursor refcursor := 'cur';
DECLARE favorite integer;
DECLARE retweet integer;
  BEGIN
    SELECT COUNT(*) INTO favorite FROM favorites F
    WHERE F.tweet_id = $1 AND F.user_id = $2;
    SELECT COUNT(*) INTO retweet FROM retweets rt
    WHERE rt.tweet_id = $1 AND rt.retweeter_id = $2;

    OPEN cursor FOR
    SELECT U.id, U.username, U.name, U.avatar_url, R.reply_id, T2.tweet_text, T2.image_url, favorite, retweet, T2.created_at
    FROM replies R INNER JOIN tweets T ON R.original_tweet_id = T.id
    INNER JOIN users U ON T.creator_id = U.id
    INNER JOIN tweets T2 ON R.reply_id = T2.id
    WHERE R.original_tweet_id = $1
    ORDER BY T2.created_at ASC
    LIMIT 4;
    RETURN cursor;
  END; $$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION get_replies(tweet_id integer)
RETURNS refcursor AS $$
DECLARE cursor refcursor := 'cur';
  BEGIN
    OPEN cursor FOR
    SELECT U.id, U.username, U.name, U.avatar_url, R.reply_id, T2.tweet_text, T2.image_url, T2.created_at
    FROM replies R INNER JOIN tweets T ON R.original_tweet_id = T.id
    INNER JOIN users U ON T.creator_id = U.id
    INNER JOIN tweets T2 ON R.reply_id = T2.id
    WHERE R.original_tweet_id = $1
    ORDER BY T2.created_at ASC;
    RETURN cursor;
  END; $$
LANGUAGE PLPGSQL;
