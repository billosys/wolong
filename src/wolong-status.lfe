(defmodule wolong-status
  (export
   (parse 1)))

;;; ----------------
;;; public API
;;; ----------------

(defun parse (stderr)
  (case (find-final-status-line (binary:split stderr #b("\n") '(global)) 'undefined)
    ('undefined `#(error missing-status-line))
    (line `#(ok ,(parse-status-fields (status-payload line))))))

;;; ----------------
;;; PANDAPI_STATUS parser
;;; ----------------

(defun find-final-status-line
  (('() acc) acc)
  ((`(,line . ,rest) acc)
   (case (status-line? line)
     ('true (find-final-status-line rest line))
     ('false (find-final-status-line rest acc)))))

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
  (('exit-code value) (parse-integer value))
  ((_key value) value))

(defun parse-integer (value)
  (case (string:to_integer (binary_to_list value))
    (`#(,integer ())
     (if (is_integer integer) integer value))
    (_ value)))
