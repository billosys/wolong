(defmodule wolong_parser_SUITE
  (export
   (all 0)
   (suite 0)
   (end_per_testcase 2)
   (locator_missing_parser_is_typed 1)
   (locator_non_executable_parser_is_typed 1)
   (valid_pair_maps_success 1)
   (missing_input_maps_missing_file 1)
   (broken_syntax_maps_invalid_hddl 1)
   (broken_reference_maps_invalid_hddl 1)))

(defun all ()
  '(locator_missing_parser_is_typed
    locator_non_executable_parser_is_typed
    valid_pair_maps_success
    missing_input_maps_missing_file
    broken_syntax_maps_invalid_hddl
    broken_reference_maps_invalid_hddl))

(defun suite ()
  `(#(timetrap #(seconds 30))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  'ok)

;;; ----------------
;;; locator
;;; ----------------

(defun locator_missing_parser_is_typed (_config)
  (set-env (fixture-path "parser-validate/no-such-parser"))
  (let ((result (wolong-binaries:parser)))
    (equal 'error (element 1 result))
    (equal 'binary (element 1 (element 2 result)))
    (equal 'missing (element 2 (element 2 result)))
    (equal 'parser (element 3 (element 2 result)))))

(defun locator_non_executable_parser_is_typed (_config)
  (let ((path (temp-path "wolong-non-executable-parser")))
    (ok (file:write_file path #b("#!/bin/sh\nexit 0\n")))
    (ok (file:change_mode path 420))
    (set-env path)
    (let ((result (wolong-binaries:parser)))
      (equal 'error (element 1 result))
      (equal 'binary (element 1 (element 2 result)))
      (equal 'non-executable (element 2 (element 2 result)))
      (equal 'parser (element 3 (element 2 result))))
    (file:delete path)))

;;; ----------------
;;; public parser validation API
;;; ----------------

(defun valid_pair_maps_success (_config)
  (set-env (parser-fixture))
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (let* ((result (wolong:validate (fixture-path "parser-validate/minimal/domain.hddl")
                                  (fixture-path "parser-validate/minimal/problem.hddl")))
         (detail (element 2 result))
         (status (map-get detail 'status-fields))
         (artifact (map-get detail 'artifact)))
    (ok (element 1 result))
    (equal #b("ok") (map-get status 'status))
    (equal #b("parser") (map-get status 'component))
    (equal 0 (map-get status 'exit-code))
    (equal #b("file") (map-get status 'artifact))
    (equal 'true (map-get artifact 'exists))
    (not-true (=< (map-get artifact 'bytes) 0))
    (equal #b() (map-get detail 'stdout))))

(defun missing_input_maps_missing_file (_config)
  (set-env (parser-fixture))
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (let* ((result (wolong:validate (fixture-path "parser-validate/minimal/no-domain.hddl")
                                  (fixture-path "parser-validate/minimal/problem.hddl")))
         (reason (element 2 result))
         (detail (element 2 reason))
         (status (map-get detail 'status-fields)))
    (equal 'error (element 1 result))
    (equal 'missing-file (element 1 reason))
    (equal #b("input_unavailable") (map-get status 'status))
    (equal #b("parser") (map-get status 'component))
    (equal 20 (map-get status 'exit-code))
    (equal #b("domain") (map-get status 'path-role))))

(defun broken_syntax_maps_invalid_hddl (_config)
  (set-env (parser-fixture))
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (assert-invalid-hddl
   (wolong:validate (fixture-path "parser-validate/broken-syntax/domain.hddl")
                    (fixture-path "parser-validate/broken-syntax/problem.hddl"))))

(defun broken_reference_maps_invalid_hddl (_config)
  (set-env (parser-fixture))
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (assert-invalid-hddl
   (wolong:validate (fixture-path "parser-validate/broken-reference/domain.hddl")
                    (fixture-path "parser-validate/broken-reference/problem.hddl"))))

(defun assert-invalid-hddl (result)
  (let* ((reason (element 2 result))
         (detail (element 2 reason))
         (status (map-get detail 'status-fields)))
    (equal 'error (element 1 result))
    (equal 'invalid-hddl (element 1 reason))
    (equal 'undistinguished (map-get detail 'invalid-kind))
    (equal #b("input_invalid") (map-get status 'status))
    (equal #b("parser") (map-get status 'component))
    (equal 22 (map-get status 'exit-code))))

;;; ----------------
;;; fixtures and config
;;; ----------------

(defun set-env (parser-path)
  (application:set_env 'wolong 'binaries (map 'parser parser-path))
  (application:set_env 'wolong 'gate-timeouts (map 'parse 5000))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir (temp-workdir) 'keep-artifacts 'true)))

(defun parser-fixture ()
  (fixture-path "parser-validate/pandapi-parser-fixture.sh"))

(defun fixture-path (relative)
  (filename:join (list (project-root) "test" "fixtures" relative)))

(defun project-root ()
  (filename:absname
   (filename:join (list (code:lib_dir 'wolong) ".." ".." ".." ".."))))

(defun temp-workdir ()
  (filename:join (list "/tmp" "wolong-parser-suite")))

(defun temp-path (name)
  (filename:join (list "/tmp" name)))

;;; ----------------
;;; assertions
;;; ----------------

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false (ct:fail (tuple 'expected expected 'actual actual)))))

(defun ok (actual)
  (equal 'ok actual))

(defun not-true (actual)
  (case actual
    ('false 'ok)
    (_ (ct:fail (tuple 'expected-not-true actual)))))
