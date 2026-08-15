(defmodule wolong_dispatch_SUITE
  (export
   (all 0)
   (suite 0)
   (end_per_testcase 2)
   (app_start_has_dispatch_supervision 1)
   (solved_and_no_plan_preserve_public_shapes 1)
   (gate_config_binary_and_workspace_failures_are_typed 1)
   (engine_timeout_is_typed_with_bounded_detail 1)
   (term_resistant_timeout_has_no_survivor_and_recovers 1)
   (synthetic_worker_crash_is_typed_and_isolated 1)
   (concurrent_dispatches_use_distinct_workers_and_workspaces 1)
   (concurrent_timeout_does_not_corrupt_success 1)
   (terminal_dispatches_leave_no_live_workers 1)
   (validate_remains_parser_only 1)))

(defun all ()
  '(app_start_has_dispatch_supervision
    solved_and_no_plan_preserve_public_shapes
    gate_config_binary_and_workspace_failures_are_typed
    engine_timeout_is_typed_with_bounded_detail
    term_resistant_timeout_has_no_survivor_and_recovers
    synthetic_worker_crash_is_typed_and_isolated
    concurrent_dispatches_use_distinct_workers_and_workspaces
    concurrent_timeout_does_not_corrupt_success
    terminal_dispatches_leave_no_live_workers
    validate_remains_parser_only))

(defun suite ()
  `(#(timetrap #(seconds 45))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  'ok)

;;; ----------------
;;; supervision topology
;;; ----------------

(defun app_start_has_dispatch_supervision (_config)
  (set-env (temp-base "app-start") 'true 5000)
  (not-equal 'undefined (whereis 'wolong-sup))
  (not-equal 'undefined (whereis 'wolong-dispatch-sup))
  (not-equal 'undefined (whereis 'exec))
  (equal 'true (supervisor-child? 'wolong-sup 'wolong-dispatch-sup))
  (equal 0 (wolong-dispatch-sup:worker-count)))

(defun solved_and_no_plan_preserve_public_shapes (_config)
  (set-env (temp-base "public-shapes") 'true 5000)
  (let* ((solved (run-case "minimal"))
         (plan (element 2 solved))
         (no-plan (run-case "unsolvable"))
         (no-plan-detail (element 2 no-plan)))
    (equal 'ok (element 1 solved))
    (equal 'solved (map-get plan 'outcome))
    (equal #b("fixture engine plan\n") (map-get plan 'payload))
    (equal 'not-run (map-get (map-get plan 'verification-boundary) 'separate-verifier))
    (assert-dispatch-detail (map-get plan 'dispatch))
    (equal 'unsolvable (element 1 no-plan))
    (equal #b("domain_no_plan")
           (map-get (map-get (map-get no-plan-detail 'engine) 'status-fields) 'status))
    (assert-dispatch-detail (map-get no-plan-detail 'dispatch))
    (wait-workers-zero)))

;;; ----------------
;;; typed failures
;;; ----------------

(defun gate_config_binary_and_workspace_failures_are_typed (_config)
  (set-env (temp-base "typed-failures") 'true 5000)
  (assert-error (wolong:plan (fixture-path "gate-contract-substrate/minimal/no-domain.hddl")
                             (case-problem "minimal"))
                'parser 'input-unavailable)
  (assert-error (run-case "grounder-invalid") 'grounder 'input-invalid)
  (assert-error (run-case "engine-invalid") 'engine 'input-invalid)
  (application:set_env 'wolong 'binaries (map 'parser (parser-fixture)
                                              'grounder (grounder-fixture)
                                              'engine (missing-engine)))
  (assert-error (run-case "minimal") 'engine 'binary)
  (set-env (temp-base "typed-config") 'true 5000)
  (application:unset_env 'wolong 'workdir)
  (assert-error (run-case "minimal") 'workspace 'config)
  (let* ((base-file (temp-path "wolong-dispatch-base-file"))
         (_ (file:delete base-file)))
    (ok (file:write_file base-file #b("not a dir\n")))
    (set-env base-file 'true 5000)
    (assert-error (run-case "minimal") 'workspace 'base-unavailable)
    (file:delete base-file))
  (wait-workers-zero))

(defun engine_timeout_is_typed_with_bounded_detail (_config)
  (set-env (temp-base "engine-timeout") 'true 250)
  (let* ((result (run-case "engine-timeout"))
         (reason (element 2 result))
         (detail (element 3 reason))
         (engine (map-get detail 'engine)))
    (equal 'error (element 1 result))
    (equal 'engine (element 1 reason))
    (equal 'timeout (element 2 reason))
    (equal #b("before-timeout\n") (map-get engine 'stdout))
    (equal #b("stderr-before-timeout\n") (map-get engine 'stderr))
    (equal 'false (map-get engine 'stdout-truncated))
    (equal 'false (map-get engine 'stderr-truncated))
    (assert-dispatch-detail (map-get detail 'dispatch))
    (wait-workers-zero)))

(defun term_resistant_timeout_has_no_survivor_and_recovers (_config)
  (set-env (temp-base "term-resistant") 'true 250)
  (let* ((result (run-case "engine-timeout"))
         (detail (element 3 (element 2 result)))
         (workspace (map-get detail 'workspace))
         (pid-file (marker-path workspace "engine-timeout.pid"))
         (`#(ok ,pid-bin) (file:read_file pid-file))
         (pid (string:trim (binary_to_list pid-bin))))
    (equal 'error (element 1 result))
    (equal 'engine (element 1 (element 2 result)))
    (equal 'timeout (element 2 (element 2 result)))
    (equal 'true (wait-until-process-gone pid 25))
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

(defun synthetic_worker_crash_is_typed_and_isolated (_config)
  (set-env (temp-base "worker-crash") 'true 5000)
  (let* ((crash (wolong-dispatch:run 'crash-dispatch-worker "unused"))
         (reason (element 2 crash))
         (detail (element 3 reason)))
    (equal 'error (element 1 crash))
    (equal 'dispatch (element 1 reason))
    (equal 'worker-exit (element 2 reason))
    (assert-dispatch-detail detail)
    (equal 'synthetic-dispatch-worker-crash (crash-reason-name (map-get detail 'reason)))
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

;;; ----------------
;;; concurrency and lifecycle
;;; ----------------

(defun concurrent_dispatches_use_distinct_workers_and_workspaces (_config)
  (set-env (temp-base "concurrent-success") 'true 5000)
  (let* ((first (async-plan "slow-success"))
         (second (async-plan "slow-success")))
    (timer:sleep 100)
    (at-least 2 (wolong-dispatch-sup:worker-count))
    (let* ((first-result (receive-async first))
           (second-result (receive-async second))
           (first-plan (element 2 first-result))
           (second-plan (element 2 second-result))
           (first-worker (map-get (map-get first-plan 'dispatch) 'worker))
           (second-worker (map-get (map-get second-plan 'dispatch) 'worker))
           (first-workspace (map-get first-plan 'workspace))
           (second-workspace (map-get second-plan 'workspace)))
      (equal 'ok (element 1 first-result))
      (equal 'ok (element 1 second-result))
      (not-equal first-worker second-worker)
      (not-equal (map-get first-workspace 'path)
                 (map-get second-workspace 'path))
      (wait-workers-zero))))

(defun concurrent_timeout_does_not_corrupt_success (_config)
  (set-env (temp-base "concurrent-mixed") 'true 350)
  (let* ((timeout (async-plan "engine-timeout"))
         (success (async-plan "minimal"))
         (success-result (receive-async success))
         (timeout-result (receive-async timeout)))
    (equal 'ok (element 1 success-result))
    (assert-error timeout-result 'engine 'timeout)
    (equal 'ok (element 1 (run-case "minimal")))
    (wait-workers-zero)))

(defun terminal_dispatches_leave_no_live_workers (_config)
  (set-env (temp-base "terminal-workers") 'true 250)
  (equal 'ok (element 1 (run-case "minimal")))
  (wait-workers-zero)
  (assert-error (wolong:plan (fixture-path "gate-contract-substrate/minimal/no-domain.hddl")
                             (case-problem "minimal"))
                'parser 'input-unavailable)
  (wait-workers-zero)
  (assert-error (run-case "engine-timeout") 'engine 'timeout)
  (wait-workers-zero)
  (assert-error (wolong-dispatch:run 'crash-dispatch-worker "unused") 'dispatch 'worker-exit)
  (wait-workers-zero))

(defun validate_remains_parser_only (_config)
  (let ((base-dir (temp-base "validate-parser-only")))
    (application:set_env 'wolong 'binaries (map 'parser (parser-fixture)))
    (application:set_env 'wolong 'gate-timeouts (map 'parse 5000))
    (application:set_env 'wolong 'workdir
                         (map 'base-dir base-dir 'keep-artifacts 'true))
    (ok (element 1 (application:ensure_all_started 'wolong)))
    (let ((result (wolong:validate (case-domain "minimal") (case-problem "minimal"))))
      (equal 'ok (element 1 result))
      (equal 'false (filelib:is_file (filename:join base-dir "engine.invoked"))))))

;;; ----------------
;;; async helpers
;;; ----------------

(defun async-plan (name)
  (let* ((parent (self))
         (ref (make_ref))
         (`#(,_pid ,mon-ref)
          (erlang:spawn_monitor
           (lambda ()
             (erlang:send parent `#(async-result ,ref ,(run-case name)))))))
    `#(,ref ,mon-ref)))

(defun receive-async
  (((tuple ref mon-ref))
   (let ((result (receive
                   (`#(async-result ,ref ,value) value)
                   (after 10000 (ct:fail #(async-result-timeout))))))
    (receive
      (`#(DOWN ,mon-ref process ,_pid ,_reason) result)
      (after 10000 (ct:fail #(async-down-timeout)))))))

;;; ----------------
;;; fixtures and config
;;; ----------------

(defun run-case (name)
  (wolong:plan (case-domain name) (case-problem name)))

(defun case-domain (name)
  (fixture-path (filename:join (list "gate-contract-substrate" name "domain.hddl"))))

(defun case-problem (name)
  (fixture-path (filename:join (list "gate-contract-substrate" name "problem.hddl"))))

(defun set-env (base-dir keep-artifacts solve-timeout-ms)
  (application:set_env 'wolong 'binaries (map 'parser (parser-fixture)
                                              'grounder (grounder-fixture)
                                              'engine (engine-fixture)))
  (application:set_env 'wolong 'gate-timeouts (map 'parse 5000
                                                   'ground 5000
                                                   'solve solve-timeout-ms))
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
  (filename:join
   (list "/tmp"
         (lists:flatten
          (io_lib:format "wolong-dispatch-~s-~p"
                         (list name (erlang:unique_integer '(positive monotonic))))))))

(defun temp-path (name)
  (filename:join
   (list "/tmp"
         (lists:flatten
          (io_lib:format "~s-~p"
                         (list name (erlang:unique_integer '(positive monotonic))))))))

;;; ----------------
;;; assertions and wait helpers
;;; ----------------

(defun assert-error (result expected-gate expected-reason)
  (let ((reason (element 2 result)))
    (equal 'error (element 1 result))
    (equal expected-gate (element 1 reason))
    (equal expected-reason (element 2 reason))))

(defun assert-dispatch-detail (detail)
  (not-equal 'undefined detail)
  (equal 'true (is_pid (map-get detail 'worker)))
  (equal 'wolong-dispatch-sup (map-get detail 'supervisor))
  (equal 'temporary (map-get detail 'restart-policy)))

(defun crash-reason-name
  ((`#(,reason ,_stack)) reason)
  ((reason) reason))

(defun supervisor-child? (supervisor child-id)
  (lists:any
   (lambda (child)
     (=:= child-id (element 1 child)))
   (supervisor:which_children supervisor)))

(defun marker-path (workspace marker)
  (filename:join (map-get workspace 'path) marker))

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false (ct:fail (tuple 'expected expected 'actual actual)))))

(defun not-equal (unexpected actual)
  (case (=:= unexpected actual)
    ('false 'ok)
    ('true (ct:fail (tuple 'unexpected unexpected)))))

(defun at-least (minimum actual)
  (case (>= actual minimum)
    ('true 'ok)
    ('false (ct:fail (tuple 'expected-at-least minimum 'actual actual)))))

(defun ok (actual)
  (equal 'ok actual))

(defun wait-workers-zero ()
  (equal 'true (wait-until (lambda () (=:= 0 (wolong-dispatch-sup:worker-count))) 30)))

(defun process-alive? (pid)
  (=:= "0\n" (os:cmd (lists:flatten (io_lib:format "kill -0 ~s >/dev/null 2>&1; echo $?"
                                                   (list pid))))))

(defun wait-until-process-gone (pid attempts)
  (wait-until (lambda () (not (process-alive? pid))) attempts))

(defun wait-until (pred attempts)
  (if (=< attempts 0)
      (funcall pred)
      (if (funcall pred)
          'true
          (progn
            (timer:sleep 100)
            (wait-until pred (- attempts 1))))))
