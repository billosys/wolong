(defmodule wolong_exec_SUITE
  (export
   (all 0)
   (app_start_stop_clean 1)
   (argv_metacharacters_arrive_unchanged 1)
   (bad_executable_is_typed_exec_error_and_app_recovers 1)
   (direct_erlexec_missing_command_errors 1)
   (direct_erlexec_true_ok 1)
   (empty_stdin_sends_eof 1)
   (end_per_testcase 2)
   (exit_zero_captures_stdout_stderr 1)
   (invalid_stdin_shape_is_typed_exec_error 1)
   (nonzero_exit_after_stdin_is_completed_result 1)
   (nonzero_exit_is_completed_result 1)
   (simple_timeout_returns_partial_output 1)
   (stdin_argv_metacharacters_arrive_unchanged 1)
   (stdin_bytes_and_eof_are_sent 1)
   (stdin_runner_preserves_validation_errors 1)
   (stdin_term_resistant_timeout_kills_process_and_recovers 1)
   (stdout_and_stderr_are_capped_independently 1)
   (stdout_and_stderr_are_capped_independently_for_stdin 1)
   (suite 0)
   (term_resistant_timeout_kills_process_and_recovers 1)))

(defun all ()
  '(app_start_stop_clean
     direct_erlexec_true_ok
     direct_erlexec_missing_command_errors
     exit_zero_captures_stdout_stderr
     nonzero_exit_is_completed_result
     argv_metacharacters_arrive_unchanged
     stdin_bytes_and_eof_are_sent
     empty_stdin_sends_eof
     invalid_stdin_shape_is_typed_exec_error
     stdin_runner_preserves_validation_errors
     stdin_argv_metacharacters_arrive_unchanged
     nonzero_exit_after_stdin_is_completed_result
     bad_executable_is_typed_exec_error_and_app_recovers
     simple_timeout_returns_partial_output
     term_resistant_timeout_kills_process_and_recovers
     stdin_term_resistant_timeout_kills_process_and_recovers
     stdout_and_stderr_are_capped_independently
     stdout_and_stderr_are_capped_independently_for_stdin))

(defun suite () `(#(timetrap #(seconds 30))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  (remove-log-handler)
  (delete-log-sink)
  'ok)

;;; ----------------
;;; application lifecycle
;;; ----------------

(defun app_start_stop_clean (_config)
  (new-log-sink)
  (ok
    (logger:add_handler 'wolong-test-log-collector 'wolong-test-log-collector
                        (map 'level 'error)))
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (not-true (=:= 'undefined (whereis 'wolong-sup)))
  (not-true (=:= 'undefined (whereis 'exec)))
  (ok (application:stop 'wolong))
  (wait-until (lambda () (=:= 'undefined (whereis 'wolong-sup))) 20)
  (equal '() (ets:tab2list 'wolong-test-log-sink)))

;;; ----------------
;;; direct erlexec probe
;;; ----------------

(defun direct_erlexec_true_ok (_config)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (ok (element 1 (exec:run "true" '(sync stdout stderr)))))

(defun direct_erlexec_missing_command_errors (_config)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (equal 'error
         (element 1
                  (exec:run "wolong-nonexistent-cmd-xyz" '(sync stdout stderr)))))

;;; ----------------
;;; completed processes
;;; ----------------

(defun exit_zero_captures_stdout_stderr (_config)
  (let* ((result (run-fixture "exit-with-output.sh" '("0") (opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 0 (result-get value 'exit-status))
    (equal #b("stdout:ok\n") (result-get value 'stdout))
    (equal #b("stderr:ok\n") (result-get value 'stderr))
    (equal 'false (result-get value 'timed-out))))

(defun nonzero_exit_is_completed_result (_config)
  (let* ((result (run-fixture "exit-with-output.sh" '("7") (opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 7 (result-get value 'exit-status))
    (equal #b("stdout:ok\n") (result-get value 'stdout))
    (equal #b("stderr:ok\n") (result-get value 'stderr))))

(defun argv_metacharacters_arrive_unchanged (_config)
  (let* ((argument "alpha beta ; $HOME && echo nope | cat")
          (result (run-fixture "argv-echo.sh" (list argument) (opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal (unicode:characters_to_binary (++ argument "\n"))
           (result-get value 'stdout))))

;;; ----------------
;;; stdin processes
;;; ----------------

(defun stdin_bytes_and_eof_are_sent (_config)
  (let* ((result
           (run-fixture-stdin "stdin-echo-on-eof.sh" '("alpha")
                              #b("payload") (opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 0 (result-get value 'exit-status))
    (equal #b("arg:alpha\nstdin:payload\n") (result-get value 'stdout))
    (equal #b("stderr:payload\n") (result-get value 'stderr))))

(defun empty_stdin_sends_eof (_config)
  (let* ((result
           (run-fixture-stdin "stdin-echo-on-eof.sh" '("empty") #b() (opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 0 (result-get value 'exit-status))
    (equal #b("arg:empty\nstdin:\n") (result-get value 'stdout))
    (equal #b("stderr:\n") (result-get value 'stderr))))

(defun invalid_stdin_shape_is_typed_exec_error (_config)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (let ((bad
          (wolong-exec:run-stdin (sh-cmd)
                                 (list (fixture "stdin-echo-on-eof.sh") "bad")
                                 "not-a-binary"
                                 (opts))))
    (equal 'error (element 1 bad))
    (equal 'exec (element 1 (element 2 bad)))
    (equal 'invalid-stdin (element 2 (element 2 bad)))
    (ok
      (element 1
               (run-fixture-stdin "stdin-echo-on-eof.sh" '("recover")
                                  #b("ok") (opts))))))

(defun stdin_runner_preserves_validation_errors (_config)
  (let ((missing
          (wolong-exec:run-stdin "wolong-missing-executable-for-test"
                                 '() #b("payload") (opts)))
         (bad-command
           (wolong-exec:run-stdin 'not-a-command '() #b("payload") (opts)))
         (bad-args
           (wolong-exec:run-stdin (sh-cmd) '(not-an-arg) #b("payload") (opts)))
         (bad-opts
           (wolong-exec:run-stdin (sh-cmd)
                                  (list (fixture "stdin-echo-on-eof.sh"))
                                  #b("payload")
                                  (map 'timeout-ms 0
                                       'kill-timeout-sec 1
                                       'output-limit-bytes 65536))))
    (equal 'error (element 1 missing))
    (equal 'command-not-found (element 2 (element 2 missing)))
    (equal 'error (element 1 bad-command))
    (equal 'invalid-command (element 2 (element 2 bad-command)))
    (equal 'error (element 1 bad-args))
    (equal 'invalid-args (element 2 (element 2 bad-args)))
    (equal 'error (element 1 bad-opts))
    (equal 'invalid-options (element 2 (element 2 bad-opts)))))

(defun stdin_argv_metacharacters_arrive_unchanged (_config)
  (let* ((argument "alpha beta ; $HOME && echo nope | cat")
          (result
            (run-fixture-stdin "stdin-echo-on-eof.sh" (list argument)
                               #b("literal") (opts)))
          (value (result-value result))
          (expected
            (unicode:characters_to_binary
              (lists:flatten (list "arg:" argument "\nstdin:literal\n")))))
    (ok (element 1 result))
    (equal expected (result-get value 'stdout))
    (equal #b("stderr:literal\n") (result-get value 'stderr))))

(defun nonzero_exit_after_stdin_is_completed_result (_config)
  (let* ((result
           (run-fixture-stdin "stdin-nonzero.sh" '("7") #b("payload") (opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 7 (result-get value 'exit-status))
    (equal #b("stdin:payload\n") (result-get value 'stdout))
    (equal #b("stderr:payload\n") (result-get value 'stderr))))

;;; ----------------
;;; failures and recovery
;;; ----------------

(defun bad_executable_is_typed_exec_error_and_app_recovers (_config)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (let ((bad (wolong-exec:run "wolong-missing-executable-for-test" '() (opts))))
    (equal 'error (element 1 bad))
    (equal 'exec (element 1 (element 2 bad)))
    (not-true (=:= 'undefined (whereis 'wolong-sup)))
    (not-true (=:= 'undefined (whereis 'exec)))
    (ok (element 1 (run-fixture "exit-with-output.sh" '("0") (opts))))))

(defun simple_timeout_returns_partial_output (_config)
  (let* ((result (run-fixture "simple-timeout.sh" '() (opts)))
          (value (result-value result)))
    (equal 'timeout (element 1 result))
    (equal 'true (result-get value 'timed-out))
    (equal #b("before-timeout\n") (result-get value 'stdout))
    (equal #b("stderr-before-timeout\n") (result-get value 'stderr))))

(defun term_resistant_timeout_kills_process_and_recovers (_config)
  (let* ((pid-file (filename:join (list "/tmp" "wolong-term-resistant.pid")))
          (_ (file:delete pid-file))
          (result
            (run-fixture "term-resistant-timeout.sh" (list pid-file) (opts)))
          (value (result-value result))
          (`#(ok ,pid-bin) (file:read_file pid-file))
          (pid (string:trim (binary_to_list pid-bin))))
    (equal 'timeout (element 1 result))
    (equal 'true (result-get value 'timed-out))
    (equal 'true (wait-until-process-gone pid 20))
    (ok (element 1 (run-fixture "exit-with-output.sh" '("0") (opts))))
    (file:delete pid-file)))

(defun stdin_term_resistant_timeout_kills_process_and_recovers (_config)
  (let* ((pid-file
           (filename:join (list "/tmp" "wolong-stdin-term-resistant.pid")))
          (_ (file:delete pid-file))
          (result
            (run-fixture-stdin "stdin-term-resistant-timeout.sh"
                               (list pid-file) #b("payload") (opts)))
          (value (result-value result))
          (`#(ok ,pid-bin) (file:read_file pid-file))
          (pid (string:trim (binary_to_list pid-bin))))
    (equal 'timeout (element 1 result))
    (equal 'true (result-get value 'timed-out))
    (equal #b("stdin-term-resistant-started\n") (result-get value 'stdout))
    (equal #b("stdin-term-resistant-stderr\n") (result-get value 'stderr))
    (equal 'true (wait-until-process-gone pid 20))
    (ok
      (element 1
               (run-fixture-stdin "stdin-echo-on-eof.sh" '("recover")
                                  #b("ok") (opts))))
    (file:delete pid-file)))

;;; ----------------
;;; output caps
;;; ----------------

(defun stdout_and_stderr_are_capped_independently (_config)
  (let* ((result (run-fixture "output-flood.sh" '() (small-output-opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 25 (byte_size (result-get value 'stdout)))
    (equal 25 (byte_size (result-get value 'stderr)))
    (equal 'true (result-get value 'stdout-truncated))
    (equal 'true (result-get value 'stderr-truncated))
    (not-true (=:= 25 (result-get value 'stdout-bytes)))
    (not-true (=:= 25 (result-get value 'stderr-bytes)))))

(defun stdout_and_stderr_are_capped_independently_for_stdin (_config)
  (let* ((result
           (run-fixture-stdin "stdin-output-flood.sh" '()
                              #b("payload") (small-output-opts)))
          (value (result-value result)))
    (ok (element 1 result))
    (equal 25 (byte_size (result-get value 'stdout)))
    (equal 25 (byte_size (result-get value 'stderr)))
    (equal 'true (result-get value 'stdout-truncated))
    (equal 'true (result-get value 'stderr-truncated))
    (not-true (=:= 25 (result-get value 'stdout-bytes)))
    (not-true (=:= 25 (result-get value 'stderr-bytes)))))

;;; ----------------
;;; fixtures
;;; ----------------

(defun opts ()
  (map 'timeout-ms 1000 'kill-timeout-sec 1 'output-limit-bytes 65536))

(defun small-output-opts ()
  (map 'timeout-ms 1000 'kill-timeout-sec 1 'output-limit-bytes 25))

(defun fixture (name)
  (filename:join (list (project-root) "test" "fixtures" "exec-runner" name)))

(defun project-root ()
  (filename:absname
    (filename:join (list (code:lib_dir 'wolong) ".." ".." ".." ".."))))

(defun sh-cmd () "/bin/sh")

(defun run-fixture (name args opts-map)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (wolong-exec:run (sh-cmd) (cons (fixture name) args) opts-map))

(defun run-fixture-stdin (name args stdin-bytes opts-map)
  (ok (element 1 (application:ensure_all_started 'wolong)))
  (wolong-exec:run-stdin (sh-cmd) (cons (fixture name) args)
                         stdin-bytes opts-map))

(defun result-value (result)
  (element 2 result))

(defun result-get (m key)
  (map-get m key))

;;; ----------------
;;; assertions and cleanup
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

(defun process-alive? (pid)
  (=:= "0\n"
       (os:cmd
         (lists:flatten
           (io_lib:format "kill -0 ~s >/dev/null 2>&1; echo $?" (list pid))))))

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

(defun new-log-sink ()
  (delete-log-sink)
  (ets:new 'wolong-test-log-sink '(named_table public set)))

(defun delete-log-sink ()
  (case (ets:whereis 'wolong-test-log-sink)
    ('undefined 'ok)
    (_
     (ets:delete 'wolong-test-log-sink))))

(defun remove-log-handler ()
  (case (logger:remove_handler 'wolong-test-log-collector)
    ('ok 'ok)
    (`#(error #(not_found ,_)) 'ok)
    (`#(error not_found) 'ok)
    (other other)))
