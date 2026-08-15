(defmodule wolong-sup
  (behaviour supervisor)
  (export
   (start_link 0)
   (init 1)))

;;; ----------------
;;; config functions
;;; ----------------

(defun server-name () (MODULE))

(defun sup-flags ()
  `#M(strategy one_for_one
      intensity 5
      period 10))

(defun dispatch-supervisor-spec ()
  #M(id wolong-dispatch-sup
     start #(wolong-dispatch-sup start_link ())
     restart permanent
     shutdown infinity
     type supervisor
     modules (wolong-dispatch-sup)))

;;; -------------------------
;;; supervisor implementation
;;; -------------------------

(defun start_link ()
  (supervisor:start_link `#(local ,(server-name)) (MODULE) '()))

(defun init (_args)
  `#(ok #(,(sup-flags) (,(dispatch-supervisor-spec)))))
