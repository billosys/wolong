(defmodule wolong-dispatch-worker
  (behaviour gen_server)
  (export
   (code_change 3)
   (handle_call 3)
   (handle_cast 2)
   (handle_info 2)
   (init 1)
   (start_link 4)
   (terminate 2)))

(defun start_link (caller ref domain-path problem-path)
  (gen_server:start_link (MODULE)
                         (list caller ref domain-path problem-path)
                         '()))

(defun init
  (((list caller ref domain-path problem-path))
   (erlang:send_after 0 (self) 'run)
   `#(ok
      ,(map 'caller caller
            'ref ref
            'domain-path domain-path
            'problem-path problem-path))))

(defun handle_call (_request _from state)
  `#(reply #(error unsupported-call) ,state))

(defun handle_cast (_request state)
  `#(noreply ,state))

(defun handle_info
  (('run state)
   (case (maps:get 'domain-path state)
     ('crash-dispatch-worker
      (erlang:error 'synthetic-dispatch-worker-crash))
     (_else
      (let* ((caller (maps:get 'caller state))
              (ref (maps:get 'ref state))
              (result
                (wolong-pipeline:run (maps:get 'domain-path state)
                                     (maps:get 'problem-path state))))
        (erlang:send caller `#(wolong-dispatch-result ,ref ,(self) ,result))
        `#(stop normal ,state)))))
  ((_info state)
   `#(noreply ,state)))

(defun terminate (_reason _state)
  'ok)

(defun code_change (_old-vsn state _extra)
  `#(ok ,state))
