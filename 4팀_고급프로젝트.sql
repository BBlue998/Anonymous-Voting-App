-- 전체 결제 성공/실패 비율
SELECT
  SUM(CASE WHEN t.status = 'success' THEN 1 ELSE 0 END) AS success_cnt,
  SUM(CASE WHEN t.status = 'fail' THEN 1 ELSE 0 END) AS fail_cnt,
  SUM(CASE WHEN t.status = 'success' THEN 1 ELSE 0 END)
    / COUNT(*) AS success_rate,
  SUM(CASE WHEN t.status = 'fail' THEN 1 ELSE 0 END)
    / COUNT(*) AS fail_rate
FROM (
  SELECT 'success' AS status FROM accounts_paymenthistory
  UNION ALL
  SELECT 'fail' AS status FROM accounts_failpaymenthistory
) t;

-- OS 별 결제 성공률
SELECT
  phone_type,
  SUM(status = 'success') AS success_cnt,
  SUM(status = 'fail') AS fail_cnt,
  SUM(status = 'success') / COUNT(*) AS success_rate
FROM (
  SELECT phone_type, 'success' AS status FROM accounts_paymenthistory
  UNION ALL
  SELECT phone_type, 'fail' AS status FROM accounts_failpaymenthistory
) t
GROUP BY phone_type;

-- 첫결제까지 걸리는 시간 평균
WITH first_payment AS (
  SELECT
    user_id,
    MIN(created_at) AS first_payment_at
  FROM accounts_paymenthistory
  GROUP BY user_id
)
SELECT
  AVG(TIMESTAMPDIFF(HOUR, u.created_at, fp.first_payment_at)) AS avg_hours_to_first_payment,
  AVG(TIMESTAMPDIFF(DAY, u.created_at, fp.first_payment_at)) AS avg_days_to_first_payment
FROM first_payment fp
JOIN accounts_user u
  ON u.id = fp.user_id;

-- accounts_
SELECT
  gender,
  COUNT(*) AS users
FROM accounts_user
GROUP BY gender
ORDER BY users DESC;

-- 성별 기준 투표향동 유저 비중
SELECT
  u.gender,
  COUNT(*) AS total_users,
  COUNT(DISTINCT v.user_id) AS voters,
  COUNT(DISTINCT v.user_id) / COUNT(*) AS voter_rate
FROM accounts_user u
LEFT JOIN accounts_userquestionrecord v
  ON v.user_id = u.id
GROUP BY u.gender;

-- 성별 결제 행동 유저 비율 
SELECT
  u.gender,
  COUNT(*) AS total_users,
  COUNT(DISTINCT p.user_id) AS payers,
  COUNT(DISTINCT p.user_id) / COUNT(*) AS payer_rate
FROM accounts_user u
LEFT JOIN accounts_paymenthistory p
  ON p.user_id = u.id
GROUP BY u.gender;

-- 신고
SELECT
  gender,
  COUNT(*) AS total_users,
  SUM(report_count > 0) AS reported_users,
  SUM(report_count > 0) / COUNT(*) AS reported_user_rate,
  AVG(report_count) AS avg_report_count
FROM accounts_user
GROUP BY gender;

-- 정상.차단.탈퇴 비중
SELECT
  ban_status,
  COUNT(*) AS users,
  COUNT(*) / (SELECT COUNT(*) FROM accounts_user) AS user_ratio
FROM accounts_user
GROUP BY ban_status
ORDER BY users DESC;

-- 신고 분포
SELECT
  report_count,
  COUNT(*) AS users
FROM accounts_user
GROUP BY report_count
ORDER BY report_count;
-- 버킷
SELECT
  CASE
    WHEN report_count = 0 THEN '0'
    WHEN report_count = 1 THEN '1'
    WHEN report_count BETWEEN 2 AND 3 THEN '2-3'
    WHEN report_count BETWEEN 4 AND 9 THEN '4-9'
    WHEN report_count BETWEEN 10 AND 15 THEN '10-15'
    WHEN report_count BETWEEN 15 AND 20 THEN '15-20'
    WHEN report_count BETWEEN 20 AND 30 THen '20-30'
    WHEN report_count BETWEEN 30 AND 50 THEN '30-50'
    ELSE '50+'
  END AS report_bucket,
  COUNT(*) AS users,
  COUNT(*) / (SELECT COUNT(*) FROM accounts_user) AS user_ratio
FROM accounts_user
GROUP BY report_bucket
ORDER BY
  CASE report_bucket
    WHEN '0' THEN 1
    WHEN '1' THEN 2
    WHEN '2-3' THEN 3
    WHEN '4-9' THEN 4
    WHEN '10-15' THEN 5
    WHEN '15-20' THEN 6
    WHEN '20-30' THEN 7
    WHEN '30-50' THEN 8
    ELSE 9
  END;

-- 비활성 신호
SELECT
  CASE
    WHEN pending_votes = 0 THEN '0'
    WHEN pending_votes = 1 THEN '1'
    WHEN pending_votes BETWEEN 2 AND 5 THEN '2-5'
    WHEN pending_votes BETWEEN 6 AND 10 THEN '6-10'
    ELSE '11+'
  END AS pending_votes_bucket,
  COUNT(*) AS users,
  COUNT(*) / (SELECT COUNT(*) FROM accounts_user) AS user_ratio
FROM accounts_user
GROUP BY pending_votes_bucket
ORDER BY
  CASE pending_votes_bucket
    WHEN '0' THEN 1
    WHEN '1' THEN 2
    WHEN '2-5' THEN 3
    WHEN '6-10' THEN 4
    ELSE 5
  END;
SELECT
  COUNT(*) AS total_users,
  SUM(pending_votes >= 5 OR pending_chat >= 5) AS inactive_risk_users,
  SUM(pending_votes >= 5 OR pending_chat >= 5) / COUNT(*) AS inactive_risk_ratio
FROM accounts_user;

-- 1인당 평균 투표 횟수
SELECT
  AVG(vote_cnt) AS avg_votes_per_user
FROM (
  SELECT
    user_id,
    COUNT(*) AS vote_cnt
  FROM accounts_userquestionrecord
  GROUP BY user_id
) t;

-- 유저별 받은 투표 수 
SELECT
  chosen_user_id,
  COUNT(*) AS received_votes
FROM accounts_userquestionrecord
GROUP BY chosen_user_id
ORDER BY received_votes DESC
LIMIT 20;
-- 버킷
WITH received AS (
  SELECT
    chosen_user_id,
    COUNT(*) AS received_votes
  FROM accounts_userquestionrecord
  GROUP BY chosen_user_id
)
SELECT
  CASE
    WHEN received_votes = 1 THEN '1'
    WHEN received_votes BETWEEN 2 AND 5 THEN '2-5'
    WHEN received_votes BETWEEN 6 AND 10 THEN '6-10'
    WHEN received_votes BETWEEN 11 AND 20 THEN '11-20'
    WHEN received_votes BETWEEN 21 AND 50 THEN '21-50'
    ELSE '51+'
  END AS bucket,
  COUNT(*) AS users
FROM received
GROUP BY bucket
ORDER BY
  CASE bucket
    WHEN '1' THEN 1
    WHEN '2-5' THEN 2
    WHEN '6-10' THEN 3
    WHEN '11-20' THEN 4
    WHEN '21-50' THEN 5
    ELSE 6
  END;


-- 호기심 전체 평균 
SELECT
  AVG(opened_times) AS avg_opened_times,
  MAX(opened_times) AS max_opened_times,
  SUM(opened_times = 0) AS zero_opened_cnt,
  SUM(opened_times = 0) / COUNT(*) AS zero_opened_rate
FROM accounts_userquestionrecord;
-- 분포
SELECT
  opened_times,
  COUNT(*) AS votes
FROM accounts_userquestionrecord
GROUP BY opened_times
ORDER BY opened_times;

-- 읽지 않음 비율
SELECT
  status,
  COUNT(*) AS total_votes,
  SUM(has_read = 0) AS unread_votes,
  SUM(has_read = 0) / COUNT(*) AS unread_rate
FROM accounts_userquestionrecord
GROUP BY status
ORDER BY total_votes DESC;

-- answer status 분포 및 응답 발생 비율
SELECT
  answer_status,
  COUNT(*) AS total_votes,
  SUM(answer_updated_at IS NOT NULL) AS answered_votes,
  SUM(answer_updated_at IS NOT NULL) / COUNT(*) AS answered_rate
FROM accounts_userquestionrecord
GROUP BY answer_status
ORDER BY total_votes DESC;


-- 신고 많이 발생하는 투표 유형 
-- 질문별 신고 집중도 TOP
SELECT
  question_id,
  SUM(report_count) AS total_reports,
  COUNT(*) AS votes,
  SUM(report_count) / COUNT(*) AS reports_per_vote
FROM accounts_userquestionrecord
GROUP BY question_id
HAVING total_reports > 0
ORDER BY total_reports DESC
LIMIT 20;

-- 투표 단위(question_piece_id) 신고 집중도 TOP
SELECT
  question_piece_id,
  SUM(report_count) AS total_reports,
  COUNT(*) AS votes,
  SUM(report_count) / COUNT(*) AS reports_per_vote
FROM accounts_userquestionrecord
GROUP BY question_piece_id
HAVING total_reports > 0
ORDER BY total_reports DESC
LIMIT 20;

-- 신고된 투표 비율” 기준 TOP (발생률)
SELECT
  q.id AS question_id,
  q.question_text,
  SUM(r.report_count) AS total_reports,
  COUNT(*) AS votes,
  SUM(r.report_count) / COUNT(*) AS reports_per_vote
FROM accounts_userquestionrecord r
JOIN polls_question q
  ON q.id = r.question_id
GROUP BY q.id, q.question_text
HAVING total_reports > 0
ORDER BY total_reports DESC
LIMIT 20;


-- 탈퇴 사유 분포
SELECT
  reason,
  COUNT(*) AS withdraw_cnt,
  COUNT(*) / (SELECT COUNT(*) FROM accounts_userwithdraw) AS withdraw_ratio
FROM accounts_userwithdraw
GROUP BY reason
ORDER BY withdraw_cnt DESC;

-- 일별 탈퇴 추이
SELECT
  DATE(created_at) AS dt,
  COUNT(*) AS withdraw_cnt
FROM accounts_userwithdraw
GROUP BY DATE(created_at)
ORDER BY dt;

SELECT
  DATE_FORMAT(created_at, '%Y-%m') AS month,
  COUNT(*) AS withdraw_cnt
FROM accounts_userwithdraw
GROUP BY DATE_FORMAT(created_at, '%Y-%m')
ORDER BY withdraw_cnt DESC;

SELECT
  COUNT(*) AS total_votes,
  SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) AS read_votes,
  ROUND(SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS read_rate
FROM accounts_userquestionrecord;

-- 일별 읽음률 추이 
SELECT
  DATE(created_at) AS dt,
  COUNT(*) AS votes,
  SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) AS read_votes,
  ROUND(SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS read_rate
FROM accounts_userquestionrecord
GROUP BY DATE(created_at)
ORDER BY dt;
-- 파이썬으로 시각화 --

-- 퍼널 2 확인 진입 
-- opened_times 분포 (0=무시 / 다회=피로 가능)
SELECT
  opened_times,
  COUNT(*) AS cnt,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM accounts_userquestionrecord), 4) AS ratio
FROM accounts_userquestionrecord
GROUP BY opened_times
ORDER BY opened_times;

SELECT
  SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) AS read_votes,
  SUM(CASE WHEN opened_times > 0 THEN 1 ELSE 0 END) AS opened_votes,
  ROUND(SUM(CASE WHEN opened_times > 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS opened_rate_total,
  ROUND(
    SUM(CASE WHEN opened_times > 0 THEN 1 ELSE 0 END) /
    NULLIF(SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END), 0),
    4
  ) AS opened_rate_among_read
FROM accounts_userquestionrecord;

SELECT
  status,
  COUNT(*) AS cnt,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM accounts_userquestionrecord), 4) AS ratio
FROM accounts_userquestionrecord
GROUP BY status
ORDER BY cnt DESC;

SELECT
  CASE
    WHEN has_read = 0 THEN 'NOT_READ'
    WHEN opened_times = 0 THEN 'READ_BUT_NOT_OPENED'
    ELSE 'OPENED'
  END AS stage,
  status,
  COUNT(*) AS cnt
FROM accounts_userquestionrecord
GROUP BY stage, status
ORDER BY stage, cnt DESC;
SELECT
  answer_status,
  COUNT(*) AS cnt,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM accounts_userquestionrecord), 4) AS ratio
FROM accounts_userquestionrecord
GROUP BY answer_status
ORDER BY cnt DESC;

SELECT
  CASE
    WHEN opened_times = 0 THEN '0'
    WHEN opened_times BETWEEN 1 AND 2 THEN '1-2'
    WHEN opened_times BETWEEN 3 AND 5 THEN '3-5'
    ELSE '6+'
  END AS opened_bucket,
  COUNT(*) AS votes,
  SUM(CASE WHEN answer_status IS NOT NULL AND answer_status <> '미답변' THEN 1 ELSE 0 END) AS answered_votes,
  ROUND(
    SUM(CASE WHEN answer_status IS NOT NULL AND answer_status <> '미답변' THEN 1 ELSE 0 END) / COUNT(*),
    4
  ) AS answer_rate
FROM accounts_userquestionrecord
GROUP BY opened_bucket
ORDER BY FIELD(opened_bucket,'0','1-2','3-5','6+');


SELECT
  AVG(diff_hours) AS avg_hours_to_answer
FROM (
  SELECT TIMESTAMPDIFF(HOUR, created_at, answer_updated_at) AS diff_hours
  FROM accounts_userquestionrecord
  WHERE answer_updated_at IS NOT NULL
) t;

SELECT
  SUM(CASE WHEN status = '차단' THEN 1 ELSE 0 END) AS blocked_cnt,
  COUNT(*) AS total,
  ROUND(SUM(CASE WHEN status = '차단' THEN 1 ELSE 0 END) / COUNT(*), 4) AS blocked_rate
FROM accounts_userquestionrecord;

SELECT
  question_id,
  COUNT(*) AS total_votes,
  SUM(CASE WHEN report_count >= 1 THEN 1 ELSE 0 END) AS reported_votes,
  SUM(CASE WHEN status = '차단' THEN 1 ELSE 0 END) AS blocked_votes,
  ROUND(SUM(CASE WHEN report_count >= 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS report_rate,
  ROUND(SUM(CASE WHEN status = '차단' THEN 1 ELSE 0 END) / COUNT(*), 4) AS block_rate
FROM accounts_userquestionrecord
GROUP BY question_id
HAVING total_votes >= 50
ORDER BY report_rate DESC, block_rate DESC;

SELECT
  DAYOFWEEK(created_at) AS dow,  -- 1=Sunday ... 7=Saturday (MySQL)
  COUNT(*) AS pieces,
  ROUND(SUM(is_voted)/COUNT(*), 4) AS vote_rate,
  ROUND(SUM(is_skipped)/COUNT(*), 4) AS skip_rate
FROM polls_questionpiece
GROUP BY DAYOFWEEK(created_at)
ORDER BY dow;


SELECT
  CASE
    WHEN exposure_cnt = 1 THEN '1'
    WHEN exposure_cnt BETWEEN 2 AND 5 THEN '2–5'
    WHEN exposure_cnt BETWEEN 6 AND 10 THEN '6–10'
    WHEN exposure_cnt BETWEEN 11 AND 20 THEN '11–20'
    ELSE '21+'
  END AS exposure_bucket,
  COUNT(*) AS users
FROM (
  SELECT
    user_id,
    COUNT(*) AS exposure_cnt
  FROM polls_usercandidate
  GROUP BY user_id
) t
GROUP BY exposure_bucket
ORDER BY FIELD(exposure_bucket,'1','2–5','6–10','11–20','21+');

SELECT
  user_id,
  COUNT(*) AS exposures,
  COUNT(DISTINCT DATE(created_at)) AS active_days,
  ROUND(COUNT(*) / COUNT(DISTINCT DATE(created_at)), 2) AS avg_daily_exposure
FROM polls_usercandidate
GROUP BY user_id
HAVING avg_daily_exposure >= 5
ORDER BY avg_daily_exposure DESC;


SELECT
  CASE
    WHEN report_cnt = 1 THEN '1'
    WHEN report_cnt BETWEEN 2 AND 3 THEN '2–3'
    WHEN report_cnt BETWEEN 4 AND 9 THEN '4–9'
    ELSE '10+'
  END AS report_bucket,
  COUNT(*) AS questions
FROM (
  SELECT question_id, COUNT(*) AS report_cnt
  FROM polls_questionreport
  GROUP BY question_id
) t
GROUP BY report_bucket
ORDER BY FIELD(report_bucket,'1','2–3','4–9','10+');

SELECT
  CASE
    WHEN report_cnt = 1 THEN '1'
    WHEN report_cnt BETWEEN 2 AND 3 THEN '2–3'
    ELSE '4+'
  END AS report_bucket,
  COUNT(*) AS users
FROM (
  SELECT user_id, COUNT(*) AS report_cnt
  FROM polls_questionreport
  GROUP BY user_id
) t
GROUP BY report_bucket
ORDER BY FIELD(report_bucket,'1','2–3','4+');


SELECT
  reason,
  COUNT(*) AS cnt,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM polls_questionreport), 4) AS ratio
FROM polls_questionreport
GROUP BY reason
ORDER BY cnt DESC;


SELECT
  puc.user_id,
  COUNT(DISTINCT pqr.id) AS report_cnt,
  COUNT(*) AS candidate_exposures
FROM polls_usercandidate puc
LEFT JOIN polls_questionreport pqr
  ON puc.user_id = pqr.user_id
GROUP BY puc.user_id
HAVING candidate_exposures >= 100
ORDER BY report_cnt DESC;


WITH user_level AS (
  SELECT
    puc.user_id,
    COUNT(*) AS candidate_exposures,
    COUNT(DISTINCT pqr.id) AS report_cnt
  FROM polls_usercandidate puc
  LEFT JOIN polls_questionreport pqr
    ON puc.user_id = pqr.user_id
  GROUP BY puc.user_id
  HAVING COUNT(*) >= 100
)
SELECT
  CASE
    WHEN candidate_exposures BETWEEN 100 AND 299 THEN '100–299'
    WHEN candidate_exposures BETWEEN 300 AND 599 THEN '300–599'
    WHEN candidate_exposures BETWEEN 600 AND 999 THEN '600–999'
    WHEN candidate_exposures BETWEEN 1000 AND 1999 THEN '1000–1999'
    ELSE '2000+'
  END AS exposure_bucket,
  COUNT(*) AS users,
  SUM(CASE WHEN report_cnt > 0 THEN 1 ELSE 0 END) AS reported_users,
  ROUND(SUM(CASE WHEN report_cnt > 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS report_user_ratio,
  ROUND(AVG(report_cnt), 2) AS avg_report_cnt
FROM user_level
GROUP BY exposure_bucket
ORDER BY exposure_bucket;


WITH user_level AS (
  SELECT
    puc.user_id,
    COUNT(*) AS candidate_exposures,
    COUNT(DISTINCT pqr.id) AS report_cnt
  FROM polls_usercandidate puc
  LEFT JOIN polls_questionreport pqr
    ON puc.user_id = pqr.user_id
  GROUP BY puc.user_id
  HAVING COUNT(*) >= 100
)
SELECT
  CASE
    WHEN report_cnt = 0 THEN 'NO_REPORT'
    WHEN report_cnt = 1 THEN 'ONE_REPORT'
    WHEN report_cnt BETWEEN 2 AND 3 THEN 'FEW_REPORTS'
    ELSE 'MANY_REPORTS'
  END AS report_bucket,
  COUNT(*) AS users,
  ROUND(AVG(candidate_exposures), 1) AS avg_exposures
FROM user_level
GROUP BY report_bucket
ORDER BY users DESC;


WITH user_level AS (
  SELECT
    puc.user_id,
    COUNT(*) AS candidate_exposures,
    COUNT(DISTINCT pqr.id) AS report_cnt
  FROM polls_usercandidate puc
  LEFT JOIN polls_questionreport pqr
    ON puc.user_id = pqr.user_id
  GROUP BY puc.user_id
)
SELECT *
FROM user_level
WHERE candidate_exposures >= 1000
  AND report_cnt >= 2
ORDER BY candidate_exposures DESC;


WITH q_reports AS (
  SELECT
    question_id,
    COUNT(*) AS report_cnt
  FROM polls_questionreport
  GROUP BY question_id
)
SELECT
  CASE
    WHEN report_cnt = 1 THEN '1'
    WHEN report_cnt BETWEEN 2 AND 3 THEN '2–3'
    WHEN report_cnt BETWEEN 4 AND 9 THEN '4–9'
    ELSE '10+'
  END AS report_bucket,
  COUNT(*) AS questions
FROM q_reports
GROUP BY report_bucket
ORDER BY FIELD(report_bucket,'1','2–3','4–9','10+');

-- 그룹별 비교
USE app_logdata;
SELECT
  SUM(CASE WHEN status = '종료' THEN 1 ELSE 0 END) AS ended_sets,
  SUM(CASE WHEN status <> '종료' THEN 1 ELSE 0 END) AS not_ended_sets,
  COUNT(*) AS total_sets,
  ROUND(SUM(CASE WHEN status = '종료' THEN 1 ELSE 0 END) / COUNT(*), 4) AS end_rate
FROM polls_questionset;


SELECT
  AVG(TIMESTAMPDIFF(MINUTE, created_at, opening_time)) AS avg_minutes_to_open
FROM polls_questionset
WHERE opening_time IS NOT NULL;

SELECT
  set_cnt,
  COUNT(*) AS users
FROM (
  SELECT
    user_id,
    COUNT(*) AS set_cnt
  FROM polls_questionset
  GROUP BY user_id
) t
GROUP BY set_cnt
ORDER BY set_cnt;


SELECT
  CASE
    WHEN set_cnt = 1 THEN '1'
    WHEN set_cnt BETWEEN 2 AND 3 THEN '2-3'
    WHEN set_cnt BETWEEN 4 AND 9 THEN '4-9'
    WHEN set_cnt BETWEEN 10 AND 19 THEN '10-19'
    ELSE '20+'
  END AS set_bucket,
  COUNT(*) AS users
FROM (
  SELECT user_id, COUNT(*) AS set_cnt
  FROM polls_questionset
  GROUP BY user_id
) t
GROUP BY set_bucket
ORDER BY FIELD(set_bucket,'1','2-3','4-9','10-19','20+');

WITH user_level AS (
  SELECT
    puc.user_id,
    COUNT(*) AS candidate_exposures,
    COUNT(uqr.id) AS chosen_cnt,
    COUNT(uqr.id) / COUNT(*) AS chosen_rate
  FROM polls_usercandidate puc
  LEFT JOIN accounts_userquestionrecord uqr
    ON puc.user_id = uqr.chosen_user_id
   AND puc.question_piece_id = uqr.question_piece_id
  GROUP BY puc.user_id
  HAVING COUNT(*) >= 50
)
SELECT
  CASE
    WHEN chosen_rate >= 0.30 THEN 'HIGH_CONVERSION'
    WHEN chosen_rate >= 0.15 THEN 'MID_CONVERSION'
    WHEN chosen_rate >= 0.05 THEN 'LOW_CONVERSION'
    ELSE 'VERY_LOW_CONVERSION'
  END AS conversion_bucket,
  COUNT(*) AS users,
  ROUND(AVG(candidate_exposures), 1) AS avg_exposures,
  ROUND(AVG(chosen_rate), 4) AS avg_chosen_rate
FROM user_level
GROUP BY conversion_bucket
ORDER BY avg_chosen_rate DESC;

WITH user_level AS (
  SELECT
    puc.user_id,
    COUNT(*) AS candidate_exposures,
    COUNT(uqr.id) AS chosen_cnt,
    COUNT(uqr.id) / COUNT(*) AS chosen_rate
  FROM polls_usercandidate puc
  LEFT JOIN accounts_userquestionrecord uqr
    ON puc.user_id = uqr.chosen_user_id
   AND puc.question_piece_id = uqr.question_piece_id
  GROUP BY puc.user_id
)
SELECT *
FROM user_level
WHERE candidate_exposures >= 200
  AND chosen_rate < 0.05
ORDER BY candidate_exposures DESC;


-- hackle data
WITH signup_events AS (
  SELECT
    id,
    MAX(CASE WHEN event_key = 'view_signup' THEN 1 ELSE 0 END) AS viewed_signup,
    MAX(CASE WHEN event_key = 'complete_signup' THEN 1 ELSE 0 END) AS completed_signup
  FROM hackle_events
  WHERE event_key IN ('view_signup', 'complete_signup')
  GROUP BY event_id
)
SELECT
  COUNT(DISTINCT CASE WHEN viewed_signup = 1 THEN id END) AS view_signup_users,
  COUNT(DISTINCT CASE WHEN completed_signup = 1 THEN id END) AS complete_signup_users,
  COUNT(DISTINCT CASE WHEN completed_signup = 1 THEN id END)
  / COUNT(DISTINCT CASE WHEN viewed_signup = 1 THEN id END) AS conversion_rate
FROM signup_events;

-- 가입 이후 즉시 이탈 비율 
WITH signup_time AS (
  SELECT
    id,
    MIN(event_datetime) AS signup_at
  FROM hackle_events
  WHERE item_name = 'complete_signup'
  GROUP BY id
),
post_signup_core_events AS (
  SELECT
    s.id,
    COUNT(e.event_id) AS core_event_cnt
  FROM signup_time s
  LEFT JOIN hackle_events e
    ON s.id = e.id
   AND e.event_datetime > s.signup_at
   AND e.item_name IN (
     'view_question',
     'vote',
     'add_friend',
     'view_timeline'
   )
  GROUP BY s.id
)
SELECT
  COUNT(*) AS signup_users,
  COUNT(CASE WHEN core_event_cnt = 0 THEN 1 END) AS immediate_churn_users,
  COUNT(CASE WHEN core_event_cnt = 0 THEN 1 END)
  / COUNT(*) AS immediate_churn_rate
FROM post_signup_core_events;
-- 가입 이후 아무 액션이 없는 유저 비율
WITH signup AS (
  SELECT
    id,
    MIN(event_datetime) AS signup_at
  FROM hackle_events
  WHERE event_key = 'complete_signup'
  GROUP BY id
),
post_events AS (
  SELECT
    s.id,
    COUNT(e.event_id) AS post_event_cnt
  FROM signup s
  LEFT JOIN hackle_events e
    ON e.id = s.id
   AND e.event_datetime > s.signup_at
  GROUP BY s.id
)
SELECT
  COUNT(*) AS signup_users,
  SUM(post_event_cnt = 0) AS immediate_churn_users,
  SUM(post_event_cnt = 0) / COUNT(*) AS immediate_churn_rate
FROM post_events;
-- 가입 이후 10분 내 추가 이벤트가 없는 비율
WITH cs AS (
  SELECT
    event_id,
    session_id,
    event_datetime
  FROM hackle_events
  WHERE event_key = 'complete_signup'
),
core AS (
  SELECT
    cs.event_id,
    COUNT(e.event_id) AS core_cnt_10m
  FROM cs
  LEFT JOIN hackle_events e
    ON e.session_id = cs.session_id
   AND e.event_datetime > cs.event_datetime
   AND e.event_datetime <= cs.event_datetime + INTERVAL 10 MINUTE
   AND e.event_key IN (
     'click_question_open',
     'click_question_start',
     'click_bottom_navigation_questions',
     'view_questions_tap',
     'complete_question',
     'click_appbar_friend_plus',
     'click_friend_invite',
     'click_invite_friend',
     'click_question_ask'
   )
  GROUP BY cs.event_id
)
SELECT
  COUNT(*) AS complete_signup_events,
  SUM(core_cnt_10m = 0) AS immediate_churn_events_core_10m,
  SUM(core_cnt_10m = 0) / COUNT(*) AS immediate_churn_rate_core_10m
FROM core;


-- 가입 이후 어떠한 액션도 취하지 않는 유저 
WITH cs AS (
  SELECT
    event_id,
    session_id,
    event_datetime
  FROM hackle_events
  WHERE event_key = 'complete_signup'
),
post_events AS (
  SELECT
    cs.event_id,
    COUNT(e.event_id) AS post_event_cnt
  FROM cs
  LEFT JOIN hackle_events e
    ON e.session_id = cs.session_id
   AND (
        e.event_datetime > cs.event_datetime
        OR (e.event_datetime = cs.event_datetime AND e.event_key <> 'complete_signup')
       )
  GROUP BY cs.event_id
)
SELECT
  COUNT(*) AS complete_signup_events,
  SUM(post_event_cnt = 0) AS immediate_churn_events,
  SUM(post_event_cnt = 0) / COUNT(*) AS immediate_churn_rate
FROM post_events;

-- 가입 직후 가장 많이 취한 액션 
WITH signup AS (
  SELECT
    event_id,
    session_id,
    event_datetime
  FROM hackle_events
  WHERE event_key = 'complete_signup'
),
first_event AS (
  SELECT
    s.event_id AS signup_event_id,
    e.event_key,
    ROW_NUMBER() OVER (
      PARTITION BY s.event_id
      ORDER BY e.event_datetime ASC, e.event_id
    ) AS rn
  FROM signup s
  JOIN hackle_events e
    ON e.session_id = s.session_id
   AND (
        e.event_datetime > s.event_datetime
        OR (e.event_datetime = s.event_datetime AND e.event_key <> 'complete_signup')
       )
)
SELECT
  event_key AS first_action,
  COUNT(*) AS users_cnt
FROM first_event
WHERE rn = 1
GROUP BY event_key
ORDER BY users_cnt DESC
LIMIT 10;


WITH cs AS (
  -- 가입이 발생한 세션 + 가입 시각
  SELECT
    session_id,
    MIN(event_datetime) AS cs_at
  FROM hackle_events
  WHERE event_key = 'complete_signup'
  GROUP BY session_id
),
ss AS (
  -- 가입 이후에 발생한 session_start 시각(세션당 1개로 고정)
  SELECT
    e.session_id,
    MIN(e.event_datetime) AS ss_at
  FROM hackle_events e
  JOIN cs
    ON cs.session_id = e.session_id
  WHERE e.event_key = '$session_start'
    AND e.event_datetime >= cs.cs_at
  GROUP BY e.session_id
),
agg AS (
  -- session_start 이후 이벤트를 한 번에 집계
  SELECT
    ss.session_id,
    -- session_start 이후에 $session_end 말고 다른 이벤트가 있는지
    SUM(CASE
          WHEN e.event_datetime > ss.ss_at
           AND e.event_key <> '$session_end' THEN 1
          ELSE 0
        END) AS other_after_start_cnt,
    -- session_start 이후에 session_end가 존재하는지
    MAX(CASE
          WHEN e.event_datetime >= ss.ss_at
           AND e.event_key = '$session_end' THEN 1
          ELSE 0
        END) AS has_end_after_start
  FROM ss
  JOIN hackle_events e
    ON e.session_id = ss.session_id
   AND e.event_datetime >= ss.ss_at
  GROUP BY ss.session_id
)
SELECT
  COUNT(*) AS signup_sessions,
  SUM(has_end_after_start = 1 AND other_after_start_cnt = 0) AS immediate_end_sessions,
  SUM(has_end_after_start = 1 AND other_after_start_cnt = 0) / COUNT(*) AS session_end_rate
FROM agg;


SELECT
  YEAR(created_at) AS year,
  WEEK(created_at, 3) AS week,   -- ISO week (월요일 시작)
  COUNT(*) AS total_votes
FROM accounts_userquestionrecord
GROUP BY YEAR(created_at), WEEK(created_at, 3)
ORDER BY year, week;

SELECT
  YEAR(created_at) AS year,
  WEEK(created_at, 3) AS week,
  COUNT(DISTINCT question_piece_id) AS unique_question_pieces,
  COUNT(*) AS total_votes
FROM accounts_userquestionrecord
GROUP BY YEAR(created_at), WEEK(created_at, 3)
ORDER BY year, week;



-- Payments
-- 최초 구매 상품 분포
WITH ranked AS (
  SELECT
    user_id,
    productID,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, productID) AS rn
  FROM accounts_paymenthistory
)
SELECT
  productID AS first_productID,
  COUNT(*)  AS users
FROM ranked
WHERE rn = 1
GROUP BY productID
ORDER BY users DESC;

-- 재구매 상품
WITH ordered AS (
  SELECT
    user_id,
    productID,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, productID) AS purchase_order
  FROM accounts_paymenthistory
)
SELECT
  productID,
  COUNT(*) AS repurchase_cnt
FROM ordered
WHERE purchase_order = 2
GROUP BY productID
ORDER BY repurchase_cnt DESC;

-- 세 번째 구매 상품 
WITH ordered AS (
  SELECT
    user_id,
    productID,
    ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at, productID) AS purchase_order
  FROM accounts_paymenthistory
)
SELECT
  productID,
  COUNT(*) AS repurchase_cnt
FROM ordered
WHERE purchase_order = 3
GROUP BY productID
ORDER BY repurchase_cnt DESC;

-- Point
-- delta_point (+) (-) 비율 비교
SELECT
  CASE
    WHEN delta_point > 0 THEN 'plus'
    WHEN delta_point < 0 THEN 'minus'
    ELSE 'zero'
  END AS delta_type,
  COUNT(*) AS cnt,
  COUNT(*) * 1.0 / (SELECT COUNT(*) FROM accounts_pointhistory) AS ratio
FROM accounts_pointhistory
GROUP BY delta_type
ORDER BY cnt DESC;

-- 유저당 누적 획득 포인트 vs 사용 포인트
WITH user_point AS (
  SELECT
    user_id,
    SUM(CASE WHEN delta_point > 0 THEN delta_point ELSE 0 END) AS earned_point,
    SUM(CASE WHEN delta_point < 0 THEN -delta_point ELSE 0 END) AS spent_point,
    SUM(delta_point) AS net_point
  FROM accounts_pointhistory
  GROUP BY user_id
)
SELECT
  AVG(earned_point) AS avg_earned_per_user,
  AVG(spent_point)  AS avg_spent_per_user,
  AVG(net_point)    AS avg_net_per_user,
  SUM(earned_point) AS total_earned,
  SUM(spent_point)  AS total_spent
FROM user_point;

-- 포인트 잔고 분포
SELECT
    user_id,
    SUM(delta_point) AS balance
FROM accounts_pointhistory
GROUP BY user_id;
WITH user_balance AS (
  SELECT
    user_id,
    SUM(delta_point) AS balance
  FROM accounts_pointhistory
  GROUP BY user_id
)
SELECT
  COUNT(*) AS users,
  MIN(balance) AS min_balance,
  MAX(balance) AS max_balance,
  AVG(balance) AS avg_balance
FROM user_balance;


-- 포인트 사용량(-) 분포(건수)
-- 10/30/200/300/500/1000
SELECT
    -delta_point AS point_used,
    COUNT(*) AS usage_count
FROM accounts_pointhistory
WHERE delta_point < 0
GROUP BY -delta_point
ORDER BY point_used;

-- 포인트 사용(-) 유저 분포
SELECT
    -delta_point AS point_used,
    COUNT(DISTINCT user_id) AS user_count
FROM accounts_pointhistory
WHERE delta_point < 0
GROUP BY -delta_point
ORDER BY point_used;

-- 포인트 카테고리별 기간
-- -200 (23-05-18 ~ 23-08-25)
SELECT
    DATE(created_at) AS usage_date,
    COUNT(*) AS cnt
FROM accounts_pointhistory
WHERE delta_point = -200
GROUP BY DATE(created_at)
ORDER BY usage_date;

-- -300(23-04-28 ~ 23-05-18)
SELECT
    DATE(created_at) AS usage_date,
    COUNT(*) AS cnt
FROM accounts_pointhistory
WHERE delta_point = -300
GROUP BY DATE(created_at)
ORDER BY usage_date;

-- -500(23-05-18 ~ 23-08-26)
SELECT
    DATE(created_at) AS usage_date,
    COUNT(*) AS cnt
FROM accounts_pointhistory
WHERE delta_point = -500
GROUP BY DATE(created_at)
ORDER BY usage_date;

-- -1000(23-05-18 ~ 23-09-26)
SELECT
    DATE(created_at) AS usage_date,
    COUNT(*) AS cnt
FROM accounts_pointhistory
WHERE delta_point = -1000
GROUP BY DATE(created_at)
ORDER BY usage_date;

-- -10(23-05-18 ~ 23-06-07)
SELECT
    DATE(created_at) AS usage_date,
    COUNT(*) AS cnt
FROM accounts_pointhistory
WHERE delta_point = -10
GROUP BY DATE(created_at)
ORDER BY usage_date;


-- 기간별 클러스터링 테이블 만들기 (4/28 · 5/18 · 6/22 기준)
DROP TABLE IF EXISTS user_agg_period_v3;

CREATE TABLE user_agg_period_v3 AS
WITH base AS (
    SELECT
        user_id,
        created_at,
        question_id,
        chosen_user_id,
        has_read,
        report_count
    FROM accounts_userquestionrecord
    WHERE created_at >= '2023-04-28'
      AND created_at <  '2023-06-25'
),
labeled AS (
    SELECT
        user_id,
        CASE
            WHEN created_at >= '2023-04-28' AND created_at < '2023-05-18' THEN 'p1'
            WHEN created_at >= '2023-05-18' AND created_at < '2023-06-22' THEN 'p2'
            WHEN created_at >= '2023-06-22' AND created_at < '2023-06-25' THEN 'p3'
        END AS period,
        question_id,
        chosen_user_id,
        has_read,
        report_count,
        created_at,
        DATE(created_at) AS activity_date
    FROM base
),
daily AS (
    SELECT
        user_id,
        period,
        activity_date,
        COUNT(*) AS daily_chosen_count
    FROM labeled
    WHERE period IS NOT NULL
    GROUP BY user_id, period, activity_date
),
agg AS (
    SELECT
        user_id,
        period,
        /* 기본 참여 지표 */
        COUNT(*) AS chosen_count,
        COUNT(DISTINCT question_id) AS unique_question_count,
        COUNT(DISTINCT chosen_user_id) AS unique_chosen_user_count,
        /* 전환 지표 */
        AVG(has_read) AS read_rate,
        SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) AS read_count,
        COUNT(*) AS exposure_count,
        SUM(CASE WHEN has_read = 1 THEN 1 ELSE 0 END) / COUNT(*) AS read_exposure_rate,
        /* 활동 빈도 */
        COUNT(DISTINCT activity_date) AS active_days,
        /* 리스크 지표 */
        SUM(report_count) AS total_report_count,
        MAX(report_count) > 0 AS has_report
    FROM labeled
    WHERE period IS NOT NULL
    GROUP BY user_id, period
)
SELECT
    a.*,
    /* 활동 강도 */
    a.chosen_count / NULLIF(a.active_days, 0) AS chosen_per_active_day,
    /* 하루 최대 행동량 */
    d.max_daily_chosen_count
FROM agg a
LEFT JOIN (
    SELECT
        user_id,
        period,
        MAX(daily_chosen_count) AS max_daily_chosen_count
    FROM daily
    GROUP BY user_id, period
) d
ON a.user_id = d.user_id
AND a.period = d.period;


-- 검증 쿼리
SELECT period, COUNT(*) AS row_cnt, COUNT(DISTINCT user_id) AS user_cnt
FROM user_agg_period_v3
GROUP BY period;


-- p1 - p2 변화량 테이블
SELECT
    p1.user_id,
    /* 활동량 변화 */
    p2.chosen_count - p1.chosen_count AS delta_chosen,
    p2.active_days  - p1.active_days  AS delta_active_days,
    p2.chosen_per_active_day - p1.chosen_per_active_day AS delta_intensity,
    /* 전환 변화 */
    p2.read_exposure_rate - p1.read_exposure_rate AS delta_read_rate,
    /* 리스크 변화 */
    p2.total_report_count - p1.total_report_count AS delta_report
FROM user_agg_period_v3 p1
JOIN user_agg_period_v3 p2
  ON p1.user_id = p2.user_id
WHERE p1.period = 'p1'
  AND p2.period = 'p2';