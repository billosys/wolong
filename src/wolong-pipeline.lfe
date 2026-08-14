(defmodule wolong-pipeline
  (export
   (run 2)))

;;; ----------------
;;; public API
;;; ----------------

(defun run (domain-path problem-path)
  (case (wolong-config:validate)
    (`#(ok ,config)
     (case (resolve-binaries)
       (`#(ok ,binaries)
        (case (wolong-workspace:create config)
          (`#(ok ,workspace)
           (run-in-workspace domain-path problem-path config binaries workspace))
          (`#(error #(,reason ,detail))
           `#(error #(workspace ,reason ,detail)))))
       (err err)))
    (err `#(error #(workspace config ,(map 'reason err))))))

;;; ----------------
;;; binary resolution
;;; ----------------

(defun resolve-binaries ()
  (case (wolong-binaries:parser)
    (`#(ok ,parser)
     (case (wolong-binaries:grounder)
       (`#(ok ,grounder)
        (case (wolong-binaries:engine)
          (`#(ok ,engine)
           `#(ok ,(map 'parser parser 'grounder grounder 'engine engine)))
          (`#(error ,reason)
           `#(error #(engine binary ,(map 'reason reason))))))
       (`#(error ,reason)
        `#(error #(grounder binary ,(map 'reason reason))))))
    (`#(error ,reason)
     `#(error #(parser binary ,(map 'reason reason))))))

;;; ----------------
;;; sequential pipeline
;;; ----------------

(defun run-in-workspace (domain-path problem-path config binaries workspace)
  (let* ((artifacts (maps:get 'artifacts workspace))
         (parser-output (maps:get 'parser artifacts))
         (grounder-output (maps:get 'grounder artifacts))
         (engine-output (maps:get 'engine artifacts))
         (parser (maps:get 'parser binaries))
         (grounder (maps:get 'grounder binaries))
         (engine (maps:get 'engine binaries)))
    (case (wolong-gate:run-parser-to parser parser-output domain-path problem-path config)
      (`#(ok ,parser-detail)
       (case (wolong-gate:run-grounder-to grounder grounder-output parser-output config)
         (`#(ok ,grounder-detail)
          (case (wolong-gate:run-engine-to engine engine-output grounder-output config)
            (`#(ok ,engine-detail)
             (finish `#(ok ,(map 'workspace workspace
                                  'parser parser-detail
                                  'grounder grounder-detail
                                  'engine engine-detail))
                     workspace config))
            (`#(domain-no-plan ,engine-detail)
             (finish `#(domain-no-plan
                        ,(map 'workspace workspace
                              'parser parser-detail
                              'grounder grounder-detail
                              'engine engine-detail))
                     workspace config))
            (`#(error #(,reason ,engine-detail))
             (finish `#(error
                        #(engine ,reason
                          ,(map 'workspace workspace
                                'parser parser-detail
                                'grounder grounder-detail
                                'engine engine-detail)))
                     workspace config))))
         (`#(error #(,reason ,grounder-detail))
          (finish `#(error
                     #(grounder ,reason
                       ,(map 'workspace workspace
                             'parser parser-detail
                             'grounder grounder-detail)))
                  workspace config))))
      (`#(error #(,reason ,parser-detail))
       (finish `#(error
                  #(parser ,reason
                    ,(map 'workspace workspace
                          'parser parser-detail)))
               workspace config)))))

;;; ----------------
;;; cleanup and result metadata
;;; ----------------

(defun finish (result workspace config)
  (let* ((workdir (maps:get 'workdir config))
         (keep-artifacts (maps:get 'keep-artifacts workdir)))
    (case (wolong-workspace:cleanup workspace keep-artifacts)
      (`#(ok ,workspace-after-cleanup)
       (attach-workspace result workspace-after-cleanup))
      (`#(error #(,reason ,detail))
       `#(error #(workspace ,reason
                 ,(map 'workspace workspace
                       'cleanup-error detail
                       'pipeline-result result)))))))

(defun attach-workspace
  ((`#(ok ,detail) workspace)
   `#(ok ,(maps:put 'workspace workspace detail)))
  ((`#(domain-no-plan ,detail) workspace)
   `#(domain-no-plan ,(maps:put 'workspace workspace detail)))
  ((`#(error #(,gate ,reason ,detail)) workspace)
   `#(error #(,gate ,reason ,(maps:put 'workspace workspace detail)))))
