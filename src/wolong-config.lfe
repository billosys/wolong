(defmodule wolong-config
  (export
   (validate 0)))

;;; ----------------
;;; public API
;;; ----------------

(defun validate ()
  (case (validate-keys (required-keys) (map))
    (`#(ok ,config)
     (validate-optional-output-limits config))
    (err err)))

;;; ----------------
;;; config surface
;;; ----------------

(defun required-keys () '(binaries gate-timeouts workdir))

(defun validate-keys
  (('() acc)
   `#(ok ,acc))
  ((`(,key . ,rest) acc)
   (case (application:get_env 'wolong key)
     ('undefined
      `#(error #(config missing-key ,key)))
     (`#(ok ,value)
      (case (validate-value key value)
        (`#(ok ,validated)
         (validate-keys rest (maps:put key validated acc)))
        (err err))))))

(defun validate-value
  (('binaries value)
   (validate-binaries value))
  (('gate-timeouts value)
   (validate-gate-timeouts value))
  (('workdir value)
   (validate-workdir value))
  (('output-limits value)
   (validate-output-limits value)))

;;; ----------------
;;; binaries: map of component (atom) -> path (string)
;;; ----------------

(defun validate-binaries (value)
  (if (is_map value)
    (validate-binary-entries (maps:to_list value) (map))
    `#(error #(config wrong-shape binaries))))

(defun validate-binary-entries
  (('() acc)
   `#(ok ,acc))
  ((`(#(,component ,path) . ,rest) acc)
   (if (is-path-string path)
     (validate-binary-entries rest (maps:put component path acc))
     `#(error #(config non-string-path binaries ,component)))))

;;; ----------------
;;; gate-timeouts: map of gate (atom) -> positive integer milliseconds
;;; ----------------

(defun validate-gate-timeouts (value)
  (if (is_map value)
    (validate-timeout-entries (maps:to_list value) (map))
    `#(error #(config wrong-shape gate-timeouts))))

(defun validate-timeout-entries
  (('() acc)
   `#(ok ,acc))
  ((`(#(,gate ,ms) . ,rest) acc)
   (if (and (is_integer ms) (> ms 0))
     (validate-timeout-entries rest (maps:put gate ms acc))
     `#(error #(config wrong-shape gate-timeouts)))))

;;; ----------------
;;; workdir: map with base-dir (string) and keep-artifacts (boolean)
;;; ----------------

(defun validate-workdir (value)
  (if (is_map value)
    (validate-workdir-shape value)
    `#(error #(config wrong-shape workdir))))

(defun validate-workdir-shape (value)
  (let ((base-dir (maps:get 'base-dir value 'undefined))
         (keep-artifacts (maps:get 'keep-artifacts value 'undefined)))
    (if (=:= base-dir 'undefined)
      `#(error #(config missing-key workdir-base-dir))
      (if (not (is-path-string base-dir))
        `#(error #(config non-string-path workdir base-dir))
        (if (not (is_boolean keep-artifacts))
          `#(error #(config wrong-shape workdir))
          `#(ok ,value))))))

;;; ----------------
;;; output-limits: optional map of gate -> stream -> positive byte limit
;;; ----------------

(defun validate-optional-output-limits (config)
  (case (application:get_env 'wolong 'output-limits)
    ('undefined
     `#(ok ,config))
    (`#(ok ,value)
     (case (validate-value 'output-limits value)
       (`#(ok ,validated)
        `#(ok ,(maps:put 'output-limits validated config)))
       (err err)))))

(defun validate-output-limits (value)
  (if (is_map value)
    (validate-output-limit-gates (maps:to_list value) (map))
    `#(error #(config wrong-shape output-limits))))

(defun validate-output-limit-gates
  (('() acc)
   `#(ok ,acc))
  ((`(#(,gate ,limits) . ,rest) acc)
   (if (andalso (is_atom gate) (is_map limits))
     (case (validate-output-limit-streams (maps:to_list limits) (map))
       (`#(ok ,validated-limits)
        (validate-output-limit-gates rest (maps:put gate validated-limits acc)))
       (err err))
     `#(error #(config wrong-shape output-limits)))))

(defun validate-output-limit-streams
  (('() acc)
   `#(ok ,acc))
  ((`(#(,stream ,limit) . ,rest) acc)
   (case (valid-output-limit-stream? stream)
     ('true
      (if (positive-integer limit)
        (validate-output-limit-streams rest (maps:put stream limit acc))
        `#(error #(config wrong-shape output-limits))))
     ('false
      `#(error #(config wrong-shape output-limits))))))

(defun valid-output-limit-stream?
  (('stdout) 'true)
  (('stderr) 'true)
  ((_stream) 'false))

;;; ----------------
;;; shared predicates
;;; ----------------

(defun is-path-string (path)
  (orelse (is_binary path)
          (andalso (is_list path) (io_lib:printable_unicode_list path))))

(defun positive-integer (value)
  (andalso (is_integer value) (> value 0)))
