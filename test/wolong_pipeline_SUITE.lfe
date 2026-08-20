(defmodule wolong_pipeline_SUITE
  (export
   (all 0)
   (cleanup_refuses_outside_dispatch_workspace 1)
   (end_per_testcase 2)
   (engine_failure_is_typed_and_distinct_from_no_plan 1)
   (grounder_failure_short_circuits 1)
   (keep_false_removes_only_dispatch_workspace 1)
   (no_plan_keep_true_preserves_domain_result 1)
   (parser_failure_short_circuits 1)
   (suite 0)
   (unavailable_workdir_is_typed 1)
   (unique_workspace_and_artifact_roles_keep_true 1)))

(defun all ()
  '(unique_workspace_and_artifact_roles_keep_true
     no_plan_keep_true_preserves_domain_result
     keep_false_removes_only_dispatch_workspace
     parser_failure_short_circuits
     grounder_failure_short_circuits
     engine_failure_is_typed_and_distinct_from_no_plan
     unavailable_workdir_is_typed
     cleanup_refuses_outside_dispatch_workspace))

(defun suite () `(#(timetrap #(seconds 30))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  'ok)

;;; ----------------
;;; workspace success paths
;;; ----------------

(defun unique_workspace_and_artifact_roles_keep_true (_config)
  (let ((base-dir (temp-base "unique")))
    (set-env base-dir 'true)
    (let* ((first (run-minimal))
            (second (run-minimal))
            (first-detail (element 2 first))
            (second-detail (element 2 second))
            (first-workspace (map-get first-detail 'workspace))
            (second-workspace (map-get second-detail 'workspace)))
      (equal 'ok (element 1 first))
      (equal 'ok (element 1 second))
      (not-equal (map-get first-workspace 'path)
                 (map-get second-workspace 'path))
      (assert-workspace-under-base base-dir first-workspace)
      (assert-artifact-roles first-workspace)
      (assert-gate-success first-detail 'parser)
      (assert-gate-success first-detail 'grounder)
      (assert-gate-success first-detail 'engine)
      (equal 'true (filelib:is_dir (map-get first-workspace 'path)))
      (equal 'true (filelib:is_file (artifact-path first-workspace 'parser)))
      (equal 'true (filelib:is_file (artifact-path first-workspace 'grounder)))
      (equal 'true (filelib:is_file (artifact-path first-workspace 'engine))))))

(defun no_plan_keep_true_preserves_domain_result (_config)
  (let ((base-dir (temp-base "no-plan")))
    (set-env base-dir 'true)
    (let* ((result (run-case "unsolvable"))
            (detail (element 2 result))
            (workspace (map-get detail 'workspace))
            (engine (map-get detail 'engine))
            (status (map-get engine 'status-fields)))
      (equal 'domain-no-plan (element 1 result))
      (equal #b("domain_no_plan") (map-get status 'status))
      (equal #b("no_plan") (map-get status 'outcome))
      (equal 'true (filelib:is_file (artifact-path workspace 'parser)))
      (equal 'true (filelib:is_file (artifact-path workspace 'grounder)))
      (equal 'false (filelib:is_file (artifact-path workspace 'engine)))
      (equal 'true (filelib:is_file (marker-path workspace "engine.invoked"))))))

(defun keep_false_removes_only_dispatch_workspace (_config)
  (let* ((base-dir (temp-base "cleanup"))
          (sentinel (filename:join base-dir "sentinel.txt")))
    (ok (filelib:ensure_dir sentinel))
    (ok (file:write_file sentinel #b("keep me\n")))
    (set-env base-dir 'false)
    (let* ((result (run-minimal))
            (detail (element 2 result))
            (workspace (map-get detail 'workspace))
            (cleanup (map-get workspace 'cleanup)))
      (equal 'ok (element 1 result))
      (equal 'removed (map-get cleanup 'action))
      (equal 'false (filelib:is_dir (map-get workspace 'path)))
      (equal 'true (filelib:is_dir base-dir))
      (equal 'true (filelib:is_file sentinel))
      (equal #b() (map-get (map-get detail 'engine) 'stdout))
      (equal 'true
             (map-get (map-get (map-get detail 'engine) 'artifact) 'exists)))))

;;; ----------------
;;; short-circuit failures
;;; ----------------

(defun parser_failure_short_circuits (_config)
  (let ((base-dir (temp-base "parser-failure")))
    (set-env base-dir 'true)
    (let* ((result
             (wolong-pipeline:run
               (fixture-path "gate-contract-substrate/minimal/no-domain.hddl")
               (fixture-path "gate-contract-substrate/minimal/problem.hddl")))
            (reason (element 2 result))
            (detail (element 3 reason))
            (workspace (map-get detail 'workspace)))
      (equal 'error (element 1 result))
      (equal 'parser (element 1 reason))
      (equal 'input-unavailable (element 2 reason))
      (equal 'true (filelib:is_file (marker-path workspace "parser.invoked")))
      (equal 'false
             (filelib:is_file (marker-path workspace "grounder.invoked")))
      (equal 'false (filelib:is_file (marker-path workspace "engine.invoked"))))))

(defun grounder_failure_short_circuits (_config)
  (let ((base-dir (temp-base "grounder-failure")))
    (set-env base-dir 'true)
    (let* ((result (run-case "grounder-invalid"))
            (reason (element 2 result))
            (detail (element 3 reason))
            (workspace (map-get detail 'workspace)))
      (equal 'error (element 1 result))
      (equal 'grounder (element 1 reason))
      (equal 'input-invalid (element 2 reason))
      (equal 'true (filelib:is_file (marker-path workspace "parser.invoked")))
      (equal 'true (filelib:is_file (marker-path workspace "grounder.invoked")))
      (equal 'false (filelib:is_file (marker-path workspace "engine.invoked"))))))

(defun engine_failure_is_typed_and_distinct_from_no_plan (_config)
  (let ((base-dir (temp-base "engine-failure")))
    (set-env base-dir 'true)
    (let* ((result (run-case "engine-invalid"))
            (reason (element 2 result))
            (detail (element 3 reason))
            (workspace (map-get detail 'workspace)))
      (equal 'error (element 1 result))
      (equal 'engine (element 1 reason))
      (equal 'input-invalid (element 2 reason))
      (equal 'true (filelib:is_file (artifact-path workspace 'parser)))
      (equal 'true (filelib:is_file (artifact-path workspace 'grounder)))
      (equal 'true (filelib:is_file (marker-path workspace "engine.invoked")))
      (equal 'false (filelib:is_file (artifact-path workspace 'engine))))))

;;; ----------------
;;; workspace failures and cleanup safety
;;; ----------------

(defun unavailable_workdir_is_typed (_config)
  (let* ((base-file (temp-path "wolong-pipeline-base-file"))
          (_ (file:delete base-file)))
    (ok (file:write_file base-file #b("not a dir\n")))
    (set-env base-file 'true)
    (let* ((result (run-minimal))
            (reason (element 2 result))
            (detail (element 3 reason)))
      (equal 'error (element 1 result))
      (equal 'workspace (element 1 reason))
      (equal 'base-unavailable (element 2 reason))
      (equal base-file (map-get detail 'base-dir)))
    (file:delete base-file)))

(defun cleanup_refuses_outside_dispatch_workspace (_config)
  (let* ((base-dir (temp-base "unsafe-cleanup"))
          (sentinel (filename:join base-dir "sentinel.txt")))
    (ok (filelib:ensure_dir sentinel))
    (ok (file:write_file sentinel #b("keep me\n")))
    (let* ((workspace (map 'base-dir base-dir 'path base-dir 'artifacts (map)))
            (result (wolong-workspace:cleanup workspace 'false)))
      (equal 'error (element 1 result))
      (equal 'unsafe-delete (element 1 (element 2 result)))
      (equal 'true (filelib:is_dir base-dir))
      (equal 'true (filelib:is_file sentinel)))))

;;; ----------------
;;; fixtures and config
;;; ----------------

(defun run-minimal () (run-case "minimal"))

(defun run-case (name)
  (wolong-pipeline:run
    (fixture-path
      (filename:join (list "gate-contract-substrate" name "domain.hddl")))
    (fixture-path
      (filename:join (list "gate-contract-substrate" name "problem.hddl")))))

(defun set-env (base-dir keep-artifacts)
  (application:set_env 'wolong
                       'binaries
                       (map 'parser (parser-fixture)
                            'grounder (grounder-fixture)
                            'engine (engine-fixture)))
  (application:set_env 'wolong
                       'gate-timeouts
                       (map 'parse 5000 'ground 5000 'solve 5000))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir base-dir 'keep-artifacts keep-artifacts))
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
  (filename:join (list "/tmp" (lists:concat (list "wolong-pipeline-" name)))))

(defun temp-path (name)
  (filename:join (list "/tmp" name)))

;;; ----------------
;;; assertions and helpers
;;; ----------------

(defun assert-workspace-under-base (base-dir workspace)
  (let ((base-parts (filename:split (filename:absname base-dir)))
         (path-parts (filename:split (map-get workspace 'path))))
    (equal 'true (lists:prefix base-parts path-parts))))

(defun assert-artifact-roles (workspace)
  (equal "parser.htn" (filename:basename (artifact-path workspace 'parser)))
  (equal "grounder.sas" (filename:basename (artifact-path workspace 'grounder)))
  (equal "engine.plan" (filename:basename (artifact-path workspace 'engine))))

(defun assert-gate-success (detail gate)
  (let* ((gate-detail (map-get detail gate))
          (status (map-get gate-detail 'status-fields))
          (artifact (map-get gate-detail 'artifact)))
    (equal #b("ok") (map-get status 'status))
    (equal 'true (map-get artifact 'exists))
    (equal #b() (map-get gate-detail 'stdout))))

(defun artifact-path (workspace role)
  (map-get (map-get workspace 'artifacts) role))

(defun marker-path (workspace marker)
  (filename:join (map-get workspace 'path) marker))

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false
     (ct:fail (tuple 'expected expected 'actual actual)))))

(defun not-equal (unexpected actual)
  (case (=:= unexpected actual)
    ('false 'ok)
    ('true
     (ct:fail (tuple 'unexpected unexpected)))))

(defun ok (actual)
  (equal 'ok actual))
