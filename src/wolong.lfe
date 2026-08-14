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

(defun validate-path-args (domain-path problem-path)
  (if (not (path-string? domain-path))
      `#(error #(invalid-argument domain-path ,domain-path))
      (if (not (path-string? problem-path))
          `#(error #(invalid-argument problem-path ,problem-path))
          'ok)))

(defun path-string? (path)
  (orelse (is_binary path)
          (andalso (is_list path) (io_lib:printable_unicode_list path))))
