(defmodule wolong_real_chengdu_SUITE
  (export
   (all 0)
   (end_per_suite 1)
   (end_per_testcase 2)
   (init_per_suite 1)
   (missing_engine_is_not_solved_proof 1)
   (plan2_minimal_returns_real_plan 1)
   (plan3_minimal_keep_false_preserves_payload 1)
   (plan3_minimal_returns_real_plan 1)
   (plan3_unsolvable_returns_domain_result 1)
   (real_parser_negative_is_typed 1)
   (suite 0)
   (validate_minimal_uses_real_parser_only 1)))

(defun all ()
  '(plan3_minimal_returns_real_plan
     plan2_minimal_returns_real_plan
     plan3_minimal_keep_false_preserves_payload
     plan3_unsolvable_returns_domain_result
     validate_minimal_uses_real_parser_only
     real_parser_negative_is_typed
     missing_engine_is_not_solved_proof))

(defun suite () `(#(timetrap #(seconds 60))))

(defun init_per_suite (config)
  (case (resolve-proof)
    (`#(ok ,proof)
     (ct:pal "real Chengdu proof: ~p" (list (proof-summary proof)))
     (cons (tuple 'proof proof) config))
    (`#(skip ,reason)
     (tuple 'skip reason))))

(defun end_per_testcase (_testcase _config)
  (application:stop 'wolong)
  'ok)

(defun end_per_suite (_config)
  'ok)

;;; ----------------
;;; public API proof cases
;;; ----------------

(defun plan3_minimal_returns_real_plan (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-plan3")))
    (set-real-env proof base-dir 'true)
    (let* ((result (plan3-case proof "minimal" (map)))
            (plan (element 2 result)))
      (equal 'ok (element 1 result))
      (assert-solved-plan plan)
      (assert-real-stdio-provenance (map-get plan 'provenance))
      (equal 'true
             (filelib:is_file (artifact-path (map-get plan 'workspace) 'engine))))))

(defun plan2_minimal_returns_real_plan (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-plan2")))
    (set-real-env proof base-dir 'true)
    (let* ((result
             (wolong:plan (case-domain proof "minimal")
                          (case-problem proof "minimal")))
            (plan (element 2 result)))
      (equal 'ok (element 1 result))
      (assert-solved-plan plan))))

(defun plan3_minimal_keep_false_preserves_payload (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-keep-false")))
    (set-real-env proof base-dir 'false)
    (let* ((result (plan3-case proof "minimal" '()))
            (plan (element 2 result))
            (workspace (map-get plan 'workspace))
            (cleanup (map-get workspace 'cleanup)))
      (equal 'ok (element 1 result))
      (assert-solved-plan plan)
      (equal 'removed (map-get cleanup 'action))
      (equal 'false (filelib:is_dir (map-get workspace 'path)))
      (equal 'false (filelib:is_file (artifact-path workspace 'engine))))))

(defun plan3_unsolvable_returns_domain_result (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-unsolvable")))
    (set-real-env proof base-dir 'true)
    (let* ((result (plan3-case proof "unsolvable" (map)))
            (detail (element 2 result))
            (engine (map-get detail 'engine))
            (status (map-get engine 'status-fields)))
      (equal 'unsolvable (element 1 result))
      (equal 2 (map-get engine 'exit-status))
      (equal #b("domain_no_plan") (map-get status 'status))
      (equal #b("no_plan") (map-get status 'outcome))
      (equal #b() (map-get engine 'stdout))
      (equal 'stdout (map-get (map-get engine 'artifact) 'source))
      (equal 'false (map-get (map-get engine 'artifact) 'exists))
      (assert-real-stdio-provenance detail))))

(defun validate_minimal_uses_real_parser_only (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-validate")))
    (set-real-parser-env proof base-dir)
    (let* ((result
             (wolong:validate (case-domain proof "minimal")
                              (case-problem proof "minimal")))
            (detail (element 2 result))
            (status (map-get detail 'status-fields)))
      (equal 'ok (element 1 result))
      (equal #b("ok") (map-get status 'status))
      (equal #b("parser") (map-get status 'component))
      (equal 'true (map-get (map-get detail 'artifact) 'exists)))))

(defun real_parser_negative_is_typed (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-negative")))
    (set-real-parser-env proof base-dir)
    (let* ((result
             (wolong:validate (case-domain proof "broken-syntax")
                              (case-problem proof "broken-syntax")))
            (reason (element 2 result))
            (detail (element 2 reason))
            (status (map-get detail 'status-fields)))
      (equal 'error (element 1 result))
      (equal 'invalid-hddl (element 1 reason))
      (equal 22 (map-get detail 'exit-status))
      (equal #b("input_invalid") (map-get status 'status))
      (equal 22 (map-get status 'exit-code))
      (equal 'undistinguished (map-get detail 'invalid-kind)))))

(defun missing_engine_is_not_solved_proof (config)
  (let* ((proof (proof config))
          (base-dir (temp-base "real-missing-engine")))
    (set-real-env (maps:put 'engine (missing-engine proof) proof)
                  base-dir
                  'true)
    (let* ((result (plan3-case proof "minimal" (map)))
            (reason (element 2 result))
            (detail (element 3 reason)))
      (equal 'error (element 1 result))
      (equal 'engine (element 1 reason))
      (equal 'binary (element 2 reason))
      (equal 'binary (element 1 (map-get detail 'reason)))
      (equal 'missing (element 2 (map-get detail 'reason)))
      (equal 'false (filelib:is_dir base-dir)))))

;;; ----------------
;;; real Chengdu resolution
;;; ----------------

(defun resolve-proof ()
  (let* ((bin-dir
           (configured-dir "WOLONG_CHENGDU_BIN_DIR" (sibling-path "bin")))
          (fixture-dir
            (configured-dir "WOLONG_CHENGDU_FIXTURE_DIR"
                            (sibling-path "fixtures"))))
    (case (usable-proof bin-dir fixture-dir)
      ('true
       `#(ok
          ,(map 'bin-dir bin-dir
                'fixture-dir fixture-dir
                'parser (component-path bin-dir "pandapi-parser")
                'grounder (component-path bin-dir "pandapi-grounder")
                'engine (component-path bin-dir "pandapi-engine")
                'chengdu-branch (chengdu-git "rev-parse --abbrev-ref HEAD")
                'chengdu-head (chengdu-git "rev-parse --short HEAD"))))
      (`#(skip ,reason)
       `#(skip ,reason)))))

(defun configured-dir (env-name default)
  (case (os:getenv env-name)
    ('false default)
    (path
     (case (filename:pathtype path)
       ('relative
        (filename:absname (filename:join (project-root) path)))
       (_
        (filename:absname path))))))

(defun sibling-path (leaf)
  (filename:absname (filename:join (list (project-root) ".." "chengdu" leaf))))

(defun usable-proof (bin-dir fixture-dir)
  (cond
    ((not (filelib:is_dir bin-dir))
     `#(skip #(missing-chengdu-bin-dir ,bin-dir)))
    ((not (filelib:is_dir fixture-dir))
     `#(skip #(missing-chengdu-fixture-dir ,fixture-dir)))
    ((not (all-real-binaries? bin-dir))
     `#(skip #(missing-real-chengdu-binary ,bin-dir)))
    ((not (all-real-fixtures? fixture-dir))
     `#(skip #(missing-real-chengdu-fixture ,fixture-dir)))
    ('true 'true)))

(defun all-real-binaries? (bin-dir)
  (lists:all
    (lambda (name) (real-executable? (component-path bin-dir name)))
    '("pandapi-parser" "pandapi-grounder" "pandapi-engine")))

(defun real-executable? (path)
  (andalso (filelib:is_file path)
           (not (inside-wolong-fixtures? path))
           (case (file:read_file_info path)
             (`#(ok ,info)
              (=/= 0 (band (element 8 info) 73)))
             (_ 'false))))

(defun inside-wolong-fixtures? (path)
  (let ((fixture-parts (filename:split (wolong-fixture-root)))
         (path-parts (filename:split (filename:absname path))))
    (lists:prefix fixture-parts path-parts)))

(defun all-real-fixtures? (fixture-dir)
  (lists:all
    (lambda (name)
      (andalso (filelib:is_file (case-domain-path fixture-dir name))
               (filelib:is_file (case-problem-path fixture-dir name))))
    '("minimal" "unsolvable" "broken-syntax")))

(defun component-path (bin-dir name)
  (filename:join bin-dir name))

(defun chengdu-git (args)
  (string:trim
    (os:cmd
      (lists:flatten
        (io_lib:format "git -C ~s ~s 2>/dev/null"
                       (list (sibling-path ".") args))))))

;;; ----------------
;;; configuration and fixtures
;;; ----------------

(defun set-real-env (proof base-dir keep-artifacts)
  (application:set_env 'wolong
                       'binaries
                       (map 'parser (map-get proof 'parser)
                            'grounder (map-get proof 'grounder)
                            'engine (map-get proof 'engine)))
  (set-common-env base-dir keep-artifacts))

(defun set-real-parser-env (proof base-dir)
  (application:set_env 'wolong 'binaries (map 'parser (map-get proof 'parser)))
  (set-common-env base-dir 'true))

(defun set-common-env (base-dir keep-artifacts)
  (application:set_env 'wolong
                       'gate-timeouts
                       (map 'parse 5000 'ground 5000 'solve 5000))
  (application:set_env 'wolong 'workdir
                       (map 'base-dir base-dir 'keep-artifacts keep-artifacts))
  (ok (element 1 (application:ensure_all_started 'wolong))))

(defun plan3-case (proof name opts)
  (wolong:plan (case-domain proof name) (case-problem proof name) opts))

(defun case-domain (proof name)
  (case-domain-path (map-get proof 'fixture-dir) name))

(defun case-problem (proof name)
  (case-problem-path (map-get proof 'fixture-dir) name))

(defun case-domain-path (fixture-dir name)
  (filename:join (list fixture-dir name "domain.hddl")))

(defun case-problem-path (fixture-dir name)
  (filename:join (list fixture-dir name "problem.hddl")))

(defun missing-engine (proof)
  (filename:join (map-get proof 'bin-dir) "pandapi-engine.missing"))

(defun proof (config)
  (proplists:get_value 'proof config))

(defun project-root ()
  (filename:absname
    (filename:join (list (code:lib_dir 'wolong) ".." ".." ".." ".."))))

(defun wolong-fixture-root ()
  (filename:join (list (project-root) "test" "fixtures")))

(defun temp-base (name)
  (filename:join
    (list "/tmp"
          (lists:flatten
            (io_lib:format "wolong-real-chengdu-~s-~p"
                           (list name
                                 (erlang:unique_integer '(positive monotonic))))))))

;;; ----------------
;;; assertions and helpers
;;; ----------------

(defun assert-solved-plan (plan)
  (equal 'solved (map-get plan 'outcome))
  (equal 'true (is_binary (map-get plan 'payload)))
  (not-true (=< (byte_size (map-get plan 'payload)) 0))
  (equal (byte_size (map-get plan 'payload)) (map-get plan 'payload-bytes))
  (equal 'stdout (map-get (map-get plan 'artifact) 'source))
  (equal 'true (map-get (map-get plan 'artifact) 'exists))
  (equal 'not-run
         (map-get (map-get plan 'verification-boundary) 'separate-verifier)))

(defun assert-real-stdio-provenance (provenance)
  (let ((parser (map-get provenance 'parser))
         (grounder (map-get provenance 'grounder))
         (engine (map-get provenance 'engine)))
    (assert-stdout-artifact parser 'parser)
    (assert-stdout-artifact grounder 'grounder)
    (assert-artifact-source engine 'engine 'stdout)
    (assert-stdin-status grounder #b("htn"))
    (assert-stdin-status engine #b("engine_input"))
    (equal #b("ok") (map-get (map-get parser 'status-fields) 'status))
    (equal #b("ok") (map-get (map-get grounder 'status-fields) 'status))))

(defun assert-stdout-artifact (detail expected-gate)
  (let ((artifact (map-get detail 'artifact))
         (status (map-get detail 'status-fields)))
    (equal expected-gate (map-get detail 'gate))
    (equal 'stdout (map-get artifact 'source))
    (equal #b("stdout") (map-get status 'artifact))))

(defun assert-artifact-source (detail expected-gate expected-source)
  (let ((artifact (map-get detail 'artifact)))
    (equal expected-gate (map-get detail 'gate))
    (equal expected-source (map-get artifact 'source))))

(defun assert-stdin-status (detail expected-role)
  (let ((status (map-get detail 'status-fields)))
    (equal #b("-") (map-get status #b("path")))
    (equal expected-role (map-get status 'path-role))
    (equal #b("read") (map-get status 'operation))))

(defun artifact-path (workspace role)
  (map-get (map-get workspace 'artifacts) role))

(defun proof-summary (proof)
  (map 'bin-dir (map-get proof 'bin-dir)
       'fixture-dir (map-get proof 'fixture-dir)
       'chengdu-branch (map-get proof 'chengdu-branch)
       'chengdu-head (map-get proof 'chengdu-head)))

(defun equal (expected actual)
  (case (=:= expected actual)
    ('true 'ok)
    ('false
     (ct:fail (tuple 'expected expected 'actual actual)))))

(defun not-true (actual)
  (case actual
    ('false 'ok)
    (_
     (ct:fail (tuple 'expected-not-true actual)))))

(defun ok (actual)
  (equal 'ok actual))
