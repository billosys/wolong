(defmodule wolong_plan_SUITE
  (export
   (all 0)
   (suite 0)
   (end_per_testcase 2)
   (solved_plan3_returns_public_plan 1)
   (solved_plan2_is_default_wrapper 1)
   (keep_false_preserves_payload_after_cleanup 1)
   (no_plan_returns_unsolvable 1)
   (parser_failure_is_typed_and_short_circuits 1)
   (grounder_failure_is_typed_and_short_circuits 1)
   (engine_failure_is_typed_and_distinct_from_unsolvable 1)
   (invalid_args_and_opts_do_not_invoke_fixtures 1)
   (workspace_failure_is_typed 1)
   (missing_binary_failure_is_typed 1)))

(defun all ()
  '(solved_plan3_returns_public_plan
    solved_plan2_is_default_wrapper
    keep_false_preserves_payload_after_cleanup
    no_plan_returns_unsolvable
    parser_failure_is_typed_and_short_circuits
    grounder_failure_is_typed_and_short_circuits
    engine_failure_is_typed_and_distinct_from_unsolvable
    invalid_args_and_opts_do_not_invoke_fixtures
    workspace_failure_is_typed
    missing_binary_failure_is_typed))

(defun suite ()
  `(#(timetrap #(seconds 30))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  'ok)

;;; ----------------
;;; success and no-plan paths
;;; ----------------

(defun solved_plan3_returns_public_plan (_config)
  (let ((base-dir (temp-base "solved-plan3")))
    (set-env base-dir 'true)
    (let* ((result (run-case "minimal" (map)))
           (plan (element 2 result))
           (workspace (map-get plan 'workspace))
           (provenance (map-get plan 'provenance))
           (engine (map-get provenance 'engine))
           (verification (map-get plan 'verification-boundary)))
      (equal 'ok (element 1 result))
      (equal 'solved (map-get plan 'outcome))
      (equal #b("fixture engine plan\n") (map-get plan 'payload))
      (equal 20 (map-get plan 'payload-bytes))
      (equal 'true (map-get (map-get plan 'artifact) 'exists))
      (equal #b("ok") (map-get (map-get engine 'status-fields) 'status))
      (equal #b("solved") (map-get (map-get engine 'status-fields) 'outcome))
      (equal 'not-run (map-get verification 'separate-verifier))
      (equal 'deferred (map-get verification 'action-sequence))
      (equal 'deferred (map-get verification 'decomposition-tree))
      (equal 'true (filelib:is_file (artifact-path workspace 'engine))))))

(defun solved_plan2_is_default_wrapper (_config)
  (let ((base-dir (temp-base "solved-plan2")))
    (set-env base-dir 'true)
    (let* ((result (wolong:plan (case-domain "minimal")
                                (case-problem "minimal")))
           (plan (element 2 result)))
      (equal 'ok (element 1 result))
      (equal #b("fixture engine plan\n") (map-get plan 'payload)))))

(defun keep_false_preserves_payload_after_cleanup (_config)
  (let ((base-dir (temp-base "keep-false")))
    (set-env base-dir 'false)
    (let* ((result (run-case "minimal" '()))
           (plan (element 2 result))
           (workspace (map-get plan 'workspace))
           (cleanup (map-get workspace 'cleanup)))
      (equal 'ok (element 1 result))
      (equal #b("fixture engine plan\n") (map-get plan 'payload))
      (equal 'removed (map-get cleanup 'action))
      (equal 'false (filelib:is_dir (map-get workspace 'path)))
      (equal 'false (filelib:is_file (artifact-path workspace 'engine))))))

(defun no_plan_returns_unsolvable (_config)
  (let ((base-dir (temp-base "no-plan")))
    (set-env base-dir 'true)
    (let* ((result (run-case "unsolvable" (map)))
           (detail (element 2 result))
           (engine (map-get detail 'engine))
           (workspace (map-get detail 'workspace))
           (status (map-get engine 'status-fields)))
      (equal 'unsolvable (element 1 result))
      (equal #b("domain_no_plan") (map-get status 'status))
      (equal #b("no_plan") (map-get status 'outcome))
      (equal 'true (filelib:is_file (artifact-path workspace 'parser)))
      (equal 'true (filelib:is_file (artifact-path workspace 'grounder)))
      (equal 'false (filelib:is_file (artifact-path workspace 'engine))))))

;;; ----------------
;;; typed failures
;;; ----------------

(defun parser_failure_is_typed_and_short_circuits (_config)
  (let ((base-dir (temp-base "parser-failure")))
    (set-env base-dir 'true)
    (let* ((result (wolong:plan
                    (fixture-path "gate-contract-substrate/minimal/no-domain.hddl")
                    (case-problem "minimal")
                    (map)))
           (reason (element 2 result))
           (detail (element 3 reason))
           (workspace (map-get detail 'workspace)))
      (equal 'error (element 1 result))
      (equal 'parser (element 1 reason))
      (equal 'input-unavailable (element 2 reason))
      (equal 'true (filelib:is_file (marker-path workspace "parser.invoked")))
      (equal 'false (filelib:is_file (marker-path workspace "grounder.invoked")))
      (equal 'false (filelib:is_file (marker-path workspace "engine.invoked"))))))

(defun grounder_failure_is_typed_and_short_circuits (_config)
  (let ((base-dir (temp-base "grounder-failure")))
    (set-env base-dir 'true)
    (let* ((result (run-case "grounder-invalid" (map)))
           (reason (element 2 result))
           (detail (element 3 reason))
           (workspace (map-get detail 'workspace)))
      (equal 'error (element 1 result))
      (equal 'grounder (element 1 reason))
      (equal 'input-invalid (element 2 reason))
      (equal 'true (filelib:is_file (marker-path workspace "parser.invoked")))
      (equal 'true (filelib:is_file (marker-path workspace "grounder.invoked")))
      (equal 'false (filelib:is_file (marker-path workspace "engine.invoked"))))))

(defun engine_failure_is_typed_and_distinct_from_unsolvable (_config)
  (let ((base-dir (temp-base "engine-failure")))
    (set-env base-dir 'true)
    (let* ((result (run-case "engine-invalid" (map)))
           (reason (element 2 result))
           (detail (element 3 reason))
           (workspace (map-get detail 'workspace)))
      (equal 'error (element 1 result))
      (equal 'engine (element 1 reason))
      (equal 'input-invalid (element 2 reason))
      (equal 'true (filelib:is_file (marker-path workspace "engine.invoked")))
      (equal 'false (filelib:is_file (artifact-path workspace 'engine))))))

(defun invalid_args_and_opts_do_not_invoke_fixtures (_config)
  (let ((base-dir (temp-base "invalid-args")))
    (set-env base-dir 'true)
    (let* ((bad-domain (wolong:plan 12345 (case-problem "minimal") (map)))
           (bad-problem (wolong:plan (case-domain "minimal") 12345 (map)))
           (bad-map-opts (wolong:plan (case-domain "minimal")
                                      (case-problem "minimal")
                                      (map 'unexpected 'true)))
           (bad-list-opts (wolong:plan (case-domain "minimal")
                                       (case-problem "minimal")
                                       '(unexpected))))
      (equal #(error #(invalid-argument domain-path 12345)) bad-domain)
      (equal #(error #(invalid-argument problem-path 12345)) bad-problem)
      (assert-opts-error bad-map-opts 'unsupported-option)
      (assert-opts-error bad-list-opts 'invalid-argument)
      (equal 'false (filelib:is_dir base-dir)))))

(defun workspace_failure_is_typed (_config)
  (let* ((base-file (temp-path "wolong-plan-base-file"))
         (_ (file:delete base-file)))
    (ok (file:write_file base-file #b("not a dir\n")))
    (set-env base-file 'true)
    (let* ((result (run-case "minimal" (map)))
           (reason (element 2 result))
           (detail (element 3 reason)))
      (equal 'error (element 1 result))
      (equal 'workspace (element 1 reason))
      (equal 'base-unavailable (element 2 reason))
      (equal base-file (map-get detail 'base-dir)))
    (file:delete base-file)))

(defun missing_binary_failure_is_typed (_config)
  (let ((base-dir (temp-base "missing-binary")))
    (set-env base-dir 'true)
    (application:set_env 'wolong 'binaries (map 'parser (parser-fixture)
                                                'grounder (grounder-fixture)
                                                'engine (missing-engine)))
    (let* ((result (run-case "minimal" (map)))
           (reason (element 2 result))
           (detail (element 3 reason))
           (binary-reason (map-get detail 'reason)))
      (equal 'error (element 1 result))
      (equal 'engine (element 1 reason))
      (equal 'binary (element 2 reason))
      (equal 'binary (element 1 binary-reason))
      (equal 'missing (element 2 binary-reason))
      (equal 'false (filelib:is_dir base-dir)))))

;;; ----------------
;;; fixtures and config
;;; ----------------

(defun run-case (name opts)
  (wolong:plan (case-domain name) (case-problem name) opts))

(defun case-domain (name)
  (fixture-path (filename:join (list "gate-contract-substrate" name "domain.hddl"))))

(defun case-problem (name)
  (fixture-path (filename:join (list "gate-contract-substrate" name "problem.hddl"))))

(defun set-env (base-dir keep-artifacts)
  (application:set_env 'wolong 'binaries (map 'parser (parser-fixture)
                                              'grounder (grounder-fixture)
                                              'engine (engine-fixture)))
  (application:set_env 'wolong 'gate-timeouts (map 'parse 5000
                                                   'ground 5000
                                                   'solve 5000))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir base-dir 'keep-artifacts keep-artifacts))
  (ok (element 1 (application:ensure_all_started 'wolong))))

(defun parser-fixture ()
  (fixture-path "gate-contract-substrate/pandapi-parser-fixture.sh"))

(defun grounder-fixture ()
  (fixture-path "gate-contract-substrate/pandapi-grounder-fixture.sh"))

(defun engine-fixture ()
  (fixture-path "gate-contract-substrate/pandapi-engine-fixture.sh"))

(defun missing-engine ()
  (fixture-path "gate-contract-substrate/no-such-engine"))

(defun fixture-path (relative)
  (filename:join (list (project-root) "test" "fixtures" relative)))

(defun project-root ()
  (filename:absname
   (filename:join (list (code:lib_dir 'wolong) ".." ".." ".." ".."))))

(defun temp-base (name)
  (filename:join (list "/tmp" (lists:concat (list "wolong-plan-" name)))))

(defun temp-path (name)
  (filename:join (list "/tmp" name)))

;;; ----------------
;;; assertions and helpers
;;; ----------------

(defun assert-opts-error (result expected-reason)
  (let ((reason (element 2 result)))
    (equal 'error (element 1 result))
    (equal 'opts (element 1 reason))
    (equal expected-reason (element 2 reason))))

(defun artifact-path (workspace role)
  (map-get (map-get workspace 'artifacts) role))

(defun marker-path (workspace marker)
  (filename:join (map-get workspace 'path) marker))

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false (ct:fail (tuple 'expected expected 'actual actual)))))

(defun ok (actual)
  (equal 'ok actual))
