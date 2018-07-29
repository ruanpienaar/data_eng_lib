%% -*- erlang -*-
-module(data_eng_lib).

-mode(compile).

-export([
    main/1
]).

main([]) ->
    setup(),
    ok = read_data(standard_io),
    io:format(standard_io, "~s\n", [binary_to_list(summary_json())]);
main(["-h"]) ->
    usage();
main(Filenames) ->
    setup(),
    [ begin
        {ok, FD} = file:open(Filename, [read, binary]),
        ok = read_data(FD),
        %io:format("Filename ~p Done.\n", [Filename]),
        ok = file:close(FD)
      end || Filename <- Filenames ],
    io:format(standard_io, "~s\n", [binary_to_list(summary_json())]).

usage() ->
    io:format(standard_io, "usage: zcat data/*.gz | ./~p\n", [?MODULE]),
    io:format(standard_io, "usage: ./~p <FILENAME>\n", [?MODULE]),
    halt(0).

setup() ->
    ok = application:start(jsone),
    new_tables().

-spec read_data(io:device()) -> ok | {error, term()}.
read_data(Device) ->
    ok = io:setopts(Device, [binary]),
    read(Device).

-spec summary_json() -> binary().
summary_json() ->
    UniqueActiveUsers = ets:info(active_users, size),
    TopThreeMan = top_x_entries(manuf, 3),
    {Total, SessionMin, SessionMax} = get_session_details(),
    SessionMean = Total / UniqueActiveUsers,
    jsone:encode(
        #{
            active_users => UniqueActiveUsers,
            manufacturers => TopThreeMan,
            sessions => #{
                mean => SessionMean,
                min => SessionMin,
                max => SessionMax
            }
        }
    ).

new_tables() ->
    active_users = ets:new(active_users, [named_table, public, ordered_set]),
    cat = ets:new(cat, [named_table, public, ordered_set]),
    manuf = ets:new(manuf, [named_table, public, ordered_set]),
    user_sessions = ets:new(user_sessions, [named_table, public, ordered_set]).

top_x_entries(Tbl, TopX) ->
    top(lists:sort(fun({_Sa, Ca}, {_Sb, Cb}) ->
        Ca > Cb
    end, ets:tab2list(Tbl)), [], TopX).

top([], R, _C) ->
    lists:reverse(R);
top(_L, R, 0) ->
    lists:reverse(R);
top([{H,_}|T], R, C) ->
    top(T, [H|R], C-1).

% @doc read takes in a io:device() and get's subsequent lines from io device.
%      A io:device can be standard_io or FD ({ok, FD} = file:open(...,)).
% @end
-spec read(io:device()) -> ok | {error, term()}.
read(Device) ->
    case io:get_line(Device, "") of
        eof ->
            ok;
        {error, Reason} ->
            io:format("ERROR: ~p~n", [Reason]),
            {error, Reason};
        Data ->
            ok = process(Data),
            %io:format("Data\n~p\n", [Data]),
            read(Device)
    end.

% asume get_line will pass along the LF
-spec process(binary()) -> ok.
process(Line) ->
    % io:format("\n\nLINE~p\n", [Line]),
    BS=byte_size(Line),
    Data =
        case binary:part(Line, BS-1, 1) of
            <<"\n">> ->
                binary:part(Line, 0, BS-1);
            _ ->
                % Maybe drop line? consistency check?
                Line
        end,
    %io:format("\n\nData~p\n", [Data]),
    Json = jsone:decode(Data),
    #{ <<"data">> :=
        #{
            <<"category">> := Cat,
            <<"user_id">> := UserId,
            <<"manufacturer">> := Manuf,
            <<"session_id">> := SessionId
        }
    } = Json,
    case ets:lookup(active_users, UserId) of
        [] ->
            true = ets:insert(active_users, {UserId, undefined});
        [{UserId, _}] ->
            ok
    end,

    % Manufacturer
    ManufLowerString = list_to_binary(string:to_lower(binary_to_list(Manuf))),
    _ = ets:update_counter(manuf, ManufLowerString, 1, {ManufLowerString, 0}),

    % Sessions
    _ = ets:update_counter(user_sessions, {UserId, SessionId}, 1, {{UserId, SessionId}, 0}),
    ok.

-spec get_session_details() -> {non_neg_integer(), non_neg_integer(), non_neg_integer()}.
get_session_details() ->
    % io:format("~p\n", [ets:tab2list(user_sessions)]),
    ets:foldl(fun
        ({{UserId, SessionId}, C}, {0,0,0}) ->
            {C, C, C};
        ({{UserId, SessionId}, C}, {Total, Min, Max}) ->
            NewMin = case C =< Min of
                true ->
                    C;
                false ->
                    Min
            end,
            NewMax = case C >= Max of
                true ->
                    C;
                false ->
                    Max
            end,
            {Total+C, NewMin, NewMax}
    end, {0,0,0}, user_sessions).