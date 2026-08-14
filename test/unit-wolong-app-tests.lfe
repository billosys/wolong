(defmodule unit-wolong-app-tests
  (behaviour ltest-unit))

(include-lib "ltest/include/ltest-macros.lfe")

(deftest start-stop-clean
  (ets:new 'wolong-test-log-sink '(named_table public set))
  (logger:add_handler 'wolong-test-log-collector 'wolong-test-log-collector
                       (map 'level 'error))
  (is-equal 'ok (element 1 (application:ensure_all_started 'wolong)))
  (is-not (=:= 'undefined (whereis 'wolong-sup)))
  (is-not (=:= 'undefined (whereis 'exec)))
  (is-equal 'ok (application:stop 'wolong))
  (timer:sleep 100)
  (is-equal '() (ets:tab2list 'wolong-test-log-sink))
  (logger:remove_handler 'wolong-test-log-collector)
  (ets:delete 'wolong-test-log-sink))
