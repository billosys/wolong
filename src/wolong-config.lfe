(defmodule wolong-config
  (export
   (validate 0)))

;;; ----------------
;;; public API
;;; ----------------

(defun validate ()
  (validate-keys (required-keys) (map)))

;;; ----------------
;;; config surface
;;; ----------------

(defun required-keys () '(binaries gate-timeouts workdir))

(defun validate-keys
  (('() acc) `#(ok ,acc))
  ((`(,key . ,rest) acc)
   (case (application:get_env 'wolong key)
     ('undefined `#(error #(config missing-key ,key)))
     (`#(ok ,value)
      (case (validate-value key value)
        (`#(ok ,validated) (validate-keys rest (maps:put key validated acc)))
        (err err))))))

(defun validate-value
  (('binaries value) (validate-binaries value))
  (('gate-timeouts value) (validate-gate-timeouts value))
  (('workdir value) (validate-workdir value)))

;;; ----------------
;;; binaries: map of component (atom) -> path (string)
;;; ----------------

(defun validate-binaries (value)
  (if (is_map value)
      (validate-binary-entries (maps:to_list value) (map))
      `#(error #(config wrong-shape binaries))))

(defun validate-binary-entries
  (('() acc) `#(ok ,acc))
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
  (('() acc) `#(ok ,acc))
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
;;; shared predicates
;;; ----------------

(defun is-path-string (path)
  (orelse (is_binary path)
          (andalso (is_list path) (io_lib:printable_unicode_list path))))
