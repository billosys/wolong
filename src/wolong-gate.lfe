(defmodule wolong-gate
  (export
   (classify 3)
   (classify-stdout 3)
   (engine-argv 2)
   (grounder-argv 2)
   (parser-argv 3)
   (run-engine 3)
   (run-engine-stdin-to 4)
   (run-engine-to 4)
   (run-grounder 3)
   (run-grounder-stdin-to 4)
   (run-grounder-to 4)
   (run-parser 4)
   (run-parser-stdout-to 5)
   (run-parser-to 5)))

;;; ----------------
;;; public runners
;;; ----------------

(defun run-parser (parser domain-path problem-path config)
  (run-gate 'parser parser
            (parser-argv-fn domain-path problem-path)
            "htn"
            config))

(defun run-grounder (grounder htn-path config)
  (run-gate 'grounder grounder (grounder-argv-fn htn-path) "sas" config))

(defun run-engine (engine sas-path config)
  (run-gate 'engine engine (engine-argv-fn sas-path) "plan" config))

(defun run-parser-to (parser output-path domain-path problem-path config)
  (run-gate-to 'parser parser
               (parser-argv output-path domain-path problem-path)
               output-path
               config))

(defun run-parser-stdout-to (parser output-path domain-path problem-path config)
  (run-gate-stdout-to 'parser parser
                      (parser-argv "-" domain-path problem-path)
                      output-path
                      config))

(defun run-grounder-to (grounder output-path htn-path config)
  (run-gate-to 'grounder grounder
               (grounder-argv output-path htn-path)
               output-path
               config))

(defun run-grounder-stdin-to (grounder output-path htn-bytes config)
  (run-gate-stdin-stdout-to 'grounder grounder
                            (grounder-argv "-" "-")
                            htn-bytes
                            output-path
                            config))

(defun run-engine-to (engine output-path sas-path config)
  (run-gate-to 'engine engine
               (engine-argv output-path sas-path)
               output-path
               config))

(defun run-engine-stdin-to (engine output-path sas-bytes config)
  (run-gate-stdin-stdout-to 'engine engine
                            (engine-argv "-" "-")
                            sas-bytes
                            output-path
                            config))

(defun classify (gate runner-result output-path)
  (classify-artifact gate runner-result (tuple 'file output-path)))

(defun classify-stdout (gate runner-result output-path)
  (classify-artifact gate runner-result (tuple 'stdout output-path)))

(defun classify-artifact (gate runner-result artifact-mode)
  (case runner-result
    (`#(ok ,result)
     (classify-completed gate result artifact-mode))
    (`#(timeout ,result)
     `#(error #(timeout ,(result-detail gate result (map) artifact-mode))))
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
  (list "--supervised" "--status=stderr" "--output" output-path htn-path))

(defun engine-argv (output-path sas-path)
  (list "--supervised" "--status=stderr" "--output" output-path sas-path))

(defun parser-argv-fn (domain-path problem-path)
  (lambda (output-path) (parser-argv output-path domain-path problem-path)))

(defun grounder-argv-fn (htn-path)
  (lambda (output-path) (grounder-argv output-path htn-path)))

(defun engine-argv-fn (sas-path)
  (lambda (output-path) (engine-argv output-path sas-path)))

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
       `#(error
          #(workdir-unavailable
            ,(map 'gate gate 'path output-path 'reason reason)))))))

(defun run-gate-to (gate binary argv output-path config)
  (case (filelib:ensure_dir output-path)
    ('ok
     (classify gate
               (wolong-exec:run binary argv (runner-opts gate config))
               output-path))
    (`#(error ,reason)
     `#(error
        #(workdir-unavailable
          ,(map 'gate gate 'path output-path 'reason reason))))))

(defun run-gate-stdout-to (gate binary argv output-path config)
  (case (filelib:ensure_dir output-path)
    ('ok
     (classify-stdout gate
                      (wolong-exec:run binary argv (runner-opts gate config))
                      output-path))
    (`#(error ,reason)
     `#(error
        #(workdir-unavailable
          ,(map 'gate gate 'path output-path 'reason reason))))))

(defun run-gate-stdin-stdout-to (gate binary
                                      argv
                                      stdin-bytes
                                      output-path
                                      config)
  (case (filelib:ensure_dir output-path)
    ('ok
     (classify-stdout
       gate
       (wolong-exec:run-stdin binary argv stdin-bytes (runner-opts gate config))
       output-path))
    (`#(error ,reason)
     `#(error
        #(workdir-unavailable
          ,(map 'gate gate 'path output-path 'reason reason))))))

(defun runner-opts (gate config)
  (let* ((gate-timeouts (maps:get 'gate-timeouts config))
          (timeout-ms (maps:get (timeout-key gate) gate-timeouts)))
    (map 'timeout-ms timeout-ms 'kill-timeout-sec 1 'output-limit-bytes 65536)))

(defun timeout-key
  (('parser) 'parse)
  (('grounder) 'ground)
  (('engine) 'solve))

(defun output-path (gate extension config)
  (let* ((workdir (maps:get 'workdir config))
          (base-dir (unicode:characters_to_list (maps:get 'base-dir workdir)))
          (id (erlang:unique_integer '(positive monotonic)))
          (name
            (lists:flatten
              (io_lib:format "wolong-~p-~p.~s" (list gate id extension)))))
    (filename:join base-dir name)))

;;; ----------------
;;; result classification
;;; ----------------

(defun classify-completed (gate result artifact-mode)
  (case (maps:is_key 'signal result)
    ('true
     `#(error
        #(signal-terminated ,(result-detail gate result (map) artifact-mode))))
    ('false
     (case (wolong-status:parse (maps:get 'stderr result))
       (`#(ok ,fields)
        (classify-status gate
                         (maps:get 'exit-status result)
                         fields
                         result
                         artifact-mode))
       (`#(error ,reason)
        `#(error
           #(missing-status ,reason
                            ,(result-detail gate result (map) artifact-mode))))))))

(defun classify-status (gate exit-status fields result artifact-mode)
  (case (exit-code-matches? exit-status fields)
    ('true
     (classify-matched-status gate exit-status fields result artifact-mode))
    ('false
     `#(error
        #(status-exit-mismatch
          ,(result-detail gate result fields artifact-mode))))))

(defun classify-matched-status (gate exit-status fields result artifact-mode)
  (case (tuple exit-status (maps:get 'status fields 'undefined))
    (`#(0 #b("ok"))
     (classify-ok gate result fields artifact-mode))
    (`#(2 #b("domain_no_plan"))
     (classify-domain-no-plan gate result fields artifact-mode))
    (`#(10 #b("cli_usage_error"))
     `#(error
        #(cli-usage-error ,(result-detail gate result fields artifact-mode))))
    (`#(20 #b("input_unavailable"))
     `#(error
        #(input-unavailable ,(result-detail gate result fields artifact-mode))))
    (`#(21 #b("output_unavailable"))
     `#(error
        #(output-unavailable ,(result-detail gate result fields artifact-mode))))
    (`#(22 #b("input_invalid"))
     `#(error
        #(input-invalid ,(result-detail gate result fields artifact-mode))))
    (`#(30 #b("unsupported_feature"))
     `#(error
        #(unsupported-feature ,(result-detail gate result fields artifact-mode))))
    (`#(31 #b("legacy_surface"))
     `#(error
        #(legacy-surface ,(result-detail gate result fields artifact-mode))))
    (`#(32 #b("experimental_surface"))
     `#(error
        #(experimental-surface
          ,(result-detail gate result fields artifact-mode))))
    (`#(33 #b("future_surface"))
     `#(error
        #(future-surface ,(result-detail gate result fields artifact-mode))))
    (`#(40 #b("timeout"))
     `#(error
        #(managed-timeout ,(result-detail gate result fields artifact-mode))))
    (`#(41 #b("resource_limit"))
     `#(error
        #(resource-limit ,(result-detail gate result fields artifact-mode))))
    (`#(42 #b("interrupted"))
     `#(error #(interrupted ,(result-detail gate result fields artifact-mode))))
    (`#(50 #b("dependency_failure"))
     `#(error
        #(dependency-failure ,(result-detail gate result fields artifact-mode))))
    (`#(51 #b("child_process_failure"))
     `#(error
        #(child-process-failure
          ,(result-detail gate result fields artifact-mode))))
    (`#(60 #b("internal_error"))
     `#(error
        #(internal-error ,(result-detail gate result fields artifact-mode))))
    (_
     `#(error
        #(unmapped-status ,(result-detail gate result fields artifact-mode))))))

(defun exit-code-matches? (exit-status fields)
  (case (maps:get 'exit-code fields 'undefined)
    ('undefined 'true)
    (status-exit-code
     (andalso (is_integer status-exit-code) (=:= exit-status status-exit-code)))))

(defun classify-ok (gate result fields artifact-mode)
  (let ((detail (result-detail gate result fields artifact-mode)))
    (case (artifact-usable? artifact-mode result)
      ('true
       `#(ok ,detail))
      (`#(error ,reason)
       `#(error #(,reason ,detail))))))

(defun classify-domain-no-plan (gate result fields artifact-mode)
  (case gate
    ('engine
     `#(domain-no-plan ,(result-detail gate result fields artifact-mode)))
    (_
     `#(error
        #(unmapped-status ,(result-detail gate result fields artifact-mode))))))

(defun result-detail (gate runner-result status-fields artifact-mode)
  (map 'gate gate
       'status-fields status-fields
       'os-pid (maps:get 'os-pid runner-result 'undefined)
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
       'artifact (artifact-metadata artifact-mode runner-result)))

(defun artifact-usable?
  (((tuple 'file output-path) _runner-result)
   (case (file:read_file_info output-path)
     (`#(ok ,_info) 'true)
     (_
      `#(error missing-artifact))))
  (((tuple 'stdout _output-path) runner-result)
   (if (=:= 'true (maps:get 'stdout-truncated runner-result 'false))
     `#(error artifact-truncated)
     (case (> (byte_size (maps:get 'stdout runner-result #b())) 0)
       ('true 'true)
       ('false
        `#(error missing-artifact))))))

(defun artifact-metadata
  (((tuple 'file output-path) _runner-result)
   (file-artifact-metadata output-path))
  (((tuple 'stdout output-path) runner-result)
   (map 'path output-path
        'source 'stdout
        'exists (> (byte_size (maps:get 'stdout runner-result #b())) 0)
        'bytes (maps:get 'stdout-bytes runner-result 0)
        'truncated (maps:get 'stdout-truncated runner-result 'false))))

(defun file-artifact-metadata (output-path)
  (case (file:read_file_info output-path)
    (`#(ok ,info)
     (map 'path output-path 'exists 'true 'bytes (element 2 info)))
    (`#(error ,reason)
     (map 'path output-path 'exists 'false 'error reason))))
