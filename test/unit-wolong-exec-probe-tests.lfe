(defmodule unit-wolong-exec-probe-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; The arc's OQ1 probe: a supervised, synchronous erlexec call from LFE,
;;; proven against both a successful and a failing OS command. Direct
;;; `exec:run/2` calls, no wrapper module -- see arc-plan.md Version History
;;; for the recorded ergonomics verdict.

(defun run_trivial_command_ok_test ()
  (is-equal 'ok (element 1 (application:ensure_all_started 'wolong)))
  (is-equal 'ok (element 1 (exec:run "true" '(sync stdout stderr)))))

(defun run_nonexistent_command_errors_test ()
  (is-equal 'ok (element 1 (application:ensure_all_started 'wolong)))
  (is-equal 'error (element 1 (exec:run "wolong-nonexistent-cmd-xyz" '(sync stdout stderr)))))
