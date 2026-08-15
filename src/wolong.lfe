(defmodule wolong
  (export
   (plan 2)
   (plan 3)
   (validate 2)))

;;; ----------------
;;; public API
;;; ----------------

(defun plan (domain-path problem-path)
  (plan domain-path problem-path (map)))

(defun plan (domain-path problem-path opts)
  (case (validate-plan-input domain-path problem-path opts)
    ('ok (adapt-plan-result (wolong-dispatch:run domain-path problem-path)))
    (err err)))

(defun validate (domain-path problem-path)
  (case (validate-path-args domain-path problem-path)
    ('ok (validate-paths domain-path problem-path))
    (err err)))

(defun adapt-plan-result
  ((`#(ok ,detail)) (public-solved-plan detail))
  ((`#(domain-no-plan ,detail)) `#(unsolvable ,detail))
  ((`#(error #(,gate ,reason ,detail))) `#(error #(,gate ,reason ,detail)))
  ((err) err))

(defun public-solved-plan (detail)
  (let* ((engine (maps:get 'engine detail))
         (payload (maps:get 'plan-payload engine 'undefined)))
    (case payload
      ('undefined
       `#(error #(engine plan-payload-missing ,detail)))
      (_ `#(ok ,(map 'outcome 'solved
                     'payload (maps:get 'bytes payload)
                     'payload-bytes (maps:get 'byte-size payload)
                     'artifact (maps:get 'artifact engine)
                     'provenance (plan-provenance detail)
                     'workspace (maps:get 'workspace detail)
                     'dispatch (maps:get 'dispatch detail 'undefined)
                     'verification-boundary (verification-boundary)))))))

(defun plan-provenance (detail)
  (map 'parser (maps:get 'parser detail)
       'grounder (maps:get 'grounder detail)
       'engine (maps:get 'engine detail)))

(defun verification-boundary ()
  (map 'chain 'parser-grounder-engine
       'plan-artifact 'produced-by-engine
       'separate-verifier 'not-run
       'action-sequence 'deferred
       'decomposition-tree 'deferred
       're-entry-condition
       #b("implement stable machine-readable plan/decomposition parsing or supported verifier contract")))

(defun validate-paths (domain-path problem-path)
  (case (wolong-config:validate)
    (`#(ok ,config)
     (case (wolong-binaries:parser)
       (`#(ok ,parser)
        (adapt-parser-result
         (wolong-gate:run-parser parser domain-path problem-path config)))
       (err err)))
    (err err)))

;;; ----------------
;;; parser compatibility adapter
;;; ----------------

(defun adapt-parser-result
  ((`#(ok ,detail)) `#(ok ,detail))
  ((`#(error #(input-unavailable ,detail)))
   `#(error #(missing-file ,detail)))
  ((`#(error #(output-unavailable ,detail)))
   `#(error #(output-unavailable ,detail)))
  ((`#(error #(input-invalid ,detail)))
   `#(error #(invalid-hddl ,(maps:put 'invalid-kind 'undistinguished detail))))
  ((`#(error #(timeout ,detail)))
   `#(error #(parser timeout ,detail)))
  ((`#(error #(exec ,reason ,detail)))
   `#(error #(parser exec ,reason ,detail)))
  ((`#(error #(missing-status ,reason ,detail)))
   `#(error #(parser status-missing ,reason ,detail)))
  ((`#(error #(status-exit-mismatch ,detail)))
   `#(error #(parser status-exit-mismatch ,detail)))
  ((`#(error #(unmapped-status ,detail)))
   `#(error #(parser unmapped-status ,detail)))
  ((err) err))

;;; ----------------
;;; input validation
;;; ----------------

(defun validate-plan-input (domain-path problem-path opts)
  (case (validate-path-args domain-path problem-path)
    ('ok (validate-plan-opts opts))
    (err err)))

(defun validate-plan-opts
  ((opts) (when (is_map opts))
   (case (maps:size opts)
     (0 'ok)
     (_ `#(error #(opts unsupported-option
                   ,(map 'supported '(#M() ())
                         'received opts))))))
  (('()) 'ok)
  ((opts)
   `#(error #(opts invalid-argument
              ,(map 'expected '(empty-map empty-list)
                    'received opts)))))

(defun validate-path-args (domain-path problem-path)
  (if (not (path-string? domain-path))
      `#(error #(invalid-argument domain-path ,domain-path))
      (if (not (path-string? problem-path))
          `#(error #(invalid-argument problem-path ,problem-path))
          'ok)))

(defun path-string? (path)
  (orelse (is_binary path)
          (andalso (is_list path) (io_lib:printable_unicode_list path))))
