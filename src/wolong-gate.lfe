(defmodule wolong-gate
  (export
   (parser-argv 3)
   (grounder-argv 2)
   (engine-argv 2)
   (run-parser 4)
   (run-grounder 3)
   (run-engine 3)
   (classify 3)))

;;; ----------------
;;; public runners
;;; ----------------

(defun run-parser (parser domain-path problem-path config)
  (run-gate 'parser parser
            (parser-argv-fn domain-path problem-path)
            "htn"
            config))

(defun run-grounder (grounder htn-path config)
  (run-gate 'grounder grounder
            (grounder-argv-fn htn-path)
            "sas"
            config))

(defun run-engine (engine sas-path config)
  (run-gate 'engine engine
            (engine-argv-fn sas-path)
            "plan"
            config))

(defun classify (gate runner-result output-path)
  (case runner-result
    (`#(ok ,result)
     (classify-completed gate result output-path))
    (`#(timeout ,result)
     `#(error #(timeout ,(result-detail gate result (map) output-path))))
    (`#(error #(exec ,reason ,detail))
     `#(error #(exec ,reason ,(map 'gate gate 'exec-detail detail))))
    (`#(error ,reason)
     `#(error #(exec ,reason ,(map 'gate gate))))))

;;; ----------------
;;; argv builders
;;; ----------------

(defun parser-argv (output-path domain-path problem-path)
  (list "--supervised"
        "--status=stderr"
        "--output"
        output-path
        domain-path
        problem-path))

(defun grounder-argv (output-path htn-path)
  (list "--supervised"
        "--status=stderr"
        "--output"
        output-path
        htn-path))

(defun engine-argv (output-path sas-path)
  (list "--supervised"
        "--status=stderr"
        "--output"
        output-path
        sas-path))

(defun parser-argv-fn (domain-path problem-path)
  (lambda (output-path)
    (parser-argv output-path domain-path problem-path)))

(defun grounder-argv-fn (htn-path)
  (lambda (output-path)
    (grounder-argv output-path htn-path)))

(defun engine-argv-fn (sas-path)
  (lambda (output-path)
    (engine-argv output-path sas-path)))

;;; ----------------
;;; invocation
;;; ----------------

(defun run-gate (gate binary argv-fn extension config)
  (let* ((output-path (output-path gate extension config))
         (ensure-result (filelib:ensure_dir output-path)))
    (case ensure-result
      ('ok
       (let ((argv (funcall argv-fn output-path))
             (opts (runner-opts gate config)))
         (classify gate (wolong-exec:run binary argv opts) output-path)))
      (`#(error ,reason)
       `#(error #(workdir-unavailable
                  ,(map 'gate gate 'path output-path 'reason reason)))))))

(defun runner-opts (gate config)
  (let* ((gate-timeouts (maps:get 'gate-timeouts config))
         (timeout-ms (maps:get (timeout-key gate) gate-timeouts)))
    (map 'timeout-ms timeout-ms
         'kill-timeout-sec 1
         'output-limit-bytes 65536)))

(defun timeout-key
  (('parser) 'parse)
  (('grounder) 'ground)
  (('engine) 'solve))

(defun output-path (gate extension config)
  (let* ((workdir (maps:get 'workdir config))
         (base-dir (unicode:characters_to_list (maps:get 'base-dir workdir)))
         (id (erlang:unique_integer '(positive monotonic)))
         (name (lists:flatten
                (io_lib:format "wolong-~p-~p.~s" (list gate id extension)))))
    (filename:join base-dir name)))

;;; ----------------
;;; result classification
;;; ----------------

(defun classify-completed (gate result output-path)
  (case (maps:is_key 'signal result)
    ('true
     `#(error #(signal-terminated ,(result-detail gate result (map) output-path))))
    ('false
     (case (wolong-status:parse (maps:get 'stderr result))
       (`#(ok ,fields)
        (classify-status gate (maps:get 'exit-status result) fields result output-path))
       (`#(error ,reason)
        `#(error #(missing-status ,reason
                   ,(result-detail gate result (map) output-path))))))))

(defun classify-status (gate exit-status fields result output-path)
  (case (tuple exit-status (maps:get 'status fields 'undefined))
    (`#(0 #b("ok"))
     (classify-ok gate result fields output-path))
    (`#(2 #b("domain_no_plan"))
     (classify-domain-no-plan gate result fields output-path))
    (`#(10 #b("cli_usage_error"))
     `#(error #(cli-usage-error ,(result-detail gate result fields output-path))))
    (`#(20 #b("input_unavailable"))
     `#(error #(input-unavailable ,(result-detail gate result fields output-path))))
    (`#(21 #b("output_unavailable"))
     `#(error #(output-unavailable ,(result-detail gate result fields output-path))))
    (`#(22 #b("input_invalid"))
     `#(error #(input-invalid ,(result-detail gate result fields output-path))))
    (`#(30 #b("unsupported_feature"))
     `#(error #(unsupported-feature ,(result-detail gate result fields output-path))))
    (`#(31 #b("legacy_surface"))
     `#(error #(legacy-surface ,(result-detail gate result fields output-path))))
    (`#(32 #b("experimental_surface"))
     `#(error #(experimental-surface ,(result-detail gate result fields output-path))))
    (`#(33 #b("future_surface"))
     `#(error #(future-surface ,(result-detail gate result fields output-path))))
    (`#(40 #b("timeout"))
     `#(error #(managed-timeout ,(result-detail gate result fields output-path))))
    (`#(41 #b("resource_limit"))
     `#(error #(resource-limit ,(result-detail gate result fields output-path))))
    (`#(42 #b("interrupted"))
     `#(error #(interrupted ,(result-detail gate result fields output-path))))
    (`#(50 #b("dependency_failure"))
     `#(error #(dependency-failure ,(result-detail gate result fields output-path))))
    (`#(51 #b("child_process_failure"))
     `#(error #(child-process-failure ,(result-detail gate result fields output-path))))
    (`#(60 #b("internal_error"))
     `#(error #(internal-error ,(result-detail gate result fields output-path))))
    (_ `#(error #(unmapped-status ,(result-detail gate result fields output-path))))))

(defun classify-ok (gate result fields output-path)
  (let ((detail (result-detail gate result fields output-path)))
    (case (artifact-present? output-path)
      ('true `#(ok ,detail))
      ('false `#(error #(missing-artifact ,detail))))))

(defun classify-domain-no-plan (gate result fields output-path)
  (case gate
    ('engine
     `#(domain-no-plan ,(result-detail gate result fields output-path)))
    (_
     `#(error #(unmapped-status ,(result-detail gate result fields output-path))))))

(defun result-detail (gate runner-result status-fields output-path)
  (map 'gate gate
       'status-fields status-fields
       'exit-status (maps:get 'exit-status runner-result 'undefined)
       'signal (maps:get 'signal runner-result 'undefined)
       'stdout (maps:get 'stdout runner-result #b())
       'stderr (maps:get 'stderr runner-result #b())
       'duration-ms (maps:get 'duration-ms runner-result 0)
       'output-limit-bytes (maps:get 'output-limit-bytes runner-result 0)
       'stdout-bytes (maps:get 'stdout-bytes runner-result 0)
       'stderr-bytes (maps:get 'stderr-bytes runner-result 0)
       'stdout-truncated (maps:get 'stdout-truncated runner-result 'false)
       'stderr-truncated (maps:get 'stderr-truncated runner-result 'false)
       'artifact (artifact-metadata output-path)))

(defun artifact-present? (output-path)
  (case (file:read_file_info output-path)
    (`#(ok ,_info) 'true)
    (_ 'false)))

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
