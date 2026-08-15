(defmodule wolong-dispatch
  (export
   (run 2)))

(defun run (domain-path problem-path)
  (let ((ref (make_ref)))
    (case (whereis 'wolong-dispatch-sup)
      ('undefined
       `#(error #(dispatch supervisor-unavailable ,(map 'supervisor 'wolong-dispatch-sup))))
      (_sup-pid
       (case (wolong-dispatch-sup:start-dispatch (self) ref domain-path problem-path)
         (`#(ok ,pid)
          (let ((mon-ref (erlang:monitor 'process pid)))
            (wait-for-result ref pid mon-ref)))
         (`#(ok ,pid ,_info)
          (let ((mon-ref (erlang:monitor 'process pid)))
            (wait-for-result ref pid mon-ref)))
         (`#(error ,reason)
          `#(error #(dispatch start-failed ,(map 'supervisor 'wolong-dispatch-sup
                                                 'reason reason)))))))))

(defun wait-for-result (ref pid mon-ref)
  (receive
    (`#(wolong-dispatch-result ,ref ,pid ,result)
     (erlang:demonitor mon-ref '(flush))
     (attach-dispatch result (dispatch-detail pid ref)))
    (`#(DOWN ,mon-ref process ,pid ,reason)
     `#(error #(dispatch worker-exit ,(dispatch-detail pid ref reason))))))

(defun dispatch-detail (pid ref)
  (map 'worker pid
       'supervisor 'wolong-dispatch-sup
       'reply-ref ref
       'restart-policy 'temporary))

(defun dispatch-detail (pid ref reason)
  (maps:put 'reason reason (dispatch-detail pid ref)))

(defun attach-dispatch
  ((`#(ok ,detail) dispatch)
   `#(ok ,(maps:put 'dispatch dispatch detail)))
  ((`#(domain-no-plan ,detail) dispatch)
   `#(domain-no-plan ,(maps:put 'dispatch dispatch detail)))
  ((`#(error #(,gate ,reason ,detail)) dispatch)
   `#(error #(,gate ,reason ,(maps:put 'dispatch dispatch detail))))
  ((other _dispatch)
   other))
