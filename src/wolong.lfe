(defmodule wolong
  (export
   (validate 2)))

;;; ----------------
;;; public API
;;; ----------------

(defun validate (domain-path problem-path)
  (case (validate-path-args domain-path problem-path)
    ('ok (validate-paths domain-path problem-path))
    (err err)))

(defun validate-paths (domain-path problem-path)
  (case (wolong-config:validate)
    (`#(ok ,config)
     (case (wolong-binaries:parser)
       (`#(ok ,parser) (run-parser parser domain-path problem-path config))
       (err err)))
    (err err)))

;;; ----------------
;;; parser invocation
;;; ----------------

(defun run-parser (parser domain-path problem-path config)
  (let* ((output-path (parser-output-path config))
         (ensure-result (filelib:ensure_dir output-path)))
    (case ensure-result
      ('ok
       (let ((argv (parser-argv output-path domain-path problem-path))
             (opts (runner-opts config)))
         (classify-run (wolong-exec:run parser argv opts) output-path)))
      (`#(error ,reason)
       `#(error #(workdir unavailable ,output-path ,reason))))))

(defun parser-argv (output-path domain-path problem-path)
  (list "--supervised"
        "--status=stderr"
        "--output"
        output-path
        domain-path
        problem-path))

(defun runner-opts (config)
  (let* ((gate-timeouts (maps:get 'gate-timeouts config))
         (timeout-ms (maps:get 'parse gate-timeouts)))
    (map 'timeout-ms timeout-ms
         'kill-timeout-sec 1
         'output-limit-bytes 65536)))

(defun parser-output-path (config)
  (let* ((workdir (maps:get 'workdir config))
         (base-dir (unicode:characters_to_list (maps:get 'base-dir workdir)))
         (id (erlang:unique_integer '(positive monotonic)))
         (name (lists:flatten (io_lib:format "wolong-parser-~p.htn" (list id)))))
    (filename:join base-dir name)))

;;; ----------------
;;; result classification
;;; ----------------

(defun classify-run
  ((`#(ok ,result) output-path)
   (classify-completed result output-path))
  ((`#(timeout ,result) _output-path)
   `#(error #(parser timeout ,result)))
  ((`#(error #(exec ,reason ,detail)) _output-path)
   `#(error #(parser exec ,reason ,detail))))

(defun classify-completed (result output-path)
  (let ((exit-status (maps:get 'exit-status result))
        (stderr (maps:get 'stderr result)))
    (case (parse-status stderr)
      (`#(ok ,fields)
       (classify-status exit-status fields result output-path))
      (`#(error ,reason)
       `#(error #(parser status-missing ,reason ,(result-detail result (fields-absent))))))))

(defun classify-status (exit-status fields result output-path)
  (case (tuple exit-status (maps:get 'status fields 'undefined))
    (`#(0 #b("ok"))
     `#(ok ,(maps:put 'artifact (artifact-metadata output-path)
                      (result-detail result fields))))
    (`#(20 #b("input_unavailable"))
     `#(error #(missing-file ,(result-detail result fields))))
    (`#(21 #b("output_unavailable"))
     `#(error #(output-unavailable ,(result-detail result fields))))
    (`#(22 #b("input_invalid"))
     `#(error #(invalid-hddl ,(maps:put 'invalid-kind 'undistinguished
                                         (result-detail result fields)))))
    (_ `#(error #(parser unmapped-status ,(result-detail result fields))))))

(defun result-detail (runner-result status-fields)
  (map 'gate 'parser
       'status-fields status-fields
       'exit-status (maps:get 'exit-status runner-result)
       'stdout (maps:get 'stdout runner-result)
       'stderr (maps:get 'stderr runner-result)
       'duration-ms (maps:get 'duration-ms runner-result)
       'output-limit-bytes (maps:get 'output-limit-bytes runner-result)
       'stdout-bytes (maps:get 'stdout-bytes runner-result)
       'stderr-bytes (maps:get 'stderr-bytes runner-result)
       'stdout-truncated (maps:get 'stdout-truncated runner-result)
       'stderr-truncated (maps:get 'stderr-truncated runner-result)))

(defun fields-absent ()
  (map))

(defun artifact-metadata (output-path)
  (case (file:read_file_info output-path)
    (`#(ok ,info)
     (map 'path output-path
          'exists 'true
          'bytes (element 2 info)))
    (`#(error ,reason)
     (map 'path output-path
          'exists 'false
          'error reason))))

;;; ----------------
;;; PANDAPI_STATUS parser
;;; ----------------

(defun parse-status (stderr)
  (case (find-status-line (binary:split stderr #b("\n") '(global)))
    ('undefined `#(error missing-status-line))
    (line `#(ok ,(parse-status-fields (status-payload line))))))

(defun find-status-line
  (('()) 'undefined)
  ((`(,line . ,rest))
   (case (status-line? line)
     ('true line)
     ('false (find-status-line rest)))))

(defun status-line? (line)
  (case (binary:match line #b("PANDAPI_STATUS\t"))
    (`#(0 ,_) 'true)
    (_ 'false)))

(defun status-payload (line)
  (let ((prefix-len (byte_size #b("PANDAPI_STATUS\t"))))
    (binary:part line prefix-len (- (byte_size line) prefix-len))))

(defun parse-status-fields (payload)
  (parse-status-field-list (binary:split payload #b("\t") '(global)) (map)))

(defun parse-status-field-list
  (('() acc) acc)
  ((`(,field . ,rest) acc)
   (case (binary:split field #b("="))
     (`(,key ,value)
      (let ((mapped-key (field-key key)))
        (parse-status-field-list rest
                                 (maps:put mapped-key
                                           (field-value mapped-key value)
                                           acc))))
     (_ (parse-status-field-list rest acc)))))

(defun field-key
  ((#b("status")) 'status)
  ((#b("component")) 'component)
  ((#b("surface")) 'surface)
  ((#b("surface_disposition")) 'surface-disposition)
  ((#b("exit_code")) 'exit-code)
  ((#b("class")) 'class)
  ((#b("outcome")) 'outcome)
  ((#b("artifact")) 'artifact)
  ((#b("partial_output_policy")) 'partial-output-policy)
  ((#b("path_role")) 'path-role)
  ((#b("operation")) 'operation)
  ((key) key))

(defun field-value
  (('exit-code value) (binary_to_integer value))
  ((_key value) value))

;;; ----------------
;;; input validation
;;; ----------------

(defun validate-path-args (domain-path problem-path)
  (if (not (path-string? domain-path))
      `#(error #(invalid-argument domain-path ,domain-path))
      (if (not (path-string? problem-path))
          `#(error #(invalid-argument problem-path ,problem-path))
          'ok)))

(defun path-string? (path)
  (orelse (is_binary path)
          (andalso (is_list path) (io_lib:printable_unicode_list path))))
