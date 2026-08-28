(defmodule unit-wolong-config-tests
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ----------------
;;; fixtures
;;; ----------------

(defun set-valid-env ()
  (application:set_env 'wolong 'binaries (map 'parser "/usr/bin/true"))
  (application:set_env 'wolong 'gate-timeouts (map 'parse 5000))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir "/tmp/wolong" 'keep-artifacts 'false))
  (application:unset_env 'wolong 'output-limits))

;;; ----------------
;;; happy path
;;; ----------------

(deftest validate-happy-path
  (set-valid-env)
  (is-equal
    `#(ok
       #M(binaries
         #M(parser "/usr/bin/true")
         gate-timeouts
         #M(parse 5000)
         workdir
         #M(base-dir "/tmp/wolong"
                     keep-artifacts
                     false)))
    (wolong-config:validate)))

(deftest validate-optional-output-limits
  (set-valid-env)
  (application:set_env 'wolong
                       'output-limits
                       (map 'parser (map 'stdout 1048576 'stderr 65536)
                            'grounder (map 'stdout 1048576 'stderr 32768)
                            'engine (map 'stdout 2097152 'stderr 65536)))
  (is-equal
    `#(ok
       #M(binaries
         #M(parser "/usr/bin/true")
         gate-timeouts
         #M(parse 5000)
         output-limits
         #M(parser
           #M(stdout 1048576
                     stderr
                     65536)
           grounder
           #M(stdout 1048576
                     stderr
                     32768)
           engine
           #M(stdout 2097152
                     stderr
                     65536))
         workdir
         #M(base-dir "/tmp/wolong"
                     keep-artifacts
                     false)))
    (wolong-config:validate)))

;;; ----------------
;;; missing-key: one per required key
;;; ----------------

(deftest validate-missing-binaries
  (set-valid-env)
  (application:unset_env 'wolong 'binaries)
  (is-equal `#(error #(config missing-key binaries)) (wolong-config:validate)))

(deftest validate-missing-gate-timeouts
  (set-valid-env)
  (application:unset_env 'wolong 'gate-timeouts)
  (is-equal `#(error #(config missing-key gate-timeouts))
            (wolong-config:validate)))

(deftest validate-missing-workdir
  (set-valid-env)
  (application:unset_env 'wolong 'workdir)
  (is-equal `#(error #(config missing-key workdir)) (wolong-config:validate)))

;;; ----------------
;;; wrong-shape
;;; ----------------

(deftest validate-binaries-wrong-shape
  (set-valid-env)
  (application:set_env 'wolong 'binaries '(not a map))
  (is-equal `#(error #(config wrong-shape binaries)) (wolong-config:validate)))

(deftest validate-gate-timeouts-wrong-shape
  (set-valid-env)
  (application:set_env 'wolong 'gate-timeouts (map 'parse -1))
  (is-equal `#(error #(config wrong-shape gate-timeouts))
            (wolong-config:validate)))

(deftest validate-workdir-wrong-shape
  (set-valid-env)
  (application:set_env 'wolong 'workdir
                       (map 'base-dir
                            "/tmp/wolong"
                            'keep-artifacts
                            'not-a-boolean))
  (is-equal `#(error #(config wrong-shape workdir)) (wolong-config:validate)))

(deftest validate-output-limits-wrong-shape
  (set-valid-env)
  (application:set_env 'wolong 'output-limits '(not a map))
  (is-equal `#(error #(config wrong-shape output-limits))
            (wolong-config:validate)))

(deftest validate-output-limits-non-positive-limit
  (set-valid-env)
  (application:set_env 'wolong
                       'output-limits
                       (map 'engine (map 'stdout 0 'stderr 65536)))
  (is-equal `#(error #(config wrong-shape output-limits))
            (wolong-config:validate)))

(deftest validate-output-limits-unknown-stream
  (set-valid-env)
  (application:set_env 'wolong
                       'output-limits
                       (map 'engine (map 'diagnostics 65536)))
  (is-equal `#(error #(config wrong-shape output-limits))
            (wolong-config:validate)))

;;; ----------------
;;; non-string-path
;;; ----------------

(deftest validate-binaries-non-string-path
  (set-valid-env)
  (application:set_env 'wolong 'binaries (map 'parser 12345))
  (is-equal `#(error #(config non-string-path binaries parser))
            (wolong-config:validate)))

(deftest validate-workdir-non-string-path
  (set-valid-env)
  (application:set_env 'wolong
                       'workdir
                       (map 'base-dir 12345 'keep-artifacts 'true))
  (is-equal `#(error #(config non-string-path workdir base-dir))
            (wolong-config:validate)))
