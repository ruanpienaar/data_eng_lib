-module(data_eng_lib_tests).
-include_lib("eunit/include/eunit.hrl").

data_eng_lib_unit_test_() ->
    {setup,
     % Setup Fixture
     fun() ->
         xxx
     end,
     % Cleanup Fixture
     fun(xxx) ->
         ok
     end,
     % List of tests
     [
       % Example test
       {"data_eng_lib:process/0",
            ?_assert(unit_testing:try_test_fun(fun process/0))}
     ]
    }.

process() ->
    % ?assert(
    %     is_list(data_eng_lib:module_info())
    % ).
    ok.
