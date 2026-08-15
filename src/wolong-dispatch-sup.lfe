(defmodule wolong-dispatch-sup
  (behaviour supervisor)
  (export
   (start_link 0)
   (start-dispatch 4)
   (worker-pids 0)
   (worker-count 0)
   (init 1)))

(defun start_link ()
  (supervisor:start_link `#(local ,(MODULE)) (MODULE) '()))

(defun start-dispatch (caller ref domain-path problem-path)
  (supervisor:start_child (MODULE) (list caller ref domain-path problem-path)))

(defun worker-pids ()
  (live-worker-pids (supervisor:which_children (MODULE)) '()))

(defun worker-count ()
  (length (worker-pids)))

(defun worker-spec ()
  #M(id wolong-dispatch-worker
     start #(wolong-dispatch-worker start_link ())
     restart temporary
     shutdown 5000
     type worker
     modules (wolong-dispatch-worker)))

(defun init (_args)
  `#(ok #(,#M(strategy simple_one_for_one
              intensity 20
              period 10)
          (,(worker-spec)))))

(defun live-worker-pids
  ((`() acc)
   (lists:reverse acc))
  (((cons `#(,_id ,pid ,_type ,_mods) rest) acc)
   (case (andalso (is_pid pid) (erlang:is_process_alive pid))
     ('true (live-worker-pids rest (cons pid acc)))
     ('false (live-worker-pids rest acc)))))
