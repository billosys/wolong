(defmodule wolong-binaries
  (export
   (parser 0)
   (grounder 0)
   (engine 0)
   (resolve 1)))

;;; ----------------
;;; public API
;;; ----------------

(defun parser ()
  (resolve 'parser))

(defun grounder ()
  (resolve 'grounder))

(defun engine ()
  (resolve 'engine))

(defun resolve (component)
  (case (wolong-config:validate)
    (`#(ok ,config) (resolve-from-config component config))
    (err err)))

;;; ----------------
;;; config-backed lookup
;;; ----------------

(defun resolve-from-config (component config)
  (let* ((binaries (maps:get 'binaries config))
         (path (maps:get component binaries 'undefined)))
    (case path
      ('undefined `#(error #(binary missing-config ,component)))
      (_ (check-path component path)))))

(defun check-path (component path)
  (let ((path-list (unicode:characters_to_list path)))
    (case (filelib:is_file path-list)
      ('false `#(error #(binary missing ,component ,path)))
      ('true (check-executable component path path-list)))))

(defun check-executable (component path path-list)
  (case (file:read_file_info path-list)
    (`#(ok ,info)
     (let ((mode (element 8 info)))
       (case (=/= 0 (band mode 73))
         ('true `#(ok ,(filename:absname path-list)))
         ('false `#(error #(binary non-executable ,component ,path))))))
    (`#(error ,reason)
     `#(error #(binary stat-failed ,component ,path ,reason)))))
