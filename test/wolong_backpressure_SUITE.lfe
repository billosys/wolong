(defmodule wolong_backpressure_SUITE
  (export
   (all 0)
   (end_per_testcase 2)
   (engine_large_stdout_returns_public_plan 1)
   (flood_timeout_bounds_output_kills_group_and_recovers 1)
   (grounder_large_stdout_feeds_engine 1)
   (missing_final_status_is_typed_error 1)
   (noisy_stderr_preserves_final_status 1)
   (parser_large_stdout_feeds_grounder 1)
   (stdout_over_limit_is_typed_and_recovers 1)
   (suite 0)))

(defun all ()
  '(parser_large_stdout_feeds_grounder
     grounder_large_stdout_feeds_engine
     engine_large_stdout_returns_public_plan
     stdout_over_limit_is_typed_and_recovers
     noisy_stderr_preserves_final_status
     missing_final_status_is_typed_error
     flood_timeout_bounds_output_kills_group_and_recovers))

(defun suite () `(#(timetrap #(seconds 45))))

(defun end_per_testcase (_testcase _config)
  (application:unset_env 'wolong 'output-limits)
  (application:stop 'wolong)
  'ok)

;;; ----------------
;;; large artifact paths
;;; ----------------

(defun parser_large_stdout_feeds_grounder (_config)
  (set-env (temp-base "large-parser") 'true 5000
           (map 'parser (map 'stdout 80000 'stderr 4096)))
  (let* ((result (run-case "large-parser"))
          (plan (element 2 result))
          (parser (map-get (map-get plan 'provenance) 'parser)))
    (equal 'ok (element 1 result))
    (greater-than 65536 (map-get parser 'stdout-bytes))
    (equal 'false (map-get parser 'stdout-truncated))
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

(defun grounder_large_stdout_feeds_engine (_config)
  (set-env (temp-base "large-grounder") 'true 5000
           (map 'grounder (map 'stdout 80000 'stderr 4096)))
  (let* ((result (run-case "large-grounder"))
          (plan (element 2 result))
          (grounder (map-get (map-get plan 'provenance) 'grounder)))
    (equal 'ok (element 1 result))
    (greater-than 65536 (map-get grounder 'stdout-bytes))
    (equal 'false (map-get grounder 'stdout-truncated))
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

(defun engine_large_stdout_returns_public_plan (_config)
  (set-env (temp-base "large-engine") 'true 5000
           (map 'engine (map 'stdout 80000 'stderr 4096)))
  (let* ((result (run-case "large-engine"))
          (plan (element 2 result))
          (payload (map-get plan 'payload))
          (engine (map-get (map-get plan 'provenance) 'engine)))
    (equal 'ok (element 1 result))
    (greater-than 65536 (map-get plan 'payload-bytes))
    (equal (byte_size payload) (map-get plan 'payload-bytes))
    (equal (byte_size payload) (map-get (map-get plan 'artifact) 'bytes))
    (equal 'false (map-get engine 'stdout-truncated))
    (wait-workers-zero)))

;;; ----------------
;;; status and truncation policies
;;; ----------------

(defun stdout_over_limit_is_typed_and_recovers (_config)
  (set-env (temp-base "stdout-over-limit") 'true 5000
           (map 'engine (map 'stdout 1024 'stderr 65536)))
  (let* ((result (run-case "output-flood"))
          (reason (element 2 result))
          (detail (element 3 reason))
          (engine (map-get detail 'engine)))
    (equal 'error (element 1 result))
    (equal 'engine (element 1 reason))
    (equal 'artifact-truncated (element 2 reason))
    (equal 1024 (byte_size (map-get engine 'stdout)))
    (greater-than 1024 (map-get engine 'stdout-bytes))
    (equal 'true (map-get engine 'stdout-truncated))
    (equal #b("ok") (map-get (map-get engine 'status-fields) 'status))
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

(defun noisy_stderr_preserves_final_status (_config)
  (set-env (temp-base "noisy-stderr") 'true 5000
           (map 'engine (map 'stdout 65536 'stderr 256)))
  (let* ((result (run-case "noisy-stderr-status"))
          (plan (element 2 result))
          (engine (map-get (map-get plan 'provenance) 'engine))
          (status (map-get engine 'status-fields)))
    (equal 'ok (element 1 result))
    (equal 'true (map-get engine 'stderr-truncated))
    (equal 'false
           (binary-contains? (map-get engine 'stderr) #b("PANDAPI_STATUS\t")))
    (equal 'true
           (binary-contains? (map-get engine 'stderr-tail)
                             #b("PANDAPI_STATUS\t")))
    (equal #b("ok") (map-get status 'status))
    (equal #b("solved") (map-get status 'outcome))
    (wait-workers-zero)))

(defun missing_final_status_is_typed_error (_config)
  (set-env (temp-base "missing-status") 'true 5000
           (map 'engine (map 'stdout 65536 'stderr 256)))
  (let* ((result (run-case "missing-status"))
          (reason (element 2 result))
          (detail (element 3 reason))
          (engine (map-get detail 'engine)))
    (equal 'error (element 1 result))
    (equal 'engine (element 1 reason))
    (equal 'missing-status (element 2 reason))
    (equal 'true (map-get engine 'stderr-truncated))
    (equal 'false
           (binary-contains? (map-get engine 'stderr-tail)
                             #b("PANDAPI_STATUS\t")))
    (wait-workers-zero)))

;;; ----------------
;;; flood timeout and recovery
;;; ----------------

(defun flood_timeout_bounds_output_kills_group_and_recovers (_config)
  (set-env (temp-base "flood-timeout") 'true 250
           (map 'engine (map 'stdout 128 'stderr 128)))
  (let* ((result (run-case "flood-timeout"))
          (reason (element 2 result))
          (detail (element 3 reason))
          (engine (map-get detail 'engine))
          (pid (integer_to_list (map-get engine 'os-pid))))
    (equal 'error (element 1 result))
    (equal 'engine (element 1 reason))
    (equal 'timeout (element 2 reason))
    (equal 'true (map-get engine 'timed-out))
    (equal 128 (byte_size (map-get engine 'stdout)))
    (equal 128 (byte_size (map-get engine 'stderr)))
    (greater-than 128 (map-get engine 'stdout-bytes))
    (greater-than 128 (map-get engine 'stderr-bytes))
    (equal 'true (map-get engine 'stdout-truncated))
    (equal 'true (map-get engine 'stderr-truncated))
    (equal 'true (wait-until-process-gone pid 25))
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

;;; ----------------
;;; fixtures and config
;;; ----------------

(defun run-case (name)
  (wolong:plan (case-domain name) (case-problem name)))

(defun case-domain (name)
  (fixture-path
    (filename:join (list "gate-contract-substrate" name "domain.hddl"))))

(defun case-problem (name)
  (fixture-path
    (filename:join (list "gate-contract-substrate" name "problem.hddl"))))

(defun set-env (base-dir keep-artifacts solve-timeout-ms output-limits)
  (application:set_env 'wolong
                       'binaries
                       (map 'parser (parser-fixture)
                            'grounder (grounder-fixture)
                            'engine (engine-fixture)))
  (application:set_env 'wolong
                       'gate-timeouts
                       (map 'parse 5000 'ground 5000 'solve solve-timeout-ms))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir base-dir 'keep-artifacts keep-artifacts))
  (application:set_env 'wolong 'output-limits output-limits)
  (ok (element 1 (application:ensure_all_started 'wolong))))

(defun parser-fixture ()
  (fixture-path "gate-contract-substrate/pandapi-parser-fixture.sh"))

(defun grounder-fixture ()
  (fixture-path "gate-contract-substrate/pandapi-grounder-fixture.sh"))

(defun engine-fixture ()
  (fixture-path "gate-contract-substrate/pandapi-engine-fixture.sh"))

(defun fixture-path (relative)
  (filename:join (list (project-root) "test" "fixtures" relative)))

(defun project-root ()
  (filename:absname
    (filename:join (list (code:lib_dir 'wolong) ".." ".." ".." ".."))))

(defun temp-base (name)
  (filename:join
    (list "/tmp"
          (lists:flatten
            (io_lib:format "wolong-backpressure-~s-~p"
                           (list name
                                 (erlang:unique_integer '(positive monotonic))))))))

;;; ----------------
;;; assertions and wait helpers
;;; ----------------

(defun binary-contains? (haystack needle)
  (case (binary:match haystack needle)
    ('nomatch 'false)
    (_ 'true)))

(defun greater-than (threshold actual)
  (case (> actual threshold)
    ('true 'ok)
    ('false
     (ct:fail (tuple 'expected-greater-than threshold 'actual actual)))))

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false
     (ct:fail (tuple 'expected expected 'actual actual)))))

(defun ok (actual)
  (equal 'ok actual))

(defun process-alive? (pid)
  (=:= "0\n"
       (os:cmd
         (lists:flatten
           (io_lib:format "kill -0 ~s >/dev/null 2>&1; echo $?" (list pid))))))

(defun wait-until-process-gone (pid attempts)
  (wait-until (lambda () (not (process-alive? pid))) attempts))

(defun wait-workers-zero ()
  (equal 'true
         (wait-until (lambda () (=:= 0 (wolong-dispatch-sup:worker-count))) 30)))

(defun wait-until (pred attempts)
  (if (=< attempts 0)
    (funcall pred)
    (if (funcall pred)
      'true
      (progn
        (timer:sleep 100)
        (wait-until pred (- attempts 1))))))
