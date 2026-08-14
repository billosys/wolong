(defmodule unit-wolong-config-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ----------------
;;; fixtures
;;; ----------------

(defun set-valid-env ()
  (application:set_env 'wolong 'binaries (map 'parser "/usr/bin/true"))
  (application:set_env 'wolong 'gate-timeouts (map 'parse 5000))
  (application:set_env 'wolong 'workdir
                        (map 'base-dir "/tmp/wolong" 'keep-artifacts 'false)))

;;; ----------------
;;; happy path
;;; ----------------

(defun validate_happy_path_test ()
  (set-valid-env)
  (is-equal `#(ok #M(binaries #M(parser "/usr/bin/true")
                     gate-timeouts #M(parse 5000)
                     workdir #M(base-dir "/tmp/wolong" keep-artifacts false)))
            (wolong-config:validate)))

;;; ----------------
;;; missing-key: one per required key
;;; ----------------

(defun validate_missing_binaries_test ()
  (set-valid-env)
  (application:unset_env 'wolong 'binaries)
  (is-equal `#(error #(config missing-key binaries)) (wolong-config:validate)))

(defun validate_missing_gate_timeouts_test ()
  (set-valid-env)
  (application:unset_env 'wolong 'gate-timeouts)
  (is-equal `#(error #(config missing-key gate-timeouts)) (wolong-config:validate)))

(defun validate_missing_workdir_test ()
  (set-valid-env)
  (application:unset_env 'wolong 'workdir)
  (is-equal `#(error #(config missing-key workdir)) (wolong-config:validate)))

;;; ----------------
;;; wrong-shape
;;; ----------------

(defun validate_binaries_wrong_shape_test ()
  (set-valid-env)
  (application:set_env 'wolong 'binaries '(not a map))
  (is-equal `#(error #(config wrong-shape binaries)) (wolong-config:validate)))

(defun validate_gate_timeouts_wrong_shape_test ()
  (set-valid-env)
  (application:set_env 'wolong 'gate-timeouts (map 'parse -1))
  (is-equal `#(error #(config wrong-shape gate-timeouts)) (wolong-config:validate)))

(defun validate_workdir_wrong_shape_test ()
  (set-valid-env)
  (application:set_env 'wolong 'workdir
                        (map 'base-dir "/tmp/wolong" 'keep-artifacts 'not-a-boolean))
  (is-equal `#(error #(config wrong-shape workdir)) (wolong-config:validate)))

;;; ----------------
;;; non-string-path
;;; ----------------

(defun validate_binaries_non_string_path_test ()
  (set-valid-env)
  (application:set_env 'wolong 'binaries (map 'parser 12345))
  (is-equal `#(error #(config non-string-path binaries parser)) (wolong-config:validate)))

(defun validate_workdir_non_string_path_test ()
  (set-valid-env)
  (application:set_env 'wolong 'workdir (map 'base-dir 12345 'keep-artifacts 'true))
  (is-equal `#(error #(config non-string-path workdir base-dir)) (wolong-config:validate)))
