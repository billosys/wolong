(defmodule wolong-test-log-collector
  (export
   (log 2)))

;;; Minimal logger handler used only by tests: records any log event at or
;;; above the handler's configured level into a public ets table, so a test
;;; can assert "no error/crash reports occurred" instead of eyeballing output.

(defun log (log-event _handler-config)
  (case (ets:whereis 'wolong-test-log-sink)
    ('undefined 'ok)
    (_
     (ets:insert 'wolong-test-log-sink
                 (tuple (erlang:unique_integer) log-event))
     'ok)))
