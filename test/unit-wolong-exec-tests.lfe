(defmodule unit-wolong-exec-tests
  (behaviour ltest-unit)
  (export all))

(include-lib "ltest/include/ltest-macros.lfe")

;;; ----------------
;;; fixtures
;;; ----------------

(defun opts ()
  (map 'timeout-ms 1000
       'kill-timeout-sec 1
       'output-limit-bytes 65536))

(defun small-output-opts ()
  (map 'timeout-ms 1000
       'kill-timeout-sec 1
       'output-limit-bytes 25))

(defun fixture (name)
  (filename:join (list "test" "fixtures" "exec-runner" name)))

(defun sh-cmd () "/bin/sh")

(defun run-fixture (name args opts-map)
  (is-equal 'ok (element 1 (application:ensure_all_started 'wolong)))
  (wolong-exec:run (sh-cmd) (cons (fixture name) args) opts-map))

(defun result-value (result)
  (element 2 result))

(defun result-get (m key)
  (map-get m key))

(defun process-alive? (pid)
  (=:= "0\n" (os:cmd (lists:flatten (io_lib:format "kill -0 ~s >/dev/null 2>&1; echo $?"
                                                   (list pid))))))

(defun wait-until-process-gone (pid attempts)
  (if (=< attempts 0)
      (not (process-alive? pid))
      (if (process-alive? pid)
          (progn
            (timer:sleep 100)
            (wait-until-process-gone pid (- attempts 1)))
          'true)))

;;; ----------------
;;; completed processes
;;; ----------------

(defun exit_zero_captures_stdout_stderr_test ()
  (let* ((result (run-fixture "exit-with-output.sh" '("0") (opts)))
         (value (result-value result)))
    (is-equal 'ok (element 1 result))
    (is-equal 0 (result-get value 'exit-status))
    (is-equal #b("stdout:ok\n") (result-get value 'stdout))
    (is-equal #b("stderr:ok\n") (result-get value 'stderr))
    (is-equal 'false (result-get value 'timed-out))))

(defun nonzero_exit_is_completed_result_test ()
  (let* ((result (run-fixture "exit-with-output.sh" '("7") (opts)))
         (value (result-value result)))
    (is-equal 'ok (element 1 result))
    (is-equal 7 (result-get value 'exit-status))
    (is-equal #b("stdout:ok\n") (result-get value 'stdout))
    (is-equal #b("stderr:ok\n") (result-get value 'stderr))))

(defun argv_metacharacters_arrive_unchanged_test ()
  (let* ((argument "alpha beta ; $HOME && echo nope | cat")
         (result (run-fixture "argv-echo.sh" (list argument) (opts)))
         (value (result-value result)))
    (is-equal 'ok (element 1 result))
    (is-equal (unicode:characters_to_binary (++ argument "\n")) (result-get value 'stdout))))

;;; ----------------
;;; failures and recovery
;;; ----------------

(defun bad_executable_is_typed_exec_error_and_app_recovers_test ()
  (let ((bad (wolong-exec:run "wolong-missing-executable-for-test" '() (opts))))
    (is-equal 'error (element 1 bad))
    (is-equal 'exec (element 1 (element 2 bad)))
    (is-not (=:= 'undefined (whereis 'wolong-sup)))
    (is-not (=:= 'undefined (whereis 'exec)))
    (is-equal 'ok (element 1 (run-fixture "exit-with-output.sh" '("0") (opts))))))

(defun simple_timeout_returns_partial_output_test ()
  (let* ((result (run-fixture "simple-timeout.sh" '() (opts)))
         (value (result-value result)))
    (is-equal 'timeout (element 1 result))
    (is-equal 'true (result-get value 'timed-out))
    (is-equal #b("before-timeout\n") (result-get value 'stdout))
    (is-equal #b("stderr-before-timeout\n") (result-get value 'stderr))))

(defun term_resistant_timeout_kills_process_and_recovers_test ()
  (let* ((pid-file (filename:join (list "/tmp" "wolong-term-resistant.pid")))
         (_ (file:delete pid-file))
         (result (run-fixture "term-resistant-timeout.sh" (list pid-file) (opts)))
         (value (result-value result))
         (`#(ok ,pid-bin) (file:read_file pid-file))
         (pid (string:trim (binary_to_list pid-bin))))
    (is-equal 'timeout (element 1 result))
    (is-equal 'true (result-get value 'timed-out))
    (is-equal 'true (wait-until-process-gone pid 20))
    (is-equal 'ok (element 1 (run-fixture "exit-with-output.sh" '("0") (opts))))
    (file:delete pid-file)))

;;; ----------------
;;; output caps
;;; ----------------

(defun stdout_and_stderr_are_capped_independently_test ()
  (let* ((result (run-fixture "output-flood.sh" '() (small-output-opts)))
         (value (result-value result)))
    (is-equal 'ok (element 1 result))
    (is-equal 25 (byte_size (result-get value 'stdout)))
    (is-equal 25 (byte_size (result-get value 'stderr)))
    (is-equal 'true (result-get value 'stdout-truncated))
    (is-equal 'true (result-get value 'stderr-truncated))
    (is-not (=:= 25 (result-get value 'stdout-bytes)))
    (is-not (=:= 25 (result-get value 'stderr-bytes)))))
