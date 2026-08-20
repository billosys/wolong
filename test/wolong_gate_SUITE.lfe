(defmodule wolong_gate_SUITE
  (export
   (all 0)
   (end_per_testcase 2)
   (engine_domain_no_plan_distinct_from_failures 1)
   (engine_domain_no_plan_success_shape 1)
   (locator_missing_component_is_typed 1)
   (locator_non_executable_component_is_typed 1)
   (locator_resolves_all_components 1)
   (mapper_covers_managed_status_vocabulary 1)
   (mapper_exec_error_is_typed 1)
   (mapper_status_exit_code_mismatch_is_typed 1)
   (status_parser_malformed_fields 1)
   (status_parser_missing_record 1)
   (status_parser_multiline_uses_final_record 1)
   (status_parser_numeric_exit_code 1)
   (status_parser_unknown_field_preserved 1)
   (status_parser_valid_record 1)
   (suite 0)
   (supervised_parse_ground_solve_fixture 1)))

(defun all ()
  '(locator_resolves_all_components
     locator_missing_component_is_typed
     locator_non_executable_component_is_typed
     status_parser_valid_record
     status_parser_missing_record
     status_parser_malformed_fields
     status_parser_numeric_exit_code
     status_parser_multiline_uses_final_record
     status_parser_unknown_field_preserved
     mapper_covers_managed_status_vocabulary
     mapper_exec_error_is_typed
     mapper_status_exit_code_mismatch_is_typed
     engine_domain_no_plan_success_shape
     engine_domain_no_plan_distinct_from_failures
     supervised_parse_ground_solve_fixture))

(defun suite () `(#(timetrap #(seconds 30))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  'ok)

;;; ----------------
;;; locator
;;; ----------------

(defun locator_resolves_all_components (_config)
  (set-env)
  (equal `#(ok ,(parser-fixture)) (wolong-binaries:parser))
  (equal `#(ok ,(grounder-fixture)) (wolong-binaries:grounder))
  (equal `#(ok ,(engine-fixture)) (wolong-binaries:engine)))

(defun locator_missing_component_is_typed (_config)
  (set-env)
  (application:set_env 'wolong
                       'binaries
                       (map 'parser (parser-fixture) 'engine (engine-fixture)))
  (let ((result (wolong-binaries:grounder)))
    (equal 'error (element 1 result))
    (equal #(binary missing-config grounder) (element 2 result))))

(defun locator_non_executable_component_is_typed (_config)
  (let ((path (temp-path "wolong-non-executable-grounder")))
    (ok (file:write_file path #b("#!/bin/sh\nexit 0\n")))
    (ok (file:change_mode path 420))
    (set-env)
    (application:set_env 'wolong
                         'binaries
                         (map 'parser (parser-fixture)
                              'grounder path
                              'engine (engine-fixture)))
    (let ((result (wolong-binaries:grounder)))
      (equal 'error (element 1 result))
      (equal 'binary (element 1 (element 2 result)))
      (equal 'non-executable (element 2 (element 2 result)))
      (equal 'grounder (element 3 (element 2 result))))
    (file:delete path)))

;;; ----------------
;;; shared status parser
;;; ----------------

(defun status_parser_valid_record (_config)
  (let* ((result
           (wolong-status:parse
             #b("note\nPANDAPI_STATUS\tstatus=ok\tcomponent=parser\texit_code=0\tartifact=file\n")))
          (fields (element 2 result)))
    (equal 'ok (element 1 result))
    (equal #b("ok") (map-get fields 'status))
    (equal #b("parser") (map-get fields 'component))
    (equal 0 (map-get fields 'exit-code))
    (equal #b("file") (map-get fields 'artifact))))

(defun status_parser_missing_record (_config)
  (equal #(error missing-status-line)
         (wolong-status:parse #b("diagnostic only\n"))))

(defun status_parser_malformed_fields (_config)
  (let* ((result
           (wolong-status:parse
             #b("PANDAPI_STATUS\tstatus=ok\tbroken-field\texit_code=NaN\tcomponent=parser\n")))
          (fields (element 2 result)))
    (equal 'ok (element 1 result))
    (equal #b("ok") (map-get fields 'status))
    (equal #b("NaN") (map-get fields 'exit-code))
    (equal 'undefined (maps:get #b("broken-field") fields 'undefined))))

(defun status_parser_numeric_exit_code (_config)
  (let* ((result
           (wolong-status:parse
             #b("PANDAPI_STATUS\tstatus=input_invalid\texit_code=22\n")))
          (fields (element 2 result)))
    (equal 22 (map-get fields 'exit-code))))

(defun status_parser_multiline_uses_final_record (_config)
  (let* ((stderr
           #b("PANDAPI_STATUS\tstatus=input_invalid\texit_code=22\nnoise\nPANDAPI_STATUS\tstatus=ok\texit_code=0\n"))
          (result (wolong-status:parse stderr))
          (fields (element 2 result)))
    (equal #b("ok") (map-get fields 'status))
    (equal 0 (map-get fields 'exit-code))))

(defun status_parser_unknown_field_preserved (_config)
  (let* ((result
           (wolong-status:parse
             #b("PANDAPI_STATUS\tstatus=ok\texit_code=0\tnew_field=value\n")))
          (fields (element 2 result)))
    (equal #b("value") (map-get fields #b("new_field")))))

;;; ----------------
;;; shared mapper
;;; ----------------

(defun mapper_covers_managed_status_vocabulary (_config)
  (let ((output-path (temp-path "wolong-gate-mapper.plan")))
    (ok (file:write_file output-path #b("artifact\n")))
    (assert-mapped 'parser 0 #b("ok") 'ok 'undefined output-path)
    (assert-mapped 'parser
                   10
                   #b("cli_usage_error")
                   'error
                   'cli-usage-error
                   output-path)
    (assert-mapped 'parser
                   20
                   #b("input_unavailable")
                   'error
                   'input-unavailable
                   output-path)
    (assert-mapped 'parser
                   21
                   #b("output_unavailable")
                   'error
                   'output-unavailable
                   output-path)
    (assert-mapped 'parser
                   22
                   #b("input_invalid")
                   'error
                   'input-invalid
                   output-path)
    (assert-mapped 'parser
                   30
                   #b("unsupported_feature")
                   'error
                   'unsupported-feature
                   output-path)
    (assert-mapped 'parser
                   31
                   #b("legacy_surface")
                   'error
                   'legacy-surface
                   output-path)
    (assert-mapped 'parser
                   32
                   #b("experimental_surface")
                   'error
                   'experimental-surface
                   output-path)
    (assert-mapped 'parser
                   33
                   #b("future_surface")
                   'error
                   'future-surface
                   output-path)
    (assert-mapped 'parser 40 #b("timeout") 'error 'managed-timeout output-path)
    (assert-mapped 'parser
                   41
                   #b("resource_limit")
                   'error
                   'resource-limit
                   output-path)
    (assert-mapped 'parser 42 #b("interrupted") 'error 'interrupted output-path)
    (assert-mapped 'parser
                   50
                   #b("dependency_failure")
                   'error
                   'dependency-failure
                   output-path)
    (assert-mapped 'parser
                   51
                   #b("child_process_failure")
                   'error
                   'child-process-failure
                   output-path)
    (assert-mapped 'parser
                   60
                   #b("internal_error")
                   'error
                   'internal-error
                   output-path)
    (assert-mapped 'parser
                   99
                   #b("new_status")
                   'error
                   'unmapped-status
                   output-path)
    (assert-classified 'parser
                       (tuple 'ok (completed-result 0 #b("diagnostic only\n")))
                       'error 'missing-status output-path)
    (assert-classified 'parser (tuple 'ok (signaled-result 'sigterm))
                       'error 'signal-terminated output-path)
    (file:delete output-path)))

(defun mapper_exec_error_is_typed (_config)
  (let* ((result
           (wolong-gate:classify
             'parser
             #(error #(exec start-failed eacces))
             (temp-path "wolong-parser-exec.plan")))
          (reason (element 2 result)))
    (equal 'error (element 1 result))
    (equal 'exec (element 1 reason))
    (equal 'start-failed (element 2 reason))))

(defun mapper_status_exit_code_mismatch_is_typed (_config)
  (let* ((output-path (temp-path "wolong-status-mismatch.htn"))
          (result
            (wolong-gate:classify
              'parser
              (tuple 'ok
                     (completed-result
                       0
                       #b("PANDAPI_STATUS\tstatus=ok\tcomponent=parser\texit_code=22\tartifact=file\n")))
              output-path))
          (reason (element 2 result))
          (detail (element 2 reason))
          (status (map-get detail 'status-fields)))
    (equal 'error (element 1 result))
    (equal 'status-exit-mismatch (element 1 reason))
    (equal 0 (map-get detail 'exit-status))
    (equal 22 (map-get status 'exit-code))))

(defun engine_domain_no_plan_success_shape (_config)
  (let* ((output-path (temp-path "wolong-engine-no-plan.plan"))
          (result
            (wolong-gate:classify
              'engine
              (tuple 'ok
                     (completed-result
                       2
                       #b("PANDAPI_STATUS\tstatus=domain_no_plan\tcomponent=engine\texit_code=2\tclass=expected_domain_outcome\tpartial_output_policy=absent\toutcome=no_plan\n")))
              output-path))
          (detail (element 2 result))
          (status (map-get detail 'status-fields))
          (artifact (map-get detail 'artifact)))
    (equal 'domain-no-plan (element 1 result))
    (equal #b("domain_no_plan") (map-get status 'status))
    (equal #b("no_plan") (map-get status 'outcome))
    (equal 'false (map-get artifact 'exists))))

(defun engine_domain_no_plan_distinct_from_failures (_config)
  (let ((output-path (temp-path "wolong-engine-missing-artifact.plan")))
    (assert-mapped 'engine
                   22
                   #b("input_invalid")
                   'error
                   'input-invalid
                   output-path)
    (assert-classified 'engine (tuple 'timeout (completed-result 0 #b()))
                       'error 'timeout output-path)
    (assert-classified 'engine
                       (tuple 'ok
                              (completed-result
                                0
                                #b("PANDAPI_STATUS\tstatus=ok\tcomponent=engine\texit_code=0\tartifact=file\n")))
                       'error 'missing-artifact output-path)))

;;; ----------------
;;; supervised fixture chain
;;; ----------------

(defun supervised_parse_ground_solve_fixture (_config)
  (set-env)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (let* ((config (ok-value (wolong-config:validate)))
          (parser (ok-value (wolong-binaries:parser)))
          (grounder (ok-value (wolong-binaries:grounder)))
          (engine (ok-value (wolong-binaries:engine)))
          (parsed
            (wolong-gate:run-parser parser
                                    (fixture-path
                                      "gate-contract-substrate/minimal/domain.hddl")
                                    (fixture-path
                                      "gate-contract-substrate/minimal/problem.hddl")
                                    config))
          (parsed-detail (element 2 parsed))
          (parsed-status (map-get parsed-detail 'status-fields))
          (htn-path (map-get (map-get parsed-detail 'artifact) 'path))
          (grounded (wolong-gate:run-grounder grounder htn-path config))
          (grounded-detail (element 2 grounded))
          (grounded-status (map-get grounded-detail 'status-fields))
          (sas-path (map-get (map-get grounded-detail 'artifact) 'path))
          (solved (wolong-gate:run-engine engine sas-path config))
          (solved-detail (element 2 solved))
          (solved-status (map-get solved-detail 'status-fields))
          (plan-artifact (map-get solved-detail 'artifact)))
    (equal 'ok (element 1 parsed))
    (equal 'ok (element 1 grounded))
    (equal 'ok (element 1 solved))
    (equal #b("ok") (map-get parsed-status 'status))
    (equal #b("parser") (map-get parsed-status 'component))
    (equal #b("ok") (map-get grounded-status 'status))
    (equal #b("grounder") (map-get grounded-status 'component))
    (equal #b("ok") (map-get solved-status 'status))
    (equal #b("engine") (map-get solved-status 'component))
    (equal #b("solved") (map-get solved-status 'outcome))
    (equal 'true (map-get plan-artifact 'exists))
    (not-true (=< (map-get plan-artifact 'bytes) 0))
    (equal #b() (map-get solved-detail 'stdout))))

;;; ----------------
;;; fixtures and config
;;; ----------------

(defun set-env ()
  (application:set_env 'wolong
                       'binaries
                       (map 'parser (parser-fixture)
                            'grounder (grounder-fixture)
                            'engine (engine-fixture)))
  (application:set_env 'wolong
                       'gate-timeouts
                       (map 'parse 5000 'ground 5000 'solve 5000))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir (temp-workdir) 'keep-artifacts 'true)))

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

(defun temp-workdir () (filename:join (list "/tmp" "wolong-gate-suite")))

(defun temp-path (name)
  (filename:join (list "/tmp" name)))

;;; ----------------
;;; synthetic runner results
;;; ----------------

(defun assert-mapped (gate exit-status
                           status
                           expected-top
                           expected-reason
                           output-path)
  (assert-classified gate
                     (tuple 'ok
                            (completed-result
                              exit-status
                              (status-record status exit-status)))
                     expected-top
                     expected-reason
                     output-path))

(defun assert-classified (gate runner-result
                               expected-top
                               expected-reason
                               output-path)
  (let ((result (wolong-gate:classify gate runner-result output-path)))
    (equal expected-top (element 1 result))
    (case expected-top
      ('ok 'ok)
      ('domain-no-plan 'ok)
      ('error
       (equal expected-reason (element 1 (element 2 result)))))))

(defun status-record (status exit-status)
  (iolist_to_binary
    (list #b("PANDAPI_STATUS\tstatus=") status
          #b("\tcomponent=parser\texit_code=")
          (integer_to_binary exit-status)
          #b("\n"))))

(defun completed-result (exit-status stderr)
  (map 'exit-status exit-status
       'stdout #b()
       'stderr stderr
       'duration-ms 1
       'output-limit-bytes 65536
       'stdout-bytes 0
       'stderr-bytes (byte_size stderr)
       'stdout-truncated 'false
       'stderr-truncated 'false
       'timed-out 'false))

(defun signaled-result (signal)
  (map 'exit-status 'undefined
       'signal signal
       'core-dump 'false
       'stdout #b()
       'stderr #b()
       'duration-ms 1
       'output-limit-bytes 65536
       'stdout-bytes 0
       'stderr-bytes 0
       'stdout-truncated 'false
       'stderr-truncated 'false
       'timed-out 'false))

(defun ok-value
  ((`#(ok ,value)) value)
  ((other)
   (ct:fail other)))

;;; ----------------
;;; assertions
;;; ----------------

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false
     (ct:fail (tuple 'expected expected 'actual actual)))))

(defun ok (actual)
  (equal 'ok actual))

(defun not-true (actual)
  (case actual
    ('false 'ok)
    (_
     (ct:fail (tuple 'expected-not-true actual)))))
