(defmodule wolong-workspace
  (export
   (cleanup 2)
   (create 1)))

;;; ----------------
;;; public API
;;; ----------------

(defun create (config)
  (let* ((workdir (maps:get 'workdir config))
          (base-dir
            (filename:absname
              (unicode:characters_to_list (maps:get 'base-dir workdir)))))
    (case (filelib:ensure_dir (filename:join base-dir ".wolong-base"))
      ('ok
       (create-dispatch base-dir 100))
      (`#(error ,reason)
       (base-unavailable base-dir reason)))))

(defun create-dispatch
  ((base-dir 0)
   `#(error #(workspace-unavailable ,(map 'base-dir base-dir 'reason 'eexist))))
  ((base-dir attempts)
   (let* ((dispatch-id (dispatch-id))
           (dispatch-dir (filename:join base-dir dispatch-id)))
     (case (file:make_dir dispatch-dir)
       ('ok
        `#(ok ,(workspace base-dir dispatch-id dispatch-dir)))
       (`#(error ,reason)
        (handle-dispatch-error base-dir dispatch-dir attempts reason))))))

(defun handle-dispatch-error
  ((base-dir _dispatch-dir attempts 'eexist)
   (create-dispatch base-dir (- attempts 1)))
  ((base-dir dispatch-dir _attempts reason)
   `#(error
      #(workspace-unavailable
        ,(map 'base-dir base-dir 'path dispatch-dir 'reason reason)))))

(defun base-unavailable (base-dir reason)
  `#(error #(base-unavailable ,(map 'base-dir base-dir 'reason reason))))

(defun cleanup (workspace keep-artifacts)
  (case keep-artifacts
    ('true
     `#(ok
        ,(maps:put 'cleanup
                   (map 'action 'kept
                        'result 'ok
                        'path (maps:get 'path workspace)
                        'exists (filelib:is_dir (maps:get 'path workspace)))
                   workspace)))
    ('false
     (remove-dispatch-workspace workspace))))

;;; ----------------
;;; workspace metadata
;;; ----------------

(defun dispatch-id ()
  (lists:flatten
    (io_lib:format "dispatch-~p"
                   (list (erlang:unique_integer '(positive monotonic))))))

(defun workspace (base-dir dispatch-id dispatch-dir)
  (map 'base-dir base-dir
       'dispatch-id dispatch-id
       'path dispatch-dir
       'artifacts
       (map 'parser (filename:join dispatch-dir "parser.htn")
            'grounder (filename:join dispatch-dir "grounder.sas")
            'engine (filename:join dispatch-dir "engine.plan"))))

;;; ----------------
;;; cleanup
;;; ----------------

(defun remove-dispatch-workspace (workspace)
  (case (safe-dispatch-workspace? workspace)
    ('true
     (let ((path (maps:get 'path workspace)))
       (case (file:del_dir_r path)
         ('ok
          `#(ok
             ,(maps:put 'cleanup
                        (map 'action 'removed
                             'result 'ok
                             'path path
                             'exists (filelib:is_dir path))
                        workspace)))
         (`#(error ,reason)
          `#(error
             #(cleanup-failed
               ,(map 'path path
                     'base-dir (maps:get 'base-dir workspace)
                     'reason reason)))))))
    ('false
     `#(error
        #(unsafe-delete
          ,(map 'path (maps:get 'path workspace 'undefined)
                'base-dir (maps:get 'base-dir workspace 'undefined)))))))

(defun safe-dispatch-workspace? (workspace)
  (let ((base-dir (maps:get 'base-dir workspace 'undefined))
         (path (maps:get 'path workspace 'undefined)))
    (andalso (is_list base-dir)
             (is_list path)
             (child-of? base-dir path)
             (lists:prefix "dispatch-" (filename:basename path)))))

(defun child-of? (base-dir path)
  (let ((base-parts (filename:split (filename:absname base-dir)))
         (path-parts (filename:split (filename:absname path))))
    (andalso (< (length base-parts) (length path-parts))
             (lists:prefix base-parts path-parts))))
