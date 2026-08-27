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
    (err
     `#(error #(workspace config ,(map 'reason err))))))

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
    (case (wolong-gate:run-parser-stdout-to parser
                                            parser-output
                                            domain-path
                                            problem-path
                                            config)
      (`#(ok ,parser-detail)
       (case (materialize-stdout-artifact parser-detail)
         (`#(ok ,parser-with-artifact)
          (run-grounder-stage grounder
                              grounder-output
                              engine
                              engine-output
                              parser-with-artifact
                              workspace
                              config))
         (`#(error #(,reason ,payload-detail))
          (finish
            `#(error
               #(parser ,reason
                        ,(map 'workspace workspace
                              'parser parser-detail
                              'payload-error payload-detail)))
            workspace config))))
      (`#(error #(,reason ,parser-detail))
       (finish
         `#(error
            #(parser ,reason ,(map 'workspace workspace 'parser parser-detail)))
         workspace config)))))

(defun run-grounder-stage (grounder grounder-output
                                    engine
                                    engine-output
                                    parser-detail
                                    workspace
                                    config)
  (case (wolong-gate:run-grounder-stdin-to grounder
                                           grounder-output
                                           (maps:get 'stdout parser-detail)
                                           config)
    (`#(ok ,grounder-detail)
     (case (materialize-stdout-artifact grounder-detail)
       (`#(ok ,grounder-with-artifact)
        (run-engine-stage engine
                          engine-output
                          parser-detail
                          grounder-with-artifact
                          workspace
                          config))
       (`#(error #(,reason ,payload-detail))
        (finish
          `#(error
             #(grounder ,reason
                        ,(map 'workspace workspace
                              'parser parser-detail
                              'grounder grounder-detail
                              'payload-error payload-detail)))
          workspace config))))
    (`#(error #(,reason ,grounder-detail))
     (finish
       `#(error
          #(grounder ,reason
                     ,(map 'workspace workspace
                           'parser parser-detail
                           'grounder grounder-detail)))
       workspace config))))

(defun run-engine-stage (engine engine-output
                                parser-detail
                                grounder-detail
                                workspace
                                config)
  (case (wolong-gate:run-engine-stdin-to engine
                                         engine-output
                                         (maps:get 'stdout grounder-detail)
                                         config)
    (`#(ok ,engine-detail)
     (case (materialize-stdout-artifact engine-detail)
       (`#(ok ,engine-with-artifact)
        (finish
          `#(ok
             ,(map 'workspace workspace
                   'parser parser-detail
                   'grounder grounder-detail
                   'engine (attach-plan-payload engine-with-artifact)))
          workspace config))
       (`#(error #(,reason ,payload-detail))
        (finish
          `#(error
             #(engine ,reason
                      ,(map 'workspace workspace
                            'parser parser-detail
                            'grounder grounder-detail
                            'engine engine-detail
                            'payload-error payload-detail)))
          workspace config))))
    (`#(domain-no-plan ,engine-detail)
     (finish
       `#(domain-no-plan
          ,(map 'workspace workspace
                'parser parser-detail
                'grounder grounder-detail
                'engine engine-detail))
       workspace config))
    (`#(error #(,reason ,engine-detail))
     (finish
       `#(error
          #(engine ,reason
                   ,(map 'workspace workspace
                         'parser parser-detail
                         'grounder grounder-detail
                         'engine engine-detail)))
       workspace config))))

(defun materialize-stdout-artifact (gate-detail)
  (let* ((artifact (maps:get 'artifact gate-detail))
          (path (maps:get 'path artifact))
          (payload (maps:get 'stdout gate-detail)))
    (case (file:write_file path payload)
      ('ok
       `#(ok
          ,(maps:put 'artifact
                     (maps:merge artifact
                                 (map 'materialized 'true
                                      'exists (filelib:is_file path)
                                      'bytes (byte_size payload)))
                     gate-detail)))
      (`#(error ,reason)
       `#(error
          #(artifact-materialize-failed
            ,(map 'path path 'reason reason 'bytes (byte_size payload))))))))

(defun attach-plan-payload (engine-detail)
  (let ((payload (maps:get 'stdout engine-detail)))
    (maps:put 'plan-payload
              (map 'bytes payload
                   'byte-size (byte_size payload)
                   'source 'engine-stdout
                   'path (maps:get 'path (maps:get 'artifact engine-detail)))
              engine-detail)))

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
       `#(error
          #(workspace ,reason
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
