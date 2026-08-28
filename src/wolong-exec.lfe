(defmodule wolong-exec
  (export
   (run 3)
   (run-stdin 4)))

;;; ----------------
;;; public API
;;; ----------------

(defun run (command args opts)
  (case (validate-input command args 'no-stdin opts)
    (`#(ok ,validated)
     (run-valid validated))
    (err err)))

(defun run-stdin (command args stdin-bytes opts)
  (case (validate-input command args stdin-bytes opts)
    (`#(ok ,validated)
     (run-valid validated))
    (err err)))

;;; ----------------
;;; input validation
;;; ----------------

(defun validate-input (command args stdin-bytes opts)
  (if (not (is-command command))
    `#(error #(exec invalid-command ,command))
    (if (not (is-args args))
      `#(error #(exec invalid-args ,args))
      (case (validate-stdin stdin-bytes)
        (`#(ok ,validated-stdin)
         (validate-opts command args validated-stdin opts))
        (err err)))))

(defun validate-stdin
  (('no-stdin)
   `#(ok no-stdin))
  ((stdin-bytes) (when (is_binary stdin-bytes))
   `#(ok ,stdin-bytes))
  ((other)
   `#(error #(exec invalid-stdin ,other))))

(defun validate-opts (command args stdin-bytes opts)
  (if (not (is_map opts))
    `#(error #(exec invalid-options ,opts))
    (let* ((timeout-ms (maps:get 'timeout-ms opts 'undefined))
            (kill-timeout-sec (maps:get 'kill-timeout-sec opts 'undefined))
            (output-limit-bytes (maps:get 'output-limit-bytes opts 'undefined))
            (stdout-limit-bytes
              (maps:get 'stdout-limit-bytes opts output-limit-bytes))
            (stderr-limit-bytes
              (maps:get 'stderr-limit-bytes opts output-limit-bytes))
            (stderr-tail-limit-bytes
              (maps:get 'stderr-tail-limit-bytes opts stderr-limit-bytes)))
      (if (not (positive-integer timeout-ms))
        `#(error #(exec invalid-options timeout-ms))
        (if (not (non-negative-integer kill-timeout-sec))
          `#(error #(exec invalid-options kill-timeout-sec))
          (if (not (positive-integer output-limit-bytes))
            `#(error #(exec invalid-options output-limit-bytes))
            (if (not (positive-integer stdout-limit-bytes))
              `#(error #(exec invalid-options stdout-limit-bytes))
              (if (not (positive-integer stderr-limit-bytes))
                `#(error #(exec invalid-options stderr-limit-bytes))
                (if (not (positive-integer stderr-tail-limit-bytes))
                  `#(error #(exec invalid-options stderr-tail-limit-bytes))
                  (case (resolve-command command)
                    (`#(ok ,resolved-command)
                     `#(ok
                        #M(command ,resolved-command
                                   args ,args
                                   stdin-bytes ,stdin-bytes
                                   timeout-ms ,timeout-ms
                                   kill-timeout-sec ,kill-timeout-sec
                                   output-limit-bytes ,output-limit-bytes
                                   stdout-limit-bytes ,stdout-limit-bytes
                                   stderr-limit-bytes ,stderr-limit-bytes
                                   stderr-tail-limit-bytes
                                   ,stderr-tail-limit-bytes)))
                    (err err)))))))))))

(defun resolve-command (command)
  (let ((command-list (unicode:characters_to_list command)))
    (if (path-like-command command-list)
      (if (filelib:is_file command-list)
        `#(ok ,command)
        `#(error #(exec command-not-found ,command)))
      (case (os:find_executable command-list)
        ('false
         `#(error #(exec command-not-found ,command)))
        (resolved
         `#(ok ,resolved))))))

(defun path-like-command (command-list)
  (=/= command-list (filename:basename command-list)))

(defun is-command (value)
  (orelse (is_binary value)
          (andalso (is_list value) (io_lib:printable_unicode_list value))))

(defun is-args
  (('()) 'true)
  ((`(,arg . ,rest))
   (andalso (is-command arg) (is-args rest)))
  ((_other) 'false))

(defun positive-integer (value)
  (andalso (is_integer value) (> value 0)))

(defun non-negative-integer (value)
  (andalso (is_integer value) (>= value 0)))

;;; ----------------
;;; erlexec lifecycle
;;; ----------------

(defun run-valid (validated)
  (let* ((command (maps:get 'command validated))
          (args (maps:get 'args validated))
          (timeout-ms (maps:get 'timeout-ms validated))
          (kill-timeout-sec (maps:get 'kill-timeout-sec validated))
          (output-limit-bytes (maps:get 'output-limit-bytes validated))
          (stdout-limit-bytes (maps:get 'stdout-limit-bytes validated))
          (stderr-limit-bytes (maps:get 'stderr-limit-bytes validated))
          (stderr-tail-limit-bytes
            (maps:get 'stderr-tail-limit-bytes validated))
          (stdin-bytes (maps:get 'stdin-bytes validated))
          (argv (cons command args))
          (options (run-options kill-timeout-sec stdin-bytes))
          (started-at (now-ms)))
    (case (exec:run argv options)
      (`#(ok ,pid ,os-pid)
       (case (send-stdin pid stdin-bytes)
         ('ok
          (collect-until-exit pid os-pid timeout-ms kill-timeout-sec
                              (empty-capture output-limit-bytes
                                             stdout-limit-bytes
                                             stderr-limit-bytes
                                             stderr-tail-limit-bytes)
                              started-at))
         (`#(error ,reason)
          (let ((_stop-result (exec:stop pid)))
            `#(error #(exec stdin-send-failed ,reason))))))
      (`#(error ,reason)
       `#(error #(exec start-failed ,reason))))))

(defun run-options
  ((kill-timeout-sec 'no-stdin)
   (base-run-options kill-timeout-sec))
  ((kill-timeout-sec _stdin-bytes)
   (cons 'stdin (base-run-options kill-timeout-sec))))

(defun base-run-options (kill-timeout-sec)
  (list 'monitor 'stdout 'stderr 'kill_group
        (tuple 'group 0)
        (tuple 'kill_timeout kill-timeout-sec)))

(defun send-stdin
  ((_pid 'no-stdin) 'ok)
  ((pid stdin-bytes)
   (case (safe-exec-send pid stdin-bytes)
     ('ok
      (safe-exec-send pid 'eof))
     (err err))))

(defun safe-exec-send (pid data)
  (try
    (exec:send pid data)
    (catch
      (`#(,class ,reason ,stacktrace)
       `#(error #(,class ,reason ,stacktrace))))))

(defun collect-until-exit (pid os-pid
                               timeout-ms
                               kill-timeout-sec
                               capture
                               started-at)
  (let ((remaining (remaining-ms started-at timeout-ms)))
    (receive
      (`#(stdout ,os-pid ,data)
       (collect-until-exit pid os-pid timeout-ms kill-timeout-sec
                           (capture-output 'stdout data capture) started-at))
      (`#(stderr ,os-pid ,data)
       (collect-until-exit pid os-pid timeout-ms kill-timeout-sec
                           (capture-output 'stderr data capture) started-at))
      (`#(DOWN ,os-pid process ,pid normal)
       `#(ok ,(completed-result 0 os-pid capture started-at)))
      (`#(DOWN ,os-pid process ,pid #(exit_status ,status))
       (case (exec:status status)
         (`#(status 127)
          `#(error
             #(exec command-not-found
                    #M(os-pid ,os-pid
                              stdout ,(maps:get 'stdout capture)
                              stderr ,(maps:get 'stderr capture)
                              duration-ms ,(- (now-ms) started-at)))))
         (`#(status ,exit-status)
          `#(ok ,(completed-result exit-status os-pid capture started-at)))
         (`#(signal ,signal ,core)
          `#(ok ,(signaled-result signal core os-pid capture started-at)))))
      (after remaining
        (timeout-process pid os-pid kill-timeout-sec capture started-at)))))

(defun timeout-process (pid os-pid kill-timeout-sec capture started-at)
  (let ((kill-result (exec:stop pid))
         (wait-ms (+ (* kill-timeout-sec 1000) 2000)))
    (wait-after-timeout pid os-pid kill-timeout-sec capture started-at
                        kill-result wait-ms)))

(defun wait-after-timeout (pid os-pid
                               kill-timeout-sec
                               capture
                               started-at
                               kill-result
                               wait-ms)
  (receive
    (`#(stdout ,os-pid ,data)
     (wait-after-timeout pid os-pid kill-timeout-sec
                         (capture-output 'stdout data capture) started-at
                         kill-result wait-ms))
    (`#(stderr ,os-pid ,data)
     (wait-after-timeout pid os-pid kill-timeout-sec
                         (capture-output 'stderr data capture) started-at
                         kill-result wait-ms))
    (`#(DOWN ,os-pid process ,pid ,reason)
     `#(timeout
        ,(timeout-result os-pid capture started-at kill-timeout-sec
                         kill-result reason 'false)))
    (after wait-ms
      (let ((sigkill-result (exec:kill pid 'sigkill)))
        (wait-after-sigkill pid os-pid kill-timeout-sec capture
                            started-at
                            `#(,kill-result ,sigkill-result))))))

(defun wait-after-sigkill (pid os-pid
                               kill-timeout-sec
                               capture
                               started-at
                               kill-result)
  (receive
    (`#(stdout ,os-pid ,data)
     (wait-after-sigkill pid os-pid kill-timeout-sec
                         (capture-output 'stdout data capture) started-at
                         kill-result))
    (`#(stderr ,os-pid ,data)
     (wait-after-sigkill pid os-pid kill-timeout-sec
                         (capture-output 'stderr data capture) started-at
                         kill-result))
    (`#(DOWN ,os-pid process ,pid ,reason)
     `#(timeout
        ,(timeout-result os-pid capture started-at kill-timeout-sec
                         kill-result reason 'true)))
    (after 1000
      `#(timeout
         ,(timeout-result os-pid capture started-at kill-timeout-sec
                          kill-result 'kill-timeout 'true)))))

;;; ----------------
;;; output capture
;;; ----------------

(defun empty-capture (output-limit stdout-limit stderr-limit stderr-tail-limit)
  (map 'stdout #b()
       'stderr #b()
       'stderr-tail #b()
       'stdout-bytes 0
       'stderr-bytes 0
       'stdout-truncated 'false
       'stderr-truncated 'false
       'output-limit-bytes output-limit
       'stdout-limit-bytes stdout-limit
       'stderr-limit-bytes stderr-limit
       'stderr-tail-limit-bytes stderr-tail-limit))

(defun capture-output (stream data capture)
  (let* ((bytes-key (stream-key stream 'bytes))
          (data-key stream)
          (truncated-key (stream-key stream 'truncated))
          (limit (maps:get (stream-key stream 'limit) capture))
          (captured (maps:get bytes-key capture))
          (incoming (byte_size data))
          (new-observed (+ captured incoming))
          (remaining (- limit captured))
          (new-data (append-capped (maps:get data-key capture) data remaining))
          (truncated
            (orelse (maps:get truncated-key capture) (> new-observed limit))))
    (capture-stderr-tail
      stream
      data
      (maps:put truncated-key truncated
                (maps:put bytes-key new-observed
                          (maps:put data-key new-data capture))))))

(defun append-capped (current data remaining)
  (if (=< remaining 0)
    current
    (let ((take (erlang:min remaining (byte_size data))))
      (if (=:= take (byte_size data))
        (iolist_to_binary (list current data))
        (iolist_to_binary (list current (binary:part data 0 take)))))))

(defun capture-stderr-tail
  (('stderr data capture)
   (let ((tail-limit (maps:get 'stderr-tail-limit-bytes capture))
          (current-tail (maps:get 'stderr-tail capture)))
     (maps:put 'stderr-tail
               (append-tail-capped current-tail data tail-limit)
               capture)))
  ((_stream _data capture) capture))

(defun append-tail-capped (current data limit)
  (let* ((combined (iolist_to_binary (list current data)))
          (combined-bytes (byte_size combined)))
    (if (=< combined-bytes limit)
      combined
      (binary:part combined (- combined-bytes limit) limit))))

(defun stream-key
  (('stdout 'bytes) 'stdout-bytes)
  (('stderr 'bytes) 'stderr-bytes)
  (('stdout 'truncated) 'stdout-truncated)
  (('stderr 'truncated) 'stderr-truncated)
  (('stdout 'limit) 'stdout-limit-bytes)
  (('stderr 'limit) 'stderr-limit-bytes))

;;; ----------------
;;; result builders
;;; ----------------

(defun completed-result (exit-status os-pid capture started-at)
  (maps:merge (base-result os-pid capture started-at)
              (map 'exit-status exit-status 'timed-out 'false)))

(defun signaled-result (signal core os-pid capture started-at)
  (maps:merge (base-result os-pid capture started-at)
              (map 'exit-status 'undefined
                   'signal signal
                   'core-dump core
                   'timed-out 'false)))

(defun timeout-result (os-pid capture
                              started-at
                              kill-timeout-sec
                              kill-result
                              reason
                              escalated)
  (maps:merge (base-result os-pid capture started-at)
              (map 'exit-status 'undefined
                   'timed-out 'true
                   'timeout 'true
                   'kill-timeout-sec kill-timeout-sec
                   'kill-result kill-result
                   'kill-reason reason
                   'kill-escalated escalated)))

(defun base-result (os-pid capture started-at)
  (map 'os-pid os-pid
       'stdout (maps:get 'stdout capture)
       'stderr (maps:get 'stderr capture)
       'stderr-tail (maps:get 'stderr-tail capture)
       'duration-ms (- (now-ms) started-at)
       'output-limit-bytes (maps:get 'output-limit-bytes capture)
       'stdout-limit-bytes (maps:get 'stdout-limit-bytes capture)
       'stderr-limit-bytes (maps:get 'stderr-limit-bytes capture)
       'stderr-tail-limit-bytes (maps:get 'stderr-tail-limit-bytes capture)
       'stdout-bytes (maps:get 'stdout-bytes capture)
       'stderr-bytes (maps:get 'stderr-bytes capture)
       'stdout-truncated (maps:get 'stdout-truncated capture)
       'stderr-truncated (maps:get 'stderr-truncated capture)))

(defun now-ms () (erlang:monotonic_time 'millisecond))

(defun remaining-ms (started-at timeout-ms)
  (erlang:max 0 (- timeout-ms (- (now-ms) started-at))))
